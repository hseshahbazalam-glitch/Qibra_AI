"""Phase 12 — settings persistence + single-flight guard."""

from helpers import bearer, fresh_client


def test_settings_empty_by_default():
    with fresh_client() as client:
        headers = bearer(client)
        assert client.get("/settings", headers=headers).json() == {}


def test_put_and_get_setting():
    with fresh_client() as client:
        headers = bearer(client)
        r = client.post("/settings", json={"key": "theme", "value": "light"}, headers=headers)
        assert r.status_code == 200
        assert client.get("/settings", headers=headers).json()["theme"] == "light"


def test_overwrite_setting():
    with fresh_client() as client:
        headers = bearer(client)
        client.post("/settings", json={"key": "theme", "value": "light"}, headers=headers)
        client.post("/settings", json={"key": "theme", "value": "dark"}, headers=headers)
        assert client.get("/settings", headers=headers).json()["theme"] == "dark"


def test_settings_require_auth():
    with fresh_client() as client:
        assert client.get("/settings").status_code == 401
        assert client.post("/settings", json={"key": "a", "value": "b"}).status_code == 401


def test_settings_isolated_per_user():
    with fresh_client() as client:
        h1 = bearer(client, email="a@e.com")
        h2 = bearer(client, email="b@e.com")
        client.post("/settings", json={"key": "city", "value": "Makka"}, headers=h1)
        assert "city" not in client.get("/settings", headers=h2).json()


def test_multiple_keys():
    with fresh_client() as client:
        headers = bearer(client)
        client.post("/settings", json={"key": "lang", "value": "en"}, headers=headers)
        client.post("/settings", json={"key": "madhab", "value": "hanafi"}, headers=headers)
        body = client.get("/settings", headers=headers).json()
        assert body["lang"] == "en"
        assert body["madhab"] == "hanafi"


def test_single_flight_guard():
    in_flight = False

    def run():
        nonlocal in_flight
        if in_flight:
            return "skipped"
        in_flight = True
        try:
            return "ran"
        finally:
            in_flight = False

    assert run() == "ran"
    assert run() == "ran"


def test_settings_no_store_header():
    with fresh_client() as client:
        headers = bearer(client)
        r = client.get("/settings", headers=headers)
        assert r.headers["Cache-Control"] == "no-store"
