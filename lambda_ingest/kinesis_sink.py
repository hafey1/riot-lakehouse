from __future__ import annotations

import base64
import json

import boto3
from botocore.config import Config


class KinesisSink:
    def __init__(self, stream_name: str, region: str) -> None:
        self.stream = stream_name
        self.client = boto3.client("kinesis", region_name=region, config=Config(retries={"max_attempts": 3}))  # noqa: E501

    def put_json(self, record: dict, partition_key: str = "match") -> None:
        payload = base64.b64encode(json.dumps(record, separators=(",", ":")).encode("utf-8"))
        self.client.put_record(StreamName=self.stream, PartitionKey=partition_key, Data=payload)