# Phase 15 audit — Final product polish (read-only)

**Date:** 2026-08-31  
**Branch:** `arena/01a049e4-qibra-ai`  
**HEAD at audit start:** `b8aa3ed` (`phase14: world-class qibra ui ux`)  
**Working tree:** clean  
**Written before any Phase 15 source edits.**

**Verdict:** Family A is **WIRED** on hubs (`QibraPage` + `QibraColors.of`). The product is **not** one chrome: Search / Mushaf / Ayah Options / inner tools / auth still mix custom Scaffolds, leftover teal/red identity, gold FILL as type, silent shrinks, and English-only copy. Dark mode tokens exist; most custom hex screens stay light-locked. Flutter SDK **NOT RUN**.

Status: **FOUNDATION** (tokens) | **WIRED** (6-tab shell, Phase 13 locale, Phase 14 Settings sheets) | **not FUNCTIONAL** as one production UX | **not PRODUCTION READY**.

Labels: `PRESENT & WIRED` | `PLACEHOLDER/STUB` | `MISSING` | `BROKEN` | `EXTRA` | `NOT RUN` | `UNKNOWN`

Preserve Phase 4–14. Ivory `#FEFDF9` / canvas `#F5F3EC`, forest `#123F36`, sage `#2F6B5D`, gold FILL `#C6A15B`, gold TEXT `#6B542B`, ink `#19312C`, danger `#B42318`. Do **not** midnight+emerald. Do **not** gold-wash. Do **not** drop Hadith. Do **not** unlock landscape. Do **not** clamp `textScaler`. Do **not** enable gen-l10n. Do **not** rewrite prayer/qibla/RAG/billing/auth/sync.

---

## Environment

| Item | Status |
| --- | --- |
| Flutter / Dart SDK | MISSING / NOT RUN |
| `flutter analyze` / `flutter test` / device / TalkBack | NOT RUN |
| Portrait lock | PRESENT & WIRED (`AppSystemUI.setPortraitOnly`) |
| gen-l10n / `generate: true` | Absent (KEEP off) |
| Pytest | **205 passed** at Phase 14 (`/tmp/qibra-venv`) — not re-run this audit |
| Postgres / Redis | NOT RUN |

Architecture (KEEP): Flutter + Riverpod + GoRouter; FastAPI backend; homemade JWT; in-memory rate limit; Quran/Hadith JSON not Postgres.

---

## Design system inventory

| Item | File | Status |
| --- | --- | --- |
| `QibraColors` light/dark | `lib/core/design_system/qibra_colors.dart` | PRESENT & WIRED (~523 `of(`). Semantic getters: `surface`, `goldText`, `error`, `success`. `goldText`/`error` are **getters**, not const fields. |
| `AppColors` parallel | `app_colors.dart` | PRESENT; compile compatibility |
| `AppTextStyles` | `app_typography.dart` | PRESENT; colors **stripped** in Phase 14 except `inputError`. Dark still needs `copyWith(QibraColors)`. |
| `docs/DESIGN_SYSTEM.md` | Family A (Phase 14) | PRESENT |
| `QibraPage` / `QibraAppBar` / cards / chips | `qibra_ui.dart` | PRESENT on ~10 hubs. RTL back icon WIRED. |
| `QibraStatus` | `qibra_status.dart` | PRESENT; **one** call site (Home hadith error) |
| `AppBottomNav` | `app_bottom_nav.dart` | 6 tabs KEEP. Height **68** vs token 80. Labels `AppStrings`. |
| `AppSemanticIconButton` | `app_a11y.dart` | PRESENT, **zero** call sites |
| `AppBreakpoints` | `app_design_system.dart` | DEFINED, **unused** |
| Raw `Color(0x…)` | lib | **~709** vs **~523** `QibraColors.of` |
| IconButton vs tooltip | lib | **65** vs **16** |
| `AppStrings` | `app_strings.dart` | Chrome only (nav, settings, empty/error). Rest of UI English. **Partial locales.** |

Search chips: forest / sage / gold TEXT (KEEP). Gold FILL as body text is still BROKEN in tools + search highlight.

---

## Router / shell

