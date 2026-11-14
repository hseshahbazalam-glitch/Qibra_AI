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
| Account deletion | — | **hard delete** | — | `DELETE /users/me` removes the user row and every dependent row (bookmarks, sync records + operation ids, settings, progress, sessions, refresh-token hashes) in one transaction. Retention after a 200: **zero rows**. No tombstone, no grace period, no backup table. Re-registering the same address starts an empty account that inherits nothing. |
| Email address | yes | yes, UNIQUE, canonical (trimmed + lowercased) | no | A deleted account's address is freed, not held |
| Billing | no | stub `is_premium` false | no | |
| Store receipts / purchase tokens | no | no | no | Verifier unconfigured. Never log. |

Observability consent default OFF. No Firebase/Sentry/Mixpanel in this checkout.
