// lib/core/router/app_router.dart
// ============================================================
// QIBRA AI – APP ROUTER (Complete)
// Version: 9.0.0 – Islamic Tools Hub Added
// THIS VERSION IS CORRECTED TO USE THE NEW HOME SCREEN
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
import 'package:qibra_ai/features/onboarding/presentation/onboarding_screen.dart';
import 'package:qibra_ai/features/prayer/presentation/prayer_times_screen.dart';
import 'package:qibra_ai/features/quran/presentation/quran_screen.dart';
import 'package:qibra_ai/features/quran/presentation/mushaf_reader_screen.dart';
import 'package:qibra_ai/features/quran/presentation/surah_reader_screen.dart';
import 'package:qibra_ai/features/quran/presentation/quran_search_screen.dart';
import 'package:qibra_ai/features/quran/presentation/surah_list_screen.dart';
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
import 'package:qibra_ai/features/home/presentation/home_screen.dart';

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
              onPressed: () => context.go(AppRoutes.home),
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
      if (!hasSeenOnboarding) return AppRoutes.onboarding;
      final bool isAuthScreen = currentPath == AppRoutes.login ||
          currentPath == AppRoutes.register ||
          currentPath == AppRoutes.forgotPassword ||
          currentPath == AppRoutes.verifyOtp;
      if (authState.isAuthenticated && isAuthScreen) {
        return AppRoutes.home;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
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
      GoRoute(
        path: AppRoutes.mushafReader,
        name: 'mushaf-reader',
        builder: (context, state) {
          final pageStr = state.uri.queryParameters['page'] ?? '1';
          final page = int.tryParse(pageStr) ?? 1;
          return MushafReaderScreen(initialPage: page);
        },
      ),
      ShellRoute(
        builder: (context, state, child) => AppShellScaffold(
          location: state.matchedLocation,
          notificationCount: 3,
          onHomeTap: () {
            debugPrint('🏠 HOME TAP → ${AppRoutes.home}');
            context.go(AppRoutes.home);
          },
          onQuranTap: () {
            debugPrint('📖 QURAN TAP → ${AppRoutes.quran}');
            context.go(AppRoutes.quran);
          },
          onPrayerTap: () {
            debugPrint('🕐 PRAYER TAP → ${AppRoutes.prayer}');
            context.go(AppRoutes.prayer);
          },
          onHadithTap: () {
            debugPrint('📚 HADITH TAP → ${AppRoutes.hadith}');
            context.go(AppRoutes.hadith);
          },
          onAiTap: () {
            debugPrint('🤖 AI TAP → ${AppRoutes.aiChat}');
            context.go(AppRoutes.aiChat);
          },
          onSettingsTap: () {
            debugPrint('⚙️ SETTINGS TAP → ${AppRoutes.settings}');
            context.go(AppRoutes.settings);
          },
          onCenterFabTap: () {
            debugPrint('🕌 FAB TAP');
            context.go(AppRoutes.quran);
          },
          child: child,
        ),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.quran,
            name: 'quran',
            builder: (context, state) => const QuranScreen(),
            routes: [
              GoRoute(
                path: 'surah/:surahNumber',
                name: 'quran-surah',
                builder: (context, state) {
                  final idStr = state.pathParameters['surahNumber'] ?? '1';
                  final surahNum = int.tryParse(idStr) ?? 1;
                  final ayahStr = state.uri.queryParameters['ayah'];
                  final ayah = ayahStr != null ? int.tryParse(ayahStr) : null;
                  return SurahReaderScreen(
                      surahNumber: surahNum, initialAyah: ayah);
                },
              ),
              GoRoute(
                path: 'surahs',
                name: 'quran-surah-list',
                builder: (context, state) => const SurahListScreen(),
              ),
              GoRoute(
                path: 'search',
                name: 'quran-search',
                builder: (context, state) => const QuranSearchScreen(),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.prayer,
            name: 'prayer',
            builder: (context, state) => const PrayerTimesScreen(),
          ),
          GoRoute(
            path: AppRoutes.qibla,
            name: 'qibla',
            builder: (context, state) => const QiblaScreen(),
          ),
          GoRoute(
            path: AppRoutes.tasbih,
            name: 'tasbih',
            builder: (context, state) => const TasbihScreen(),
          ),
          GoRoute(
            path: AppRoutes.hadith,
            name: 'hadith',
            builder: (context, state) => const HadithScreen(),
          ),
          GoRoute(
            path: AppRoutes.aiChat,
            name: 'ai-chat',
            builder: (context, state) => const AIExplainScreen(),
          ),
          GoRoute(
            path: AppRoutes.dua,
            name: 'dua',
            builder: (context, state) => const DuasHomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.islamicCalendar,
            name: 'islamic-calendar',
            builder: (context, state) => const IslamicCalendarScreen(),
          ),
          GoRoute(
            path: AppRoutes.mosques,
            name: 'mosques',
            builder: (context, state) => const _MosquesPlaceholder(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            name: 'profile',
            builder: (context, state) => const _ProfilePlaceholder(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
          GoRoute(
            path: '/tools',
            name: 'tools',
            builder: (context, state) => const ToolsHubScreen(),
          ),
          GoRoute(
            path: '/tools/zakat',
            name: 'tools-zakat',
            builder: (context, state) => const ZakatCalculatorScreen(),
          ),
          GoRoute(
            path: '/tools/dhikr',
            name: 'tools-dhikr',
            builder: (context, state) => const DhikrCounterScreen(),
          ),
          GoRoute(
            path: '/tools/sadaqah',
            name: 'tools-sadaqah',
            builder: (context, state) => const SadaqahTrackerScreen(),
          ),
          GoRoute(
            path: '/tools/habits',
            name: 'tools-habits',
            builder: (context, state) => const HabitTrackerScreen(),
          ),
          GoRoute(
            path: '/tools/ramadan',
            name: 'tools-ramadan',
            builder: (context, state) => const RamadanTimerScreen(),
          ),
          GoRoute(
            path: '/tools/hajj',
            name: 'tools-hajj',
            builder: (context, state) => const HajjGuideScreen(),
          ),
          GoRoute(
            path: '/tools/umrah',
            name: 'tools-umrah',
            builder: (context, state) => const UmrahGuideScreen(),
          ),
          GoRoute(
            path: '/tools/nikah',
            name: 'tools-nikah',
            builder: (context, state) => const NikahGuideScreen(),
          ),
          GoRoute(
            path: '/tools/asma',
            name: 'tools-asma',
            builder: (context, state) => const AsmaUlHusnaScreen(),
          ),
          GoRoute(
            path: '/tools/halal',
            name: 'tools-halal',
            builder: (context, state) => const HalalScannerScreen(),
          ),
          GoRoute(
            path: '/tools/names',
            name: 'tools-names',
            builder: (context, state) => const IslamicNameFinderScreen(),
          ),
          GoRoute(
            path: '/tools/inheritance',
            name: 'tools-inheritance',
            builder: (context, state) => const InheritanceCalculatorScreen(),
          ),
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
