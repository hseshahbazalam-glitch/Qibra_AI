from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="QIBRA_", extra="ignore")

    env: str = "development"
    secret_key: str = "dev-only-secret"
    billing_webhook_secret: str = "dev-webhook-secret"
    token_minutes: int = 60 * 24 * 7
    app_name: str = "Qibra API"
    version: str = "0.6.0"


@lru_cache
def get_settings() -> Settings:
    return Settings()
