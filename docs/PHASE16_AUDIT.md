# Phase 16 read-only audit

**Date:** 2026-08-23  
**Scope:** Flutter client and FastAPI 0.6.0 service restored on this branch from the available Phase 15 implementation. This audit was written before Phase 16 source changes.

## Contract inventory

- Quran and Hadith are local-content flows. Recitation is explicitly unavailable unless a licensed asset is present; no audio or tafsir will be added in Phase 16.
- Prayer and Qibla use the existing local services. No live prayer provider, location persistence, or fabricated times will be introduced.
- AI is retrieval-only and already refuses when no approved source is available. That behavior is a release blocker for any change touching `ai_service.py`.
- Billing remains server-authoritative. No client-side entitlement authority is introduced.
- Auth currently has expiry and revocation plumbing, but uses a development default signing secret and SHA-256 password derivation; production secret validation and a deliberately slow, salted password derivation are needed without invalidating active contracts.
- Sync keeps the existing store’s merge behavior. Phase 16 will not modify data shapes or merge ordering.

## Findings and bounded plan

| Area | Finding | Safe Phase 16 action |
|---|---|---|
| CORS | FastAPI accepts `*` in every environment. | Configure explicit origins, permitting a local development default only when `QIBRA_ENV=development`. |
| Security headers | No request ID or browser hardening middleware is mounted. | Add request IDs and `nosniff`, deny framing, and a strict referrer policy. Do not log request bodies, tokens, or content. |
| Secrets | Production can start with `dev-only-secret`. | Fail fast outside development for placeholder/short secrets; document required env vars. |
| Passwords | Plain fast SHA-256 is not adequate password storage. | Use versioned PBKDF2-HMAC-SHA256 for new credentials and retain legacy verification so existing in-memory fixtures/accounts do not break. |
| Rate limiting | No endpoint throttling middleware. | Add in-process, IP-keyed limits for auth, AI, and billing paths. This is intentionally local-process only and documented as such. |
| Health honesty | Health does not expose the required readiness flags. | Add only false/unproven flags and the required local-only/location facts. |
| Flutter theme | Several older screens retain static AppColors/white values; broad mechanical replacement risks visual and semantic regressions. | Improve shared Qibra UI primitives, status states, and theme tokens. Do not mass-rewrite 1–2k line tool/auth/calculator screens without device review. |
| Accessibility | Shared pressables do not enforce a 48dp semantic target. | Make reusable Qibra cards/buttons semantic and minimum-target compliant. |
| Offline | Content availability varies by bundled data, and status presentation is not consistently reusable. | Add an honest reusable offline/stale/missing status surface; do not claim freshness or cached content not verified by a repository. |
| Localization | The codebase does not have complete chrome packs beyond en/ar/ur. | Do not enable gen-l10n or mark any additional locale ready. |

## Explicitly not changed

No Quran/Hadith source data, tafsir/recitation licensing, prayer calculations, Qibla math, RAG source policy, billing authority, sync merge policy, or token transport/query-string behavior is in scope. If testing exposes a contract conflict, the relevant change is to be stopped and documented rather than weakened.
