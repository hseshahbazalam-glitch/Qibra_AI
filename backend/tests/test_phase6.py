from tests.conftest import auth_header, register


def test_users_me_requires_auth(client):
    response = client.get("/api/v1/users/me")
    assert response.status_code == 401


def test_profile_round_trip(client):
    token = register(client).json()["data"]["accessToken"]
    headers = auth_header(token)
    me = client.get("/api/v1/users/me", headers=headers)
    assert me.status_code == 200
    updated = client.put("/api/v1/profile", json={"name": "Noor"}, headers=headers)
    assert updated.status_code == 200
    assert updated.json()["data"]["name"] == "Noor"
    profile = client.get("/api/v1/profile", headers=headers)
    assert profile.json()["data"]["name"] == "Noor"


def test_delete_profile(client):
    token = register(client).json()["data"]["accessToken"]
    deleted = client.delete("/api/v1/profile", headers=auth_header(token))
    assert deleted.status_code == 200
    assert deleted.json()["data"]["deleted"] is True
    again = client.get("/api/v1/users/me", headers=auth_header(token))
    assert again.status_code == 401
