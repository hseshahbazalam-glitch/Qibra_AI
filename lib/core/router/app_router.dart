// lib/core/router/app_router.dart
import 'package:qibra_ai/features/prayer/presentation/mosque_finder_screen.dart';
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
import 'package:qibra_ai/features/prayer/presentation/salah_schedule_screen.dart';
import 'package:qibra_ai/features/prayer/presentation/prayer_statistics_screen.dart';
import 'package:qibra_ai/features/prayer/presentation/tahajjud_details_screen.dart';
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
import 'package:qibra_ai/features/hadith/presentation/hadith_book_screen.dart';
import 'package:qibra_ai/features/hadith/data/models/hadith_models.dart';
import 'package:qibra_ai/features/hadith/data/services/hadith_database_service.dart';
import 'package:qibra_ai/features/tasbih/presentation/tasbih_screen.dart';
import 'package:qibra_ai/features/tools/screens/zakat_calculator_screen.dart';
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
import 'package:qibra_ai/features/settings/presentation/user_profile_screen.dart';
import 'package:qibra_ai/features/tafseer/presentation/tafseer_screen.dart';
import 'package:qibra_ai/features/more/presentation/more_screen.dart';
import 'package:qibra_ai/features/bookmarks/presentation/bookmarks_hub_screen.dart';
import 'package:qibra_ai/core/design_system/qibra_colors.dart';

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
            Text(message ?? 'The requested page does not exist.',
                style: AppTextStyles.bodyMedium.secondary,
                textAlign: TextAlign.center),
            const SizedBox(height: AppSpacing.xl3),
            ElevatedButton(
                onPressed: () => context.go(AppRoutes.home),
                child: const Text('Go to Home')),
          ],
        ),
      ),
    );
  }
}

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
          builder: (context, state) => const SplashScreen()),
      GoRoute(
          path: AppRoutes.onboarding,
          name: 'onboarding',
          builder: (context, state) => const OnboardingScreen()),
      GoRoute(
          path: AppRoutes.login,
          name: 'login',
          builder: (context, state) => const LoginScreen()),
      GoRoute(
          path: AppRoutes.register,
          name: 'register',
          builder: (context, state) => const RegisterScreen()),
      GoRoute(
          path: AppRoutes.forgotPassword,
          name: 'forgot-password',
          builder: (context, state) => const ForgotPasswordScreen()),
      GoRoute(
          path: AppRoutes.verifyOtp,
          name: 'verify-otp',
          builder: (context, state) =>
              VerifyOtpScreen(email: state.uri.queryParameters['email'])),
      GoRoute(
          path: AppRoutes.profileSetup,
          name: 'profile-setup',
          builder: (context, state) => const ProfileSetupScreen()),
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
          onHomeTap: () => context.go(AppRoutes.home),
          onQuranTap: () => context.go(AppRoutes.quran),
          onPrayerTap: () => context.go(AppRoutes.prayer),
          onHadithTap: () => context.go(AppRoutes.hadith),
          onAiTap: () => context.go(AppRoutes.aiChat),
          onMoreTap: () => context.go(AppRoutes.more),
          child: child,
        ),
        routes: [
          GoRoute(
              path: AppRoutes.home,
              name: 'home',
              builder: (context, state) => const HomeScreen()),
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
                  builder: (context, state) => const SurahListScreen()),
              GoRoute(
                  path: 'search',
                  name: 'quran-search',
                  builder: (context, state) => const QuranSearchScreen()),
              GoRoute(
                  path: 'bookmarks',
                  name: 'quran-bookmarks',
                  builder: (context, state) => const BookmarksHubScreen()),
            ],
          ),
          GoRoute(
              path: AppRoutes.prayer,
              name: 'prayer',
              builder: (context, state) => const PrayerTimesScreen()),
          GoRoute(
              path: AppRoutes.prayerSchedule,
              name: 'prayer-schedule',
              builder: (context, state) => const SalahScheduleScreen()),
          GoRoute(
              path: AppRoutes.prayerStatistics,
              name: 'prayer-statistics',
              builder: (context, state) => const PrayerStatisticsScreen()),
          GoRoute(
              path: AppRoutes.tahajjud,
              name: 'tahajjud',
              builder: (context, state) => const TahajjudDetailsScreen()),
          GoRoute(
              path: AppRoutes.qibla,
              name: 'qibla',
              builder: (context, state) => const QiblaScreen()),
          GoRoute(
              path: AppRoutes.tasbih,
              name: 'tasbih',
              builder: (context, state) => const TasbihScreen()),
          GoRoute(
            path: AppRoutes.hadith,
            name: 'hadith',
            builder: (context, state) => const HadithScreen(),
            routes: [
              GoRoute(
                path: 'book/:slug',
                name: 'hadith-book',
                builder: (context, state) {
                  final slug = state.pathParameters['slug'] ?? 'bukhari';
                  final db = HadithDatabaseService();
                  final bookInfo = db.getBookInfo(slug);
                  return HadithBookScreen(
                    book: HadithBook(
                      id: slug,
                      slug: slug,
                      name: bookInfo?.name ?? 'Hadith Collection',
                      nameArabic: '',
                      author: 'Islamic Scholar',
                      authorArabic: '',
                      totalHadiths: bookInfo?.totalHadiths ?? 0,
                      totalChapters: bookInfo?.sections.length ?? 0,
                      description: 'Authentic Hadith Collection',
                      color: QibraColors.of(context).primary,
                    ),
                  );
                },
              ),
            ],
          ),
          GoRoute(
              path: AppRoutes.aiChat,
              name: 'ai-chat',
              builder: (context, state) => const AIExplainScreen()),
          GoRoute(
              path: AppRoutes.dua,
              name: 'dua',
              builder: (context, state) => const DuasHomeScreen()),
          GoRoute(
              path: AppRoutes.islamicCalendar,
              name: 'islamic-calendar',
              builder: (context, state) => const IslamicCalendarScreen()),
          GoRoute(
              path: AppRoutes.mosques,
              name: 'mosques',
              builder: (context, state) => const MosqueFinderScreen()),
          GoRoute(
              path: AppRoutes.profile,
              name: 'profile',
              builder: (context, state) => const UserProfileScreen()),
          GoRoute(
              path: '/quran/tafseer',
              name: 'tafseer',
              builder: (context, state) => const TafseerScreen(surahNumber: 1)),
          GoRoute(
              path: AppRoutes.more,
              name: 'more',
              builder: (context, state) => const MoreScreen()),
          GoRoute(
              path: AppRoutes.bookmarks,
              name: 'bookmarks',
              builder: (context, state) => const BookmarksHubScreen()),
          GoRoute(
              path: AppRoutes.settings,
              name: 'settings',
              builder: (context, state) => const SettingsScreen()),
          GoRoute(
              path: '/tools',
              name: 'tools',
              builder: (context, state) => const ToolsHubScreen()),
          GoRoute(
              path: '/tools/zakat',
              name: 'tools-zakat',
              builder: (context, state) => const ZakatCalculatorScreen()),
          GoRoute(
              path: '/tools/dhikr',
              name: 'tools-dhikr',
              builder: (context, state) => const TasbihScreen()),
          GoRoute(
              path: '/tools/sadaqah',
              name: 'tools-sadaqah',
              builder: (context, state) => const SadaqahTrackerScreen()),
          GoRoute(
              path: '/tools/habits',
              name: 'tools-habits',
              builder: (context, state) => const HabitTrackerScreen()),
          GoRoute(
              path: '/tools/ramadan',
              name: 'tools-ramadan',
              builder: (context, state) => const RamadanTimerScreen()),
          GoRoute(
              path: '/tools/hajj',
              name: 'tools-hajj',
              builder: (context, state) => const HajjGuideScreen()),
          GoRoute(
              path: '/tools/umrah',
              name: 'tools-umrah',
              builder: (context, state) => const UmrahGuideScreen()),
          GoRoute(
              path: '/tools/nikah',
              name: 'tools-nikah',
              builder: (context, state) => const NikahGuideScreen()),
          GoRoute(
              path: '/tools/asma',
              name: 'tools-asma',
              builder: (context, state) => const AsmaUlHusnaScreen()),
          GoRoute(
              path: '/tools/halal',
              name: 'tools-halal',
              builder: (context, state) => const HalalScannerScreen()),
          GoRoute(
              path: '/tools/names',
              name: 'tools-names',
              builder: (context, state) => const IslamicNameFinderScreen()),
          GoRoute(
              path: '/tools/inheritance',
              name: 'tools-inheritance',
              builder: (context, state) => const InheritanceCalculatorScreen()),
          GoRoute(
              path: '/settings/notifications',
              name: 'notification-settings',
              builder: (context, state) => const NotificationSettingsScreen()),
        ],
      ),
    ],
  );
});

class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen<AuthState>(authProvider, (_, __) => notifyListeners());
    ref.listen<bool>(onboardingProvider, (_, __) => notifyListeners());
  }
}
