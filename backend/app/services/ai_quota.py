"""Per-user budget for the one endpoint that costs real money (QB-011).

Deliberately in-process, like the global limiter: one Render free-tier instance, one
dict, no shared store. That means the quota is PER INSTANCE and resets on restart — a
disclosed wall, not a hidden one. The honest answer when the ledger runs out is a 429
that says so, with the wait time in it.
"""

import os
import time
from collections import OrderedDict, deque

from ..config import get_settings

# The numbers live in Settings (env-tunable, single source of truth); these names exist
# so callers and tests read one obvious constant instead of digging through settings.
AI_ASK_LIMIT: int = get_settings().ai_ask_limit
AI_ASK_WINDOW_SECONDS: int = get_settings().ai_ask_window_seconds
_MAX_KEYS = 20_000


class QuotaLedger:
    """Sliding-window counter per key. `take` returns None when the request may run,
    or the number of seconds until a slot frees."""

    def __init__(self, *, limit: int, window_seconds: int, max_keys: int = _MAX_KEYS) -> None:
        self.limit = int(limit)
        self.window_seconds = int(window_seconds)
        self.max_keys = int(max_keys)
        self._hits: "OrderedDict[str, deque]" = OrderedDict()

    def take(self, key: str, now: float | None = None) -> float | None:
        now = time.monotonic() if now is None else now
        cutoff = now - self.window_seconds
        bucket = self._hits.get(key)
        if bucket is not None:
            while bucket and bucket[0] <= cutoff:
                bucket.popleft()
            if not bucket:
                # nothing inside the window any more: forget the key rather than keep
                # one deque per address that visited this process once
                del self._hits[key]
                bucket = None
        if bucket is None:
            bucket = deque()
            self._hits[key] = bucket
            self._bound_size()
        else:
            self._hits.move_to_end(key)
        if len(bucket) >= self.limit:
            return max(1.0, round(bucket[0] + self.window_seconds - now, 3))
        bucket.append(now)
        return None


    def prune(self, now: float | None = None) -> int:
        """Drop buckets with nothing inside the window. Called on every request path that
        already touches the store, so growth is bounded without a background task."""
        now = time.monotonic() if now is None else now
        cutoff = now - self.window_seconds
        empty = [key for key, bucket in self._hits.items() if not bucket or bucket[-1] <= cutoff]
        for key in empty:
            del self._hits[key]
        return len(empty)

    def _bound_size(self) -> None:
        while len(self._hits) > self.max_keys:
            self._hits.popitem(last=False)

    def reset(self) -> None:
        self._hits.clear()


_LEDGER = QuotaLedger(limit=AI_ASK_LIMIT, window_seconds=AI_ASK_WINDOW_SECONDS)


def take_ai_slot(user_id: str | int) -> float | None:
    return _LEDGER.take(str(user_id))


def reset_ai_quota_store() -> None:
    _LEDGER.reset()


def quota_debug() -> dict:
    """For /health-style introspection in dev only — counts, never identities."""
    return {"limit": _LEDGER.limit, "window_seconds": _LEDGER.window_seconds, "tracked": len(_LEDGER._hits)}
