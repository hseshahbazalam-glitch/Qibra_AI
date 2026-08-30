# Auth architecture

Anonymous-first client when `AppApi.isBackendEnabled` is false. Quran/Hadith/Prayer stay usable without login.

Server:
- PBKDF2 password hashes (210k)
- Short-lived HS256 access JWT (`sub` = user id)
- Opaque refresh token; **only SHA-256 hash stored**
- Rotation on `/auth/refresh`; reuse of a revoked refresh revokes the user's tokens
- Sessions: device_id / platform / app_version (optional, no GPS)
- Soft-delete users (`deleted_at`)
- Rate limit 60/60
- Production refuses empty/default `JWT_SECRET` when `QIBRA_ENV=production`

Client:
- `flutter_secure_storage` for tokens
- No fake JWTs
- `AppUser.isPremium` never trusted from JSON
- Network failure on refresh **must not** log the user out
