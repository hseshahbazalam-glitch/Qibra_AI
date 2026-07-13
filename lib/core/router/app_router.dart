// lib/core/router/app_router.dart

// ============================================================
// QIBRA AI — APP ROUTER (Home Dashboard Integrated)
// Version: 5.0.0 — PHASE 1 COMPLETE
// Description: Final router with all real screens.
//              Splash, Onboarding, Auth, Home — all real.
//              Only Phase 2 features are placeholders.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qibra_ai/core/constants/app_constants.dart';
import 'package:qibra_ai/core/design_system/app_colors.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';
import 'package:qibra_ai/core/providers/auth_provider.dart';
import 'package:qibra_ai/core/providers/theme_provider.dart';
import 'package:qibra_ai/features/auth/presentation/forgot_password_screen.dart';
import 'package:qibra_ai/features/auth/presentation/login_screen.dart';
import 'package:qibra_ai/features/auth/presentation/register_screen.dart';
import 'package:qibra_ai/features/auth/presentation/verify_otp_screen.dart';
import 'package:qibra_ai/features/home/presentation/home_screen.dart';
import 'package:qibra_ai/features/onboarding/presentation/onboarding_screen.dart';
import 'package:qibra_ai/features/splash/presentation/splash_screen.dart';
import 'package:qibra_ai/shared/widgets/navigation/app_bottom_nav.dart';

// ============================================================
// PHASE 2 PLACEHOLDER SCREENS
// These will be replaced in Phase 2 development
// ============================================================

