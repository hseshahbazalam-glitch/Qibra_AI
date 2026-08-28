"""Phase 10 — billing unconfigured; never trust client JSON."""

from helpers import fresh_client
from app.services.billing_service import BillingService
from app.services.store_verify import StoreVerifier


def test_billing_status_unconfigured():
    with fresh_client() as client:
        r = client.get("/billing/status")
        assert r.status_code == 200
        assert r.json()["store"] == "unconfigured"
        assert r.json()["is_premium"] is False
        assert r.json()["billing_production_ready"] is False


def test_verify_receipt_rejected():
    with fresh_client() as client:
        v = client.post("/billing/verify")
        assert v.status_code == 200
        assert v.json()["ok"] is False
        assert v.json()["is_premium"] is False
        assert v.json()["reason"] == "store_unconfigured"


def test_entitlement_ignores_true_json():
    entitlement = BillingService().entitlement_from_json({"is_premium": True})
    assert entitlement.is_premium is False
    assert entitlement.source == "unconfigured"


def test_entitlement_ignores_nested_flags():
    entitlement = BillingService().entitlement_from_json(
        {"user": {"isPremium": True}, "receipt": "abc"}
    )
    assert entitlement.is_premium is False


def test_store_verifier_not_configured():
    v = StoreVerifier()
    assert v.configured is False
    assert v.verify("any-receipt") is False


def test_empty_receipt_still_false():
    assert StoreVerifier().verify("") is False


def test_health_billing_flag_false():
    with fresh_client() as client:
        assert client.get("/health").json()["flags"]["billing_production_ready"] is False


def test_me_is_premium_false_even_after_verify():
    from helpers import bearer

    with fresh_client() as client:
        headers = bearer(client)
        client.post("/billing/verify")
        me = client.get("/users/me", headers=headers).json()
        assert me["is_premium"] is False


def test_status_never_says_production_ready():
    status = BillingService().status()
    assert status["billing_production_ready"] is False
    assert status["is_premium"] is False
