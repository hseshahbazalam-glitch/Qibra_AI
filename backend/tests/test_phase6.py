"""Phase 6 — merge last-write-wins."""

from datetime import datetime, timedelta, timezone

from app.services.merge import last_write_wins


def test_last_write_wins():
    now = datetime.now(timezone.utc)
    earlier = now - timedelta(minutes=5)
    assert last_write_wins(now, earlier) == "a"
    assert last_write_wins(earlier, now) == "b"
