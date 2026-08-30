# Phase 14 audit — Full UI/UX (read-only)

**Date:** 2026-08-31  
**Branch:** `arena/01a049e4-qibra-ai`  
**HEAD at audit start:** `d0e853f` (`phase13: accessibility and i18n`)  
**Written before any Phase 14 implementation.** No source modified in this pass.

**Verdict:** Family A tokens exist and the six-tab shell + several hubs already use `QibraPage` / `QibraColors`. The product is **not** a consistent premium Islamic super-app: leftover midnight/rainbow hex, gold-fill-as-text, dual typography (light tokens baked into `AppTextStyles`), custom Scaffolds vs shared chrome, and at least one **Settings** screen that does not compile on static read.

Status for this phase: **FOUNDATION** (tokens + some hubs) | **WIRED** (locale/delegates from Phase 13; not full-app copy) | **not FUNCTIONAL** as one visual system | **not PRODUCTION READY**.

Flutter SDK **NOT RUN**. Device / TalkBack / VoiceOver / screenshot review **NOT RUN**. Contrast ratios below are token-level, not measured on device.

Labels: `PRESENT & WIRED` | `PLACEHOLDER/STUB` | `MISSING` | `BROKEN` | `EXTRA` | `NOT RUN` | `UNKNOWN`

Preserve Phase 4–13. Ivory `#FEFDF9` / canvas `#F5F3EC`, forest `#123F36`, sage `#2F6B5D`, gold FILL `#C6A15B`, gold TEXT `#6B542B`, ink `#19312C`, danger `#B42318`. Do **not** switch to midnight+emerald. Do **not** gold-wash. Do **not** drop Hadith. Do **not** unlock landscape. Do **not** clamp `textScaler`. Do **not** enable gen-l10n. Do **not** translate Quran/Hadith source. Do **not** rewrite prayer/qibla/zakat/inheritance math.

---

## Method

- Inventory: `lib/core/router/app_router.dart`, every `*screen*.dart` under `lib/features`, shared widgets, design tokens.
- Compared to a **world-class premium Islamic super-app** bar (Quran.com / Muslim Pro / Tarteel class): one identity, readable Arabic, honest empty/error, 48dp targets, RTL chrome, calm motion, no leftover product skins.
- This tree is **not** that bar. Filename “world-class” in older docs is not a certificate.

---

## 1. Design tokens & identity

| Item | Status | Notes |
| --- | --- | --- |
| `QibraColors` light/dark ThemeExtension | PRESENT & WIRED | `ThemeData.extensions`; `QibraColors.of` used **486** times in features |
| Family A hex (ivory/forest/gold text/fill) | PRESENT | `qibra_colors.dart`, `app_colors.dart`, `contrast.dart` |
| `AppColors` + `AppEmerald` / `AppGold` | PRESENT | Parallel palette; token names preserved for compile |
| `AppTextStyles` / `GoogleFonts.inter` + `Amiri` | PRESENT | Colors **hardcoded to light `AppColors`**; dark mode text can stay ink-on-forest-night (**BROKEN** for dark) |
| `docs/DESIGN_SYSTEM.md` | BROKEN (stale) | Still “Black / Emerald / Gold / White”; not Family A |
| `AppSpacing` 4px grid | PRESENT | Not used everywhere; magic `20/32/120` padding common |
| `AppRadius` | PRESENT | Cards mix 12 / 16 / 20 / 24 |
| `AppShadows` forest-tinted | PRESENT | Many screens still use `Colors.black.withValues(alpha: 0.1–0.3)` |
| `AppBreakpoints` | PRESENT, unused | **MISSING** at call sites; portrait-only anyway |
| `AppAssets` | EXTRA / dead | Paths like `assets/images/logo.png` unused; real assets under `assets/images/logo/` |
| Lottie JSON in `assets/animations/` | EXTRA | Files exist; **no** `Lottie` usage in Dart |
| Gold FILL as body/title text | BROKEN (contract) | `AppArabicStyles.surahName` / `bismillah` use `AppColors.accent` (`#C6A15B`); Settings About title `colors.accent`; ShaderMask gold on splash “QIBRA AI” |
| Gold TEXT `#6B542B` | PRESENT | `Contrast.goldText`, `QibraColors.goldText`; used well in Settings section titles |
| Navy / midnight leftovers | BROKEN | See §4 |
| Rainbow / extra hues | BROKEN | BETA red `#EF4444`/`#DC2626`; dua heart `#FF6B6B`; tools purple `#2D1B69`; navy `#152E4A`; maroon `#3D1528`; silver `#C0C0C0`; grey `0xFF6B7280` |
| `textScaler` clamp | Absent (KEEP) | Do not add |
| Portrait lock | PRESENT & WIRED | `AppSystemUI.setPortraitOnly` (KEEP) |

