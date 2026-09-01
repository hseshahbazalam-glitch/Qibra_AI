"""Aladhan JSON parser. Does not call the network. Does not invent times."""

_KEYS = ("Imsak", "Fajr", "Sunrise", "Dhuhr", "Asr", "Sunset", "Maghrib", "Isha")


def parse_timings(payload: dict | None) -> dict[str, str]:
    if not isinstance(payload, dict):
        return {}
    data = payload.get("data") if isinstance(payload.get("data"), dict) else payload
    timings = data.get("timings") if isinstance(data, dict) else None
    if not isinstance(timings, dict):
        return {}
    out: dict[str, str] = {}
    for key in _KEYS:
        raw = str(timings.get(key) or "").split(" ")[0].strip()
        if len(raw) >= 4 and ":" in raw:
            hh, _, rest = raw.partition(":")
            if hh.isdigit() and rest[:2].isdigit():
                out[key] = f"{int(hh):02d}:{rest[:2]}"
    return out
