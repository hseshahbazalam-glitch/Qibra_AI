"""Runtime flags. Production-ready flags stay FALSE until documented otherwise."""

import os
from functools import lru_cache


def _jwt_secret() -> str:
    """Never treat the local fallback as a production secret.

    Set JWT_SECRET in backend/.env (see .env.example). Tests set it in conftest.
    """
    value = os.environ.get("JWT_SECRET", "").strip()
    if value:
        return value
    return "dev-only-change-me"


class Settings:
    app_name: str = "Qibra API"
    version: str = "0.6.0"
    jwt_secret: str = _jwt_secret()
    jwt_algorithm: str = "HS256"
    access_token_minutes: int = 60
    database_url: str = os.environ.get("DATABASE_URL", "sqlite+pysqlite:///:memory:")

    auth_production_ready: bool = False
    content_production_ready: bool = False
    billing_production_ready: bool = False
    analytics_production_ready: bool = False
    notifications_local_only: bool = True
    precise_location_stored_on_server: bool = False


@lru_cache
def get_settings() -> Settings:
    return Settings()
