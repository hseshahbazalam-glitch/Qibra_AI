# Qibra AI — Architecture

> Read-this-first map for new maintainers. Every claim here cites real
> paths; if code and this file disagree, the code wins and this file is
> a bug (fix it in the same commit as the change).
> Companion docs: [`docs/CONVENTIONS.md`](docs/CONVENTIONS.md) (how we
> write code and tests), [`docs/API_CONTRACT.md`](docs/API_CONTRACT.md),
> [`docs/AUTH.md`](docs/AUTH.md), and
> [`lib/core/design_system/DESIGN_SYSTEM.md`](lib/core/design_system/DESIGN_SYSTEM.md).

## Layer diagram

```
lib/main.dart                    entry: binding → tz table (synchronous,
   │                             pre-runApp BY DESIGN) → dotenv → system UI
   │                             → runApp FIRST; heavy data init lives in
   │                             core/providers/app_providers.dart
   ▼                             (dataBootstrapProvider, started by the
lib/core/router/app_router.dart   splash's first frame — perf pass).
   single GoRouter, 44 GoRoutes
   │
   ▼
lib/features/<feature>/          17 features: ai, auth, bookmarks,
   ├── data/     models · services· repository   (pure Dart, no context)
   ├── providers/ Riverpod state (the only layer widgets watch)
   └── presentation/ screens + sheets (widgets; no business logic)
   │
   ▼
lib/core/ (19 modules) + lib/shared/ (widgets, utils)   ← the shared base
```

Feature → feature imports are forbidden; sharing between features goes
through `core/`, `shared/`, or a provider. Enforced socially (import
policy, [`docs/CONVENTIONS.md`](docs/CONVENTIONS.md)), not by tooling.

## The `core/` module table (19)

| module | contents (verified) | add here when… |
|---|---|---|
| `router` | `app_router.dart` — the one GoRouter + `AppRoutes` | every new *screen* gets a route here; nothing else |
| `observability` | `observability.dart` — logging sinks | a new cross-cutting log/debug channel belongs here, not `print` |
| `offline` | `data_status.dart`, `offline_store.dart`, `reachability.dart` | a feature needs "is it downloaded / are we online" state |
| `cache` | `cache_store.dart` | anything download-once-read-often (audio, remote content) |
| `sync` | `sync_engine.dart`, `conflict.dart`, `retry_policy.dart`, `account_migration.dart` | account-scoped local→remote mirroring rules change |
| `hijri` | `hijri_civil.dart` — civil-day helpers over the bundled `hijri` package | Hijri math used by 2+ features (per-screen formatting is call-site: e.g. `hijriTodayLabel` in `hadith_screen.dart`) |
| `l10n` | `app_locales.dart`, `app_strings.dart` — code-getter strings, **no .arb** (UI copy is English-only; *content* is multilingual by design) | new UI strings; never hardcode copy inside a screen if AppStrings has a getter |
| `network` | `api_client.dart`, `http_auth_repository.dart` | any HTTP leaves the app only through here |
| `notifications` | `notification_reconcile.dart`, `dua_reminder_policy.dart` (channel plumbing: `core/services/notification_service.dart`) | scheduled-notification policy |
| `providers` | `app_providers.dart` (**`dataBootstrapProvider`** — the whole heavy-init story), `auth_provider.dart`, `theme_provider.dart` | an app-lifetime provider; per-feature providers stay in their feature |
| `services` | `notification_service.dart` | plugin-facing services shared by features |
| `utils` | `search_normalizer.dart` (fold-aware search: `allMatches` answers in ORIGINAL text coordinates), `countdown_format.dart` | a pure helper used by 2+ features — Quran *and* Hadith search both ride `SearchNormalizer`; that shared truth is why it lives here |
| `a11y` | `app_a11y.dart` | semantics helpers beyond per-widget tooltips |
| `billing` | `billing_service.dart` | entitlement surface (gates are pinned by `test/core/phase10_*`) |
| `content` | `content_provenance.dart`, `content_validator.dart`, `edition_resolver.dart`, `word_by_word.dart` | anything about corpus provenance/validation joins here + `assets/data/content_manifest.json` |
| `location` | `location_engine.dart`, `location_resolver.dart`, `privacy` doc `LOCATION_PRIVACY.md` at root | city/coordinate resolution; the honest-UNKNOWN contract lives here |
| `timezone` | `timezone_engine.dart` | prayer-time timezone math |
| `constants` | `app_constants.dart` (storage keys, assets), `app_assets_check.dart` (debug asset guard) | new SharedPreferences keys and asset paths — single source |
| `design_system` | `qibra_navy.dart` (token single-source), `qibra_colors.dart`, `app_theme.dart`, `app_typography.dart`, `contrast.dart`, `DESIGN_SYSTEM.md` | any color/typography token; screens never mint `Color(0x…)` outside token files (battery-enforced) |

## Feature anatomy — hadith as the worked example

