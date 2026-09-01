# Location privacy

Qibra FastAPI flag: `precise_location_stored_on_server: false`.

| What | Where | Transmitted to Qibra API | Retention |
| --- | --- | --- | --- |
| Lat/lng from Geolocator | Device memory + `SharedPreferences` `prayer_location_cache` | **No** | Until user clears app data or overwrites |
| Named city | Only if inside `KnownCityCatalog` radius | **No** | Same |
| IANA timezone | Derived from catalog / manual city | **No** | Same |
| Prayer times | Calculated on device; optional local cache | **No** | 24h TTL cache |
| Qibla | On-device bearing | **No** | None on server |

Do not add a backend route that stores GPS. Prayer calculation does not require server retention.

Manual city fallback is first-class when permission is denied, denied-forever, service-disabled, timed out, or unavailable.
