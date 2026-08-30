# Production Phase 4

**NOT APPROVED.** Flags stay false.

| Item | Status |
| --- | --- |
| Hashed passwords + access JWT | IMPLEMENTED |
| Hashed refresh tokens + rotation + reuse revoke | IMPLEMENTED (SQLite tests) |
| Sessions list/revoke | IMPLEMENTED (SQLite tests) |
| PATCH `/users/me` | IMPLEMENTED |
| Sync batch cap + progress upsert | IMPLEMENTED |
| Client sync queue statuses | IMPLEMENTED (local) |
| PostgreSQL live | BLOCKED — no server in this environment |
| Client live API (`isBackendEnabled`) | NOT IMPLEMENTED (kept false) |
| `/v1` prefix | NOT IMPLEMENTED (would break existing tests) |
| Flutter analyze/test | NOT RUN |
| Auth production ready flag | false |

Deploy needs: real `JWT_SECRET`, `QIBRA_ENV=production`, PostgreSQL `DATABASE_URL`, `alembic upgrade head`, HTTPS, no CORS `*`.
