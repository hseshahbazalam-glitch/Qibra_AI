# Phase 8 report — Notification & background reliability

**Starting HEAD:** `0b1bb52` (requested `89201e4` absent; no reset)  
**Status:** **WIRED** in source. Implemented in source, verified by available Python tests, but device/platform verification remains. Flutter analyze/test **NOT RUN**. **Not production-ready.** Never COMPLETE.

Phase 6 licenses unchanged. No Quran/Hadith row marked VERIFIED. GPS not sent to the Qibra API. Prayer math / qibla / Home UI: **untouched**.

## What landed

- Deterministic FNV-1a notification IDs (`prayer|date|IANA|city|settings|hhmm|kind`)
- Idempotent reconcile (cancel / keep / create); persisted IDs without lat/lng
- Permission mapping; denied → no schedule
- Unused `SCHEDULE_EXACT_ALARM` removed; inexact scheduling kept
- `azanSchedulerProvider` passes IANA timezone + city key (not GPS)
- Python mirror of the engine for tests
- Honest docs: architecture, reliability, platform limits

Adhan audio present on disk; license **UNKNOWN**. Boot receiver present; **not reboot-proof**.

## Tests

- `backend/tests/test_phase8.py` — health flags, no GPS in health
- `backend/tests/test_phase8_notifications.py` — IDs, idempotency, DST, midnight, location, settings, permission
- Flutter `test/phase8_test.dart`, `test/phase8_reconcile_test.dart` — **NOT RUN** (no Flutter SDK)
- Backend pytest this checkout: **178 passed** (includes Phase 8). Flutter analyze/test: **NOT RUN**. PostgreSQL: **NOT RUN**.

## Remaining blockers

No device reboot test. Inexact alarms. OEM battery killers. iOS deferral. Adhan license UNKNOWN. `isBackendEnabled` remains false.
