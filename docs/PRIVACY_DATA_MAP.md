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
| GPS / city | local cache | no | no | `precise_location_stored_on_server=false` |
| AI prompts | no | no query logs | no | |
| Billing | no | stub `is_premium` false | no | |

Observability consent default OFF. No Firebase/Sentry/Mixpanel in this checkout.
