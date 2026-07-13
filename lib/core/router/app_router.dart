// lib/core/router/app_router.dart

// ============================================================
// QIBRA AI — APP ROUTER (Premium Bottom Nav Integrated)
// Version: 4.0.0
// Description: Uses AppShellScaffold from reusable navigation.
//              All auth screens integrated.
//              Ready for Step 17 (Home Dashboard).
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
import 'package:qibra_ai/features/onboarding/presentation/onboarding_screen.dart';
import 'package:qibra_ai/features/splash/presentation/splash_screen.dart';
import 'package:qibra_ai/shared/widgets/navigation/app_bottom_nav.dart';

// ============================================================
// PLACEHOLDER SCREENS (Only for main app — Step 17+ replace)
// Auth placeholders removed — real screens now used
// ============================================================

// ── HOME PLACEHOLDER (Step 17 mein real screen aayega) ──
class _HomePlaceholder extends ConsumerWidget {
  const _HomePlaceholder();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final userName = ref.watch(userDisplayNameProvider);
    final isDark = ref.watch(isDarkModeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              ref.read(themeProvider.notifier).toggleTheme();
            },
          ),
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
            const Icon(
              Icons.check_circle,
              color: AppColors.primary,
              size: 64,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Welcome, $userName!',
              style: AppTextStyles.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (user != null)
              Text(
                user.email,
                style: AppTextStyles.bodyMedium.secondary,
              ),
            const SizedBox(height: AppSpacing.xl3),
            Container(
              padding: AppSpacing.cardPadding,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.cardRadius,
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                children: [
                  Text(
                    '✅ Bottom Nav Integrated!',
                    style: AppTextStyles.titleMedium.emerald,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Premium bottom navigation active\n'
                    'Center gold FAB → Quran quick access\n'
                    'Prayer tab has notification badge (3)\n'
                    'Step 17 mein real Home Dashboard aayega',
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

// ── FEATURE PLACEHOLDERS (Phase 2 mein real screens) ────

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
            const Icon(
              Icons.menu_book,
              color: AppColors.primary,
              size: 64,
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
          ],
        ),
      ),
    );
  }
}

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
            const Icon(
              Icons.access_time_filled,
              color: AppColors.primary,
              size: 64,
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
          ],
        ),
      ),
    );
  }
}

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
            const Icon(
              Icons.library_books,
              color: AppColors.primary,
              size: 64,
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
          ],
        ),
      ),
    );
  }
}

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
            const Icon(
              Icons.smart_toy,
              color: AppColors.primary,
              size: 64,
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
          ],
        ),
      ),
    );
  }
}

class _ProfilePlaceholder extends StatelessWidget {
  const _ProfilePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text(
          'Profile Screen',
          style: AppTextStyles.headlineLarge,
        ),
      ),
    );
  }
}

class _SettingsPlaceholder extends StatelessWidget {
  const _SettingsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text(
          'Settings Screen',
          style: AppTextStyles.headlineLarge,
        ),
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
      // Splash Screen
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Onboarding Screen
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
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            builder: (context, state) => const _HomePlaceholder(),
          ),
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
          GoRoute(
            path: AppRoutes.hadith,
            name: 'hadith',
            builder: (context, state) => const _HadithPlaceholder(),
          ),
          GoRoute(
            path: AppRoutes.aiChat,
            name: 'ai-chat',
            builder: (context, state) => const _AiChatPlaceholder(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            name: 'profile',
            builder: (context, state) => const _ProfilePlaceholder(),
          ),
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
