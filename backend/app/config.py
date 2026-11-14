"""Runtime flags AND the boot guards that refuse a silently-insecure configuration.

Two rules shape this file after the QB-cluster audit:

* The two values that decide *security* rather than convenience — the signing secret
  and the database — have no silent default. A missing one is a boot failure in every
  environment, because a deployment that misreads the dashboard must refuse to start
  rather than serve an API signed with a published key on an ephemeral database.
* ``QIBRA_ENV=dev`` is an explicit opt-in for the convenience branches (an in-memory
  database, a loud banner). Unset is NOT dev — it is treated as strict, so forgetting
  to set it fails closed instead of open.

Production-ready flags stay FALSE until documented otherwise.
"""

import os
import sys
from functools import lru_cache

MIN_JWT_SECRET_BYTES = 32

# Values that have appeared in tutorials and copied dotfiles. The length rule below
# already catches every one of them; the list stays so a padded copy of a placeholder
# ("changeme-----------------") is refused too. Note there is deliberately NO fallback
# secret in this module — an unset JWT_SECRET is an error, not a default.
_INSECURE_JWT = frozenset(
    {
        "replace-me",
        "changeme",
        "secret",
        "password",
        "your-secret-here",
        "change-me",
    }
)
_DEV_VALUES = frozenset({"dev", "development"})

_SQLITE_SCHEMES = ("sqlite", "sqlite+pysqlite")


class BootConfigError(RuntimeError):
    """The process must not serve traffic. A ``RuntimeError`` subclass so anything
    already catching startup failures keeps catching this."""


def _lookup(env, name: str) -> str:
    if env is None:
        env = os.environ
    return (env.get(name) or "").strip()


def dev_mode(env=None) -> bool:
    """True only when QIBRA_ENV explicitly says so."""
    return _lookup(env, "QIBRA_ENV").lower() in _DEV_VALUES


def jwt_secret_or_raise(env=None) -> str:
    """A real signing key, or no boot. Length is NOT relaxed in dev mode (QB-001)."""
    value = _lookup(env, "JWT_SECRET")
    if not value:
        raise BootConfigError(
            "JWT_SECRET is not set. Generate one (e.g. `python -c \"import secrets;"
            "print(secrets.token_urlsafe(48))\"`) and put it in the environment."
            " There is no fallback secret in the code."
        )
    length = len(value.encode("utf-8"))
    if length < MIN_JWT_SECRET_BYTES:
        raise BootConfigError(
            f"JWT_SECRET is too short: {length} bytes, minimum is "
            f"{MIN_JWT_SECRET_BYTES}. This applies in every QIBRA_ENV, dev included."
        )
    if value.lower() in _INSECURE_JWT:
        raise BootConfigError("JWT_SECRET is a well-known placeholder; set a random one.")
    return value


def database_url_or_raise(env=None) -> str:
    """A real database URL, or no boot. SQLite is a dev-only convenience (QB-004)."""
    value = _lookup(env, "DATABASE_URL")
    if not value:
        raise BootConfigError(
            "DATABASE_URL is not set. Point it at the managed Postgres database. "
            "There is no default URL in the code — an ephemeral in-memory database "
            "silently replacing a misconfigured one is how accounts get lost."
        )
    if value.startswith(_SQLITE_SCHEMES) and not dev_mode(env):
        raise BootConfigError(
            "DATABASE_URL points at SQLite. SQLite is only allowed when QIBRA_ENV=dev "
            "(and it must then be an explicit in-memory or scratch file); production "
            "needs PostgreSQL, otherwise every restart wipes the accounts."
        )
    return value


def database_summary(url: str) -> dict:
    """What /health may say about the database: its type, and whether it is ephemeral.

    Never the URL. Credentials, host, port and database name stay out of a
    publicly-readable endpoint.
    """
    scheme = (url or "").split(":", 1)[0].split("+")[0].strip().lower()
    return {
        "type": scheme or "unknown",
        "in_memory": ":memory:" in (url or ""),
    }


def startup_notes(env=None) -> list:
    """Operator-facing lines printed once per boot. The dev line is a warning; the
    GROQ line is the honest statement of which AI level this process serves."""
    notes = []
    if dev_mode(env):
        notes.append(
            "QIBRA_ENV=dev — convenience mode is ON: SQLite is allowed and data "
            "lives only as long as the process. Never deploy like this."
        )
    if _lookup(env, "GROQ_API_KEY"):
        notes.append("GROQ_API_KEY is set: /ai/ask answers from the model.")
    else:
        notes.append(
            "GROQ_API_KEY is absent: /ai/ask degrades to the deterministic extractive "
            "path (level 0), which is a valid posture, not an error."
        )
    return notes


class Settings:
    app_name: str = "Qibra API"
    version: str = "0.6.0"
    jwt_algorithm: str = "HS256"
    access_token_minutes: int = 15
    auth_production_ready: bool = False
    content_production_ready: bool = False
    billing_production_ready: bool = False
    analytics_production_ready: bool = False
    notifications_local_only: bool = True
    precise_location_stored_on_server: bool = False

    def __init__(self, env=None) -> None:
        # Both security-critical values go through the guards. A bare Settings()
        # therefore validates exactly like a real boot.
        self.jwt_secret = jwt_secret_or_raise(env)
        self.database_url = database_url_or_raise(env)
        self.refresh_token_days = int(_lookup(env, "REFRESH_TOKEN_DAYS") or "30")
        # Groq (LLM) — the API key lives ONLY in the environment (Render env var
        # GROQ_API_KEY). Never a default, never a file, never logged.
        self.groq_api_key = _lookup(env, "GROQ_API_KEY")
        self.groq_model = _lookup(env, "GROQ_MODEL") or "llama-3.3-70b-versatile"
        self.groq_timeout_seconds = float(
            _lookup(env, "GROQ_TIMEOUT_SECONDS") or "30"
        )
        self.dev = dev_mode(env)

    def print_startup_notes(self, stream=None) -> None:
        """One visible block per boot — the dev opt-in is allowed to be loud."""
        notes = startup_notes()
        if not notes:
            return
        out = stream or sys.stderr
        bar = "=" * 68
        out.write(f"\n{bar}\n")
        for note in notes:
            out.write(f"  QIBRA  {note}\n")
        out.write(f"{bar}\n\n")


@lru_cache
def get_settings() -> Settings:
    settings = Settings()
    if settings.dev:
        settings.print_startup_notes()
    return settings
