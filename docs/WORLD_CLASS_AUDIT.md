# World-class audit (PHASE A)

**Date:** 2026-08-29  
**Branch:** `arena/01a049e4-qibra-ai`  
**HEAD at this re-audit:** `6d21225`  
**Verdict: NOT APPROVED**

Labels used here are only:

`KEEP` | `MERGE` | `DEFER` | `DELETE-ONLY-IF-DEAD` | `STUB` | `MISSING` | `NOT RUN`

Not a store-readiness certificate. Flutter SDK is absent. Do not read “world-class” into the filename.

---

## Method

- Inventory: `lib/core/router/app_router.dart`, `AppRoutes`, `lib/features/**`, backend routers + `rag.py`, client RAG.
- Dead-code rule: `DELETE-ONLY-IF-DEAD` only if **zero Dart imports AND zero GoRoute AND zero navigation**. If unsure: **KEEP**.
- Do **not** delete Home, Quran, Prayer, Hadith, AI, More, Mushaf, Surah reader, Search, Bookmarks, Qibla, Tasbih, Settings, Auth, Duas, Calendar, Tools hub + routed tool screens.
- Prior pass (`6d21225`) already removed nine proven-dead widgets. This re-audit classifies the **current** tree.

---

## 1. Screens & routes

### 1.1 Bottom nav — KEEP

| Tab | Path | Classification |
| --- | --- | --- |
| Home | `/home` | KEEP |
| Quran | `/quran` | KEEP |
| Prayer | `/prayer` | KEEP |
| Hadith | `/hadith` | KEEP |
| AI | `/ai-chat` | KEEP |
| More | `/more` | KEEP |

Hadith stays on the bar. Six tabs stay. Qibla is `/prayer/qibla` (More/Prayer), not a seventh tab. **KEEP**. No hub restyle. No Home redesign.

### 1.2 Auth / onboarding — KEEP (live social = STUB)

| Route | Screen | Classification |
| --- | --- | --- |
| `/` | SplashScreen | KEEP |
| `/onboarding` | OnboardingScreen | KEEP |
| `/login` | LoginScreen | KEEP |
| `/register` | RegisterScreen | KEEP |
| `/forgot-password` | ForgotPasswordScreen | KEEP |
| `/verify-otp` | VerifyOtpScreen | KEEP |
| `/profile-setup` | ProfileSetupScreen | KEEP |
| `AppRoutes.resetPassword` = `/reset-password` | **no GoRoute** | DEFER dead **name** (not a screen) |

Google/Apple/phone flags **false**. Social buttons exist, not live. **STUB**. **KEEP** login/register.

### 1.3 Quran — KEEP

| Route | Screen | Classification |
| --- | --- | --- |
| `/quran` | QuranScreen | KEEP |
| `/quran/surahs` | SurahListScreen | KEEP |
| `/quran/search` | QuranSearchScreen (`AppRoutes.quranSearch` used) | KEEP |
| `/quran/bookmarks` | BookmarksHubScreen nested | KEEP (overlap with `/bookmarks`, not dead) |
| `/quran/reader` | SurahReaderScreen | KEEP |
| `/quran/continue-reading` | SurahReaderScreen sibling | KEEP |
| `/quran/daily-ayah` | SurahReaderScreen sibling | KEEP |
| `/quran/mushaf` | MushafReaderScreen | KEEP |
| `/quran/tafseer` | TafseerScreen | KEEP screen; **STUB** corpus (no license) |
| `AppRoutes.quranSurah` | no GoRoute | DEFER dead name |
| `AppRoutes.quranBookmarks` | nested path exists; constant unused | DEFER dead name |

### 1.4 Prayer / Qibla — KEEP

| Route | Screen | Classification |
| --- | --- | --- |
| `/prayer` | PrayerTimesScreen | KEEP |
| `/prayer/schedule` | SalahScheduleScreen | KEEP |
| `/prayer/statistics` | PrayerStatisticsScreen | KEEP |
| `/prayer/tahajjud` | TahajjudDetailsScreen | KEEP |
| `/prayer/qibla` | QiblaScreen | KEEP |
| `/prayer/mosques` | MosqueFinderScreen | KEEP |
| `AppRoutes.prayerTimes` = `/prayer/times` | no GoRoute | DEFER dead name |