**Contrast (token-level, NOT RUN on device):**

- Ink `#19312C` on ivory: intended AA (`Contrast.meetsAa` tested in Phase 13 Dart — **NOT RUN** here).
- Sage text `#71807A` (`textSecondary`) on `#FEFDF9` / `#F5F3EC`: **UNKNOWN**, likely **fails AA** for 14px body.
- Gold fill `#C6A15B` as text on ivory: **fails AA** (contract forbids as body text).
- Forest `#123F36` on ivory: intended AA.
- Dark mode: `AppTextStyles` still paint `AppColors.textPrimary` (ink) unless every `Text` overrides with `QibraColors` — mixed.

---

## 2. Shared components

| Component | File | Status |
| --- | --- | --- |
| `QibraAppBar` / `QibraPage` | `lib/shared/widgets/qibra_ui.dart` | PRESENT & WIRED on Home, Quran hub, Prayer hub, Hadith hub, AI, More, Tools hub, Settings, Profile, Mosque finder. **Unused** on most tools, readers, duas, calendar, qibla, tasbih, auth (except login wraps `QibraPage` without app bar) |
| `QibraCard` / `QibraSectionHeader` / `QibraChip` / `QibraIconButton` / `QibraSoftButton` / `QibraEmptyState` | same | PRESENT; empty-state copy still English |
| `QibraStatus` (loading/empty/error/offline) | `qibra_status.dart` | PRESENT, **unused** by screens — they `shrink()` on error or raw `CircularProgressIndicator` |
| `AppBottomNav` 6 tabs | `app_bottom_nav.dart` | PRESENT & WIRED; height **68** vs token `AppSpacing.bottomNavHeight` **80**; labels from `AppStrings` + Semantics (Phase 13) |
| `AppButton` | `shared/widgets/buttons/app_button.dart` | PRESENT; not the primary CTA on hubs |
| `AppSwitchTile` | `controls/app_switch_tile.dart` | PRESENT |
| `SafeImage` | `media/safe_image.dart` | PRESENT |
| `AppSemanticIconButton` | `app_a11y.dart` | PRESENT, **zero call sites** |
| Auth widgets | `auth_button.dart`, `auth_text_field.dart`, `auth_social_buttons.dart` | PRESENT; social **STUB** (disabled); leftover `Colors.white.withValues(alpha: 0.05–0.20)` |

---

## 3. Screen-by-screen

Chrome = app bar, padding, cards, type, empty/error. Identity = Family A vs leftover skin.

### 3.1 Shell / entry

| Screen | File | Identity | Chrome | Loading/empty/error | A11y / RTL | vs premium bar |
| --- | --- | --- | --- | --- | --- | --- |
| Splash | `splash_screen.dart` | Ivory + **gold wash** ShaderMask + **BETA red** | Custom particles/pattern, 3.5s delay | Loading dots only | Decorative painters extra nodes | Over-animated; credit/BETA compete with Bismillah |
| Onboarding | `onboarding_screen.dart` | Mixed; `Colors.white` overlays | Custom | UNKNOWN | NOT RUN | Glass leftover |
| Login | `login_screen.dart` | Ivory bg + gold glow logo | `QibraPage` no bar; particles; glass card | Error banner PRESENT | Guest path honest; social STUB | Pulse button + particles ≠ calm premium |
| Register / Forgot / OTP | matching auth files | Same glass + white overlays | Custom | Error banners | OTP fields | Same leftover dark-glass language |
| Profile setup | `profile_setup_screen.dart` | Heavy hex `#19312C` / white overlays | Custom | SnackBars | NOT RUN | Not Family A chrome |

