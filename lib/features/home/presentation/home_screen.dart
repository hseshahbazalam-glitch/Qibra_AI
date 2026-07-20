// lib/features/home/presentation/home_screen.dart
// ============================================================
// QIBRA AI — HOME DASHBOARD (Clean v7.0)
// Removed: unused fields, methods, duplicates
// Fixed: All onTap handlers connected to real routes
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// ── Core ─────────────────────────────────────────────────
import 'package:qibra_ai/core/constants/app_constants.dart';
import 'package:qibra_ai/core/design_system/app_colors.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';
import 'package:qibra_ai/core/providers/auth_provider.dart';

// ── Feature Screens ──────────────────────────────────────
import '../../quran/presentation/quran_search_screen.dart';
import '../../quran/presentation/surah_reader_screen.dart';
import '../../quran/presentation/bookmarks_screen.dart';
import '../../prayer/providers/prayer_provider.dart';
import '../../prayer/data/models/prayer_models.dart';
import 'package:qibra_ai/features/tafseer/presentation/tafseer_home_screen.dart';
import 'package:qibra_ai/features/tasbih/presentation/tasbih_screen.dart';

// ── Shared Widgets ───────────────────────────────────────
import 'package:qibra_ai/shared/widgets/cards/app_recent_surah_card.dart';
import 'package:qibra_ai/shared/widgets/cards/app_listen_card.dart';
import 'package:qibra_ai/shared/widgets/cards/app_feature_illustration_card.dart';
import 'package:qibra_ai/shared/widgets/badges/app_ornamental_star_badge.dart';

// ── Providers (Quran + Reading Progress) ─────────────────
import 'package:qibra_ai/features/quran/providers/quran_provider.dart'
    hide readingProgressProvider;
import 'package:qibra_ai/features/quran/providers/reading_progress_provider.dart';
import 'package:qibra_ai/features/quran/data/models/quran_models.dart';

// ============================================================
// PRAYER TYPE UI HELPERS
// ============================================================

extension PrayerTypeUIHelpers on PrayerType {
  String get displayName {
    switch (this) {
      case PrayerType.fajr:
        return 'Fajr';
      case PrayerType.sunrise:
        return 'Sunrise';
      case PrayerType.dhuhr:
        return 'Dhuhr';
      case PrayerType.asr:
        return 'Asr';
      case PrayerType.maghrib:
        return 'Maghrib';
      case PrayerType.isha:
        return 'Isha';
    }
  }

  String get arabicName {
    switch (this) {
      case PrayerType.fajr:
        return '\u0627\u0644\u0641\u064E\u062C\u0631';
      case PrayerType.sunrise:
        return '\u0627\u0644\u0634\u0631\u0648\u0642';
      case PrayerType.dhuhr:
        return '\u0627\u0644\u0638\u064F\u0647\u0631';
      case PrayerType.asr:
        return '\u0627\u0644\u0639\u064E\u0635\u0631';
      case PrayerType.maghrib:
        return '\u0627\u0644\u0645\u064E\u063A\u0631\u0628';
      case PrayerType.isha:
        return '\u0627\u0644\u0639\u0650\u0634\u064E\u0627\u0621';
    }
  }

  Color get uiColor {
    switch (this) {
      case PrayerType.fajr:
        return const Color(0xFFF59E0B);
      case PrayerType.sunrise:
        return const Color(0xFFFCD34D);
      case PrayerType.dhuhr:
        return const Color(0xFFFBBF24);
      case PrayerType.asr:
        return const Color(0xFF00A86B);
      case PrayerType.maghrib:
        return const Color(0xFF7C3AED);
      case PrayerType.isha:
        return const Color(0xFF0891B2);
    }
  }

  IconData get uiIcon {
    switch (this) {
      case PrayerType.fajr:
        return Icons.wb_twilight_rounded;
      case PrayerType.sunrise:
        return Icons.wb_sunny_outlined;
      case PrayerType.dhuhr:
        return Icons.wb_sunny_rounded;
      case PrayerType.asr:
        return Icons.wb_cloudy_rounded;
      case PrayerType.maghrib:
        return Icons.nights_stay_rounded;
      case PrayerType.isha:
        return Icons.brightness_2_rounded;
    }
  }
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

class _QuickAccessItem {
  final IconData icon;
  final String label;
  final Color color;
  final String route;

  const _QuickAccessItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.route,
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

class _DailyProgressStat {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final double progress;
  final String route;

  const _DailyProgressStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.progress,
    required this.route,
  });
}

class _NearbyMosque {
  final String mosqueName;
  final String mosqueNameArabic;
  final String mosqueAddress;
  final String distanceKm;
  final String nextJamaat;
  final bool isOpen;
  final double rating;

  const _NearbyMosque({
    required this.mosqueName,
    required this.mosqueNameArabic,
    required this.mosqueAddress,
    required this.distanceKm,
    required this.nextJamaat,
    required this.isOpen,
    required this.rating,
  });
}

class _BottomFeature {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;

  const _BottomFeature({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
  });
}

// ============================================================
// STATIC DATA
// ============================================================

const List<_AyahOfDay> _allAyahsList = [
  _AyahOfDay(
    arabicText: 'إِنَّ الصَّلَاةَ تَنْهَىٰ عَنِ الْفَحْشَاءِ وَالْمُنكَرِ',
    translationText:
        'Indeed, prayer restrains from immorality and wrong doing.',
    referenceText: '29:45',
    surahNameText: 'Surah Al-Ankabut',
  ),
  _AyahOfDay(
    arabicText: 'إِنَّ مَعَ الْعُسْرِ يُسْرًا',
    translationText: 'Indeed, with hardship comes ease.',
    referenceText: '94:6',
    surahNameText: 'Surah Ash-Sharh',
  ),
  _AyahOfDay(
    arabicText: 'رَبِّ زِدْنِي عِلْمًا',
    translationText: 'My Lord, increase me in knowledge.',
    referenceText: '20:114',
    surahNameText: 'Surah Taha',
  ),
  _AyahOfDay(
    arabicText: 'وَمَن يَتَّقِ اللَّهَ يَجْعَل لَّهُ مَخْرَجًا',
    translationText:
        'And whoever fears Allah — He will make for him a way out.',
    referenceText: '65:2',
    surahNameText: 'Surah At-Talaq',
  ),
  _AyahOfDay(
    arabicText: 'اللَّهُ نُورُ السَّمَاوَاتِ وَالْأَرْضِ',
    translationText: 'Allah is the Light of the heavens and the earth.',
    referenceText: '24:35',
    surahNameText: 'Surah An-Nur',
  ),
];

