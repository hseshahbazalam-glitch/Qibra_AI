from functools import lru_cache

from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """Runtime configuration. Secrets are supplied only through environment variables."""

    model_config = SettingsConfigDict(env_prefix="QIBRA_", extra="ignore")

    env: str = "development"
    secret_key: str = "dev-only-secret"
    billing_webhook_secret: str = "dev-webhook-secret"
    token_minutes: int = 60 * 24 * 7
    cors_origins: str = ""
    app_name: str = "Qibra API"
    version: str = "0.6.0"

    @field_validator("secret_key")
    @classmethod
    def validate_secret(cls, value: str) -> str:
        # A development default is useful for local/tests only. Production must
        # intentionally provide a high-entropy signing secret.
        if value.strip() == "":
            raise ValueError("QIBRA_SECRET_KEY must not be empty")
        return value

    @property
    def is_development(self) -> bool:
        return self.env.lower() in {"development", "dev", "test", "testing"}

    @property
    def allowed_origins(self) -> list[str]:
        configured = [item.strip() for item in self.cors_origins.split(",") if item.strip()]
        if configured:
            return configured
        # Never use wildcard CORS. A browser client must be explicitly configured
        # for staging/production; local origins are adequate for development.
        return ["http://localhost:3000", "http://localhost:5173"] if self.is_development else []

    def assert_secure_production(self) -> None:
        weak = {"dev-only-secret", "change-me", "", "dev-webhook-secret", "change-me-webhook"}
        if not self.is_development and (len(self.secret_key) < 32 or self.secret_key in weak):
            raise RuntimeError("QIBRA_SECRET_KEY must be at least 32 non-placeholder characters in production")
        if not self.is_development and self.billing_webhook_secret in weak:
            raise RuntimeError("QIBRA_BILLING_WEBHOOK_SECRET must be configured in production")


@lru_cache
def get_settings() -> Settings:
    return Settings()
