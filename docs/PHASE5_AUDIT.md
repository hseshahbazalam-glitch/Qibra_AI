# Phase 5 audit — integration & reliability

**Date:** 2026-08-30  
**Branch:** `arena/01a049e4-qibra-ai`  
**HEAD:** `de12971`  
**Requested Phase 4 `3f2a7bc`:** not in this checkout. Continue from `de12971`. No reset.

**Verdict: NOT APPROVED.** Flutter SDK absent. PostgreSQL absent. Implementation landed after this audit; see `PHASE5_REPORT.md`. The audit file itself is still **NOT APPROVED**.

---

## Architecture (KEEP)

Flutter Riverpod + FastAPI + SQLAlchemy sync. Quran/Hadith stay local. 6 tabs including Hadith. Ivory/forest/gold. `isBackendEnabled=false`. Rate limit 60/60. No CORS `*`. RAG refuse-on-empty.

## Known gaps after Phase 4 (`de12971`)

| Gap | Evidence |
| --- | --- |
| No `HttpAuthRepository` | `StubAuthRepository` only |
| 401 → refresh not wired | `ApiClient` has no 401 interceptor; `AuthNotifier.refreshToken()` returns false |
| `onTokensRotated` / `onSessionExpired` | missing |
| Anonymous → account migration | missing |
| Queue not persisted / no auto-flush | in-memory `SyncQueue` |
| Refresh `family_id` | missing on `RefreshToken` |
| Sync idempotency / partial batch | `/sync` all-or-nothing merge |
| DELETE `/users/me` does not revoke sessions | `users.py` only sets `deleted_at` |
| Homemade JWT | tested HMAC; `python-jose` unused |
| In-memory rate limit | single-process only |
| PostgreSQL | no server; SQLite tests |

## Files that will change

Auth/sync/client reliability only: `api_client.dart`, `auth_provider.dart`, new `http_auth_repository.dart`, `account_migration.dart`, `sync_engine.dart`, backend auth/sync/users/models, alembic `0004`, tests, docs.

## Files that must remain unchanged

Prayer math, qibla formula, RAG, billing, zakat/inheritance formulas, Home/Quran/Hadith/Prayer/Qibla UI, `isBackendEnabled`, 60/60 limiter numbers, no CORS `*`, existing pytest files except additive tests.

## JWT decision

**KEEP** current HMAC-SHA256 implementation (`backend/app/security.py`). It is covered by tests, has no third-party JWT surface, and `python-jose` is unused. Replacing it in this pass is a compatibility risk without a production JWT audit environment.

## PostgreSQL

Support pooling when `DATABASE_URL` is `postgresql…`. Refuse SQLite when `QIBRA_ENV=production`. **Do not claim Postgres tests passed.**
