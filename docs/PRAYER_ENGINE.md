# Prayer engine

Local astronomical calculation (`PrayerCalculationService`) is the source of truth on device. **Formulas were not rewritten in Phase 7.**

## Provider

| Kind | Status |
| --- | --- |
| Local (on-device) | WIRED — Fajr, Sunrise, Dhuhr, Asr, Maghrib, Isha |
| Aladhan JSON parser | Parser only (`AladhanParser`). **Not a live network source.** |
| Imsak | Optional Aladhan field only. Not invented by local calc. |

## Documented defaults (not silent GPS fiqh)

- Method: Muslim World League (Fajr 18°, Isha 17°)
- Asr: Standard (shadow = 1×)
- High latitude: none
- Clock: 12-hour unless `use24HourFormat`
- `autoConfigureForCountry` is an **explicit** helper, not a hidden GPS religion picker

## Next prayer

After Isha, next is **tomorrow Fajr**. Sunrise is never an obligatory “current salah”. Countdown is `next.time - now` (no independent ticker math).

## Cache

Key: `lat4|lng4|YYYY-MM-DD|IANA|method|asr|provider`  
TTL 24h. Date rollover, timezone change, settings change, or location change miss the cache. Offline → empty/stale, never invented times.

## Known-city catalog

GPS does not invent city names. Unmatched coordinates stay `UNKNOWN`.
