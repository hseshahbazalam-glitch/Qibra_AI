# Phase 12 audit — Performance

**Date:** 2026-08-31  
**Branch:** `arena/01a049e4-qibra-ai`  
**Actual HEAD at audit start:** `0f36a25`  
**This file written before Phase 12 implementation.**

**Verdict:** Several **code-evident** bottlenecks (startup blocking, duplicate TZ init, sync per-item queries). **No device/Flutter profile.** Do not invent ms/FPS numbers. Do not restyle UI. Do not replace Phase 4–11 engines.

Flutter SDK **NOT RUN**. Device **NOT RUN**. PostgreSQL **NOT RUN**. Redis **NOT RUN**.

---

## 1. Current HEAD / scope / environment

Scope: measurable performance without changing user-visible UI or Phase 4–11 contracts.

Environment: Python pytest available (`/tmp/qibra-venv`). No `flutter`/`dart` on PATH.

---

## 2–5. Flutter / backend / startup / rebuilds

| Area | Finding | Class |
| --- | --- | --- |
| `main()` | Awaits timezone, dotenv, notifications, **full Quran JSON**, **full Hadith corpus** before `runApp`. First frame cannot happen until ~7 hadith collections are decoded. Hadith screens already call `initialize()` lazily. | **P1** |
| Timezone | `main` uses `timezone/data/latest_all.dart`; `NotificationService` uses `latest.dart` and inits again. Duplicate work. | **P2** |
| Quran | Single-flight `_initInFlight`; Isolate.parse for large JSON. **KEEP.** | INFO |
| Hadith load | Sequential `for` over 7 books, 3 JSON files each. Parallelizing all 7 risks memory peak — **do not** without a device. | P2 (defer) |
| Hadith search | Linear scan of all loaded texts; `maxResults` cap. Changing ranking would change behavior — **do not rewrite.** | P2 leave |
| Qibla | Compass `StreamSubscription` cancelled in `dispose`. Controllers disposed. | INFO |
| Home/Prayer `ListView(` | Small fixed children (hub chrome), not 6236-row lists. `ListView.builder` already used for surah reader / hadith book / search. | INFO |
| `google_fonts` | Runtime Inter fetch can delay first text. Replacing fonts would change look — **do not.** | P2 leave |
| Rebuilds | Not profiled. Do not sprinkle `const` / `select()` blindly. | NOT RUN |
| Hive/sqflite | Absent. | INFO |

---

## 6–9. Memory / Quran / search / cache

| Area | Finding | Class |
| --- | --- | --- |
| In-memory Quran + Hadith | Entire corpora retained after init. Correct for offline-first. Do not unload. | INFO |
| Observability buffer | Capped at 50 events. | INFO |
| Metrics counters | `defaultdict` with no key cap; `inc()` only blocks forbidden names. Unbounded distinct keys theoretically. | **P2** |
| CacheStore | Prefs backend cached after first access. Expired rows kept (Phase 9). | INFO |
| SharedPreferences | Many `getInstance()` call sites; OS caches the singleton. | INFO |

---

## 10–18. Sync / notifications / RAG / billing / API / DB / observability

| Area | Finding | Class |
| --- | --- | --- |
| `merge_records` | Per item: `SyncOperation` lookup + `SyncRecord` lookup (again on idempotent hit). N+1 on a 500-item batch. UniqueConstraint exists; semantics must stay LWW + idempotent. | **P1** |
| Bookmark `user_id` | UniqueConstraint `(user_id, collection, item_id)` covers list-by-user. Extra index not justified without Postgres EXPLAIN. | INFO |
| Notifications | Reconcile is O(n) set ops. Do not “optimize” by skipping reconcile. | INFO |
| RAG | Substring scan; honesty over speed. Do not add fuzzy shortcuts. | INFO |
| Billing | Unconfigured; no store round-trip. | INFO |
| API middleware | Metrics on every request including `/health`. Tiny overhead; skipping health is optional P3. | P3 |
| Engine | SQLite memory StaticPool in tests; Postgres `pool_pre_ping` + size 5. | INFO |
| Observability | Consent OFF; no third-party SDK. | INFO |

---

## 19. Performance risks of naive “fixes”

- Parallel 7-book Hadith decode → RAM spike.  
- Defer Quran as well as Hadith → Home daily ayah empty.  
- Isolate for Hadith search → copy 40k objects.  
- New packages (cached_network_image, etc.) — forbidden without measured need.

---

## 20. Prioritized plan (after this audit)

1. **P1** Defer Hadith corpus load until after `runApp`; keep Quran+notifications before first frame. Screens already `await initialize()`. Attach RAG when load completes.  
2. **P1** Prefetch `SyncRecord` / `SyncOperation` for the batch in `merge_records` (same LWW).  
3. **P2** Skip duplicate timezone init in `NotificationService` if already initialized.  
4. **P2** Cap metrics distinct keys (e.g. 64).  
5. Leave UI lists, google_fonts, RAG retrieve, notification IDs, prayer math.

---

## 21–22. Measurements

**Available:** pytest latency of sync merge / RAG / reconcile in this process (code-level).  
**Unavailable:** cold/warm startup, first frame, jank, RAM, scroll FPS, Flutter analyze — **NOT RUN**.

---

## 23. Files proposed

`lib/main.dart`, `lib/core/services/notification_service.dart`, `backend/app/services/sync_service.py`, `backend/app/observability/metrics.py`, tests + this audit/report.

## 24. Intentionally untouched

Prayer formulas, qibla, RAG retrieve algorithm, notification fingerprint, billing verifier, Home/Quran/Hadith UI, `google_fonts`, `isBackendEnabled`, content JSON.
