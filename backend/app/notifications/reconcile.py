"""Deterministic local notification IDs and idempotent reconcile.

The API does not schedule device alarms. GPS is never part of a payload.
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timedelta

OBLIGATORY = ("Fajr", "Dhuhr", "Asr", "Maghrib", "Isha")


def fnv1a(text: str) -> int:
    h = 2166136261
    for b in text.encode("utf-8"):
        h ^= b
        h = (h * 16777619) & 0xFFFFFFFF
    v = h & 0x7FFFFFFF
    return v or 1


def alert_id(
    *,
    prayer: str,
    local_date: str,
    timezone: str,
    location_key: str,
    settings_key: str,
    hhmm: str,
    kind: str = "prayer",
) -> int:
    return fnv1a(f"{prayer}|{local_date}|{timezone}|{location_key}|{settings_key}|{hhmm}|{kind}")


def permission_status(raw: str) -> str:
    if raw == "granted":
        return "granted"
    if raw == "denied":
        return "denied"
    if raw in {"deniedForever", "permanentlyDenied", "restricted"}:
        return "deniedForever"
    if raw == "notDetermined":
        return "notDetermined"
    return "unsupported"


@dataclass(frozen=True)
class Alert:
    id: int
    name: str
    when: datetime
    kind: str = "prayer"


def desired_alerts(
    times: dict[str, datetime],
    now: datetime,
    *,
    enabled: bool,
    pre_minutes: int = 0,
    include_sunrise: bool = False,
    timezone: str,
    location_key: str,
    settings_key: str,
    permission: str = "granted",
) -> list[Alert]:
    if not enabled:
        return []
    if permission in {"denied", "deniedForever", "unsupported"}:
        return []
    if not timezone or timezone == "UNKNOWN":
        return []
    names = list(OBLIGATORY)
    if include_sunrise:
        names.append("Sunrise")
    out: list[Alert] = []
    for name in names:
        when = times.get(name)
        if when is None or when <= now:
            continue
        hhmm = when.strftime("%H:%M")
        local_date = when.strftime("%Y-%m-%d")
        out.append(
            Alert(
                id=alert_id(
                    prayer=name,
                    local_date=local_date,
                    timezone=timezone,
                    location_key=location_key,
                    settings_key=settings_key,
                    hhmm=hhmm,
                ),
                name=name,
                when=when,
            )
        )
        if pre_minutes > 0:
            pre = when - timedelta(minutes=pre_minutes)
            if pre > now:
                out.append(
                    Alert(
                        id=alert_id(
                            prayer=name,
                            local_date=local_date,
                            timezone=timezone,
                            location_key=location_key,
                            settings_key=settings_key,
                            hhmm=hhmm,
                            kind="pre",
                        ),
                        name=name,
                        when=pre,
                        kind="pre",
                    )
                )
    out.sort(key=lambda a: a.when)
    return out


def reconcile(desired: list[Alert], existing_ids: set[int]) -> dict:
    want = {a.id for a in desired}
    cancel = set(existing_ids) - want
    keep = set(existing_ids) & want
    create = [a for a in desired if a.id not in existing_ids]
    resulting = sorted(keep | {a.id for a in create})
    from ..observability.metrics import inc

    inc("notif_plan")
    return {
        "cancel": sorted(cancel),
        "keep": sorted(keep),
        "create_ids": [a.id for a in create],
        "resulting": resulting,
    }
