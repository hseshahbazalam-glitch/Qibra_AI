"""Phase 7 — prayer / timezone / next-prayer midnight wrap."""

from datetime import datetime, timedelta

from app.prayer.times import next_prayer_after


def test_next_prayer_after_isha_is_tomorrow_fajr():
    now = datetime(2026, 8, 28, 23, 30)
    today = {
        "Fajr": datetime(2026, 8, 28, 5, 0),
        "Dhuhr": datetime(2026, 8, 28, 12, 10),
        "Asr": datetime(2026, 8, 28, 15, 40),
        "Maghrib": datetime(2026, 8, 28, 18, 50),
        "Isha": datetime(2026, 8, 28, 20, 10),
    }
    tomorrow_fajr = datetime(2026, 8, 29, 5, 1)
    result = next_prayer_after(now, today, tomorrow_fajr)
    assert result["name"] == "Fajr"
    assert result["tomorrow"] is True
    assert datetime.fromisoformat(result["time"]) > now


def test_next_prayer_before_dhuhr():
    now = datetime(2026, 8, 28, 10, 0)
    today = {
        "Fajr": datetime(2026, 8, 28, 5, 0),
        "Dhuhr": datetime(2026, 8, 28, 12, 10),
        "Asr": datetime(2026, 8, 28, 15, 40),
        "Maghrib": datetime(2026, 8, 28, 18, 50),
        "Isha": datetime(2026, 8, 28, 20, 10),
    }
    result = next_prayer_after(now, today, datetime(2026, 8, 29, 5, 1))
    assert result["name"] == "Dhuhr"
    assert result["tomorrow"] is False
    _ = timedelta  # imported for clarity of midnight math
