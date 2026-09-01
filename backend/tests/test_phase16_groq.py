"""Phase 16 — /ai/ask level 1: Groq path with mocked upstream.

The real Groq API is NEVER called from tests (key lives only on Render).
"""

import json

import pytest

from app import groq_client
from helpers import fresh_client

CORPUS = [{"text": "Allah is most merciful", "source": "Quran 1:1"}]


def _ask(client, **kw):
    body = {"query": "merciful", "corpus": CORPUS, **kw}
    return client.post("/ai/ask", json=body)


def test_no_key_means_extractive_passthrough(monkeypatch):
    monkeypatch.setattr(groq_client, "enabled", lambda: False)
    with fresh_client() as client:
        body = _ask(client).json()
    assert body["refused"] is False
    assert body["answer"] == "Allah is most merciful"
    assert "grounded_model" not in body or body.get("grounded_model") is not True


def test_groq_answer_marked_grounded(monkeypatch):
    async def fake_chat(messages):
        assert messages[0]["role"] == "system"
        return "It says Allah is most merciful (Quran 1:1)."

    monkeypatch.setattr(groq_client, "enabled", lambda: True)
    monkeypatch.setattr(groq_client, "chat", fake_chat)
    with fresh_client() as client:
        body = _ask(client).json()
    assert body["grounded_model"] is True
    assert body["verified"] is False
    assert "most merciful" in body["answer"]
    assert body["citations"] == ["Quran 1:1"]


def test_missing_citations_get_appended(monkeypatch):
    async def fake_chat(messages):
        return "A mercy for everyone."  # cited nothing

    monkeypatch.setattr(groq_client, "enabled", lambda: True)
    monkeypatch.setattr(groq_client, "chat", fake_chat)
    with fresh_client() as client:
        body = _ask(client).json()
    assert "Passages: Quran 1:1" in body["answer"]


def test_groq_failure_falls_back_extractive(monkeypatch):
    async def boom(messages):
        raise groq_client.GroqError("groq_status_503")

    monkeypatch.setattr(groq_client, "enabled", lambda: True)
    monkeypatch.setattr(groq_client, "chat", boom)
    with fresh_client() as client:
        body = _ask(client).json()
    assert body["grounded_model"] is False
    assert body["answer"] == "Allah is most merciful"


def test_history_trimmed_to_last_10_turns(monkeypatch):
    seen = {}

    async def fake_chat(messages):
        seen["n"] = len(messages)
        return "ok [1:1]"

    monkeypatch.setattr(groq_client, "enabled", lambda: True)
    monkeypatch.setattr(groq_client, "chat", fake_chat)
    hist = [{"role": "user", "content": f"q{i}"} for i in range(40)]
    with fresh_client() as client:
        r = client.post("/ai/ask", json={"query": "merciful", "corpus": CORPUS, "history": hist})
    assert r.status_code == 200
    # 1 system + 20 history + 1 prompt <= 22
    assert seen["n"] <= 22


def test_stream_yields_sse_deltas_and_done(monkeypatch):
    async def fake_stream(messages):
        for piece in ("Beshak ", "Allah ", "raheem ", "hai [1:1]."):
            yield piece

    monkeypatch.setattr(groq_client, "enabled", lambda: True)
    monkeypatch.setattr(groq_client, "stream_chat", fake_stream)
    with fresh_client() as client:
        with client.stream("POST", "/ai/ask", json={"query": "merciful", "corpus": CORPUS, "stream": True}) as r:
            assert r.status_code == 200
            assert r.headers["content-type"].startswith("text/event-stream")
            events = []
            for line in r.iter_lines():
                if line.startswith("data: "):
                    events.append(json.loads(line[6:]))
    assert [e["type"] for e in events if e["type"] != "done"] == ["delta"] * 4
    text = "".join(e["text"] for e in events if e["type"] == "delta")
    assert text == "Beshak Allah raheem hai [1:1]."
    done = [e for e in events if e["type"] == "done"][0]
    assert done["citations"] == ["Quran 1:1"]
    assert done["verified"] is False


def test_stream_groq_down_emits_fallback_event(monkeypatch):
    async def dead_stream(messages):
        raise groq_client.GroqError("groq_unavailable")
        yield  # pragma: no cover

    monkeypatch.setattr(groq_client, "enabled", lambda: True)
    monkeypatch.setattr(groq_client, "stream_chat", dead_stream)
    with fresh_client() as client:
        with client.stream("POST", "/ai/ask", json={"query": "merciful", "corpus": CORPUS, "stream": True}) as r:
            events = [json.loads(l[6:]) for l in r.iter_lines() if l.startswith("data: ")]
    fb = [e for e in events if e["type"] == "fallback"]
    assert fb and fb[0]["answer"] == "Allah is most merciful"


def test_empty_corpus_refusal_shape_unchanged(monkeypatch):
    monkeypatch.setattr(groq_client, "enabled", lambda: True)
    with fresh_client() as client:
        body = client.post("/ai/ask", json={"query": "anything", "corpus": [], "stream": True}).json()
    assert body["refused"] is True and body["answer"] is None


def test_system_prompt_carries_the_four_rules():
    sys_ = groq_client.SYSTEM_PROMPT.lower()
    assert "only from the numbered passages" in sys_
    assert "roman urdu" in sys_
    assert "disclaimer" in sys_ and "scholar" in sys_
    assert "never invent" in sys_


def test_stream_config_uses_pinned_model():
    assert groq_client.GROQ_URL.endswith("/openai/v1/chat/completions")
