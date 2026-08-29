# World-class audit (PHASE A)

**Date:** 2026-08-29  
**Branch:** `arena/01a049e4-qibra-ai`  
**HEAD at audit start:** `af6cf78`  
**Verdict after this pass: NOT APPROVED**

This is a read-then-classify audit. Labels in this file are only:

`KEEP` | `MERGE` | `DEFER` | `DELETE-ONLY-IF-DEAD` | `STUB` | `MISSING` | `NOT RUN`

Do not treat this document as a store-readiness certificate. Flutter SDK is absent here.

---

## Method

- Inventory: `lib/core/router/app_router.dart`, `AppRoutes`, `AppShellScaffold` (6 tabs).
- Dead-code rule: `DELETE-ONLY-IF-DEAD` only if **zero Dart imports AND zero GoRoute AND zero navigation**. If unsure: **KEEP**.
- Do **not** recommend deleting Home, Quran, Prayer, Hadith, AI, More, Mushaf, Surah reader, Search, Bookmarks, Qibla, Tasbih, Settings, Auth, Duas, Calendar, Tools hub + routed tool screens.
- Backend: `backend/app/{main,config,rag,deps}.py` + routers bookmarks/sync/users/progress/settings/ai/auth/billing/health.
- RAG: `backend/app/rag.py`, `lib/features/ai/services/rag_service.dart`, `lib/features/ai/providers/ai_provider.dart`.
- Flutter analyze / test: **NOT RUN** (no SDK). Backend pytest: re-run after PHASE B.

---

## 1. Screens / routes

### 1.1 Bottom navigation — KEEP

| Tab | Path | Classification |
| --- | --- | --- |
| Home | `/home` | KEEP |
| Quran | `/quran` | KEEP |
| Prayer | `/prayer` | KEEP |
| Hadith | `/hadith` | KEEP |
| AI | `/ai-chat` | KEEP |
| More | `/more` | KEEP |

Hadith stays on the bar. Six tabs stay. Qibla is a routed sibling (`/prayer/qibla`) reached from More/Prayer, not a seventh tab. **KEEP** that layout. Do not restyle hubs. Do not redesign Home.

### 1.2 Auth / onboarding — KEEP (some STUB)

| Route | Screen | Classification |
| --- | --- | --- |
| `/` | SplashScreen | KEEP |
| `/onboarding` | OnboardingScreen | KEEP |
| `/login` | LoginScreen | KEEP |
| `/register` | RegisterScreen | KEEP |
| `/forgot-password` | ForgotPasswordScreen | KEEP |
| `/verify-otp` | VerifyOtpScreen | KEEP |
| `/profile-setup` | ProfileSetupScreen | KEEP |
| `/reset-password` | AppRoutes constant only, **no GoRoute** | DEFER (constant; not a live screen) |

Google/Apple/phone auth flags are **false**. Social buttons exist but are not live. **STUB** for live social auth. **KEEP** the login/register screens.

### 1.3 Quran family — KEEP

| Route | Screen | Classification |
| --- | --- | --- |
| `/quran` | QuranScreen | KEEP |
| `/quran/surahs` | SurahListScreen (nested) | KEEP |
| `/quran/search` | QuranSearchScreen (nested; `AppRoutes.quranSearch` used from QuranScreen) | KEEP |
| `/quran/bookmarks` | BookmarksHubScreen (nested) | KEEP (duplicate of `/bookmarks`, not dead) |
| `/quran/reader` | SurahReaderScreen | KEEP |
| `/quran/continue-reading` | SurahReaderScreen sibling | KEEP |
| `/quran/daily-ayah` | SurahReaderScreen sibling | KEEP |
| `/quran/mushaf` | MushafReaderScreen (outside tab shell) | KEEP |
| `/quran/tafseer` | TafseerScreen | KEEP screen; **STUB** corpus (no license file) |
| `AppRoutes.quranSurah` = `/quran/surah` | no GoRoute | DEFER constant |

### 1.4 Prayer / Qibla — KEEP

| Route | Screen | Classification |
| --- | --- | --- |
| `/prayer` | PrayerTimesScreen | KEEP |
| `/prayer/schedule` | SalahScheduleScreen | KEEP |
| `/prayer/statistics` | PrayerStatisticsScreen | KEEP |
| `/prayer/tahajjud` | TahajjudDetailsScreen | KEEP |
| `/prayer/qibla` | QiblaScreen | KEEP |
| `/prayer/mosques` | MosqueFinderScreen | KEEP |
| `AppRoutes.prayerTimes` = `/prayer/times` | no GoRoute (hub is `/prayer`) | DEFER constant |

