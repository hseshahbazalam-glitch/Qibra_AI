// lib/features/home/presentation/home_screen.dart
// ============================================================
// QIBRA AI — HOME DASHBOARD (v8.1 — Audio Fixed)
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:qibra_ai/core/constants/app_constants.dart';
import 'package:qibra_ai/core/design_system/app_colors.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';
import 'package:qibra_ai/core/providers/auth_provider.dart';
import 'package:qibra_ai/features/quran/data/services/quran_audio_service.dart';
import 'package:qibra_ai/features/quran/presentation/widgets/quran_audio_player_sheet.dart';

import '../../quran/presentation/quran_search_screen.dart';
import '../../quran/presentation/surah_reader_screen.dart';
import '../../quran/presentation/bookmarks_screen.dart';
import '../../prayer/providers/prayer_provider.dart';
import '../../prayer/data/models/prayer_models.dart';
import 'package:qibra_ai/features/quran/providers/quran_provider.dart'
    hide readingProgressProvider;
import 'package:qibra_ai/features/quran/providers/reading_progress_provider.dart';
import 'package:qibra_ai/features/quran/data/models/quran_models.dart';
import 'package:qibra_ai/shared/widgets/cards/app_recent_surah_card.dart';
import 'package:qibra_ai/shared/widgets/badges/app_ornamental_star_badge.dart';

// ── Split Widgets ──
import 'widgets/golden_watermark.dart';
import 'widgets/hadith_card.dart';
import 'widgets/bottom_features.dart';
import 'widgets/quick_access_section.dart';
import 'widgets/daily_progress_section.dart';
import 'widgets/nearby_mosques_section.dart';
import 'widgets/feature_grid_section.dart';
import 'widgets/error_empty_states.dart';

// ============================================================
// PRAYER TYPE UI HELPERS
// ============================================================

extension PrayerTypeUIHelpers on PrayerType {
  String get displayName => switch (this) {
        PrayerType.fajr => 'Fajr',
        PrayerType.sunrise => 'Sunrise',
        PrayerType.dhuhr => 'Dhuhr',
        PrayerType.asr => 'Asr',
        PrayerType.maghrib => 'Maghrib',
        PrayerType.isha => 'Isha',
      };

  String get arabicName => switch (this) {
        PrayerType.fajr => '\u0627\u0644\u0641\u064E\u062C\u0631',
        PrayerType.sunrise => '\u0627\u0644\u0634\u0631\u0648\u0642',
        PrayerType.dhuhr => '\u0627\u0644\u0638\u064F\u0647\u0631',
        PrayerType.asr => '\u0627\u0644\u0639\u064E\u0635\u0631',
        PrayerType.maghrib => '\u0627\u0644\u0645\u064E\u063A\u0631\u0628',
        PrayerType.isha => '\u0627\u0644\u0639\u0650\u0634\u064E\u0627\u0621',
      };

  Color get uiColor => switch (this) {
        PrayerType.fajr => const Color(0xFFF59E0B),
        PrayerType.sunrise => const Color(0xFFFCD34D),
        PrayerType.dhuhr => const Color(0xFFFBBF24),
        PrayerType.asr => const Color(0xFF00A86B),
        PrayerType.maghrib => const Color(0xFF7C3AED),
        PrayerType.isha => const Color(0xFF0891B2),
      };

  IconData get uiIcon => switch (this) {
        PrayerType.fajr => Icons.wb_twilight_rounded,
        PrayerType.sunrise => Icons.wb_sunny_outlined,
        PrayerType.dhuhr => Icons.wb_sunny_rounded,
        PrayerType.asr => Icons.wb_cloudy_rounded,
        PrayerType.maghrib => Icons.nights_stay_rounded,
        PrayerType.isha => Icons.brightness_2_rounded,
      };
}

// ============================================================
// DATA MODELS
// ============================================================

class _AyahOfDay {
  final String arabicText;
  final String translationText;
  final String referenceText;
  final String surahNameText;
  const _AyahOfDay({
    required this.arabicText,
    required this.translationText,
    required this.referenceText,
    required this.surahNameText,
  });
}

class _PrayerInfo {
  final String name;
  final String nameArabic;
  final String time;
  final IconData icon;
  final Color color;
  const _PrayerInfo({
    required this.name,
    required this.nameArabic,
    required this.time,
    required this.icon,
    required this.color,
  });
}

class _RamadanInfo {
  final bool isRamadanActive;
  final int daysRemaining;
  final int currentRamadanDay;
  final String sehriTime;
  final String iftarTime;
  final String hijriRamadanDate;
  const _RamadanInfo({
    required this.isRamadanActive,
    required this.daysRemaining,
    required this.currentRamadanDay,
    required this.sehriTime,
    required this.iftarTime,
    required this.hijriRamadanDate,
  });
}

// ============================================================
// STATIC DATA
// ============================================================

