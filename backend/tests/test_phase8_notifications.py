"""Phase 8 — local notification IDs and idempotent reconcile."""

from datetime import datetime, timedelta

from app.config import Settings
from app.notifications.reconcile import (
    alert_id,
    desired_alerts,
    fnv1a,
    permission_status,
    reconcile,
)


TIMES = {
    "Fajr": datetime(2026, 8, 28, 5, 0),
    "Sunrise": datetime(2026, 8, 28, 6, 20),
    "Dhuhr": datetime(2026, 8, 28, 12, 10),
    "Asr": datetime(2026, 8, 28, 15, 40),
    "Maghrib": datetime(2026, 8, 28, 18, 50),
    "Isha": datetime(2026, 8, 28, 20, 10),
}


def _desired(**kwargs):
    base = dict(
        times=TIMES,
        now=datetime(2026, 8, 28, 4, 0),
        enabled=True,
        pre_minutes=10,
        timezone="Asia/Karachi",
        location_key="Karachi",
        settings_key="prayer=1|pre=10|sun=0",
        permission="granted",
    )
    base.update(kwargs)
    return desired_alerts(base.pop("times"), base.pop("now"), **base)


def test_id_determinism():
    a = alert_id(
        prayer="Fajr",
        local_date="2026-08-28",
        timezone="Asia/Karachi",
        location_key="Karachi",
        settings_key="x",
        hhmm="05:00",
    )
    b = alert_id(
        prayer="Fajr",
        local_date="2026-08-28",
        timezone="Asia/Karachi",
        location_key="Karachi",
        settings_key="x",
        hhmm="05:00",
    )
    assert a == b
    assert a == fnv1a("Fajr|2026-08-28|Asia/Karachi|Karachi|x|05:00|prayer")


def test_reconcile_idempotent():
    first = _desired()
    plan1 = reconcile(first, set())
    plan2 = reconcile(first, set(plan1["resulting"]))
    plan3 = reconcile(first, set(plan2["resulting"]))
    assert plan2["create_ids"] == []
    assert plan3["create_ids"] == []
    assert plan1["resulting"] == plan2["resulting"] == plan3["resulting"]
    assert len(plan1["resulting"]) == len(set(plan1["resulting"]))


def test_stale_removed_on_location_and_settings_and_tz():
    a = _desired()
    b = _desired(location_key="Makkah", timezone="Asia/Riyadh")
    plan = reconcile(b, {x.id for x in a})
    assert plan["keep"] == []
    assert plan["cancel"]
    c = _desired(settings_key="prayer=1|pre=0|sun=0")
    plan2 = reconcile(c, {x.id for x in a})
    assert plan2["keep"] == []


def test_dst_hhmm_changes_id():
    winter = alert_id(
        prayer="Dhuhr",
        local_date="2026-01-15",
        timezone="America/New_York",
        location_key="New York",
        settings_key="s",
        hhmm="12:10",
    )
    summer = alert_id(
        prayer="Dhuhr",
        local_date="2026-07-15",
        timezone="America/New_York",
        location_key="New York",
        settings_key="s",
        hhmm="13:10",
    )
    assert winter != summer


def test_midnight_rollover_drops_yesterday():
    now = datetime(2026, 8, 29, 0, 5)
    today = {k: v + timedelta(days=1) for k, v in TIMES.items()}
    desired = _desired(times=today, now=now)
    leftover = _desired()
    plan = reconcile(desired, {a.id for a in leftover})
    assert plan["keep"] == []


def test_permission_denied_and_disabled():
    assert permission_status("denied") == "denied"
    assert permission_status("deniedForever") == "deniedForever"
    assert _desired(permission="denied") == []
    assert _desired(enabled=False) == []
    assert _desired(timezone="UNKNOWN") == []
    assert _desired(times={}, now=datetime(2026, 8, 28, 4, 0)) == []


def test_pre_alerts_and_sunrise_opt_in():
    without = _desired(pre_minutes=0, include_sunrise=False)
    with_pre = _desired(pre_minutes=10, include_sunrise=True)
    assert len(with_pre) > len(without)
    assert any(a.kind == "pre" for a in with_pre)
    assert any(a.name == "Sunrise" for a in with_pre)


def test_notifications_remain_local_only():
    assert Settings().notifications_local_only is True
    assert Settings().precise_location_stored_on_server is False
