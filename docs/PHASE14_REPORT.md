# Phase 14 report — Family A UI/UX

**Branch:** `arena/01a049e4-qibra-ai`  
**Based on:** `d0e853f` (`phase13: accessibility and i18n`) + `docs/PHASE14_AUDIT.md`  
**Status:** **WIRED** for Family A tokens + Settings sheets + hub honesty. **Not** a new product identity. **Not PRODUCTION READY.**

Flutter analyze / `flutter test` / device / TalkBack / VoiceOver: **NOT RUN** (SDK not on PATH). Postgres/Redis: **NOT RUN**.

## What landed

1. **Tokens:** `AppTextStyles` no longer bake light `AppColors` on display/body (error style kept). `.gold` / `.goldBright` are gold TEXT `#6B542B`.
2. **Chrome:** `QibraAppBar` back icon flips with RTL `Directionality`. Six tabs **kept**. Portrait **kept**. No gen-l10n. No scaler clamp.
3. **Settings:** Language / font / Quran translation / Hadith language sheets persist via `localeProvider`, `readingPreferencesProvider`, `EditionResolver.allBundled()` (non-`ar`), `hadithLanguageProvider`. Guest chip only when guest. About title `goldText`. BETA uses danger `#B42318`.
4. **Home:** Hadith load failure uses `QibraStatus.error` (no silent shrink). Ask Qibra stays a compact card — **not** a new dashboard.
5. **Quran hub:** “View all surahs” uses `context.go('/quran/surahs')`.
6. **Onboarding / AI:** Retrieval-only, not a fatwa. Unused AI `_buildAppBar` status is no longer “Online”.
7. **Tools / duas / notifications:** leftover navy / purple / maroon / teal / pink identity hex swapped toward Family A. Overview heroes that used dark forest as a second gradient stop were corrected to card/canvas so ink stays readable. Notification toggle labels no longer paint `Colors.white` on ivory.
8. **Splash / auth overlays:** gold ShaderMask off Bismillah / wordmark / credit; particles 12; `Colors.white` 5% glass overlays on auth/onboarding/profile-setup replaced with ink alpha. Logo gold **fill** kept.
9. **A11y (cheap):** Back tooltips on bookmarks hub + hadith book; 48dp helper unchanged.
10. **Docs:** this report; `docs/DESIGN_SYSTEM.md` rewritten to Family A.

## Honesty (unchanged contracts)

- Quran / Hadith / tafsir / prayer / qibla / authenticity / user stats are never invented.
- Recitation not bundled. Tafsir unavailable unless licensed. Hadith missing author `"—"`.
- Unbundled editions (e.g. Hindi) stay honest misses.
- UI locale vs Quran translation vs Hadith language stay independent.
- No “100% Authentic” / “Islamic Scholar”.

## Not done / still mixed

- Custom `Scaffold` / `SliverAppBar` on duas, calendar, qibla, readers, inner tools — not converted to `QibraPage`.
- Qibla / mushaf / surah-night palettes left (high visual risk; math untouched).
- Auth still uses particles / pulse; social buttons remain **STUB**.
- Most IconButtons still unlabeled. `AppSemanticIconButton` / `AppBreakpoints` unused.
- `textSecondary` `#71807A` on ivory contrast **UNKNOWN** (not measured).
- Gold FILL still appears as some tool/icon accents (allowed as fill, not as body type).

## Tests

- Flutter: `test/phase14_test.dart`, `test/phase14_ui_test.dart` — gold TEXT `#6B542B`, 48dp, 3 locales — **NOT RUN**.
- Backend: `backend/tests/test_phase14.py` (Family A hex constants + existing `/progress` API). Pytest **205 passed** this phase (`/tmp/qibra-venv`).

## Out of scope (not done)

Home restyle-as-dashboard, drop any tab, landscape unlock, gen-l10n, scaler clamp, prayer/qibla/zakat/inheritance/RAG rewrite, IAP, analytics SDKs, claiming production-ready.
