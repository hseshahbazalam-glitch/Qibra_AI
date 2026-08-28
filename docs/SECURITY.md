# Security

- No secrets in git. `.env.example` only.
- JWT + hashed passwords on the API.
- Rate limit + security headers + request id.
- Observability consent default OFF.
- Do not log email, GPS, tokens, receipts, Quran/Hadith text, or AI prompts.
- Precise location is not stored on the server (`precise_location_stored_on_server: false`).
- `USE_EXACT_ALARM` permission removed.