### 3.2 Six tabs (KEEP all six)

| Tab | Screen | File | Identity | Notes |
| --- | --- | --- | --- | --- |
| Home | `HomeScreen` | `home_screen.dart` | Family A `QibraPage` | Greeting + hijri + next prayer + continue + hadith/dua + 4 quick actions. Hadith error **shrinks** (MISSING error). **Do not restyle as a new Home** in impl without an explicit later brief — polish tokens only. |
| Quran | `QuranScreen` | `quran_screen.dart` | Family A | Continue + ayah of day + Surah/Juz chips. “View all surahs” uses **MaterialPageRoute** not GoRouter (`EXTRA` nav). Error empty-state PRESENT. |
| Prayer | `PrayerTimesScreen` | `prayer_times_screen.dart` | Family A | Honest `—` / location empty. Method sheet PRESENT. Do not touch prayer math. |
| Hadith | `HadithScreen` | `hadith_screen.dart` | Family A | Empty/error PRESENT. Author `"—"`. Search/detail sheets. Bookmark `IconButton` unlabeled. |
| AI | `AIExplainScreen` | `ai_explain_screen.dart` | Family A colors, **gold+sage gradient wash** | Honesty subtitle “Retrieval only — not a fatwa” KEEP. Status **“Online”** in unused `_buildAppBar` is dishonest if revived. Listening uses `AvatarGlow`. Mic/send 48dp. English+emoji chips. `_buildAppBar` **dead**. |
| More | `MoreScreen` | `more_screen.dart` | Family A | Clean list. KEEP hub structure. |

### 3.3 Quran reading (siblings KEEP)

| Screen | File | Identity | Findings |
| --- | --- | --- | --- |
| Surah list | `surah_list_screen.dart` | Mixed | `Colors.black` shadows; `Colors.white` on buttons; empty-state PRESENT; huge file (~1361) |
| Surah reader | `surah_reader_screen.dart` | Mixed | Night `#020A08`; selected chip `Colors.white70`; loading forest hex not `QibraColors.of` |
| Mushaf | `mushaf_reader_screen.dart` | **EXTRA parchment** `#F5EEDC` / `Colors.black` night | Reading surface may stay distinct; chrome should still use Family A. 48dp on some controls |
| Search | `quran_search_screen.dart` | Mixed | Black shadow leftover; chips must stay forest/sage/goldText (KEEP contract) |
| Tafseer | `tafseer_screen.dart` | Mixed hex | Corpus **STUB** (unlicensed). Loading spinner PRESENT. Do not invent tafsir |
| Ayah sheet | `ayah_options_sheet.dart` | `Colors.black` barrier | OK for scrim; rest UNKNOWN |

### 3.4 Prayer extras

| Screen | File | Findings |
| --- | --- | --- |
| Schedule | `salah_schedule_screen.dart` | Custom Scaffold; `Colors.black` 0.3; Arabic RTL on names KEEP |
| Statistics | `prayer_statistics_screen.dart` | Custom; progress bars |
| Tahajjud | `tahajjud_details_screen.dart` | Custom; Arabic RTL |
| Mosque finder | `mosque_finder_screen.dart` | `QibraPage` + `QibraEmptyState` PRESENT |
| Qibla | `qibla_screen.dart` | **Dark compass painter** (`Colors.black`, white ticks). Do **not** rewrite formula. Chrome/hex leftover vs Family A |

### 3.5 Hadith book / tasbih / duas / calendar / bookmarks

