"""Login-specific throttle (QB-013), separate from the global 60/60 limiter.

Two budgets, both counting FAILED attempts only:

* per IP — stops one address spraying passwords across many accounts;
* per account (canonical email) — stops many addresses working on one account, which a
  per-IP rule cannot see at all.

Traffic itself is already bounded by `RateLimitMiddleware`, so counting only failures
here means a busy office behind one NAT exit is never locked out by its own volume, and
an attacker cannot use the throttle to deny a real user their own account.

In-process on purpose (same disclosure as the AI quota and the global limiter): one
free-tier Render instance, no shared store, and the counters reset on a restart. The
IP is `request.client.host`, i.e. whatever uvicorn was told to trust — see the
`--proxy-headers` note in docs/DEPLOY.md. This module never reads `X-Forwarded-For`
itself: that header is a client's claim unless the proxy sets it.
"""

import time
from collections import OrderedDict, deque

LOGIN_WINDOW_SECONDS = 60
LOGIN_IP_MAX_FAILURES = 10
LOGIN_ACCOUNT_MAX_FAILURES = 5
LOGIN_MAX_KEYS = 10_000


def canonical_email(email: str) -> str:
    return (email or "").strip().lower()


class LoginGuard:
    def __init__(
        self,
        *,
        window_seconds: int = LOGIN_WINDOW_SECONDS,
        ip_max: int = LOGIN_IP_MAX_FAILURES,
        account_max: int = LOGIN_ACCOUNT_MAX_FAILURES,
        max_keys: int = LOGIN_MAX_KEYS,
    ) -> None:
        self.window_seconds = int(window_seconds)
        self.ip_max = int(ip_max)
        self.account_max = int(account_max)
        self.max_keys = int(max_keys)
        self.ip_buckets: "OrderedDict[str, deque]" = OrderedDict()
        self.account_buckets: "OrderedDict[str, deque]" = OrderedDict()

    # -- clock, so tests can stand on either side of the window without sleeping ----
    def _now(self) -> float:
        return time.monotonic()

    def check(self, *, ip: str, email: str, now: float | None = None) -> dict | None:
        """None when the attempt may run; otherwise the honest refusal body."""
        now = self._now() if now is None else now
        for store, limit, scope in (
            (self.account_buckets, self.account_max, "account"),
            (self.ip_buckets, self.ip_max, "ip"),
        ):
            bucket = store.get(self._key(scope, ip, email))
            if bucket is None:
                continue
            self._trim(bucket, now)
            if len(bucket) >= limit:
                retry = bucket[0] + self.window_seconds - now
                return {
                    "detail": "login_throttled",
                    "scope": scope,
                    "retry_after_seconds": max(1, int(round(retry))),
                }
        return None

    def record_failure(self, *, ip: str, email: str, now: float | None = None) -> None:
        now = self._now() if now is None else now
        for store, scope in ((self.ip_buckets, "ip"), (self.account_buckets, "account")):
            key = self._key(scope, ip, email)
            bucket = store.get(key)
            if bucket is None:
                bucket = deque()
                store[key] = bucket
            bucket.append(now)
            self._bound(store)

    def succeeded(self, *, ip: str, email: str) -> None:
        """A good password clears that account's failure budget. The IP budget is NOT
        cleared: the attempts that preceded the success still happened."""
        self.account_buckets.pop(canonical_email(email), None)

    def prune(self, now: float | None = None) -> int:
        """Drop buckets that have nothing left inside the window. Empty buckets are what
        turns a per-address map into a slow memory leak, and this is cheap enough to
        call from the request path (see `login_guard_note`)."""
        now = self._now() if now is None else now
        dropped = 0
        for store in (self.ip_buckets, self.account_buckets):
            for key in [k for k, b in store.items() if not b or b[-1] <= now - self.window_seconds]:
                del store[key]
                dropped += 1
        return dropped

    def stats(self) -> dict:
        return {
            "window_seconds": self.window_seconds,
            "ip_max": self.ip_max,
            "account_max": self.account_max,
            "ip_keys": len(self.ip_buckets),
            "account_keys": len(self.account_buckets),
        }

    # -- internals ------------------------------------------------------------------
    @staticmethod
    def _key(scope: str, ip: str, email: str) -> str:
        return (ip or "unknown") if scope == "ip" else canonical_email(email)

    def _trim(self, bucket: deque, now: float) -> None:
        cutoff = now - self.window_seconds
        while bucket and bucket[0] <= cutoff:
            bucket.popleft()

    def _bound(self, store: OrderedDict) -> None:
        while len(store) > self.max_keys:
            store.popitem(last=False)
        # opportunistic prune: the request path already holds the store open, and a
        # background task would need one more moving part to reason about
        if len(store) % 512 == 0:
            self.prune()


_GUARD = LoginGuard()


def check_login_attempt(*, ip: str, email: str) -> dict | None:
    return _GUARD.check(ip=ip, email=email)


def note_login_failure(*, ip: str, email: str) -> None:
    _GUARD.record_failure(ip=ip, email=email)


def note_login_success(*, ip: str, email: str) -> None:
    _GUARD.succeeded(ip=ip, email=email)


def reset_login_guard_store() -> None:
    _GUARD.ip_buckets.clear()
    _GUARD.account_buckets.clear()
