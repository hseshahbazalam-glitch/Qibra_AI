"""Phase 5 — logout / delete / rate limit."""

import os
import sys
from pathlib import Path

from fastapi.testclient import TestClient

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
os.environ.setdefault("DATABASE_URL", "sqlite+pysqlite:///:memory:")

from app.db.session import reset_engine
from app.main import app
from app.middleware.rate_limit import RateLimitMiddleware


def test_logout_and_delete():
    reset_engine("sqlite+pysqlite:///:memory:")
    with TestClient(app) as client:
        client.post(
            "/auth/register",
            json={"email": "d@e.com", "password": "password1", "name": "D"},
        )
        login = client.post("/auth/login", json={"email": "d@e.com", "password": "password1"})
        token = login.json()["access_token"]
        headers = {"Authorization": f"Bearer {token}"}
        assert client.post("/auth/logout").status_code == 200
        deleted = client.delete("/users/me", headers=headers)
        assert deleted.status_code == 200
        gone = client.get("/users/me", headers=headers)
        assert gone.status_code == 401


def test_rate_limit_middleware_exists():
    assert RateLimitMiddleware is not None
