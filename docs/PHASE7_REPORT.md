# Phase 7 report — Prayer / location / timezone

**Starting HEAD:** `bd3faf0` (requested `fa8ad10` absent; no reset)  
**Status:** WIRED on-device. Flutter analyze **NOT RUN**. PostgreSQL **NOT RUN**. **Not production-ready.**

Phase 6 content licenses unchanged. No Quran/Hadith row marked VERIFIED.

## What landed

- Location permission states including denied-forever and timeout
- `LocationFix` DEVICE / MANUAL / CACHED
- IANA DST helpers + calendar-date boundary
- Schedule cache key includes location/date/tz/settings/provider
- Next/current prayer midnight wrap (Sunrise not obligatory)
- Hijri labelled civil/tabular
- Aladhan parser rejects invalid JSON; not live
- **No new Qibra GPS API**

Prayer math / qibla formulas: **untouched**. Home UI: **untouched**.

## Tests

See `backend/tests/test_phase7.py`, `test_phase7_engine.py`, Flutter `test/phase7_*.dart`.
Flutter analyze/test: only if SDK present.
