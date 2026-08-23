from tests.conftest import auth_header, register


def test_bad_login_is_unauthorized(client):
    register(client)
    response = client.post(
        "/api/v1/auth/login",
        json={"email": "user@qibra.ai", "password": "wrong-pass"},
    )
    assert response.status_code == 401
    assert response.json()["success"] is False


def test_logout_revokes_token(client):
    token = register(client).json()["data"]["accessToken"]
    logout = client.post("/api/v1/auth/logout", headers=auth_header(token))
    assert logout.status_code == 200
    me = client.get("/api/v1/users/me", headers=auth_header(token))
    assert me.status_code == 401


def test_forgot_password_does_not_reveal_account(client):
    response = client.post(
        "/api/v1/auth/forgot-password",
        json={"email": "missing@qibra.ai"},
    )
    assert response.status_code == 200
    assert response.json()["success"] is True
    assert "If that account exists" in response.json()["message"]
