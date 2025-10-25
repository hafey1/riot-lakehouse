from __future__ import annotations

import json

import boto3


def get_riot_api_key(secret_name: str, region: str) -> str:
    sm = boto3.client("secretsmanager", region_name=region)
    resp = sm.get_secret_value(SecretId=secret_name)
    blob = json.loads(resp["SecretString"])
    return blob["RIOT_API_KEY"]