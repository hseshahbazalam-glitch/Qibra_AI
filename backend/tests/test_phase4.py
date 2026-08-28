"""Phase 4 — auth + SQLAlchemy user data."""

import os
import sys
from pathlib import Path

from fastapi.testclient import TestClient

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
os.environ.setdefault("DATABASE_URL", "sqlite+pysqlite:///:memory:")

from app.db.session import reset_engine
from app.main import app
from app.security import hash_password, verify_password


def test_password_is_hashed():
    stored = hash_password("password1")
    assert "password1" not in stored
    assert verify_password("password1", stored)
    assert not verify_password("nope", stored)


def test_register_login_me():
    reset_engine("sqlite+pysqlite:///:memory:")
    with TestClient(app) as client:
        r = client.post(
            "/auth/register",
            json={"email": "user@example.com", "password": "password1", "name": "U"},
        )
        assert r.status_code == 200
        login = client.post(
            "/auth/login", json={"email": "user@example.com", "password": "password1"}
        )
        assert login.status_code == 200
        token = login.json()["access_token"]
        me = client.get("/users/me", headers={"Authorization": f"Bearer {token}"})
        assert me.status_code == 200
        assert me.json()["email"] == "user@example.com"
        assert me.json()["is_premium"] is False
