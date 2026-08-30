"""Phase 4 continuation — refresh rotation, sessions, profile patch."""

from helpers import bearer, fresh_client, login, register
from app.security import hash_refresh_token
from app.services.merge import bookmark_set_merge, last_write_wins
from datetime import datetime, timezone


def test_login_issues_refresh_and_not_raw_hash():
    with fresh_client() as client:
        register(client)
        body = login(client).json()
        assert "access_token" in body
        refresh = body["refresh_token"]
        assert refresh
        assert "$" not in refresh
        assert hash_refresh_token(refresh) != refresh


def test_refresh_rotates_and_old_token_is_reuse():
    with fresh_client() as client:
        register(client)
        first = login(client).json()
        old = first["refresh_token"]
        rotated = client.post("/auth/refresh", json={"refresh_token": old})
        assert rotated.status_code == 200
        new = rotated.json()["refresh_token"]
        assert new != old
        reuse = client.post("/auth/refresh", json={"refresh_token": old})
        assert reuse.status_code == 401
        assert reuse.json()["detail"] == "refresh_reuse"


def test_refresh_garbage():
    with fresh_client() as client:
        r = client.post("/auth/refresh", json={"refresh_token": "nope"})
        assert r.status_code == 401


def test_logout_revokes_refresh():
    with fresh_client() as client:
        register(client)
        refresh = login(client).json()["refresh_token"]
        assert client.post("/auth/logout", json={"refresh_token": refresh}).status_code == 200
        again = client.post("/auth/refresh", json={"refresh_token": refresh})
        assert again.status_code == 401


def test_logout_without_body_still_ok():
    with fresh_client() as client:
        assert client.post("/auth/logout").status_code == 200


def test_sessions_list_and_revoke():
    with fresh_client() as client:
        headers = bearer(client)
        listed = client.get("/auth/sessions", headers=headers)
        assert listed.status_code == 200
        rows = listed.json()
        assert len(rows) >= 1
        sid = rows[0]["id"]
        deleted = client.delete(f"/auth/sessions/{sid}", headers=headers)
        assert deleted.status_code == 200
        missing = client.delete("/auth/sessions/999999", headers=headers)
        assert missing.status_code == 404


def test_session_idor():
    with fresh_client() as client:
        h1 = bearer(client, email="s1@e.com")
        h2 = bearer(client, email="s2@e.com")
        sid = client.get("/auth/sessions", headers=h1).json()[0]["id"]
        assert client.delete(f"/auth/sessions/{sid}", headers=h2).status_code == 404


def test_logout_all_requires_auth():
    with fresh_client() as client:
        assert client.post("/auth/logout-all").status_code == 401
        headers = bearer(client)
        refresh = login(client).json()["refresh_token"]
        assert client.post("/auth/logout-all", headers=headers).status_code == 200
        assert client.post("/auth/refresh", json={"refresh_token": refresh}).status_code == 401


def test_auth_me_and_patch():
    with fresh_client() as client:
        headers = bearer(client)
        me = client.get("/auth/me", headers=headers).json()
        assert me["is_premium"] is False
        patched = client.patch(
            "/users/me",
            json={"name": "N", "preferred_locale": "ur", "timezone": "Asia/Kolkata"},
            headers=headers,
        )
        assert patched.status_code == 200
        assert patched.json()["name"] == "N"
        assert patched.json()["preferred_locale"] == "ur"
        bad = client.patch("/users/me", json={"preferred_locale": "hi"}, headers=headers)
        assert bad.status_code == 400


def test_sync_batch_cap():
    with fresh_client() as client:
        headers = bearer(client)
        items = [
            {
                "collection": "quran",
                "item_id": str(i),
                "payload": {},
                "updated_at": datetime.now(timezone.utc).isoformat(),
                "deleted": False,
            }
            for i in range(501)
        ]
        r = client.post("/sync", json={"items": items}, headers=headers)
        assert r.status_code == 400
        assert r.json()["detail"] == "sync_batch_too_large"


def test_progress_upsert_same_kind():
    with fresh_client() as client:
        headers = bearer(client)
        client.post("/progress", json={"kind": "quran", "payload": {"surah": 1}}, headers=headers)
        client.post("/progress", json={"kind": "quran", "payload": {"surah": 2}}, headers=headers)
        listed = client.get("/progress", headers=headers).json()
        quran = [row for row in listed if row["kind"] == "quran"]
        assert len(quran) == 1
        assert quran[0]["payload"]["surah"] == 2


def test_bookmark_set_merge_and_lww():
    assert bookmark_set_merge(["1:1", "2:1"], ["2:1", "3:1"], ["3:1"]) == ["1:1", "2:1"]
    a = datetime(2026, 1, 1, tzinfo=timezone.utc)
    b = datetime(2026, 1, 2, tzinfo=timezone.utc)
    assert last_write_wins(b, a) == "a"


def test_refresh_token_not_in_login_logs_shape():
    with fresh_client() as client:
        register(client)
        body = login(client).json()
        assert "password" not in body
        assert "password_hash" not in body
        assert "token_hash" not in body
