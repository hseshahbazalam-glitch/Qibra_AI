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

Both lines must be run **from `backend/`**: `alembic.ini` resolves `script_location`
against the working directory, and since QB-018 it also carries
`prepend_sys_path = .`, because `alembic/env.py` imports `app.db.*`. Before that
line existed the bare `alembic` script died with `ModuleNotFoundError: No module
named 'app'` and only `python -m alembic` worked (runpy prepends the cwd) — a trap
worth naming, because `alembic heads` never executes `env.py`, so it printed
`0004 (head)` the whole time and looked healthy.
`test_qb018_schema_and_alembic.py` runs the console script against a fresh file
database and asserts the result: exit 0, `alembic_version = 0005` (this pin read
`0004` until the owner-ordered drift closure below, which moved it), and all nine
user tables present.

**The app no longer builds the schema at boot** (QB-018). `reset_engine()` called
`Base.metadata.create_all()` unconditionally from a `@app.on_event("startup")`
handler; the hook is now a lifespan handler and `create_all` sits behind
`if dev_mode():`. So:

| Boot | Schema |
| --- | --- |
| `QIBRA_ENV=dev` (tests, local) | `create_all` convenience, as before |
| anything else (staging, production) | **only** what `alembic upgrade head` put there |

`alembic check` — **clean**, and that sentence has a history. QB-018 found it NOT
clean and wrote the finding down instead of burying it: two drifts from the models, a
missing `ix_progress_user_id` on `progress.user_id`, and `users.updated_at` nullable
in the migrations while the model says `nullable=False`. The gap was invisible while
every boot ran `create_all`, because dev databases came from the models and production
ones from the revisions. G2-D could not close it — that pass pins head = `0004` — so
the owner ordered a micro-pass before the release candidate, and `0005` is that
migration. Measured on the tree that added it:

```
$ alembic upgrade head && alembic check   ->  No new upgrade operations detected.  (exit 0)
$ alembic heads                            ->  0005 (head)
$ alembic downgrade 0004; alembic upgrade head
                                           ->  both exit 0; the index comes back
```

Before `0005` the same `alembic check` exited 255 with
`New upgrade operations detected: [('add_index', Index('ix_progress_user_id', …)),
[('modify_nullable', …, 'users', 'updated_at', …, True, False)]]`. The paste-ready job
in `docs/ci-backend-job.yaml` now runs `alembic check` as a step, because it can.

Revisions: `0001` user data → `0002` sync/audit → `0003` sessions + hashed refresh tokens + progress unique `(user_id, kind)` → `0004` refresh `family_id` / `rotated_at` + `sync_operations` idempotency → `0005` `ix_progress_user_id` + `users.updated_at` NOT NULL, backfilled from `created_at` (drift closure, reversible).

## Tables (user data)

users, bookmarks, user_settings, progress, sync_records, audit_events, user_sessions, refresh_tokens (`token_hash`, `family_id`), sync_operations.

`QIBRA_ENV=production` refuses SQLite. PostgreSQL uses `pool_pre_ping` and `pool_size=5` when `DATABASE_URL` is `postgresql…`. **Postgres tests: NOT RUN.**

No GPS history. No raw refresh tokens. No Quran verse text required on the server.
