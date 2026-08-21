// lib/core/router/app_router.dart
// ============================================================
// QIBRA AI – APP ROUTER (Complete)
// Version: 9.0.0 – Islamic Tools Hub Added
// ============================================================
import 'package:qibra_ai/features/prayer/presentation/mosque_finder_screen.dart';
import 'package:qibra_ai/features/calendar/presentation/islamic_calendar_screen.dart';
import 'package:qibra_ai/features/settings/presentation/settings_screen.dart';
import 'package:qibra_ai/features/settings/presentation/user_profile_screen.dart';
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
import 'package:qibra_ai/features/quran/presentation/tafseer_screen.dart';
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
import 'package:qibra_ai/features/home/presentation/home_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final isAuth = authState.isAuthenticated;
      final isSplash = state.matchedLocation == AppRoutes.splash;
      final isOnboarding = state.matchedLocation == AppRoutes.onboarding;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');

      if (isSplash) return null;

      if (!isAuth && !isOnboarding && !isAuthRoute) {
        return null;
      }

      if (isAuth && (isAuthRoute || isOnboarding)) {
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
            debugPrint('🕌 MOSQUE FAB TAP → ${AppRoutes.mosques}');
            context.go(AppRoutes.mosques);
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
                      color: const Color(0xFF00A86B),
                    ),
                  );
                },
              ),
            ],
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
            builder: (context, state) => const MosqueFinderScreen(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            name: 'profile',
            builder: (context, state) => const UserProfileScreen(),
          ),
          GoRoute(
            path: '/quran/tafseer',
            name: 'tafseer',
            builder: (context, state) => const TafseerScreen(),
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
            name: 'tool-zakat',
            builder: (context, state) => const ZakatCalculatorScreen(),
          ),
          GoRoute(
            path: '/tools/dhikr',
            name: 'tool-dhikr',
            builder: (context, state) => const DhikrCounterScreen(),
          ),
          GoRoute(
            path: '/tools/sadaqah',
            name: 'tool-sadaqah',
            builder: (context, state) => const SadaqahTrackerScreen(),
          ),
          GoRoute(
            path: '/tools/habit',
            name: 'tool-habit',
            builder: (context, state) => const HabitTrackerScreen(),
          ),
          GoRoute(
            path: '/tools/ramadan',
            name: 'tool-ramadan',
            builder: (context, state) => const RamadanTimerScreen(),
          ),
          GoRoute(
            path: '/tools/hajj',
            name: 'tool-hajj',
            builder: (context, state) => const HajjGuideScreen(),
          ),
          GoRoute(
            path: '/tools/umrah',
            name: 'tool-umrah',
            builder: (context, state) => const UmrahGuideScreen(),
          ),
          GoRoute(
            path: '/tools/nikah',
            name: 'tool-nikah',
            builder: (context, state) => const NikahGuideScreen(),
          ),
          GoRoute(
            path: '/tools/halal',
            name: 'tool-halal',
            builder: (context, state) => const HalalScannerScreen(),
          ),
          GoRoute(
            path: '/tools/asma-ul-husna',
            name: 'tool-asma-ul-husna',
            builder: (context, state) => const AsmaUlHusnaScreen(),
          ),
          GoRoute(
            path: '/tools/names',
            name: 'tool-names',
            builder: (context, state) => const IslamicNameFinderScreen(),
          ),
          GoRoute(
            path: '/tools/inheritance',
            name: 'tool-inheritance',
            builder: (context, state) => const InheritanceCalculatorScreen(),
          ),
        ],
      ),
    ],
  );
});
