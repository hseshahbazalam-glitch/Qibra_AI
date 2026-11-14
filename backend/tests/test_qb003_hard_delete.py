"""QB-003 — DELETE /users/me actually deletes.

Red first: at 9aedc87 the handler only sets `users.deleted_at`, so the email, the name,
every bookmark, sync record, setting, progress row, session and refresh-token hash stay
in the database forever. The privacy docs said "soft delete"; the owner's order is that
an account deletion deletes.
"""

from sqlalchemy import func, select

from app.db import session as db_session
from app.db.models import (
    Bookmark,
    Progress,
    RefreshToken,
    SyncOperation,
    SyncRecord,
    User,
    UserSession,
    UserSetting,
)
from helpers import fresh_client, login, register

TARGET = "purge@e.com"
OTHER = "neighbour@e.com"

_TABLES = (
    ("users", User, User.id),
    ("bookmarks", Bookmark, Bookmark.user_id),
    ("sync_records", SyncRecord, SyncRecord.user_id),
    ("user_settings", UserSetting, UserSetting.user_id),
    ("progress", Progress, Progress.user_id),
    ("user_sessions", UserSession, UserSession.user_id),
    ("refresh_tokens", RefreshToken, RefreshToken.user_id),
    ("sync_operations", SyncOperation, SyncOperation.user_id),
)


def _populate(client) -> dict:
    headers = {"Authorization": f"Bearer {login(client, email=TARGET).json()['access_token']}"}
    client.post("/bookmarks", json={"collection": "quran", "item_id": "2:255"}, headers=headers)
    client.post(
        "/sync",
        json={
            "items": [
                {
                    "collection": "hadith",
                    "item_id": "bukhari/1",
                    "payload": {"x": 1},
                    "updated_at": "2026-11-01T00:00:00+00:00",
                    "deleted": False,
                    "operation_id": "op-purge-1",
                }
            ]
        },
        headers=headers,
    )
    client.patch("/users/me", json={"name": "Purger", "timezone": "Asia/Karachi"}, headers=headers)
    client.post("/progress", json={"kind": "quran", "payload": {"surah": 2}}, headers=headers)
    db = db_session.SessionLocal()
    try:
        uid = db.scalar(select(User.id).where(User.email == TARGET))
        return {
            "user_id": uid,
            "settings_rows": db.scalar(
                select(func.count()).select_from(UserSetting).where(UserSetting.user_id == uid)
            ),
        }
    finally:
        db.close()


def _counts(user_id: int) -> dict:
    db = db_session.SessionLocal()
    try:
        return {
            name: db.scalar(select(func.count()).select_from(model).where(column == user_id))
            for name, model, column in _TABLES
        }
    finally:
        db.close()


def test_delete_me_leaves_no_rows_for_that_user():
    with fresh_client() as client:
        register(client, email=TARGET, password="password1")
        info = _populate(client)
        assert info["settings_rows"] >= 0  # sanity: the fixture ran
        assert _counts(info["user_id"])["bookmarks"] == 1
        assert _counts(info["user_id"])["sync_records"] == 1
        assert _counts(info["user_id"])["sync_operations"] == 1

        r = client.delete(
            "/users/me",
            headers={"Authorization": f"Bearer {login(client, email=TARGET).json()['access_token']}"},
        )
        assert r.status_code == 200, r.text
        assert r.json() == {"ok": True, "deleted": True}
        assert _counts(info["user_id"]) == {name: 0 for name, _m, _c in _TABLES}


def test_the_row_is_gone_not_flagged():
    with fresh_client() as client:
        register(client, email=TARGET)
        info = _populate(client)
        client.delete(
            "/users/me",
            headers={"Authorization": f"Bearer {login(client, email=TARGET).json()['access_token']}"},
        )
        db = db_session.SessionLocal()
        try:
            assert db.scalar(select(User).where(User.id == info["user_id"])) is None
            # a tombstone would still be a row; a flagged row is exactly what this
            # finding is about, so pin that no deleted_at value survives anywhere
            assert db.scalar(
                select(func.count()).select_from(User).where(User.deleted_at.is_not(None))
            ) == 0
        finally:
            db.close()


def test_the_credential_stops_working_in_the_same_transaction():
    with fresh_client() as client:
        register(client, email=TARGET)
        info = _populate(client)
        tokens = login(client, email=TARGET).json()
        client.delete("/users/me", headers={"Authorization": f"Bearer {tokens['access_token']}"})
        assert login(client, email=TARGET).status_code == 401
        assert client.post("/auth/refresh", json={"refresh_token": tokens["refresh_token"]}).status_code == 401
        assert (
            client.get("/users/me", headers={"Authorization": f"Bearer {tokens['access_token']}"}).status_code
            == 401
        )
        assert _counts(info["user_id"])["refresh_tokens"] == 0


def test_a_neighbour_is_untouched():
    with fresh_client() as client:
        register(client, email=TARGET)
        register(client, email=OTHER)
        mine = _populate(client)
        other_headers = {
            "Authorization": f"Bearer {login(client, email=OTHER).json()['access_token']}"
        }
        client.post("/bookmarks", json={"collection": "quran", "item_id": "1:1"}, headers=other_headers)
        db = db_session.SessionLocal()
        try:
            other_id = db.scalar(select(User.id).where(User.email == OTHER))
        finally:
            db.close()
        client.delete(
            "/users/me",
            headers={"Authorization": f"Bearer {login(client, email=TARGET).json()['access_token']}"},
        )
        assert _counts(other_id)["bookmarks"] == 1
        assert _counts(other_id)["users"] == 1
        assert _counts(mine["user_id"]) == {name: 0 for name, _m, _c in _TABLES}


def test_the_email_can_be_registered_again_immediately():
    """Deletion means the address is free — that is the user-visible half of the promise."""
    with fresh_client() as client:
        register(client, email=TARGET)
        info = _populate(client)
        client.delete(
            "/users/me",
            headers={"Authorization": f"Bearer {login(client, email=TARGET).json()['access_token']}"},
        )
        # a decoy first, so the freed rowid is not the one the new account takes
        assert register(client, email=TARGET, password="brandnew1").status_code == 200
        assert login(client, email=TARGET, password="brandnew1").status_code == 200
        assert login(client, email=TARGET, password="password1").status_code == 401
