# API contract

Base: FastAPI `backend/app/main.py`. Paths are unversioned (not `/v1`) to match existing tests.

| Method | Path | Auth | Notes |
| --- | --- | --- | --- |
| GET | `/health` | no | flags stay false; `database: {type, in_memory}` — never the URL |
| POST | `/auth/register` | no | `EmailStr` (trim + lowercase, ≤255), name ≤120, password 8–1024; hashed password |
| POST | `/auth/login` | no | access JWT + refresh (raw once) |
| POST | `/auth/refresh` | no | body `{refresh_token}`; rotates |
| POST | `/auth/logout` | no | optional `{refresh_token}` revoke; empty body still 200 |
| POST | `/auth/logout-all` | yes | revoke all sessions |
| GET | `/auth/me` | yes | same public fields as `/users/me` |
| GET | `/auth/sessions` | yes | |
| DELETE | `/auth/sessions/{id}` | yes | IDOR filtered |
| GET | `/users/me` | yes | `is_premium` always false |
| PATCH | `/users/me` | yes | name / locale en\|ar\|ur / timezone |
| DELETE | `/users/me` | yes | **hard delete** — user + bookmarks/sync/settings/progress/sessions/refresh tokens, one transaction, zero retention |
| GET/POST/DELETE | `/bookmarks` | yes | refs only |
| POST | `/sync` | yes | last-write-wins; max 500 items |
| POST | `/ai/ask` | **yes** | retrieval-only; `query` ≤500, ≤32 corpus items each field-capped, ≤20 history msgs, per-user budget → 429 |
| GET | `/billing/status` | no | store unconfigured |
| GET/POST | `/settings` | yes | |
| GET/POST | `/progress` | yes | upsert by kind |

Errors: `{ "detail": "<code>", ...optional fields }` — no stack traces, and a structured
detail is returned flat (never nested under a second `detail`).

| 429 | extra body fields | scope |
| --- | --- | --- |
| `rate_limited` | — | per IP, 60/60, global |
| `login_throttled` | `scope: "ip"|"account"`, `retry_after_seconds` | per IP (10 failures/60 s) **and** per account (5/60 s), failures only |
| `ai_quota_exceeded` | `limit`, `window_seconds`, `retry_after_seconds`, `scope` | per signed-in user, 20/60 s |

Every 429/413 carries `Retry-After` where a wait is known, the four security headers, and
`x-request-id` — the middleware order in `app/main.py` puts RequestId and SecurityHeaders
outside the limiter so a refusal cannot escape unbelted.
