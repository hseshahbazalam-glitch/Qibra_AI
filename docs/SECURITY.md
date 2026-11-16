# Security

- No secrets in git. `.env.example` only.
- JWT + hashed passwords on the API. Homemade HMAC-SHA256; refresh tokens stored as SHA-256 hashes with `family_id` rotation.
- Rate limit is **in-process** 60 hits / 60 seconds (`RateLimitMiddleware`), plus a
  login-specific throttle (10 failed attempts per IP, 5 per account, per 60 s,
  `app/services/login_guard.py`) and a per-user budget on `/ai/ask` (20 per 60 s). None
  of it is **Redis** and none of it is shared: multi-instance production needs a shared
  store; do not claim Redis is live. The login budgets count FAILED attempts only, so the
  throttle cannot be used to lock a real user out of their own account.
- `/ai/ask` requires a valid access token and is bounded per field (query 500 chars, 32
  corpus items with a cap on every field, 20 history messages). It is no longer public:
  `docs/WORLD_CLASS_AUDIT.md` recorded "unauthenticated — KEEP" and QB-011 reversed it.
- Request bodies are capped by MEASURED BYTES on the stream (`BodySizeLimitMiddleware`),
  not by `Content-Length`, so a chunked or lying client cannot walk past 256 KiB.
- Password hashes carry their own iteration count
  (`pbkdf2-sha256$<iterations>$<salt>$<digest>`); a corrupt stored hash verifies as a
  failed login (401), never a 500.
- Boot refuses to start without a ≥32-byte `JWT_SECRET` and an explicit `DATABASE_URL`;
  SQLite needs `QIBRA_ENV=dev`. `/health` reports the database TYPE only, never the URL.
- Security headers + request id.
- Observability consent default OFF. No Firebase/Sentry/Mixpanel.
- Do not log email, GPS, tokens, receipts, Quran/Hadith text, or AI prompts.
- Precise location is not stored on the server (`precise_location_stored_on_server: false`).
- `USE_EXACT_ALARM` permission removed.
- `QIBRA_ENV=production` refuses SQLite. PostgreSQL pooling is configured in code; this checkout has no Postgres server.
