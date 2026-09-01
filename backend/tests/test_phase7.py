"""Phase 7 — next-prayer order and midnight wrap."""

from datetime import datetime

from app.prayer.times import next_prayer_after

TODAY = {
    "Fajr": datetime(2026, 8, 28, 5, 0),
    "Dhuhr": datetime(2026, 8, 28, 12, 10),
    "Asr": datetime(2026, 8, 28, 15, 40),
    "Maghrib": datetime(2026, 8, 28, 18, 50),
    "Isha": datetime(2026, 8, 28, 20, 10),
}
TOMORROW_FAJR = datetime(2026, 8, 29, 5, 1)


def test_before_fajr_is_fajr_today():
    r = next_prayer_after(datetime(2026, 8, 28, 4, 0), TODAY, TOMORROW_FAJR)
    assert r["name"] == "Fajr"
    assert r["tomorrow"] is False


def test_after_fajr_is_dhuhr():
    r = next_prayer_after(datetime(2026, 8, 28, 10, 0), TODAY, TOMORROW_FAJR)
    assert r["name"] == "Dhuhr"
    assert r["tomorrow"] is False


def test_after_dhuhr_is_asr():
    r = next_prayer_after(datetime(2026, 8, 28, 13, 0), TODAY, TOMORROW_FAJR)
    assert r["name"] == "Asr"


def test_after_asr_is_maghrib():
    r = next_prayer_after(datetime(2026, 8, 28, 16, 0), TODAY, TOMORROW_FAJR)
    assert r["name"] == "Maghrib"


def test_after_maghrib_is_isha():
    r = next_prayer_after(datetime(2026, 8, 28, 19, 0), TODAY, TOMORROW_FAJR)
    assert r["name"] == "Isha"
    assert r["tomorrow"] is False


def test_after_isha_wraps_to_tomorrow_fajr():
    r = next_prayer_after(datetime(2026, 8, 28, 23, 30), TODAY, TOMORROW_FAJR)
    assert r["name"] == "Fajr"
    assert r["tomorrow"] is True
    assert datetime.fromisoformat(r["time"]) > datetime(2026, 8, 28, 23, 30)


def test_equal_time_is_not_next():
    r = next_prayer_after(TODAY["Dhuhr"], TODAY, TOMORROW_FAJR)
    assert r["name"] == "Asr"


def test_order_is_canonical():
    names = []
    now = datetime(2026, 8, 28, 0, 1)
    for _ in range(5):
        r = next_prayer_after(now, TODAY, TOMORROW_FAJR)
        names.append(r["name"])
        now = datetime.fromisoformat(r["time"])
    assert names == ["Fajr", "Dhuhr", "Asr", "Maghrib", "Isha"]


def test_missing_prayer_skipped():
    partial = dict(TODAY)
    del partial["Asr"]
    r = next_prayer_after(datetime(2026, 8, 28, 13, 0), partial, TOMORROW_FAJR)
    assert r["name"] == "Maghrib"


def test_time_is_isoformat():
    r = next_prayer_after(datetime(2026, 8, 28, 10, 0), TODAY, TOMORROW_FAJR)
    datetime.fromisoformat(r["time"])
