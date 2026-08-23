from app import __version__
from app.main import app


def test_version_is_060():
    assert __version__ == "0.6.0"
    assert app.version == "0.6.0"


def test_phase15_surface_is_mounted(client):
    paths = {route.path for route in app.routes}
    expected = {
        "/health",
        "/api/v1/health",
        "/api/v1/auth/login",
        "/api/v1/auth/register",
        "/api/v1/auth/logout",
        "/api/v1/auth/forgot-password",
        "/api/v1/users/me",
        "/api/v1/profile",
        "/api/v1/bookmarks",
        "/api/v1/sync",
        "/api/v1/ai/chat",
        "/api/v1/ai/ayah",
        "/api/v1/ai/hadith",
        "/api/v1/ai/dua",
        "/api/v1/billing/plans",
        "/api/v1/billing/checkout",
        "/api/v1/billing/status",
        "/api/v1/billing/webhook",
        "/v1/health",
    }
    missing = expected - paths
    assert not missing, missing


def test_health_lists_required_modules(client):
    modules = client.get("/api/v1/health").json()["data"]["modules"]
    assert modules == [
        "health",
        "auth",
        "users",
        "bookmarks",
        "sync",
        "ai",
        "billing",
    ]
