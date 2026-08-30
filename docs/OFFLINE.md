# Offline

See `OFFLINE_FIRST_ARCHITECTURE.md`, `CACHE_STRATEGY.md`, `OFFLINE_SYNC.md`.

- Unknown / reconnecting is not online.
- Transport online is not backend-available.
- Cache hits may serve Quran/Hadith/prayer chrome without claiming live connectivity.
- Expired cache is kept until invalidated.
- Sync uses jittered backoff; it does not reboot-proof notifications.
