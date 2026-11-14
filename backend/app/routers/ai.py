"""POST /ai/ask — RAG-gated Groq answers with an SSE streaming mode.

Contract:
  • no GROQ_API_KEY -> deterministic refusal, identical shape to the
    extractive level-0 (test_phase15 keeps its teeth);
  • owner 2026-09-02: key set + nothing retrieved -> LABELLED
    general-knowledge answer (GENERAL_LABEL prefix, never a fabricated
    citation). Hard refusal is kept only for fatwa-class questions, and
    its message mirrors the query language;
  • requires a valid access token (QB-011, 2026-11-14 — it used to be public, and
    test_ask_does_not_require_auth pinned that; the pin is inverted, not deleted),
    bounded per field and rate-limited per user; never caches (no-store via
    SecurityHeaders);
  • no query/corpus/prompt/Quran/hadith text is ever logged.

Caps (QB-011): query <=500 chars, <=32 corpus items with a per-field cap each, <=20
history messages bounded too, and a per-user budget of AI_ASK_LIMIT calls per
AI_ASK_WINDOW_SECONDS (in-process, per instance — disclosed wall, no shared store).

Level 1 (owner 2026-09-02): when GROQ_API_KEY is configured, grounded
answers come from llama-3.3-70b-versatile constrained by the system
prompt in groq_client (passages-only, language mirroring, fatwa-class
scholar-refusal, no invented references). Groq down / no key ->
extractive fallback, flagged grounded_model=False. stream=true gets
text/event-stream deltas + a terminal done event carrying citations.
"""

from __future__ import annotations

import json

from fastapi import APIRouter, Depends, Header, HTTPException
from fastapi.responses import JSONResponse, StreamingResponse
from pydantic import BaseModel, Field, field_validator

from .. import groq_client
from ..deps import bearer_subject
from ..observability.metrics import inc
from ..rag import answer, retrieve
from ..services.ai_quota import (
    AI_ASK_LIMIT,
    AI_ASK_WINDOW_SECONDS,
    take_ai_slot,
)

router = APIRouter(prefix="/ai", tags=["ai"])

_MAX_CORPUS_ITEMS = 32
_MAX_HISTORY_MESSAGES = 20  # last 10 turns

# QB-011: bound EVERY field, not just the number of items. The caps are byte-ish
# (character counts) because the only thing these fields can become is text in a prompt,
# and the value is measured after str() so a nested structure cannot smuggle a payload
# past a cap it does not appear to have.
MAX_QUERY_CHARS = 500
MAX_CORPUS_TEXT_CHARS = 8000
MAX_HISTORY_CONTENT_CHARS = 4000
MAX_ITEM_KEYS = 16
_MAX_UNKNOWN_FIELD_CHARS = 200
_CORPUS_FIELD_CAPS = {
    "text": MAX_CORPUS_TEXT_CHARS,
    "source": 200,
    "source_id": 200,
    "source_name": 200,
    "reference": 200,
    "collection": 32,
    "edition": 200,
    "translator": 200,
    "license": 200,
    "license_url": 512,
    "copyright_status": 64,
    "attribution_required": 8,
    "verified_at": 64,
    "verification_status": 32,
    "status": 32,
}
_HISTORY_FIELD_CAPS = {"role": 32, "content": MAX_HISTORY_CONTENT_CHARS}


def _bounded_items(value: list, *, caps: dict, label: str, count_code: str) -> list:
    """Validate one list-of-dicts field: size, then shape, then every value."""
    if not isinstance(value, list):
        raise ValueError(f"{label}_shape")
    if len(value) > caps["__max_items__"]:
        raise ValueError(count_code)
    out = []
    for item in value:
        if not isinstance(item, dict):
            raise ValueError(f"{label}_shape")
        if len(item) > MAX_ITEM_KEYS:
            raise ValueError(f"{label}_too_many_fields")
        for key, raw in item.items():
            cap = caps.get(str(key), _MAX_UNKNOWN_FIELD_CHARS)
            text = raw if isinstance(raw, str) else json.dumps(raw, default=str)
            if len(text) > cap:
                raise ValueError(f"{label}_{key}_too_long")
        out.append(item)
    return out


class AskIn(BaseModel):
    query: str = Field(min_length=1, max_length=MAX_QUERY_CHARS)
    corpus: list[dict] = Field(default_factory=list)
    history: list[dict] = Field(default_factory=list)
    stream: bool = False

    @field_validator("corpus")
    @classmethod
    def _cap_corpus(cls, value: list[dict]) -> list[dict]:
        return _bounded_items(
            value,
            caps=dict(_CORPUS_FIELD_CAPS, __max_items__=_MAX_CORPUS_ITEMS),
            label="corpus",
            count_code="corpus_too_large",
        )

    @field_validator("history")
    @classmethod
    def _cap_history(cls, value: list[dict]) -> list[dict]:
        # the last N turns are kept (a longer tail is truncated, not refused — the
        # client owns that UI and a hard error would break it for no security gain),
        # but every message that survives is bounded before it reaches the prompt
        return _bounded_items(
            value[-_MAX_HISTORY_MESSAGES:],
            caps=dict(_HISTORY_FIELD_CAPS, __max_items__=_MAX_HISTORY_MESSAGES),
            label="history",
            count_code="history_too_large",
        )


def ask_user_id(authorization: str | None = Header(default=None)) -> int:
    """QB-011: /ai/ask is no longer a public endpoint.

    The wording is endpoint-specific on purpose ("sign in"), because the caller here is a
    person in the AI pane, not a retry loop. The generic codes in deps.py stay what they
    are for every other route, and the header parsing itself is shared with them.
    """
    sub, error = bearer_subject(authorization)
    if error or not sub:
        raise HTTPException(
            status_code=401,
            detail={
                "detail": "auth_required",
                "reason": error or "invalid_token",
                "hint": "Sign in to ask — the AI pane answers through this endpoint on "
                "your behalf, and it costs real inference per call.",
            },
        )
    try:
        return int(sub)
    except (TypeError, ValueError):
        raise HTTPException(status_code=401, detail={"detail": "invalid_token"}) from None


def _quota_denied(retry_after_seconds: float) -> JSONResponse:
    """A 429 that says what it is, how long to wait, and that the limit is per account —
    and that reaches the client through the same middleware chain as everything else, so
    it carries the security headers and x-request-id like any other response."""
    seconds = max(1, int(round(retry_after_seconds)))
    return JSONResponse(
        {
            "detail": "ai_quota_exceeded",
            "limit": AI_ASK_LIMIT,
            "window_seconds": AI_ASK_WINDOW_SECONDS,
            "retry_after_seconds": seconds,
            "scope": "per signed-in user",
        },
        status_code=429,
        headers={"Retry-After": str(seconds)},
    )


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
async def ask(body: AskIn, user_id: int = Depends(ask_user_id)):
    # Do not log query, corpus, prompts, Quran, or Hadith text.
    # Auth + per-user quota first: the expensive call is what needs bounding.
    wait = take_ai_slot(user_id)
    if wait is not None:
        inc("ai_quota_denied")
        return _quota_denied(wait)
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