- Splash, onboarding, auth, **mushaf**, **surah reader**, continue-reading, daily-ayah are **outside** the 6-tab `ShellRoute` (KEEP).
- `/quran/surahs`, `/quran/search`, `/quran/bookmarks` are **inside** the shell → tab bar still visible (intentional for search/list).
- Duplicate KEEP: `/tasbih` + `/tools/dhikr` (redirect), `/bookmarks` + `/quran/bookmarks`.
- Tafseer route `/quran/tafseer` always `TafseerScreen(surahNumber: 1)` — **BROKEN** query (does not pass ayah). Inner ayah sheet uses `Navigator.push` instead.

---

## Screen-by-screen

Format: FILE → COMPONENT → PROBLEM → SEVERITY → FIX  
Severity: P0 identity/contrast/honesty/compile | P1 consistency/a11y/states | P2 polish

### Auth / entry

| Screen | Identity | States | Notes |
| --- | --- | --- | --- |
| Splash | Family A + gold **fill** logo | Loading dots only | Particles 12. No `disableAnimations`. Tagline honest. |
| Onboarding | Mixed; ink-alpha overlays | UNKNOWN | Honesty copy Phase 14 KEEP |
| Login | `QibraPage` no bar | Error banner PRESENT | Particles + pulse EXTRA. Social **STUB** |
| Register / Forgot / OTP | Custom Scaffold | Error banners | Same leftover glass |
| Profile setup | Hex + ink overlays | SnackBars | Not Family A chrome |

Exact:

- `splash_screen.dart` → `_buildFloatingParticles` → no reduced-motion → P1 → skip painter when `MediaQuery.disableAnimations`.
- `login_screen.dart` → particles/pulse → EXTRA motion → P2 → leave unless cheap.
- `auth_social_buttons.dart` → Google/Apple → STUB labeled soon → KEEP honesty.

### Six tabs (KEEP all)

| Tab | File | Identity | Loading/empty/error | vs brief |
| --- | --- | --- | --- | --- |
| Home | `home_screen.dart` | Family A `QibraPage` | Hadith error `QibraStatus`; null hadith **shrinks** | Next prayer PRIMARY; **no current prayer**; no location line; no daily ayah (on Quran hub). 4 quick actions + Ask Qibra. Do **not** invent a dashboard. |
| Quran | `quran_screen.dart` | Family A | Daily ayah **error shrinks**; surah list empty PRESENT | Continue + ayah + chips KEEP |
| Prayer | `prayer_times_screen.dart` | Family A | Location empty honest `—` | Next highlighted; **current** not labeled on rows. Math KEEP |
| Hadith | `hadith_screen.dart` | Family A | Daily/featured empty PRESENT; **books error shrinks** | Author `"—"`. Search sheet English |
| AI | `ai_explain_screen.dart` | Family A + gold/sage gradients | Empty + listening | Subtitle honesty KEEP. `_buildAppBar` EXTRA unused. Mic/send 48dp |
| More | `more_screen.dart` | Family A | N/A list | KEEP hub IA |

Exact:

- `home_screen.dart` → filled prayer card → missing current prayer + location (without inventing city) → P1 → present `currentPrayerProvider` + `location.displayName` if not `UNKNOWN`.
- `home_screen.dart` → `_QuickAction` ×4 → 320dp label overflow UNKNOWN → P1 → `maxLines: 1` + ellipsis.
- `quran_screen.dart` → `dailyAyah.when(error: shrink)` → silent fail → P1 → `QibraStatus.error`.
- `hadith_screen.dart` → `books.when(error: shrink)` → P1 → `QibraStatus.error`.
- `hadith_screen.dart` → detail `IconButton` bookmark/copy unlabeled → P1 → tooltip.
- `ai_explain_screen.dart` → `_buildAppBar` dead → P2 EXTRA → delete only if unused (it is).
- `prayer_times_screen.dart` → `_PrayerRow` → current prayer not marked → P1 → `isCurrent` chip from `currentPrayerProvider` (presentation only).

### Quran reading

