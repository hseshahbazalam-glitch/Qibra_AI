"""Phase 15 — RAG honesty + security headers."""

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


def test_ai_refuse_and_headers():
    reset_engine("sqlite+pysqlite:///:memory:")
    with TestClient(app) as client:
        r = client.post("/ai/ask", json={"query": "xyz", "corpus": []})
        assert r.status_code == 200
        assert r.json()["refused"] is True
        health = client.get("/health")
        assert health.headers.get("X-Content-Type-Options") == "nosniff"
        assert health.headers.get("X-Request-Id")
    hit = answer("merciful", [{"text": "Allah is most merciful", "source": "Quran 1:1"}])
    assert hit["refused"] is False
    assert hit["verified"] is False
