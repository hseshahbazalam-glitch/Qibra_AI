"""In-process counters. No user ids. Not an analytics export."""

from __future__ import annotations

from collections import defaultdict

from .allowlist import is_forbidden

_COUNTERS: dict[str, int] = defaultdict(int)
_LATENCY_SUM_MS: float = 0.0
_LATENCY_COUNT: int = 0
_MAX_KEYS = 64


def reset_metrics() -> None:
    _COUNTERS.clear()
    global _LATENCY_SUM_MS, _LATENCY_COUNT
    _LATENCY_SUM_MS = 0.0
    _LATENCY_COUNT = 0


def inc(name: str, n: int = 1) -> None:
    if not name or is_forbidden(name):
        return
    if name not in _COUNTERS and len(_COUNTERS) >= _MAX_KEYS:
        return
    _COUNTERS[name] += n


def observe_ms(ms: float) -> None:
    global _LATENCY_SUM_MS, _LATENCY_COUNT
    if ms < 0:
        return
    _LATENCY_SUM_MS += ms
    _LATENCY_COUNT += 1


def snapshot() -> dict:
    avg = (_LATENCY_SUM_MS / _LATENCY_COUNT) if _LATENCY_COUNT else 0.0
    return {
        "analytics_production_ready": False,
        "consent_default": False,
        "third_party_sdks": [],
        "counters": dict(_COUNTERS),
        "api": {
            "latency_ms_sum": round(_LATENCY_SUM_MS, 3),
            "latency_ms_count": _LATENCY_COUNT,
            "latency_ms_avg": round(avg, 3),
        },
    }


def note_crash() -> None:
    inc("crash_hook")
