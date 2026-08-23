"""Runtime configuration. Secrets come from the environment only."""

from __future__ import annotations

from functools import lru_cache
from pathlib import Path

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


BACKEND_ROOT = Path(__file__).resolve().parents[2]
REPO_ROOT = BACKEND_ROOT.parent


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_prefix="QIBRA_",
        env_file=str(BACKEND_ROOT / ".env"),
        extra="ignore",
    )

    env: str = "development"
    host: str = "0.0.0.0"
    port: int = 8000
    jwt_secret: str = "qibra-dev-only-change-me"
    jwt_expire_minutes: int = 60
    database_path: Path = Field(default=BACKEND_ROOT / "data" / "qibra.db")
    assets_root: Path = Field(default=REPO_ROOT / "assets" / "data")
    cors_origins: str = "*"
    llm_api_key: str = ""
    llm_base_url: str = ""

    @property
    def is_production(self) -> bool:
        return self.env.lower() == "production"

    @property
    def cors_origin_list(self) -> list[str]:
        if self.cors_origins.strip() == "*":
            return ["*"]
        return [item.strip() for item in self.cors_origins.split(",") if item.strip()]

    @property
    def dua_catalog_path(self) -> Path:
        return Path(__file__).resolve().parents[1] / "data" / "duas.json"


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    settings = Settings()
    settings.database_path.parent.mkdir(parents=True, exist_ok=True)
    return settings
