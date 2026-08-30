"""Location fix helpers. Never invent a city name. Never send GPS to Qibra API."""

from __future__ import annotations

SOURCES = ("DEVICE", "MANUAL", "CACHED")
STATUSES = (
    "granted",
    "denied",
    "deniedForever",
    "serviceDisabled",
    "timeout",
    "unavailable",
    "cached",
)


def permission_status(*, service_enabled: bool, permission: str, timed_out: bool = False) -> str:
    if timed_out:
        return "timeout"
    if not service_enabled:
        return "serviceDisabled"
    if permission in {"deniedForever", "deniedForeverPermission"}:
        return "deniedForever"
    if permission == "denied":
        return "denied"
    if permission in {"granted", "whileInUse", "always"}:
        return "granted"
    return "unavailable"


def location_payload(
    *,
    latitude: float,
    longitude: float,
    source: str,
    city: str | None = None,
    country: str | None = None,
    country_code: str | None = None,
    timezone: str | None = None,
    accuracy: float | None = None,
) -> dict:
    if source not in SOURCES:
        raise ValueError("invalid_source")
    named = city if city and city != "UNKNOWN" else None
    return {
        "latitude": latitude,
        "longitude": longitude,
        "city": named or "UNKNOWN",
        "country": country or "UNKNOWN",
        "countryCode": country_code,
        "timezone": timezone,
        "accuracy": accuracy,
        "source": source,
        "sent_to_qibra_api": False,
    }