// ── QURAN PLACEHOLDER ──────────────────────────────────
class _QuranPlaceholder extends StatelessWidget {
  const _QuranPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppGradients.emerald,
                shape: BoxShape.circle,
                boxShadow: AppShadows.emeraldGlow,
              ),
              child: const Icon(
                Icons.menu_book,
                color: AppColors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Quran Screen',
              style: AppTextStyles.headlineLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Coming in Phase 2',
              style: AppTextStyles.bodyMedium.secondary,
            ),
            const SizedBox(height: AppSpacing.xl2),
            Container(
              padding: AppSpacing.cardPadding,
              margin: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl2,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.cardRadius,
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                children: [
                  Text(
                    '📖 Full Quran',
                    style: AppTextStyles.titleMedium.emerald,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '114 Surahs · 6236 Ayahs\n'
                    'Audio Recitation\n'
                    'Multiple Translations\n'
                    'Bookmarks & Progress',
                    style: AppTextStyles.bodySmall.secondary,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── PRAYER PLACEHOLDER ─────────────────────────────────
class _PrayerPlaceholder extends StatelessWidget {
  const _PrayerPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A8A),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1E3A8A).withValues(alpha: 0.40),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.access_time_filled,
                color: AppColors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Prayer Screen',
              style: AppTextStyles.headlineLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Coming in Phase 2',
              style: AppTextStyles.bodyMedium.secondary,
            ),
            const SizedBox(height: AppSpacing.xl2),
            Container(
              padding: AppSpacing.cardPadding,
              margin: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl2,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.cardRadius,
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                children: [
                  Text(
                    '🕌 Prayer Times',
                    style: AppTextStyles.titleMedium.emerald,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Accurate GPS-based Times\n'
                    '5 Daily Prayers\n'
                    'Qibla Direction Compass\n'
                    'Adhan Notifications',
                    style: AppTextStyles.bodySmall.secondary,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── HADITH PLACEHOLDER ─────────────────────────────────
class _HadithPlaceholder extends StatelessWidget {
  const _HadithPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: AppGradients.gold,
                shape: BoxShape.circle,
                boxShadow: AppShadows.goldGlow,
              ),
              child: const Icon(
                Icons.library_books,
                color: AppColors.background,
                size: 40,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Hadith Screen',
              style: AppTextStyles.headlineLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Coming in Phase 2',
              style: AppTextStyles.bodyMedium.secondary,
            ),
            const SizedBox(height: AppSpacing.xl2),
            Container(
              padding: AppSpacing.cardPadding,
              margin: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl2,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.cardRadius,
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                children: [
                  Text(
                    '📚 Hadith Collections',
                    style: AppTextStyles.titleMedium.gold,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Sahih al-Bukhari\n'
                    'Sahih Muslim\n'
                    'Sunan Abu Dawud\n'
                    'Daily Hadith',
                    style: AppTextStyles.bodySmall.secondary,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── AI CHAT PLACEHOLDER ────────────────────────────────
class _AiChatPlaceholder extends StatelessWidget {
  const _AiChatPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF7C3AED),
                    Color(0xFF6D28D9),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF7C3AED).withValues(alpha: 0.40),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.smart_toy,
                color: AppColors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'AI Chat Screen',
              style: AppTextStyles.headlineLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Coming in Phase 2',
              style: AppTextStyles.bodyMedium.secondary,
            ),
            const SizedBox(height: AppSpacing.xl2),
            Container(
              padding: AppSpacing.cardPadding,
              margin: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl2,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.cardRadius,
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                children: [
                  Text(
                    '🤖 Islamic AI Assistant',
                    style: AppTextStyles.titleMedium.emerald,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Ask Islamic Questions\n'
                    'Fatwa Guidance\n'
                    'Quran Explanations\n'
                    'Voice Input Support',
                    style: AppTextStyles.bodySmall.secondary,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── PROFILE PLACEHOLDER ────────────────────────────────
class _ProfilePlaceholder extends ConsumerWidget {
  const _ProfilePlaceholder();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final userName = ref.watch(userDisplayNameProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Avatar
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: AppGradients.emerald,
                shape: BoxShape.circle,
                boxShadow: AppShadows.emeraldGlow,
              ),
              child: Center(
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                  style: AppTextStyles.displaySmall.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              userName,
              style: AppTextStyles.headlineMedium,
            ),
            if (user != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                user.email,
                style: AppTextStyles.bodyMedium.secondary,
              ),
            ],
            const SizedBox(height: AppSpacing.xl2),
            Text(
              'Profile Screen — Coming Soon',
              style: AppTextStyles.bodySmall.tertiary,
            ),
          ],
        ),
      ),
    );
  }
}

// ── SETTINGS PLACEHOLDER ───────────────────────────────
class _SettingsPlaceholder extends ConsumerWidget {
  const _SettingsPlaceholder();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: AppColors.background,
      ),
      body: ListView(
        padding: AppSpacing.screenPadding,
        children: [
          const SizedBox(height: AppSpacing.md),
          // Theme toggle
          ListTile(
            leading: Icon(
              isDark ? Icons.dark_mode : Icons.light_mode,
              color: AppColors.primary,
            ),
            title: Text(
              'Dark Mode',
              style: AppTextStyles.bodyMedium,
            ),
            trailing: Switch(
              value: isDark,
              onChanged: (_) {
                ref.read(themeProvider.notifier).toggleTheme();
              },
            ),
          ),
          const Divider(color: AppColors.divider),
          // App version
          ListTile(
            leading: const Icon(
              Icons.info_outline,
              color: AppColors.iconSecondary,
            ),
            title: Text(
              'App Version',
              style: AppTextStyles.bodyMedium,
            ),
            trailing: Text(
              AppInfo.versionFull,
              style: AppTextStyles.labelMedium.secondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── ERROR SCREEN ───────────────────────────────────────
class _ErrorScreen extends StatelessWidget {
  final String? message;
  const _ErrorScreen({this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 64,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Page Not Found',
              style: AppTextStyles.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message ?? 'The requested page does not exist.',
              style: AppTextStyles.bodyMedium.secondary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl3),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.splash),
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ROUTER PROVIDER — Main Router
// ============================================================

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier(ref);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: refreshNotifier,

    errorBuilder: (context, state) => _ErrorScreen(
      message: state.error?.message,
    ),

    // ── REDIRECT LOGIC ─────────────────────────────────
    redirect: (context, state) {
      final String currentPath = state.matchedLocation;
      final authState = ref.read(authProvider);
      final hasSeenOnboarding = ref.read(onboardingProvider);

      // Loading state — splash pe rehne do
      if (authState.status == AuthStatus.initial ||
          authState.status == AuthStatus.loading) {
        if (currentPath != AppRoutes.splash) {
          return AppRoutes.splash;
        }
        return null;
      }

      // Splash screen pe hai — splash khud navigate karega
      if (currentPath == AppRoutes.splash) {
        return null;
      }

      // Onboarding screen — no redirect
      if (currentPath == AppRoutes.onboarding) return null;

      // Auth screens check
      final bool isAuthScreen = currentPath == AppRoutes.login ||
          currentPath == AppRoutes.register ||
          currentPath == AppRoutes.forgotPassword ||
          currentPath == AppRoutes.verifyOtp;

      if (!hasSeenOnboarding) return AppRoutes.onboarding;

      if (!authState.isAuthenticated && !isAuthScreen) {
        return AppRoutes.login;
      }

      if (authState.isAuthenticated && isAuthScreen) {
        return AppRoutes.home;
      }

      return null;
    },

    // ── ROUTES ─────────────────────────────────────────
    routes: [
      // Splash Screen (REAL)
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Onboarding Screen (REAL)
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // ── AUTH ROUTES (All Real Screens) ───────────────
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
        routes: [
          GoRoute(
            path: 'register',
            name: 'register',
            builder: (context, state) => const RegisterScreen(),
          ),
          GoRoute(
            path: 'forgot-password',
            name: 'forgot-password',
            builder: (context, state) => const ForgotPasswordScreen(),
          ),
          GoRoute(
            path: 'verify-otp',
            name: 'verify-otp',
            builder: (context, state) {
              final email = state.uri.queryParameters['email'];
              return VerifyOtpScreen(email: email);
            },
          ),
        ],
      ),

      // ── MAIN APP with Premium Bottom Nav ─────────────
      ShellRoute(
        builder: (context, state, child) => AppShellScaffold(
          location: state.matchedLocation,
          notificationCount: 3, // Example — real count later
          onHomeTap: () => context.go(AppRoutes.home),
          onQuranTap: () => context.go(AppRoutes.quran),
          onPrayerTap: () => context.go(AppRoutes.prayer),
          onHadithTap: () => context.go(AppRoutes.hadith),
          onAiTap: () => context.go(AppRoutes.aiChat),
          onCenterFabTap: () {
            // Center FAB press — Quick Quran access
            context.go(AppRoutes.quran);
          },
          child: child,
        ),
        routes: [
          // Home (REAL — Phase 1 Complete!)
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),

          // Quran (Phase 2)
          GoRoute(
            path: AppRoutes.quran,
            name: 'quran',
            builder: (context, state) => const _QuranPlaceholder(),
            routes: [
              GoRoute(
                path: 'surah',
                name: 'quran-surah',
                builder: (context, state) => const _QuranPlaceholder(),
              ),
              GoRoute(
                path: 'search',
                name: 'quran-search',
                builder: (context, state) => const _QuranPlaceholder(),
              ),
            ],
          ),

          // Prayer (Phase 2)
          GoRoute(
            path: AppRoutes.prayer,
            name: 'prayer',
            builder: (context, state) => const _PrayerPlaceholder(),
            routes: [
              GoRoute(
                path: 'qibla',
                name: 'qibla',
                builder: (context, state) => const _PrayerPlaceholder(),
              ),
            ],
          ),

          // Hadith (Phase 2)
          GoRoute(
            path: AppRoutes.hadith,
            name: 'hadith',
            builder: (context, state) => const _HadithPlaceholder(),
          ),

          // AI Chat (Phase 2)
          GoRoute(
            path: AppRoutes.aiChat,
            name: 'ai-chat',
            builder: (context, state) => const _AiChatPlaceholder(),
          ),

          // Profile
          GoRoute(
            path: AppRoutes.profile,
            name: 'profile',
            builder: (context, state) => const _ProfilePlaceholder(),
          ),

          // Settings
          GoRoute(
            path: AppRoutes.settings,
            name: 'settings',
            builder: (context, state) => const _SettingsPlaceholder(),
          ),
        ],
      ),
    ],
  );
});

// ============================================================
// ROUTER REFRESH NOTIFIER
// ============================================================

class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen<AuthState>(authProvider, (_, __) {
      notifyListeners();
    });
    ref.listen<bool>(onboardingProvider, (_, __) {
      notifyListeners();
    });
  }
}