Do not rewrite prayer math or qibla formula.

### 1.5 Hadith — KEEP

| Route | Screen | Classification |
| --- | --- | --- |
| `/hadith` | HadithScreen | KEEP |
| `/hadith/book/:slug` | HadithBookScreen | KEEP |
| `hadithCollection` / `hadithDetail` / `hadithSearch` constants | no matching GoRoute | DEFER constants |

Author missing → `"—"`. **KEEP**.

### 1.6 AI — KEEP (honesty STUB until backend)

| Route | Screen | Classification |
| --- | --- | --- |
| `/ai-chat` | AIExplainScreen | KEEP |

`AppApi.isBackendEnabled = false` **KEEP false**. Client still talks as if an LLM path exists. PHASE B3 tightens refuse / citations / logging. Not a scholar. **STUB** for live LLM.

### 1.7 More hub extras — KEEP

| Route | Screen | Classification |
| --- | --- | --- |
| `/more` | MoreScreen | KEEP |
| `/dua` | DuasHomeScreen | KEEP |
| Duas list / detail | MaterialPageRoute from hub (not GoRouter) | KEEP |
| `/calendar` | IslamicCalendarScreen | KEEP |
| `/tasbih` | TasbihScreen | KEEP |
| `/bookmarks` | BookmarksHubScreen | KEEP |
| `/settings` | SettingsScreen | KEEP |
| `/settings/notifications` | NotificationSettingsScreen | KEEP |
| `/profile` | UserProfileScreen | KEEP |
| `AppRoutes.notifications` = `/notifications` | no GoRoute | DEFER constant |
| `AppRoutes.about` | no GoRoute | DEFER constant |
| `AppRoutes.duaDetail` | no GoRoute (Navigator push) | KEEP navigation via MaterialPageRoute |

Privacy/Terms: copy-URL dialog, live pages **UNKNOWN**. Help/Rate/Share/font/reciter/translation: coming-soon. **STUB**.

### 1.8 Tools hub + routed tools — KEEP

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
| `/tools/halal` | HalalScannerScreen | KEEP (scanner is honest/local, not a licensed DB) |
| `/tools/names` | IslamicNameFinderScreen | KEEP |
| `/tools/dhikr` | **TasbihScreen** (same widget as `/tasbih`) | KEEP route; MERGE candidate only — **do not delete route** |

Do not restyle the tools hub.

---

## 2. Double / overlapping (not dead)

| Pair | Notes | Classification |
| --- | --- | --- |
| `/tasbih` and `/tools/dhikr` | Both build `TasbihScreen` | KEEP both routes |
| `/bookmarks` and `/quran/bookmarks` | Both `BookmarksHubScreen` | KEEP |
| `/quran/reader`, `/quran/continue-reading`, `/quran/daily-ayah` | Same reader, required siblings outside nested tab children | KEEP |
| `lib/features/quran/presentation/bookmarks_screen.dart` | Wrapper around hub; **zero importers, zero GoRoute** | DELETE-ONLY-IF-DEAD |
| `DhikrCounterScreen` | `/tools/dhikr` uses Tasbih, not this file; **zero importers** | DELETE-ONLY-IF-DEAD |

Unused `AppRoutes` string constants (`resetPassword`, `quranSurah`, `prayerTimes`, hadith* names, `about`, `notifications`) are **not** extra screens. **DEFER** — do not delete the class; constants are documentation.

---

## 3. Proven-dead files (PHASE B1 candidates)

Zero Dart importers, zero GoRoute, zero navigation. Feature screens above are **not** in this list.

| File | Why |
| --- | --- |
| `lib/features/tools/screens/dhikr_counter_screen.dart` | Unused duplicate of Tasbih |
| `lib/features/quran/presentation/bookmarks_screen.dart` | Unused wrapper |
| `lib/features/home/presentation/widgets/daily_progress_section.dart` | Home does not import it |
| `lib/features/home/presentation/widgets/error_empty_states.dart` | Zero importers |
| `lib/features/home/presentation/widgets/hadith_card.dart` | `HomeHadithCard` unused (Hadith tab has its own cards) |
| `lib/features/prayer/presentation/widgets/prayer_hero_card.dart` | PrayerTimesScreen does not import it |
| `lib/features/prayer/presentation/widgets/prayer_insight_cards.dart` | Zero importers |
| `lib/features/prayer/presentation/widgets/prayer_quick_action.dart` | Zero importers |
| `lib/features/prayer/presentation/widgets/prayer_timeline_card.dart` | Zero importers |

