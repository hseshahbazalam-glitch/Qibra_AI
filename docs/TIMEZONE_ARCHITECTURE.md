# Timezone architecture

- Store **IANA** identifiers (`Asia/Karachi`, `America/New_York`, …).
- Resolve offsets with the `timezone` package (Flutter) / `zoneinfo` (pytest).
- DST is the difference vs the smaller of mid-January / mid-July offsets.
- Unknown IANA → `ok: false`, offset not invented. **No default to `Asia/Kolkata` or `UTC`.**
- Prayer clocks should use the **location** IANA, not the phone locale, when an IANA id is present.
- Hijri UI uses the `hijri` package on the **local civil date**. That conversion is tabular, **not** moon-sighting, and is not authoritative for Ramadan/Eid.
