import base64
import json

import boto3
from botocore.stub import Stubber

from lambda_ingest.kinesis_sink import KinesisSink


def test_put_json():
    client = boto3.client("kinesis", region_name="us-west-2")
    stubber = Stubber(client)
    sink = KinesisSink("stream", "us-west-2")
    sink.client = client  # inject stubbed client

    expected_params = {
        "StreamName": "stream",
        "PartitionKey": "match",
        "Data": base64.b64encode(json.dumps({"x":1}, separators=(",",":")).encode("utf-8")),
    }
    stubber.add_response("put_record", {"ShardId": "shardId-000", "SequenceNumber": "1"}, expected_params)  # noqa: E501
    with stubber:
        sink.put_json({"x": 1})