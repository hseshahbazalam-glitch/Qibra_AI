PROTECTED = [
    ("GET", "/api/v1/users/me"),
    ("GET", "/api/v1/bookmarks"),
    ("GET", "/api/v1/sync"),
    ("POST", "/api/v1/ai/chat"),
    ("GET", "/api/v1/billing/status"),
]


def test_protected_routes_require_auth(client):
    for method, path in PROTECTED:
        response = client.request(method, path, json={"message": "hi"})
        assert response.status_code == 401, path
        assert response.json()["success"] is False