**KEEP despite zero filename importers (unsure / infrastructure / math):**  
`billing_service.dart`, `content_provenance.dart`, `content_validator.dart`, `contrast.dart`, `app_locales.dart`, `notification_reconcile.dart`, `observability.dart`, `offline_store.dart`, `sync_engine.dart`, `timezone_engine.dart`, `next_prayer_engine.dart`, `prayer_schedule_cache.dart`, `prayer_source.dart`, `quran_meta.dart`, `ayah_options_sheet.dart`, `reading_preferences_provider.dart`, `safe_context.dart`.

---

## 4. Backend gaps

| Item | Classification | Notes |
| --- | --- | --- |
| Bookmarks GET/POST/DELETE scoped `Bookmark.user_id == user.id` | KEEP | IDOR already filtered |
| Progress GET/POST scoped `user.id` | KEEP | |
| Settings GET/POST scoped `user.id` | KEEP | |
| Sync POST `merge_records(..., user.id)` | KEEP | |
| Users GET/DELETE `/me` via `current_user` | KEEP | |
| `/ai/ask` unauthenticated | KEEP | Required by `test_ask_does_not_require_auth` |
| Auth rate limit 60/60 + store reset | KEEP | Do not weaken |
| Health flags `*_production_ready` false | KEEP | Do not flip |
| CORS `allow_origins=*` | KEEP absent | Do not add `*` |
| JWT empty → `"dev-only-change-me"` | KEEP explicit dev-only; tighten production refuse | Tests set `JWT_SECRET=test-secret` |
| Unhandled exceptions / stack traces in JSON | DEFER→fix in B2 | FastAPI default debug off; add generic 500 without traceback |
| Request body size cap | MISSING → B2 | No Content-Length cap |
| Logging of `/ai/ask` query | KEEP none today | Do not add query logs |
| Billing `/status` `/verify` | STUB | `is_premium` false; store unconfigured |
| Client `isBackendEnabled` | KEEP false | |

---

## 5. RAG

| Item | Classification | Notes |
| --- | --- | --- |
| Empty retrieve → refuse (`no_retrieved_passage`) | KEEP | Do not loosen substring retrieve |
| `verified: False` always | KEEP | Never invent VERIFIED |
| Citations = `source` from retrieved items only | KEEP + tighten | Do not fabricate extra citations; drop empty sources without inventing labels |
| Client “qualified scholar” / fatwa copy in refuse + system prompt | STUB honesty leak | Strip in B3 |
| Actionish regex `open\|...\|settings\|qibla\|...` skips empty-retrieve refuse | BROKEN-ish | Tighten: question text must still refuse; commands only |
| Offline: connectivity none blocks before local retrieve | DEFER→B3 | Allow local retrieve/refuse offline |
| `debugPrint` of AI errors / retrieved sources | DEFER→B3 | Do not log prompts / Quran / Hadith |
| `isBackendEnabled` | KEEP false | |
| Client corpus on `/ai/ask` | KEEP for tests | Labels are client-provided, never marked verified |

---

## 6. Already good (do not “improve” by rewriting)

- Six-tab shell with Hadith kept.
- Quran/Hadith/Prayer stay free (no paywall on those tabs).
- Gold fill `#C6A15B` vs gold text `#6B542B`; forest `#123F36`; ivory backgrounds; danger `#B42318`.
- Recitation honest (not bundled). Tafsir unavailable without license.
- Continue-reading / daily ayah / surah reader as GoRouter siblings.
- IDOR filters on user-owned collections.
- RAG refuse on empty retrieve; `verified` never true.
- Rate limit 60 hits / 60 seconds.
- Health production flags false.
- No CORS `*`.
- Observability / Firebase / Sentry / Mixpanel not wired; consent default off.

---

## 7. Flutter / tests

| Item | Classification |
| --- | --- |
| Flutter SDK | MISSING |
| `flutter analyze` / `flutter test` / release builds | NOT RUN |
| Backend `test_phase3.py` … `test_phase15.py` | Re-run after PHASE B; do not delete tests |

---

## 8. PHASE B plan (only after this file exists)

- **B1:** Delete the nine proven-dead files in §3. Nothing else.
- **B2:** Body-size cap; generic 500 without stack traces; production JWT refuse if secret empty/insecure; keep 60/60, flags false, no CORS `*`; IDOR stays user-scoped.
- **B3:** Empty retrieve refuse; no invented citations; strip scholar/fatwa wording; no prompt/Quran/Hadith logs; tighter actionish bypass; offline local retrieve; `isBackendEnabled` stays false.
- **B4:** No hub restyle. No Home redesign. **Skip.**

---

**Verdict: NOT APPROVED**
