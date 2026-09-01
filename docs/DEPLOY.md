# Deploy — Qibra Backend on Render (live)

Live since 2026-09-02. This is the single reproducible description of the production service.

## Service

| Key | Value |
|---|---|
| Host | Render — Web Service (free tier), autoscaling off |
| URL | `https://qibra-ai.onrender.com` |
| Repo / branch | `hseshahbazalam-glitch/Qibra_AI` → `arena/01a05b41-qibra-ai` (auto-deploy on push) |
| Root directory | `backend` |
| Runtime | Python **3.12.7** |
| Install command | `pip install -r requirements.txt` |
| Start command | `uvicorn app.main:app --host 0.0.0.0 --port $PORT` |
| Health check path | `/health` |

## Environment variables (set in the Render dashboard — never in git)

| Name | Required | Notes |
|---|---|---|
| `GROQ_API_KEY` | for grounded AI answers | Key lives ONLY here. Absent ⇒ `/ai/ask` degrades to the deterministic extractive RAG path, never an error. |
| `JWT_SECRET` | yes | `app/config.py` refuses well-known values when `QIBRA_ENV=production`. |
| `DATABASE_URL` | optional | Default in-memory SQLite (dev posture); set a managed Postgres URL for persistence, then `alembic upgrade head`. |
| `QIBRA_ENV` | optional | `production` turns on strict secret validation. |
| `GROQ_MODEL` | optional | Defaults to `llama-3.3-70b-versatile`. |
| `GROQ_TIMEOUT_SECONDS` | optional | Defaults to `30`. |

## Endpoints (all mounted at the root — no `/v1` prefix)

- `POST /ai/ask` — body `{query, corpus[≤32], history[≤20 msgs], stream}`.
  No corpus hit or no key ⇒ deterministic extractive answer/refusal (level 0 shape).
  `stream: true` ⇒ `text/event-stream` with `data: {"type":"delta"|"done"|"fallback", ...}` frames.
  Public by design, rate-limited by middleware, `Cache-Control: no-store`, never logged.
- `GET /health` — liveness + production flags.

## App-side wiring

Single source constant: `AppApi.baseUrlProduction = 'https://qibra-ai.onrender.com'`
(`lib/core/constants/app_constants.dart`). `AppApi.apiUrl == baseUrl` because the
backend serves routes at root. `AppApi.isBackendEnabled` gates the live path; it is
kept `false` in-repo until the owner flips it after device testing.

## Reproduce from scratch

1. Render → New Web Service → connect repo, branch `arena/01a05b41-qibra-ai`.
2. Root directory `backend`; Runtime Python 3; version **3.12.7**; commands as above.
3. Add env vars from the table (secret values only in the dashboard).
4. Verify: `GET /health` → 200; `POST /ai/ask` with `{"query":"x","corpus":[]}` → `{"refused":true,...}`.
5. Local parity tests: `cd backend && python -m pytest tests -q` (mocked Groq — no key needed).

## Rollback

Render → Versions → manual rollback to previous successful build. Datasets are bundled
assets; DB migrations are forward-only (`alembic/versions`) — reverting code does not
drop columns.
