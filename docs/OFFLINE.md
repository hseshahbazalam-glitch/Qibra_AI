# Offline

See `OFFLINE_FIRST_ARCHITECTURE.md`.

- Unknown network is not online.
- Cache hits may serve Quran/Hadith/prayer chrome without claiming live connectivity.
- Sync uses jittered backoff and retries; it does not reboot-proof notifications.