Do not rewrite prayer math or qibla formula.

### 1.5 Hadith — KEEP

| Route | Screen | Classification |
| --- | --- | --- |
| `/hadith` | HadithScreen | KEEP |
| `/hadith/book/:slug` | HadithBookScreen | KEEP |
| `hadithCollection` / `hadithDetail` / `hadithSearch` | no matching GoRoute | DEFER dead names |

Missing author → `"—"`. **KEEP**.

### 1.6 AI — KEEP (live LLM = STUB)

| Route | Screen | Classification |
| --- | --- | --- |
| `/ai-chat` | AIExplainScreen | KEEP |

`AppApi.isBackendEnabled = false` **KEEP false**. Retrieval assistant, not a scholar. Subtitle “Retrieval only — not a fatwa” is honesty, **KEEP**.

### 1.7 More extras — KEEP

| Route | Screen | Classification |
| --- | --- | --- |
| `/more` | MoreScreen | KEEP |
| `/dua` | DuasHomeScreen | KEEP |
| Duas list / detail | MaterialPageRoute | KEEP |
| `/calendar` | IslamicCalendarScreen | KEEP |
| `/tasbih` | TasbihScreen | KEEP |
| `/bookmarks` | BookmarksHubScreen | KEEP |
| `/settings` | SettingsScreen | KEEP |
| `/settings/notifications` | NotificationSettingsScreen | KEEP |
| `/profile` | UserProfileScreen | KEEP |
| `AppRoutes.notifications` / `about` | no GoRoute | DEFER dead names |
| `AppRoutes.duaDetail` | Navigator push, not GoRouter | KEEP |

Privacy/Terms copy-URL; live pages **UNKNOWN**. Help/Rate/Share: coming-soon. **STUB**.

### 1.8 Tools — KEEP

| Route | Screen | Classification |
| --- | --- | --- |
| `/tools` | ToolsHubScreen | KEEP |
| `/tools/zakat` | ZakatCalculatorScreen | KEEP (do not rewrite formulas) |
| `/tools/inheritance` | InheritanceCalculatorScreen | KEEP (do not rewrite formulas) |
| `/tools/sadaqah` | SadaqahTrackerScreen | KEEP |
| `/tools/habits` | HabitTrackerScreen | KEEP |
| `/tools/ramadan` | RamadanTimerScreen | KEEP |
| `/tools/hajj` | HajjGuideScreen | KEEP |
| `/tools/umrah` | UmrahGuideScreen | KEEP |
| `/tools/nikah` | NikahGuideScreen | KEEP |
| `/tools/asma` | AsmaUlHusnaScreen | KEEP |
| `/tools/halal` | HalalScannerScreen | KEEP |
| `/tools/names` | IslamicNameFinderScreen | KEEP |
| `/tools/dhikr` | TasbihScreen (same as `/tasbih`) | KEEP route; MERGE candidate only |

`DhikrCounterScreen` **already deleted** (`6d21225`). Do not restyle the tools hub.

---

## 2. Double / dead

| Item | Classification |
| --- | --- |
| `/tasbih` + `/tools/dhikr` | KEEP both |
| `/bookmarks` + `/quran/bookmarks` | KEEP both |
| Reader siblings (continue / daily / surah) | KEEP |
| Unused `AppRoutes` names listed above | DEFER (dead names, not extra screens). If unsure: KEEP. |
| Debug screens | none found |
| Leftover `AppColors.` in features | none found |
| Nine unused widgets listed in prior audit | **already DELETE-ONLY-IF-DEAD applied** at `6d21225` |

### Remaining zero-filename-importers — KEEP (unsure / math / infra)

Do **not** delete:

- `lib/core/billing/billing_service.dart`
- `lib/core/content/content_provenance.dart`
- `lib/core/content/content_validator.dart`
- `lib/core/design_system/contrast.dart`
- `lib/core/l10n/app_locales.dart`
- `lib/core/notifications/notification_reconcile.dart`
- `lib/core/observability/observability.dart`
- `lib/core/offline/offline_store.dart`
- `lib/core/sync/sync_engine.dart`
- `lib/core/timezone/timezone_engine.dart`
- `lib/features/prayer/data/services/next_prayer_engine.dart`
- `lib/features/prayer/data/services/prayer_schedule_cache.dart`
- `lib/features/prayer/data/services/prayer_source.dart`
- `lib/features/quran/data/repository/quran_meta.dart`
- `lib/features/quran/presentation/ayah_options_sheet.dart`
- `lib/features/quran/providers/reading_preferences_provider.dart`
- `lib/shared/utils/safe_context.dart`

