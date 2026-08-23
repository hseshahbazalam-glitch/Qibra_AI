from tests.conftest import auth_header, register


def test_sync_conflict_requires_pull(client):
    token = register(client).json()["data"]["accessToken"]
    headers = auth_header(token)
    client.post(
        "/api/v1/bookmarks",
        json={"kind": "ayah", "ref": "1:1"},
        headers=headers,
    )
    conflict = client.post(
        "/api/v1/sync",
        json={"clientRev": 0, "bookmarks": [{"kind": "ayah", "ref": "1:2"}]},
        headers=headers,
    )
    assert conflict.status_code == 409
    assert conflict.json()["success"] is False
    server = conflict.json()["data"]["server"]
    assert server["rev"] >= 1


def test_v1_alias_matches_api_v1(client):
    token = register(client).json()["data"]["accessToken"]
    a = client.get("/api/v1/users/me", headers=auth_header(token))
    b = client.get("/v1/users/me", headers=auth_header(token))
    assert a.status_code == 200
    assert b.status_code == 200
    assert a.json()["data"]["id"] == b.json()["data"]["id"]
