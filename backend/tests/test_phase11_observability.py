"""Phase 11 — allowlist, redaction, metrics. Consent still default OFF."""

from app.observability.allowlist import is_allowed
from app.observability.local import Observability
from app.observability.metrics import inc, reset_metrics, snapshot
from app.observability.redact import redact
from app.rag import answer
from helpers import fresh_client


def test_unknown_event_not_recorded_even_with_consent():
    obs = Observability(consent=True)
    obs.record("random_debug_dump")
    assert obs.events == []


def test_allowlist_still_blocks_banned_substrings():
    assert is_allowed("email_leaked") is False
    assert is_allowed("opened_home") is True


def test_redact_email_token_geo():
    text = redact("user@example.com bearer abc.def lat=21.3891")
    assert "user@example.com" not in text
    assert "21.3891" not in text
    assert "[redacted-email]" in text
    assert "[redacted-geo]" in text


def test_metrics_ignore_forbidden_names():
    reset_metrics()
    inc("gps_fix")
    inc("rag_no_context")
    body = snapshot()
    assert "gps_fix" not in body["counters"]
    assert body["counters"]["rag_no_context"] == 1
    assert body["analytics_production_ready"] is False
    assert body["consent_default"] is False
    assert body["third_party_sdks"] == []


def test_health_metrics_endpoint_has_no_pii():
    with fresh_client() as client:
        client.get("/health")
        r = client.get("/health/metrics")
        assert r.status_code == 200
        blob = str(r.json()).lower()
        assert "sentry" not in blob
        assert "mixpanel" not in blob
        assert "firebase" not in blob
        assert r.json()["analytics_production_ready"] is False
        assert "email" not in blob
        assert "gps" not in blob
        assert r.json()["counters"]["api_request"] >= 1


def test_rag_increments_no_context():
    reset_metrics()
    answer("zzzz-no-hit", [{"text": "mercy in a verse", "source": "local"}])
    assert snapshot()["counters"]["rag_no_context"] == 1


def test_billing_status_increments_unconfigured():
    with fresh_client() as client:
        client.get("/billing/status")
        metrics = client.get("/health/metrics").json()["counters"]
        assert metrics.get("billing_unconfigured", 0) >= 1
