# riot-lakehouse


## dev setup
utilizing github codespace
configured to autorun dev env setup on container creation
ruff used for linting
see makefile for dev commands
	
    
    
•	Riot dev keys expire in ~24h. Update the secret whenever you regenerate the key.

# riot-lakehouse — Dev Quick Ops (to ingestion)

Step-by-step commands to go from a fresh dev stack to **pulling match data by PUUID** and verifying it landed in S3 **bronze**.

> Session defaults (set once per shell):
>
> ```bash
> export AWS_PROFILE=riot-dev
> export AWS_REGION=us-west-2
> ```

---

## 0) Prereqs

- Codespace/devcontainer is running (Python 3.11, AWS CLI, Terraform, make).
- Terraform **dev** stack has been applied in `terraform/` (S3/Kinesis/Firehose/Lambda/Secret).
- You have a **Riot developer API key** (expires ~24h).

---

## 1) Store/Update the Riot API key (daily)

```bash
aws secretsmanager update-secret \
  --secret-id riotlake/dev/api-key \
  --secret-string '{"RIOT_API_KEY":"RGAPI-your-new-key-here"}' \
  --region us-west-2
```
## 2) Get RiotID

```bash
REGION=americas
GAME_NAME="SummonerName"   # your Riot ID (before the #)
TAG_LINE="NA1"             # your Riot ID tag (after the #)
GAME_ENC=$(printf '%s' "$GAME_NAME" | jq -sRr @uri)
TAG_ENC=$(printf '%s' "$TAG_LINE"  | jq -sRr @uri)

curl -sS -H "X-Riot-Token: $(aws secretsmanager get-secret-value \
  --secret-id riotlake/dev/api-key \
  --query 'SecretString' --output text | jq -r 'fromjson.RIOT_API_KEY')" \
  "https://${REGION}.api.riotgames.com/riot/account/v1/accounts/by-riot-id/${GAME_ENC}/${TAG_ENC}" \
  | jq -r .puuid
  ```

## 3) Build/Deploy Lambda Code

```bash
make lambda-zip
cd terraform
terraform apply -var-file=env/dev.tfvars
```

## 4) Invoke Lambda Function to ingest match data

```bash
aws lambda invoke \
  --function-name riotlake-dev-ingester \
  --payload '{"puuids":["PASTE_PUUID_HERE"],"count":3}' \
  --cli-binary-format raw-in-base64-out \
  out.json && cat out.json
# Expected: {"ok": true, "ingested": true, "puuids": 1}
```

## 5) Tail Logs

```bash
aws logs tail "/aws/lambda/riotlake-dev-ingester" --follow
```

## 6 Checking Match Objects in Bronze

```bash
BUCKET=$(terraform output -raw bucket)
aws s3 ls "s3://$BUCKET/bronze/matches/env=dev/" --recursive | tail -n 10
```

sink configured for NDJSON:

```bash
KEY=$(aws s3api list-objects-v2 --bucket "$BUCKET" --prefix "bronze/matches/env=dev/" \
  --query 'reverse(sort_by(Contents,&LastModified))[0].Key' --output text)
aws s3 cp "s3://$BUCKET/$KEY" - | gunzip | head -n 3 | jq .
```

base64 inside gzip:

```bash
aws s3 cp "s3://$BUCKET/$KEY" - | gunzip | sed -n '1p' | base64 --decode | jq .
```

Daily commands:
```bash
# 1) Update dev key
aws secretsmanager update-secret --secret-id riotlake/dev/api-key \
  --secret-string '{"RIOT_API_KEY":"RGAPI-your-new-key"}'

# 2) Get PUUID
# (use Account-V1 by Riot ID)

# 3) Ingest a few matches
aws lambda invoke --function-name riotlake-dev-ingester \
  --payload '{"puuids":["PUUID"],"count":3}' \
  --cli-binary-format raw-in-base64-out out.json && cat out.json

# 4) Verify in S3
BUCKET=$(terraform output -raw bucket)
aws s3 ls "s3://$BUCKET/bronze/matches/env=dev/" --recursive | tail -n 5
```

