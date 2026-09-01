# Offline-first architecture

**Status:** WIRED in source. Flutter **NOT RUN**. Not production-ready.

Source of truth:

```
LOCAL DATA (assets, prefs, secure storage)
        ↓
CACHE / REPOSITORY
        ↓
NETWORK (only if Reachability.online)
        ↓
REMOTE SYNC (only if ServicePlane.backendAvailable)
```

UI must not treat connectivity loading as online. `unknown` and `reconnecting` are **not** online.

## Feature contract

| Feature | Offline | Notes |
| --- | --- | --- |
| Quran / Hadith / Duas | bundled | licenses unchanged from Phase 6 |
| Tafsir | unavailable | do not invent |
| Prayer / Hijri / Qibla | local calc | network never required |
| Location | cached + manual | no GPS to Qibra API |
| Notifications | Phase 8 local reconcile | inexact; not reboot-proof |
| RAG | local retrieve | `NO_CONTEXT` if empty; never VERIFIED here |
| Auth | cached session | `serverValidated` false offline |
| Bookmarks / progress | local prefs | queue until backend is on |

## Service plane

- `LOCAL_ONLY` — no usable transport
- `NETWORK_AVAILABLE` — transport up; API not proven
- `BACKEND_AVAILABLE` — `isBackendEnabled` **and** a real health probe (`backendHealthy`)

This checkout: `isBackendEnabled = false`, `backendHealthy = false`.

## Data status

`fresh` | `stale` | `unavailable` | `syncing` | `offline` | `failed` | `pendingSync`

Do not hide stale data. Do not block startup on network.
