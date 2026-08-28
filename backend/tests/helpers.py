"""Shared TestClient helpers. Each test should call fresh_client()."""

from __future__ import annotations

import os
import sys
from pathlib import Path

from fastapi.testclient import TestClient

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
os.environ.setdefault("DATABASE_URL", "sqlite+pysqlite:///:memory:")
os.environ.setdefault("JWT_SECRET", "test-secret")

from app.db.session import reset_engine  # noqa: E402
from app.main import app  # noqa: E402


def fresh_client() -> TestClient:
    reset_engine("sqlite+pysqlite:///:memory:")
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
