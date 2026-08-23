def test_envelope_keys_on_success_and_error(client):
    ok = client.get("/api/v1/health").json()
    for key in ("success", "message", "data", "timestamp", "traceId"):
        assert key in ok
    bad = client.post("/api/v1/auth/login", json={"email": "not-an-email"})
    assert bad.status_code == 422
    body = bad.json()
    assert body["success"] is False
    for key in ("success", "message", "data", "timestamp", "traceId"):
        assert key in body


def test_unknown_route_is_not_success(client):
    response = client.get("/api/v1/does-not-exist")
    assert response.status_code == 404
