from __future__ import annotations

import os


def get_env(name: str, default: str | None = None) -> str:
    val = os.getenv(name, default)
    if val is None or val == "":
        raise RuntimeError(f"Missing required env var: {name}")
    return val

class Settings:
    def __init__(self) -> None:
        self.env = os.getenv("ENV", "dev")
        self.region = get_env("AWS_REGION", "us-west-2")
        self.stream_name = os.getenv("KINESIS_STREAM", f"riotlake-{self.env}-matches-raw")
        self.secret_name = os.getenv("SECRET_NAME", f"riotlake/{self.env}/api-key")
        self.riot_base_url = os.getenv("RIOT_BASE_URL", "https://americas.api.riotgames.com")