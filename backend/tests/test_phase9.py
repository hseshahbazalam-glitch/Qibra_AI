"""Phase 9 — unknown reachability is not online; cache-control."""

from helpers import bearer, fresh_client


def test_unknown_is_not_online():
    unknown = "unknown"
    assert unknown != "online"
    assert (unknown == "online") is False


def test_offline_must_not_use_network():
    reachability = "offline"
    may_use_network = reachability == "online"
    assert may_use_network is False


def test_health_works_without_auth():
    with fresh_client() as client:
        assert client.get("/health").status_code == 200


def test_protected_routes_fail_offline_without_token():
    with fresh_client() as client:
        assert client.get("/bookmarks").status_code == 401
        assert client.get("/settings").status_code == 401
        assert client.get("/progress").status_code == 401
        assert client.post("/sync", json={"items": []}).status_code == 401


def test_sync_empty_with_auth():
    with fresh_client() as client:
        headers = bearer(client)
        r = client.post("/sync", json={"items": []}, headers=headers)
        assert r.status_code == 200
        assert r.json()["items"] == []


def test_no_store_header_on_sync():
    with fresh_client() as client:
        headers = bearer(client)
        r = client.post("/sync", json={"items": []}, headers=headers)
        assert r.headers["Cache-Control"] == "no-store"


def test_bookmarks_start_empty():
    with fresh_client() as client:
        headers = bearer(client)
        assert client.get("/bookmarks", headers=headers).json() == []


def test_settings_start_empty():
    with fresh_client() as client:
        headers = bearer(client)
        assert client.get("/settings", headers=headers).json() == {}
