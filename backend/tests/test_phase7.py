from tests.conftest import auth_header, register


def test_bookmark_create_list_delete(client):
    token = register(client).json()["data"]["accessToken"]
    headers = auth_header(token)
    created = client.post(
        "/api/v1/bookmarks",
        json={"kind": "ayah", "ref": "2:255", "note": "Ayat al-Kursi"},
        headers=headers,
    )
    assert created.status_code == 201
    bookmark_id = created.json()["data"]["id"]
    listed = client.get("/api/v1/bookmarks", headers=headers)
    assert listed.json()["data"]["count"] == 1
    deleted = client.delete(f"/api/v1/bookmarks/{bookmark_id}", headers=headers)
    assert deleted.status_code == 200
    empty = client.get("/api/v1/bookmarks", headers=headers)
    assert empty.json()["data"]["count"] == 0


def test_missing_bookmark_is_404(client):
    token = register(client).json()["data"]["accessToken"]
    response = client.delete("/api/v1/bookmarks/missing", headers=auth_header(token))
    assert response.status_code == 404
