# QIBRA AI — COMPLETE PROJECT CONTEXT

## PROJECT IDENTITY
- **Name:** QIBRA AI
- **Type:** Islamic Super App
- **Framework:** Flutter (Dart 3.3+)
- **Package:** ai.qibra.app
- **Version:** 1.0.0+1
- **Theme:** Dark Emerald (#00A86B) + Royal Gold (#D4AF37)
- **Fonts:** Poppins (English) + Amiri (Arabic)

## TECH STACK
- Flutter Material 3
- Riverpod 2.5.1 (state management)
- GoRouter 14.2.7 (navigation)
- GetIt 7.7.0 (dependency injection)
- Dio 5.4.3 (HTTP)
- FlutterSecureStorage (tokens)
- SharedPreferences (settings)
- Google Fonts (Poppins + Amiri)

## FOLDER STRUCTURE
```
lib/
├── core/
│   ├── constants/
│   │   ├── app_constants.dart
│   │   └── app_assets_check.dart
│   ├── design_system/
│   │   ├── app_design_system.dart
│   │   ├── app_colors.dart
│   │   ├── app_typography.dart
│   │   └── app_theme.dart
│   ├── di/
│   │   └── service_locator.dart
│   ├── network/
│   │   └── dio_client.dart
│   ├── providers/
│   │   ├── app_providers.dart
│   │   ├── auth_provider.dart
│   │   └── theme_provider.dart
│   ├── router/
│   │   └── app_router.dart
│   └── services/
│       └── api_service.dart
├── features/
│   ├── auth/
│   │   └── presentation/
│   │       ├── login_screen.dart
│   │       ├── register_screen.dart
│   │       ├── forgot_password_screen.dart
│   │       └── verify_otp_screen.dart
│   ├── home/
│   │   └── presentation/
│   │       └── home_screen.dart
│   ├── onboarding/
│   │   └── presentation/
│   │       └── onboarding_screen.dart
│   └── splash/
│       └── presentation/
│           └── splash_screen.dart
├── shared/
│   └── widgets/
│       ├── buttons/
│       │   └── app_button.dart
│       ├── cards/
│       │   └── app_card.dart
│       ├── inputs/
│       │   └── app_text_field.dart
│       └── navigation/
│           └── app_bottom_nav.dart
└── main.dart
```

## EXISTING REUSABLE WIDGETS

### Buttons (from app_button.dart):
- AppPrimaryButton — Emerald gradient
- AppSecondaryButton — Outlined emerald
- AppGoldButton — Royal gold gradient
- AppTextBtn — Text only
- AppIconBtn — Circular icon
- AppSocialButton — Google/Apple
- AppLoadingButton — Auto async

### Cards (from app_card.dart):
- AppCard — Standard dark
- AppGradientCard — Emerald/Gold
- AppFeatureCard — Islamic features
- AppInfoCard — Stats display
- AppPrayerCard — Prayer times
- AppListCard — List items
- AppQuranCard — Surah cards
- AppHadithCard — Hadith display
- AppShimmerCard — Loading skeleton

### Inputs (from app_text_field.dart):
- AppTextField — Standard
- AppPasswordField — With show/hide
- AppSearchField — With clear button
- AppOtpField — 6-digit OTP
- AppTextArea — Multi-line
- AppDropdownField — Selection

### Navigation (from app_bottom_nav.dart):
- AppBottomNav — Custom nav bar
- AppShellScaffold — Router shell
- NavBarItem — Data model

## DESIGN SYSTEM TOKENS

### Spacing:
```dart
AppSpacing.xs2 (2), xs (4), sm (8), md (12), lg (16)
AppSpacing.xl (20), xl2 (24), xl3 (32), xl4 (40)
```

### Colors:
```dart
AppColors.primary (Emerald #00A86B)
AppColors.accent (Gold #D4AF37)
AppColors.background (Deep dark)
AppColors.surface (Card bg)
AppColors.textPrimary/Secondary/Tertiary
AppColors.success/error/warning/info
```

### Typography:
```dart
AppTextStyles.headlineLarge/Medium/Small
AppTextStyles.titleLarge/Medium/Small
AppTextStyles.bodyLarge/Medium/Small
AppTextStyles.labelLarge/Medium/Small
AppTextStyles.appName, .goldHeading, .emeraldHeading
AppArabicStyles.bismillah, .quranMedium, .translation
```

### Extensions:
```dart
.emerald, .gold, .bold, .semiBold, .italic
.secondary, .tertiary, .success, .error
```

## PROVIDERS (Riverpod)

### Auth:
- authProvider (StateNotifierProvider)
- isAuthenticatedProvider
- currentUserProvider
- authLoadingProvider
- authErrorProvider
- userDisplayNameProvider

### Theme:
- themeProvider (StateNotifierProvider)
- localeProvider
- onboardingProvider
- flutterThemeModeProvider
- isDarkModeProvider
- currentLanguageProvider
- isRTLProvider

### Router:
- routerProvider (Provider<GoRouter>)

### System:
- sharedPreferencesProvider
- secureStorageProvider
- connectivityProvider
- isOnlineProvider

## ROUTES

```dart
AppRoutes.splash = '/'
AppRoutes.onboarding = '/onboarding'
AppRoutes.login = '/login'
AppRoutes.register = '/login/register'
AppRoutes.forgotPassword = '/login/forgot-password'
AppRoutes.verifyOtp = '/login/verify-otp'
AppRoutes.home = '/home'
AppRoutes.quran = '/quran'
AppRoutes.prayer = '/prayer'
AppRoutes.hadith = '/hadith'
AppRoutes.aiChat = '/ai-chat'
AppRoutes.profile = '/profile'
AppRoutes.settings = '/settings'
```

## CRITICAL RULES

### NEVER:
- Create new project
- Break existing code
- Redesign completed modules
- Use placeholders or TODO
- Use withOpacity() — use withValues(alpha:) instead
- Hardcode values — use design system tokens
- Skip explanations
- Handle multiple files at once

### ALWAYS:
- Continue from existing project
- Use existing reusable widgets
- Explain in simple Hinglish
- Wait for user confirmation after each file
- Use ConsumerWidget/ConsumerStatefulWidget for Riverpod
- Dispose controllers in dispose()
- Check mounted before setState after async

## RESPONSE FORMAT

Every response must follow:
1. STEP NUMBER
2. GOAL
3. WHY
4. Prerequisites
5. Folder Path
6. File Name
7. Create or Replace
8. Delete old code (if needed)
9. Complete production-ready code
10. Explain every important line
11. How to save
12. Terminal command
13. Expected output
14. Common errors
15. How to fix
16. Testing
17. Expected UI (ASCII art)
18. Files changed
19. Git commit message
20. Update AI_CONTEXT.md
21. Update PROJECT_STATUS.md
22. Update NEXT_STEP.md
23. STOP. Wait for confirmation.

## KNOWN FIXES APPLIED
- withOpacity → withValues(alpha:)
- AppColors.surfaceHighest added
- hijri package updated to ^3.0.1
- MyApp → QibraApp in tests
- Splash mounted checks added
- 30 placeholder assets created via create_assets.py
- Router integrated with all real screens

## APP FLOW WORKING
1. Splash (3s) → auto navigate
2. First time → Onboarding → Login
3. Not logged in → Login Screen
4. Logged in → Home Dashboard
5. Home → Bottom Nav (5 tabs + gold FAB)

## TEST CREDENTIALS
- Email: test@qibra.ai
- Password: password123
- OTP: 123456