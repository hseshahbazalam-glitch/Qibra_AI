# Phase 9 audit — Offline-first architecture

**Date:** 2026-08-30  
**Branch:** `arena/01a049e4-qibra-ai`  
**Actual HEAD at audit start:** `40b7892`  
**Requested start `1c65f66`:** not in this checkout. No reset.  
**This file written before Phase 9 implementation.**

**Verdict: NOT APPROVED for production.** Bundled Quran/Hadith/Dua/prayer already work without a backend. Cache, reachability, and SyncEngine exist but are incomplete for stale-while-revalidate, service-plane distinction, and conservative retries. Flutter SDK **NOT RUN**. Device **NOT RUN**. PostgreSQL/Redis **NOT RUN**. `AppApi.isBackendEnabled = false`.

Do not restyle UI. Do not replace Phase 6 SyncEngine / SyncPull. Do not rewrite Phase 7 prayer math or Phase 8 notification IDs. Do not invent Islamic content. Phase 6 licenses stay UNKNOWN / REQUIRES_PERMISSION / DO_NOT_DISTRIBUTE.

---

## 1. Git / reports

| Report | Status on tree |
| --- | --- |
| PHASE6_REPORT / PHASE6_CONTENT_REPORT | Present. Integrity WIRED. No VERIFIED licenses. |
| PHASE7_REPORT | Present. Local prayer + cached/manual location. No GPS API. |
| PHASE8_REPORT | Present. Local inexact notifications. Not reboot-proof. |
| OFFLINE.md / OFFLINE_FIRST_ARCHITECTURE.md | Stubs. |
| CACHE_STRATEGY.md / OFFLINE_SYNC.md | **MISSING**. |
| Existing PHASE9_AUDIT / PHASE9_REPORT | Placeholder checklists, not an architecture audit. |

Working tree at audit start: clean on `40b7892`.

---

## 2. Storage inventory

| Store | Path | Notes |
| --- | --- | --- |
| SharedPreferences | CacheStore, SyncEngine queue, prayer location, reading progress, notif IDs | Durable across restart. Not a SQL DB. |
| FlutterSecureStorage | access/refresh tokens, user id | Encrypted. Never log. |
| Asset JSON | Quran, Hadith, Duas | Bundled. Read-only. Offline. |
| In-memory maps | QuranRepository, HadithDatabaseService | Lost on process death; reload from assets. |
| Hive / sqflite / Isar / Drift | **not in pubspec** | Do **not** add a second database. |

`lib/features/duas/data/database/dua_database.dart` is Dart lists, not SQLite.

---

## 3. Cache

`lib/core/cache/cache_store.dart` — PRESENT & WIRED.

- `CacheEntry`: key, value, storedAt, ttl. **Missing:** version, source, checksum, expiresAt as first-class, freshness enum.
- `read()` **deletes** expired entries and returns null. Violates “do not delete useful stale data merely because TTL expired.”
- Prayer schedule cache (`prayer_schedule_cache.dart`) uses 24h TTL; expired day → miss even if times would still be useful offline.
- No stale-while-revalidate helper.
- Prefix `qibra_cache_`. Does not log payloads.

`OfflineStore` is a thin prefix wrapper. Extra, not a second engine.

---

## 4. Connectivity

`Reachability` = online | offline | unknown. **unknown ≠ online** (`mayUseNetwork` only for online). **PRESENT & WIRED** via `reachabilityProvider`.

Gaps:

- No `reconnecting`.
- Transport “online” treated as API-ready. **Network ≠ backend health.**
- No `NETWORK_AVAILABLE` / `BACKEND_AVAILABLE` / `LOCAL_ONLY` plane.
- `ApiClient._ensureOnline` uses `connectivity_plus` only; empty/none → offline exception; other errors swallowed (may still attempt Dio).
- `ai_provider.dart` also imports connectivity (scattered check).

`isBackendEnabled` is false → all cloud paths must stay local-only.

---

## 5. Sync

`SyncEngine` + `SyncQueue` + `SyncOp` — PRESENT & WIRED. Persist key `qibra_sync_queue_v1`. Single-flight. Batch 500. Enqueue replaces same `collection+id` (idempotent slot).

Gaps:

