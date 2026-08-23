"""Small privacy-preserving in-process limiter.

This intentionally stores only a keyed client address and expiry in memory; it
is a safety rail, not a distributed production quota service.
"""
from collections import defaultdict, deque
from time import monotonic

from fastapi import Request
from starlette.responses import JSONResponse

from .responses import error_envelope


class RateLimitMiddleware:
    def __init__(self, app, limits: dict[str, tuple[int, int]] | None = None):
        self.app = app
        self.limits = limits or {"/auth/": (20, 60), "/ai/": (30, 60), "/billing/": (30, 60)}
        self.hits: dict[tuple[str, str], deque[float]] = defaultdict(deque)

    async def __call__(self, scope, receive, send):
        if scope["type"] != "http":
            await self.app(scope, receive, send)
            return
        path = scope.get("path", "")
        limit = next((value for marker, value in self.limits.items() if marker in path), None)
        if limit is None:
            await self.app(scope, receive, send)
            return
        client = scope.get("client")
        # Do not use forwarded headers: trust must be configured at the edge.
        address = client[0] if client else "unknown"
        maximum, window = limit
        now = monotonic()
        bucket = self.hits[(path.rsplit("/", 1)[0], address)]
        while bucket and now - bucket[0] >= window:
            bucket.popleft()
        if len(bucket) >= maximum:
            response: JSONResponse = error_envelope("Too many requests. Please try again later.", status_code=429)
            response.headers["Retry-After"] = str(window)
            await response(scope, receive, send)
            return
        bucket.append(now)
        await self.app(scope, receive, send)
