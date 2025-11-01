from __future__ import annotations

import json

import boto3
from botocore.config import Config


class KinesisSink:
    def __init__(self, stream_name: str, region: str) -> None:
        self.stream = stream_name
        self.client = boto3.client("kinesis", region_name=region, config=Config(retries={"max_attempts": 3}))  # noqa: E501

    def put_json(self, record: dict, partition_key: str = "match") -> None:
        # Send plain NDJSON (newline-delimited JSON), no base64
        payload = (json.dumps(record, separators=(",", ":")) + "\n").encode("utf-8")
        self.client.put_record(StreamName=self.stream, PartitionKey=partition_key, Data=payload)