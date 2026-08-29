# Auth

See `AUTH_ARCHITECTURE.md`.

- Access + refresh tokens live in secure storage.
- Network failure on refresh must **not** log the user out.
- Guest mode is first-class; do not invent a premium badge from JSON.
