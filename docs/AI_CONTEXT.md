# QIBRA AI — COMPLETE PROJECT CONTEXT

**Last Updated:** v6.0 Home Screen Live + Real Quran Data Integrated
**Current:** Ready for Phase 8.3 — Surah Reader (Biggest Feature!)

═══════════════════════════════════════
PROJECT VISION
═══════════════════════════════════════

QIBRA AI = #1 Global Islamic Super App
- 100K+ downloads Year 1
- 4.5+ star ratings
- Multi-language support
- Complete Islamic companion
- Sadaqah Jariyah for developer

═══════════════════════════════════════
TECH STACK (LOCKED)
═══════════════════════════════════════

- Flutter Material 3
- Dart 3.3+
- Riverpod 2.5.1 (state management - LOCKED)
- GoRouter 14.2.7 (navigation)
- GetIt 7.7.0 (DI)
- Dio 5.4.3 (networking)
- Google Fonts (Poppins + Amiri)
- flutter_local_notifications 17.2.2
- just_audio 0.9.40 (Quran audio)
- audio_session 0.1.21
- path_provider 2.1.4
- sqflite 2.3.3+1

═══════════════════════════════════════
FOLDER STRUCTURE
═══════════════════════════════════════

lib/
├── core/
│   ├── constants/app_constants.dart
│   ├── design_system/
│   │   ├── app_colors.dart
│   │   ├── app_typography.dart
│   │   ├── app_theme.dart
│   │   └── app_design_system.dart
│   ├── di/service_locator.dart
│   ├── network/dio_client.dart
│   ├── providers/
│   │   ├── app_provider.dart
│   │   ├── auth_provider.dart
│   │   └── theme_provider.dart
│   ├── router/app_router.dart
│   └── services/api_service.dart
│
├── features/
│   ├── auth/presentation/
│   │   ├── login_screen.dart
│   │   ├── register_screen.dart
│   │   ├── forgot_password_screen.dart
│   │   └── otp_verification_screen.dart
│   │
│   ├── home/presentation/
│   │   └── home_screen.dart ✅ v6.0 (4800 lines, 27 sections)
│   │
│   ├── onboarding/presentation/
│   │   ├── onboarding_v1_screen.dart
│   │   ├── onboarding_v2_screen.dart
│   │   └── onboarding_v3_screen.dart
│   │
│   ├── prayer/presentation/
│   │   └── prayer_screen.dart ✅ v1.1
│   │
│   ├── quran/
│   │   ├── data/
│   │   │   ├── models/quran_models.dart ✅ (8 models)
│   │   │   └── repository/quran_repository.dart ✅
│   │   ├── providers/quran_provider.dart ✅ (19 providers)
│   │   └── presentation/quran_screen.dart ✅
│   │
│   ├── settings/presentation/
│   │   ├── language_selection_screen.dart
│   │   ├── permission_screen.dart
│   │   └── profile_setup_screen.dart
│   │
│   └── splash/presentation/
│       └── splash_screen.dart
│
├── shared/widgets/
│   ├── buttons/app_button.dart
│   ├── cards/
│   │   ├── app_card.dart
│   │   ├── app_hero_image_card.dart ✅
│   │   ├── app_recent_surah_card.dart ✅
│   │   ├── app_listen_card.dart ✅
│   │   └── app_feature_illustration_card.dart ✅
│   ├── inputs/app_text_field.dart
│   ├── navigation/app_bottom_nav.dart ✅
│   ├── indicators/app_circular_progress_ring.dart ✅
│   └── badges/app_ornamental_star_badge.dart ✅
│
└── main.dart ✅

═══════════════════════════════════════
DESIGN SYSTEM TOKENS
═══════════════════════════════════════

**Colors (AppColors):**
- primary, primaryDark, primaryLight (Emerald)
- accent, accentDark, accentLight (Gold)
- background, surface, surfaceElevated
- textPrimary, textSecondary, textTertiary
- success, error, warning, info
- white, black
- borderSubtle, borderRegular
- iconPrimary, iconSecondary

**Spacing (AppSpacing):**
- xs2 (2px), xs (4px), sm (8px)
- md (12px), lg (16px)
- xl (20px), xl2 (24px), xl3 (32px)
- xl4 (48px), xl6 (64px)

**Typography (AppTextStyles):**
- displayLarge, displayMedium, displaySmall
- headlineLarge, headlineMedium, headlineSmall
- titleLarge, titleMedium, titleSmall
- bodyLarge, bodyMedium, bodySmall
- labelLarge, labelMedium, labelSmall

**Arabic (AppArabicStyles):**
- headlineArabic, bodyArabic, labelArabic
- Font: Amiri (bundled)

**Gradients (AppGradients):**
- emerald (green gradient)
- gold (yellow gradient)
- emeraldRadial, goldRadial

**Shadows (AppShadows):**
- small, medium, large
- emeraldGlow, goldGlow

**Radius (AppRadius):**
- buttonRadius (12px)
- cardRadius (16px)
- cardRadiusLarge (24px)
- pillRadius (999px)

**Durations (AppDurations):**
- fast (200ms), medium (400ms), slow (800ms)

═══════════════════════════════════════
PROVIDERS (RIVERPOD)
═══════════════════════════════════════

