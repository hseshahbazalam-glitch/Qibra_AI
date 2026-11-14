"""QB-013 — a login-specific throttle, per IP and per account, and a 429 that behaves
like every other response on this API.

Red first: the only limiter is the global 60/60 one, so a password attacker gets 60
tries a minute forever; its 429 is produced by a middleware that sits OUTSIDE
RequestId and SecurityHeaders, so the refusal carries neither `x-request-id` nor the
security headers; and nothing prunes the buckets, so the store only grows.
"""

import json
from pathlib import Path

from app.middleware.rate_limit import MAX_HITS, reset_rate_limit_store
from app.services.login_guard import (
    LOGIN_ACCOUNT_MAX_FAILURES,
    LOGIN_IP_MAX_FAILURES,
    LOGIN_WINDOW_SECONDS,
    LoginGuard,
)
from helpers import fresh_client, register

PASSWORD = "password1"


def _login(client, email, password=PASSWORD, **kw):
    return client.post("/auth/login", json={"email": email, "password": password, **kw})


def test_the_budgets_are_login_specific_and_stricter_than_global():
    assert LOGIN_WINDOW_SECONDS == 60
    assert LOGIN_IP_MAX_FAILURES < MAX_HITS
    assert LOGIN_ACCOUNT_MAX_FAILURES < LOGIN_IP_MAX_FAILURES
    assert (LOGIN_IP_MAX_FAILURES, LOGIN_ACCOUNT_MAX_FAILURES) == (10, 5)
    assert LOGIN_ACCOUNT_MAX_FAILURES < LOGIN_IP_MAX_FAILURES


def test_failed_logins_from_one_address_are_cut_off():
    with fresh_client() as client:
        # a distinct (non-existent) address per attempt, so only the IP budget can fill —
        # the account budget is smaller and would trip first on a single target
        codes = [
            _login(client, f"t{i}@e.com", "wrong" + str(i)).status_code
            for i in range(LOGIN_IP_MAX_FAILURES)
        ]
        assert codes == [401] * LOGIN_IP_MAX_FAILURES, codes
        limited = _login(client, "thief@e.com", "wrongagain")
        assert limited.status_code == 429
        body = limited.json()
        assert body["detail"] == "login_throttled"
        assert body["scope"] == "ip"
        assert 0 < body["retry_after_seconds"] <= LOGIN_WINDOW_SECONDS
        assert limited.headers["retry-after"] == str(body["retry_after_seconds"])


def test_one_account_gets_the_tighter_budget_before_the_ip_one():
    """5 failures on one address, all from this client: the account bucket (5) is
    smaller than the IP bucket (10), so the response must name the account scope."""
    with fresh_client() as client:
        register(client, email="target@e.com")
        for i in range(LOGIN_ACCOUNT_MAX_FAILURES):
            assert _login(client, "target@e.com", f"guess{i}").status_code == 401
        limited = _login(client, "target@e.com", "guess6")
        assert limited.status_code == 429
        assert limited.json()["scope"] == "account"
        # a different account on the same address is untouched
        register(client, email="neighbour@e.com")
        assert _login(client, "neighbour@e.com", PASSWORD).status_code == 200


def test_a_429_carries_the_same_headers_and_request_id_as_everything_else():
    with fresh_client() as client:
        register(client, email="hdr@e.com")
        for i in range(LOGIN_IP_MAX_FAILURES):
            _login(client, f"h{i}@e.com", f"nope{i}")
        limited = client.post(
            "/auth/login",
            json={"email": "hdr@e.com", "password": "nope"},
            headers={"X-Request-Id": "g2c-trace-1"},
        )
        assert limited.status_code == 429
        assert limited.headers["x-request-id"] == "g2c-trace-1"
        assert limited.headers["x-content-type-options"] == "nosniff"
        assert limited.headers["x-frame-options"] == "DENY"
        assert limited.headers["referrer-policy"] == "no-referrer"
        assert limited.headers["cache-control"] == "no-store"


def test_the_global_limiters_429_is_wrapped_the_same_way():
    """The middleware order is the fix: RequestId and SecurityHeaders now run OUTSIDE
    RateLimit, so even a limiter refusal is a fully-formed response."""
    with fresh_client() as client:
        reset_rate_limit_store()
        for _ in range(MAX_HITS):
            client.get("/health")
        limited = client.get("/health", headers={"X-Request-Id": "global-429"})
        assert limited.status_code == 429
        assert limited.json()["detail"] == "rate_limited"
        assert limited.headers["x-request-id"] == "global-429"
        assert limited.headers["x-content-type-options"] == "nosniff"
        reset_rate_limit_store()


