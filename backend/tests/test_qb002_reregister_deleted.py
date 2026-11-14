"""QB-002 — re-registering over a soft-deleted account is a decision, not a 500.

Red first: `auth_service.register()` at 9aedc87 skips the `email_taken` raise when the
existing row has `deleted_at` set, then INSERTs a second row with the same UNIQUE email —
which raises IntegrityError out of `db.commit()` and reaches the client as a 500.
"""

from datetime import datetime, timezone

import pytest

from sqlalchemy import func, select

from app.db import session as db_session
from app.db.models import Bookmark, RefreshToken, SyncRecord, User, UserSession
from helpers import fresh_client, login, register

LEGACY = "legacy@e.com"


def _soft_delete(email: str) -> dict:
    """Reproduce a row written BEFORE QB-003: deleted_at set, body of the account intact."""
    db = db_session.SessionLocal()
    try:
        row = db.scalar(select(User).where(User.email == email))
        row.deleted_at = datetime.now(timezone.utc)
        db.commit()
        return {"id": row.id, "name": row.name, "password_hash": row.password_hash}
    finally:
        db.close()


def _rows_for(user_id: int) -> dict:
    db = db_session.SessionLocal()
    try:
        return {
            "users": db.scalar(
                select(func.count()).select_from(User).where(User.id == user_id)
            ),
            "bookmarks": db.scalar(
                select(func.count()).select_from(Bookmark).where(Bookmark.user_id == user_id)
            ),
            "sync": db.scalar(
                select(func.count()).select_from(SyncRecord).where(SyncRecord.user_id == user_id)
            ),
            "sessions": db.scalar(
                select(func.count())
                .select_from(UserSession)
                .where(UserSession.user_id == user_id)
            ),
            "refresh": db.scalar(
                select(func.count())
                .select_from(RefreshToken)
                .where(RefreshToken.user_id == user_id)
            ),
        }
    finally:
        db.close()


def test_reregistering_a_soft_deleted_email_is_not_a_500():
    with fresh_client() as client:
        register(client, email="decoy@e.com")  # keeps the rowid allocator honest
        assert register(client, email=LEGACY, password="password1").status_code == 200
        before = _soft_delete(LEGACY)
        again = client.post(
            "/auth/register",
            json={"email": LEGACY, "password": "another1", "name": "Fresh"},
        )
        assert again.status_code == 200, (again.status_code, again.text)
        # whatever rowid the new account lands on (SQLite reuses freed ones), the
        # tombstone's OWN data is gone and the new row is not the old row re-used
        rows = _rows_for(before["id"])
        assert rows["users"] in (0, 1), rows
        for key in ("bookmarks", "sync", "sessions", "refresh"):
            assert rows[key] == 0, rows
        db = db_session.SessionLocal()
        try:
            fresh = db.scalar(select(User).where(User.email == LEGACY))
            assert fresh is not None and fresh.deleted_at is None
            assert fresh.password_hash != before["password_hash"]
            assert fresh.name == "Fresh"
        finally:
            db.close()


def test_a_purged_account_does_not_hand_over_its_data_or_its_password():
    with fresh_client() as client:
        register(client, email=LEGACY, password="password1")
        headers = {"Authorization": f"Bearer {login(client, email=LEGACY).json()['access_token']}"}
        client.post("/bookmarks", json={"collection": "quran", "item_id": "1:1"}, headers=headers)
        before = _soft_delete(LEGACY)
        assert _rows_for(before["id"])["bookmarks"] == 1

        client.post(
            "/auth/register", json={"email": LEGACY, "password": "another1", "name": "Fresh"}
        )
        # the OLD password can no longer sign in anywhere, and neither can it have
        # inherited the old row's bookmark
        assert login(client, email=LEGACY, password="password1").status_code == 401
        assert login(client, email=LEGACY, password="another1").status_code == 200
        new_id = db_session.SessionLocal().scalar(
            select(User.id).where(User.email == LEGACY)
        )
        assert _rows_for(new_id)["bookmarks"] == 0


def test_live_account_still_conflicts():
    with fresh_client() as client:
        assert register(client, email="live@e.com").status_code == 200
        again = register(client, email="live@e.com")
        assert again.status_code == 409
        assert again.json()["detail"] == "email_taken"


def test_a_unique_race_becomes_409_not_a_500(monkeypatch):
    """The row can be committed between the lookup and the INSERT. What matters is that
    the losing writer is told "taken", not shown a stack trace."""
    from sqlalchemy.exc import IntegrityError

    import app.routers.auth as auth_router

    def boom(*_args, **_kwargs):
        raise IntegrityError("INSERT INTO users ...", {}, Exception("UNIQUE constraint"))

    monkeypatch.setattr(auth_router, "register", boom)
    with fresh_client() as client:
        r = client.post(
            "/auth/register", json={"email": "race@e.com", "password": "password1"}
        )
        assert r.status_code == 409, (r.status_code, r.text)
        assert r.json()["detail"] == "email_taken"


class _BlindLookup:
    """A session whose SELECT sees nothing, so the INSERT reaches the UNIQUE index.

    That is the race: another writer committed between our lookup and our insert. The
    service must still answer "email_taken", and must not leak IntegrityError to a
    non-HTTP caller.
    """

    def __init__(self, inner) -> None:
        self._inner = inner

    def scalar(self, *_args, **_kwargs):
        return None

    def __getattr__(self, name):
        return getattr(self._inner, name)


def test_service_translates_a_unique_violation_into_email_taken():
    from sqlalchemy.exc import IntegrityError

    from app.services import auth_service as service

    with fresh_client() as client:
        register(client, email="race2@e.com")
        db = db_session.SessionLocal()
        try:
            try:
                service.register(_BlindLookup(db), "race2@e.com", "password1", "R")
            except service.AuthError as exc:
                assert exc.status == 409
                assert str(exc) == "email_taken"
            except IntegrityError:
                pytest.fail("IntegrityError escaped the service — that is a 500 in production")
            else:
                pytest.fail("a duplicate row was created without any error at all")
        finally:
            db.close()
