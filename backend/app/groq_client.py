"""Groq chat access for /ai/ask — grounded answers, never logging content.

Design rules (owner, 2026-09-02):
  • answers ONLY from the RAG passages the app sends (they arrive in the
    prompt as the complete allowed context; "no passage" refusals happen in
    the router before this module is even called);
  • Roman Urdu question -> Roman Urdu reply (the prompt mirrors language);
  • fatwa-class questions -> scholar-refusal + disclaimer (prompt-level rule,
    and the refusal shape survives even if the model complies badly);
  • NEVER invent ayat/hadith numbers; passages are always cited — the router
    additionally guarantees a citations list on every non-refused response.

No request/response body is ever logged (house rule for /ai: no query,
corpus, prompts, Quran or Hadith text in logs).
"""

from __future__ import annotations

import json
from typing import AsyncIterator

import httpx

from .config import get_settings

GROQ_URL = "https://api.groq.com/openai/v1/chat/completions"

SYSTEM_PROMPT = """You are Qibra AI, an Islamic assistant.

GROUNDING — hard rules, no exceptions:
1. Answer ONLY from the numbered PASSAGES provided in the user message. If
   they do not cover the question, say exactly what could not be found in
   them and stop. Never add knowledge from outside the passages.
2. NEVER invent or guess Quran ayat numbers, hadith numbers, chapter numbers
   or grading. Cite ONLY the references attached to the passages you used,
   inline as [surah:ayah] for Quran or the given hadith reference otherwise.
3. Every answer must be grounded in at least one passage.
4. FATWA-CLASS QUESTIONS (permissible/not, rulings, divorce, inheritance
   disputes, personal religious verdicts): do not issue a ruling. Reply that
   this requires a qualified scholar, and add:
   "Disclaimer: AI cannot give fatwa. Please consult a qualified scholar."

LANGUAGE:
- Detect the user's language and reply in EXACTLY that language.
- A Roman Urdu question gets a Roman Urdu reply. Never switch languages.

APP-COMMAND MODE:
When the user message is a short app-control command (not a question), reply
with ONLY this JSON in a ```json fence and nothing else:
{"action": "<NAME>", "params": {..}, "reply": "<one short line>"}
Valid names: SET_TAHAJJUD_ALARM, SET_MORNING_ADHKAR, SET_EVENING_ADHKAR,
SET_JUMMAH_REMINDER, CANCEL_ALL_NOTIFICATIONS, TEST_NOTIFICATION, OPEN_QURAN,
OPEN_PRAYER, OPEN_QIBLA, OPEN_HADITH, OPEN_TASBIH, OPEN_ZAKAT,
OPEN_INHERITANCE, OPEN_HABITS. Never emit this JSON shape otherwise.

STYLE: short paragraphs, no markdown headings, no emoji. You are not a
mufti and never pretend to be one."""


class GroqError(Exception):
    """Upstream unavailable/erroring — callers fall back to extractive RAG."""


# --- General-knowledge fallback (owner 2026-09-02) ---------------------
# No retrieved passages no longer means a hard refusal for knowledge
# questions: the answer ships with a visible label and the citation
# guarantee is replaced by a ban on specific numbers. Fatwa-class stays a
# hard refusal, and refusal text mirrors the query language.

GENERAL_LABEL = (
    "General knowledge answer — no specific passage was retrieved. "
    "Please verify with the Quran/scholars."
)

FATWA_DISCLAIMER = "Disclaimer: AI cannot give fatwa. Please consult a qualified scholar."

_FATWA_MARKERS = (
    "fatwa", "halal", "haram", "haraam", "permissible", "impermissible",
    "ruling", "divorce", "talaq", "jaiz", "jayaz", "najaiz", "hukm",
)

_ROMAN_URDU_TOKENS = {
    "hai", "h", "kya", "kiya", "kyu", "kyun", "kyon", "kaise", "kese",
    "ka", "ki", "ke", "ko", "kaun", "karo", "karta", "karti", "kar",
    "bata", "batao", "chahiye", "chahye", "nahi", "nahin", "kyonke",
    "liye", "se", "say", "par", "mein", "main", "apna", "apni", "aap",
    "tum", "hamara", "hamari", "mera", "meri", "wala", "wali", "tha",
    "thi", "tha", "hoga", "hogi", "sakta", "sakti",
}

# Same words the app-side Roman Urdu bridge keys on (client is the source
# of truth there; this list only drives the language of server-side
# canned messages, so a small overlap is acceptable and self-contained).
_ROMAN_URDU_ISLAMIC_WORDS = {
    "namaz", "roza", "dua", "sabr", "jannah", "jahannam", "paani",
    "taubah", "nabi", "farz", "sunnat", "wuzu", "ghusl", "iman",
    "qibla", "hajat", "pakeezgi",
}


def is_fatwa_query(text: str) -> bool:
    """Deterministic fatwa gate for the ungrounded path — deliberately
    conservative; the prompt rule stays the backstop when passages exist."""
    low = text.lower()
    return any(marker in low for marker in _FATWA_MARKERS)