def test_a_successful_login_resets_the_account_budget_but_not_the_ip_one():
    guard = LoginGuard(window_seconds=60, ip_max=6, account_max=2)
    for _ in range(2):
        assert guard.check(ip="1.1.1.1", email="a@e.com") is None
        guard.record_failure(ip="1.1.1.1", email="a@e.com")
    blocked = guard.check(ip="1.1.1.1", email="a@e.com")
    assert blocked is not None and blocked["scope"] == "account"
    guard.succeeded(ip="1.1.1.1", email="a@e.com")
    assert guard.check(ip="1.1.1.1", email="a@e.com") is None  # account budget restored
    # the IP budget keeps what it saw: four more failures and the address itself is
    # cut off, for every account, even one that never failed
    for i in range(6):
        guard.record_failure(ip="1.1.1.1", email=f"filler{i}@e.com")
    fresh = guard.check(ip="1.1.1.1", email="innocent@e.com")
    assert fresh is not None and fresh["scope"] == "ip"


def test_the_account_budget_follows_the_canonical_email_not_the_spelling():
    guard = LoginGuard(window_seconds=60, ip_max=100, account_max=2)
    for ip, email in (("9.9.9.9", " Victim@E.com "), ("9.9.9.8", "victim@e.com")):
        assert guard.check(ip=ip, email=email) is None
        guard.record_failure(ip=ip, email=email)
    blocked = guard.check(ip="9.9.9.7", email="VICTIM@E.COM")
    assert blocked is not None and blocked["scope"] == "account"


def test_empty_and_expired_buckets_are_pruned():
    guard = LoginGuard(window_seconds=1, ip_max=2, account_max=2)
    for i in range(20):
        guard.record_failure(ip=f"10.0.0.{i}", email=f"u{i}@e.com")
    assert len(guard.ip_buckets) > 0
    guard.prune(now=guard._now() + 10)
    assert guard.ip_buckets == {}
    assert guard.account_buckets == {}


def test_the_store_is_bounded_so_this_cannot_become_a_memory_attack():
    guard = LoginGuard(window_seconds=60, ip_max=2, account_max=2, max_keys=50)
    for i in range(400):
        guard.record_failure(ip=f"10.1.{i // 250}.{i % 250}", email=f"u{i}@e.com")
    assert len(guard.ip_buckets) <= 50
    assert len(guard.account_buckets) <= 50


def test_the_shared_store_resets_between_tests_like_the_global_one():
    from app.services.login_guard import reset_login_guard_store

    with fresh_client() as client:
        register(client, email="reset@e.com")
        for i in range(LOGIN_IP_MAX_FAILURES):
            _login(client, f"r{i}@e.com", f"nope{i}")
        assert _login(client, "reset@e.com", "nope").status_code == 429
        reset_login_guard_store()
        assert _login(client, "reset@e.com", PASSWORD).status_code == 200


def test_the_guard_counts_failures_only_not_traffic():
    """A busy office behind one NAT exit must not be locked out by its own volume — the
    global 60/60 limiter already covers traffic. Only failures are counted here."""
    guard = LoginGuard(window_seconds=60, ip_max=2, account_max=2)
    for _ in range(10):
        guard.succeeded(ip="5.5.5.5", email="busy@e.com")
    assert guard.check(ip="5.5.5.5", email="busy@e.com") is None


def test_proxy_headers_are_documented_and_not_forged_here():
    """Render terminates TLS, so request.client.host is the proxy unless uvicorn is
    told to trust X-Forwarded-For. Reading that header ourselves would trust any client
    that writes it — the flag belongs in the start command, which is a deploy decision."""
    deploy = (Path(__file__).resolve().parents[2] / "docs" / "DEPLOY.md").read_text(
        encoding="utf-8"
    )
    assert "--proxy-headers" in deploy
    assert "--forwarded-allow-ips" in deploy
    source = (
        Path(__file__).resolve().parents[1] / "app" / "services" / "login_guard.py"
    ).read_text(encoding="utf-8")
    assert ".headers" not in source, "the guard must not read request headers itself"
    assert "scope[" not in source, "nor dig into the ASGI scope"
    router = (
        Path(__file__).resolve().parents[1] / "app" / "routers" / "auth.py"
    ).read_text(encoding="utf-8")
    assert "request.client" in router


def test_the_quota_and_throttle_bodies_never_leak_the_password_or_the_hash():
    with fresh_client() as client:
        register(client, email="leak@e.com")
        for i in range(LOGIN_IP_MAX_FAILURES):
            _login(client, f"l{i}@e.com", f"nope{i}")
        limited = _login(client, "leak@e.com", "sup3rs3cret-attempt")
        blob = json.dumps(limited.json()).lower()
        assert "sup3rs3cret" not in blob
        assert "password" not in blob
