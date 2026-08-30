# Phase 5 report — Connected reliability

**Date:** 2026-08-30  
**Branch:** `arena/01a049e4-qibra-ai`  
**Status labels:** FOUNDATION | WIRED | FUNCTIONAL | PRODUCTION READY | BLOCKED  
**Overall:** WIRED for FastAPI reliability tests. Flutter client wiring is FOUNDATION (SDK **NOT RUN**). **Not COMPLETE. Not production-ready.**

Unknown remains UNKNOWN. `isBackendEnabled` stays **false**. Homemade HMAC JWT kept. Rate limit 60/60. No CORS `*`. No `/v1` added to FastAPI.

---

## 1. Verdict

WIRED on the API (pytest). Flutter analyze **NOT RUN**. PostgreSQL **NOT RUN**. Production **NOT APPROVED**.

## 2. Scope kept

No Home restyle. No prayer/qibla/RAG/billing/formula rewrites. Quran/Hadith stay local. 6 tabs including Hadith. Duplicate `/tasbih`+`/tools/dhikr` and `/bookmarks`+`/quran/bookmarks` kept.

## 3. Auth client (`HttpAuthRepository`)

| Field | Value |
| --- | --- |
| FILE | `lib/core/network/http_auth_repository.dart` |
| CLASS | `HttpAuthRepository` |
| FUNCTION | `login` / `register` / `logout` / `getCurrentUser` / `refreshWith` / `deleteAccount` |
| CURRENT | Wired to `/auth/login`, `/auth/register`, `/auth/logout`, `/auth/refresh`, `/auth/me`, `DELETE /users/me` |
| PROBLEM | Selected only when `AppApi.isBackendEnabled` is true (still false) |
| SEVERITY | info |
| FIX | Keep flag false until e2e |
| TEST STATUS | Dart tests NOT RUN (no SDK). Backend login/register/refresh covered by pytest |

## 4. 401 → single-flight refresh → retry once

| Field | Value |
| --- | --- |
| FILE | `lib/core/network/api_client.dart` |
| CLASS | `ApiClient` |
| FUNCTION | interceptor `onError`, `_singleFlightRefresh` |
| CURRENT | 401 (except login/refresh) waits on one in-flight refresh, copies `Authorization`, retries once |
| PROBLEM | Not exercised without Flutter integration |
| SEVERITY | medium until e2e |
| FIX | Wired; flag off |
| TEST STATUS | NOT RUN |

## 5. Network failure must not logout

| Field | Value |
| --- | --- |
| FILE | `lib/core/providers/auth_provider.dart` |
| CLASS | `AuthNotifier` |
| FUNCTION | `_rotateAccess`, `_checkAuthStatus` |
| CURRENT | `RefreshOutcome.networkFailure` does not call logout. Offline restore keeps tokens |
| PROBLEM | Offline restore user has empty email/name |
| SEVERITY | low |
| FIX | Do not invent email |
| TEST STATUS | NOT RUN (Flutter) |

## 6. Session restore

| Field | Value |
| --- | --- |
| FILE | `lib/core/providers/auth_provider.dart` |
| CLASS | `AuthNotifier` |
| FUNCTION | `_checkAuthStatus` |
| CURRENT | Backend-off → guest. Backend-on → bearer + `/auth/me`. Fake `fake_*` tokens purged |
| PROBLEM | Flag false so restore path idle |
| SEVERITY | info |
| FIX | none this phase |
| TEST STATUS | NOT RUN |

## 7. Anonymous → account migration

| Field | Value |
| --- | --- |
| FILE | `lib/core/sync/account_migration.dart` |
| CLASS | `AccountMigration` |
| FUNCTION | `attachLocal` |
| CURRENT | Enqueues local ops; does not wipe existing queue |
| PROBLEM | Login/register call it with empty `localOps` until feature screens pass snapshots |
| SEVERITY | medium |
| FIX | Callers can pass bookmarks/progress later; do not wipe first |
| TEST STATUS | Dart unit written; NOT RUN |

## 8. Sync queue persist

| Field | Value |
| --- | --- |
| FILE | `lib/core/sync/sync_engine.dart` |
| CLASS | `SyncEngine` |
| FUNCTION | `persist` / `load` |
| CURRENT | SharedPreferences JSON under `qibra_sync_queue_v1` |
| PROBLEM | Not hooked from `main.dart` |
| SEVERITY | medium |
| FIX | Call `load` at startup when a later phase enables backend |
| TEST STATUS | Dart unit written; NOT RUN |

## 9. Auto-flush when online

| Field | Value |
| --- | --- |
| FILE | `lib/core/sync/sync_engine.dart` |
| CLASS | `SyncEngine` |
| FUNCTION | `flushWhenOnline` |
| CURRENT | No-op while `isBackendEnabled` is false |
| PROBLEM | No Connectivity subscription in `main` |
| SEVERITY | medium |
| FIX | Intentional while backend off |
| TEST STATUS | Dart unit written; NOT RUN |

