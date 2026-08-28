"""Phase 10 — billing stubs unconfigured."""

import os
import sys
from pathlib import Path

from fastapi.testclient import TestClient

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))
os.environ.setdefault("DATABASE_URL", "sqlite+pysqlite:///:memory:")

from app.db.session import reset_engine
from app.main import app
from app.services.billing_service import BillingService


def test_billing_unconfigured():
    reset_engine("sqlite+pysqlite:///:memory:")
    with TestClient(app) as client:
        r = client.get("/billing/status")
        assert r.status_code == 200
        assert r.json()["store"] == "unconfigured"
        assert r.json()["is_premium"] is False
        v = client.post("/billing/verify")
        assert v.json()["ok"] is False
    entitlement = BillingService().entitlement_from_json({"is_premium": True})
    assert entitlement.is_premium is False
