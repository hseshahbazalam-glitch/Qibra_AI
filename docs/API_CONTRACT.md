# API contract

Base: FastAPI `backend/app/main.py`. Paths are unversioned (not `/v1`) to match existing tests.

| Method | Path | Auth | Notes |
| --- | --- | --- | --- |
| GET | `/health` | no | flags stay false |
| POST | `/auth/register` | no | hashed password |
| POST | `/auth/login` | no | access JWT + refresh (raw once) |
| POST | `/auth/refresh` | no | body `{refresh_token}`; rotates |
| POST | `/auth/logout` | no | optional `{refresh_token}` revoke; empty body still 200 |
| POST | `/auth/logout-all` | yes | revoke all sessions |
| GET | `/auth/me` | yes | same public fields as `/users/me` |
| GET | `/auth/sessions` | yes | |
| DELETE | `/auth/sessions/{id}` | yes | IDOR filtered |
| GET | `/users/me` | yes | `is_premium` always false |
| PATCH | `/users/me` | yes | name / locale en\|ar\|ur / timezone |
| DELETE | `/users/me` | yes | soft delete |
| GET/POST/DELETE | `/bookmarks` | yes | refs only |
| POST | `/sync` | yes | last-write-wins; max 500 items |
| POST | `/ai/ask` | no | retrieval-only |
| GET | `/billing/status` | no | store unconfigured |
| GET/POST | `/settings` | yes | |
| GET/POST | `/progress` | yes | upsert by kind |

Errors: `{ "detail": "<code>" }` — no stack traces. 429 `rate_limited` (60/60).
