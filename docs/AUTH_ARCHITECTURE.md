# Auth architecture

Anonymous-first client when backend is disabled.

Server:
- JWT HMAC HS256 (`backend/app/security.py`)
- PBKDF2 password hashes
- Rate limit middleware
- Soft-delete users (`deleted_at`)

Client does not mint fake JWTs. `AppUser.isPremium` is never trusted from JSON.