const List<_AyahOfDay> _allAyahsList = [
  _AyahOfDay(
    arabicText:
        '\u0625\u0650\u0646\u0651\u064E \u0627\u0644\u0635\u0651\u064E\u0644\u064E\u0627\u0629\u064E \u062A\u064E\u0646\u0652\u0647\u064E\u0649\u0670 \u0639\u064E\u0646\u0650 \u0627\u0644\u0652\u0641\u064E\u062D\u0652\u0634\u064E\u0627\u0621\u0650 \u0648\u064E\u0627\u0644\u0652\u0645\u064F\u0646\u0643\u064E\u0631\u0650',
    translationText:
        'Indeed, prayer restrains from immorality and wrong doing.',
    referenceText: '29:45',
    surahNameText: 'Surah Al-Ankabut',
  ),
  _AyahOfDay(
    arabicText:
        '\u0625\u0650\u0646\u0651\u064E \u0645\u064E\u0639\u064E \u0627\u0644\u0652\u0639\u064F\u0633\u0652\u0631\u0650 \u064A\u064F\u0633\u0652\u0631\u064B\u0627',
    translationText: 'Indeed, with hardship comes ease.',
    referenceText: '94:6',
    surahNameText: 'Surah Ash-Sharh',
  ),
  _AyahOfDay(
    arabicText:
        '\u0631\u064E\u0628\u0651\u0650 \u0632\u0650\u062F\u0652\u0646\u0650\u064A \u0639\u0650\u0644\u0652\u0645\u064B\u0627',
    translationText: 'My Lord, increase me in knowledge.',
    referenceText: '20:114',
    surahNameText: 'Surah Taha',
  ),
  _AyahOfDay(
    arabicText:
        '\u0648\u064E\u0645\u064E\u0646 \u064A\u064E\u062A\u0651\u064E\u0642\u0650 \u0627\u0644\u0644\u0651\u064E\u0647\u064E \u064A\u064E\u062C\u0652\u0639\u064E\u0644 \u0644\u0651\u064E\u0647\u064F \u0645\u064E\u062E\u0652\u0631\u064E\u062C\u064B\u0627',
    translationText:
        'And whoever fears Allah \u2014 He will make for him a way out.',
    referenceText: '65:2',
    surahNameText: 'Surah At-Talaq',
  ),
  _AyahOfDay(
    arabicText:
        '\u0627\u0644\u0644\u0651\u064E\u0647\u064F \u0646\u064F\u0648\u0631\u064F \u0627\u0644\u0633\u0651\u064E\u0645\u064E\u0627\u0648\u064E\u0627\u062A\u0650 \u0648\u064E\u0627\u0644\u0652\u0623\u064E\u0631\u0652\u0636\u0650',
    translationText: 'Allah is the Light of the heavens and the earth.',
    referenceText: '24:35',
    surahNameText: 'Surah An-Nur',
  ),
];

const List<_PrayerInfo> _allPrayers = [
  _PrayerInfo(
      name: 'Fajr',
      nameArabic: '\u0627\u0644\u0652\u0641\u064E\u062C\u0652\u0631',
      time: '5:12 AM',
      icon: Icons.wb_twilight_rounded,
      color: Color(0xFFF59E0B)),
  _PrayerInfo(
      name: 'Dhuhr',
      nameArabic: '\u0627\u0644\u0638\u064F\u0651\u0647\u0652\u0631',
      time: '12:30 PM',
      icon: Icons.wb_sunny_rounded,
      color: Color(0xFFFBBF24)),
  _PrayerInfo(
      name: 'Asr',
      nameArabic: '\u0627\u0644\u0652\u0639\u064E\u0635\u0652\u0631',
      time: '3:45 PM',
      icon: Icons.wb_cloudy_rounded,
      color: Color(0xFF00A86B)),
  _PrayerInfo(
      name: 'Maghrib',
      nameArabic:
          '\u0627\u0644\u0652\u0645\u064E\u063A\u0652\u0631\u0650\u0628',
      time: '6:52 PM',
      icon: Icons.nights_stay_rounded,
      color: Color(0xFF7C3AED)),
  _PrayerInfo(
      name: 'Isha',
      nameArabic: '\u0627\u0644\u0652\u0639\u0650\u0634\u064E\u0627\u0621',
      time: '8:15 PM',
      icon: Icons.brightness_2_rounded,
      color: Color(0xFF0891B2)),
];

const List<RecentSurahItem> _fallbackRecentSurahs = [
  RecentSurahItem(
      surahNumber: 1,
      surahName: 'Al-Fatihah',
      versesCount: 7,
      surahNameArabic: '\u0627\u0644\u0641\u0627\u062A\u062D\u0629',
      revelationType: SurahRevelationType.makki),
  RecentSurahItem(
      surahNumber: 2,
      surahName: 'Al-Baqarah',
      versesCount: 286,
      surahNameArabic: '\u0627\u0644\u0628\u0642\u0631\u0629',
      revelationType: SurahRevelationType.madani),
  RecentSurahItem(
      surahNumber: 18,
      surahName: 'Al-Kahf',
      versesCount: 110,
      surahNameArabic: '\u0627\u0644\u0643\u0647\u0641',
      revelationType: SurahRevelationType.makki),
  RecentSurahItem(
      surahNumber: 36,
      surahName: 'Ya-Sin',
      versesCount: 83,
      surahNameArabic: '\u064A\u0633',
      revelationType: SurahRevelationType.makki),
];

const _RamadanInfo _currentRamadanInfo = _RamadanInfo(
  isRamadanActive: false,
  daysRemaining: 87,
  currentRamadanDay: 0,
  sehriTime: '4:22 AM',
  iftarTime: '6:52 PM',
  hijriRamadanDate: '1 Ramadan 1447 AH',
);

