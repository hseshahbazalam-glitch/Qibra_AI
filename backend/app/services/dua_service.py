"""Masnoon dua catalog extracted from the existing Flutter offline database."""

from __future__ import annotations

import json
from functools import lru_cache
from typing import Any

from app.core.config import get_settings


class DuaService:
    def __init__(self, catalog_path) -> None:
        payload = json.loads(catalog_path.read_text(encoding="utf-8"))
        self._categories: list[dict[str, Any]] = payload.get("categories", [])
        self._duas: list[dict[str, Any]] = payload.get("duas", [])

    def list_duas(self, category: str | None = None) -> list[dict[str, Any]]:
        if not category:
            return list(self._duas)
        return [item for item in self._duas if item.get("category") == category]

    def list_categories(self) -> list[dict[str, Any]]:
        counts: dict[str, int] = {}
        for dua in self._duas:
            counts[dua["category"]] = counts.get(dua["category"], 0) + 1
        items = []
        for category in self._categories:
            items.append({**category, "dua_count": counts.get(category["id"], 0)})
        return items

    def get_category(self, category_id: str) -> dict[str, Any] | None:
        for category in self.list_categories():
            if category["id"] == category_id or category["nameEnglish"].lower() == category_id.lower():
                return {
                    **category,
                    "duas": self.list_duas(category["id"]),
                }
        return None

    def search(self, query: str, limit: int = 20) -> list[dict[str, Any]]:
        needle = query.strip().lower()
        if not needle:
            return []
        matches = []
        for dua in self._duas:
            haystack = " ".join(
                [
                    str(dua.get("titleEnglish") or ""),
                    str(dua.get("titleUrdu") or ""),
                    str(dua.get("titleArabic") or ""),
                    str(dua.get("translationEnglish") or ""),
                    str(dua.get("translationUrdu") or ""),
                    str(dua.get("transliteration") or ""),
                    str(dua.get("reference") or ""),
                    " ".join(dua.get("tags") or []),
                ]
            ).lower()
            if needle in haystack:
                matches.append(dua)
                if len(matches) >= limit:
                    break
        return matches

    def get_dua(self, dua_id: str) -> dict[str, Any] | None:
        for dua in self._duas:
            if dua["id"] == dua_id:
                return dua
        return None


@lru_cache(maxsize=1)
def get_dua_service() -> DuaService:
    return DuaService(get_settings().dua_catalog_path)
