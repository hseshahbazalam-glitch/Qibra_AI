from __future__ import annotations

ENVELOPE = {"success", "message", "data", "timestamp", "traceId"}


def test_register_login_logout_and_forgot_password(client):
    register = client.post(
        "/api/v1/auth/register",
        json={"email": "samir@example.com", "password": "Secret123", "name": "Samir"},
    )
    assert register.status_code == 201
    body = register.json()
    assert ENVELOPE <= set(body)
    assert body["success"] is True
    token = body["data"]["token"]
    assert token

    duplicate = client.post(
        "/api/v1/auth/register",
        json={"email": "samir@example.com", "password": "Secret123", "name": "Samir"},
    )
    assert duplicate.status_code == 409
    assert duplicate.json()["success"] is False

    bad = client.post(
        "/api/v1/auth/login",
        json={"email": "samir@example.com", "password": "wrongpass"},
    )
    assert bad.status_code == 401

    login = client.post(
        "/api/v1/auth/login",
        json={"email": "samir@example.com", "password": "Secret123"},
    )
    assert login.status_code == 200
    login_token = login.json()["data"]["token"]

    logout = client.post(
        "/api/v1/auth/logout",
        headers={"Authorization": f"Bearer {login_token}"},
    )
    assert logout.status_code == 200
    assert logout.json()["data"]["logged_out"] is True

    blocked = client.get(
        "/api/v1/profile",
        headers={"Authorization": f"Bearer {login_token}"},
    )
    assert blocked.status_code == 401

    forgot = client.post("/api/v1/auth/forgot-password", json={"email": "missing@example.com"})
    assert forgot.status_code == 200
    assert forgot.json()["success"] is True
    assert "If an account exists" in forgot.json()["message"]


def test_register_rejects_invalid_email(client):
    response = client.post(
        "/api/v1/auth/register",
        json={"email": "not-an-email", "password": "Secret123", "name": "Noor"},
    )
    assert response.status_code == 400
    assert response.json()["success"] is False
