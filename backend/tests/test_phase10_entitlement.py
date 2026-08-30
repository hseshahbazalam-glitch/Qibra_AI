"""Phase 10 — entitlement states. Production verifier never sets verified=True."""

from datetime import datetime, timedelta

from helpers import fresh_client
from app.services.billing_service import BillingService
from app.services.entitlement import (
    ACTIVE,
    CANCELLED,
    EXPIRED,
    IN_GRACE,
    REFUNDED,
    REVOKED,
    derive,
)
from app.services.store_verify import StoreVerifier

NOW = datetime(2026, 8, 31, 12, 0, 0)


def test_unverified_never_premium_even_if_state_active():
    ent = derive(verified=False, now=NOW, state=ACTIVE, expires_at=NOW + timedelta(days=30))
    assert ent.is_premium is False
    assert ent.server_validated is False


def test_verified_active_then_expiry_and_grace():
    exp = NOW + timedelta(days=1)
    grace = NOW + timedelta(days=4)
    active = derive(verified=True, now=NOW, state=ACTIVE, source="test", expires_at=exp, grace_ends_at=grace)
    assert active.is_premium is True
    assert active.state == ACTIVE
    late = derive(
        verified=True,
        now=exp + timedelta(hours=1),
        state=ACTIVE,
        source="test",
        expires_at=exp,
        grace_ends_at=grace,
    )
    assert late.is_premium is True
    assert late.state == IN_GRACE
    dead = derive(
        verified=True,
        now=grace + timedelta(seconds=1),
        state=IN_GRACE,
        source="test",
        expires_at=exp,
        grace_ends_at=grace,
    )
    assert dead.is_premium is False
    assert dead.state == EXPIRED


def test_cancelled_keeps_access_until_expiry():
    exp = NOW + timedelta(days=7)
    ent = derive(verified=True, now=NOW, state=CANCELLED, source="test", expires_at=exp)
    assert ent.is_premium is True
    assert ent.state == CANCELLED
    after = derive(verified=True, now=exp + timedelta(seconds=1), state=CANCELLED, source="test", expires_at=exp)
    assert after.is_premium is False
    assert after.state == EXPIRED


def test_refund_and_revoke_drop_premium():
    exp = NOW + timedelta(days=30)
    for state in (REFUNDED, REVOKED):
        ent = derive(verified=True, now=NOW, state=state, source="test", expires_at=exp)
        assert ent.is_premium is False
        assert ent.state == state


def test_production_verifier_cannot_grant():
    assert StoreVerifier().configured is False
    assert StoreVerifier().verify("Ek-fake-receipt") is False
    result = StoreVerifier().verify_purchase("Ek-fake-receipt", "android")
    assert result.verified is False
    assert result.reason == "store_unconfigured"


def test_restore_and_verify_routes_unconfigured():
    with fresh_client() as client:
        r = client.post("/billing/restore")
        assert r.status_code == 200
        body = r.json()
        assert body["ok"] is False
        assert body["is_premium"] is False
        assert body["purchases"] == []
        v = client.post("/billing/verify", json={"receipt": "abc", "is_premium": True})
        assert v.json()["ok"] is False
        assert v.json()["is_premium"] is False
        assert v.json()["server_validated"] is False


def test_json_cannot_mint_offline_grant():
    ent = BillingService().entitlement_from_json({"is_premium": True, "state": "active"})
    assert ent.is_premium is False
    assert ent.source == "unconfigured"
