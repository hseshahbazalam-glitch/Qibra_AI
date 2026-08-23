# Phase 16 report — security, reliability, and UX completion

**Date:** 2026-08-23  
**Branch:** `arena/01a030b8-qibra-ai`

## What changed

### Safe backend hardening

- Replaced the unsafe wildcard CORS policy with configured origins. Development has two explicit localhost defaults; staging/production must set `QIBRA_CORS_ORIGINS`. Wildcards are not used.
- Added a production startup guard: placeholder/short JWT signing secrets and placeholder webhook secrets are rejected outside development.
- New registrations use versioned, salted PBKDF2-HMAC-SHA256 password hashes (310,000 iterations). Legacy Phase 15 SHA-256 records remain verifiable only to avoid unexpectedly locking an existing account out; successful legacy-login rehash migration is not implemented because the current store has no safe persistence/update path.
- Kept signed JWT expiry, Bearer-header-only token transport, and logout revocation behavior intact. No token, password, prompt, email, Quran, or Hadith content logging was added.
- Added request IDs and `X-Content-Type-Options: nosniff`, `X-Frame-Options: DENY`, and `Referrer-Policy: no-referrer` to responses.
- Added an intentionally modest in-process rate limiter for auth, AI, and billing route families. It uses only client-address keys and expiry timestamps; it is not a distributed production rate-limit service.
- Health now honestly reports all unproven readiness flags as `false`, `notifications_local_only: true`, and `precise_location_stored_on_server: false`.
- Added a Phase 16 content guard test that confirms an unretrieved reference remains answerless. RAG policy was not loosened.

### Flutter shared UX/a11y tokens

- Aligned `QibraColors.dark` to the requested midnight surfaces (`#0B1210`, `#15201C`) rather than navy.
- Updated shared `QibraCard`, section actions, and `QibraIconButton` to use semantic/minimum 48dp interactive targets. This improves every screen that uses these shared widgets without risky mechanical edits to the large legacy tool/auth screens.
- No gold body text, new analytics SDK, audio, tafsir, generated scripture, prayer provider, or fake player was added.

## Contract preservation

No Quran or Hadith datasets were changed. No tafsir/recitation licenses were added or asserted. Prayer calculation and Qibla services were untouched. AI stays retrieval-only/no-source-no-answer. Billing remains server-authoritative; an unpaid checkout remains unpaid until its existing server webhook path accepts it. Sync conflict behavior was not changed.

## Validation performed

Backend tests were run **individually**, using `backend/.venv/bin/python -m pytest <file> -q`:

| Test file | Passed |
|---|---:|
| `test_phase3.py` | 3 |
| `test_phase4.py` | 3 |
| `test_phase5.py` | 3 |
| `test_phase6.py` | 3 |
| `test_phase6_content.py` | 1 |
| `test_phase7.py` | 2 |
| `test_phase8.py` | 1 |
| `test_phase9.py` | 2 |
| `test_phase10.py` | 1 |
| `test_phase11.py` | 2 |
| `test_phase12.py` | 2 |
| `test_phase13.py` | 1 |
| `test_phase14.py` | 2 |
| `test_phase15.py` | 3 |
| `test_phase16.py` | 3 |
| **Total** | **32** |

`python -m compileall -q backend/app` also passed. A tracked-file secret-pattern scan for common private-key/AWS/Google key forms returned no matches. Dependency versions are pinned in `backend/requirements.txt`; a networked vulnerability audit was not run because no approved audit tool/credentials are configured.

### Not run

- `flutter analyze`: **NOT RUN** — Flutter SDK was not installed in this environment.
- `flutter test` (including `test/phase16_shared_ui_test.dart`): **NOT RUN** — Flutter SDK was not installed.
- Device/emulator validation, TalkBack/VoiceOver, dark-mode visual review, notification scheduling/reboot behavior, Postgres/SQLAlchemy/Alembic integration, real CORS deployment, payment provider/webhook delivery, Play Store, and App Store validation: **NOT RUN**.

## Remaining blockers to a real 9/10

1. The restored backend is an in-memory store, not the requested SQLAlchemy/Alembic/Postgres persistence layer; rate limiting is process-local. Those need an architecture-reviewed persistence/deployment phase.
2. Legacy Family B auth/tools/calendar/tasbih screens still contain static `AppColors`/white treatments. Shared controls are improved, but completing them safely requires Flutter visual/a11y device review rather than broad text replacement.
3. The Flutter SDK was unavailable, so no analyzer, widget test, screen-reader, text-scaling, offline-resume, or actual-device notification test has been proven.
4. No real production host has been configured, so certificate pinning is **not pinned — host unknown**. CORS production origins also need deployment values.
5. Content licensing remains deliberately unresolved: no recitation or tafsir is bundled or claimed available.

This is an honest hardening increment, not a claim of production readiness or a 9/10 release.