| Screen | Identity | Findings |
| --- | --- | --- |
| Surah list | Mixed hex + `QibraColors` | Custom Scaffold; `Colors.white` on some buttons; ALL-CAPS leftover possible |
| Surah reader | Mixed; night `#020A08` | KEEP reading night. Chrome leftover. |
| Mushaf | **Parchment** `#F5EEDC` / black night | KEEP paper. Chrome already `QibraColors.of` in several widgets. |
| Search | Family A colors + **glass blur** + ALL-CAPS “EXPLORE THE QURAN” | Chips forest/sage/goldText KEEP. Highlight uses **gold FILL** as type. `Colors.black` 0.12 shadow. 4-col topic grid overflow UNKNOWN at 320. `_CircleButton` no tooltip. Result ayah number on gold/forest gradient may fail contrast (`textPrimary` ink on forest). |
| Ayah options | Family A + **teal** `#14B8A6` Share | Recitation toast honest. Favorite inactive icon `onPrimary` on ivory card → **near-invisible** (P0). Translation/Tafsir both open `TafseerScreen` (duplicate). Bookmark local prefs ≠ bookmarks hub. |
| Tafseer | Mixed | Corpus STUB / honest unavailable KEEP. Route always surah 1. |
| Bookmarks hub | Material AppBar | Empty PRESENT. Duplicate route KEEP |

Exact:

- `ayah_options_sheet.dart` → Share `_actionButton` `Color(0xFF14B8A6)` → leftover teal → P0 → `colors.primarySoft`.
- `ayah_options_sheet.dart` → favorite inactive `colors.onPrimary` → contrast fail on ivory → P0 → `colors.textTertiary`.
- `quran_search_screen.dart` → header `EXPLORE THE QURAN` ALL-CAPS → P1 → sentence case, `goldText` or primary.
- `quran_search_screen.dart` → highlight `color: colors.accent` → gold FILL as type → P0 → `colors.goldText`.
- `quran_search_screen.dart` → result badge `colors.accent` as EN/AR type → P1 → goldText if gold, else primarySoft.
- `quran_search_screen.dart` → `Colors.black` shadow → P1 → `colors.primary` alpha.
- `quran_search_screen.dart` → `_CircleButton` unlabeled → P1 → tooltip Back.
- `mushaf_reader_screen.dart` → parchment `#F5EEDC` → KEEP reading surface (not identity chrome).
- `surah_reader_screen.dart` → night `#020A08` → KEEP.

### Prayer extras / Qibla

| Screen | Findings |
| --- | --- |
| Schedule / stats / tahajjud | Custom; leftover `#EF4444` |
| Mosque finder | `QibraEmptyState` PRESENT (not `QibraPage`) |
| Qibla | Dark compass painter KEEP math. `#EF4444` status color EXTRA vs danger token |

Exact:

- `qibla_screen.dart:547` → `Color(0xFFEF4444)` → P1 → `QibraColors.light.error` (visual only).
- `salah_schedule_screen.dart:1108`, `tahajjud_details_screen.dart:300,743` → same.

### Tools / duas / calendar / tasbih

Inner tools still custom heroes. Hajj leftover parchment `#F8F1E3` + `#2B1F00` (dark brown second stop can crush ink). Halal `_ => Color(0xFF6B7280)` grey. Ramadan/zakat/nikah use `colors.accent` as **Text** color (gold FILL as type) — P1 swap to `goldText` only on `Text`/`label` not icons.

Duas: Family A hex after Phase 14. Calendar selected `Colors.white`. Tasbih gold gradients KEEP as fill if not body type.

Do **not** rewrite zakat/inheritance formulas.

### Settings

| Screen | Status |
| --- | --- |
| Settings | Sheets persist (Phase 14). Guest gated. About `goldText`. Reciter honest. Help/Rate/Share STUB KEEP. |
| Notifications | Hardcoded Family A hex, not `QibraColors.of` → dark-mode **BROKEN**. Time picker still `ThemeData.dark()`. |
| User profile | `QibraPage` |

---

## Cross-cutting

### P0

1. Ayah Share teal `#14B8A6` (non-Family-A identity).
2. Ayah favorite inactive `onPrimary` on ivory (invisible).
3. Search match highlight gold FILL as text.
4. Gold FILL as type in ramadan/zakat/nikah/hajj labels (partial).
5. `textSecondary` `#71807A` on ivory AA **UNKNOWN** (not measured).

### P1

