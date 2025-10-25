from __future__ import annotations

import httpx
from tenacity import retry, retry_if_exception_type, stop_after_attempt, wait_exponential


class RiotRateLimitError(Exception): ...
class RiotClientError(Exception): ...

def _raise_for_status(resp: httpx.Response) -> None:
    if resp.status_code == 429:
        raise RiotRateLimitError("Rate limited by Riot API")
    try:
        resp.raise_for_status()
    except httpx.HTTPStatusError as e:
        raise RiotClientError(str(e)) from e

class RiotClient:
    def __init__(self, api_key: str, base_url: str) -> None:
        self._client = httpx.Client(
            headers={"X-Riot-Token": api_key},
            timeout=httpx.Timeout(10.0, connect=5.0),
        )
        self._base = base_url.rstrip("/")

    @retry(
        reraise=True,
        stop=stop_after_attempt(5),
        wait=wait_exponential(multiplier=0.5, min=0.5, max=8),
        retry=retry_if_exception_type((RiotRateLimitError, httpx.HTTPError)),
    )
    def get_match_ids(self, puuid: str, start: int = 0, count: int = 20) -> list[str]:
        url = f"{self._base}/lol/match/v5/matches/by-puuid/{puuid}/ids"
        resp = self._client.get(url, params={"start": start, "count": count})
        _raise_for_status(resp)
        data = resp.json()
        return data if isinstance(data, list) else []

    @retry(
        reraise=True,
        stop=stop_after_attempt(5),
        wait=wait_exponential(multiplier=0.5, min=0.5, max=8),
        retry=retry_if_exception_type((RiotRateLimitError, httpx.HTTPError)),
    )
    def get_match(self, match_id: str) -> dict:
        url = f"{self._base}/lol/match/v5/matches/{match_id}"
        resp = self._client.get(url)
        _raise_for_status(resp)
        return resp.json()

    def close(self) -> None:
        self._client.close()