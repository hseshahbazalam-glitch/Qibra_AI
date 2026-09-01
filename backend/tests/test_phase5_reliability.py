"""Phase 5 — family reuse, idempotent sync, account delete revokes sessions."""

from datetime import datetime, timedelta, timezone

from sqlalchemy import select

from helpers import bearer, fresh_client, login, register


def test_refresh_reuse_invalidates_family():
    with fresh_client() as client:
        register(client)
        first = login(client).json()
        old = first["refresh_token"]
        rotated = client.post("/auth/refresh", json={"refresh_token": old}).json()
        new = rotated["refresh_token"]
        reuse = client.post("/auth/refresh", json={"refresh_token": old})
        assert reuse.status_code == 401
        assert client.post("/auth/refresh", json={"refresh_token": new}).status_code == 401


def test_delete_me_revokes_refresh():
    with fresh_client() as client:
        headers = bearer(client, email="gone2@e.com")
        refresh = login(client, email="gone2@e.com").json()["refresh_token"]
        assert client.delete("/users/me", headers=headers).status_code == 200
        assert client.post("/auth/refresh", json={"refresh_token": refresh}).status_code == 401


def test_sync_idempotent_operation_id():
    with fresh_client() as client:
        headers = bearer(client)
        now = datetime.now(timezone.utc).isoformat()
        payload = {
            "items": [
                {
                    "collection": "quran",
                    "item_id": "2:255",
                    "payload": {"surah": 2, "ayah": 255},
                    "updated_at": now,
                    "deleted": False,
                    "operation_id": "op-1",
                }
            ]
        }
        a = client.post("/sync", json=payload, headers=headers)
        b = client.post("/sync", json=payload, headers=headers)
        assert a.status_code == 200
        assert b.status_code == 200
        assert b.json()["results"][0]["reason"] == "idempotent"


def test_sync_partial_bad_item_does_not_abort():
    with fresh_client() as client:
        headers = bearer(client)
        now = datetime.now(timezone.utc).isoformat()
        r = client.post(
            "/sync",
            json={
                "items": [
                    {
                        "collection": "",
                        "item_id": "",
                        "payload": {},
                        "updated_at": now,
                        "deleted": False,
                    },
                    {
                        "collection": "hadith",
                        "item_id": "bukhari:1",
                        "payload": {},
                        "updated_at": now,
                        "deleted": False,
                    },
                ]
            },
            headers=headers,
        )
        assert r.status_code == 200
        statuses = [row["status"] for row in r.json()["results"]]
        assert "rejected" in statuses
        assert "accepted" in statuses


def test_bookmarks_pagination_empty():
    with fresh_client() as client:
        headers = bearer(client)
        assert client.get("/bookmarks?limit=10&offset=0", headers=headers).json() == []


def test_expired_refresh_fails():
    with fresh_client() as client:
        register(client)
        refresh = login(client).json()["refresh_token"]
        from app.db.models import RefreshToken
        from app.db.session import SessionLocal
        from app.security import hash_refresh_token

        db = SessionLocal()
        row = db.scalar(
            select(RefreshToken).where(
                RefreshToken.token_hash == hash_refresh_token(refresh)
            )
        )
        assert row is not None
        row.expires_at = datetime.now(timezone.utc) - timedelta(days=1)
        db.commit()
        db.close()
        assert client.post("/auth/refresh", json={"refresh_token": refresh}).status_code == 401


def test_production_sqlite_refused(monkeypatch):
    monkeypatch.setenv("QIBRA_ENV", "production")
    from app.db.session import _make_engine
    import pytest

    with pytest.raises(RuntimeError):
        _make_engine("sqlite+pysqlite:///:memory:")
