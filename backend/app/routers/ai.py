"""POST /ai/ask — RAG-gated Groq answers with an SSE streaming mode.

Contract:
  • no GROQ_API_KEY -> deterministic refusal, identical shape to the
    extractive level-0 (test_phase15 keeps its teeth);
  • owner 2026-09-02: key set + nothing retrieved -> LABELLED
    general-knowledge answer (GENERAL_LABEL prefix, never a fabricated
    citation). Hard refusal is kept only for fatwa-class questions, and
    its message mirrors the query language;
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


async def _general(body: AskIn):
    """Key is set but nothing was retrieved — owner-approved labelled
    general-knowledge answer. Fatwa-class stays a hard refusal (deterministic
    gate here, prompt rule as backstop). Never emits citations, never claims
    verification, never invents a number."""
    refusal = {
        "refused": True,
        "reason": "fatwa_requires_scholar",
        "answer": groq_client.fatwa_refusal_message(body.query),
        "citations": [],
        "verified": False,
    }
    if groq_client.is_fatwa_query(body.query):
        inc("general_fatwa_refused")
        if body.stream:
            return _sse(f"data: {json.dumps({'type': 'fallback', **refusal})}\n\n")
        return refusal

    messages = groq_client.build_general_messages(body.query, body.history)

    if body.stream:
        async def gen():
            labeled = False
            try:
                async for delta in groq_client.stream_chat(messages):
                    if not labeled:
                        # Label is server-owned and rides with the FIRST
                        # real delta — never a bare label if the model dies
                        # at connect. The model can't forget or mis-quote it.
                        labeled = True
                        yield (
                            "data: "
                            + json.dumps(
                                {
                                    "type": "delta",
                                    "text": groq_client.GENERAL_LABEL + "\n\n",
                                }
                            )
                            + "\n\n"
                        )
                    yield f"data: {json.dumps({'type': 'delta', 'text': delta})}\n\n"
                if not labeled:
                    # Stream produced nothing at all: honest fallback instead
                    # of dressing silence up as a labelled answer.
                    fb = answer(body.query, body.corpus)
                    yield f"data: {json.dumps({'type': 'fallback', **fb})}\n\n"
                    return
                yield f"data: {json.dumps({'type': 'done', 'citations': [], 'verified': False, 'general_knowledge': True})}\n\n"
                inc("groq_general_stream")
            except groq_client.GroqError:
                inc("groq_stream_fallback")
                fb = answer(body.query, body.corpus)
                yield f"data: {json.dumps({'type': 'fallback', **fb})}\n\n"

        return StreamingResponse(
            gen(),
            media_type="text/event-stream",
            headers={"Cache-Control": "no-store", "X-Accel-Buffering": "no"},
        )

    try:
        text = await groq_client.chat(messages)
        inc("groq_general")
    except groq_client.GroqError:
        inc("groq_fallback")
        fb = answer(body.query, body.corpus)
        fb["grounded_model"] = False
        return fb

    stripped = text.strip()
    if groq_client.FATWA_DISCLAIMER in text:
        # model-side refusal (gate missed the wording): keep it absolute
        inc("general_fatwa_refused")
        return {**refusal, "answer": stripped}
    if stripped.startswith("```"):
        # app-command payload — the client parses it; no label in front
        return {"refused": False, "answer": stripped, "citations": [], "verified": False,
                "general_knowledge": True, "production_rag_eligible": False,
                "grounded_model": True}
    return {
        "refused": False,
        "answer": groq_client.GENERAL_LABEL + "\n\n" + stripped,
        "citations": [],
        "verified": False,
        "general_knowledge": True,
        "production_rag_eligible": False,
        "grounded_model": True,
    }


def _sse(body: str) -> StreamingResponse:
    async def one():
        yield body

    return StreamingResponse(
        one(),
        media_type="text/event-stream",
        headers={"Cache-Control": "no-store", "X-Accel-Buffering": "no"},
    )


@router.post("/ask")
async def ask(body: AskIn):
    # Unauthenticated on purpose (test_ask_does_not_require_auth).
    # Do not log query, corpus, prompts, Quran, or Hadith text.
    if not groq_client.enabled():
        return answer(body.query, body.corpus)

    hits = retrieve(body.query, body.corpus)
    if not hits:
        return await _general(body)

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
