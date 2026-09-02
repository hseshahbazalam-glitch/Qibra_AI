"""Phase 17 — labelled general-knowledge fallback (owner 2026-09-02).

Empty / no-hit corpus with GROQ enabled must NOT hard-refuse knowledge
questions: the answer carries GENERAL_LABEL up front. Fatwa-class stays a
hard refusal in the query's language. Groq is mocked — never called.
"""

import json

from app import groq_client
from helpers import fresh_client

LABEL = (
    "General knowledge answer — no specific passage was retrieved. "
    "Please verify with the Quran/scholars."
)
DISCLAIMER = "Disclaimer: AI cannot give fatwa. Please consult a qualified scholar."


def _sse_events(client, payload):
    with client.stream("POST", "/ai/ask", json={**payload, "stream": True}) as r:
        return [json.loads(line[6:]) for line in r.iter_lines() if line.startswith("data: ")]


def test_no_key_empty_corpus_keeps_legacy_refusal():
    # no GROQ_API_KEY in the test env -> enabled() is False: level-0 shape
    with fresh_client() as client:
        body = client.post("/ai/ask", json={"query": "namaz kya hai", "corpus": []}).json()
    assert body["refused"] is True and body["answer"] is None


def test_general_answer_is_labelled(monkeypatch):
    async def fake_chat(messages):
        assert messages[0]["content"] == groq_client.GENERAL_SYSTEM_PROMPT
        return "Namaz is the second pillar of Islam, established from the Quran and Sunnah."

    monkeypatch.setattr(groq_client, "enabled", lambda: True)
    monkeypatch.setattr(groq_client, "chat", fake_chat)
    with fresh_client() as client:
        body = client.post("/ai/ask", json={"query": "namaz kya hai", "corpus": []}).json()
    assert body["refused"] is False
    assert body["answer"].startswith(LABEL)
    assert "Namaz is the second pillar" in body["answer"]
    assert body["citations"] == []
    assert body["verified"] is False
    assert body["general_knowledge"] is True
    assert "Passages:" not in body["answer"]  # no citation footer without passages


def test_corpus_with_zero_hits_also_goes_general(monkeypatch):
    async def fake_chat(messages):
        return "Tawakkul means reliance upon Allah."

    monkeypatch.setattr(groq_client, "enabled", lambda: True)
    monkeypatch.setattr(groq_client, "chat", fake_chat)
    with fresh_client() as client:
        body = client.post(
            "/ai/ask",
            json={"query": "tawakkul", "corpus": [{"text": "unrelated passage", "source": "Quran 2:2"}]},
        ).json()
    assert body["answer"].startswith(LABEL)
    assert body["general_knowledge"] is True


def test_fatwa_hard_refuses_without_model_call(monkeypatch):
    called = {"n": 0}

    async def spy_chat(messages):
        called["n"] += 1
        return "must not run"

    monkeypatch.setattr(groq_client, "enabled", lambda: True)
    monkeypatch.setattr(groq_client, "chat", spy_chat)
    with fresh_client() as client:
        body = client.post("/ai/ask", json={"query": "is bitcoin halal?", "corpus": []}).json()
    assert called["n"] == 0  # deterministic gate — the model never sees it
    assert body["refused"] is True
    assert body["reason"] == "fatwa_requires_scholar"
    assert DISCLAIMER in body["answer"]
    assert not body["answer"].startswith(LABEL)


def test_fatwa_refusal_mirrors_roman_urdu(monkeypatch):
    monkeypatch.setattr(groq_client, "enabled", lambda: True)
    with fresh_client() as client:
        en = client.post("/ai/ask", json={"query": "is music haram", "corpus": []}).json()
        ur = client.post("/ai/ask", json={"query": "musiqi kya haram hai", "corpus": []}).json()
    assert "qualified scholar" in en["answer"]
    assert "sawal" in ur["answer"] and "scholar" in ur["answer"]
    assert DISCLAIMER in ur["answer"]  # the disclaimer itself stays exact-English


def test_model_side_fatwa_refusal_never_gets_the_label(monkeypatch):
    async def fake_chat(messages):
        return "Yeh masla sirf scholar hal kar sakte hain. " + DISCLAIMER

    monkeypatch.setattr(groq_client, "enabled", lambda: True)
    monkeypatch.setattr(groq_client, "chat", fake_chat)
    with fresh_client() as client:
        body = client.post("/ai/ask", json={"query": "muta marriage ka hukm kya hai bhai", "corpus": []}).json()
    assert body["refused"] is True
    assert not body["answer"].startswith(LABEL)
    assert DISCLAIMER in body["answer"]


def test_action_json_passthrough_skips_the_label(monkeypatch):
    async def fake_chat(messages):
        return '```json\n{"action": "OPEN_QURAN", "params": {}, "reply": "Quran khol raha hoon"}\n```'

    monkeypatch.setattr(groq_client, "enabled", lambda: True)
    monkeypatch.setattr(groq_client, "chat", fake_chat)
    with fresh_client() as client:
        body = client.post("/ai/ask", json={"query": "quran kholo", "corpus": []}).json()
    assert body["answer"].startswith("```json")  # client JSON-parses; label would break it


def test_stream_general_leads_with_label_then_done(monkeypatch):
    async def fake_stream(messages):
        for piece in ["Namaz ", "deen ka ", "thumhara khamba hai."]:
            yield piece

    monkeypatch.setattr(groq_client, "enabled", lambda: True)
    monkeypatch.setattr(groq_client, "stream_chat", fake_stream)
    with fresh_client() as client:
        events = _sse_events(client, {"query": "namaz kya hai", "corpus": []})
    assert events[0] == {"type": "delta", "text": LABEL + "\n\n"}
    assert events[-1]["type"] == "done"
    assert events[-1]["general_knowledge"] is True
    assert events[-1]["citations"] == []
    assert "".join(e["text"] for e in events if e["type"] == "delta").count(LABEL) == 1


def test_stream_fatwa_emits_refusal_fallback(monkeypatch):
    monkeypatch.setattr(groq_client, "enabled", lambda: True)
    with fresh_client() as client:
        events = _sse_events(client, {"query": "is crypto trading halal", "corpus": []})
    assert len(events) == 1 and events[0]["type"] == "fallback"
    assert events[0]["refused"] is True
    assert DISCLAIMER in events[0]["answer"]


def test_stream_general_model_down_emits_legacy_fallback(monkeypatch):
    async def dead(messages):
        raise groq_client.GroqError("groq_unavailable")
        yield  # pragma: no cover

    monkeypatch.setattr(groq_client, "enabled", lambda: True)
    monkeypatch.setattr(groq_client, "stream_chat", dead)
    with fresh_client() as client:
        events = _sse_events(client, {"query": "sabr kya hai", "corpus": []})
    assert events and events[-1]["type"] == "fallback"
    assert events[-1]["refused"] is True and events[-1]["answer"] is None


def test_grounded_path_stays_unlabelled(monkeypatch):
    async def fake_chat(messages):
        return "It says Allah is most merciful (Quran 1:1)."

    monkeypatch.setattr(groq_client, "enabled", lambda: True)
    monkeypatch.setattr(groq_client, "chat", fake_chat)
    with fresh_client() as client:
        body = client.post(
            "/ai/ask",
            json={"query": "merciful", "corpus": [{"text": "Allah is most merciful", "source": "Quran 1:1"}]},
        ).json()
    assert not body["answer"].startswith(LABEL)
    assert body.get("general_knowledge") is None
    assert body["citations"] == ["Quran 1:1"]
