"""Cache freshness. Expired entries stay until invalidated."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import Optional


MISSING = "missing"
FRESH = "fresh"
STALE = "stale"
EXPIRED = "expired"


@dataclass(frozen=True)
class CacheEntry:
    key: str
    value: str
    stored_at: datetime
    ttl: Optional[timedelta] = None
    stale_after: Optional[timedelta] = None
    version: Optional[str] = None
    source: Optional[str] = None
    checksum: Optional[str] = None

    @property
    def expires_at(self) -> Optional[datetime]:
        if self.ttl is None:
            return None
        return self.stored_at + self.ttl

    @property
    def stale_at(self) -> Optional[datetime]:
        if self.stale_after is not None:
            return self.stored_at + self.stale_after
        return self.expires_at


class MemoryCache:
    def __init__(self) -> None:
        self._data: dict[str, CacheEntry] = {}

    def write(self, entry: CacheEntry) -> None:
        self._data[entry.key] = entry

    def get(self, key: str) -> Optional[CacheEntry]:
        return self._data.get(key)

    def invalidate(self, key: str) -> None:
        self._data.pop(key, None)


def classify(entry: Optional[CacheEntry], now: datetime) -> str:
    if entry is None:
        return MISSING
    exp = entry.expires_at
    stale_at = entry.stale_at
    if exp is not None and now >= exp:
        return EXPIRED
    if stale_at is not None and now >= stale_at:
        return STALE
    return FRESH


def lookup(cache: MemoryCache, key: str, now: datetime) -> tuple[str, Optional[CacheEntry]]:
    entry = cache.get(key)
    freshness = classify(entry, now)
    from ..observability.metrics import inc

    if freshness == MISSING:
        inc("cache_miss")
    elif freshness == STALE:
        inc("cache_stale")
    elif freshness == FRESH:
        inc("cache_hit")
    return freshness, entry
