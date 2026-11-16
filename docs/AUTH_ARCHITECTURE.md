# Auth architecture

Anonymous-first client when `AppApi.isBackendEnabled` is false. Quran/Hadith/Prayer stay usable without login.

Server:
- PBKDF2 password hashes, 210k iterations **stored inside the hash string**
  (`pbkdf2-sha256$<iterations>$<salt>$<digest>`) so a future raise is a data migration;
  legacy `salt$digest` rows still verify; a corrupt row reads as a wrong password (401)
- Short-lived HS256 access JWT: `sub` (user id), `exp`, `iat`, `jti`
- Opaque refresh token; **only SHA-256 hash stored** — never a plaintext token at rest
- Rotation on `/auth/refresh`, under `SELECT … FOR UPDATE`. Reuse of a rotated token
  inside `REFRESH_REUSE_GRACE_SECONDS` (default 30 s) returns the **same** successor
  instead of revoking the family, so a lost response cannot sign a user out; past the
  window, and for any token revoked without a rotation (a logout), reuse still revokes
  the whole family
- Sessions: device_id / platform / app_version (optional, no GPS)
- `DELETE /users/me` hard-deletes the user and every dependent row in one transaction;
  a soft-deleted row left by the old behaviour is purged on re-registration
- Rate limit 60/60 global, plus a login throttle on failed attempts only — 10/IP/60 s
  and 5/account/60 s (`app/services/login_guard.py`), 429 with `scope` + `Retry-After`.
  All budgets are per process; there is no shared store (no Redis) and they reset on boot
- Boot refuses to start on a missing/short `JWT_SECRET` (< 32 bytes) or a missing
  `DATABASE_URL`, in **every** `QIBRA_ENV`; SQLite needs `QIBRA_ENV=dev` explicitly

Client:
- `flutter_secure_storage` for tokens
- No fake JWTs
- `AppUser.isPremium` never trusted from JSON
- Network failure on refresh **must not** log the user out
