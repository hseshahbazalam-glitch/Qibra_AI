"""QB-016 — a retried refresh inside a short grace window gets the SAME successor back,
and a rotation takes a row lock so two concurrent rotates cannot both win.

Red first: at 9aedc87 `rotate_refresh` revokes the whole family the moment it sees a
`revoked_at` row, so a phone that rotated successfully and never saw the response is
signed out with `refresh_reuse` — the single most common way a weak mobile link turns
into a lost account session. There is no window, and no lock.
"""

import re
from datetime import datetime, timedelta, timezone

from sqlalchemy import select
from sqlalchemy.dialects import postgresql

from app.config import Settings, get_settings
from app.db import session as db_session
from app.db.models import RefreshToken
from app.security import hash_refresh_token
from helpers import fresh_client, login, register

DEVICE_EMAIL = "retry@e.com"


def _backdate_rotation(old_raw: str, seconds: int) -> None:
    """Move the parent row's rotation stamp so a test can stand on either side of the
    window without sleeping."""
    db = db_session.SessionLocal()
    try:
        row = db.scalar(
            select(RefreshToken).where(RefreshToken.token_hash == hash_refresh_token(old_raw))
        )
        assert row is not None and row.rotated_at is not None, "no rotated row to move"
        row.rotated_at = datetime.now(timezone.utc) - timedelta(seconds=seconds)
        db.commit()
    finally:
        db.close()


def _rotate(client, token: str):
    return client.post("/auth/refresh", json={"refresh_token": token})


def test_window_default_is_30_seconds_and_configurable():
    assert Settings.refresh_reuse_grace_seconds == 30
    assert get_settings().refresh_reuse_grace_seconds == 30


def test_retry_inside_the_window_returns_the_same_successor():
    with fresh_client() as client:
        register(client, email=DEVICE_EMAIL)
        first = login(client, email=DEVICE_EMAIL).json()
        old = first["refresh_token"]
        rotated = _rotate(client, old)
        assert rotated.status_code == 200
        successor = rotated.json()["refresh_token"]

        # the same request again: the response was lost on the way to the phone
        retry = _rotate(client, old)
        assert retry.status_code == 200, (retry.status_code, retry.text)
        assert retry.json()["refresh_token"] == successor
        assert retry.json()["user_id"] == rotated.json()["user_id"]
        # and it is a different access token each time, as any refresh response is
        assert retry.json()["access_token"] != rotated.json()["access_token"]


def test_the_handed_back_successor_is_still_the_live_credential():
    with fresh_client() as client:
        register(client, email=DEVICE_EMAIL)
        old = login(client, email=DEVICE_EMAIL).json()["refresh_token"]
        successor = _rotate(client, old).json()["refresh_token"]
        assert _rotate(client, old).status_code == 200  # the retry
        # the app then carries on with the successor it now holds
        nxt = _rotate(client, successor)
        assert nxt.status_code == 200
        assert nxt.json()["refresh_token"] != successor
        # and the spent parent no longer replays: the window follows the rotation
        assert _rotate(client, old).status_code == 401


def test_reuse_outside_the_window_still_revokes_the_family():
    with fresh_client() as client:
        register(client, email=DEVICE_EMAIL)
        old = login(client, email=DEVICE_EMAIL).json()["refresh_token"]
        successor = _rotate(client, old).json()["refresh_token"]
        _backdate_rotation(old, 31)

        reuse = _rotate(client, old)
        assert reuse.status_code == 401
        assert reuse.json()["detail"] == "refresh_reuse"
        # the family is gone, including the successor the client was holding
        assert _rotate(client, successor).status_code == 401


def test_a_logout_revocation_has_no_successor_to_resurrect():
    """The window belongs to ROTATIONS. `revoked_at` without `rotated_at` is a logout,
    and a logout must never be talkable-out of."""
    with fresh_client() as client:
        register(client, email=DEVICE_EMAIL)
        token = login(client, email=DEVICE_EMAIL).json()["refresh_token"]
        assert client.post("/auth/logout", json={"refresh_token": token}).status_code == 200
        assert _rotate(client, token).status_code == 401


def test_window_never_revives_a_row_revoked_by_family_reuse():
    with fresh_client() as client:
        register(client, email=DEVICE_EMAIL)
        old = login(client, email=DEVICE_EMAIL).json()["refresh_token"]
        successor = _rotate(client, old).json()["refresh_token"]
        _backdate_rotation(old, 31)
        assert _rotate(client, old).status_code == 401  # trips the family revoke
        # the successor is now revoked WITHOUT rotated_at — the window must not help it
        assert _rotate(client, successor).status_code == 401


def test_the_rotation_lookup_asks_for_a_row_lock():
    """Two concurrent rotates of one token used to both read `revoked_at IS NULL` and
    both issue successors. The fix is to take the row lock; SQLite has no FOR UPDATE,
    so the pin is (a) the code path uses it and (b) the dialect that matters renders it."""
    from pathlib import Path

    source = (
        Path(__file__).resolve().parents[1] / "app" / "services" / "auth_service.py"
    ).read_text(encoding="utf-8")
    assert source.count("with_for_update()") >= 1

    stmt = (
        select(RefreshToken)
        .where(RefreshToken.token_hash == "x" * 64)
        .with_for_update()
        .compile(dialect=postgresql.dialect())
    )
    assert "FOR UPDATE" in str(stmt)


def test_the_window_is_a_single_source_of_truth():
    """Pinned so a magic number cannot appear in a second place: the grace value comes
    from Settings, and rotate_refresh reads it from there."""
    from pathlib import Path

    source = (
        Path(__file__).resolve().parents[1] / "app" / "services" / "auth_service.py"
    ).read_text(encoding="utf-8")
    body = source[source.index("def rotate_refresh") : source.index("def revoke_refresh")]
    assert "refresh_reuse_grace_seconds" in source
    assert "_grace_replay" in body  # the revoke path goes through the window check
    for number, line in enumerate(source.splitlines(), 1):
        if "grace" in line.lower():
            assert not re.search(r"\w\s*=\s*\d", line), f"line {number}: {line}"
