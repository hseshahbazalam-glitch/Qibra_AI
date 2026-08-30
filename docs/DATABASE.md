# Database

Islamic Quran/Hadith/Dua assets stay on-device. PostgreSQL (when deployed) stores **user data only**.

## Engines

| Environment | URL | Status |
| --- | --- | --- |
| Tests | `sqlite+pysqlite:///:memory:` + StaticPool | IMPLEMENTED |
| Local dev | `sqlite+pysqlite:///./qibra.db` (`.env.example`) | IMPLEMENTED |
| Production | `DATABASE_URL=postgresql+psycopg2://…` | REQUIRES PRODUCTION INFRASTRUCTURE |

SQLAlchemy is **sync**. Do not add a second async ORM.

## Migrations

```
cd backend
alembic upgrade head
alembic downgrade -1
```

`alembic/env.py` reads `DATABASE_URL` when set.

Revisions: `0001` user data → `0002` sync/audit → `0003` sessions + hashed refresh tokens + progress unique `(user_id, kind)` → `0004` refresh `family_id` / `rotated_at` + `sync_operations` idempotency.

## Tables (user data)

users, bookmarks, user_settings, progress, sync_records, audit_events, user_sessions, refresh_tokens (`token_hash`, `family_id`), sync_operations.

`QIBRA_ENV=production` refuses SQLite. PostgreSQL uses `pool_pre_ping` and `pool_size=5` when `DATABASE_URL` is `postgresql…`. **Postgres tests: NOT RUN.**

No GPS history. No raw refresh tokens. No Quran verse text required on the server.