6. Dual chrome: 10 `QibraPage` vs ~35 custom Scaffolds.
7. `QibraStatus` unused except Home hadith.
8. Quran daily ayah / Hadith books silent shrink.
9. Home missing current prayer + location presentation.
10. ~49 IconButtons unlabeled; `AppSemanticIconButton` unused.
11. RTL: MaterialApp WIRED; most copy English; `CrossAxisAlignment.start` on app bars.
12. Dark mode: hubs via extension; hex screens light-locked.
13. Search 4-col grid / Home 4 actions at 320dp UNKNOWN overflow.
14. Nav height 68 vs token 80.
15. Splash/auth motion ignore `disableAnimations`.
16. Search ALL-CAPS eyebrow.
17. Leftover `#EF4444` in qibla/tahajjud/schedule.

### P2

18. AI `_buildAppBar` dead.
19. Emoji tips on search.
20. Nested `Navigator.push` beside GoRouter for ayah/tafsir.
21. Guest/social STUB honesty KEEP.
22. `AppBreakpoints` unused.
23. Tablet / landscape: landscape locked (KEEP). Tablet unused.

---

## Accessibility

| Item | Status |
| --- | --- |
| 48dp `AppA11y.minTapTarget` | PRESENT on `QibraAppBar` / some tools |
| Mass 48 restyle | Do **not** |
| textScaler clamp | Absent KEEP |
| TalkBack / focus | NOT RUN |
| Contrast gold fill as type | BROKEN where used as body |
| Decorative painters | Extra nodes UNKNOWN |

---

## i18n / RTL

`AppStrings` covers nav + a handful of chrome strings (en/ar/ur). **Do not** claim Arabic/Urdu UI is complete. **Do not** gen-l10n. **Do not** `_t()` Quran/Hadith. Independent UI vs Quran translation vs Hadith language KEEP.

---

## Responsive

Portrait only. `AppBreakpoints` unused. 6 tabs + FittedBox labels likely OK at 360; 320 UNKNOWN. Search topic `crossAxisCount: 4` is the highest overflow risk. Tablet: no two-pane. Landscape: locked KEEP.

---

## Motion / performance / privacy

Splash 7 controllers + particles. Auth pulse. Search BackdropFilter blur. Phase 12 deferred Quran/Hadith KEEP — do not parallel-decode books, do not defer Quran incorrectly.

No new analytics. Do not log GPS/email/tokens/Quran/Hadith/AI. Location on Home must show cached city or `UNKNOWN`, never invent, never raw coordinates.

---

## Contract risks

| Change | Class |
| --- | --- |
| Midnight identity / gold wash / drop tab / landscape / gen-l10n / scaler clamp | DANGEROUS STOP |
| Prayer/qibla/RAG/billing/auth/sync rewrite | DANGEROUS STOP |
| Home restyle-as-dashboard | STOP (Phase 14). Token + current/next line OK |
| Mushaf parchment / qibla painter structure | CAUTION (visual risk) |
| Hex → `QibraColors` / goldText / `QibraStatus` / tooltips / reduced-motion | SAFE |
| Add chrome strings to `AppStrings` without gen-l10n | SAFE, do not claim full translation |

---

## Implementation waves (SAFE only)

1. Tokens: teal/EF4444/gold-fill-as-type/search highlight/hajj dark stop.  
2. Shared: more `QibraStatus`; do not mass-convert Scaffolds.  
3. Shell: KEEP 6 tabs / 68 height (changing height = layout CAUTION).  
4. Home: current prayer + honest location line; ellipsis on quick actions. **Not** a new dashboard.  
5. Quran: search chrome/highlight/shadow/tooltip; daily ayah error status; ayah teal + contrast. Mushaf paper KEEP.  
6. Hadith: books error status; bookmark tooltips.  
7. Prayer/Qibla: current-row chip; EF4444 → error. Painter math KEEP.  
8. AI: delete unused `_buildAppBar` only. Honesty KEEP.  
9. Tools: hajj crush gradient; Text gold → goldText where cheap. Formulas KEEP.  
10. Settings: no architecture change. Notifications dark-lock DEFER (large hex file).  
11. A11y: search back tooltip; reduced-motion splash; no scaler clamp.  
12. Responsive: search topics 2-col under 360 via `LayoutBuilder`.  
13. Docs + tests (token assertions). Flutter analyze still NOT RUN if SDK missing.

**Intentionally NOT changed:** prayer math, qibla formula, RAG, billing, auth contracts, sync, notification scheduling logic, recitation (not bundled), tafsir corpus, landscape, gen-l10n, 6 tabs, mushaf parchment, Home IA (no extra widgets dump), social STUB.

---

**Stop here.** Implementation follows this brief only.