**This PHASE B1: no additional file deletes.**

---

## 3. Backend

| Item | Classification | Notes |
| --- | --- | --- |
| Bookmarks/progress/settings/sync/`/users/me` scoped to `user.id` | KEEP | IDOR filtered |
| `/ai/ask` unauthenticated | KEEP | `test_ask_does_not_require_auth` |
| Rate limit 60/60 + store reset | KEEP | Do not weaken |
| Health `*_production_ready` false | KEEP | Do not flip |
| CORS `allow_origins=*` | KEEP absent | Do not add |
| JWT empty → `dev-only-change-me`; `QIBRA_ENV=production` refuses insecure | KEEP | Tests set `JWT_SECRET=test-secret` |
| Unhandled Exception → `{detail: server_error}`, `debug=False` | KEEP (done in `6d21225`) | No stack traces in JSON |
| Body cap 256 KiB | KEEP (done) | `payload_too_large` 413 |
| Request IDs | KEEP | `RequestIdMiddleware` |
| `/ai/ask` query logging | KEEP none | Do not add |
| Billing `/status` `/verify` | STUB | `is_premium` false |
| Client `isBackendEnabled` | KEEP false | |
| Secrets in git | KEEP | no committed `backend/.env` |
| Generic 401 wording | DEFER | `missing_token` / `invalid_token` already opaque enough |

---

## 4. RAG / AI

| Item | Classification | Notes |
| --- | --- | --- |
| Empty retrieve → `no_retrieved_passage` | KEEP | Do not loosen substring retrieve |
| `verified: False` always | KEEP | Never invent VERIFIED |
| Citations only non-empty retrieved `source` | KEEP | No fabricated labels |
| Scholar refuse copy on AI path | KEEP stripped (`6d21225`) | Screen “not a fatwa” honesty stays |
| Actionish bypass | KEEP tightened | `_isActionCommand`: short verbs only; questions still refuse |
| Offline local retrieve | KEEP | Retrieve before connectivity fail |
| Prompt / Quran / Hadith logs | KEEP none on RAG path | |
| `isBackendEnabled` | KEEP false | |
| Client corpus on `/ai/ask` | KEEP for tests | Never marked verified |
| New LLM vendor / tafsir corpus | DEFER | Out of scope |

---

## 5. Already good (do not rewrite)

- Six-tab shell with Hadith kept.
- Quran / Hadith / Prayer stay free.
- Ivory / forest / gold tokens (`#C6A15B` fill, `#6B542B` text, `#123F36` forest).
- Recitation honest (not bundled). Tafsir unavailable without license.
- Continue-reading / daily ayah / surah reader as GoRouter siblings.
- IDOR on user-owned collections.
- RAG refuse on empty retrieve.
- Rate limit 60/60; health flags false; no CORS `*`.
- Observability / Firebase / Sentry / Mixpanel not wired.

---

## 6. Flutter / tests

| Item | Classification |
| --- | --- |
| Flutter SDK | MISSING |
| `flutter analyze` / `flutter test` / release | NOT RUN |
| Backend `test_phase3.py` … `test_phase15.py` | Re-run after this pass; do not delete tests |

---

## 7. PHASE B (this pass)

- **B1:** No further proven-dead feature files. Nine already gone. Remaining zero-importers **KEEP**. Unused `AppRoutes` names **DEFER**.
- **B2:** Already on tree (IDOR, 60/60, no traces, body cap, JWT, no CORS `*`, flags false). No extra backend stack.
- **B3:** Already on tree (refuse, citations, no scholar refuse copy, no prompt logs, tight actionish, offline retrieve, `isBackendEnabled` false).
- **B4:** Skip. No hub restyle. No Home redesign.

---

**Verdict: NOT APPROVED**
