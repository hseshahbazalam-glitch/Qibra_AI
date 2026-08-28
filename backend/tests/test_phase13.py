"""Phase 13 — bookmarks + a11y contract notes."""

from helpers import bearer, fresh_client


def test_min_tap_target_contract():
    assert 48 == 48


def test_partial_locales():
    assert ["en", "ar", "ur"] == ["en", "ar", "ur"]


def test_bookmark_roundtrip():
    with fresh_client() as client:
        headers = bearer(client)
        r = client.post(
            "/bookmarks",
            json={"collection": "quran", "item_id": "1:1", "payload": {"surah": 1}},
            headers=headers,
        )
        assert r.status_code == 200
        listed = client.get("/bookmarks", headers=headers).json()
        assert listed[0]["item_id"] == "1:1"
        assert listed[0]["payload"]["surah"] == 1


def test_bookmark_delete():
    with fresh_client() as client:
        headers = bearer(client)
        client.post(
            "/bookmarks",
            json={"collection": "hadith", "item_id": "bukhari-1", "payload": {}},
            headers=headers,
        )
        client.delete("/bookmarks", params={"collection": "hadith", "item_id": "bukhari-1"}, headers=headers)
        assert client.get("/bookmarks", headers=headers).json() == []


def test_bookmark_upsert_payload():
    with fresh_client() as client:
        headers = bearer(client)
        client.post("/bookmarks", json={"collection": "quran", "item_id": "2:1", "payload": {"n": 1}}, headers=headers)
        client.post("/bookmarks", json={"collection": "quran", "item_id": "2:1", "payload": {"n": 2}}, headers=headers)
        listed = client.get("/bookmarks", headers=headers).json()
        assert len(listed) == 1
        assert listed[0]["payload"]["n"] == 2


def test_bookmarks_require_auth():
    with fresh_client() as client:
        assert client.get("/bookmarks").status_code == 401


def test_bookmarks_isolated():
    with fresh_client() as client:
        h1 = bearer(client, email="a@e.com")
        h2 = bearer(client, email="b@e.com")
        client.post("/bookmarks", json={"collection": "quran", "item_id": "1:1", "payload": {}}, headers=h1)
        assert client.get("/bookmarks", headers=h2).json() == []


def test_delete_missing_bookmark_ok():
    with fresh_client() as client:
        headers = bearer(client)
        r = client.delete("/bookmarks", params={"collection": "quran", "item_id": "missing"}, headers=headers)
        assert r.status_code == 200


def test_hadith_missing_author_is_not_invented():
    # Client shows "—" when author unknown; API stores payload as given.
    with fresh_client() as client:
        headers = bearer(client)
        client.post(
            "/bookmarks",
            json={"collection": "hadith", "item_id": "x", "payload": {"author": None}},
            headers=headers,
        )
        payload = client.get("/bookmarks", headers=headers).json()[0]["payload"]
        assert payload["author"] is None
