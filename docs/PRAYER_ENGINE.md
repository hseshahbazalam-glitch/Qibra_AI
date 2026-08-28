# Prayer engine

Local astronomical calculation is the source of truth.

- Known-city catalog: GPS does not invent city names. Unmatched coordinates stay UNKNOWN.
- IANA timezone engine (`lib/core/timezone/timezone_engine.dart`).
- Next-prayer midnight wrap: after Isha, next is tomorrow Fajr.
- Schedule cache: 24h TTL.
- Aladhan parser exists but is not a live network source unless already wired.