```
lib/features/hadith/
├── data/
│   ├── hadith_availability.dart     per-book×language AVAILABILITY truth
│   ├── models/hadith_models.dart    HadithModel/HadithBook/HadithGrade
│   └── services/
│       ├── hadith_database_service.dart   factory-singleton over the bundled
│       │                                  corpus; multi-language rows joined
│       │                                  per book by pairKey; scanning runs
│       │                                  OFF the UI isolate (searchBatchOff-
│       │                                  Main); [HADITH_DB] timing logs;
│       │                                  waitForReady() bounded cold-start
│       └── hadith_view_history.dart   persisted '<slug>#<n>' LRU (cap 50,
│                                     newest-first; the ONLY continue truth)
├── providers/                       hadith_provider.dart — the ONLY writer
│                                     of view history is recordHadithView;
│                                     bookmarks/recents/search providers
└── presentation/                    hadith_screen.dart (Today card, segment
                                      rail, search sheet), hadith_book_screen
                                      .dart (reader + sheets), hadith_related
                                      _section.dart
```

Canonical shape for every feature (`quran/` mirrors it, `tools/` predates
it — `tools/screens/` is legacy, see conventions). Rules the hadith
feature demonstrates globally:

- **Data flows one way:** assets → service → provider → widget. Screens
  never read `rootBundle` (battery gate G6 pins this).
- **Honest absence is a feature, not a fallback:** no topic data in the
  corpus ⇒ no Topics grid; no timestamps in the LRU ⇒ no "read 2m ago".
  `HadithGrade.unknown` renders nothing rather than guessing a grade
  (the tab surfaces show `'<grade> · collection grade'` qualifiers —
  `hadith_screen.dart` — and the AI layer keeps `REFUSE: no retrieved
  passage. Do not invent Quran or Hadith.` as its sentinel).
- **Search highlights are the corpus's truth:** `SearchNormalizer`
  folds diacritics/case for MATCHING only; the displayed span is always
  the verbatim original at original coordinates.

## The quality system (this repo's identity)

**CI** — one workflow, one job, three gates
(`.github/workflows/ci.yml`, Flutter `3.44.6` pinned):
1. `flutter analyze --no-fatal-infos` — **0 errors, 0 warnings**; the
   ~160 infos are sanctioned debt (see the comment above that step).
2. `flutter test` — the full suite (60 files / ~341 tests as of 2026-09-08),
   discovered recursively from `test/`.
3. `python3 scripts/static_battery.py` — the repo-authored static
   analyzer (gates G1–G17 + design sweeps L1–L8; G2 is advisory-only;
   see the header index in the script). Prints `::error`/`::notice`
   GitHub annotations when `GITHUB_ACTIONS=true` — API-readable findings
   even when raw logs are not.

**The REPORT RULE:** every battery result is reported as the exact three
counts, verbatim — `hard findings: N | G2 advisories: N | L2 alpha
advisories: N` — never summarized, never truncated, exit code included.

**Source-pin philosophy:** a large share of the suite are *pin tests* —
they read `lib/` files as text and assert on structure
(`File('lib/features/…').readAsStringSync().contains(…)`) so that
architectural promises (boot order, single writers, absent chrome,
token policy) fail CI if a refactor erodes them. Consequences:
- **Moving/renaming any `lib/` file requires updating every pin in the
  same commit** (`grep -rl "<new-path-fragment>" test/` finds them; the
  paths are stable strings, not regexes).
- Negative pins must run comment-blind (`test/support/source_guards.dart
  → stripCommentsForGuard`) — an honest explanatory comment is allowed
  to *name* a forbidden string; code is not (this exact bug cost a CI
  cycle on 2026-09-08, see the fix in `test/hadith_redesign_test.dart`).
- Pin tests are fixture-only: no network, no real assets; pure helpers
  extracted for testability (`neighbourNumber`, `hadithPositionLabel`,
  `hadithHighlightSpans`, `todayIndexFor`…) carry the real logic.

**MERGE HOLD protocol:** work lands on `arena/*` branches, pushes allowed,
**no PR/merge without an explicit owner decision**, `main` is untouched
by agents. Owner handles `.github/workflows/**` pushes personally.

**CLOSED FOREVER** (product decisions, do not re-propose; each has a
test or battery gate holding the line): Topics grid · narrator-chain/
isnad UI · explanation pages · share-as-image · narrator filter ·
Roman-Urdu hadith *content* (search normalization for it is allowed) ·
Listen/TTS tiles · sort dropdown.

## Data truths

- **Hadith corpus:** 7 books (`_bookNames` in `hadith_database_service
  .dart`: bukhari, muslim, nasai, abudawud, tirmidhi, ibnmajah, malik)
  × 7 languages (Arabic/English/Urdu/Bengali/Turkish/Indonesian/French —
  the `text*` fields of `LocalHadith`), bundled under `assets/data/
  hadith/`, joined per book row-by-row by **pairKey** (see
  `hadith_database_service.dart`) — a language that fails the join
  renders as honestly unavailable (`hadith_availability.dart`), never
  as a silent substitution. Upstream provenance and audits:
  `assets/data/content_manifest.json` + `scripts/validate_content.py`
  + `lib/core/content/`.
- **Honest-UNKNOWN principle** (32 `'UNKNOWN'` sites, e.g.
  `location_engine.dart`, `prayer_times_screen.dart`): when the app does
  not know — city unresolved, grade absent, translation missing — it
  shows `UNKNOWN`/the absence, and every feature gate that could paper
  over it is pinned off.
