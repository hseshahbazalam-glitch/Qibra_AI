from datetime import datetime, timedelta


def next_prayer_after(now: datetime, today: dict[str, datetime], tomorrow_fajr: datetime) -> dict:
    order = ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"]
    for name in order:
        t = today.get(name)
        if t is not None and t > now:
            return {"name": name, "time": t.isoformat(), "tomorrow": False}
    fajr = tomorrow_fajr
    if fajr <= now:
        fajr = fajr + timedelta(days=1)
    return {"name": "Fajr", "time": fajr.isoformat(), "tomorrow": True}
