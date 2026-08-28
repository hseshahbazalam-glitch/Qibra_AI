"""Phase 8 — notifications local only; no exact alarm requirement."""

import os
import sys
from pathlib import Path

from fastapi.testclient import TestClient

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
os.environ.setdefault("DATABASE_URL", "sqlite+pysqlite:///:memory:")

from app.db.session import reset_engine
from app.main import app


def test_notifications_local_only_flag():
    reset_engine("sqlite+pysqlite:///:memory:")
    with TestClient(app) as client:
        flags = client.get("/health").json()["flags"]
        assert flags["notifications_local_only"] is True
