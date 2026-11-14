"""QB-011 — `/ai/ask` is a paid-for resource: it needs a token, every field is bounded,
and one user cannot spend the shared Groq budget.

Red first: at 9aedc87 the endpoint is deliberately public (`test_ask_does_not_require_auth`
pinned it), `query` is an unbounded `str`, the corpus is bounded by ITEM COUNT ONLY (so
32 items × any length is fine), and there is no per-user quota — an anonymous caller can
drive it forever.
"""

import json

from app.config import Settings
from app.routers.ai import (
    MAX_CORPUS_TEXT_CHARS,
    MAX_HISTORY_CONTENT_CHARS,
    MAX_QUERY_CHARS,
)
from app.services.ai_quota import AI_ASK_LIMIT, AI_ASK_WINDOW_SECONDS
from helpers import fresh_client, login, register

SMALL_CORPUS = [{"text": "Allah is most merciful", "source": "Quran 1:1"}]


def _ask(client, headers=None, **body):
    return client.post(
        "/ai/ask", json={"query": "merciful", "corpus": SMALL_CORPUS, **body}, headers=headers
    )


def _auth(client, email="ask@e.com") -> dict:
    register(client, email=email)
    return {"Authorization": f"Bearer {login(client, email=email).json()['access_token']}"}


def test_unauthenticated_is_401_with_an_honest_body():
    with fresh_client() as client:
        r = _ask(client)
        assert r.status_code == 401
        assert r.json()["detail"] == "auth_required"
        assert "sign in" in json.dumps(r.json()).lower()


def test_a_structured_detail_is_returned_flat_not_nested():
    """The contract is one flat object per error: {"detail": code, ...extra}. A
    dependency that wanted to add a hint must not produce detail.detail."""
    with fresh_client() as client:
        body = _ask(client).json()
        assert body["detail"] == "auth_required"
        assert isinstance(body.get("hint"), str) and len(body["hint"]) > 20


def test_a_bearer_token_of_any_shape_is_still_validated():
    with fresh_client() as client:
        assert _ask(client, headers={"Authorization": "Bearer nonsense"}).status_code == 401
        assert _ask(client, headers={"Authorization": "Token x"}).status_code == 401


def test_a_valid_access_token_answers_normally():
    with fresh_client() as client:
        r = _ask(client, headers=_auth(client))
        assert r.status_code == 200, r.text
        assert r.json()["citations"] == ["Quran 1:1"]
        assert r.headers["Cache-Control"] == "no-store"


def test_streaming_needs_the_token_too():
    with fresh_client() as client:
        with client.stream("POST", "/ai/ask", json={"query": "x", "corpus": []}) as r:
            assert r.status_code == 401


def test_query_is_bounded_and_the_boundary_is_pinned():
    with fresh_client() as client:
        auth = _auth(client)
        assert _ask(client, auth, query="q" * MAX_QUERY_CHARS).status_code == 200
        over = _ask(client, auth, query="q" * (MAX_QUERY_CHARS + 1))
        assert over.status_code == 422
        assert "query" in json.dumps(over.json())
        assert _ask(client, auth, query="").status_code in (200, 400, 422)


def test_every_corpus_field_is_bounded_not_just_the_item_count():
    caps = {
        "text": MAX_CORPUS_TEXT_CHARS,
        "source": 200,
        "reference": 200,
        "collection": 32,
        "verification_status": 32,
    }
    with fresh_client() as client:
        for field, cap in caps.items():
            base = {"text": "Allah is merciful", "source": "Quran 1:1"}
            ok = _ask(client, _auth(client, email=f"cap-{field}@e.com"), corpus=[{**base, field: "a" * cap}])
            assert ok.status_code == 200, (field, cap, ok.status_code, ok.text[:120])
            over = _ask(
                client,
                _auth(client, email=f"over-{field}@e.com"),
                corpus=[{**base, field: "a" * (cap + 1)}],
            )
            assert over.status_code == 422, (field, over.status_code, over.text[:160])
            assert field in json.dumps(over.json())


def test_history_messages_are_bounded():
    with fresh_client() as client:
        auth = _auth(client)
        ok = _ask(client, auth, history=[{"role": "user", "content": "h" * MAX_HISTORY_CONTENT_CHARS}])
        assert ok.status_code == 200, ok.text[:160]
        over = _ask(client, auth, history=[{"role": "user", "content": "h" * (MAX_HISTORY_CONTENT_CHARS + 1)}])
        assert over.status_code == 422


def test_a_corpus_item_cannot_smuggle_unbounded_other_keys():
    with fresh_client() as client:
        auth = _auth(client)
        blob = "a" * 4000
        over = _ask(client, auth, corpus=[{f"k{i}": blob for i in range(24)}])
        assert over.status_code == 422, (over.status_code, over.text[:200])
        # a dict in a text field must not smuggle an unbounded payload past the cap
        nested = _ask(client, _auth(client, "nested@e.com"),
                      corpus=[{"text": {"nested": "x" * (MAX_CORPUS_TEXT_CHARS + 10)}, "source": "s"}])
        assert nested.status_code == 422, (nested.status_code, nested.text[:200])


def test_per_user_quota_answers_429_with_an_honest_body():
    with fresh_client() as client:
        auth = _auth(client)
        codes = [_ask(client, auth).status_code for _ in range(AI_ASK_LIMIT)]
        assert codes == [200] * AI_ASK_LIMIT, codes
        limited = _ask(client, auth)
        assert limited.status_code == 429
        body = limited.json()
        assert body["detail"] == "ai_quota_exceeded"
        assert body["limit"] == AI_ASK_LIMIT
        assert body["window_seconds"] == AI_ASK_WINDOW_SECONDS
        assert 0 < body["retry_after_seconds"] <= AI_ASK_WINDOW_SECONDS
        assert limited.headers["retry-after"] == str(body["retry_after_seconds"])
        # the refusal is a real response: same headers as everything else
        assert limited.headers["x-content-type-options"] == "nosniff"
        assert limited.headers["x-request-id"]


def test_the_quota_is_per_user_not_global():
    with fresh_client() as client:
        mine = _auth(client, email="quota-a@e.com")
        theirs = _auth(client, email="quota-b@e.com")
        for _ in range(AI_ASK_LIMIT):
            assert _ask(client, mine).status_code == 200
        assert _ask(client, mine).status_code == 429
        assert _ask(client, theirs).status_code == 200


def test_quota_constants_are_the_documented_ones_and_env_overridable():
    assert (AI_ASK_LIMIT, AI_ASK_WINDOW_SECONDS) == (20, 60)
    assert Settings.ai_ask_limit == 20
    from app.services.ai_quota import QuotaLedger

    ledger = QuotaLedger(limit=2, window_seconds=60)
    assert ledger.take("u") is None
    assert ledger.take("u") is None
    wait = ledger.take("u")
    assert wait is not None and 0 < wait <= 60
    assert ledger.take("other") is None  # per-user, not shared


def test_the_guard_is_on_the_router_not_only_in_the_model():
    """A source pin: /ai/ask must depend on the auth dependency, and the caps must be
    declared on the request model (so a new field cannot arrive unbounded by accident)."""
    from pathlib import Path

    source = (
        Path(__file__).resolve().parents[1] / "app" / "routers" / "ai.py"
    ).read_text(encoding="utf-8")
    assert "Depends(ask_user_id)" in source
    assert "bearer_subject" in source  # shared parser, not a re-implementation
    assert "max_length=MAX_QUERY_CHARS" in source
