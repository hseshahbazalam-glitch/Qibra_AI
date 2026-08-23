from tests.conftest import auth_header, register


def test_sync_pull_and_push(client):
    token = register(client).json()["data"]["accessToken"]
    headers = auth_header(token)
    pulled = client.get("/api/v1/sync", headers=headers)
    assert pulled.status_code == 200
    rev = pulled.json()["data"]["rev"]
    pushed = client.post(
        "/api/v1/sync",
        json={
            "clientRev": rev,
            "profile": {"name": "Synced"},
            "bookmarks": [{"kind": "hadith", "ref": "bukhari:1"}],
        },
        headers=headers,
    )
    assert pushed.status_code == 200
    body = pushed.json()["data"]
    assert body["profile"]["name"] == "Synced"
    assert len(body["bookmarks"]) == 1
