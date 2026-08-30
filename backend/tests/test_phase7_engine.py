"""Phase 7 — location, timezone/DST, cache, next prayer, Aladhan parse."""

from datetime import datetime, timedelta, timezone

from app.config import Settings
from app.prayer.aladhan import parse_timings
from app.prayer.cache import PrayerScheduleMemoryCache, cache_key
from app.prayer.location import location_payload, permission_status
from app.prayer.times import current_prayer_at, next_prayer_after
from app.prayer.timezone import is_dst, local_calendar_date, offset_hours


TODAY = {
    "Fajr": datetime(2026, 8, 28, 5, 0),
    "Sunrise": datetime(2026, 8, 28, 6, 20),
    "Dhuhr": datetime(2026, 8, 28, 12, 10),
    "Asr": datetime(2026, 8, 28, 15, 40),
    "Maghrib": datetime(2026, 8, 28, 18, 50),
    "Isha": datetime(2026, 8, 28, 20, 10),
}
TOMORROW_FAJR = datetime(2026, 8, 29, 5, 1)


def test_location_model_source_and_unknown_city():
    row = location_payload(
        latitude=1.23,
        longitude=4.56,
        source="DEVICE",
        city=None,
        timezone="Africa/Nairobi",
    )
    assert row["city"] == "UNKNOWN"
    assert row["source"] == "DEVICE"
    assert row["sent_to_qibra_api"] is False
    assert row["timezone"] == "Africa/Nairobi"


def test_permission_states():
    assert permission_status(service_enabled=False, permission="granted") == "serviceDisabled"
    assert permission_status(service_enabled=True, permission="denied") == "denied"
    assert permission_status(service_enabled=True, permission="deniedForever") == "deniedForever"
    assert permission_status(service_enabled=True, permission="granted") == "granted"
    assert permission_status(service_enabled=True, permission="granted", timed_out=True) == "timeout"
    assert permission_status(service_enabled=True, permission="nope") == "unavailable"


def test_timezone_conversion_not_india_default():
    assert offset_hours("America/New_York", datetime(2026, 1, 15, 12, tzinfo=timezone.utc)) == -5
    assert offset_hours("Not/AZone", datetime(2026, 1, 1, tzinfo=timezone.utc)) is None


def test_dst_transition_new_york_2026():
    # US DST 2026 starts 2026-03-08 02:00 local.
    before = datetime(2026, 3, 7, 17, tzinfo=timezone.utc)  # 12:00 EST
    after = datetime(2026, 3, 8, 16, tzinfo=timezone.utc)  # 12:00 EDT
    assert is_dst("America/New_York", before) is False
    assert is_dst("America/New_York", after) is True
    assert offset_hours("America/New_York", after) == offset_hours("America/New_York", before) + 1


def test_aladhan_parse_and_invalid():
    good = parse_timings(
        {
            "data": {
                "timings": {
                    "Fajr": "05:01 (PKT)",
                    "Sunrise": "06:20",
                    "Dhuhr": "12:10",
                    "Asr": "15:40",
                    "Maghrib": "18:50",
                    "Isha": "20:10",
                    "Imsak": "04:51",
                }
            }
        }
    )
    assert good["Fajr"] == "05:01"
    assert good["Imsak"] == "04:51"
    assert parse_timings(None) == {}
    assert parse_timings({"data": "nope"}) == {}
    assert parse_timings({"data": {"timings": {"Fajr": "soon"}}}) == {}


def test_prayer_cache_hit_miss_stale_and_location_change():
    cache = PrayerScheduleMemoryCache(ttl=timedelta(hours=24))
    now = datetime(2026, 8, 28, 10, 0)
    key = cache_key(
        latitude=24.8607,
        longitude=67.0011,
        date=now,
        timezone="Asia/Karachi",
        method="MWL",
        asr="standard",
        provider="local",
    )
    cache.put(key, {"Fajr": "05:00"}, now)
    assert cache.get(key, now)["Fajr"] == "05:00"
    stale = cache.get(key, now + timedelta(hours=25))
    assert stale is None
    moved = cache_key(
        latitude=21.3891,
        longitude=39.8579,
        date=now,
        timezone="Asia/Riyadh",
        method="MWL",
        asr="standard",
        provider="local",
    )
    assert moved != key
    assert cache.get(moved, now) is None
    rolled = cache_key(
        latitude=24.8607,
        longitude=67.0011,
        date=now + timedelta(days=1),
        timezone="Asia/Karachi",
        method="MWL",
        asr="standard",
        provider="local",
    )
    assert rolled != key


def test_midnight_wrap_and_current_prayer():
    assert current_prayer_at(datetime(2026, 8, 28, 4, 0), TODAY) is None
    assert current_prayer_at(datetime(2026, 8, 28, 13, 0), TODAY)["name"] == "Dhuhr"
    nxt = next_prayer_after(datetime(2026, 8, 28, 23, 30), TODAY, TOMORROW_FAJR)
    assert nxt["name"] == "Fajr"
    assert nxt["tomorrow"] is True


def test_offline_fallback_is_stale_or_empty_not_invented():
    cache = PrayerScheduleMemoryCache()
    assert cache.get("missing", datetime(2026, 8, 28)) is None


def test_hijri_civil_date_boundary_uses_iana():
    utc = datetime(2026, 8, 30, 22, 0, tzinfo=timezone.utc)
    kolkata = local_calendar_date("Asia/Kolkata", utc)
    new_york = local_calendar_date("America/New_York", utc)
    assert str(kolkata) == "2026-08-31"
    assert str(new_york) == "2026-08-30"


def test_timeout_status_and_precise_location_not_on_server():
    assert permission_status(service_enabled=True, permission="granted", timed_out=True) == "timeout"
    assert Settings().precise_location_stored_on_server is False
