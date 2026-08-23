"""Retrieval-first Islamic assistant. Never fabricates Quran or Hadith citations."""

from __future__ import annotations

from functools import lru_cache
from typing import Any

from app.services.dua_service import DuaService, get_dua_service
from app.services.hadith_service import HadithService, get_hadith_service
from app.services.quran_service import QuranService, get_quran_service

NO_SOURCE = (
    "I couldn't find a verified source for this — please consult a qualified scholar."
)
FATWA_DISCLAIMER = (
    "This is general information, not a fatwa — please consult a qualified scholar."
)


class AiService:
    def __init__(
        self,
        quran: QuranService,
        hadith: HadithService,
        duas: DuaService,
    ) -> None:
        self._quran = quran
        self._hadith = hadith
        self._duas = duas

    def _latest_user_message(self, payload: dict[str, Any]) -> str:
        if isinstance(payload.get("message"), str) and payload["message"].strip():
            return payload["message"].strip()
        if isinstance(payload.get("question"), str) and payload["question"].strip():
            return payload["question"].strip()
        messages = payload.get("messages")
        if isinstance(messages, list):
            for item in reversed(messages):
                if not isinstance(item, dict):
                    continue
                role = str(item.get("role") or "").lower()
                content = str(item.get("content") or "").strip()
                if role in {"user", ""} and content:
                    return content
        return ""

    def retrieve(self, query: str, limit: int = 3) -> dict[str, list[dict[str, Any]]]:
        return {
            "quran": self._quran.search(query, limit=limit),
            "hadith": self._hadith.search(query, limit=limit, collection="bukhari"),
            "duas": self._duas.search(query, limit=limit),
        }

    def chat(self, payload: dict[str, Any]) -> dict[str, Any]:
        question = self._latest_user_message(payload)
        if not question:
            return {
                "reply": "Please ask a question about the Quran, Hadith, or a dua.",
                "sources": [],
                "mode": "retrieval",
            }
        retrieved = self.retrieve(question)
        sources = [
            *[
                {
                    "type": "quran",
                    "reference": item["reference"],
                    "text": item["translation_en"] or item["arabic"],
                }
                for item in retrieved["quran"]
            ],
            *[
                {
                    "type": "hadith",
                    "reference": item["reference"]["display"],
                    "text": item["english"],
                }
                for item in retrieved["hadith"]
            ],
            *[
                {
                    "type": "dua",
                    "reference": item.get("reference") or item.get("id"),
                    "text": item.get("translationEnglish") or item.get("titleEnglish"),
                }
                for item in retrieved["duas"]
            ],
        ]
        if not sources:
            return {
                "reply": NO_SOURCE,
                "sources": [],
                "mode": "retrieval",
            }

        evidence_lines = []
        for source in sources[:4]:
            snippet = source["text"].strip()
            if len(snippet) > 220:
                snippet = snippet[:217] + "..."
            evidence_lines.append(f"- {source['reference']}: {snippet}")

        reply = "\n".join(
            [
                "Direct Answer",
                "Here are verified passages that match your question.",
                "",
                "Evidence",
                *evidence_lines,
                "",
                "References",
                *[f"- {source['reference']}" for source in sources[:4]],
                "",
                "Practical Guidance",
                "Read the cited text in context. " + FATWA_DISCLAIMER,
            ]
        )
        return {
            "reply": reply,
            "sources": sources[:6],
            "mode": "retrieval",
        }

    def explain_ayah(self, payload: dict[str, Any]) -> dict[str, Any]:
        surah = _as_int(payload.get("surah") or payload.get("surah_id") or payload.get("id"))
        ayah = _as_int(payload.get("ayah") or payload.get("ayah_id") or payload.get("number"))
        if surah is None or ayah is None:
            query = str(payload.get("query") or payload.get("message") or "").strip()
            matches = self._quran.search(query, limit=1) if query else []
            if not matches:
                return {"reply": NO_SOURCE, "sources": []}
            surah = matches[0]["surah_id"]
            ayah = matches[0]["ayah"]
        found = self._quran.get_ayah(surah, ayah)
        if found is None:
            return {"reply": NO_SOURCE, "sources": []}
        reference = f"Quran {found['surah']['id']}:{found['number']}"
        reply = (
            f"{reference}\n"
            f"{found['arabic']}\n\n"
            f"{found['translation_en']}\n\n"
            f"{FATWA_DISCLAIMER}"
        )
        return {
            "reply": reply,
            "ayah": found,
            "sources": [{"type": "quran", "reference": reference}],
        }

    def explain_hadith(self, payload: dict[str, Any]) -> dict[str, Any]:
        collection = str(
            payload.get("collection") or payload.get("book") or "bukhari"
        ).strip()
        resolved = self._hadith.resolve_collection(collection) or "bukhari"
        number = payload.get("number") or payload.get("hadith")
        found = None
        if number is not None:
            found = self._hadith.get_hadith(resolved, str(number))
        if found is None:
            query = str(payload.get("query") or payload.get("message") or "").strip()
            matches = self._hadith.search(query or "intentions", limit=1, collection=resolved)
            found = matches[0] if matches else None
        if found is None or not found.get("english"):
            return {"reply": NO_SOURCE, "sources": []}
        reference = found["reference"]["display"]
        reply = f"{reference}\n{found['english']}\n\n{FATWA_DISCLAIMER}"
        return {
            "reply": reply,
            "hadith": found,
            "sources": [{"type": "hadith", "reference": reference}],
        }

    def explain_dua(self, payload: dict[str, Any]) -> dict[str, Any]:
        dua_id = str(payload.get("id") or payload.get("dua_id") or "").strip()
        found = self._duas.get_dua(dua_id) if dua_id else None
        if found is None:
            query = str(
                payload.get("query") or payload.get("message") or payload.get("title") or ""
            ).strip()
            matches = self._duas.search(query, limit=1) if query else []
            found = matches[0] if matches else None
        if found is None:
            return {"reply": NO_SOURCE, "sources": []}
        reference = found.get("reference") or found["id"]
        reply = (
            f"{found.get('titleEnglish')}\n"
            f"{found.get('arabic')}\n\n"
            f"{found.get('translationEnglish')}\n\n"
            f"Reference: {reference}\n"
            f"{FATWA_DISCLAIMER}"
        )
        return {
            "reply": reply,
            "dua": found,
            "sources": [{"type": "dua", "reference": reference}],
        }


def _as_int(value: Any) -> int | None:
    try:
        if value is None or value == "":
            return None
        return int(value)
    except (TypeError, ValueError):
        return None


@lru_cache(maxsize=1)
def get_ai_service() -> AiService:
    return AiService(get_quran_service(), get_hadith_service(), get_dua_service())
