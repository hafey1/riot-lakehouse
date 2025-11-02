import json
import os

import boto3

# ---- Env
ENV         = os.environ.get("ENV", "dev")
REGION      = os.environ.get("REGION", "us-west-2")
SECRET_NAME = os.environ["SECRET_NAME"]  # e.g., riotlake/dev/api-key

# ---- AWS clients
session = boto3.session.Session(region_name=REGION)
secrets = session.client("secretsmanager")

def _get_key() -> str:
    sec = secrets.get_secret_value(SecretId=SECRET_NAME)
    blob = json.loads(sec["SecretString"])
    return blob["RIOT_API_KEY"]

def handler(event, context):
    # Touch the key to verify credentials + permissions
    _ = _get_key()
    return {"ok": True, "env": ENV}