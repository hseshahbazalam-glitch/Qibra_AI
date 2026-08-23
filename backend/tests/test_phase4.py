from tests.conftest import register


def test_register_returns_envelope_and_token(client):
    response = register(client)
    assert response.status_code == 201
    body = response.json()
    assert body["success"] is True
    assert body["data"]["user"]["email"] == "user@qibra.ai"
    assert body["data"]["accessToken"]


def test_duplicate_register_is_conflict(client):
    assert register(client).status_code == 201
    again = register(client)
    assert again.status_code == 409
    assert again.json()["success"] is False


def test_login_success(client):
    register(client)
    response = client.post(
        "/api/v1/auth/login",
        json={"email": "user@qibra.ai", "password": "Secret123"},
    )
    assert response.status_code == 200
    assert response.json()["data"]["user"]["name"] == "Amina"