// ============================================================
// HOME SCREEN
// ============================================================

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  Timer? _ayahRotationTimer;
  late final AnimationController _headerAnimationController;
  late final AnimationController _cardStaggerController;
  late final AnimationController _pulseAnimationController;
  late final AnimationController _ayahFadeController;
  late final Animation<double> _headerFadeAnimation;
  late final Animation<Offset> _headerSlideAnimation;
  late final Animation<double> _pulseScaleAnimation;
  late final Animation<double> _ayahFadeAnimation;

  int _currentAyahIndex = 0;
  bool _hasLoadingError = false;
  bool _isContentEmpty = false;
  final ScrollController _scrollController = ScrollController();

  static const int _streakDays = 12;
  static const String _temperature = '21\u00B0C';
  static const String _weatherCondition = 'Clear Sky';

  _AyahOfDay get _currentAyahFallback => _allAyahsList[_currentAyahIndex];

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
    _ayahRotationTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) _changeAyah();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _detectLocation();
    });
  }

  Future<void> _detectLocation() async {
    final locationState = ref.read(locationProvider);
    if (locationState.location == null) {
      debugPrint('🌍 Fetching location on home load...');
      try {
        await ref
            .read(locationProvider.notifier)
            .fetchCurrentLocation()
            .timeout(const Duration(seconds: 20));
      } catch (e) {
        debugPrint('⚠️ Location timeout - using Makkah default');
        await ref.read(locationProvider.notifier).resetToDefault();
      }
    }
  }

  void _initAnimations() {
    _headerAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 800));
    _cardStaggerController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _pulseAnimationController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2000))
      ..repeat(reverse: true);
    _ayahFadeController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));

    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
            parent: _headerAnimationController, curve: Curves.easeOut));
    _headerSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _headerAnimationController,
                curve: Curves.easeOutCubic));
    _pulseScaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
        CurvedAnimation(
            parent: _pulseAnimationController, curve: Curves.easeInOut));
    _ayahFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _ayahFadeController, curve: Curves.easeIn));
  }

  void _startAnimations() {
    _headerAnimationController.forward();
    _ayahFadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _cardStaggerController.forward();
    });
  }

  void _changeAyah() {
    _ayahFadeController.reverse().then((_) {
      if (!mounted) return;
      setState(() =>
          _currentAyahIndex = (_currentAyahIndex + 1) % _allAyahsList.length);
      _ayahFadeController.forward();
    });
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.mediumImpact();
    setState(() => _hasLoadingError = false);
    ref.invalidate(autoRotatingAyahProvider);
    ref.invalidate(popularSurahsProvider);
    ref.invalidate(dailyPrayerTimesProvider);
    ref.invalidate(nextPrayerProvider);
    ref.invalidate(readingProgressProvider);
    await Future.delayed(const Duration(milliseconds: 1500));
  }

  void _clearSpecialState() {
    setState(() {
      _hasLoadingError = false;
      _isContentEmpty = false;
    });
  }

  // ─── Audio Play Helper ────────────────────────────────────
  void _playAudio(int surahNumber, String surahName) async {
    HapticFeedback.heavyImpact();
    await QuranAudioService.instance.playSurah(surahNumber, surahName);
    if (mounted) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (_) => const QuranAudioPlayerSheet(),
      );
    }
  }

  String _getDayName(int w) => [
        'Monday',
        'Tuesday',
        'Wednesday',
        'Thursday',
        'Friday',
        'Saturday',
        'Sunday'
      ][w - 1];

  String _getMonthShort(int m) => [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'May',
        'Jun',
        'Jul',
        'Aug',
        'Sep',
        'Oct',
        'Nov',
        'Dec'
      ][m - 1];

  @override
  void dispose() {
    _ayahRotationTimer?.cancel();
    _headerAnimationController.dispose();
    _cardStaggerController.dispose();
    _pulseAnimationController.dispose();
    _ayahFadeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ============================================================
  // BUILD METHOD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final String userName = ref.watch(userDisplayNameProvider);

    if (_hasLoadingError) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: HomeErrorState(onRetry: _clearSpecialState),
      );
    }

    if (_isContentEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: HomeEmptyState(onGetStarted: _clearSpecialState),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        displacement: 60,
        strokeWidth: 2.5,
        onRefresh: _handleRefresh,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            SliverPadding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + AppSpacing.md,
                bottom: 120,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildHeroHeader(userName),
                  const SizedBox(height: AppSpacing.lg),
                  _buildPrayerCountdownCard(),
                  const SizedBox(height: AppSpacing.md),
                  _buildAllPrayersStrip(),
                  const SizedBox(height: AppSpacing.xl2),
                  const HomeDailyProgressSection(),
                  const SizedBox(height: AppSpacing.xl2),
                  _buildDailyVerseSection(),
                  const SizedBox(height: AppSpacing.xl2),
                  _buildReadingStreakCard(),
                  const SizedBox(height: AppSpacing.xl2),
                  _buildSectionHeader(
                      title: 'RAMADAN', icon: Icons.nightlight_round),
                  const SizedBox(height: AppSpacing.md),
                  _buildRamadanWidget(),
                  const SizedBox(height: AppSpacing.xl2),
                  const HomeQuickAccessSection(),
                  const SizedBox(height: AppSpacing.xl2),
                  _buildQuranSectionHeader(),
                  const SizedBox(height: AppSpacing.md),
                  _buildContinueReadingCard(),
                  const SizedBox(height: AppSpacing.md),
                  _buildQuranStatsRow(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildPopularSurahsList(),
                  const SizedBox(height: AppSpacing.xl2),
                  _buildSectionHeader(
                      title: 'NEARBY MOSQUES', icon: Icons.mosque_rounded),
                  const SizedBox(height: AppSpacing.md),
                  const HomeNearbyMosquesSection(),
                  const SizedBox(height: AppSpacing.xl2),
                  _buildSectionHeader(
                      title: 'HADITH OF THE DAY',
                      icon: Icons.format_quote_rounded),
                  const SizedBox(height: AppSpacing.md),
                  const HomeHadithCard(),
                  const SizedBox(height: AppSpacing.xl3),
                  _buildSectionHeader(
                      title: 'ALL FEATURES', icon: Icons.apps_rounded),
                  const SizedBox(height: AppSpacing.md),
                  const HomeFeatureGrid(),
                  const SizedBox(height: AppSpacing.xl2),
                  _buildIslamicToolsBanner(),
                  const SizedBox(height: AppSpacing.xl2),
                  const HomeBottomFeatures(),
                  const SizedBox(height: AppSpacing.xl3),
                  const GoldenArabicWatermark(),
                  const SizedBox(height: AppSpacing.xl6),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ISLAMIC TOOLS BANNER
  // ============================================================

  Widget _buildIslamicToolsBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          context.push('/tools');
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1B4332),
                Color(0xFF2D6A4F),
                Color(0xFF1B4332),
              ],
            ),
            borderRadius: AppRadius.cardRadiusLarge,
            border: Border.all(
              color: const Color(0xFF52B788).withValues(alpha: 0.35),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF52B788).withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF52B788).withValues(alpha: 0.20),
                        borderRadius: AppRadius.pillRadius,
                        border: Border.all(
                          color:
                              const Color(0xFF52B788).withValues(alpha: 0.40),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.apps_rounded,
                            color: Color(0xFF52B788),
                            size: 10,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'ISLAMIC TOOLS',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: const Color(0xFF52B788),
                              fontWeight: FontWeight.w800,
                              fontSize: 9,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Your Islamic\nToolkit',
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Zakat • Hajj • Ramadan • Habits',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(
                        color: const Color(0xFF52B788),
                        borderRadius: AppRadius.pillRadius,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Explore Tools',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.arrow_forward_rounded,
                            color: Colors.white,
                            size: 12,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Column(
                children: [
                  Row(
                    children: [
                      _toolEmoji('💚'),
                      const SizedBox(width: 8),
                      _toolEmoji('🕋'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _toolEmoji('🌙'),
                      const SizedBox(width: 8),
                      _toolEmoji('📿'),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _toolEmoji(String emoji) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF52B788).withValues(alpha: 0.20),
        ),
      ),
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 20)),
      ),
    );
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================

  Widget _buildSectionHeader(
      {required String title, required IconData icon, Widget? trailingWidget}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          Container(
              width: 3,
              height: 14,
              decoration: BoxDecoration(
                  gradient: AppGradients.gold,
                  borderRadius: AppRadius.pillRadius)),
          const SizedBox(width: AppSpacing.sm),
          Icon(icon, color: AppColors.accent, size: 16),
          const SizedBox(width: AppSpacing.xs),
          Text(title,
              style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.accent,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w700)),
          if (trailingWidget != null) ...[const Spacer(), trailingWidget],
        ],
      ),
    );
  }

  // ============================================================
  // HERO HEADER
  // ============================================================

  Widget _buildHeroHeader(String userName) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: FadeTransition(
        opacity: _headerFadeAnimation,
        child: SlideTransition(
          position: _headerSlideAnimation,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: AppRadius.cardRadiusLarge,
              boxShadow: [
                BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8))
              ],
            ),
            child: ClipRRect(
              borderRadius: AppRadius.cardRadiusLarge,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/hero/mosque_night.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      decoration: const BoxDecoration(
                          gradient: LinearGradient(colors: [
                        Color(0xFF0A2540),
                        Color(0xFF1A3A5C),
                        Color(0xFF00A86B)
                      ])),
                    ),
                  ),
                  Container(
                      decoration: BoxDecoration(
                          gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                        Colors.black.withValues(alpha: 0.30),
                        Colors.black.withValues(alpha: 0.60)
                      ]))),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Assalamu Alaikum',
                                style: AppTextStyles.labelSmall.copyWith(
                                    color:
                                        AppColors.white.withValues(alpha: 0.90),
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.5)),
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (_) => const QuranSearchScreen()));
                              },
                              child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                      color: AppColors.white
                                          .withValues(alpha: 0.20),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                          color: AppColors.white
                                              .withValues(alpha: 0.30))),
                                  child: const Icon(Icons.search_rounded,
                                      color: AppColors.white, size: 20)),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text('QIBRA AI',
                            style: AppTextStyles.headlineLarge.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2.0,
                                height: 1.0,
                                fontSize: 28)),
                        const SizedBox(height: 2),
                        Text('Your Islamic Companion',
                            style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                                fontStyle: FontStyle.italic)),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(Icons.location_on_rounded,
                                color: AppColors.white, size: 11),
                            const SizedBox(width: 3),
                            Flexible(
                                flex: 2,
                                child: Text(
                                    ref
                                            .watch(locationProvider)
                                            .location
                                            ?.displayName ??
                                        'Detecting...',
                                    style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 9),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis)),
                            const SizedBox(width: 8),
                            const Icon(Icons.wb_sunny_rounded,
                                color: AppColors.accent, size: 11),
                            const SizedBox(width: 3),
                            Flexible(
                                flex: 2,
                                child: Text(
                                    '$_temperature \u00B7 $_weatherCondition',
                                    style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.accent,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 9),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis)),
                            const SizedBox(width: 8),
                            Flexible(
                                flex: 3,
                                child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('15 Rabi al-Thani 1446 AH',
                                          style: AppTextStyles.labelSmall
                                              .copyWith(
                                                  color: AppColors.white,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 8),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                      Text(
                                          '${_getDayName(DateTime.now().weekday)}, ${DateTime.now().day} ${_getMonthShort(DateTime.now().month)} ${DateTime.now().year}',
                                          style: AppTextStyles.labelSmall
                                              .copyWith(
                                                  color: AppColors.white
                                                      .withValues(alpha: 0.75),
                                                  fontSize: 8),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis),
                                    ])),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // PRAYER COUNTDOWN
  // ============================================================

  Widget _buildPrayerCountdownCard() {
    final nextPrayerInfo = ref.watch(nextPrayerProvider);
    final dailyTimes = ref.watch(dailyPrayerTimesProvider);
    final displayType = nextPrayerInfo?.prayer.type ?? PrayerType.asr;
    final displayTime = nextPrayerInfo?.prayer.formattedTime ?? '--:-- --';
    final displayCountdown = nextPrayerInfo?.countdown ?? Duration.zero;
    final sunriseTime = dailyTimes?.sunrise.formattedTime ?? '--:-- --';
    final sunsetTime = dailyTimes?.maghrib.formattedTime ?? '--:-- --';

    final s = displayCountdown.inSeconds.abs();
    final formatted =
        '${(s ~/ 3600).toString().padLeft(2, '0')}:${((s % 3600) ~/ 60).toString().padLeft(2, '0')}:${(s % 60).toString().padLeft(2, '0')}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          context.go(AppRoutes.prayer);
        },
        child: ScaleTransition(
          scale: _pulseScaleAnimation,
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [
                Color(0xFF00A86B),
                Color(0xFF007A4D),
                Color(0xFF005C39)
              ]),
              borderRadius: AppRadius.cardRadiusLarge,
              boxShadow: [
                BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.45),
                    blurRadius: 24,
                    offset: const Offset(0, 8))
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                  color:
                                      AppColors.white.withValues(alpha: 0.20),
                                  borderRadius: AppRadius.buttonRadius),
                              child: const Icon(
                                  Icons.access_time_filled_rounded,
                                  color: AppColors.white,
                                  size: 12)),
                          const SizedBox(width: 6),
                          Text('NEXT PRAYER',
                              style: AppTextStyles.labelSmall.copyWith(
                                  color:
                                      AppColors.white.withValues(alpha: 0.90),
                                  letterSpacing: 2.0,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10)),
                        ]),
                        Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                                color: AppColors.white.withValues(alpha: 0.20),
                                borderRadius: AppRadius.pillRadius),
                            child:
                                Row(mainAxisSize: MainAxisSize.min, children: [
                              Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                      color: Color(0xFF10B981),
                                      shape: BoxShape.circle)),
                              const SizedBox(width: 4),
                              Text('Live',
                                  style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10))
                            ])),
                      ]),
                  const SizedBox(height: AppSpacing.md),
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text(displayType.displayName,
                        style: AppTextStyles.displaySmall.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                            fontSize: 40)),
                    const SizedBox(width: 8),
                    Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(displayType.arabicName,
                            style: const TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: 22,
                                color: AppColors.white,
                                fontWeight: FontWeight.w600,
                                height: 1.0),
                            textDirection: TextDirection.rtl)),
                  ]),
                  const SizedBox(height: 4),
                  Text('at $displayTime',
                      style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.white.withValues(alpha: 0.75))),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: AppColors.background.withValues(alpha: 0.40),
                          borderRadius: AppRadius.buttonRadius,
                          border: Border.all(
                              color: AppColors.white.withValues(alpha: 0.25))),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.timer_outlined,
                            color: AppColors.white, size: 12),
                        const SizedBox(width: 4),
                        Text(formatted,
                            style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'monospace',
                                letterSpacing: 1.0,
                                fontSize: 13))
                      ])),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildSunTime(
                            Icons.wb_twilight_rounded, 'Sunrise', sunriseTime),
                        _buildSunTime(
                            Icons.nights_stay_rounded, 'Sunset', sunsetTime),
                      ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSunTime(IconData icon, String label, String time) {
    return Row(children: [
      Icon(icon, color: AppColors.white.withValues(alpha: 0.85), size: 14),
      const SizedBox(width: 5),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.white.withValues(alpha: 0.70), fontSize: 9)),
        Text(time,
            style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11)),
      ]),
    ]);
  }

  // ============================================================
  // PRAYER STRIP
  // ============================================================

  Widget _buildAllPrayersStrip() {
    final dailyTimes = ref.watch(dailyPrayerTimesProvider);
    final nextPrayerInfo = ref.watch(nextPrayerProvider);

    if (dailyTimes == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
            children: List.generate(_allPrayers.length, (i) {
          final p = _allPrayers[i];
          return Expanded(
              child: Padding(
                  padding: EdgeInsets.only(
                      right: i == _allPrayers.length - 1 ? 0 : 6),
                  child: _buildPrayerPill(p, i == 2, i < 2)));
        })),
      );
    }

    final prayers = [
      dailyTimes.fajr,
      dailyTimes.dhuhr,
      dailyTimes.asr,
      dailyTimes.maghrib,
      dailyTimes.isha
    ];
    final nextType = nextPrayerInfo?.prayer.type;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
          children: List.generate(prayers.length, (i) {
        final pt = prayers[i];
        final isNext = pt.type == nextType;
        final isDone = pt.isPast(DateTime.now()) && !isNext;
        final info = _PrayerInfo(
            name: pt.type.displayName,
            nameArabic: pt.type.arabicName,
            time: pt.formattedTime,
            icon: pt.type.uiIcon,
            color: pt.type.uiColor);
        return Expanded(
            child: Padding(
                padding:
                    EdgeInsets.only(right: i == prayers.length - 1 ? 0 : 6),
                child: _buildPrayerPill(info, isNext, isDone)));
      })),
    );
  }

  Widget _buildPrayerPill(_PrayerInfo p, bool isNext, bool isDone) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        context.go(AppRoutes.prayer);
      },
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: isNext
              ? LinearGradient(
                  colors: [p.color, p.color.withValues(alpha: 0.70)])
              : null,
          color: isNext ? null : AppColors.surface,
          borderRadius: AppRadius.cardRadius,
          border: Border.all(
              color: isNext
                  ? Colors.transparent
                  : isDone
                      ? p.color.withValues(alpha: 0.30)
                      : AppColors.borderSubtle),
          boxShadow: isNext
              ? [
                  BoxShadow(
                      color: p.color.withValues(alpha: 0.40),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ]
              : null,
        ),
        child: Column(children: [
          Icon(isDone ? Icons.check_circle_rounded : p.icon,
              size: 16,
              color: isNext
                  ? AppColors.white
                  : isDone
                      ? p.color
                      : AppColors.iconSecondary),
          const SizedBox(height: 3),
          Text(p.name,
              style: AppTextStyles.labelSmall.copyWith(
                  color: isNext
                      ? AppColors.white
                      : isDone
                          ? p.color
                          : AppColors.textSecondary,
                  fontWeight: isNext ? FontWeight.w700 : FontWeight.w600,
                  fontSize: 10)),
          const SizedBox(height: 1),
          Text(p.time,
              style: AppTextStyles.labelSmall.copyWith(
                  color: isNext
                      ? AppColors.white.withValues(alpha: 0.85)
                      : AppColors.textTertiary,
                  fontSize: 9,
                  fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  // ============================================================
  // DAILY VERSE
  // ============================================================

  Widget _buildDailyVerseSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Consumer(builder: (context, ref, _) {
        final ayahAsync = ref.watch(autoRotatingAyahProvider);
        return ayahAsync.when(
          data: (ayah) => ayah != null
              ? _buildVerseCard(ayah.text, ayah.translation ?? 'Loading...',
                  'Ayah ${ayah.number}')
              : _buildVerseCard(
                  _currentAyahFallback.arabicText,
                  _currentAyahFallback.translationText,
                  '${_currentAyahFallback.surahNameText} (${_currentAyahFallback.referenceText})'),
          loading: () => _buildVerseCard(
              _currentAyahFallback.arabicText,
              _currentAyahFallback.translationText,
              '${_currentAyahFallback.surahNameText} (${_currentAyahFallback.referenceText})'),
          error: (_, __) => _buildVerseCard(
              _currentAyahFallback.arabicText,
              _currentAyahFallback.translationText,
              '${_currentAyahFallback.surahNameText} (${_currentAyahFallback.referenceText})'),
        );
      }),
    );
  }

  Widget _buildVerseCard(String arabic, String translation, String reference) {
    return FadeTransition(
      opacity: _ayahFadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.cardRadiusLarge,
            border:
                Border.all(color: AppColors.accent.withValues(alpha: 0.25))),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
                width: 3,
                height: 10,
                decoration: BoxDecoration(
                    gradient: AppGradients.gold,
                    borderRadius: AppRadius.pillRadius)),
            const SizedBox(width: 6),
            Text('DAILY VERSE',
                style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.accent,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w700,
                    fontSize: 9))
          ]),
          const SizedBox(height: 8),
          Text(arabic,
              style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 16,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                  height: 1.5),
              textDirection: TextDirection.rtl,
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Text('"$translation"',
              style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                  fontSize: 11,
                  height: 1.4),
              maxLines: 2,
              overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Text('\u2014 $reference',
              style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 10)),
        ]),
      ),
    );
  }

  // ============================================================
  // READING STREAK
  // ============================================================

  Widget _buildReadingStreakCard() {
    final progressState = ref.watch(readingProgressProvider);
    final streak = progressState.streak;
    final displayStreak =
        streak.currentStreak > 0 ? streak.currentStreak : _streakDays;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          context.go(AppRoutes.quran);
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [
              Color(0xFF7C3AED),
              Color(0xFF6D28D9),
              Color(0xFF5B21B6)
            ]),
            borderRadius: AppRadius.cardRadiusLarge,
            boxShadow: [
              BoxShadow(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.40),
                  blurRadius: 20,
                  offset: const Offset(0, 8))
            ],
          ),
          child: Row(children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(children: [
                    Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.20),
                            borderRadius: AppRadius.buttonRadius),
                        child: const Icon(Icons.local_fire_department_rounded,
                            color: AppColors.white, size: 14)),
                    const SizedBox(width: 6),
                    Text('Prayer Streak',
                        style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w700))
                  ]),
                  const SizedBox(height: 12),
                  Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    Text('$displayStreak',
                        style: AppTextStyles.displayLarge.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                            fontSize: 44,
                            letterSpacing: -2.0)),
                    const SizedBox(width: 4),
                    Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text('Days',
                            style: AppTextStyles.titleMedium.copyWith(
                                color: AppColors.white.withValues(alpha: 0.90),
                                fontWeight: FontWeight.w700))),
                  ]),
                  const SizedBox(height: 4),
                  Text(
                      progressState.hasReadToday
                          ? 'MashaAllah! Keep it up! \uD83D\uDD25'
                          : 'Keep it up!',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.white.withValues(alpha: 0.85),
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Row(
                      children: List.generate(7, (i) {
                    final done = i < displayStreak;
                    const days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
                    return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Column(children: [
                          Container(
                              width: 18,
                              height: 18,
                              decoration: BoxDecoration(
                                  color: done
                                      ? AppColors.white
                                      : AppColors.white.withValues(alpha: 0.20),
                                  shape: BoxShape.circle),
                              child: done
                                  ? const Icon(Icons.check_rounded,
                                      color: Color(0xFF7C3AED), size: 12)
                                  : null),
                          const SizedBox(height: 3),
                          Text(days[i],
                              style: AppTextStyles.labelSmall.copyWith(
                                  color:
                                      AppColors.white.withValues(alpha: 0.75),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 8)),
                        ]));
                  })),
                ])),
          ]),
        ),
      ),
    );
  }

  // ============================================================
  // RAMADAN WIDGET
  // ============================================================

  Widget _buildRamadanWidget() {
    const data = _currentRamadanInfo;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          context.go(AppRoutes.islamicCalendar);
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [
              Color(0xFF6B21A8),
              Color(0xFF4C1D95),
              Color(0xFF1E1B4B)
            ]),
            borderRadius: AppRadius.cardRadiusLarge,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl2),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Row(children: [
                  const Icon(Icons.nightlight_round,
                      color: Color(0xFFFFD700), size: 14),
                  const SizedBox(width: 6),
                  Text('RAMADAN',
                      style: AppTextStyles.labelSmall.copyWith(
                          color: const Color(0xFFFFD700),
                          letterSpacing: 2.5,
                          fontWeight: FontWeight.w800))
                ]),
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.15),
                        borderRadius: AppRadius.pillRadius),
                    child: Text('UPCOMING',
                        style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 9))),
              ]),
              const SizedBox(height: AppSpacing.md),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('${data.daysRemaining}',
                    style: AppTextStyles.displayLarge.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                        fontSize: 48)),
                const SizedBox(width: 6),
                Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('days',
                        style: AppTextStyles.titleLarge.copyWith(
                            color: AppColors.white.withValues(alpha: 0.80),
                            fontWeight: FontWeight.w600))),
              ]),
              Text('until Ramadan Mubarak',
                  style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.white.withValues(alpha: 0.75))),
              const SizedBox(height: 4),
              const Text(
                  '\u0631\u064E\u0645\u064E\u0636\u064E\u0627\u0646 \u0645\u064F\u0628\u064E\u0627\u0631\u064E\u0643',
                  style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 18,
                      color: Color(0xFFFFD700),
                      fontWeight: FontWeight.w600),
                  textDirection: TextDirection.rtl),
            ]),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // QURAN SECTION
  // ============================================================

  Widget _buildQuranSectionHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.cardRadius,
            border: Border.all(color: AppColors.borderSubtle)),
        child: Row(children: [
          Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                  gradient: AppGradients.emerald, shape: BoxShape.circle),
              child: const Icon(Icons.menu_book_rounded,
                  color: AppColors.white, size: 18)),
          const SizedBox(width: AppSpacing.sm),
          Text('Quran',
              style: AppTextStyles.titleMedium
                  .copyWith(fontWeight: FontWeight.w800)),
          const Spacer(),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const QuranSearchScreen()));
            },
            child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    shape: BoxShape.circle),
                child: const Icon(Icons.search_rounded,
                    color: AppColors.primary, size: 16)),
          ),
        ]),
      ),
    );
  }

  Widget _buildContinueReadingCard() {
    final ps = ref.watch(readingProgressProvider);
    final cp = ps.currentPage;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          context.push('${AppRoutes.mushafReader}?page=${cp?.pageNumber ?? 1}');
        },
        child: Container(
          decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppRadius.cardRadiusLarge,
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: 0.25))),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: AppRadius.pillRadius),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.bookmark_rounded,
                          color: AppColors.primary, size: 10),
                      const SizedBox(width: 3),
                      Text('CONTINUE READING',
                          style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 9,
                              letterSpacing: 1.0))
                    ])),
                const Spacer(),
                Text(cp?.progressText ?? '0.0%',
                    style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 16)),
              ]),
              const SizedBox(height: AppSpacing.md),
              Text(cp?.surahName ?? 'Start Reading',
                  style: AppTextStyles.headlineSmall.copyWith(
                      fontWeight: FontWeight.w900, fontSize: 22, height: 1.2)),
              const SizedBox(height: 2),
              Text(
                  cp != null
                      ? 'Page ${cp.pageNumber} \u2022 Juz ${cp.juzNumber}'
                      : 'Tap to open Mushaf',
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textSecondary)),
              const SizedBox(height: AppSpacing.md),
              Row(children: [
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      ClipRRect(
                          borderRadius: AppRadius.pillRadius,
                          child: LinearProgressIndicator(
                              value: ps.overallProgress,
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: 0.15),
                              valueColor: const AlwaysStoppedAnimation(
                                  AppColors.primary),
                              minHeight: 5)),
                      const SizedBox(height: 4),
                      Text(
                          cp != null
                              ? 'Page ${cp.pageNumber} of 604'
                              : 'Begin your journey',
                          style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textTertiary, fontSize: 10)),
                    ])),
                const SizedBox(width: AppSpacing.md),
                Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                        gradient: AppGradients.emerald,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.40),
                              blurRadius: 12,
                              offset: const Offset(0, 4))
                        ]),
                    child: const Icon(Icons.play_arrow_rounded,
                        color: AppColors.white, size: 28)),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildQuranStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(children: [
        _stat(Icons.menu_book_rounded, '114', 'All Surahs', AppColors.primary,
            () => context.go(AppRoutes.quran)),
        const SizedBox(width: AppSpacing.sm),
        _stat(Icons.book_rounded, '30', 'Juz', AppColors.accent,
            () => context.go(AppRoutes.quran)),
        const SizedBox(width: AppSpacing.sm),
        _stat(
            Icons.description_rounded,
            '604',
            'Pages',
            const Color(0xFF7C3AED),
            () => context.push('${AppRoutes.mushafReader}?page=1')),
        const SizedBox(width: AppSpacing.sm),
        _stat(
            Icons.bookmark_rounded,
            '12',
            'Bookmarks',
            const Color(0xFFEF4444),
            () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const BookmarksScreen()))),
      ]),
    );
  }

  Widget _stat(IconData icon, String value, String label, Color color,
      VoidCallback onTap) {
    return Expanded(
        child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            child: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.cardRadius,
                    border: Border.all(color: color.withValues(alpha: 0.25))),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(height: 4),
                  Text(value,
                      style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          height: 1.0)),
                  const SizedBox(height: 2),
                  Text(label,
                      style: AppTextStyles.labelSmall.copyWith(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: 9)),
                ]))));
  }

  // ============================================================
  // POPULAR SURAHS
  // ============================================================

  Widget _buildPopularSurahsList() {
    return Consumer(builder: (context, ref, _) {
      final async = ref.watch(popularSurahsProvider);
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(children: [
              Container(
                  width: 3,
                  height: 14,
                  decoration: BoxDecoration(
                      gradient: AppGradients.gold,
                      borderRadius: AppRadius.pillRadius)),
              const SizedBox(width: AppSpacing.sm),
              const Icon(Icons.trending_up_rounded,
                  color: AppColors.accent, size: 16),
              const SizedBox(width: 4),
              Text('POPULAR SURAHS',
                  style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.accent,
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.go(AppRoutes.quran);
                  },
                  child: Text('View All',
                      style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 10))),
            ])),
        const SizedBox(height: AppSpacing.md),
        async.when(
          data: (surahs) {
            if (surahs.isEmpty) return _buildFallbackSurahs();
            return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                    children: surahs
                        .take(4)
                        .map((s) => Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: _buildSurahTile(s)))
                        .toList()));
          },
          loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.xl2),
              child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary))),
          error: (_, __) => _buildFallbackSurahs(),
        ),
      ]);
    });
  }

  Widget _buildSurahTile(SurahInfoModel surah) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => SurahReaderScreen(surahNumber: surah.number)));
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.cardRadius,
            border:
                Border.all(color: AppColors.primary.withValues(alpha: 0.20))),
        child: Row(children: [
          AppOrnamentalStarBadge(
              number: surah.number,
              customSize: 44,
              theme: BadgeColorTheme.emerald,
              showGlow: false),
          const SizedBox(width: AppSpacing.md),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Row(children: [
                  Expanded(
                      child: Text(surah.name,
                          style: AppTextStyles.titleSmall.copyWith(
                              fontWeight: FontWeight.w800, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis)),
                  Text(surah.nameArabic,
                      style: const TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 16,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700),
                      textDirection: TextDirection.rtl)
                ]),
                const SizedBox(height: 3),
                Row(children: [
                  Text('${surah.numberOfAyahs} Ayahs',
                      style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textTertiary, fontSize: 10)),
                  const SizedBox(width: 6),
                  Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                          color: (surah.isMeccan
                                  ? AppColors.accent
                                  : AppColors.primary)
                              .withValues(alpha: 0.15),
                          borderRadius: AppRadius.pillRadius),
                      child: Text(surah.isMeccan ? 'Meccan' : 'Medinan',
                          style: AppTextStyles.labelSmall.copyWith(
                              color: surah.isMeccan
                                  ? AppColors.accent
                                  : AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 8)))
                ]),
              ])),
          const SizedBox(width: AppSpacing.sm),
          GestureDetector(
            onTap: () => _playAudio(surah.number, surah.name),
            child: Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                  gradient: AppGradients.emerald, shape: BoxShape.circle),
              child: const Icon(Icons.play_arrow_rounded,
                  color: AppColors.white, size: 20),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildFallbackSurahs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
          children: _fallbackRecentSurahs
              .map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.mediumImpact();
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) =>
                                SurahReaderScreen(surahNumber: s.surahNumber)));
                      },
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: AppRadius.cardRadius,
                            border: Border.all(
                                color:
                                    AppColors.primary.withValues(alpha: 0.20))),
                        child: Row(children: [
                          AppOrnamentalStarBadge(
                              number: s.surahNumber,
                              customSize: 44,
                              theme: BadgeColorTheme.emerald,
                              showGlow: false),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                Row(children: [
                                  Text(s.surahName,
                                      style: AppTextStyles.titleSmall.copyWith(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 14)),
                                  const Spacer(),
                                  Text(s.surahNameArabic ?? '',
                                      style: const TextStyle(
                                          fontFamily: 'Amiri',
                                          fontSize: 16,
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700),
                                      textDirection: TextDirection.rtl)
                                ]),
                                Text('${s.versesCount} Ayahs',
                                    style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.textTertiary,
                                        fontSize: 10)),
                              ])),
                          GestureDetector(
                            onTap: () => _playAudio(s.surahNumber, s.surahName),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                  gradient: AppGradients.emerald,
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.play_arrow_rounded,
                                  color: AppColors.white, size: 20),
                            ),
                          ),
                        ]),
                      ),
                    ),
                  ))
              .toList()),
    );
  }
}