def is_roman_urdu(text: str) -> bool:
    import re

    tokens = set(re.findall(r"[a-z']+", text.lower()))
    if not tokens:
        return False
    return bool(tokens & _ROMAN_URDU_TOKENS) or bool(
        tokens & _ROMAN_URDU_ISLAMIC_WORDS
    )


def fatwa_refusal_message(text: str) -> str:
    if is_roman_urdu(text):
        return (
            "Yeh sawal ka hukm sirf ek qualified scholar de sakta hai — "
            "AI fatwa nahi deta. " + FATWA_DISCLAIMER
        )
    return (
        "This question needs a qualified scholar — AI cannot rule on it. "
        + FATWA_DISCLAIMER
    )


GENERAL_SYSTEM_PROMPT = """You are Qibra AI, an Islamic assistant.
NO passages were retrieved for this question. Answer from well-known,
general Islamic knowledge only.

HARD RULES:
1. NEVER quote, invent or guess specific ayat numbers, hadith numbers,
   chapter numbers or grading. Refer to surahs or topics by name only.
2. The system prefixes a general-knowledge notice before your reply. Do not
   repeat, rephrase or reference it yourself.
3. FATWA-CLASS questions (permissible/not, rulings, divorce, inheritance
   disputes, personal religious verdicts): do not answer them. Say only
   that a qualified scholar must be consulted, and end with exactly:
   "Disclaimer: AI cannot give fatwa. Please consult a qualified scholar."
4. Detect the user's language and reply in EXACTLY that language. A Roman
   Urdu question gets a Roman Urdu reply — including any refusal.
5. If the user message is a short app-control command (not a question),
   reply with ONLY this JSON in a ```json fence and nothing else:
   {"action": "<NAME>", "params": {..}, "reply": "<one short line>"}

STYLE: short paragraphs, no markdown headings, no emoji. You are not a
mufti and never pretend to be one."""


def build_general_messages(query: str, history: list[dict]) -> list[dict]:
    messages = [{"role": "system", "content": GENERAL_SYSTEM_PROMPT}]
    for turn in history[-20:]:
        if turn.get("role") in ("user", "assistant") and isinstance(
            turn.get("content"), str
        ):
            messages.append({"role": turn["role"], "content": turn["content"]})
    messages.append({"role": "user", "content": f"QUESTION: {query}"})
    return messages


def enabled() -> bool:
    return bool(get_settings().groq_api_key.strip())


def build_messages(query: str, passages: list[dict], history: list[dict]) -> list[dict]:
    corpus = "\n\n".join(
        f"[{i + 1}] ({p.get('source') or p.get('reference') or 'source unknown'}) "
        f"{p.get('text', '')}"
        for i, p in enumerate(passages)
    )
    messages = [{"role": "system", "content": SYSTEM_PROMPT}]
    for turn in history[-20:]:
        if turn.get("role") in ("user", "assistant") and isinstance(turn.get("content"), str):
            messages.append({"role": turn["role"], "content": turn["content"]})
    messages.append(
        {
            "role": "user",
            "content": f"PASSAGES (the only permitted content source):\n{corpus}"
            f"\n\nQUESTION: {query}",
        }
    )
    return messages


def _headers() -> dict:
    return {
        "Authorization": f"Bearer {get_settings().groq_api_key}",
        "Content-Type": "application/json",
    }


async def chat(messages: list[dict]) -> str:
    cfg = get_settings()
    try:
        async with httpx.AsyncClient(timeout=cfg.groq_timeout_seconds) as client:
            r = await client.post(
                GROQ_URL,
                headers=_headers(),
                json={"model": cfg.groq_model, "messages": messages, "temperature": 0.2},
            )
            if r.status_code != 200:
                raise GroqError(f"groq_status_{r.status_code}")
            return r.json()["choices"][0]["message"]["content"]
    except GroqError:
        raise
    except Exception:
        # never surface upstream bodies (they may contain user content)
        raise GroqError("groq_unavailable")


async def stream_chat(messages: list[dict]) -> AsyncIterator[str]:
    """Yield text deltas in OpenAI-compatible SSE. Raises GroqError before
    the first yield on failure; mid-stream drops end the generator silently —
    the router decides how to finish."""
    cfg = get_settings()
    payload = {
        "model": cfg.groq_model,
        "messages": messages,
        "temperature": 0.2,
        "stream": True,
    }
    try:
        async with httpx.AsyncClient(timeout=cfg.groq_timeout_seconds) as client:
            async with client.stream("POST", GROQ_URL, headers=_headers(), json=payload) as r:
                if r.status_code != 200:
                    raise GroqError(f"groq_status_{r.status_code}")
                async for line in r.aiter_lines():
                    if not line.startswith("data:"):
                        continue
                    data = line[5:].strip()
                    if data == "[DONE]":
                        return
                    try:
                        ev = json.loads(data)
                    except ValueError:
                        continue
                    delta = ev.get("choices", [{}])[0].get("delta", {}).get("content")
                    if delta:
                        yield delta
    except GroqError:
        raise
    except Exception:
        raise GroqError("groq_stream_unavailable")
