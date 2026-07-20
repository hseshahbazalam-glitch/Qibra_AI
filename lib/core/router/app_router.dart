// lib/core/router/app_router.dart
// ============================================================
// QIBRA AI — APP ROUTER (Complete)
// Version: 8.0.0 — Mushaf Fullscreen (No Bottom Nav)
// ============================================================
import 'package:qibra_ai/features/qibla/presentation/qibla_screen.dart';
import 'package:qibra_ai/features/duas/presentation/duas_home_screen.dart';
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
import 'package:qibra_ai/features/prayer/presentation/prayer_times_screen.dart';
import 'package:qibra_ai/features/quran/presentation/quran_screen.dart';
import 'package:qibra_ai/features/quran/presentation/mushaf_reader_screen.dart';
import 'package:qibra_ai/features/settings/presentation/profile_setup_screen.dart';
import 'package:qibra_ai/features/splash/presentation/splash_screen.dart';
import 'package:qibra_ai/shared/widgets/navigation/app_bottom_nav.dart';
import 'package:qibra_ai/features/chat/presentation/screens/ai_chat_screen.dart';
import 'package:qibra_ai/features/hadith/presentation/hadith_screen.dart';
import 'package:qibra_ai/features/tasbih/presentation/tasbih_screen.dart';

// ============================================================
// PLACEHOLDER SCREENS
// ============================================================

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
            Text('Quran Screen', style: AppTextStyles.headlineLarge),
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

// ignore: unused_element
class _PrayerTimesPlaceholder extends StatelessWidget {
  const _PrayerTimesPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(child: Text('Prayer', style: AppTextStyles.headlineLarge)),
    );
  }
}

// ignore: unused_element
class _QiblaPlaceholder extends StatelessWidget {
  const _QiblaPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(child: Text('Qibla', style: AppTextStyles.headlineLarge)),
    );
  }
}

// ignore: unused_element
class _TasbihPlaceholder extends StatelessWidget {
  const _TasbihPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(child: Text('Tasbih', style: AppTextStyles.headlineLarge)),
    );
  }
}

// ignore: unused_element
class _HadithPlaceholder extends StatelessWidget {
  const _HadithPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(child: Text('Hadith', style: AppTextStyles.headlineLarge)),
    );
  }
}

// ignore: unused_element
class _AiChatPlaceholder extends StatelessWidget {
  const _AiChatPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(child: Text('AI Chat', style: AppTextStyles.headlineLarge)),
    );
  }
}

// ignore: unused_element
class _DuaPlaceholder extends StatelessWidget {
  const _DuaPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(child: Text('Duas', style: AppTextStyles.headlineLarge)),
    );
  }
}

class _CalendarPlaceholder extends StatelessWidget {
  const _CalendarPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text('Islamic Calendar', style: AppTextStyles.headlineLarge),
      ),
    );
  }
}

