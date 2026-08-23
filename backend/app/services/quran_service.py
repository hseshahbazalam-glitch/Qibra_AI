"""Offline Quran corpus loaded from the existing Flutter assets."""

from __future__ import annotations

import json
import threading
from functools import lru_cache
from pathlib import Path
from typing import Any

from app.core.config import get_settings

JUZ_BOUNDARIES: list[tuple[int, int]] = [
    (1, 1),
    (2, 142),
    (2, 253),
    (3, 93),
    (4, 24),
    (4, 148),
    (5, 83),
    (6, 111),
    (7, 88),
    (8, 41),
    (9, 93),
    (11, 6),
    (12, 53),
    (15, 2),
    (17, 1),
    (18, 75),
    (21, 1),
    (23, 1),
    (25, 21),
    (27, 56),
    (29, 46),
    (33, 28),
    (36, 28),
    (39, 32),
    (41, 47),
    (46, 1),
    (51, 31),
    (58, 1),
    (67, 1),
    (78, 1),
]


def _clean(text: str) -> str:
    return text.replace("\ufeff", "").strip()


class QuranService:
    def __init__(self, assets_root: Path) -> None:
        self._assets_root = assets_root
        self._lock = threading.Lock()
        self._loaded = False
        self._surahs: list[dict[str, Any]] = []
        self._by_number: dict[int, dict[str, Any]] = {}

    def _load(self) -> None:
        if self._loaded:
            return
        with self._lock:
            if self._loaded:
                return
            arabic_path = self._assets_root / "quran" / "quran_arabic.json"
            english_path = self._assets_root / "quran" / "translation_en.json"
            arabic = json.loads(arabic_path.read_text(encoding="utf-8"))
            english = json.loads(english_path.read_text(encoding="utf-8"))
            arabic_surahs = arabic["data"]["surahs"]
            english_surahs = {
                int(item["number"]): item for item in english["data"]["surahs"]
            }
            surahs: list[dict[str, Any]] = []
            for raw in arabic_surahs:
                number = int(raw["number"])
                english_surah = english_surahs.get(number, {})
                english_ayahs = {
                    int(ayah.get("numberInSurah") or ayah.get("number") or 0): _clean(
                        str(ayah.get("text") or "")
                    )
                    for ayah in english_surah.get("ayahs", [])
                }
                ayahs = []
                for ayah in raw.get("ayahs", []):
                    ayah_no = int(ayah.get("numberInSurah") or 0)
                    ayahs.append(
                        {
                            "number": ayah_no,
                            "numberInQuran": int(ayah.get("number") or 0),
                            "arabic": _clean(str(ayah.get("text") or "")),
                            "translation_en": english_ayahs.get(ayah_no, ""),
                            "juz": int(ayah.get("juz") or 1),
                            "page": int(ayah.get("page") or 1),
                            "hizb": int(ayah.get("hizbQuarter") or 0),
                            "ruku": int(ayah.get("ruku") or 0),
                            "sajdah": bool(ayah.get("sajda")),
                        }
                    )
                record = {
                    "id": number,
                    "number": number,
                    "name": raw.get("englishName") or "",
                    "name_arabic": raw.get("name") or "",
                    "english_name_translation": raw.get("englishNameTranslation") or "",
                    "revelation_type": raw.get("revelationType") or "Meccan",
                    "ayah_count": len(ayahs),
                    "ayahs": ayahs,
                }
                surahs.append(record)
                self._by_number[number] = record
            self._surahs = surahs
            self._loaded = True

    def list_surahs(self) -> list[dict[str, Any]]:
        self._load()
        return [
            {
                "id": item["id"],
                "number": item["number"],
                "name": item["name"],
                "name_arabic": item["name_arabic"],
                "english_name_translation": item["english_name_translation"],
                "revelation_type": item["revelation_type"],
                "ayah_count": item["ayah_count"],
            }
            for item in self._surahs
        ]

    def get_surah(self, surah_id: int) -> dict[str, Any] | None:
        self._load()
        surah = self._by_number.get(surah_id)
        if surah is None:
            return None
        return surah

    def get_ayah(self, surah_id: int, ayah_number: int) -> dict[str, Any] | None:
        surah = self.get_surah(surah_id)
        if surah is None:
            return None
        for ayah in surah["ayahs"]:
            if ayah["number"] == ayah_number:
                return {
                    "surah": {
                        "id": surah["id"],
                        "name": surah["name"],
                        "name_arabic": surah["name_arabic"],
                    },
                    **ayah,
                }
        return None

    def search(self, query: str, limit: int = 20) -> list[dict[str, Any]]:
        self._load()
        needle = query.strip().lower()
        if len(needle) < 2:
            return []
        matches: list[dict[str, Any]] = []
        for surah in self._surahs:
            for ayah in surah["ayahs"]:
                haystacks = (
                    ayah["arabic"].lower(),
                    ayah["translation_en"].lower(),
                    surah["name"].lower(),
                )
                if any(needle in item for item in haystacks):
                    matches.append(
                        {
                            "surah_id": surah["id"],
                            "surah_name": surah["name"],
                            "ayah": ayah["number"],
                            "arabic": ayah["arabic"],
                            "translation_en": ayah["translation_en"],
                            "reference": f"Quran {surah['id']}:{ayah['number']}",
                        }
                    )
                    if len(matches) >= limit:
                        return matches
        return matches

    def list_juz(self) -> list[dict[str, Any]]:
        self._load()
        items = []
        for index, (start_surah, start_ayah) in enumerate(JUZ_BOUNDARIES, start=1):
            if index == len(JUZ_BOUNDARIES):
                end_surah, end_ayah = 114, 6
            else:
                next_surah, next_ayah = JUZ_BOUNDARIES[index]
                if next_ayah == 1:
                    end_surah = next_surah - 1
                    end_ayah = self._by_number[end_surah]["ayah_count"]
                else:
                    end_surah = next_surah
                    end_ayah = next_ayah - 1
            items.append(
                {
                    "id": index,
                    "number": index,
                    "start_surah": start_surah,
                    "start_ayah": start_ayah,
                    "end_surah": end_surah,
                    "end_ayah": end_ayah,
                }
            )
        return items

    def get_juz(self, juz_id: int) -> dict[str, Any] | None:
        self._load()
        if juz_id < 1 or juz_id > 30:
            return None
        meta = next(item for item in self.list_juz() if item["id"] == juz_id)
        ayahs = []
        for surah in self._surahs:
            for ayah in surah["ayahs"]:
                if ayah["juz"] == juz_id:
                    ayahs.append(
                        {
                            "surah_id": surah["id"],
                            "surah_name": surah["name"],
                            "ayah": ayah["number"],
                            "arabic": ayah["arabic"],
                            "translation_en": ayah["translation_en"],
                            "reference": f"Quran {surah['id']}:{ayah['number']}",
                        }
                    )
        return {**meta, "ayah_count": len(ayahs), "ayahs": ayahs}

    @property
    def totals(self) -> dict[str, int]:
        self._load()
        return {
            "surahs": len(self._surahs),
            "ayahs": sum(item["ayah_count"] for item in self._surahs),
            "juz": 30,
        }


@lru_cache(maxsize=1)
def get_quran_service() -> QuranService:
    return QuranService(get_settings().assets_root)
