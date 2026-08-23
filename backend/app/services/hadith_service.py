"""Offline Hadith corpus loaded from the existing Flutter assets."""

from __future__ import annotations

import json
import threading
from functools import lru_cache
from pathlib import Path
from typing import Any

from app.core.config import get_settings

COLLECTIONS: dict[str, dict[str, str]] = {
    "bukhari": {
        "id": "bukhari",
        "name": "Sahih al-Bukhari",
        "name_arabic": "صحيح البخاري",
        "author": "Imam al-Bukhari",
        "folder": "bukhari",
    },
    "muslim": {
        "id": "muslim",
        "name": "Sahih Muslim",
        "name_arabic": "صحيح مسلم",
        "author": "Imam Muslim",
        "folder": "muslim",
    },
    "abudawud": {
        "id": "abudawud",
        "name": "Sunan Abu Dawud",
        "name_arabic": "سنن أبي داود",
        "author": "Imam Abu Dawud",
        "folder": "abudawud",
    },
    "tirmidhi": {
        "id": "tirmidhi",
        "name": "Jami at-Tirmidhi",
        "name_arabic": "جامع الترمذي",
        "author": "Imam at-Tirmidhi",
        "folder": "tirmidhi",
    },
    "nasai": {
        "id": "nasai",
        "name": "Sunan an-Nasa'i",
        "name_arabic": "سنن النسائي",
        "author": "Imam an-Nasa'i",
        "folder": "nasai",
    },
    "ibnmajah": {
        "id": "ibnmajah",
        "name": "Sunan Ibn Majah",
        "name_arabic": "سنن ابن ماجه",
        "author": "Imam Ibn Majah",
        "folder": "ibnmajah",
    },
    "malik": {
        "id": "malik",
        "name": "Muwatta Malik",
        "name_arabic": "موطأ مالك",
        "author": "Imam Malik",
        "folder": "malik",
    },
}

ALIASES = {
    "sahih al-bukhari": "bukhari",
    "sahih bukhari": "bukhari",
    "bukhari": "bukhari",
    "sahih muslim": "muslim",
    "muslim": "muslim",
    "abu dawud": "abudawud",
    "abu dawood": "abudawud",
    "abudawud": "abudawud",
    "tirmidhi": "tirmidhi",
    "al-tirmidhi": "tirmidhi",
    "nasai": "nasai",
    "an-nasai": "nasai",
    "ibn majah": "ibnmajah",
    "ibnmajah": "ibnmajah",
    "malik": "malik",
    "muwatta": "malik",
    "muwatta malik": "malik",
}


