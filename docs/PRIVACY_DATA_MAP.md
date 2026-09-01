# Privacy data map

| Data | Local | Server | Synced | Notes |
| --- | --- | --- | --- | --- |
| Quran/Hadith/Dua assets | yes | no | no | Bundled files |
| App language, reading prefs | yes | optional settings keys | optional | No religious text |
| Quran bookmark refs | yes | `bookmarks` collection | optional | surah/ayah only |
| Hadith bookmark refs | yes | `bookmarks` collection | optional | book + id |
| Reading progress | yes | `progress` | optional | last position |
| Access/refresh tokens | secure storage | refresh **hash** only | no | Never log |
| Password | never | PBKDF2 hash | no | |
| GPS / city | local cache | no | no | `precise_location_stored_on_server=false`. See `LOCATION_PRIVACY.md`. |
| Generic CacheStore | prefs `qibra_cache_*` | no | no | No tokens/passwords/GPS/scripture in values. |
| Sync queue | prefs `qibra_sync_queue_v1` | optional `/sync` | refs only | Bookmarks/progress ids. Never tokens. |
| AI prompts | no | no query logs | no | |
| Billing | no | stub `is_premium` false | no | |
| Store receipts / purchase tokens | no | no | no | Verifier unconfigured. Never log. |

Observability consent default OFF. No Firebase/Sentry/Mixpanel in this checkout.
