// lib/core/router/app_router.dart
// ============================================================
// QIBRA AI – APP ROUTER (Complete)
// Version: 9.0.0 – Islamic Tools Hub Added
// ============================================================
import 'package:qibra_ai/features/calendar/presentation/islamic_calendar_screen.dart';
import 'package:qibra_ai/features/settings/presentation/settings_screen.dart';
import 'package:qibra_ai/features/qibla/presentation/qibla_screen.dart';
import 'package:qibra_ai/features/duas/presentation/duas_home_screen.dart';
import 'package:qibra_ai/features/tools/screens/tools_hub_screen.dart';
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
import 'package:qibra_ai/features/ai/presentation/ai_explain_screen.dart';
import 'package:qibra_ai/features/hadith/presentation/hadith_screen.dart';
import 'package:qibra_ai/features/tasbih/presentation/tasbih_screen.dart';
import 'package:qibra_ai/features/tools/screens/zakat_calculator_screen.dart';
import 'package:qibra_ai/features/tools/screens/dhikr_counter_screen.dart';
import 'package:qibra_ai/features/tools/screens/sadaqah_tracker_screen.dart';
import 'package:qibra_ai/features/tools/screens/habit_tracker_screen.dart';
import 'package:qibra_ai/features/tools/screens/ramadan_timer_screen.dart';
import 'package:qibra_ai/features/tools/screens/hajj_guide_screen.dart';
import 'package:qibra_ai/features/tools/screens/umrah_guide_screen.dart';
import 'package:qibra_ai/features/tools/screens/nikah_guide_screen.dart';
import 'package:qibra_ai/features/tools/screens/halal_scanner_screen.dart';
import 'package:qibra_ai/features/tools/screens/asma_ul_husna_screen.dart';
import 'package:qibra_ai/features/tools/screens/islamic_name_finder_screen.dart';
import 'package:qibra_ai/features/tools/screens/inheritance_calculator_screen.dart';
import 'package:qibra_ai/features/settings/presentation/notification_settings_screen.dart';
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