| Screen | File | Findings |
| --- | --- | --- |
| Hadith book | `hadith_book_screen.dart` | Custom; `Colors.redAccent` error icon **EXTRA** |
| Tasbih | `tasbih_screen.dart` | Custom; gold+`#B8860B` gradients; 48dp on some controls; Arabic RTL |
| Duas home/list/detail | `duas_*.dart` | SliverAppBar (not `QibraPage`); emoji icons; favorite **pink** `#FF6B6B`; `Icons.verified_rounded` on references may over-claim grade — honesty risk |
| Calendar | `islamic_calendar_screen.dart` | SliverAppBar; `Colors.black` 0.3; selected day `Colors.white` |
| Bookmarks hub | `bookmarks_hub_screen.dart` | Material `AppBar`+`TabBar` not `QibraPage`; empty-states PRESENT; unlabeled IconButtons; opens reader via `Navigator.push` |

### 3.6 Settings / profile / notifications

| Screen | File | Findings |
| --- | --- | --- |
| Settings | `settings_screen.dart` | **BROKEN (static):** `_showLanguageSheet(context, ref)` but method is `(BuildContext context)` only; **MISSING** `_showFontSizeSheet`, `_showQuranTranslationSheet`, `_showHadithLanguageSheet` (called, not defined). Language sheet does **not** write `localeProvider` (snackbar only). Guest badge always shown. About title uses **gold fill**. BETA red. Section titles correctly `goldText`. |
| User profile | `user_profile_screen.dart` | `QibraPage` |
| Notifications | `notification_settings_screen.dart` | **Navy leftover** `#1E2535` dividers, `#1A1A2E` fill, hardcoded ivory/forest hex instead of `QibraColors.of` |
| Reciter row | Settings | Honest “Recitation not bundled” KEEP |

### 3.7 Tools (KEEP all routes; do not restyle hub list structure)

Hub `tools_hub_screen.dart` is Family A `QibraPage` — **KEEP**. Inner tools are a **second product skin** (ALL-CAPS `letterSpacing: 2`, w900, rainbow heroes):

| Screen | Leftover identity |
| --- | --- |
| Hajj / Umrah / Ramadan | `#F8F1E3` + `#2B1F00` / `#152E4A` |
| Nikah | `#3D1528` maroon |
| Asma / Habits / Inheritance | `#2D1B69` purple |
| Sadaqah | `#1A3D38` / `#2D8F88` teal |
| Zakat | silver `#C0C0C0`; 48dp on some steppers |
| Halal | `Colors.red` / `Colors.black` overlays; grey `#6B7280` |
| Names | Custom; Arabic RTL on names KEEP |

Do **not** rewrite zakat/inheritance formulas. Visual-only token swap is the safe impl.

### 3.8 Dead / unused UI

| Item | Status |
| --- | --- |
| AI `_buildAppBar` | EXTRA (unreferenced) |
| `QibraStatus` | UNUSED |
| `AppSemanticIconButton` | UNUSED |
| `AppBreakpoints` | UNUSED |
| `AppAssets` | UNUSED |
| Lottie files | UNUSED |
| Social/biometric buttons | STUB (disabled, labeled coming soon) — KEEP visible honesty |

---

## 4. Cross-cutting findings (P0 / P1 / P2)

### P0 — identity, contrast, compile, honesty

1. **Settings sheets BROKEN** (`settings_screen.dart`): extra `ref` arg; missing font/Quran/Hadith language sheet methods. Locale picker does not persist. **Flutter analyze NOT RUN**; this is source-read.
2. **Gold FILL as text** (`#C6A15B`) in Arabic display styles, splash name, Settings About, several tool accents used as type.
3. **Leftover midnight/rainbow** in notifications + tools + splash BETA + dua hearts — violates Family A and prior “navy not identity”.
4. **`AppTextStyles` light-locked** — dark theme cannot be premium until styles take `QibraColors` or `ColorScheme`.
5. **Secondary text `#71807A`** likely below AA on ivory for body (UNKNOWN until measured; treat as P0 if measured fail).

### P1 — consistency, a11y, states, RTL chrome

