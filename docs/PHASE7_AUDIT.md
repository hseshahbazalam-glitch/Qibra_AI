# Phase 7 audit — Prayer / location / timezone

**Date:** 2026-08-30  
**Branch:** `arena/01a049e4-qibra-ai`  
**Actual HEAD at audit start:** `bd3faf0`  
**Requested `fa8ad10`:** not in this checkout. No reset.

**Verdict: NOT APPROVED / FOUNDATION.** Local astronomical calculation and next-prayer wrap exist. Permission/cache/DST/privacy docs are incomplete. Flutter SDK **NOT RUN**. PostgreSQL **NOT RUN**. Do not call this production-ready.

This file was written **before** Phase 7 wiring edits. Prayer math and qibla formulas are **KEEP**. Home/Prayer screens are **not** restyled. Phase 6 license statuses stay UNKNOWN / REQUIRES_PERMISSION / DO_NOT_DISTRIBUTE.

---

## Existing (reuse, do not duplicate)

| Piece | Path | Label |
| --- | --- | --- |
| Astronomical times | `lib/features/prayer/data/services/prayer_calculation_service.dart` | PRESENT & WIRED — **do not rewrite formulas** |
| Models/settings | `lib/features/prayer/data/models/prayer_models.dart` | PRESENT & WIRED — MWL + Standard Asr defaults |
| Geolocator + cache | `lib/features/prayer/providers/prayer_provider.dart` `LocationNotifier` | PRESENT & WIRED — missing deniedForever/timeout distinct states |
| City names | `lib/core/location/location_resolver.dart` + `known_city_catalog.dart` | PRESENT & WIRED — GPS does not invent cities |
| IANA offset | `lib/core/timezone/timezone_engine.dart` | PRESENT & WIRED — DST untested here |
| Next prayer | `lib/features/prayer/data/services/next_prayer_engine.dart` + provider | PRESENT & WIRED — midnight wrap exists |
| Aladhan parser | `lib/features/prayer/data/services/prayer_source.dart` | PRESENT BUT PLACEHOLDER — parse only, no live network |
| Schedule cache | `lib/features/prayer/data/services/prayer_schedule_cache.dart` | PRESENT — key is date-only, not settings/provider |
| Hijri UI | `hijri` package on Home/Prayer/Calendar | PRESENT & WIRED — tabular civil conversion, **not** moon-sighting |
| Backend next | `backend/app/prayer/times.py` | PRESENT & WIRED |
| Health flag | `precise_location_stored_on_server: false` | PRESENT & WIRED |
| Qibra GPS API | — | MISSING (KEEP missing — do not add) |

## Gaps vs Phase 7

1. Location source enum DEVICE / MANUAL / CACHED not first-class.  
2. Permission: denied forever collapsed into denied; timeout/unavailable not separate.  
3. Cache does not include timezone/settings/provider.  
4. No DST tests.  
5. Hijri not labelled as approximate civil conversion.  
6. Aladhan invalid JSON / timeout not tested.  
7. No LOCATION_PRIVACY / TIMEZONE_ARCHITECTURE docs.

## Defaults (must be documented, not silent)

- Calculation method: `CalculationMethod.muslimWorldLeague` (Fajr 18°, Isha 17°).  
- Asr: `AsrMethod.standard` (shadow factor 1).  
- High latitude: `HighLatitudeMethod.none`.  
- 12-hour display unless `use24HourFormat`.  
- `autoConfigureForCountry` exists but is an explicit call, not a hidden GPS religion picker.

## Privacy

Coordinates stay on-device (`SharedPreferences` prayer location cache). Qibra FastAPI does not persist GPS. Do not add `/prayer/times` that stores lat/lng.

## Planned edits

Location engine + richer cache key + next/current prayer helpers + Hijri civil helper + Aladhan parse hardening + pytest + docs. **No Home redesign. No prayer formula rewrite. No Quran/Hadith VERIFIED.**
