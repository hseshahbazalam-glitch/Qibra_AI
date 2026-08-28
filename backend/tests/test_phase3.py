"""Phase 3 — foundations: health, flags, edition honesty."""

import os
import sys
from pathlib import Path

from fastapi.testclient import TestClient

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
os.environ.setdefault("DATABASE_URL", "sqlite+pysqlite:///:memory:")

from app.db.session import reset_engine
from app.main import app
from app.rag import answer


def test_health_version_and_flags():
    reset_engine("sqlite+pysqlite:///:memory:")
    with TestClient(app) as client:
        r = client.get("/health")
        assert r.status_code == 200
        body = r.json()
        assert body["version"] == "0.6.0"
        flags = body["flags"]
        assert flags["auth_production_ready"] is False
        assert flags["content_production_ready"] is False
        assert flags["billing_production_ready"] is False
        assert flags["analytics_production_ready"] is False
        assert flags["notifications_local_only"] is True
        assert flags["precise_location_stored_on_server"] is False


def test_rag_refuses_without_passage():
    result = answer("unknown topic xyz", [])
    assert result["refused"] is True
    assert result["answer"] is None
