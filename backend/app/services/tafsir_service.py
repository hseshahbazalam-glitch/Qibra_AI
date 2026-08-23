"""Tafsir lookup that refuses to fabricate a licensed commentary corpus."""

from __future__ import annotations

from functools import lru_cache
from typing import Any

from app.services.quran_service import QuranService, get_quran_service


UNAVAILABLE_MESSAGE = (
    "A licensed tafsir corpus is not bundled in this repository. "
    "The matching ayah translation is returned for navigation only and is not tafsir."
)


class TafsirService:
    def __init__(self, quran: QuranService) -> None:
        self._quran = quran

    def sources(self) -> dict[str, Any]:
        return {
            "available": False,
            "sources": [],
            "message": UNAVAILABLE_MESSAGE,
        }

    def lookup(self, surah_id: int | None, ayah: int | None) -> dict[str, Any]:
        payload: dict[str, Any] = {
            "available": False,
            "source": None,
            "content": None,
            "message": UNAVAILABLE_MESSAGE,
        }
        if surah_id and ayah:
            found = self._quran.get_ayah(surah_id, ayah)
            if found is None:
                return payload
            payload["ayah"] = found
            payload["translation_en"] = found.get("translation_en")
            payload["label"] = "translation"
        return payload

    def search(self, query: str, limit: int = 20) -> dict[str, Any]:
        matches = self._quran.search(query, limit=limit)
        return {
            "available": False,
            "message": UNAVAILABLE_MESSAGE,
            "matches": [
                {
                    **item,
                    "kind": "translation",
                }
                for item in matches
            ],
        }


@lru_cache(maxsize=1)
def get_tafsir_service() -> TafsirService:
    return TafsirService(get_quran_service())
