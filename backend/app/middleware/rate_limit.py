import time
from collections import defaultdict, deque

from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import JSONResponse

WINDOW_SECONDS = 60
MAX_HITS = 60

# Per-instance buckets. Tests may call reset_rate_limit_store() so a combined
# pytest run does not leak 429s. Production limits stay 60/60s.
_STORE: dict[int, dict[str, deque[float]]] = {}


def reset_rate_limit_store() -> None:
    for buckets in _STORE.values():
        buckets.clear()


class RateLimitMiddleware(BaseHTTPMiddleware):
    def __init__(self, app, max_hits: int = MAX_HITS, window: int = WINDOW_SECONDS):
        super().__init__(app)
        self.max_hits = max_hits
        self.window = window
        self._hits: dict[str, deque[float]] = defaultdict(deque)
        _STORE[id(self)] = self._hits

    async def dispatch(self, request: Request, call_next):
        key = request.client.host if request.client else "unknown"
        now = time.time()
        bucket = self._hits[key]
        while bucket and now - bucket[0] > self.window:
            bucket.popleft()
        if len(bucket) >= self.max_hits:
            return JSONResponse({"detail": "rate_limited"}, status_code=429)
        bucket.append(now)
        return await call_next(request)
