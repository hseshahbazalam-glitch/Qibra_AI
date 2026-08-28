# Phase 7 report — Prayer/location/timezone

Status: implemented on this branch. UNKNOWN remains UNKNOWN. No fake recitation player. Production-ready flags remain FALSE.

## What landed
Known-city catalog. IANA timezone engine. Next-prayer midnight wrap. Local prayer source + schedule cache. Aladhan parser only.

## Honesty
- Quran/Hadith/tafsir/prayer/qibla/authenticity/user stats are never invented.
- Unbundled editions are honest misses.
- Health version is 0.6.0.

## Tests
See `backend/tests/test_phase7.py` and Flutter `test/phase7_*.dart`.
Flutter analyze/test: run only if SDK present.
