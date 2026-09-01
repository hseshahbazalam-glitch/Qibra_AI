# Security

- No secrets in git. `.env.example` only.
- JWT + hashed passwords on the API. Homemade HMAC-SHA256; refresh tokens stored as SHA-256 hashes with `family_id` rotation.
- Rate limit is **in-process** 60 hits / 60 seconds (`RateLimitMiddleware`). It is **not** Redis. Multi-instance production needs a shared store; do not claim Redis is live.
- Security headers + request id.
- Observability consent default OFF. No Firebase/Sentry/Mixpanel.
- Do not log email, GPS, tokens, receipts, Quran/Hadith text, or AI prompts.
- Precise location is not stored on the server (`precise_location_stored_on_server: false`).
- `USE_EXACT_ALARM` permission removed.
- `QIBRA_ENV=production` refuses SQLite. PostgreSQL pooling is configured in code; this checkout has no Postgres server.
