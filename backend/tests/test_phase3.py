"""Phase 3 — foundations: health, flags, headers, RAG honesty."""

from helpers import fresh_client
from app.config import Settings, get_settings
from app.rag import answer, retrieve


def test_health_ok():
    with fresh_client() as client:
        r = client.get("/health")
        assert r.status_code == 200
        assert r.json()["status"] == "ok"


def test_health_version_0_6_0():
    with fresh_client() as client:
        assert client.get("/health").json()["version"] == "0.6.0"


def test_production_ready_flags_are_false():
    with fresh_client() as client:
        flags = client.get("/health").json()["flags"]
        assert flags["auth_production_ready"] is False
        assert flags["content_production_ready"] is False
        assert flags["billing_production_ready"] is False
        assert flags["analytics_production_ready"] is False


def test_notifications_local_only_true():
    with fresh_client() as client:
        assert client.get("/health").json()["flags"]["notifications_local_only"] is True


def test_precise_location_not_stored():
    with fresh_client() as client:
        assert client.get("/health").json()["flags"]["precise_location_stored_on_server"] is False


def test_settings_defaults_match_health():
    s = Settings()
    assert s.version == "0.6.0"
    assert s.auth_production_ready is False
    assert get_settings().version == "0.6.0"


def test_security_headers_on_health():
    with fresh_client() as client:
        r = client.get("/health")
        assert r.headers["X-Content-Type-Options"] == "nosniff"
        assert r.headers["X-Frame-Options"] == "DENY"
        assert r.headers["Referrer-Policy"] == "no-referrer"
        assert r.headers["Cache-Control"] == "no-store"


def test_request_id_echo_and_generate():
    with fresh_client() as client:
        echoed = client.get("/health", headers={"x-request-id": "abc-123"})
        assert echoed.headers["X-Request-Id"] == "abc-123"
        generated = client.get("/health")
        assert generated.headers.get("X-Request-Id")


def test_rag_refuses_without_passage():
    result = answer("unknown topic xyz", [])
    assert result["refused"] is True
    assert result["answer"] is None
    assert result["reason"] == "no_retrieved_passage"


def test_rag_empty_query_retrieves_nothing():
    assert retrieve("   ", [{"text": "Allah is most merciful"}]) == []


def test_rag_does_not_claim_verified():
    hit = answer("merciful", [{"text": "Allah is most merciful", "source": "Quran 1:1"}])
    assert hit["refused"] is False
    assert hit["verified"] is False
    assert "Verified Qibra sources" not in str(hit)
