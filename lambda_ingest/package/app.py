from __future__ import annotations

from lambda_ingest.config import Settings
from lambda_ingest.kinesis_sink import KinesisSink
from lambda_ingest.riot_client import RiotClient
from lambda_ingest.secrets import get_riot_api_key


# event shape we’ll accept for now:
# { "puuids": ["<puuid1>", "<puuid2>"], "count": 5 }
def handler(event, context):
    st = Settings()
    api_key = get_riot_api_key(st.secret_name, st.region)
    sink = KinesisSink(st.stream_name, st.region)

    # default input if none provided (safe no-op)
    puuids = (event or {}).get("puuids", [])
    count = int((event or {}).get("count", 5))

    client = RiotClient(api_key, st.riot_base_url)
    try:
        for puuid in puuids:
            ids = client.get_match_ids(puuid, start=0, count=count)
            for mid in ids:
                match = client.get_match(mid)
                sink.put_json({"env": st.env, "match_id": mid, "payload": match}, partition_key=puuid[:8])  # noqa: E501
        return {"ok": True, "ingested": True, "puuids": len(puuids)}
    finally:
        client.close()