from __future__ import annotations


def _auth(client):
    response = client.post(
        "/api/v1/auth/register",
        json={"email": "amina@example.com", "password": "Secret123", "name": "Amina"},
    )
    token = response.json()["data"]["token"]
    return {"Authorization": f"Bearer {token}"}


def test_profile_requires_auth(client):
    assert client.get("/api/v1/profile").status_code == 401


def test_profile_crud(client):
    headers = _auth(client)
    loaded = client.get("/api/v1/profile", headers=headers)
    assert loaded.status_code == 200
    assert loaded.json()["data"]["email"] == "amina@example.com"

    updated = client.put("/api/v1/profile", headers=headers, json={"name": "Amina Rahman", "language": "ur"})
    assert updated.status_code == 200
    assert updated.json()["data"]["name"] == "Amina Rahman"
    assert updated.json()["data"]["language"] == "ur"

    deleted = client.delete("/api/v1/profile", headers=headers)
    assert deleted.status_code == 200
    assert deleted.json()["data"]["deleted"] is True
    assert client.get("/api/v1/profile", headers=headers).status_code == 401


def test_flutter_profile_alias(client):
    headers = _auth(client)
    response = client.get("/v1/user/profile", headers=headers)
    assert response.status_code == 200
    assert response.json()["data"]["name"] == "Amina"
