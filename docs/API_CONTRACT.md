# API contract

Base: FastAPI `backend/app/main.py` version **0.6.0**.

| Method | Path | Auth | Notes |
| --- | --- | --- | --- |
| GET | `/health` | no | version + flags |
| POST | `/auth/register` | no | hashed password |
| POST | `/auth/login` | no | JWT |
| POST | `/auth/logout` | no | client discards token |
| GET | `/users/me` | yes | `is_premium` always false from this API |
| DELETE | `/users/me` | yes | soft delete |
| GET/POST/DELETE | `/bookmarks` | yes | |
| POST | `/sync` | yes | last-write-wins |
| POST | `/ai/ask` | no | retrieval-only; refuse if no passage |
| GET | `/billing/status` | no | store unconfigured |
| GET/POST | `/settings` | yes | |
| GET/POST | `/progress` | yes | |

Flags on `/health`:
- auth_production_ready: false
- content_production_ready: false
- billing_production_ready: false
- analytics_production_ready: false
- notifications_local_only: true
- precise_location_stored_on_server: false
