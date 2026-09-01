from datetime import datetime, timedelta

ORDER = ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"]


def current_prayer_at(now: datetime, today: dict[str, datetime]) -> dict | None:
    active = None
    for name in ORDER:
        t = today.get(name)
        if t is not None and t <= now:
            active = {"name": name, "time": t.isoformat()}
    return active


def next_prayer_after(now: datetime, today: dict[str, datetime], tomorrow_fajr: datetime) -> dict:
    for name in ORDER:
        t = today.get(name)
        if t is not None and t > now:
            return {"name": name, "time": t.isoformat(), "tomorrow": False}
    fajr = tomorrow_fajr
    if fajr <= now:
        fajr = fajr + timedelta(days=1)
    return {"name": "Fajr", "time": fajr.isoformat(), "tomorrow": True}