6. Two chromes: `QibraPage` hubs vs 30+ custom `Scaffold`/`SliverAppBar` (duas, calendar, qibla, readers, tools).
7. **`QibraStatus` unused**; errors often `SizedBox.shrink()` (Home hadith, Quran daily ayah).
8. **~65 `IconButton`s**, **13 tooltips**, **3 `Semantics(`** in app code (nav + a few). `AppSemanticIconButton` unused.
9. **RTL:** MaterialApp locale/delegates **WIRED** (Phase 13). Chrome still English; many `CrossAxisAlignment.start` / hardcoded LTR. Arabic *source* correctly `TextDirection.rtl` in readers — KEEP. Do not `_t()` ayah/hadith.
10. **Responsive:** `AppBreakpoints` unused; 6 tabs + FittedBox on ~320px **UNKNOWN** overflow; landscape locked (KEEP).
11. **Mushaf/Qibla/Surah night** are a third palette (parchment/black).
12. **Auth/splash motion:** multi-controller particles, elastic logo, repeating pulse — no `MediaQuery.disableAnimations` / reduced-motion.
13. **Google Fonts runtime** (`google_fonts`) — offline Arabic/Latin **UNKNOWN**.
14. **AI** gold-sage gradients, “Online”, emoji suggestion chips, unused app bar.
15. **Nav height 68 vs token 80.**
16. **Quran “View all surahs”** and bookmarks/duas use `Navigator.push` beside GoRouter siblings.

### P2 — polish

17. Stale `DESIGN_SYSTEM.md`.
18. Dead `AppAssets` / unused Lottie.
19. Emoji-as-icon (duas grid, AI chips, habits).
20. Guest badge on Settings even when named user.
21. Help / Rate / Share STUB (KEEP honest).
22. Nested scroll + `bottom: 120` padding guessing tab overlap.
23. ShaderMask gold on type (splash, login Sign Up) = gold wash.

---

## 5. Accessibility (extends Phase 13)

| Item | Status |
| --- | --- |
| `AppA11y.minTapTarget` 48 | PRESENT; applied on `QibraAppBar`, some zakat/inheritance/tasbih/mushaf |
| Mass 48dp restyle | **Do not** (layout redesign). Prefer helper on icon buttons only |
| `textScaler` | Not clamped (KEEP) |
| TalkBack / VoiceOver | NOT RUN |
| Focus order / keyboard | NOT RUN |
| Decorative CustomPaint (splash, qibla, particles) | Extra semantics UNKNOWN |
| Contrast gold text vs fill | Token exists; fill still used as type |

---

## 6. i18n / RTL (extends Phase 13)

| Item | Status |
| --- | --- |
| `flutter_localizations` + `AppStringsScope` | PRESENT & WIRED (`d0e853f`) |
| gen-l10n / `generate: true` | Absent (KEEP off) |
| Nav 6 labels | WIRED via `AppStrings` |
| Rest of UI copy | English hardcoded — translating all copy is **out of scope** unless a later brief; do not gen-l10n |
| UI vs Quran translation vs Hadith language | Independent (KEEP) |
| Settings language sheet | BROKEN (does not set locale) |
| Hindi / unbundled | Honest miss (KEEP) |

---

## 7. Motion, hierarchy, loading

| Item | Status |
| --- | --- |
| Splash 3.5s + 7 controllers | EXTRA motion vs premium calm |
| Auth particles + button pulse | EXTRA |
| AI typing dots | PRESENT, appropriate |
| Shimmer tokens | DEFINED, unused |
| Hierarchy | Hubs: forest filled card = primary. Tools: competing heroes. Splash: BETA/credit fight Bismillah |
| Loading | Spinners; almost no skeleton |
| Empty | `QibraEmptyState` on some hubs only |
| Error | Often silent shrink |

---

## 8. Contract risks (STOP vs safe)

