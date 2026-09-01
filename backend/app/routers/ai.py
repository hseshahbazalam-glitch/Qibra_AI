"""POST /ai/ask — RAG-gated Groq answers with an SSE streaming mode.

Contract (unchanged core):
  • empty / no-hit corpus -> deterministic refusal, identical shape to
    the extractive level-0 (test_phase15 keeps its teeth);
  • never requires auth, never caches (no-store via SecurityHeaders);
  • no query/corpus/prompt/Quran/hadith text is ever logged.

Level 1 (owner 2026-09-02): when GROQ_API_KEY is configured, grounded
answers come from llama-3.3-70b-versatile constrained by the system
prompt in groq_client (passages-only, language mirroring, fatwa-class
scholar-refusal, no invented references). Groq down / no key ->
extractive fallback, flagged grounded_model=False. stream=true gets
text/event-stream deltas + a terminal done event carrying citations.
"""

from __future__ import annotations

import json

from fastapi import APIRouter
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, Field, field_validator

from .. import groq_client
from ..observability.metrics import inc
from ..rag import answer, retrieve

router = APIRouter(prefix="/ai", tags=["ai"])

_MAX_CORPUS_ITEMS = 32
_MAX_HISTORY_MESSAGES = 20  # last 10 turns


class AskIn(BaseModel):
    query: str
    corpus: list[dict] = Field(default_factory=list)
    history: list[dict] = Field(default_factory=list)
    stream: bool = False

    @field_validator("corpus")
    @classmethod
    def _cap_corpus(cls, value: list[dict]) -> list[dict]:
        if len(value) > _MAX_CORPUS_ITEMS:
            raise ValueError("corpus_too_large")
        return value

    @field_validator("history")
    @classmethod
    def _cap_history(cls, value: list[dict]) -> list[dict]:
        return value[-_MAX_HISTORY_MESSAGES:]


def _citations(passages: list[dict]) -> list[str]:
    out = []
    for p in passages:
        for key in ("source", "reference"):
            ref = p.get(key)
            if isinstance(ref, str) and ref.strip() and ref.strip() not in out:
                out.append(ref.strip())
    return out


def _ensure_cited(text: str, citations: list[str]) -> str:
    """Citations are not optional: if the model omitted every reference,
    append them so the answer still surfaces its passages."""
    if citations and not any(c in text for c in citations) and "[1:" not in text:
        return text.rstrip() + "\n\nPassages: " + "; ".join(citations)
    return text


@router.post("/ask")
async def ask(body: AskIn):
    # Unauthenticated on purpose (test_ask_does_not_require_auth).
    # Do not log query, corpus, prompts, Quran, or Hadith text.
    hits = retrieve(body.query, body.corpus)
    if not hits or not groq_client.enabled():
        return answer(body.query, body.corpus)

    messages = groq_client.build_messages(body.query, hits, body.history)

    if body.stream:
        async def sse():
            buf: list[str] = []
            try:
                async for delta in groq_client.stream_chat(messages):
                    buf.append(delta)
                    yield f"data: {json.dumps({'type': 'delta', 'text': delta})}\n\n"
                text = _ensure_cited("".join(buf), _citations(hits))
                if text and not buf:
                    # generator died silently before any delta — still ship
                    # the grounded text so the client never sees an empty answer
                    yield f"data: {json.dumps({'type': 'delta', 'text': text})}\n\n"
                yield f"data: {json.dumps({'type': 'done', 'citations': _citations(hits), 'verified': False, 'grounded_model': True})}\n\n"
                inc("groq_stream")
            except groq_client.GroqError:
                inc("groq_stream_fallback")
                fb = answer(body.query, body.corpus)
                yield f"data: {json.dumps({'type': 'fallback', **fb})}\n\n"

        return StreamingResponse(
            sse(),
            media_type="text/event-stream",
            headers={"Cache-Control": "no-store", "X-Accel-Buffering": "no"},
        )

    try:
        text = await groq_client.chat(messages)
        inc("groq_chat")
    except groq_client.GroqError:
        inc("groq_fallback")
        fb = answer(body.query, body.corpus)
        fb["grounded_model"] = False
        return fb

    citations = _citations(hits)
    return {
        "refused": False,
        "answer": _ensure_cited(text, citations),
        "citations": citations,
        "verified": False,
        "provenance": [
            {
                "reference": h.get("source") or h.get("reference") or "unknown",
                "verification_status": h.get("verification_status")
                or h.get("status")
                or "UNKNOWN",
            }
            for h in hits
        ],
        "production_rag_eligible": False,
        "grounded_model": True,
    }
