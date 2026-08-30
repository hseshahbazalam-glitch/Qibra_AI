# Phase 15 report — Final product polish

**Branch:** `arena/01a049e4-qibra-ai`  
**Based on:** `b8aa3ed` (`phase14: world-class qibra ui ux`) + `docs/PHASE15_AUDIT.md`  
**Status:** **WIRED** polish on Family A chrome. **Not PRODUCTION READY.**

Flutter analyze / `flutter test` / device / TalkBack: **NOT RUN** (SDK not on PATH). Postgres/Redis: **NOT RUN**.

## Waves completed (SAFE only)

1. Tokens: ayah Share teal removed; leftover `#EF4444` → `QibraColors.light.error`; Hajj crushing `#2B1F00` gradient → card/canvas; gold FILL as type → `goldText` on Hajj captions/Arabic display; search highlight `goldText`.
2. Shared: `QibraStatus` on Quran daily-ayah error and Hadith collections error.
3. Shell: 6 tabs **kept**. Nav height 68 **kept**. Portrait **kept**.
4. Home: current prayer line from `currentPrayerProvider`; location label is cached name or `UNKNOWN` (never GPS). Quick-action ellipsis. **Not** a new dashboard.
5. Quran: Search sentence-case eyebrow, back tooltip, forest shadow, 2-col topics under 360dp, ayah number `onPrimary` on forest fill. Ayah favorite contrast fixed. Mushaf parchment **kept**.
6. Hadith: collections error status; bookmark/copy tooltips.
7. Prayer: “Now” chip from `currentPrayerProvider`. Qibla math **untouched**.
8. AI: honesty subtitle **kept**. Unused `_buildAppBar` left (P2).
9. Tools: Hajj overview readable; Halal grey → `textTertiary`. Formulas **untouched**.
10. Settings: no architecture change. Notifications still hex-locked (DEFER).
11. A11y: search/Hajj back tooltips; splash particles skip when `disableAnimations`. No scaler clamp.
12. Responsive: search topic grid 2/4 columns.

## Honesty (unchanged)

- Quran / Hadith / tafsir / prayer / qibla / authenticity / user stats never invented.
- Recitation not bundled. Tafsir unavailable unless licensed.
- UI locale vs Quran translation vs Hadith language independent.
- Arabic/Urdu chrome is **partial** (`AppStrings` only). Not fully translated.

## Intentionally untouched

Prayer calculation, qibla formula, RAG, billing, auth, sync, notification scheduling, recitation player, tafsir corpus, landscape, gen-l10n, 6 tabs, mushaf parchment, Home IA dump, social STUB, mass 48dp restyle, converting all Scaffolds to `QibraPage`.

## Tests

- Flutter: `test/phase15_test.dart`, `test/phase15_ui_test.dart` — **NOT RUN**.
- Backend pytest: **205 passed** this phase (`/tmp/qibra-venv`).

## Remaining risks

Custom chrome on duas/calendar/qibla/readers/inner tools; dark-mode hex screens; unlabeled IconButtons; `#71807A` AA UNKNOWN; tablet unused; Flutter analyze NOT RUN.
