"""Phase 5 — logout, delete, rate limit, headers."""

from helpers import bearer, fresh_client, login, register
from app.middleware.rate_limit import RateLimitMiddleware
from starlette.applications import Starlette
from starlette.responses import PlainTextResponse
from starlette.routing import Route
from starlette.testclient import TestClient


def test_logout_ok():
    with fresh_client() as client:
        r = client.post("/auth/logout")
        assert r.status_code == 200
        assert r.json()["ok"] is True


def test_delete_account_then_me_fails():
    with fresh_client() as client:
        headers = bearer(client, email="d@e.com", name="D")
        deleted = client.delete("/users/me", headers=headers)
        assert deleted.status_code == 200
        assert client.get("/users/me", headers=headers).status_code == 401


def test_deleted_user_cannot_login():
    with fresh_client() as client:
        headers = bearer(client, email="gone@e.com")
        client.delete("/users/me", headers=headers)
        assert login(client, email="gone@e.com").status_code == 401


def test_delete_requires_auth():
    with fresh_client() as client:
        assert client.delete("/users/me").status_code == 401


def test_rate_limit_defaults():
    from app.middleware.rate_limit import MAX_HITS, WINDOW_SECONDS

    assert RateLimitMiddleware is not None
    assert MAX_HITS == 60
    assert WINDOW_SECONDS == 60


def test_rate_limit_returns_429():
    async def ping(_):
        return PlainTextResponse("ok")

    app = Starlette(routes=[Route("/ping", ping)])
    app.add_middleware(RateLimitMiddleware, max_hits=2, window=60)
    with TestClient(app) as client:
        assert client.get("/ping").status_code == 200
        assert client.get("/ping").status_code == 200
        limited = client.get("/ping")
        assert limited.status_code == 429
        assert limited.json()["detail"] == "rate_limited"


def test_security_headers_on_auth_error():
    with fresh_client() as client:
        r = client.get("/users/me")
        assert r.headers["X-Content-Type-Options"] == "nosniff"
        assert r.headers["X-Frame-Options"] == "DENY"


def test_register_then_second_user_isolated():
    with fresh_client() as client:
        h1 = bearer(client, email="one@e.com", name="One")
        h2 = bearer(client, email="two@e.com", name="Two")
        assert client.get("/users/me", headers=h1).json()["email"] == "one@e.com"
        assert client.get("/users/me", headers=h2).json()["email"] == "two@e.com"


def test_logout_does_not_require_token():
    with fresh_client() as client:
        register(client)
        assert client.post("/auth/logout").status_code == 200