## 10. Refresh `family_id` reuse

| Field | Value |
| --- | --- |
| FILE | `backend/app/services/auth_service.py` |
| CLASS | — |
| FUNCTION | `rotate_refresh`, `_revoke_family` |
| CURRENT | Reuse of a rotated token revokes the whole family, so the successor also 401s |
| PROBLEM | none in SQLite tests |
| SEVERITY | — |
| FIX | shipped |
| TEST STATUS | `test_refresh_reuse_invalidates_family` |

## 11. Expired refresh fails

| Field | Value |
| --- | --- |
| FILE | `backend/app/services/auth_service.py` |
| CLASS | — |
| FUNCTION | `rotate_refresh` |
| CURRENT | `expires_at < now` → 401 `invalid_refresh` |
| PROBLEM | none |
| SEVERITY | — |
| FIX | shipped |
| TEST STATUS | `test_expired_refresh_fails` |

## 12. Sync `operation_id` idempotency

| Field | Value |
| --- | --- |
| FILE | `backend/app/services/sync_service.py` |
| CLASS | — |
| FUNCTION | `merge_records` |
| CURRENT | `SyncOperation` unique `(user_id, operation_id)`; replay returns `reason=idempotent` |
| PROBLEM | none in tests |
| SEVERITY | — |
| FIX | shipped |
| TEST STATUS | `test_sync_idempotent_operation_id` |

## 13. Partial batch results

| Field | Value |
| --- | --- |
| FILE | `backend/app/routers/sync.py` |
| CLASS | — |
| FUNCTION | `sync` |
| CURRENT | Response `{items, results}`. Empty `/sync` still `items == []`. Bad item `rejected`; others `accepted` |
| PROBLEM | none |
| SEVERITY | — |
| FIX | shipped |
| TEST STATUS | `test_sync_partial_bad_item_does_not_abort`; existing `test_phase9` empty items kept |

## 14. DELETE `/users/me` revokes sessions

| Field | Value |
| --- | --- |
| FILE | `backend/app/routers/users.py` |
| CLASS | — |
| FUNCTION | `delete_me` |
| CURRENT | `logout_all` then `deleted_at` |
| PROBLEM | Access JWT may still parse until expiry; `get_user` returns None → 401 |
| SEVERITY | low |
| FIX | acceptable |
| TEST STATUS | `test_delete_me_revokes_refresh` |

## 15. Production SQLite refuse

| Field | Value |
| --- | --- |
| FILE | `backend/app/db/session.py` |
| CLASS | — |
| FUNCTION | `_make_engine` |
| CURRENT | `QIBRA_ENV=production` + sqlite → `RuntimeError`. Postgres: `pool_pre_ping`, `pool_size=5` |
| PROBLEM | PostgreSQL server absent here |
| SEVERITY | blocker for production |
| FIX | deploy Postgres; do not claim it passed |
| TEST STATUS | `test_production_sqlite_refused`. Postgres **NOT RUN** |

## 16. Redis rate limit — documented, not pretended

| Field | Value |
| --- | --- |
| FILE | `backend/app/middleware/rate_limit.py` |
| CLASS | `RateLimitMiddleware` |
| FUNCTION | `dispatch` |
| CURRENT | In-process dict, 60 hits / 60s |
| PROBLEM | Multi-instance deploy would not share buckets. Redis is **not** live |
| SEVERITY | high for multi-node production |
| FIX | Keep in-memory; document Redis as future |
| TEST STATUS | existing `test_phase5.py` 60/60 |

## 17. JWT

KEEP homemade HS256 in `backend/app/security.py`. `python-jose` unused. Access TTL 15 minutes.

## 18. Bookmarks pagination

`GET /bookmarks?limit&offset` capped 1–500. Empty list contract `== []` kept.

## 19. Tests run this phase

- Pytest: run from `backend/` with `/tmp/qibra-venv` (see below). Existing files not rewritten; added `test_phase5_reliability.py`.
- Flutter analyze / `flutter test`: **NOT RUN** (SDK absent).
- Postgres: **NOT RUN**.

## 20. Remaining blockers (not COMPLETE)

1. Flutter SDK missing → compile unknown.  
2. `AppApi.isBackendEnabled = false` and `AppApi.apiUrl` still includes `/v1` while FastAPI has no `/v1`. Do not enable until that is reconciled.  
3. No PostgreSQL.  
4. In-memory rate limit ≠ Redis.  
5. Health `*_production_ready` remain false.  
6. Sync persist not called from app startup.  
7. Login attachLocal still empty snapshots.

---

## Honesty

- Quran/Hadith/tafsir/prayer/qibla/authenticity/user stats are never invented.
- Unbundled editions are honest misses.
- Health version is 0.6.0.
