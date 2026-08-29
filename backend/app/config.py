"""Runtime flags. Production-ready flags stay FALSE until documented otherwise."""

import os
from functools import lru_cache


_INSECURE_JWT = frozenset(
    {"", "dev-only-change-me", "replace-me", "changeme", "secret"}
)


def _jwt_secret() -> str:
    """Never treat the local fallback as a production secret.

    Set JWT_SECRET in backend/.env (see .env.example). Tests set it in conftest.
    Empty / well-known values are refused when QIBRA_ENV is production.
    Otherwise the fallback is an explicit dev-only sentinel, not a deploy secret.
    """
    value = os.environ.get("JWT_SECRET", "").strip()
    env = os.environ.get("QIBRA_ENV", "").strip().lower()
    if env in {"prod", "production"} and value in _INSECURE_JWT:
        raise RuntimeError("JWT_SECRET must be set to a non-default value in production")
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
