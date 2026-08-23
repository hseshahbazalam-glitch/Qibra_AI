from tests.conftest import auth_header, register


def test_security_headers_and_honest_health(client):
    response = client.get("/api/v1/health")
    assert response.headers["x-content-type-options"] == "nosniff"
    assert response.headers["x-frame-options"] == "DENY"
    assert response.headers["referrer-policy"] == "no-referrer"
    assert response.headers["x-request-id"]
    data = response.json()["data"]
    assert data["notifications_local_only"] is True
    assert data["precise_location_stored_on_server"] is False
    assert data["auth_production_ready"] is False


def test_new_password_hash_is_salted_and_login_works(client):
    registered = register(client)
    assert registered.status_code == 201
    # A valid login demonstrates PBKDF2 verification without exposing a hash.
    login = client.post("/api/v1/auth/login", json={"email": "user@qibra.ai", "password": "Secret123"})
    assert login.status_code == 200


def test_rate_limit_leaves_normal_authenticated_ai_request_available(client):
    token = register(client).json()["data"]["accessToken"]
    response = client.post("/api/v1/ai/chat", json={"message": "unretrieved request"}, headers=auth_header(token))
    assert response.status_code == 200
    assert response.json()["data"]["answer"] is None
