"""Phase 15 — RAG honesty + security headers."""

from helpers import fresh_client
from app.rag import answer, retrieve


def test_ask_refuses_empty_corpus():
    with fresh_client() as client:
        r = client.post("/ai/ask", json={"query": "xyz", "corpus": []})
        assert r.status_code == 200
        assert r.json()["refused"] is True
        assert r.json()["answer"] is None


def test_ask_returns_passage_not_verified():
    with fresh_client() as client:
        r = client.post(
            "/ai/ask",
            json={
                "query": "merciful",
                "corpus": [{"text": "Allah is most merciful", "source": "Quran 1:1"}],
            },
        )
        body = r.json()
        assert body["refused"] is False
        assert body["verified"] is False
        assert body["answer"] == "Allah is most merciful"
        assert "Quran 1:1" in body["citations"]


def test_never_claims_verified_qibra_sources():
    hit = answer("merciful", [{"text": "Allah is most merciful", "source": "Quran 1:1"}])
    assert "Verified Qibra sources" not in str(hit)
    assert hit["verified"] is False


def test_retrieve_miss_is_empty():
    assert retrieve("qibla-angle-invented", [{"text": "prayer times"}]) == []


def test_empty_query_refuses():
    assert answer("  ", [{"text": "Allah is most merciful"}])["refused"] is True


def test_security_headers():
    with fresh_client() as client:
        health = client.get("/health")
        assert health.headers.get("X-Content-Type-Options") == "nosniff"
        assert health.headers.get("X-Frame-Options") == "DENY"
        assert health.headers.get("X-Request-Id")


def test_ask_does_not_require_auth():
    with fresh_client() as client:
        r = client.post("/ai/ask", json={"query": "x", "corpus": []})
        assert r.status_code == 200


def test_multiple_citations():
    hit = answer(
        "allah",
        [
            {"text": "Allah is one", "source": "Quran 112:1"},
            {"text": "Allah is most merciful", "source": "Quran 1:1"},
        ],
    )
    assert hit["refused"] is False
    assert len(hit["citations"]) == 2


def test_health_auth_not_production():
    with fresh_client() as client:
        assert client.get("/health").json()["flags"]["auth_production_ready"] is False


def test_no_store_on_ask():
    with fresh_client() as client:
        r = client.post("/ai/ask", json={"query": "x", "corpus": []})
        assert r.headers["Cache-Control"] == "no-store"
