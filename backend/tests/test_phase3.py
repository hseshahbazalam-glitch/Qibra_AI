from app import __version__


def test_health_root(client):
    response = client.get("/health")
    assert response.status_code == 200
    body = response.json()
    assert body["success"] is True
    assert body["data"]["status"] == "ok"
    assert body["data"]["version"] == "0.6.0"
    assert __version__ == "0.6.0"


def test_health_api_v1(client):
    response = client.get("/api/v1/health")
    assert response.status_code == 200
    modules = response.json()["data"]["modules"]
    for name in ("health", "auth", "users", "bookmarks", "sync", "ai", "billing"):
        assert name in modules


def test_health_flutter_v1_alias(client):
    response = client.get("/v1/health")
    assert response.status_code == 200
    assert response.json()["data"]["version"] == "0.6.0"
