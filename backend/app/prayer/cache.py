"""In-memory prayer schedule cache keyed by location/date/tz/settings/provider."""

from __future__ import annotations

from datetime import datetime, timedelta


def cache_key(
    *,
    latitude: float,
    longitude: float,
    date: datetime,
    timezone: str,
    method: str,
    asr: str,
    provider: str,
) -> str:
    day = date.strftime("%Y-%m-%d")
    return (
        f"{latitude:.4f}|{longitude:.4f}|{day}|{timezone}|{method}|{asr}|{provider}"
    )


class PrayerScheduleMemoryCache:
    def __init__(self, ttl: timedelta | None = None):
        self.ttl = ttl or timedelta(hours=24)
        self._store: dict[str, tuple[datetime, dict[str, str]]] = {}

    def put(self, key: str, times: dict[str, str], now: datetime) -> None:
        self._store[key] = (now, dict(times))

    def get(self, key: str, now: datetime) -> dict[str, str] | None:
        row = self._store.get(key)
        if row is None:
            return None
        stored_at, times = row
        if now - stored_at > self.ttl:
            self._store.pop(key, None)
            return None
        return dict(times)