Core Providers:
- authProvider
- currentUserProvider
- userDisplayNameProvider
- themeProvider
- isDarkModeProvider
- flutterThemeModeProvider
- onboardingProvider
- routerProvider

Quran Providers (19 total):
- quranRepositoryProvider
- quranInitProvider
- allSurahsProvider
- surahDetailProvider (family)
- surahInfoProvider (family)
- ayahProvider (family)
- randomAyahProvider
- autoRotatingAyahProvider ⭐
- popularSurahsProvider ⭐
- meccanSurahsProvider
- medinanSurahsProvider
- searchQuranProvider
- searchSurahProvider
- currentSurahIndexProvider
- currentAyahIndexProvider
- lastReadProvider
- bookmarksProvider
- bookmarksCountProvider
- isBookmarkedProvider (family)
- readingProgressProvider

═══════════════════════════════════════
ROUTES (EXISTING)
═══════════════════════════════════════

Auth Routes (top-level):
/  → splash
/onboarding
/login
/register
/forgot-password
/verify-otp
/profile-setup

Main App (with bottom nav):
/home ✅ (v6.0)
/quran ✅
/prayer ✅
/prayer/qibla
/tasbih (placeholder)
/hadith (placeholder - has beautiful card only)
/ai-chat (placeholder)
/dua (placeholder)
/calendar (placeholder)
/mosques (placeholder)
/profile (basic)
/settings (basic)

═══════════════════════════════════════
COMPLETED WORK SUMMARY
═══════════════════════════════════════

**Phase 6-8 Home Screen (v6.0) has:**
- Hero Header with mosque bg + weather (21°C)
- Prayer Countdown Card with Kaaba 3D + gold ring
- 5 colorful prayer pills (Asr highlighted)
- Today's Progress with 4 mini bars
- Daily Verse (REAL random ayah - auto rotates!)
- Reading Streak (12 days purple with lanterns)
- Ramadan Widget (purple gradient + lanterns) ⭐
- Quick Access (6 circular icons)
- Quran Section Header (with search + filter)
- Continue Reading (Al-Baqarah + Ayat-ul-Kursi) ⭐
- Quran Stats (114, 30, 604, 12)
- Popular Surahs (REAL 4 from repository) ⭐
- Nearby Mosques (3 cards with ratings) ⭐
- Hadith Card (amber Sahih al-Bukhari) ⭐
- Listen to Quran (single audio player)
- Feature Grid (6 3D cards) ⭐
- Bottom Features (Audio, Trans, Tafsir, Notes)
- Golden Arabic Watermark (جزاك الله) ⭐
- Error State + Empty State ⭐

⭐ = V4 features restored in v6.0

**Phase 7 Prayer Screen has:**
- Sun arc custom painter with moving sun
- Live countdown (30s updates)
- All 5 prayers with cards
- Adhan/reminder toggles per prayer
- Calculation method selector (6 methods)
- Asr method (Standard/Hanafi)
- Time format toggle (12H/24H)
- Location header with GPS refresh
- More options card

**Phase 8 Quran Screen has:**
- Al-Fatihah hero card with 3D Quran
- 4 circular categories
- Reading progress card
- Recently Read section
- Daily Verse
- Listen to Quran card
- Bottom info card

**Phase 8.2 Real Quran Data:**
- Downloaded 6.4 MB Quran JSON
- Created 8 data models
- Full repository with search
- 19 Riverpod providers
- Auto-rotating daily verse
- Real popular surahs
- main.dart preload

═══════════════════════════════════════
STATISTICS
═══════════════════════════════════════

- Total Files: 65+
- Lines of Code: ~40,000+
- Screens: 20+
- Reusable Widgets: 30+
- Analyzer Issues: 0 errors, 13 warnings (safe)
- Test Coverage: Manual (real device)
- Progress: 65%

═══════════════════════════════════════
TEST CREDENTIALS
═══════════════════════════════════════

Email: test@qibra.ai
Password: password123
OTP: 123456

═══════════════════════════════════════
IMMEDIATE NEXT ACTION
═══════════════════════════════════════

### PHASE 8.3: SURAH READER (RECOMMENDED FIRST!)

**Priority:** HIGHEST 🔥
**Duration:** 5-7 days
**Reason:** Users can see surah names but can't read them!

**Files to Create:**
1. `lib/features/quran/presentation/surah_list_screen.dart`
   - All 114 surahs list
   - Search functionality
   - Filter by Meccan/Medinan
   - Grid/List view toggle

2. `lib/features/quran/presentation/surah_reader_screen.dart`
   - Ayah-by-ayah display
   - Arabic + Translation
   - Font size controls
   - Play audio button per ayah
   - Bookmark button per ayah
   - Auto-scroll while playing

3. `lib/features/quran/presentation/ayah_action_sheet.dart`
   - Bottom sheet with actions
   - Bookmark toggle
   - Share as image/text
   - Copy to clipboard
   - Add personal note

4. `lib/features/quran/presentation/font_size_selector.dart`
   - Small (14px)
   - Medium (18px)
   - Large (22px)
   - Extra Large (26px)

**Data Available:**
✅ 114 Surahs
✅ 6,236 Ayahs
✅ English translation
✅ 19 Providers ready
✅ All models ready
✅ Repository working

═══════════════════════════════════════