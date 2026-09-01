"""Phase 6 — last-write-wins merge."""

from datetime import datetime, timedelta, timezone

from app.services.merge import last_write_wins


def _ts(minutes=0):
    return datetime(2026, 8, 28, 12, 0, tzinfo=timezone.utc) + timedelta(minutes=minutes)


def test_newer_a_wins():
    assert last_write_wins(_ts(5), _ts(0)) == "a"


def test_newer_b_wins():
    assert last_write_wins(_ts(0), _ts(5)) == "b"


def test_equal_timestamps_prefer_a():
    now = _ts()
    assert last_write_wins(now, now) == "a"


def test_naive_datetimes_compare():
    a = datetime(2026, 8, 28, 13, 0)
    b = datetime(2026, 8, 28, 12, 0)
    assert last_write_wins(a, b) == "a"


def test_far_future_b():
    assert last_write_wins(_ts(), _ts(60 * 24)) == "b"


def test_far_past_b():
    assert last_write_wins(_ts(), _ts(-60)) == "a"


def test_order_is_only_a_or_b():
    assert last_write_wins(_ts(1), _ts(2)) in {"a", "b"}


def test_minute_resolution():
    assert last_write_wins(_ts(1), _ts(2)) == "b"
    assert last_write_wins(_ts(3), _ts(2)) == "a"
