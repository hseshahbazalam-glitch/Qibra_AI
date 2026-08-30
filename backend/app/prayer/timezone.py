"""IANA offsets via zoneinfo. Unknown IANA stays unknown — no India/UTC default."""

from __future__ import annotations

from datetime import datetime, timezone
from zoneinfo import ZoneInfo, ZoneInfoNotFoundError


def offset_hours(iana: str, at: datetime) -> float | None:
    try:
        loc = ZoneInfo(iana)
    except ZoneInfoNotFoundError:
        return None
    if at.tzinfo is None:
        at = at.replace(tzinfo=timezone.utc)
    local = at.astimezone(loc)
    delta = local.utcoffset()
    if delta is None:
        return None
    return delta.total_seconds() / 3600.0


def is_dst(iana: str, at: datetime) -> bool | None:
    jan = offset_hours(iana, datetime(at.year, 1, 15, 12, tzinfo=timezone.utc))
    jul = offset_hours(iana, datetime(at.year, 7, 15, 12, tzinfo=timezone.utc))
    now = offset_hours(iana, at)
    if jan is None or jul is None or now is None:
        return None
    std = min(jan, jul)
    return now > std


def local_calendar_date(iana: str, utc: datetime):
    try:
        loc = ZoneInfo(iana)
    except ZoneInfoNotFoundError:
        return None
    if utc.tzinfo is None:
        utc = utc.replace(tzinfo=timezone.utc)
    local = utc.astimezone(loc)
    return local.date()