- `retry()` retries **all** exceptions, including validation/auth if callers pass them.
- No `nextRetryAt`. `errorCode` exists; no typed lastError.
- `flushWhenOnline` no-ops unless `online && isBackendEnabled`.
- No second engine. **KEEP.** Do not create SyncPull replacement.
- Conflict: `BookmarkMerge` set-union + tombstones; `ProgressMerge` latest-wins. **KEEP.**

Queue payload contract: references only, never tokens / Quran-Hadith full text (`SYNC_PROTOCOL.md`).

---

## 6. Feature offline matrix

| Feature | Local source | Network required? | Honesty |
| --- | --- | --- | --- |
| Quran | bundled JSON | no | licenses UNKNOWN / Asad REQUIRES_PERMISSION |
| Hadith | bundled JSON | no | UNKNOWN; missing Tirmidhi Urdu |
| Tafsir | not bundled | n/a | stay unavailable; do not invent |
| Duas | Dart corpus | no | existing text only |
| Prayer | on-device calc + cache + manual city | no | Aladhan optional/not live |
| Hijri | `hijri_civil.dart` | no | civil/tabular, not ru’yah |
| Location | DEVICE / MANUAL / CACHED | GPS optional | no city invention; no GPS to Qibra API |
| Notifications | Phase 8 reconcile from local times | no | inexact; not reboot-proof |
| RAG | local substring retrieve | no | no-source refuse; never VERIFIED here |
| Auth | secure storage + stub repo | yes for login/refresh | network fail must not logout; `serverValidated` false offline |
| Bookmarks/progress | SharedPreferences | sync only if backend on | |

---

## 7. RAG

Backend `app/rag.py`: retrieve substring; empty → `no_retrieved_passage`; `verified` always False; production corpus only VERIFIED → empty.

Dart `RagService`: local Quran/Hadith search; UNKNOWN status; empty → refuse string. **No retrieval-mode enum** (`LOCAL_RETRIEVAL` / `REMOTE_RETRIEVAL` / `NO_CONTEXT`). Do not redesign retrieval.

---

## 8. Auth / startup

- Backend off → guest immediately. Fake JWT purged.
- Offline `getCurrentUser` → keep authenticated with cached id; **does not** set `serverValidated`.
- Refresh network failure → `RefreshOutcome.networkFailure`, no logout.
- Logout always clears local tokens even if remote logout fails.
- `main.dart` initializes tz, notifications (failure swallowed), Quran, Hadith. Does not wait on network. **KEEP.**

Expired access token while offline: refresh needs network → stay on cached session, not server-validated. Not fully enumerated as a type.

---

## 9. Privacy

Tokens in secure storage. GPS in local prayer location cache only (`LOCATION_PRIVACY.md`). Sync queue must not hold tokens/GPS/full scripture. CacheStore values are opaque strings — callers must not write secrets. Observability consent default OFF.

---

## 10. TODOs / online-only assumptions

- One TODO in `halal_service.dart` (Open Food Facts) — leave; not Phase 9.
- No Hive/SQLite.
- Direct API from UI: Dio is centralized in `ApiClient`. AI provider has extra connectivity import.
- Cache keys: prayer key includes rounded lat/lng (Phase 7). Generic cache has no schema version.

---

## 11. Tests today

`test/phase9_test.dart` / `backend/tests/test_phase9.py` — string/flag checks, **not** cache/queue/SWR behavior.

Flutter analyze/test: **NOT RUN**. Last backend pytest (Phase 8): 178 passed.

---

## 12. Planned Phase 9 edits (after this audit)

1. Cache freshness: missing / fresh / stale / expired; **keep** expired data; optional memory backend for tests.  
2. `DataStatus` + `ServicePlane` (localOnly / networkAvailable / backendAvailable). Reachability + reconnecting; unknown ≠ online.  
3. Retry classifier (retry timeout/5xx/network; not 4xx auth/validation). `nextRetryAt` on SyncOp. **Do not** replace SyncEngine.  
4. RAG retrieval mode wrapper only.  
5. Python mirrors + Dart/Python tests. Docs.  
6. No new database. No UI redesign. No prayer/notification/auth rewrite.

## Production blockers (unchanged)

No Flutter/device/Postgres. Backend flag false. Content licenses not VERIFIED. Notifications not reboot-proof.
