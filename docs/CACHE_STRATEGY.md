# Cache strategy

Store: SharedPreferences via `CacheStore` (`qibra_cache_*`). No second database.

`CacheEntry`: key, value, storedAt, updatedAt, expiresAt (from ttl), staleAfter, version, source, checksum.

| Freshness | Behavior |
| --- | --- |
| missing | no row; network if plane allows; else `unavailable` |
| fresh | return immediately |
| stale | return data; caller may revalidate (no refresh loop) |
| expired | **keep** data until `invalidate`; treat as usable stale |

TTL expiry does **not** delete. Invalidation is explicit.

Do not cache: access tokens, refresh tokens, passwords, raw GPS, Quran/Hadith full text (those live in bundled assets / in-memory repos).

Prayer schedule cache key remains Phase 7 (`lat4|lng4|date|tz|method|asr|provider`). 24h TTL; expired times may still be read.
