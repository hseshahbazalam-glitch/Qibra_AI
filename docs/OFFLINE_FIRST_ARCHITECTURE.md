# Offline-first

Quran, Hadith, Duas, and prayer calculation work without a backend.

Reachability: **unknown ≠ online**. Connectivity loading/error does not pretend the device is online.

Cache: `lib/core/cache/cache_store.dart`. Sync queue is client-side until `/sync` is available.