const List<_PrayerInfo> _allPrayers = [
  _PrayerInfo(
    name: 'Fajr',
    nameArabic: 'الْفَجْر',
    time: '5:12 AM',
    icon: Icons.wb_twilight_rounded,
    color: Color(0xFFF59E0B),
  ),
  _PrayerInfo(
    name: 'Dhuhr',
    nameArabic: 'الظُّهْر',
    time: '12:30 PM',
    icon: Icons.wb_sunny_rounded,
    color: Color(0xFFFBBF24),
  ),
  _PrayerInfo(
    name: 'Asr',
    nameArabic: 'الْعَصْر',
    time: '3:45 PM',
    icon: Icons.wb_cloudy_rounded,
    color: Color(0xFF00A86B),
  ),
  _PrayerInfo(
    name: 'Maghrib',
    nameArabic: 'الْمَغْرِب',
    time: '6:52 PM',
    icon: Icons.nights_stay_rounded,
    color: Color(0xFF7C3AED),
  ),
  _PrayerInfo(
    name: 'Isha',
    nameArabic: 'الْعِشَاء',
    time: '8:15 PM',
    icon: Icons.brightness_2_rounded,
    color: Color(0xFF0891B2),
  ),
];

const List<_QuickAccessItem> _quickAccessItems = [
  _QuickAccessItem(
    icon: Icons.menu_book_rounded,
    label: 'Quran',
    color: AppColors.primary,
    route: AppRoutes.quran,
  ),
  _QuickAccessItem(
    icon: Icons.collections_bookmark_rounded,
    label: 'Hadith',
    color: Color(0xFFB45309),
    route: AppRoutes.hadith,
  ),
  _QuickAccessItem(
    icon: Icons.explore_rounded,
    label: 'Qibla',
    color: Color(0xFF7C3AED),
    route: AppRoutes.qibla,
  ),
  _QuickAccessItem(
    icon: Icons.grain_rounded,
    label: 'Tasbih',
    color: AppColors.accent,
    route: AppRoutes.tasbih,
  ),
  _QuickAccessItem(
    icon: Icons.volunteer_activism_rounded,
    label: 'Duas',
    color: Color(0xFF0891B2),
    route: AppRoutes.dua,
  ),
  _QuickAccessItem(
    icon: Icons.apps_rounded,
    label: 'More',
    color: Color(0xFF6B7280),
    route: AppRoutes.settings,
  ),
];

const _RamadanInfo _currentRamadanInfo = _RamadanInfo(
  isRamadanActive: false,
  daysRemaining: 87,
  currentRamadanDay: 0,
  sehriTime: '4:22 AM',
  iftarTime: '6:52 PM',
  hijriRamadanDate: '1 Ramadan 1447 AH',
);

const List<_DailyProgressStat> _dailyProgressStats = [
  _DailyProgressStat(
    label: 'Prayer',
    value: '4/5',
    icon: Icons.mosque_rounded,
    color: AppColors.primary,
    progress: 0.80,
    route: AppRoutes.prayer,
  ),
  _DailyProgressStat(
    label: 'Quran',
    value: '20 min',
    icon: Icons.menu_book_rounded,
    color: AppColors.accent,
    progress: 0.66,
    route: AppRoutes.quran,
  ),
  _DailyProgressStat(
    label: 'Tasbih',
    value: '66/200',
    icon: Icons.grain_rounded,
    color: Color(0xFF7C3AED),
    progress: 0.33,
    route: AppRoutes.tasbih,
  ),
  _DailyProgressStat(
    label: 'Duas',
    value: '12/40',
    icon: Icons.volunteer_activism_rounded,
    color: Color(0xFFEF4444),
    progress: 0.30,
    route: AppRoutes.dua,
  ),
];

const List<RecentSurahItem> _fallbackRecentSurahs = [
  RecentSurahItem(
    surahNumber: 1,
    surahName: 'Al-Fatihah',
    versesCount: 7,
    surahNameArabic: 'الفاتحة',
    revelationType: SurahRevelationType.makki,
  ),
  RecentSurahItem(
    surahNumber: 2,
    surahName: 'Al-Baqarah',
    versesCount: 286,
    surahNameArabic: 'البقرة',
    revelationType: SurahRevelationType.madani,
  ),
  RecentSurahItem(
    surahNumber: 18,
    surahName: 'Al-Kahf',
    versesCount: 110,
    surahNameArabic: 'الكهف',
    revelationType: SurahRevelationType.makki,
  ),
  RecentSurahItem(
    surahNumber: 36,
    surahName: 'Ya-Sin',
    versesCount: 83,
    surahNameArabic: 'يس',
    revelationType: SurahRevelationType.makki,
  ),
];

final List<FeatureItem> _homeFeatures = [
  const FeatureItem(
    title: 'Prayer Times',
    description: 'Accurate prayer times with beautiful countdown',
    icon: Icons.access_time_filled_rounded,
    theme: FeatureCardTheme.gold,
  ),
  const FeatureItem(
    title: 'Quran',
    description: 'Read, listen and understand the Quran',
    icon: Icons.menu_book_rounded,
    theme: FeatureCardTheme.emerald,
  ),
  const FeatureItem(
    title: 'Hadith',
    description: 'Authentic hadith collections with search',
    icon: Icons.collections_bookmark_rounded,
    theme: FeatureCardTheme.amber,
  ),
  const FeatureItem(
    title: 'Qibla',
    description: 'Find the direction of Qibla accurately',
    icon: Icons.explore_rounded,
    theme: FeatureCardTheme.dark,
  ),
  const FeatureItem(
    title: 'AI Assistant',
    description: 'Ask anything about Islam with AI',
    icon: Icons.auto_awesome_rounded,
    theme: FeatureCardTheme.purple,
    badge: FeatureBadgeType.newBadge,
  ),
  const FeatureItem(
    title: 'Tasbih',
    description: 'Digital tasbih with counter and dhikr',
    icon: Icons.grain_rounded,
    theme: FeatureCardTheme.emerald,
  ),
  const FeatureItem(
    title: 'Tafseer',
    description: 'Read Ibn Kathir tafseer in Urdu',
    icon: Icons.menu_book_rounded,
    theme: FeatureCardTheme.amber,
  ),
];

const List<_NearbyMosque> _nearbyMosques = [
  _NearbyMosque(
    mosqueName: 'Masjid Al-Noor',
    mosqueNameArabic: 'مَسْجِد النُّور',
    mosqueAddress: 'Block 5, Gulshan-e-Iqbal',
    distanceKm: '0.3 km',
    nextJamaat: 'Asr · 3:50 PM',
    isOpen: true,
    rating: 4.8,
  ),
  _NearbyMosque(
    mosqueName: 'Jamia Masjid Baitul Mukarram',
    mosqueNameArabic: 'جَامِعَة مَسْجِد',
    mosqueAddress: 'Karachi University Road',
    distanceKm: '0.7 km',
    nextJamaat: 'Asr · 3:45 PM',
    isOpen: true,
    rating: 4.6,
  ),
  _NearbyMosque(
    mosqueName: 'Masjid Bilal',
    mosqueNameArabic: 'مَسْجِد بِلَال',
    mosqueAddress: 'North Nazimabad, Block B',
    distanceKm: '1.2 km',
    nextJamaat: 'Asr · 3:55 PM',
    isOpen: true,
    rating: 4.5,
  ),
];

