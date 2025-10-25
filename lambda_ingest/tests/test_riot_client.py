from pytest_httpx import HTTPXMock

from lambda_ingest.riot_client import RiotClient

BASE = "https://americas.api.riotgames.com"

def test_get_match_ids(httpx_mock: HTTPXMock):
    client = RiotClient("fake", "https://americas.api.riotgames.com")
    httpx_mock.add_response(
        method="GET",
        url=f"{BASE}/lol/match/v5/matches/by-puuid/PU/ids?start=0&count=3",
        json=["A", "B", "C"],
    )
    ids = client.get_match_ids("PU", start=0, count=3)
    assert ids == ["A", "B", "C"]
    client.close()

def test_get_match(httpx_mock: HTTPXMock):
    client = RiotClient("fake", "https://americas.api.riotgames.com")
    httpx_mock.add_response(
        method="GET",
        url="https://americas.api.riotgames.com/lol/match/v5/matches/FOO",
        json={"metadata": {"matchId": "FOO"}},
    )
    data = client.get_match("FOO")
    assert data["metadata"]["matchId"] == "FOO"
    client.close()