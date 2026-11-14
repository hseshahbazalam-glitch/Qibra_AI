"""Shared TestClient helpers. Each test should call fresh_client()."""

from __future__ import annotations

import os
import sys
from pathlib import Path

from fastapi.testclient import TestClient

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
# Same declaration as conftest.py — helpers.py is also importable as a first module
# (a test that imports only helpers must still boot the app), so it cannot depend on
# conftest having run first. Both must stay in sync with tests/test_qb001_boot_guards.py.
os.environ.setdefault("QIBRA_ENV", "dev")
os.environ.setdefault("DATABASE_URL", "sqlite+pysqlite:///:memory:")
os.environ.setdefault("JWT_SECRET", "qibra-test-only-signing-secret-32b+")

from app.db.session import reset_engine  # noqa: E402
from app.main import app  # noqa: E402
from app.middleware.rate_limit import reset_rate_limit_store  # noqa: E402
from app.observability.metrics import reset_metrics  # noqa: E402


def fresh_client() -> TestClient:
    reset_engine("sqlite+pysqlite:///:memory:")
    reset_rate_limit_store()
    reset_metrics()
    return TestClient(app)


def register(
    client: TestClient,
    email: str = "user@example.com",
    password: str = "password1",
    name: str = "U",
):
    return client.post(
        "/auth/register",
        json={"email": email, "password": password, "name": name},
    )


def login(client: TestClient, email: str = "user@example.com", password: str = "password1"):
    return client.post("/auth/login", json={"email": email, "password": password})


def bearer(client: TestClient, email: str = "user@example.com", password: str = "password1", name: str = "U") -> dict[str, str]:
    register(client, email, password, name)
    token = login(client, email, password).json()["access_token"]
    return {"Authorization": f"Bearer {token}"}