class _MosquesPlaceholder extends StatelessWidget {
  const _MosquesPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(child: Text('Mosques', style: AppTextStyles.headlineLarge)),
    );
  }
}

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
            Text(userName, style: AppTextStyles.headlineMedium),
            if (user != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(user.email, style: AppTextStyles.bodyMedium.secondary),
            ],
          ],
        ),
      ),
    );
  }
}

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
          ListTile(
            leading: Icon(
              isDark ? Icons.dark_mode : Icons.light_mode,
              color: AppColors.primary,
            ),
            title: Text('Dark Mode', style: AppTextStyles.bodyMedium),
            trailing: Switch(
              value: isDark,
              onChanged: (_) {
                ref.read(themeProvider.notifier).toggleTheme();
              },
            ),
          ),
          const Divider(color: AppColors.divider),
          ListTile(
            leading: const Icon(
              Icons.info_outline,
              color: AppColors.iconSecondary,
            ),
            title: Text('App Version', style: AppTextStyles.bodyMedium),
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
            const Icon(Icons.error_outline, color: AppColors.error, size: 64),
            const SizedBox(height: AppSpacing.lg),
            Text('Page Not Found', style: AppTextStyles.headlineSmall),
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
// ROUTER PROVIDER
// ============================================================

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier(ref);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: refreshNotifier,
    errorBuilder: (context, state) =>
        _ErrorScreen(message: state.error?.message),
    redirect: (context, state) {
      final String currentPath = state.matchedLocation;
      final authState = ref.read(authProvider);
      final hasSeenOnboarding = ref.read(onboardingProvider);

      if (authState.status == AuthStatus.initial ||
          authState.status == AuthStatus.loading) {
        if (currentPath != AppRoutes.splash) return AppRoutes.splash;
        return null;
      }

      if (currentPath == AppRoutes.splash) return null;
      if (currentPath == AppRoutes.onboarding) return null;

      final bool isAuthScreen = currentPath == AppRoutes.login ||
          currentPath == AppRoutes.register ||
          currentPath == AppRoutes.forgotPassword ||
          currentPath == AppRoutes.verifyOtp;

      if (!hasSeenOnboarding) return AppRoutes.onboarding;
      if (!authState.isAuthenticated && !isAuthScreen) return AppRoutes.login;
      if (authState.isAuthenticated && isAuthScreen) return AppRoutes.home;

      return null;
    },
    routes: [
      // Splash
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Onboarding
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Auth Routes
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.verifyOtp,
        name: 'verify-otp',
        builder: (context, state) {
          final email = state.uri.queryParameters['email'];
          return VerifyOtpScreen(email: email);
        },
      ),
      GoRoute(
        path: AppRoutes.profileSetup,
        name: 'profile-setup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),

      // ✅ MUSHAF READER — FULLSCREEN (OUTSIDE ShellRoute)
      // Ye bottom nav ke bahar hai — full immersive experience
      GoRoute(
        path: AppRoutes.mushafReader,
        name: 'mushaf-reader',
        builder: (context, state) {
          final pageStr = state.uri.queryParameters['page'] ?? '1';
          final page = int.tryParse(pageStr) ?? 1;
          return MushafReaderScreen(initialPage: page);
        },
      ),

      // ── MAIN APP Shell (with Bottom Nav) ─────────────────
      ShellRoute(
        builder: (context, state, child) => AppShellScaffold(
          location: state.matchedLocation,
          notificationCount: 3,
          onHomeTap: () => context.go(AppRoutes.home),
          onQuranTap: () => context.go(AppRoutes.quran),
          onPrayerTap: () => context.go(AppRoutes.prayer),
          onHadithTap: () => context.go(AppRoutes.hadith),
          onAiTap: () => context.go(AppRoutes.aiChat),
          onCenterFabTap: () => context.go(AppRoutes.quran),
          child: child,
        ),
        routes: [
          // Home
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),

          // Quran (with sub-routes only — NO mushaf here)
          GoRoute(
            path: AppRoutes.quran,
            name: 'quran',
            builder: (context, state) => const QuranScreen(),
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

          // Prayer
          GoRoute(
            path: AppRoutes.prayer,
            name: 'prayer',
            builder: (context, state) => const PrayerTimesScreen(),
          ),

          // Qibla
          GoRoute(
            path: AppRoutes.qibla,
            name: 'qibla',
            builder: (context, state) => const QiblaScreen(),
          ),

          // Tasbih
          GoRoute(
            path: AppRoutes.tasbih,
            name: 'tasbih',
            builder: (context, state) => const TasbihScreen(),
          ),

          // Hadith
          GoRoute(
            path: AppRoutes.hadith,
            name: 'hadith',
            builder: (context, state) => const HadithScreen(),
          ),

          // AI Chat
          GoRoute(
            path: AppRoutes.aiChat,
            name: 'ai-chat',
            builder: (context, state) => const AiChatScreen(),
          ),

          // Dua
          GoRoute(
            path: AppRoutes.dua,
            name: 'dua',
            builder: (context, state) => const DuasHomeScreen(),
          ),

          // Islamic Calendar
          GoRoute(
            path: AppRoutes.islamicCalendar,
            name: 'islamic-calendar',
            builder: (context, state) => const _CalendarPlaceholder(),
          ),

          // Mosques
          GoRoute(
            path: AppRoutes.mosques,
            name: 'mosques',
            builder: (context, state) => const _MosquesPlaceholder(),
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
    ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
    ref.listen<bool>(onboardingProvider, (_, __) => notifyListeners());
  }
}