const List<_BottomFeature> _bottomFeatures = [
  _BottomFeature(
    label: 'Audio Quran',
    subtitle: 'Full recitations',
    icon: Icons.headphones_rounded,
    color: AppColors.primary,
    route: AppRoutes.quran,
  ),
  _BottomFeature(
    label: 'Translations',
    subtitle: '50+ languages',
    icon: Icons.translate_rounded,
    color: Color(0xFF0891B2),
    route: AppRoutes.quran,
  ),
  _BottomFeature(
    label: 'Bookmarks',
    subtitle: 'Saved verses',
    icon: Icons.bookmark_rounded,
    color: Color(0xFF7C3AED),
    route: AppRoutes.quran,
  ),
];

// ============================================================
// HOME SCREEN WIDGET
// ============================================================

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  // Timers
  Timer? _ayahRotationTimer;

  // Animation Controllers
  late final AnimationController _headerAnimationController;
  late final AnimationController _cardStaggerController;
  late final AnimationController _pulseAnimationController;
  late final AnimationController _ayahFadeController;

  // Animations
  late final Animation<double> _headerFadeAnimation;
  late final Animation<Offset> _headerSlideAnimation;
  late final Animation<double> _pulseScaleAnimation;
  late final Animation<double> _ayahFadeAnimation;

  // State Variables
  int _currentAyahIndex = 0;
  ListenPlaybackState _listenPlaybackState = ListenPlaybackState.stopped;
  bool _hasLoadingError = false;
  bool _isContentEmpty = false;
  final ScrollController _scrollController = ScrollController();

  // Static config
  static const int _streakDays = 12;
  static const String _temperature = '21°C';
  static const String _weatherCondition = 'Clear Sky';

  // Shortcuts
  _AyahOfDay get _currentAyahFallback => _allAyahsList[_currentAyahIndex];

  // ============================================================
  // INIT & DISPOSE
  // ============================================================

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
    _startAyahRotationTimer();
  }

  void _initializeAnimations() {
    _headerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _cardStaggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _ayahFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: Curves.easeOut,
      ),
    );

    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _pulseScaleAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(
        parent: _pulseAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    _ayahFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ayahFadeController,
        curve: Curves.easeIn,
      ),
    );
  }

  void _startAnimations() {
    _headerAnimationController.forward();
    _ayahFadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _cardStaggerController.forward();
    });
  }

  void _startAyahRotationTimer() {
    _ayahRotationTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (!mounted) return;
      _changeAyahWithAnimation();
    });
  }

  void _changeAyahWithAnimation() {
    _ayahFadeController.reverse().then((_) {
      if (!mounted) return;
      setState(() {
        _currentAyahIndex = (_currentAyahIndex + 1) % _allAyahsList.length;
      });
      _ayahFadeController.forward();
    });
  }

  void _toggleListenPlayback() {
    HapticFeedback.mediumImpact();
    setState(() {
      _listenPlaybackState = _listenPlaybackState == ListenPlaybackState.playing
          ? ListenPlaybackState.paused
          : ListenPlaybackState.playing;
    });
    context.go(AppRoutes.quran);
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _hasLoadingError = false;
    });
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

  String get _greetingEnglish => 'Assalamu Alaikum';

  String _getDayName(int weekday) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    return days[weekday - 1];
  }

  String _getMonthShort(int month) {
    const months = [
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
      'Dec',
    ];
    return months[month - 1];
  }

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
        body: _buildErrorState(),
      );
    }

    if (_isContentEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: _buildEmptyState(),
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
                  // Hero Header
                  _buildHeroHeader(userName),

                  // Prayer Countdown
                  const SizedBox(height: AppSpacing.lg),
                  _buildPrayerCountdownCard(),

                  // All Prayers Strip
                  const SizedBox(height: AppSpacing.md),
                  _buildAllPrayersStrip(),

                  // Today's Progress
                  const SizedBox(height: AppSpacing.xl2),
                  _buildDailyProgressSection(),

                  // Daily Verse
                  const SizedBox(height: AppSpacing.xl2),
                  _buildDailyVerseSection(),

                  // Reading Streak
                  const SizedBox(height: AppSpacing.xl2),
                  _buildReadingStreakCard(),

                  // Ramadan Widget
                  const SizedBox(height: AppSpacing.xl2),
                  _buildSectionHeader(
                    title: 'RAMADAN',
                    icon: Icons.nightlight_round,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildRamadanWidget(),

                  // Quick Access
                  const SizedBox(height: AppSpacing.xl2),
                  _buildQuickAccessSection(),

                  // Quran Section Header
                  const SizedBox(height: AppSpacing.xl2),
                  _buildQuranSectionHeader(),

                  // Continue Reading
                  const SizedBox(height: AppSpacing.md),
                  _buildContinueReadingCard(),

                  // Quran Stats
                  const SizedBox(height: AppSpacing.md),
                  _buildQuranStatsRow(),

                  // Popular Surahs
                  const SizedBox(height: AppSpacing.lg),
                  _buildPopularSurahsList(),

                  // Nearby Mosques
                  const SizedBox(height: AppSpacing.xl2),
                  _buildSectionHeader(
                    title: 'NEARBY MOSQUES',
                    icon: Icons.mosque_rounded,
                    trailingWidget: _buildSeeAllButton(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        context.go(AppRoutes.mosques);
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildNearbyMosqueSection(),

                  // Hadith
                  const SizedBox(height: AppSpacing.xl2),
                  _buildSectionHeader(
                    title: 'HADITH OF THE DAY',
                    icon: Icons.format_quote_rounded,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildHadithCard(),

                  // Listen to Quran
                  const SizedBox(height: AppSpacing.xl2),
                  _buildListenToQuranCard(),

                  // Feature Grid
                  const SizedBox(height: AppSpacing.xl3),
                  _buildSectionHeader(
                    title: 'ALL FEATURES',
                    icon: Icons.apps_rounded,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildFeatureGrid(),

                  // Bottom Features
                  const SizedBox(height: AppSpacing.xl2),
                  _buildBottomFeaturesRow(),

                  // Watermark
                  const SizedBox(height: AppSpacing.xl3),
                  _buildGoldenArabicWatermark(),

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
                  offset: const Offset(0, 8),
                ),
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
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF0A2540),
                              Color(0xFF1A3A5C),
                              Color(0xFF00A86B),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.30),
                          Colors.black.withValues(alpha: 0.60),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _greetingEnglish,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.white.withValues(alpha: 0.90),
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.5,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const QuranSearchScreen(),
                                  ),
                                );
                              },
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.white.withValues(alpha: 0.20),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color:
                                        AppColors.white.withValues(alpha: 0.30),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.search_rounded,
                                  color: AppColors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          'QIBRA AI',
                          style: AppTextStyles.headlineLarge.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                            height: 1.0,
                            fontSize: 28,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Your Islamic Companion',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on_rounded,
                              color: AppColors.white,
                              size: 11,
                            ),
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
                                  fontSize: 9,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(
                              Icons.wb_sunny_rounded,
                              color: AppColors.accent,
                              size: 11,
                            ),
                            const SizedBox(width: 3),
                            Flexible(
                              flex: 2,
                              child: Text(
                                '$_temperature · $_weatherCondition',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 9,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '15 Rabi al-Thani 1446 AH',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 8,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    '${_getDayName(DateTime.now().weekday)}, ${DateTime.now().day} ${_getMonthShort(DateTime.now().month)} ${DateTime.now().year}',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.white
                                          .withValues(alpha: 0.75),
                                      fontSize: 8,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
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
  // PRAYER COUNTDOWN CARD
  // ============================================================

  Widget _buildPrayerCountdownCard() {
    final nextPrayerInfo = ref.watch(nextPrayerProvider);
    final dailyTimes = ref.watch(dailyPrayerTimesProvider);

    final PrayerType displayType =
        nextPrayerInfo?.prayer.type ?? PrayerType.asr;
    final String displayName = displayType.displayName;
    final String displayArabic = displayType.arabicName;
    final String displayTime =
        nextPrayerInfo?.prayer.formattedTime ?? '--:-- --';
    final Duration displayCountdown =
        nextPrayerInfo?.countdown ?? Duration.zero;
    final String sunriseTime = dailyTimes?.sunrise.formattedTime ?? '--:-- --';
    final String sunsetTime = dailyTimes?.maghrib.formattedTime ?? '--:-- --';

    final int totalSeconds = displayCountdown.inSeconds.abs();
    final int h = totalSeconds ~/ 3600;
    final int m = (totalSeconds % 3600) ~/ 60;
    final int s = totalSeconds % 60;
    final String formattedCountdown =
        '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

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
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF00A86B),
                  Color(0xFF007A4D),
                  Color(0xFF005C39),
                ],
              ),
              borderRadius: AppRadius.cardRadiusLarge,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.45),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: AppRadius.cardRadiusLarge,
              child: Stack(
                children: [
                  Positioned(
                    right: -40,
                    top: -40,
                    child: Container(
                      width: 160,
                      height: 160,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.white.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color:
                                        AppColors.white.withValues(alpha: 0.20),
                                    borderRadius: AppRadius.buttonRadius,
                                  ),
                                  child: const Icon(
                                    Icons.access_time_filled_rounded,
                                    color: AppColors.white,
                                    size: 12,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'NEXT PRAYER',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color:
                                        AppColors.white.withValues(alpha: 0.90),
                                    letterSpacing: 2.0,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.white.withValues(alpha: 0.20),
                                borderRadius: AppRadius.pillRadius,
                                border: Border.all(
                                  color:
                                      AppColors.white.withValues(alpha: 0.30),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF10B981),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Live',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        displayName,
                                        style:
                                            AppTextStyles.displaySmall.copyWith(
                                          color: AppColors.white,
                                          fontWeight: FontWeight.w900,
                                          height: 1.0,
                                          fontSize: 40,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 6),
                                        child: Text(
                                          displayArabic,
                                          style: const TextStyle(
                                            fontFamily: 'Amiri',
                                            fontSize: 22,
                                            color: AppColors.white,
                                            fontWeight: FontWeight.w600,
                                            height: 1.0,
                                          ),
                                          textDirection: TextDirection.rtl,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'at $displayTime',
                                    style: AppTextStyles.bodyMedium.copyWith(
                                      color: AppColors.white
                                          .withValues(alpha: 0.75),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.background
                                          .withValues(alpha: 0.40),
                                      borderRadius: AppRadius.buttonRadius,
                                      border: Border.all(
                                        color: AppColors.white
                                            .withValues(alpha: 0.25),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.timer_outlined,
                                          color: AppColors.white,
                                          size: 12,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          formattedCountdown,
                                          style: AppTextStyles.labelMedium
                                              .copyWith(
                                            color: AppColors.white,
                                            fontWeight: FontWeight.w800,
                                            fontFamily: 'monospace',
                                            letterSpacing: 1.0,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _buildKaabaWithRing(),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.white.withValues(alpha: 0.10),
                            borderRadius: AppRadius.buttonRadius,
                          ),
                          child: Text(
                            '"Indeed, prayer restrains from immorality and wrong doing." — Surah Al-Ankabut (29:45)',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.white.withValues(alpha: 0.85),
                              fontSize: 10,
                              fontStyle: FontStyle.italic,
                              height: 1.4,
                            ),
                            maxLines: 2,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildSunTimeInfo(
                              icon: Icons.wb_twilight_rounded,
                              label: 'Sunrise',
                              time: sunriseTime,
                            ),
                            _buildSunTimeInfo(
                              icon: Icons.nights_stay_rounded,
                              label: 'Sunset',
                              time: sunsetTime,
                            ),
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

  Widget _buildKaabaWithRing() {
    return SizedBox(
      width: 110,
      height: 110,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.60),
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.40),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
          ),
          ClipOval(
            child: Container(
              width: 90,
              height: 90,
              color: AppColors.background,
              child: Image.asset(
                'assets/images/hero/kaaba_3d.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    decoration: const BoxDecoration(color: Colors.black),
                    child: const Icon(
                      Icons.mosque_rounded,
                      color: AppColors.accent,
                      size: 40,
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSunTimeInfo({
    required IconData icon,
    required String label,
    required String time,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.white.withValues(alpha: 0.85), size: 14),
        const SizedBox(width: 5),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.white.withValues(alpha: 0.70),
                fontSize: 9,
              ),
            ),
            Text(
              time,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // ALL PRAYERS STRIP
  // ============================================================

  Widget _buildAllPrayersStrip() {
    final dailyTimes = ref.watch(dailyPrayerTimesProvider);
    final nextPrayerInfo = ref.watch(nextPrayerProvider);

    if (dailyTimes == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Row(
          children: List.generate(_allPrayers.length, (index) {
            final prayer = _allPrayers[index];
            final isNext = index == 2;
            final isDone = index < 2;
            final isLast = index == _allPrayers.length - 1;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: isLast ? 0 : 6),
                child: _buildPrayerPill(prayer, isNext, isDone),
              ),
            );
          }),
        ),
      );
    }

    final List<PrayerTime> obligatoryPrayers = [
      dailyTimes.fajr,
      dailyTimes.dhuhr,
      dailyTimes.asr,
      dailyTimes.maghrib,
      dailyTimes.isha,
    ];

    final PrayerType? nextType = nextPrayerInfo?.prayer.type;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: List.generate(obligatoryPrayers.length, (index) {
          final prayerTime = obligatoryPrayers[index];
          final bool isNext = prayerTime.type == nextType;
          final bool isDone = prayerTime.isPast(DateTime.now()) && !isNext;
          final bool isLast = index == obligatoryPrayers.length - 1;

          final realPrayer = _PrayerInfo(
            name: prayerTime.type.displayName,
            nameArabic: prayerTime.type.arabicName,
            time: prayerTime.formattedTime,
            icon: prayerTime.type.uiIcon,
            color: prayerTime.type.uiColor,
          );

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: isLast ? 0 : 6),
              child: _buildPrayerPill(realPrayer, isNext, isDone),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildPrayerPill(_PrayerInfo prayer, bool isNext, bool isDone) {
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
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    prayer.color,
                    prayer.color.withValues(alpha: 0.70),
                  ],
                )
              : null,
          color: isNext ? null : AppColors.surface,
          borderRadius: AppRadius.cardRadius,
          border: Border.all(
            color: isNext
                ? Colors.transparent
                : isDone
                    ? prayer.color.withValues(alpha: 0.30)
                    : AppColors.borderSubtle,
          ),
          boxShadow: isNext
              ? [
                  BoxShadow(
                    color: prayer.color.withValues(alpha: 0.40),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Icon(
              isDone ? Icons.check_circle_rounded : prayer.icon,
              size: 16,
              color: isNext
                  ? AppColors.white
                  : isDone
                      ? prayer.color
                      : AppColors.iconSecondary,
            ),
            const SizedBox(height: 3),
            Text(
              prayer.name,
              style: AppTextStyles.labelSmall.copyWith(
                color: isNext
                    ? AppColors.white
                    : isDone
                        ? prayer.color
                        : AppColors.textSecondary,
                fontWeight: isNext ? FontWeight.w700 : FontWeight.w600,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              prayer.time,
              style: AppTextStyles.labelSmall.copyWith(
                color: isNext
                    ? AppColors.white.withValues(alpha: 0.85)
                    : AppColors.textTertiary,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SECTION HEADER HELPERS
  // ============================================================

  Widget _buildSectionHeader({
    required String title,
    required IconData icon,
    Widget? trailingWidget,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              gradient: AppGradients.gold,
              borderRadius: AppRadius.pillRadius,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Icon(icon, color: AppColors.accent, size: 16),
          const SizedBox(width: AppSpacing.xs),
          Text(
            title,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.accent,
              letterSpacing: 2.0,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (trailingWidget != null) ...[
            const Spacer(),
            trailingWidget,
          ],
        ],
      ),
    );
  }

  Widget _buildSeeAllButton({required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.10),
          borderRadius: AppRadius.pillRadius,
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.30),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'See All',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
            const SizedBox(width: 3),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.accent,
              size: 9,
            ),
          ],
        ),
      ),
    );
  }
  // ============================================================
  // DAILY PROGRESS SECTION
  // ============================================================

  Widget _buildDailyProgressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  gradient: AppGradients.gold,
                  borderRadius: AppRadius.pillRadius,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                Icons.insights_rounded,
                color: AppColors.accent,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                "TODAY'S PROGRESS",
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.accent,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.go(AppRoutes.prayer);
                },
                child: Text(
                  'View All',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: List.generate(_dailyProgressStats.length, (index) {
              final stat = _dailyProgressStats[index];
              final isLast = index == _dailyProgressStats.length - 1;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: isLast ? 0 : AppSpacing.sm),
                  child: _buildProgressTile(stat),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressTile(_DailyProgressStat stat) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.go(stat.route);
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.cardRadius,
          border: Border.all(
            color: stat.color.withValues(alpha: 0.25),
          ),
          boxShadow: [
            BoxShadow(
              color: stat.color.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(stat.icon, color: stat.color, size: 16),
            const SizedBox(height: 6),
            Text(
              stat.label,
              style: AppTextStyles.labelSmall.copyWith(
                color: stat.color,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              stat.value,
              style: AppTextStyles.titleSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              stat.progress >= 1.0
                  ? 'Completed'
                  : stat.progress >= 0.5
                      ? 'On Track'
                      : 'Daily Goal',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textTertiary,
                fontSize: 8,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: stat.progress.clamp(0.0, 1.0),
                backgroundColor: stat.color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(stat.color),
                minHeight: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DAILY VERSE
  // ============================================================

  Widget _buildDailyVerseSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Consumer(
        builder: (context, ref, _) {
          final randomAyahAsync = ref.watch(autoRotatingAyahProvider);
          return randomAyahAsync.when(
            data: (ayah) {
              if (ayah != null) {
                return _buildVerseCard(
                  arabicText: ayah.text,
                  translationText: ayah.translation ?? 'Translation loading...',
                  reference: 'Ayah ${ayah.number}',
                );
              }
              return _buildVerseCard(
                arabicText: _currentAyahFallback.arabicText,
                translationText: _currentAyahFallback.translationText,
                reference:
                    '${_currentAyahFallback.surahNameText} (${_currentAyahFallback.referenceText})',
              );
            },
            loading: () => _buildVerseCard(
              arabicText: _currentAyahFallback.arabicText,
              translationText: _currentAyahFallback.translationText,
              reference:
                  '${_currentAyahFallback.surahNameText} (${_currentAyahFallback.referenceText})',
            ),
            error: (_, __) => _buildVerseCard(
              arabicText: _currentAyahFallback.arabicText,
              translationText: _currentAyahFallback.translationText,
              reference:
                  '${_currentAyahFallback.surahNameText} (${_currentAyahFallback.referenceText})',
            ),
          );
        },
      ),
    );
  }

  Widget _buildVerseCard({
    required String arabicText,
    required String translationText,
    required String reference,
  }) {
    return FadeTransition(
      opacity: _ayahFadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.cardRadiusLarge,
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.25),
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.10),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 3,
                        height: 10,
                        decoration: BoxDecoration(
                          gradient: AppGradients.gold,
                          borderRadius: AppRadius.pillRadius,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'DAILY VERSE',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.accent,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w700,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    arabicText,
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 16,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                    textDirection: TextDirection.rtl,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '"$translationText"',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                      fontSize: 11,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '— $reference',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            _buildLanternPair(),
          ],
        ),
      ),
    );
  }

  Widget _buildLanternPair() {
    return SizedBox(
      width: 80,
      height: 100,
      child: Image.asset(
        'assets/images/hero/lantern_pair.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Icon(
              Icons.wb_incandescent_rounded,
              color: AppColors.accent,
              size: 48,
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // READING STREAK CARD — Now with real progress data
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
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF7C3AED),
                Color(0xFF6D28D9),
                Color(0xFF5B21B6),
              ],
            ),
            borderRadius: AppRadius.cardRadiusLarge,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.40),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -15,
                top: -15,
                child: Icon(
                  Icons.local_fire_department_rounded,
                  size: 100,
                  color: AppColors.white.withValues(alpha: 0.15),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.white.withValues(alpha: 0.20),
                                borderRadius: AppRadius.buttonRadius,
                              ),
                              child: const Icon(
                                Icons.local_fire_department_rounded,
                                color: AppColors.white,
                                size: 14,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Prayer Streak',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '$displayStreak',
                              style: AppTextStyles.displayLarge.copyWith(
                                color: AppColors.white,
                                fontWeight: FontWeight.w900,
                                height: 1.0,
                                fontSize: 44,
                                letterSpacing: -2.0,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                'Days',
                                style: AppTextStyles.titleMedium.copyWith(
                                  color:
                                      AppColors.white.withValues(alpha: 0.90),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          progressState.hasReadToday
                              ? 'MashaAllah! Keep it up! 🔥'
                              : 'Keep it up!',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.white.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: List.generate(7, (index) {
                            final completed = index < displayStreak;
                            const days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: Column(
                                children: [
                                  Container(
                                    width: 18,
                                    height: 18,
                                    decoration: BoxDecoration(
                                      color: completed
                                          ? AppColors.white
                                          : AppColors.white
                                              .withValues(alpha: 0.20),
                                      shape: BoxShape.circle,
                                    ),
                                    child: completed
                                        ? const Icon(
                                            Icons.check_rounded,
                                            color: Color(0xFF7C3AED),
                                            size: 12,
                                          )
                                        : null,
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    days[index],
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: AppColors.white
                                          .withValues(alpha: 0.75),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 8,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 90,
                    height: 110,
                    child: Image.asset(
                      'assets/images/hero/lantern_pair.png',
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.local_fire_department_rounded,
                          color: AppColors.white.withValues(alpha: 0.5),
                          size: 60,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // RAMADAN WIDGET
  // ============================================================

  Widget _buildRamadanWidget() {
    const _RamadanInfo ramadanData = _currentRamadanInfo;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          context.go(AppRoutes.islamicCalendar);
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF6B21A8),
                Color(0xFF4C1D95),
                Color(0xFF1E1B4B),
              ],
            ),
            borderRadius: AppRadius.cardRadiusLarge,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6B21A8).withValues(alpha: 0.40),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: AppRadius.cardRadiusLarge,
            child: Stack(
              children: [
                Positioned(
                  right: -20,
                  top: -10,
                  child: Icon(
                    Icons.nightlight_round,
                    size: 130,
                    color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl2),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRamadanTopRow(ramadanData),
                      const SizedBox(height: AppSpacing.md),
                      ramadanData.isRamadanActive
                          ? _buildActiveRamadanContent(ramadanData)
                          : _buildUpcomingRamadanContent(ramadanData),
                      const SizedBox(height: AppSpacing.md),
                      _buildSehriIftarRow(ramadanData),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRamadanTopRow(_RamadanInfo ramadanData) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withValues(alpha: 0.20),
                borderRadius: AppRadius.buttonRadius,
                border: Border.all(
                  color: const Color(0xFFFFD700).withValues(alpha: 0.40),
                ),
              ),
              child: const Icon(
                Icons.nightlight_round,
                color: Color(0xFFFFD700),
                size: 14,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'RAMADAN',
              style: AppTextStyles.labelSmall.copyWith(
                color: const Color(0xFFFFD700),
                letterSpacing: 2.5,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: ramadanData.isRamadanActive
                ? const Color(0xFF10B981).withValues(alpha: 0.20)
                : AppColors.white.withValues(alpha: 0.15),
            borderRadius: AppRadius.pillRadius,
            border: Border.all(
              color: ramadanData.isRamadanActive
                  ? const Color(0xFF10B981).withValues(alpha: 0.40)
                  : AppColors.white.withValues(alpha: 0.25),
            ),
          ),
          child: Text(
            ramadanData.isRamadanActive ? 'ACTIVE' : 'UPCOMING',
            style: AppTextStyles.labelSmall.copyWith(
              color: ramadanData.isRamadanActive
                  ? const Color(0xFF10B981)
                  : AppColors.white,
              fontWeight: FontWeight.w800,
              fontSize: 9,
              letterSpacing: 1.0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingRamadanContent(_RamadanInfo ramadanData) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${ramadanData.daysRemaining}',
              style: AppTextStyles.displayLarge.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
                height: 1.0,
                fontSize: 48,
                letterSpacing: -2.0,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'days',
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.white.withValues(alpha: 0.80),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'until Ramadan Mubarak',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.white.withValues(alpha: 0.75),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        const Text(
          'رَمَضَان مُبَارَك',
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 18,
            color: Color(0xFFFFD700),
            fontWeight: FontWeight.w600,
            height: 1.0,
          ),
          textDirection: TextDirection.rtl,
        ),
      ],
    );
  }

  Widget _buildActiveRamadanContent(_RamadanInfo ramadanData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'Day ${ramadanData.currentRamadanDay}',
              style: AppTextStyles.displayMedium.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
                height: 1.0,
                letterSpacing: -1.0,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                'of 30',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.white.withValues(alpha: 0.70),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: AppRadius.pillRadius,
          child: LinearProgressIndicator(
            value: ramadanData.currentRamadanDay / 30,
            backgroundColor: AppColors.white.withValues(alpha: 0.20),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFD700)),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  Widget _buildSehriIftarRow(_RamadanInfo ramadanData) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.10),
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTimeInfoBlock(
              iconData: Icons.brightness_5_outlined,
              labelText: 'SEHRI',
              timeText: ramadanData.sehriTime,
              iconColor: const Color(0xFFFFB84D),
            ),
          ),
          Container(
            width: 1,
            height: 40,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            color: AppColors.white.withValues(alpha: 0.20),
          ),
          Expanded(
            child: _buildTimeInfoBlock(
              iconData: Icons.dinner_dining_outlined,
              labelText: 'IFTAR',
              timeText: ramadanData.iftarTime,
              iconColor: const Color(0xFFEF5350),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeInfoBlock({
    required IconData iconData,
    required String labelText,
    required String timeText,
    required Color iconColor,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.20),
            shape: BoxShape.circle,
          ),
          child: Icon(iconData, color: iconColor, size: 16),
        ),
        const SizedBox(width: AppSpacing.sm),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              labelText,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.white.withValues(alpha: 0.60),
                fontWeight: FontWeight.w700,
                fontSize: 9,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              timeText,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w800,
                fontFamily: 'monospace',
                fontSize: 13,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ============================================================
  // QUICK ACCESS
  // ============================================================

  Widget _buildQuickAccessSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  gradient: AppGradients.gold,
                  borderRadius: AppRadius.pillRadius,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                Icons.grid_view_rounded,
                color: AppColors.accent,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                'QUICK ACCESS',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.accent,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(_quickAccessItems.length, (index) {
              return _buildQuickAccessIcon(_quickAccessItems[index]);
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickAccessIcon(_QuickAccessItem item) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        context.go(item.route);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  item.color.withValues(alpha: 0.20),
                  item.color.withValues(alpha: 0.08),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: item.color.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            child: Icon(item.icon, color: item.color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            item.label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // QURAN SECTION HEADER
  // ============================================================

  Widget _buildQuranSectionHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.cardRadius,
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: AppGradients.emerald,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                color: AppColors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Quran',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const QuranSearchScreen(),
                  ),
                );
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: const Icon(
                  Icons.search_rounded,
                  color: AppColors.primary,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CONTINUE READING — Uses Real Mushaf Progress
  // ============================================================

  Widget _buildContinueReadingCard() {
    final progressState = ref.watch(readingProgressProvider);
    final currentPage = progressState.currentPage;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          if (currentPage != null) {
            context.push(
              '${AppRoutes.mushafReader}?page=${currentPage.pageNumber}',
            );
          } else {
            context.push('${AppRoutes.mushafReader}?page=1');
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.cardRadiusLarge,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.25),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.10),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: AppRadius.pillRadius,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.bookmark_rounded,
                            color: AppColors.primary,
                            size: 10,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'CONTINUE READING',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                              fontSize: 9,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      currentPage != null ? currentPage.progressText : '0.0%',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  currentPage != null ? currentPage.surahName : 'Start Reading',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  currentPage != null
                      ? 'Page ${currentPage.pageNumber} • Juz ${currentPage.juzNumber}'
                      : 'Tap to open Mushaf reader',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: AppRadius.pillRadius,
                            child: LinearProgressIndicator(
                              value: progressState.overallProgress,
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: 0.15),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                              minHeight: 5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentPage != null
                                ? 'Page ${currentPage.pageNumber} of 604'
                                : 'Begin your journey',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textTertiary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: AppColors.white,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // QURAN STATS ROW
  // ============================================================

  Widget _buildQuranStatsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              icon: Icons.menu_book_rounded,
              value: '114',
              label: 'All Surahs',
              color: AppColors.primary,
              onTap: () {
                HapticFeedback.lightImpact();
                context.go(AppRoutes.quran);
              },
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _buildStatCard(
              icon: Icons.book_rounded,
              value: '30',
              label: 'Juz',
              color: AppColors.accent,
              onTap: () {
                HapticFeedback.lightImpact();
                context.go(AppRoutes.quran);
              },
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _buildStatCard(
              icon: Icons.description_rounded,
              value: '604',
              label: 'Pages',
              color: const Color(0xFF7C3AED),
              onTap: () {
                HapticFeedback.lightImpact();
                context.push('${AppRoutes.mushafReader}?page=1');
              },
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _buildStatCard(
              icon: Icons.bookmark_rounded,
              value: '12',
              label: 'Bookmarks',
              color: const Color(0xFFEF4444),
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const BookmarksScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.cardRadius,
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              value,
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w900,
                fontSize: 18,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 9,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // POPULAR SURAHS
  // ============================================================

  Widget _buildPopularSurahsList() {
    return Consumer(
      builder: (context, ref, _) {
        final popularSurahsAsync = ref.watch(popularSurahsProvider);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: 14,
                    decoration: BoxDecoration(
                      gradient: AppGradients.gold,
                      borderRadius: AppRadius.pillRadius,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  const Icon(
                    Icons.trending_up_rounded,
                    color: AppColors.accent,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'POPULAR SURAHS',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.accent,
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      context.go(AppRoutes.quran);
                    },
                    child: Text(
                      'View All',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            popularSurahsAsync.when(
              data: (surahs) {
                if (surahs.isEmpty) return _buildPopularSurahsFallback();
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Column(
                    children: surahs.take(4).map((surah) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: _buildRealSurahTile(surah),
                      );
                    }).toList(),
                  ),
                );
              },
              loading: () => Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Column(
                  children: List.generate(
                    4,
                    (index) => _buildLoadingSurahTile(),
                  ),
                ),
              ),
              error: (_, __) => _buildPopularSurahsFallback(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRealSurahTile(SurahInfoModel surah) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SurahReaderScreen(surahNumber: surah.number),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.cardRadius,
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.20),
          ),
        ),
        child: Row(
          children: [
            AppOrnamentalStarBadge(
              number: surah.number,
              customSize: 44,
              theme: BadgeColorTheme.emerald,
              showGlow: false,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          surah.name,
                          style: AppTextStyles.titleSmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        surah.nameArabic,
                        style: const TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 16,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(
                        '${surah.numberOfAyahs} Ayahs',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textTertiary,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: surah.isMeccan
                              ? AppColors.accent.withValues(alpha: 0.15)
                              : AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: AppRadius.pillRadius,
                        ),
                        child: Text(
                          surah.isMeccan ? 'Meccan' : 'Medinan',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: surah.isMeccan
                                ? AppColors.accent
                                : AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: AppGradients.emerald,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: AppColors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSurahTile() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.cardRadius,
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(AppColors.primary),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 100,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 60,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularSurahsFallback() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: _fallbackRecentSurahs.map((surah) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SurahReaderScreen(
                      surahNumber: surah.surahNumber,
                    ),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.cardRadius,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.20),
                  ),
                ),
                child: Row(
                  children: [
                    AppOrnamentalStarBadge(
                      number: surah.surahNumber,
                      customSize: 44,
                      theme: BadgeColorTheme.emerald,
                      showGlow: false,
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                surah.surahName,
                                style: AppTextStyles.titleSmall.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                surah.surahNameArabic ?? '',
                                style: const TextStyle(
                                  fontFamily: 'Amiri',
                                  fontSize: 16,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                                textDirection: TextDirection.rtl,
                              ),
                            ],
                          ),
                          Text(
                            '${surah.versesCount} Ayahs',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textTertiary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        gradient: AppGradients.emerald,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.play_arrow_rounded,
                        color: AppColors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ============================================================
  // NEARBY MOSQUES
  // ============================================================

  Widget _buildNearbyMosqueSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            physics: const BouncingScrollPhysics(),
            itemCount: _nearbyMosques.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              return _buildMosqueCard(_nearbyMosques[index], index);
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              context.go(AppRoutes.mosques);
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.cardRadius,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.30),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.map_outlined,
                    color: AppColors.primary,
                    size: 16,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'View all mosques on map',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMosqueCard(_NearbyMosque mosque, int index) {
    final cardColors = [
      const Color(0xFF004D2E),
      const Color(0xFF003D26),
      const Color(0xFF1A3A2A),
    ];

    return Container(
      width: 220,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadiusLarge,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.20),
        ),
      ),
      child: ClipRRect(
        borderRadius: AppRadius.cardRadiusLarge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    cardColors[index % cardColors.length],
                    AppColors.primary.withValues(alpha: 0.80),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: mosque.isOpen
                            ? const Color(0xFF10B981).withValues(alpha: 0.25)
                            : AppColors.error.withValues(alpha: 0.25),
                        borderRadius: AppRadius.pillRadius,
                      ),
                      child: Text(
                        mosque.isOpen ? 'OPEN' : 'CLOSED',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: mosque.isOpen
                              ? const Color(0xFF10B981)
                              : AppColors.error,
                          fontWeight: FontWeight.w800,
                          fontSize: 8,
                        ),
                      ),
                    ),
                    Text(
                      mosque.distanceKm,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mosque.mosqueName,
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      mosque.mosqueNameArabic,
                      style: const TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 13,
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                      ),
                      textDirection: TextDirection.rtl,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      mosque.mosqueAddress,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        borderRadius: AppRadius.buttonRadius,
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        'Next: ${mosque.nextJamaat}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HADITH CARD
  // ============================================================

  Widget _buildHadithCard() {
    const String narrator = 'Abu Hurairah (RA)';
    const String collection = 'Sahih al-Bukhari · 6477';
    const String hadithBody =
        'The Prophet ﷺ said: "Whoever believes in Allah and the Last Day should speak a good word or remain silent."';
    const String hadithArabic =
        'مَنْ كَانَ يُؤْمِنُ بِاللَّهِ وَالْيَوْمِ الآخِرِ فَلْيَقُلْ خَيْرًا أَوْ لِيَصْمُتْ';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          context.go(AppRoutes.hadith);
        },
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.cardRadiusLarge,
            border: Border.all(
              color: const Color(0xFFB45309).withValues(alpha: 0.20),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 3,
                          height: 14,
                          decoration: BoxDecoration(
                            color: const Color(0xFFB45309),
                            borderRadius: AppRadius.pillRadius,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'HADITH',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: const Color(0xFFB45309),
                            letterSpacing: 2.0,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      collection,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: const Color(0xFFB45309),
                        fontWeight: FontWeight.w700,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  hadithArabic,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 18,
                    color: AppColors.textPrimary,
                    height: 2.0,
                    fontWeight: FontWeight.w600,
                  ),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  hadithBody,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.7,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      narrator,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'Read more',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: const Color(0xFFB45309),
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Color(0xFFB45309),
                          size: 10,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // LISTEN TO QURAN
  // ============================================================

  Widget _buildListenToQuranCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: AppQuranListenCard(
        qariName: 'Mishary Rashid',
        playbackState: _listenPlaybackState,
        onPlayTap: _toggleListenPlayback,
        onCardTap: () {
          HapticFeedback.lightImpact();
          context.go(AppRoutes.quran);
        },
      ),
    );
  }

  // ============================================================
  // FEATURE GRID
  // ============================================================

  Widget _buildFeatureGrid() {
    return AppFeatureIllustrationList(
      features: _homeFeatures.map((feature) {
        return FeatureItem(
          title: feature.title,
          description: feature.description,
          icon: feature.icon,
          imagePath: feature.imagePath,
          theme: feature.theme,
          badge: feature.badge,
          onTap: () {
            HapticFeedback.mediumImpact();
            switch (feature.title) {
              case 'Prayer Times':
                context.go(AppRoutes.prayer);
                break;
              case 'Quran':
                context.go(AppRoutes.quran);
                break;
              case 'Hadith':
                context.go(AppRoutes.hadith);
                break;
              case 'Qibla':
                context.go(AppRoutes.qibla);
                break;
              case 'AI Assistant':
                context.go(AppRoutes.aiChat);
                break;
              case 'Tafseer':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TafseerHomeScreen(),
                  ),
                );
                break;
              case 'Tasbih':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const TasbihScreen(),
                  ),
                );
                break;
              default:
                context.go(AppRoutes.home);
            }
          },
        );
      }).toList(),
      cardSize: FeatureCardSize.standard,
    );
  }

  // ============================================================
  // BOTTOM FEATURES
  // ============================================================

  Widget _buildBottomFeaturesRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: List.generate(_bottomFeatures.length, (index) {
          final feature = _bottomFeatures[index];
          final isLast = index == _bottomFeatures.length - 1;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: isLast ? 0 : AppSpacing.sm),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  context.go(feature.route);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.cardRadius,
                    border: Border.all(
                      color: feature.color.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              feature.color.withValues(alpha: 0.20),
                              feature.color.withValues(alpha: 0.08),
                            ],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: feature.color.withValues(alpha: 0.30),
                          ),
                        ),
                        child: Icon(
                          feature.icon,
                          color: feature.color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        feature.label,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        feature.subtitle,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: feature.color,
                          fontWeight: FontWeight.w600,
                          fontSize: 8,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // ============================================================
  // GOLDEN ARABIC WATERMARK
  // ============================================================

  Widget _buildGoldenArabicWatermark() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppColors.accent.withValues(alpha: 0.30),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Icon(
                  Icons.star_rounded,
                  color: AppColors.accent.withValues(alpha: 0.60),
                  size: 16,
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accent.withValues(alpha: 0.30),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [
                Color(0xFFFFD700),
                Color(0xFFB8960C),
              ],
            ).createShader(bounds),
            child: const Text(
              'جَزَاكَ اللَّه',
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 32,
                color: Colors.white,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'May Allah reward you',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.accent.withValues(alpha: 0.70),
              fontStyle: FontStyle.italic,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'QIBRA AI',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w800,
              letterSpacing: 3.0,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState() {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl3),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.25),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  color: AppColors.error,
                  size: 40,
                ),
              ),
              const SizedBox(height: AppSpacing.xl2),
              Text(
                'Something went wrong',
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Please check your connection and try again.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl3),
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _clearSpecialState();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  decoration: BoxDecoration(
                    gradient: AppGradients.emerald,
                    borderRadius: AppRadius.buttonRadius,
                    boxShadow: AppShadows.emeraldGlow,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.refresh_rounded,
                        color: AppColors.white,
                        size: 18,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Try Again',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl3),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.15),
                      AppColors.accent.withValues(alpha: 0.10),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.20),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.mosque_rounded,
                  color: AppColors.primary,
                  size: 60,
                ),
              ),
              const SizedBox(height: AppSpacing.xl2),
              Text(
                'Welcome to QIBRA AI',
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Your Islamic companion is ready.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl3),
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  _clearSpecialState();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  decoration: BoxDecoration(
                    gradient: AppGradients.emerald,
                    borderRadius: AppRadius.buttonRadius,
                    boxShadow: AppShadows.emeraldGlow,
                  ),
                  child: Text(
                    'Get Started',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} // ← END of _HomeScreenState
