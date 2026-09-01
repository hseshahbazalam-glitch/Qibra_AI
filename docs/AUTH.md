# Auth

See `AUTH_ARCHITECTURE.md`.

- Access + refresh tokens live in secure storage.
- Network failure on refresh must **not** log the user out. 401 uses single-flight refresh then one retry; only a rejected refresh logs out.
- Guest mode is first-class; do not invent a premium badge from JSON.
- `HttpAuthRepository` is compiled but unused while `AppApi.isBackendEnabled` is false.
- Refresh reuse revokes the token **family**, not only the presented row.
