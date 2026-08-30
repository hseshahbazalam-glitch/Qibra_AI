# Phase 4 audit — data, auth, sync

**Date:** 2026-08-30  
**Branch:** `arena/01a049e4-qibra-ai`  
**HEAD at audit:** `97bca39`  
**Requested baseline `3603f57` / `cdd771a` / `9ca38d0`:** not in this checkout. Work continues from current HEAD. No reset.

**Verdict: NOT APPROVED.** Flutter SDK absent. PostgreSQL not running here.

---

## Current architecture

| Layer | Evidence | State |
| --- | --- | --- |
| Flutter | Riverpod + GoRouter, 6 tabs including Hadith | KEEP |
| Local Islamic content | `assets/data/quran`, `assets/data/hadith` | KEEP — not moving to Postgres |
| FastAPI | `backend/app/main.py` unversioned routes (`/auth`, not `/v1`) | KEEP paths (130 tests) |
| SQLAlchemy sync | `backend/app/db/session.py` | KEEP — do not add a second async ORM |
| SQLite tests | `DATABASE_URL=sqlite+pysqlite:///:memory:` + StaticPool | KEEP |
| Alembic | `0001` users/bookmarks/settings/progress; `0002` sync_records/audit | PRESENT |
| Passwords | PBKDF2-HMAC-SHA256 210k | KEEP |
| Access JWT | HS256, `JWT_SECRET` env, production refuses empty/default | KEEP |
| Rate limit | 60/60, test store reset | KEEP — do not weaken |
| CORS `*` | absent | KEEP absent |
| Client backend | `AppApi.isBackendEnabled = false` | KEEP false |
| Tokens on device | `flutter_secure_storage` | KEEP |
| RAG | refuse on empty retrieve; `verified: False` | KEEP |

## Auth state (before this pass)

- `POST /auth/register`, `POST /auth/login` (access JWT only), `POST /auth/logout` no-op 200.
- `GET /users/me` — `is_premium` always false.
- No refresh token, no hashed refresh storage, no sessions/devices, no `/auth/refresh`.
- Logout does not revoke anything.
- Client `refreshToken()` returns false and **must not logout on network failure**.

## Persistence / sync (before this pass)

- Server: bookmarks, settings, progress, last-write-wins `sync_records`.
- Client: in-memory `SyncQueue` (not persisted, no status enum).
- Progress POST inserts a new row each time (no upsert).
- No batch cap on `/sync`.

## Security state

- Unhandled errors → `{detail: server_error}`, no stack traces.
- Request IDs + security headers.
- No committed `.env`.
- Health `*_production_ready` flags **false**.
- No GPS stored on server (`precise_location_stored_on_server: false`).

## Gaps this pass will close (feasible)

1. Hashed refresh tokens + rotation + reuse revoke.  
2. Sessions list/revoke.  
3. `/auth/refresh`, authenticated logout-all, `/auth/me` alias.  
4. PATCH `/users/me` (name/locale/timezone only).  
5. Progress upsert by `(user_id, kind)`.  
6. Sync batch cap 500.  
7. Client sync queue statuses + set-merge helper (local).  
8. Docs: DATABASE, SYNC_PROTOCOL, PRIVACY_DATA_MAP, PRODUCTION_PHASE4.

## Explicitly not doing

- UI redesign / midnight palette / gen-l10n / dropping Hadith.  
- Replacing Quran/Hadith assets with Postgres.  
- UUID PK rewrite (would break existing integer `user.id` tests).  
- `/v1` prefix (would break current pytest paths).  
- Async SQLAlchemy / second HTTP client.  
- Weakening 60/60 or adding CORS `*`.  
- Flipping production-ready flags.  
- Claiming Postgres integration tests passed (no Postgres here).  
- Enabling `isBackendEnabled`.