class HadithService:
    def __init__(self, assets_root: Path) -> None:
        self._root = assets_root / "hadith"
        self._lock = threading.Lock()
        self._cache: dict[str, list[dict[str, Any]]] = {}

    def resolve_collection(self, name: str | None) -> str | None:
        if not name:
            return None
        key = name.strip().lower().replace("_", "").replace("-", "")
        compact = {
            alias.replace(" ", "").replace("-", "").replace("'", ""): value
            for alias, value in ALIASES.items()
        }
        normalized = name.strip().lower()
        if normalized in ALIASES:
            return ALIASES[normalized]
        if key in compact:
            return compact[key]
        if normalized in COLLECTIONS:
            return normalized
        return None

    def list_collections(self) -> list[dict[str, Any]]:
        items = []
        for meta in COLLECTIONS.values():
            folder = self._root / meta["folder"]
            english = folder / "english.json"
            items.append(
                {
                    **{k: v for k, v in meta.items() if k != "folder"},
                    "available": english.exists(),
                }
            )
        return items

    def _load_language(self, collection: str, language: str) -> dict[str, Any]:
        folder = COLLECTIONS[collection]["folder"]
        path = self._root / folder / f"{language}.json"
        if not path.exists():
            return {}
        return json.loads(path.read_text(encoding="utf-8"))

    def load_book(self, collection: str) -> list[dict[str, Any]]:
        if collection not in COLLECTIONS:
            return []
        if collection in self._cache:
            return self._cache[collection]
        with self._lock:
            if collection in self._cache:
                return self._cache[collection]
            english = self._load_language(collection, "english")
            arabic = self._load_language(collection, "arabic")
            urdu = self._load_language(collection, "urdu")
            arabic_by_number = {
                str(item.get("hadithnumber")): str(item.get("text") or "")
                for item in arabic.get("hadiths", [])
            }
            urdu_by_number = {
                str(item.get("hadithnumber")): str(item.get("text") or "")
                for item in urdu.get("hadiths", [])
            }
            sections = english.get("metadata", {}).get("sections", {})
            records: list[dict[str, Any]] = []
            for item in english.get("hadiths", []):
                number = str(item.get("hadithnumber") or "")
                text_en = str(item.get("text") or "").strip()
                if not number:
                    continue
                reference = item.get("reference") or {}
                book_no = int(reference.get("book") or 0)
                chapter_name = sections.get(str(book_no), "") if isinstance(sections, dict) else ""
                records.append(
                    {
                        "id": f"{collection}:{number}",
                        "collection": collection,
                        "book": COLLECTIONS[collection]["name"],
                        "chapter": chapter_name,
                        "number": number,
                        "arabic": arabic_by_number.get(number, ""),
                        "english": text_en,
                        "urdu": urdu_by_number.get(number, ""),
                        "grade": "sahih"
                        if collection in {"bukhari", "muslim"}
                        else "unknown",
                        "reference": {
                            "book": book_no,
                            "hadith": reference.get("hadith"),
                            "display": f"{COLLECTIONS[collection]['name']} {number}",
                        },
                    }
                )
            self._cache[collection] = records
            return records

    def list_hadiths(
        self,
        collection: str | None = None,
        page: int = 1,
        limit: int = 20,
    ) -> dict[str, Any]:
        if collection:
            records = [item for item in self.load_book(collection) if item["english"]]
            book_name = COLLECTIONS[collection]["name"]
        else:
            records = []
            book_name = None
            for key in COLLECTIONS:
                for item in self.load_book(key):
                    if item["english"]:
                        records.append(item)
                        if len(records) >= page * limit:
                            break
                if len(records) >= page * limit:
                    break
        total = len(records)
        start = max(page - 1, 0) * limit
        return {
            "collection": collection,
            "book": book_name,
            "page": page,
            "limit": limit,
            "total": total,
            "items": records[start : start + limit],
        }

    def get_book(self, name: str, page: int = 1, limit: int = 20) -> dict[str, Any] | None:
        collection = self.resolve_collection(name)
        if collection is None:
            return None
        payload = self.list_hadiths(collection=collection, page=page, limit=limit)
        meta = COLLECTIONS[collection]
        return {
            "id": meta["id"],
            "name": meta["name"],
            "name_arabic": meta["name_arabic"],
            "author": meta["author"],
            **payload,
        }

    def search(self, query: str, limit: int = 20, collection: str | None = None) -> list[dict[str, Any]]:
        needle = query.strip().lower()
        if len(needle) < 2:
            return []
        keys = [collection] if collection else list(COLLECTIONS)
        matches: list[dict[str, Any]] = []
        for key in keys:
            if key is None:
                continue
            for item in self.load_book(key):
                haystack = " ".join(
                    [
                        item["english"],
                        item["arabic"],
                        item["urdu"],
                        item["chapter"],
                        item["reference"]["display"],
                    ]
                ).lower()
                if needle in haystack and item["english"]:
                    matches.append(item)
                    if len(matches) >= limit:
                        return matches
        return matches

    def get_hadith(self, collection: str, number: str) -> dict[str, Any] | None:
        for item in self.load_book(collection):
            if str(item["number"]) == str(number):
                return item
        return None


@lru_cache(maxsize=1)
def get_hadith_service() -> HadithService:
    return HadithService(get_settings().assets_root)