class _MosquesPlaceholder extends StatelessWidget {
  const _MosquesPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text('Mosques', style: AppTextStyles.headlineLarge),
      ),
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
              Text(
                user.email,
                style: AppTextStyles.bodyMedium.secondary,
              ),
            ],
          ],
        ),
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
            const Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 64,
            ),
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

    // ============================================================
    // REDIRECT LOGIC
    // ============================================================
    redirect: (context, state) {
      final String currentPath = state.matchedLocation;
      final authState = ref.read(authProvider);
      final hasSeenOnboarding = ref.read(onboardingProvider);

      // 1️⃣ Agar auth abhi load ho raha hai → splash pe raho
      if (authState.status == AuthStatus.initial ||
          authState.status == AuthStatus.loading) {
        if (currentPath != AppRoutes.splash) return AppRoutes.splash;
        return null;
      }

      // 2️⃣ Splash aur Onboarding ko freely jaane do
      if (currentPath == AppRoutes.splash) return null;
      if (currentPath == AppRoutes.onboarding) return null;

      // 3️⃣ Onboarding nahi dekha → pehle onboarding
      if (!hasSeenOnboarding) return AppRoutes.onboarding;

      // 4️⃣ Auth screens (login, register, etc.)
      final bool isAuthScreen = currentPath == AppRoutes.login ||
          currentPath == AppRoutes.register ||
          currentPath == AppRoutes.forgotPassword ||
          currentPath == AppRoutes.verifyOtp;

      // Login optional hai — agar already logged in hai aur auth screen pe hai
      // toh home pe bhejo
      if (authState.isAuthenticated && isAuthScreen) {
        return AppRoutes.home;
      }

      // 5️⃣ Baaki sab allow — no forced login
      return null;
    },

    // ============================================================
    // ROUTES
    // ============================================================
    routes: [
      // ── Splash ────────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // ── Onboarding ────────────────────────────────────────────
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // ── Auth Routes ───────────────────────────────────────────
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

      // ── Mushaf Reader (Fullscreen — Shell ke bahar) ───────────
      GoRoute(
        path: AppRoutes.mushafReader,
        name: 'mushaf-reader',
        builder: (context, state) {
          final pageStr = state.uri.queryParameters['page'] ?? '1';
          final page = int.tryParse(pageStr) ?? 1;
          return MushafReaderScreen(initialPage: page);
        },
      ),

      // ── Main App Shell (Bottom Nav ke saath) ──────────────────
      ShellRoute(
        builder: (context, state, child) => AppShellScaffold(
          location: state.matchedLocation,
          notificationCount: 3,
          onHomeTap: () => context.go(AppRoutes.home),
          onQuranTap: () => context.go(AppRoutes.quran),
          onPrayerTap: () => context.go(AppRoutes.prayer),
          onHadithTap: () => context.go(AppRoutes.hadith),
          onAiTap: () => context.go(AppRoutes.aiChat),
          onSettingsTap: () => context.go(AppRoutes.settings),
          onCenterFabTap: () => context.go(AppRoutes.quran),
          child: child,
        ),
        routes: [
          // ── Home ──────────────────────────────────────────────
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),

          // ── Quran ─────────────────────────────────────────────
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

          // ── Prayer Times ───────────────────────────────────────
          GoRoute(
            path: AppRoutes.prayer,
            name: 'prayer',
            builder: (context, state) => const PrayerTimesScreen(),
          ),

          // ── Qibla ─────────────────────────────────────────────
          GoRoute(
            path: AppRoutes.qibla,
            name: 'qibla',
            builder: (context, state) => const QiblaScreen(),
          ),

          // ── Tasbih ────────────────────────────────────────────
          GoRoute(
            path: AppRoutes.tasbih,
            name: 'tasbih',
            builder: (context, state) => const TasbihScreen(),
          ),

          // ── Hadith ────────────────────────────────────────────
          GoRoute(
            path: AppRoutes.hadith,
            name: 'hadith',
            builder: (context, state) => const HadithScreen(),
          ),

          // ── AI Chat ───────────────────────────────────────────
          GoRoute(
            path: AppRoutes.aiChat,
            name: 'ai-chat',
            builder: (context, state) => const AIExplainScreen(),
          ),

          // ── Dua ───────────────────────────────────────────────
          GoRoute(
            path: AppRoutes.dua,
            name: 'dua',
            builder: (context, state) => const DuasHomeScreen(),
          ),

          // ── Islamic Calendar ──────────────────────────────────
          GoRoute(
            path: AppRoutes.islamicCalendar,
            name: 'islamic-calendar',
            builder: (context, state) => const IslamicCalendarScreen(),
          ),

          // ── Mosques ───────────────────────────────────────────
          GoRoute(
            path: AppRoutes.mosques,
            name: 'mosques',
            builder: (context, state) => const _MosquesPlaceholder(),
          ),

          // ── Profile ───────────────────────────────────────────
          GoRoute(
            path: AppRoutes.profile,
            name: 'profile',
            builder: (context, state) => const _ProfilePlaceholder(),
          ),

          // ── Settings ──────────────────────────────────────────
          GoRoute(
            path: AppRoutes.settings,
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),

          // ── Islamic Tools Hub ─────────────────────────────────
          GoRoute(
            path: '/tools',
            name: 'tools',
            builder: (context, state) => const ToolsHubScreen(),
          ),

          // ── Zakat Calculator ──────────────────────────────────
          GoRoute(
            path: '/tools/zakat',
            name: 'tools-zakat',
            builder: (context, state) => const ZakatCalculatorScreen(),
          ),
          // ── Dhikr Counter ─────────────────────────────────────
          GoRoute(
            path: '/tools/dhikr',
            name: 'tools-dhikr',
            builder: (context, state) => const DhikrCounterScreen(),
          ),
          // ── Sadaqah Tracker ───────────────────────────────────
          GoRoute(
            path: '/tools/sadaqah',
            name: 'tools-sadaqah',
            builder: (context, state) => const SadaqahTrackerScreen(),
          ),
          // ── Habit Tracker ─────────────────────────────────────
          GoRoute(
            path: '/tools/habits',
            name: 'tools-habits',
            builder: (context, state) => const HabitTrackerScreen(),
          ),
          // ── Ramadan Timer ─────────────────────────────────────
          GoRoute(
            path: '/tools/ramadan',
            name: 'tools-ramadan',
            builder: (context, state) => const RamadanTimerScreen(),
          ),
          // ── Hajj Guide ────────────────────────────────────────
          GoRoute(
            path: '/tools/hajj',
            name: 'tools-hajj',
            builder: (context, state) => const HajjGuideScreen(),
          ),

          // ── Umrah Guide ───────────────────────────────────────
          GoRoute(
            path: '/tools/umrah',
            name: 'tools-umrah',
            builder: (context, state) => const UmrahGuideScreen(),
          ),
          // ── Nikah Guide ───────────────────────────────────────
          GoRoute(
            path: '/tools/nikah',
            name: 'tools-nikah',
            builder: (context, state) => const NikahGuideScreen(),
          ),
          // ── 99 Names of Allah ─────────────────────────────────
          GoRoute(
            path: '/tools/asma',
            name: 'tools-asma',
            builder: (context, state) => const AsmaUlHusnaScreen(),
          ),
          // ── Halal Scanner ─────────────────────────────────────
          GoRoute(
            path: '/tools/halal',
            name: 'tools-halal',
            builder: (context, state) => const HalalScannerScreen(),
          ),
          // ── Islamic Name Finder ───────────────────────────────
          GoRoute(
            path: '/tools/names',
            name: 'tools-names',
            builder: (context, state) => const IslamicNameFinderScreen(),
          ),
          // ── Inheritance Calculator ────────────────────────────
          GoRoute(
            path: '/tools/inheritance',
            name: 'tools-inheritance',
            builder: (context, state) => const InheritanceCalculatorScreen(),
          ),
          // ── Notification Settings ─────────────────────────────
          GoRoute(
            path: '/settings/notifications',
            name: 'notification-settings',
            builder: (context, state) => const NotificationSettingsScreen(),
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
