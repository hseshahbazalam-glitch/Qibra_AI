git add docs/AI_HANDOFF.md
git commit -m "docs: update AI_HANDOFF.md to v3.0 with complete Steps 1-15.3 state"
# QIBRA AI — COMPLETE AI HANDOFF DOCUMENT

**Version:** 3.0 — Final Polished  
**Last Updated:** End of Step 15.3 (Forgot Password Screen complete)  
**Status:** Phase 1 Foundation — 15.3 of 17 steps complete  

---

## ⚠️ MOST CRITICAL RULE

> This is an **EXISTING PROJECT**.  
> **NEVER create a new project.**  
> **Continue ONLY from this existing codebase.**  
> **Read this entire file BEFORE writing a single line of code.**

---

## SECTION 1 — PROJECT IDENTITY

| Field | Value |
|---|---|
| **App Name** | QIBRA AI |
| **Full Name** | QIBRA AI — Islamic Super App |
| **Framework** | Flutter (Dart 3.3+) |
| **Package Name** | ai.qibra.app |
| **Version** | 1.0.0+1 |
| **Current Phase** | PHASE 1 — FOUNDATION |
| **Theme** | Dark Emerald (#00A86B) + Royal Gold (#D4AF37) |
| **State Management** | Riverpod ^2.5.1 |
| **Navigation** | GoRouter ^14.2.7 |
| **DI** | GetIt ^7.7.0 |
| **HTTP** | Dio ^5.4.3+1 |
| **Fonts** | Poppins (English) + Amiri (Arabic) via google_fonts |
| **Developer** | QIBRA Technologies |
| **Support** | support@qibra.ai |

---

## SECTION 2 — NON-NEGOTIABLE RULES

### Development Rules
1. **NEVER create a new project** — continue from existing only
2. **NEVER break existing working code**
3. **NEVER redesign completed modules** — they are production-ready
4. **NEVER use placeholders, TODO, or demo code**
5. Every code must be **production-ready**
6. Handle only **ONE FILE at a time**
7. Wait for user confirmation after every file
8. Build in the **EXACT order** defined in Section 4
9. **DO NOT start Phase 2 features** (Quran, Prayer, Hadith, AI) until Phase 1 complete

### Teaching Rules
10. **Explain everything in simple Hinglish** (Hindi + English mix)
11. **Never skip explanations** — teach every concept
12. **Teach like the user is a complete beginner**
13. **Explain every technical term simply**

### Code Quality Rules
14. Use `withValues(alpha:)` NOT `withOpacity()` — Flutter 3.27+ compatibility
15. All enums use `abstract final class` pattern for constants
16. `ConsumerWidget` for Riverpod-aware stateless widgets
17. `ConsumerStatefulWidget` for Riverpod-aware stateful widgets
18. Dispose all controllers and focus nodes in `dispose()`
19. Check `mounted` before `setState` after async operations
20. Always use `AppSpacing.md` etc., NEVER hardcode values like `16.0`

---

## SECTION 3 — APP CONCEPT

QIBRA AI is a premium Islamic Super App containing:

| Feature | Description | Status |
|---|---|---|
| Quran | Full Arabic Quran with translation, audio, bookmarks | ⏳ Phase 2 |
| Prayer Times | GPS-based accurate prayer times | ⏳ Phase 2 |
| Qibla | Compass-based Qibla direction | ⏳ Phase 2 |
| Hadith | Major hadith collections | ⏳ Phase 2 |
| AI Chat | Islamic AI assistant | ⏳ Phase 2 |
| Dua | Duas by category | ⏳ Phase 2 |
| Tasbih | Digital tasbih counter | ⏳ Phase 2 |
| Islamic Calendar | Hijri calendar + events | ⏳ Phase 2 |

> **DO NOT build any of the above features until PHASE 1 FOUNDATION is 100% complete.**

---

## SECTION 4 — OFFICIAL BUILD ORDER (PHASE 1)

```
PHASE 1 — FOUNDATION

Step 01 ✅ Premium Design System
Step 02 ✅ Color System
Step 03 ✅ Typography System
Step 04 ✅ Theme System
Step 05 ✅ App Constants
Step 06 ✅ Assets Structure
Step 07 ✅ Reusable Buttons
Step 08 ✅ Reusable Cards
Step 09 ✅ Reusable Text Fields
Step 10 ✅ App Router (GoRouter)
Step 11 ✅ Riverpod Setup (4 sub-steps complete)
Step 12 ✅ Dependency Injection (3 sub-steps complete)
Step 13 ✅ Splash Screen
Step 14 ✅ Onboarding Screen
Step 15 🔄 Authentication (3 of 5 sub-steps complete)
      ✅ 15.1 Login Screen
      ✅ 15.2 Register Screen
      ✅ 15.3 Forgot Password Screen
      ❌ 15.4 Verify OTP Screen         ← NEXT FILE
      ❌ 15.5 Router Update (integrate all 4 auth screens)
Step 16 ⏳ Bottom Navigation (real implementation)
Step 17 ⏳ Home Dashboard

Legend:
✅ = Complete
🔄 = In Progress
⏳ = Pending
❌ = Not Yet Created
```

---

## SECTION 5 — ALL FILES CREATED (22 files)

### Core — Design System (4 files)

```
lib/core/design_system/app_design_system.dart   ✅
lib/core/design_system/app_colors.dart          ✅
lib/core/design_system/app_typography.dart      ✅
lib/core/design_system/app_theme.dart           ✅
```

### Core — Constants (2 files)

```
lib/core/constants/app_constants.dart           ✅
lib/core/constants/app_assets_check.dart        ✅
```

### Core — Providers (3 files)

```
lib/core/providers/app_providers.dart           ✅
lib/core/providers/auth_provider.dart           ✅
lib/core/providers/theme_provider.dart          ✅
```

### Core — Network & Services (2 files)

```
lib/core/network/dio_client.dart                ✅
lib/core/services/api_service.dart              ✅
```

### Core — DI & Router (2 files)

```
lib/core/di/service_locator.dart                ✅
lib/core/router/app_router.dart                 ✅
```

### Shared — Reusable Widgets (3 files)

```
lib/shared/widgets/buttons/app_button.dart      ✅
lib/shared/widgets/cards/app_card.dart          ✅
lib/shared/widgets/inputs/app_text_field.dart   ✅
```

### Features (6 files)

```
lib/features/splash/presentation/splash_screen.dart               ✅
lib/features/onboarding/presentation/onboarding_screen.dart       ✅
lib/features/auth/presentation/login_screen.dart                  ✅
lib/features/auth/presentation/register_screen.dart               ✅
lib/features/auth/presentation/forgot_password_screen.dart        ✅
lib/features/auth/presentation/verify_otp_screen.dart             ❌ NEXT
```

### Entry Point & Config

```
lib/main.dart                                   ✅
pubspec.yaml                                    ✅
test/widget_test.dart                           ✅
ios/Runner/Info.plist                           ✅
docs/AI_HANDOFF.md                              ✅ (this file)
```

---

## SECTION 6 — WHAT EACH FILE CONTAINS

### `app_design_system.dart`
- `AppSpacing` — spacing tokens (xs2 to xl9)
- `AppRadius` — border radius tokens
- `AppElevation` & `AppShadows` — shadow presets (goldGlow, emeraldGlow)
- `AppDurations` & `AppCurves` — animation tokens
- `AppIconSizes` — icon size scale
- `AppBreakpoints` — responsive breakpoints
- `AppGradients` — gradient presets (emerald, gold, splash, premium)
- `AppBorders` — border styles
- `AppOpacity` — opacity constants
- `AppAssets` — asset path constants
- `AppZIndex` — layer ordering

### `app_colors.dart`
- `AppEmerald` — 9-shade emerald palette (s50 to s900)
- `AppGold` — 9-shade royal gold palette (s50 to s900)
- `AppNeutral` — cool-tinted gray scale
- `AppSemanticColors` — success, error, warning, info
- `AppSurface` — dark surface hierarchy (background, card, elevated, high, highest)
- `AppTextColors` — text color hierarchy
- `AppIconColors` — icon colors
- `AppBorderColors` — border colors
- `AppColors` — main unified access class

### `app_typography.dart`
- `AppFontFamily` — Poppins + Amiri
- `AppFontWeight` — 100 to 900
- `AppFontSize` — complete type scale
- `AppLineHeight` & `AppLetterSpacing`
- `AppTextStyles` — 30+ English text presets
- `AppArabicStyles` — Quran, Hadith, Bismillah styles
- `TextStyleExtension` — chainable modifiers (.gold, .bold, .emerald)
- `AppTextTheme` — Material TextTheme integration

### `app_theme.dart`
- `AppTheme.dark` — complete dark ThemeData
- M3 ColorScheme, AppBar, Card, ElevatedButton, OutlinedButton, TextButton
- FloatingActionButton, InputDecoration, Dialog, BottomSheet
- SnackBar, Chip, Divider, ListTile, Switch, Checkbox, Radio
- Slider, ProgressIndicator, TabBar, Tooltip, PopupMenu
- Drawer, Badge, SearchBar themes
- `AppSystemUI` — status bar + orientation helpers

### `app_constants.dart`
- `AppInfo` — name, version, URLs, contact
- `AppApi` — base URLs, all endpoint constants, timeouts
- `AppStorageKeys` — SharedPreferences keys
- `AppPagination` — page sizes
- `AppIslamicConstants` — Quran (114 surahs, 6236 ayahs), prayer names, Hijri months, common duas
- `AppValidation` — regex patterns, length limits, error messages
- `AppCacheDuration` — cache timeouts per feature
- `AppFeatureFlags` — enable/disable features
- `AppUIConstants` — common UI sizes
- `AppLanguages` — en, ar, ur
- `AppRoutes` — all route name constants

### `app_providers.dart`
- `sharedPreferencesProvider` (FutureProvider)
- `secureStorageProvider` (Provider)
- `packageInfoProvider` (FutureProvider)
- `connectivityProvider` (StreamProvider)
- `isOnlineProvider` (Provider<bool>)
- `appInitializationProvider` (FutureProvider)
- `appLifecycleProvider` (StateProvider)
- `AppInitState` and `AppLifecycleStatus` models

### `auth_provider.dart`
- `AuthStatus` enum (initial, loading, authenticated, unauthenticated)
- `AppUser` immutable model (id, email, name, avatar, phone, etc.)
- `AuthState` model with copyWith
- `AuthNotifier` — login, register, logout, refreshToken methods
- `authProvider` (StateNotifierProvider)
- Convenience providers: `isAuthenticatedProvider`, `currentUserProvider`, `authLoadingProvider`, `authErrorProvider`, `userDisplayNameProvider`, `isPremiumUserProvider`

### `theme_provider.dart`
- `AppThemeMode` enum (system, light, dark) with helpers
- `ThemeNotifier` — theme with SharedPreferences persistence
- `LocaleNotifier` — language with RTL support
- `OnboardingNotifier` — onboarding completion tracking
- `themeProvider`, `localeProvider`, `onboardingProvider`
- `flutterThemeModeProvider`, `isDarkModeProvider`, `currentLanguageProvider`, `isRTLProvider`
- `_DummyPrefs` — fallback for async loading

### `dio_client.dart`
- `DioClient` class with baseUrl and timeouts
- Auth interceptor (auto-inject Bearer token)
- Logging interceptor (debug mode)
- Error interceptor (auto-logout on 401)
- HTTP methods: get, post, put, patch, delete
- `ApiException` custom exception
- `ApiExceptionType` enum

### `api_service.dart`
- `ApiService` wrapping DioClient
- 40+ endpoint methods across all features:
  - Auth: login, register, logout, refresh, OTP, social
  - User: profile, update, password, delete, avatar upload
  - Prayer: times, qibla, nearby mosques
  - Quran: surahs, ayahs, search, audio, bookmarks
  - Hadith: collections, books, search, daily
  - AI Chat: send message, history, Islamic questions
  - Dua: categories, list, favorites
  - Calendar: Hijri, Islamic events, Ramadan
  - Notifications: list, mark read, FCM
  - Tasbih: save, history

### `service_locator.dart`
- `ServiceLocator.init()` — GetIt initialization
- `sl` global instance
- Registered: SharedPreferences, FlutterSecureStorage, DioClient, ApiService
- Convenience accessors: prefs, secureStorage, dioClient, apiService

### `app_router.dart`
- `routerProvider` (Provider<GoRouter>)
- `_RouterRefreshNotifier` — auth state listener
- Redirect logic (auth guard, onboarding check)
- Routes: splash, onboarding, login, register, forgot-password, verify-otp
- ShellRoute with bottom nav (home, quran, prayer, hadith, ai-chat, profile, settings)
- `_ShellScaffold`, `_AppBottomNavBar`, `_NavItem` widgets
- Placeholder screens: `_LoginPlaceholder`, `_RegisterPlaceholder`, `_HomePlaceholder`, etc.
- Real screens integrated: `SplashScreen`, `OnboardingScreen`

### `app_button.dart` (Reusable Buttons)
- `AppButtonSize` enum (small, medium, large)
- `AppPrimaryButton` — Emerald gradient with press animation
- `AppSecondaryButton` — Transparent with emerald border
- `AppGoldButton` — Royal gold gradient with glow
- `AppTextBtn` — Text only with gold/emerald variants
- `AppIconBtn` — Circular with badge, outlined, filled variants
- `AppSocialButton` — Google and Apple sign-in
- `AppLoadingButton` — Auto async loading management
- All with HapticFeedback and scale animations

### `app_card.dart` (Reusable Cards)
- `AppCard` — Standard dark card with optional tap
- `AppGradientCard` — Emerald/Gold gradient cards
- `AppFeatureCard` — Islamic feature grid cards with badges
- `AppInfoCard` — Stats/info display
- `AppPrayerCard` — Prayer time with active state
- `AppListCard` — List item with InkWell ripple
- `AppQuranCard` — Surah list with bookmarks
- `AppHadithCard` — Hadith with Arabic text
- `AppShimmerCard` — Skeleton loading animation
- `AppShimmerList` — Multiple shimmer items

### `app_text_field.dart` (Reusable Inputs)
- `AppTextField` — Standard input with focus animation
- `AppPasswordField` — Password with show/hide toggle
- `AppSearchField` — Search with clear button
- `AppOtpField` — 6-digit OTP with auto-advance
- `AppTextArea` — Multi-line with char counter
- `AppDropdownField` — Dropdown selection
- All with error/success states, validation, RTL support

### `splash_screen.dart`
- Multiple animations (logo, text, bismillah, loading dots)
- Gold gradient logo with mosque icon
- ShaderMask for gradient text/icons
- Bismillah with Arabic + English
- Custom animated loading dots (wave effect)
- Rotating Islamic pattern background
- Version info and copyright
- Auto-navigation based on auth state (3 second delay)

### `onboarding_screen.dart`
- 4-slide PageView experience
- Multi-layered animated icon containers
- Radial gradient backgrounds per slide
- Arabic text badges with English translations
- Animated page indicators (expand for active)
- Skip button in top bar
- Previous/Next navigation
- Gold "Get Started" button on last slide
- HapticFeedback on page changes
- Auto-mark onboarding complete via provider

### `login_screen.dart`
- Email + password fields with validation
- Form validation via GlobalKey
- Riverpod authProvider integration
- Remember me checkbox
- Forgot password navigation
- Google + Apple social auth buttons
- Error banner with dismiss
- Loading states
- Focus node chaining
- Register link at bottom

### `register_screen.dart`
- 4 form fields (name, email, password, confirm)
- Real-time password strength indicator (5 levels)
- Color-coded progress bar
- Terms & Conditions checkbox with RichText
- Form validation
- Auto-navigation between fields
- Auto-navigate to OTP verification on success

### `forgot_password_screen.dart`
- 2-state UI (form + success)
- AnimatedSwitcher smooth transition
- Email validation
- Simulated API call
- Success state with sent email display
- Numbered instruction list
- Warning banner for link expiration
- Open email + Resend link buttons

### `main.dart`
- Entry point with ProviderScope
- ServiceLocator.init() before runApp
- QibraApp as ConsumerWidget
- Uses routerProvider for navigation
- Uses flutterThemeModeProvider for theme
- Console boot test
- Asset verification in debug mode

---

## SECTION 7 — CURRENT STEP STATUS

### ✅ COMPLETED
- Steps 1 through 14 (100% complete)
- Step 15.1 Login Screen
- Step 15.2 Register Screen
- Step 15.3 Forgot Password Screen

### ❌ NOT DONE — IMMEDIATE NEXT WORK

**Step 15.4** — Create `verify_otp_screen.dart`

**Location:** `lib/features/auth/presentation/verify_otp_screen.dart`

**Must contain:**
- 6-digit OTP input using existing `AppOtpField` component (from Step 9)
- Timer countdown for resend (60 seconds)
- Auto-submit when all 6 digits entered
- Resend OTP button (enabled after timer expires)
- Email display showing where OTP was sent
- Error state handling
- Loading state with spinner
- Success → auto-navigate to home
- Riverpod auth integration
- Premium Islamic design (Dark Emerald + Royal Gold)
- Uses `AppTextStyles`, `AppColors`, `AppSpacing`, `AppRadius` from design system
- Uses `AppPrimaryButton`, `AppSecondaryButton`, `AppTextBtn` from reusable widgets

**Step 15.5** — After OTP screen, update `app_router.dart`:
- Replace `_LoginPlaceholder` with `LoginScreen`
- Replace `_RegisterPlaceholder` with `RegisterScreen`
- Replace forgot-password `_ErrorScreen` with `ForgotPasswordScreen`
- Replace verify-otp `_ErrorScreen` with `VerifyOtpScreen`
- Add imports for all 4 screens
- Delete placeholder classes: `_LoginPlaceholder`, `_RegisterPlaceholder`

---

## SECTION 8 — KNOWN BUGS & FIXES APPLIED

| Bug | Fix | Status |
|---|---|---|
| `withOpacity()` deprecated Flutter 3.27+ | Replaced with `withValues(alpha:)` in all files | ✅ Fixed |
| `AppColors.surfaceHighest` missing | Added to app_colors.dart | ✅ Fixed |
| `hijri ^2.0.1` null safety failure | Updated pubspec to `hijri: ^3.0.1` | ✅ Fixed |
| `MyApp` not found in widget_test.dart | Changed to `QibraApp` | ✅ Fixed |
| Unused `_fonts` field | Removed from app_design_system.dart | ✅ Fixed |
| `DioExceptionType` switch not exhaustive | Added `default` case | ✅ Fixed |
| `_SplashPlaceholder` class corrupt | Deleted, real `SplashScreen` integrated | ✅ Fixed |
| `_OnboardingScreen` wrong name | Changed to `OnboardingScreen` | ✅ Fixed |
| Missing `(` in GoRoute | Fixed syntax | ✅ Fixed |
| Missing `;` at end of routerProvider | Fixed syntax | ✅ Fixed |
| Stray `S` character in router | Removed | ✅ Fixed |
| Unnecessary `foundation.dart` import | Removed | ✅ Fixed |
| `AppUIConstants` not found in buttons | Added import | ✅ Fixed |

### Remaining Issues:
**NONE** — Last `flutter analyze` returned zero issues.  
App runs without crashes.

---

## SECTION 9 — pubspec.yaml DEPENDENCIES

### Production Dependencies:

```yaml
google_fonts: ^6.2.1
flutter_svg: ^2.0.10+1
cached_network_image: ^3.3.1
lottie: ^3.1.2
flutter_riverpod: ^2.5.1
riverpod_annotation: ^2.3.5
go_router: ^14.2.7
dio: ^5.4.3+1
shared_preferences: ^2.3.2
flutter_secure_storage: ^9.2.2
get_it: ^7.7.0
permission_handler: ^11.3.1
geolocator: ^13.0.1
geocoding: ^3.0.0
intl: ^0.19.0
connectivity_plus: ^6.0.5
url_launcher: ^6.3.0
share_plus: ^10.0.2
package_info_plus: ^8.0.2
device_info_plus: ^10.1.2
uuid: ^4.4.2
equatable: ^2.0.5
freezed_annotation: ^2.4.4
json_annotation: ^4.9.0
hijri: ^3.0.1
flutter_local_notifications: ^17.2.2
```

### Dev Dependencies:

```yaml
flutter_lints: ^4.0.0
build_runner: ^2.4.12
riverpod_generator: ^2.4.3
freezed: ^2.5.7
json_serializable: ^6.8.0
```

---

## SECTION 10 — ASSETS STRUCTURE

```
assets/
├── images/          (16 placeholder PNGs)
│   ├── logo.png
│   ├── logo_white.png
│   ├── logo_icon.png
│   ├── splash_bg.png
│   ├── splash_logo.png
│   ├── onboarding_1.png
│   ├── onboarding_2.png
│   ├── onboarding_3.png
│   ├── onboarding_4.png
│   ├── quran_bg.png
│   ├── quran_cover.png
│   ├── mosque.png
│   ├── compass_bg.png
│   ├── islamic_pattern_1.png
│   ├── islamic_pattern_2.png
│   └── pattern_overlay.png
├── icons/           (8 placeholder SVGs)
│   ├── quran.svg
│   ├── prayer.svg
│   ├── qibla.svg
│   ├── hadith.svg
│   ├── ai.svg
│   ├── calendar.svg
│   ├── tasbih.svg
│   └── dua.svg
├── animations/      (6 placeholder Lottie JSONs)
│   ├── loading.json
│   ├── success.json
│   ├── error.json
│   ├── prayer.json
│   ├── quran.json
│   └── ai_thinking.json
└── fonts/           (empty — Google Fonts handles)
```

---

## SECTION 11 — REQUIRED RESPONSE FORMAT

Every response must follow this format exactly:

```
STEP NUMBER

GOAL

WHY

Prerequisites

Folder Path

File Name

Create or Replace

Delete old code (if required)

Paste complete production-ready code

Explain every important line (in Hinglish)

How to save

Terminal command

Expected output

Common errors

How to fix them

Testing steps

Expected UI (ASCII art)

Git commit message

What will be built next

STOP.
Wait for confirmation.
```

### Additional Style Rules:
- Explain in **simple Hinglish** (Hindi + English mix)
- Use **tables** for comparisons
- Use **ASCII art** for UI mockups
- Show **folder trees** for file locations
- Include **git commit messages** for every file
- When giving main.dart or router changes — give **FULL FILE**
- When fixing errors — use **DHUNDO** (find) → **REPLACE WITH** pattern
- Explain **WHY** something is needed, not just HOW
- When adding to existing file — explain **exact location** (before/after which line)

---

## SECTION 12 — DO NOT REBUILD

### These files are FINAL and PRODUCTION-READY:

❌ Do not recreate `app_design_system.dart`  
❌ Do not recreate `app_colors.dart`  
❌ Do not recreate `app_typography.dart`  
❌ Do not recreate `app_theme.dart`  
❌ Do not recreate `app_constants.dart`  
❌ Do not recreate `app_assets_check.dart`  
❌ Do not recreate any provider file  
❌ Do not recreate `dio_client.dart`  
❌ Do not recreate `api_service.dart`  
❌ Do not recreate `service_locator.dart`  
❌ Do not redesign button components  
❌ Do not redesign card components  
❌ Do not redesign text field components  
❌ Do not redesign splash screen  
❌ Do not redesign onboarding screen  
❌ Do not redesign login screen  
❌ Do not redesign register screen  
❌ Do not redesign forgot password screen  

### Only modify existing files when:
1. Fixing a confirmed bug
2. Adding an import for a new file
3. Replacing a placeholder with a real screen (in router)

---

## SECTION 13 — COMMANDS TO RESUME

```bash
# Verify project state
cd qibra_ai
flutter clean
flutter pub get
dart analyze
flutter run

# If dependency issues
flutter pub outdated
flutter pub upgrade

# Create next file folder (already exists)
# lib/features/auth/presentation/verify_otp_screen.dart
```

---

## SECTION 14 — GIT WORKFLOW

### Save current state:
```bash
git status
git add .
git commit -m "checkpoint: Steps 1-15.3 complete, ready for Step 15.4"
git log --oneline -5
```

### Before starting new AI session:
```bash
git log --oneline -10  # See last 10 commits
```

---

## SECTION 15 — MASTER HANDOVER PROMPT

**Copy-paste this entire prompt into a new AI chat:**

```
You are a Senior Flutter Architect, Senior Full Stack Engineer, Senior UI/UX Designer, Senior AI Engineer, Senior Code Reviewer, and Technical Mentor.

You are continuing work on an EXISTING Flutter project called QIBRA AI — an Islamic Super App.

CRITICAL RULES (NEVER BREAK):
1. NEVER create a new project — continue from existing only
2. NEVER break existing working code
3. NEVER redesign completed modules — they are production-ready
4. NEVER use placeholders, TODO, or demo code
5. Every code must be production-ready
6. Handle only ONE FILE at a time
7. Wait for user confirmation after every file
8. Explain everything in simple Hinglish (Hindi + English mix)
9. Teach like the user is a complete beginner
10. Use withValues(alpha:) NOT withOpacity() — Flutter 3.27+

CURRENT PROJECT STATE:
- Phase 1 Foundation in progress
- Steps 1-14 FULLY COMPLETE (Design System, Colors, Typography, Theme, Constants, Assets, Buttons, Cards, Text Fields, Router, Riverpod, DI, Splash, Onboarding)
- Step 15 Authentication PARTIALLY complete:
  ✅ login_screen.dart DONE
  ✅ register_screen.dart DONE
  ✅ forgot_password_screen.dart DONE
  ❌ verify_otp_screen.dart NOT YET CREATED ← BUILD THIS NEXT
  ❌ app_router.dart update PENDING

NEXT IMMEDIATE ACTION:
Create file: lib/features/auth/presentation/verify_otp_screen.dart

Must contain:
- 6-digit OTP input using existing AppOtpField component
- Timer countdown (60 seconds) for resend
- Auto-submit when all 6 digits entered
- Resend OTP button (enabled after timer)
- Email display showing where OTP was sent
- Error/loading states
- Success → navigate to home
- Riverpod auth integration
- Premium Islamic design (Dark Emerald + Royal Gold theme)

After OTP screen, update app_router.dart to replace all 4 placeholder auth screens with real ones (LoginScreen, RegisterScreen, ForgotPasswordScreen, VerifyOtpScreen).

After auth complete:
- Step 16: Bottom Navigation (real implementation)
- Step 17: Home Dashboard
- Then Phase 1 Foundation COMPLETE

TECH STACK:
- Flutter (Dart 3.3+), Material 3
- Riverpod (state management)
- GoRouter (navigation with auth guards)
- GetIt (dependency injection)
- Dio (HTTP client)
- Google Fonts (Poppins + Amiri)
- SharedPreferences + FlutterSecureStorage

EXISTING REUSABLE WIDGETS (already built, just import and use):
- Buttons: AppPrimaryButton, AppSecondaryButton, AppGoldButton, AppTextBtn, AppIconBtn, AppSocialButton, AppLoadingButton
- Cards: AppCard, AppGradientCard, AppFeatureCard, AppInfoCard, AppPrayerCard, AppQuranCard, AppHadithCard, AppShimmerCard
- Inputs: AppTextField, AppPasswordField, AppSearchField, AppOtpField, AppTextArea, AppDropdownField
- Design System: AppSpacing, AppRadius, AppColors, AppTextStyles, AppArabicStyles, AppGradients, AppShadows, AppDurations

RESPONSE FORMAT (follow exactly):
STEP NUMBER / GOAL / WHY / Prerequisites / Folder Path / File Name / Create or Replace / Delete old code / Complete production-ready code / Explain every important line in Hinglish / How to save / Terminal command / Expected output / Common errors / How to fix / Testing steps / Expected UI (ASCII art) / Git commit message / What next / STOP. Wait for confirmation.

START NOW:
Begin with Step 15.4: verify_otp_screen.dart
Handle only this ONE FILE.
Wait for my confirmation before proceeding.
```

---

## SECTION 16 — HANDOFF STATUS

```
Document Version   : 3.0 Final
Phase              : 1 — Foundation
Steps Complete     : 1-14, 15.1, 15.2, 15.3
Steps In Progress  : 15 (2 sub-steps remaining)
Steps Pending      : 16, 17
Next File          : lib/features/auth/presentation/verify_otp_screen.dart
Total Files Built  : 22 production files
Total Code Lines   : ~8000+ Dart
Last Analyzer Run  : Zero issues
App Status         : Runs perfectly
Last Known Issue   : None
```

---

*This document is the SINGLE SOURCE OF TRUTH for QIBRA AI project continuation.*  
*Any future AI must read this ENTIRELY before making any changes.*  
*Version 3.0 — Generated at end of Step 15.3.*