| Change | Risk |
| --- | --- |
| Midnight + emerald / Design System 2.0 dark identity | **STOP** |
| Gold wash / gold fill as body text | **STOP** |
| Drop Hadith or any of 6 tabs | **STOP** |
| Unlock landscape | **STOP** |
| Clamp `textScaler` | **STOP** |
| gen-l10n / `generate: true` | **STOP** |
| Translate Quran/Hadith JSON via `_t()` | **STOP** |
| Rewrite prayer / qibla / zakat / inheritance / RAG | **STOP** |
| Restyle Home into a new dashboard | **STOP** unless a later explicit brief; token-only OK |
| Restyle More/Tools **hub lists** into new IA | **STOP** |
| Enable `isBackendEnabled`, IAP, analytics SDKs | **STOP** (other phases) |
| Replace leftover hex with `QibraColors.of` | Safe |
| Fix Settings sheets to existing providers | Safe (functional + UI) |
| Tooltips on IconButtons / use `AppSemanticIconButton` | Safe |
| Point `AppTextStyles` color through theme/`QibraColors` | Safe if no new hex |
| Use `QibraStatus` instead of shrink | Safe |
| Mushaf parchment keep as reading paper, chrome to Family A | Safe |
| Qibla painter colors to forest/ivory **without** changing math | Safe, high visual risk — P1 not first commit |

---

## 9. Safe implementation plan (do not execute in this pass)

**Goal of later Phase 14 impl:** one Family A chrome. Not a new app. Not production-ready claim.

1. **Compile/honesty first:** restore Settings language/font/Quran/Hadith sheets using existing `localeProvider` / `readingPreferencesProvider` / `hadithLanguageProvider`. No ALL-CAPS gold fill. `QibraColors.of`. Persist locale.
2. **Token sweep (no layout):** replace navy/purple/maroon/teal/BETA-red-as-identity/pink hearts with forest/sage/danger/goldText. Search chips stay forest/sage/goldText. No new hex.
3. **Typography:** `AppTextStyles` must not bake light `AppColors`; `copyWith(color: QibraColors.of(context).…)` or theme `TextTheme`. Gold TEXT for captions; ink/forest for body; gold FILL for icons/borders/fills only.
4. **States:** wire `QibraStatus` on hub `when(error/loading/empty)` instead of shrink. Do not invent content.
5. **A11y (no mass padding):** tooltip/`AppSemanticIconButton` on existing IconButtons; keep 48 helper. Do not clamp scaler.
6. **Chrome only where cheap:** Bookmarks AppBar → `QibraAppBar` colors; leave Mushaf/Qibla/Surah reader structure. Do not restyle Home/More/Tools hub IA.
7. **Auth/splash:** drop `Colors.white` 5% overlays; reduce (don’t invent) particle intensity; keep guest + disabled social honesty; no gold wash on wordmarks.
8. **RTL chrome:** rely on `Directionality`; don’t hardcode English layout mirrors; don’t translate scripture.
9. **Tests:** token tests (no navy identity hex in tools/notifications if swept); gold text `#6B542B`; Settings locale write; no `generate: true`. Flutter analyze **NOT RUN** until SDK present.
10. **Docs:** rewrite `DESIGN_SYSTEM.md` to Family A after impl — not before.

**Out of scope for Phase 14 impl:** landscape, gen-l10n, bundling recitation, tafsir corpus, IAP, analytics, prayer math, RAG, Home redesign, dropping tabs, claiming 90% or production-ready.

---

## 10. Privacy / performance (UI-only)

No new analytics. No logging GPS/email/tokens/Quran/Hadith/AI. No extra network for UI except existing `google_fonts` (already a risk). Do not add font CDN packages. Particle/splash animation cost **UNKNOWN** (NOT RUN).

---

## 11. Flutter / device

| Item | Status |
| --- | --- |
| Flutter SDK | MISSING / NOT RUN |
| `flutter analyze` / `flutter test` | NOT RUN |
| Visual QA / RTL device / TalkBack | NOT RUN |
| Backend pytest | Not part of this UI audit |

---

**Stop here.** No implementation until this audit is accepted as the Phase 14 brief.
