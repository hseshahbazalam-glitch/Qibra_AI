# Phase 12 report — Performance optimization

**Starting HEAD:** `0f36a25`  
**Status:** **WIRED** (code-level). Flutter profile **NOT RUN**. Device **NOT RUN**. **Not production-ready.** Never COMPLETE.

Phase 4–11 contracts preserved. No UI redesign. No new packages. No invented FPS/ms numbers.

## Audit summary

Startup blocked on full Hadith decode; duplicate timezone init; sync merge did per-item SELECTs; metrics keys unbounded. Large-list UI already uses builders. RAG/search algorithms left alone.

## Optimizations implemented

| Change | Before | After | Measurement | Confidence |
| --- | --- | --- | --- | --- |
| Hadith load after `runApp` | Awaited before first frame | `unawaited` background; screens still `initialize()` | Code-level only | Medium that TTF improves; **not device-timed** |
| Skip 2nd TZ init | `latest_all` + `latest` | Flag after main init | Code-level | High that duplicate call is skipped |
| Sync merge prefetch | 2+ SELECTs per item | 2 SELECTs per batch + in-memory map | 20-item `/sync` accepted; Phase 4/5 LWW still pass | High for correctness; **no Postgres EXPLAIN** |
| Metrics key cap | unbounded defaultdict | max 64 keys | pytest: 80 incs → ≤64 | High |
| Skip metrics on `/health/metrics` | counted itself | skipped | code-level | Low impact |

## Files changed

`lib/main.dart`, `lib/core/services/notification_service.dart`, `backend/app/services/sync_service.py`, `backend/app/observability/metrics.py`, `backend/app/middleware/metrics.py`, tests, `docs/PHASE12_AUDIT.md`, this report.

## Tests

Phase 3–12 Python files passed in isolation (Phase 12: 8 + 3). Full `backend/tests`: **201 passed**.

Flutter analyze/test/build: **NOT RUN**. Android/iOS: **NOT RUN**. PostgreSQL/Redis: **NOT RUN**.

## Remaining bottlenecks

Quran still loaded before first frame. Hadith linear search. `google_fonts` runtime. Home small `ListView(`s. No frame/memory profile.
