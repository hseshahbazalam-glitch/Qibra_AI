// lib/features/home/presentation/home_screen.dart
// ============================================================
// QIBRA AI — HOME DASHBOARD (PREMIUM v4.0)
// Phase: 8 — Reference Image Match Redesign
// ============================================================
// CHANGES FROM v3.0:
//   ── NEW SECTIONS ADDED (Reference Match) ──
//   ✨ Recently Read Surahs (with ornamental star badges)
//   ✨ Daily Verse Card (with mosque background)
//   ✨ Listen to Quran Card (animated waveform)
//   ✨ Feature Grid (6 premium 3D feature cards)
//   ✨ Golden Arabic Watermark (جزاك الله)
//
//   ── REDESIGNED SECTIONS ──
//   🔄 Prayer Countdown: Linear bar → CIRCULAR PROGRESS RING
//   🔄 Daily Stats: Basic icons → Vertical mini-bars with progress
//   🔄 Quick Actions: Gradient cards → Circular icon buttons
//
//   ── PRESERVED (All bonus features intact) ──
//   ✅ App Bar, Greeting, Prayer Strip, Date Card
//   ✅ Ayah of the Day (auto-rotating)
//   ✅ Ramadan Widget (purple gradient)
//   ✅ Nearby Mosques, Continue Reading, Hadith Card
//   ✅ Error State, Empty State
//   ✅ Timer 30s bug fix
//   ✅ All animations
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
import 'package:qibra_ai/core/providers/theme_provider.dart';

// ── Shared Widgets ───────────────────────────────────────
import 'package:qibra_ai/shared/widgets/cards/app_card.dart';

// ── 🆕 NEW PREMIUM WIDGETS (Phase 8 — Steps 2-7) ────────
import 'package:qibra_ai/shared/widgets/cards/app_hero_image_card.dart';
import 'package:qibra_ai/shared/widgets/cards/app_recent_surah_card.dart';
import 'package:qibra_ai/shared/widgets/cards/app_listen_card.dart';
import 'package:qibra_ai/shared/widgets/cards/app_feature_illustration_card.dart';
import 'package:qibra_ai/shared/widgets/indicators/app_circular_progress_ring.dart';

// ============================================================
// SECTION 1 — DATA MODELS
// ============================================================

/// Ayah of the day model
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

/// Quick action item model (circular icons — reference match)
class _QuickActionItem {
  final IconData actionIcon;
  final String actionTitle;
  final Color themeColor;
  final String routePath;

  const _QuickActionItem({
    required this.actionIcon,
    required this.actionTitle,
    required this.themeColor,
    required this.routePath,
  });
}

/// Prayer info model
class _PrayerInfo {
  final String prayerName;
  final String prayerNameArabic;
  final String prayerTime;
  final IconData prayerIcon;

  const _PrayerInfo({
    required this.prayerName,
    required this.prayerNameArabic,
    required this.prayerTime,
    required this.prayerIcon,
  });
}

/// Ramadan info model
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

/// Daily progress stat model (ENHANCED with progress value)
class _DailyProgressStat {
  final String statLabel;
  final String statValue;
  final IconData statIcon;
  final Color statColor;
  final double progressValue; // 🆕 0.0 - 1.0 for mini bars

  const _DailyProgressStat({
    required this.statLabel,
    required this.statValue,
    required this.statIcon,
    required this.statColor,
    required this.progressValue,
  });
}

/// Nearby mosque model
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

// ============================================================
// SECTION 2 — STATIC DATA
// ============================================================

/// Rotating ayahs list — 5 beautiful ayahs
const List<_AyahOfDay> _allAyahsList = [
  _AyahOfDay(
    arabicText: 'وَمَن يَتَّقِ اللَّهَ يَجْعَل لَّهُ مَخْرَجًا',
    translationText:
        'And whoever fears Allah — He will make for him a way out.',
    referenceText: '65:2',
    surahNameText: 'Surah At-Talaq',
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
    arabicText: 'فَإِنَّ مَعَ الْعُسْرِ يُسْرًا ۝ إِنَّ مَعَ الْعُسْرِ يُسْرًا',
    translationText:
        'So, truly with hardship comes ease. Truly with hardship comes ease.',
    referenceText: '94:5–6',
    surahNameText: 'Surah Ash-Sharh',
  ),
  _AyahOfDay(
    arabicText: 'اللَّهُ نُورُ السَّمَاوَاتِ وَالْأَرْضِ',
    translationText: 'Allah is the Light of the heavens and the earth.',
    referenceText: '24:35',
    surahNameText: 'Surah An-Nur',
  ),
];

/// Today's prayers list
const List<_PrayerInfo> _allPrayersList = [
  _PrayerInfo(
    prayerName: 'Fajr',
    prayerNameArabic: 'الْفَجْر',
    prayerTime: '5:12 AM',
    prayerIcon: Icons.wb_twilight_outlined,
  ),
  _PrayerInfo(
    prayerName: 'Dhuhr',
    prayerNameArabic: 'الظُّهْر',
    prayerTime: '12:30 PM',
    prayerIcon: Icons.wb_sunny_outlined,
  ),
  _PrayerInfo(
    prayerName: 'Asr',
    prayerNameArabic: 'الْعَصْر',
    prayerTime: '3:45 PM',
    prayerIcon: Icons.wb_cloudy_outlined,
  ),
  _PrayerInfo(
    prayerName: 'Maghrib',
    prayerNameArabic: 'الْمَغْرِب',
    prayerTime: '6:52 PM',
    prayerIcon: Icons.nights_stay_outlined,
  ),
  _PrayerInfo(
    prayerName: 'Isha',
    prayerNameArabic: 'الْعِشَاء',
    prayerTime: '8:15 PM',
    prayerIcon: Icons.star_outline,
  ),
];

/// Quick actions list — 6 circular icons (reference match!)
const List<_QuickActionItem> _allQuickActions = [
  _QuickActionItem(
    actionIcon: Icons.menu_book_rounded,
    actionTitle: 'Quran',
    themeColor: AppColors.primary,
    routePath: AppRoutes.quran,
  ),
  _QuickActionItem(
    actionIcon: Icons.collections_bookmark_rounded,
    actionTitle: 'Hadith',
    themeColor: Color(0xFFB45309),
    routePath: AppRoutes.hadith,
  ),
  _QuickActionItem(
    actionIcon: Icons.explore_rounded,
    actionTitle: 'Qibla',
    themeColor: Color(0xFF7C3AED),
    routePath: AppRoutes.qibla,
  ),
  _QuickActionItem(
    actionIcon: Icons.grain_rounded,
    actionTitle: 'Tasbih',
    themeColor: AppColors.accent,
    routePath: AppRoutes.tasbih,
  ),
  _QuickActionItem(
    actionIcon: Icons.volunteer_activism_rounded,
    actionTitle: 'Duas',
    themeColor: Color(0xFF0891B2),
    routePath: AppRoutes.dua,
  ),
  _QuickActionItem(
    actionIcon: Icons.auto_awesome_rounded,
    actionTitle: 'AI Chat',
    themeColor: Color(0xFF06B6D4),
    routePath: AppRoutes.aiChat,
  ),
];

/// Current Ramadan info
const _RamadanInfo _currentRamadanInfo = _RamadanInfo(
  isRamadanActive: false,
  daysRemaining: 87,
  currentRamadanDay: 0,
  sehriTime: '4:22 AM',
  iftarTime: '6:52 PM',
  hijriRamadanDate: '1 Ramadan 1447 AH',
);

/// 🆕 Daily progress stats (ENHANCED with progress values)
const List<_DailyProgressStat> _dailyProgressList = [
  _DailyProgressStat(
    statLabel: 'Quran',
    statValue: '20 min',
    statIcon: Icons.menu_book_rounded,
    statColor: AppColors.primary,
    progressValue: 0.66,
  ),
  _DailyProgressStat(
    statLabel: 'Hadith',
    statValue: '8/20',
    statIcon: Icons.format_quote_rounded,
    statColor: Color(0xFFB45309),
    progressValue: 0.40,
  ),
  _DailyProgressStat(
    statLabel: 'Duas',
    statValue: '12/40',
    statIcon: Icons.volunteer_activism_rounded,
    statColor: Color(0xFFF59E0B),
    progressValue: 0.30,
  ),
  _DailyProgressStat(
    statLabel: 'Tasbih',
    statValue: '66/200',
    statIcon: Icons.grain_rounded,
    statColor: AppColors.accent,
    progressValue: 0.33,
  ),
];

/// 🆕 NEW: Recently read surahs (reference match — 4 surahs)
const List<RecentSurahItem> _recentlyReadSurahs = [
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
    surahNumber: 3,
    surahName: 'Aal-E-Imran',
    versesCount: 200,
    surahNameArabic: 'آل عمران',
    revelationType: SurahRevelationType.madani,
  ),
  RecentSurahItem(
    surahNumber: 4,
    surahName: 'An-Nisa',
    versesCount: 176,
    surahNameArabic: 'النساء',
    revelationType: SurahRevelationType.madani,
  ),
];

/// 🆕 NEW: Feature grid items (reference match — 6 features)
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
];

/// Nearby mosques dummy data
const List<_NearbyMosque> _nearbyMosquesList = [
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

// ============================================================
// SECTION 3 — HOME SCREEN WIDGET
// ============================================================

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

// ============================================================
// SECTION 4 — STATE CLASS
// ============================================================

class _HomeScreenState extends ConsumerState<HomeScreen>
    with TickerProviderStateMixin {
  // ── TIMERS ──────────────────────────────────────────────
  Timer? _countdownTimer;
  Timer? _ayahRotationTimer;

  // ── ANIMATION CONTROLLERS ───────────────────────────────
  late final AnimationController _headerAnimationController;
  late final AnimationController _cardStaggerController;
  late final AnimationController _pulseAnimationController;
  late final AnimationController _ayahFadeController;

  // ── ANIMATIONS ──────────────────────────────────────────
  late final Animation<double> _headerFadeAnimation;
  late final Animation<Offset> _headerSlideAnimation;
  late final Animation<double> _pulseScaleAnimation;
  late final Animation<double> _ayahFadeAnimation;

  // ── STATE VARIABLES ─────────────────────────────────────

  // Countdown duration (updated every 30 seconds — bug fix v3.0)
  Duration _timeToNextPrayer =
      const Duration(hours: 1, minutes: 32, seconds: 0);

  // 🆕 Total gap for circular ring calculation
  static const Duration _totalPrayerGap = Duration(hours: 3, minutes: 15);

  int _currentAyahIndex = 0;
  bool _isAyahBookmarked = false;

  // 🆕 Listen card playback state
  ListenPlaybackState _listenPlaybackState = ListenPlaybackState.stopped;

  // ── HOME CONTENT STATE ──────────────────────────────────
  bool _hasLoadingError = false;
  bool _isContentEmpty = false;

  // ── NEXT PRAYER INDEX ────────────────────────────────────
  static const int _nextPrayerIndex = 2;

  // ── SCROLL CONTROLLER ───────────────────────────────────
  final ScrollController _scrollController = ScrollController();

  // ── SHORTCUTS ────────────────────────────────────────────
  _PrayerInfo get _nextPrayer => _allPrayersList[_nextPrayerIndex];
  _AyahOfDay get _currentAyah => _allAyahsList[_currentAyahIndex];

  // ============================================================
  // INIT STATE
  // ============================================================

  @override
  void initState() {
    super.initState();
    _initializeAnimationControllers();
    _startAnimations();
    _startCountdownTimer();
    _startAyahRotationTimer();
  }

  // ── INITIALIZE ALL ANIMATION CONTROLLERS ─────────────────
  void _initializeAnimationControllers() {
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

  // ── START ALL ANIMATIONS ─────────────────────────────────
  void _startAnimations() {
    _headerAnimationController.forward();

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _cardStaggerController.forward();
    });

    _ayahFadeController.forward();
  }

  // ============================================================
  // SECTION 5 — TIMERS (BUG FIXED v3.0 — 30s preserved)
  // ============================================================

  void _startCountdownTimer() {
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 30), // ✅ 30s to prevent scroll stuck
      (timer) {
        if (!mounted) return;
        if (_timeToNextPrayer.inSeconds > 30) {
          setState(() {
            _timeToNextPrayer = _timeToNextPrayer - const Duration(seconds: 30);
          });
        } else {
          timer.cancel();
          if (mounted) {
            setState(() {
              _timeToNextPrayer = Duration.zero;
            });
          }
        }
      },
    );
  }

  // ── AYAH ROTATION TIMER — 10 seconds ─────────────────────
  void _startAyahRotationTimer() {
    _ayahRotationTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (!mounted) return;
      _changeAyahWithAnimation();
    });
  }

  // ── CHANGE AYAH WITH FADE ANIMATION ─────────────────────
  void _changeAyahWithAnimation() {
    _ayahFadeController.reverse().then((_) {
      if (!mounted) return;
      setState(() {
        _currentAyahIndex = (_currentAyahIndex + 1) % _allAyahsList.length;
        _isAyahBookmarked = false;
      });
      _ayahFadeController.forward();
    });
  }

  // ── MANUAL AYAH CHANGE ───────────────────────────────────
  void _jumpToAyah(int targetIndex) {
    if (targetIndex == _currentAyahIndex) return;
    HapticFeedback.selectionClick();
    _ayahFadeController.reverse().then((_) {
      if (!mounted) return;
      setState(() {
        _currentAyahIndex = targetIndex;
        _isAyahBookmarked = false;
      });
      _ayahFadeController.forward();
    });
  }

  // 🆕 LISTEN CARD PLAY TOGGLE
  void _toggleListenPlayback() {
    HapticFeedback.mediumImpact();
    setState(() {
      if (_listenPlaybackState == ListenPlaybackState.playing) {
        _listenPlaybackState = ListenPlaybackState.paused;
      } else {
        _listenPlaybackState = ListenPlaybackState.playing;
      }
    });
    _showComingSoonSnackbar('Audio player coming in Phase 8.2');
  }

  // ── PULL TO REFRESH ──────────────────────────────────────
  Future<void> _handleRefresh() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _hasLoadingError = false;
    });

    await Future.delayed(const Duration(milliseconds: 1500));

    if (!mounted) return;
    setState(() {
      _timeToNextPrayer = const Duration(hours: 1, minutes: 32, seconds: 0);
    });
  }

  // ── CLEAR ERROR / EMPTY STATE ────────────────────────────
  void _clearSpecialState() {
    setState(() {
      _hasLoadingError = false;
      _isContentEmpty = false;
    });
  }

  // ── FORMAT COUNTDOWN ─────────────────────────────────────
  String get _formattedCountdown {
    final int totalSeconds = _timeToNextPrayer.inSeconds;
    final int hoursValue = totalSeconds ~/ 3600;
    final int minutesValue = (totalSeconds % 3600) ~/ 60;
    final int secondsValue = totalSeconds % 60;

    return '${hoursValue.toString().padLeft(2, '0')}:'
        '${minutesValue.toString().padLeft(2, '0')}:'
        '${secondsValue.toString().padLeft(2, '0')}';
  }

  // ── TIME-BASED GREETINGS ─────────────────────────────────
  String get _islamicGreetingEnglish {
    final int h = DateTime.now().hour;
    if (h >= 4 && h < 12) return 'Sabah al-khayr';
    if (h >= 12 && h < 17) return 'Asr al-khayr';
    return 'Masa al-khayr';
  }

  String get _islamicGreetingArabic {
    final int h = DateTime.now().hour;
    if (h >= 4 && h < 12) return 'صَبَاحُ الْخَيْر';
    if (h >= 12 && h < 17) return 'عَصْرُ الْخَيْر';
    return 'مَسَاءُ الْخَيْر';
  }

  String get _timeBasedEmoji {
    final int h = DateTime.now().hour;
    if (h >= 4 && h < 12) return '🌅';
    if (h >= 12 && h < 17) return '☀️';
    if (h >= 17 && h < 20) return '🌇';
    return '🏮';
  }

  // ── DATE HELPERS ─────────────────────────────────────────
  String _getWeekdayName(int weekday) {
    const List<String> days = [
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

  String _getMonthName(int month) {
    const List<String> months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month - 1];
  }

  String get _formattedGregorianDate {
    final DateTime now = DateTime.now();
    return '${_getWeekdayName(now.weekday)}, '
        '${now.day} ${_getMonthName(now.month)} ${now.year}';
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _ayahRotationTimer?.cancel();
    _headerAnimationController.dispose();
    _cardStaggerController.dispose();
    _pulseAnimationController.dispose();
    _ayahFadeController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ============================================================
  // SECTION 6 — BUILD METHOD (v4.0 with all sections)
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final String userName = ref.watch(userDisplayNameProvider);

    // ── ERROR STATE ─────────────────────────────────────────
    if (_hasLoadingError) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: _buildErrorState(),
      );
    }

    // ── EMPTY STATE ─────────────────────────────────────────
    if (_isContentEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: _buildEmptyState(),
      );
    }

    // ── NORMAL STATE ────────────────────────────────────────
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
            _buildPremiumAppBar(userName),
            SliverPadding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl6),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ═══════ REFERENCE MATCH SECTIONS ═══════

                  // 1. Greeting section
                  const SizedBox(height: AppSpacing.lg),
                  _buildGreetingSection(userName),

                  // 2. 🔄 REDESIGNED: Circular Prayer Countdown Card
                  const SizedBox(height: AppSpacing.xl2),
                  _buildPrayerCountdownCard(),

                  // 3. All prayers strip
                  const SizedBox(height: AppSpacing.md),
                  _buildAllPrayersStrip(),

                  // 4. Date card
                  const SizedBox(height: AppSpacing.xl2),
                  _buildSectionHeader(
                    sectionTitle: 'TODAY',
                    sectionIcon: Icons.today_rounded,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildDateCard(),

                  // 5. 🔄 ENHANCED: Daily Progress with Mini Bars
                  const SizedBox(height: AppSpacing.xl2),
                  _buildSectionHeader(
                    sectionTitle: 'DAILY PROGRESS',
                    sectionIcon: Icons.insights_rounded,
                    trailingWidget: _buildSeeAllButton(
                      onTapAction: () {
                        HapticFeedback.lightImpact();
                        _showComingSoonSnackbar('Progress tracker coming soon');
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildDailyProgressRow(),

                  // 6. 🔄 REDESIGNED: Circular Quick Actions
                  const SizedBox(height: AppSpacing.xl2),
                  _buildSectionHeader(
                    sectionTitle: 'QUICK ACCESS',
                    sectionIcon: Icons.grid_view_rounded,
                    trailingWidget: _buildEditButton(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildQuickAccessCircles(),

                  // 7. 🆕 NEW: Recently Read Surahs
                  const SizedBox(height: AppSpacing.xl2),
                  _buildSectionHeader(
                    sectionTitle: 'RECENTLY READ',
                    sectionIcon: Icons.menu_book_rounded,
                    trailingWidget: _buildSeeAllButton(
                      onTapAction: () {
                        HapticFeedback.lightImpact();
                        context.go(AppRoutes.quran);
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildRecentlyReadSection(),

                  // 8. 🆕 NEW: Daily Verse Card
                  const SizedBox(height: AppSpacing.xl2),
                  _buildSectionHeader(
                    sectionTitle: 'DAILY VERSE',
                    sectionIcon: Icons.auto_awesome_rounded,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildDailyVerseCard(),

                  // 9. 🆕 NEW: Listen to Quran Card
                  const SizedBox(height: AppSpacing.xl2),
                  _buildListenToQuranCard(),

                  // ═══════ BONUS SECTIONS (Preserved from v3.0) ═══════

                  // 10. Ayah of the day (with rotation)
                  const SizedBox(height: AppSpacing.xl2),
                  _buildSectionHeader(
                    sectionTitle: 'AYAH OF THE DAY',
                    sectionIcon: Icons.auto_stories_rounded,
                    trailingWidget: _buildAyahDotIndicators(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildAyahOfTheDayCard(),

                  // 11. Ramadan Widget
                  const SizedBox(height: AppSpacing.xl2),
                  _buildSectionHeader(
                    sectionTitle: 'RAMADAN',
                    sectionIcon: Icons.nightlight_round,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildRamadanWidget(),

                  // 12. Nearby Mosques
                  const SizedBox(height: AppSpacing.xl2),
                  _buildSectionHeader(
                    sectionTitle: 'NEARBY MOSQUES',
                    sectionIcon: Icons.mosque_rounded,
                    trailingWidget: _buildSeeAllButton(
                      onTapAction: () {
                        HapticFeedback.lightImpact();
                        _showComingSoonSnackbar('Mosque finder coming soon');
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildNearbyMosqueSection(),

                  // 13. Continue reading
                  const SizedBox(height: AppSpacing.xl2),
                  _buildSectionHeader(
                    sectionTitle: 'CONTINUE READING',
                    sectionIcon: Icons.bookmark_rounded,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildContinueReadingCard(),

                  // 14. Hadith of the day
                  const SizedBox(height: AppSpacing.xl2),
                  _buildSectionHeader(
                    sectionTitle: 'HADITH OF THE DAY',
                    sectionIcon: Icons.format_quote_rounded,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildHadithCard(),

                  // 15. 🆕 NEW: Feature Grid (6 3D cards)
                  const SizedBox(height: AppSpacing.xl3),
                  _buildSectionHeader(
                    sectionTitle: 'ALL FEATURES',
                    sectionIcon: Icons.apps_rounded,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildFeatureGrid(),

                  // 16. 🆕 NEW: Golden Arabic Watermark
                  const SizedBox(height: AppSpacing.xl3),
                  _buildGoldenArabicWatermark(),

                  // Bottom breathing room
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
  // ⏸️ PART A ENDS HERE — Line count: ~700
  // ============================================================
  // PART B will contain:
  //   - _buildPremiumAppBar (kept)
  //   - _buildAvatarWidget (kept)
  //   - _buildGreetingSection (kept)
  //   - _buildPrayerCountdownCard 🔄 REDESIGNED (circular ring)
  //   - _buildAllPrayersStrip (kept)
  //   - _buildSectionHeader (kept)
  //   - _buildSeeAllButton (kept)
  //   - _buildEditButton 🆕 NEW
  //   - _buildDateCard (kept)
  //   - _buildDailyProgressRow 🔄 ENHANCED (mini bars)
  //   - _buildQuickAccessCircles 🔄 REDESIGNED (circular)
  //   - _buildRecentlyReadSection 🆕 NEW
  //   - _buildDailyVerseCard 🆕 NEW
  //   - _buildListenToQuranCard 🆕 NEW
  //
  // PART C will contain:
  //   - _buildAyahDotIndicators (kept)
  //   - _buildAyahOfTheDayCard (kept)
  //   - _buildRamadanWidget + all sub-widgets (kept)
  //   - _buildNearbyMosqueSection + _buildMosqueCard (kept)
  //   - _buildContinueReadingCard (kept)
  //   - _buildHadithCard (kept)
  //   - _buildFeatureGrid 🆕 NEW
  //   - _buildGoldenArabicWatermark 🆕 NEW
  //   - _buildErrorState (kept)
  //   - _buildEmptyState (kept)
  //   - _buildFeatureChip (kept)
  //   - _showComingSoonSnackbar (kept)
  //   - END of file
  // ============================================================

  // ============================================================
  // SECTION 7 — PREMIUM APP BAR (KEPT from v3.0)
  // ============================================================

  Widget _buildPremiumAppBar(String userName) {
    final bool isDarkModeEnabled = ref.watch(isDarkModeProvider);

    return SliverAppBar(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      pinned: false,
      floating: true,
      snap: true,
      expandedHeight: 70,
      leadingWidth: 72,
      leading: Padding(
        padding: const EdgeInsets.only(
          left: AppSpacing.lg,
          top: AppSpacing.sm,
          bottom: AppSpacing.sm,
        ),
        child: FadeTransition(
          opacity: _headerFadeAnimation,
          child: _buildAvatarWidget(userName),
        ),
      ),
      title: FadeTransition(
        opacity: _headerFadeAnimation,
        child: SlideTransition(
          position: _headerSlideAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _islamicGreetingArabic,
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 13,
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                ),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: 2),
              Text(
                userName.isNotEmpty ? userName : 'Muslim',
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
      actions: [
        FadeTransition(
          opacity: _headerFadeAnimation,
          child: Container(
            margin: const EdgeInsets.only(top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderSubtle, width: 1),
            ),
            child: IconButton(
              icon: Icon(
                isDarkModeEnabled
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
                color: AppColors.iconSecondary,
                size: 20,
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                ref.read(themeProvider.notifier).toggleTheme();
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        FadeTransition(
          opacity: _headerFadeAnimation,
          child: Container(
            margin: const EdgeInsets.only(top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderSubtle, width: 1),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.notifications_outlined,
                    color: AppColors.iconSecondary,
                    size: 20,
                  ),
                  onPressed: () => HapticFeedback.lightImpact(),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 38,
                    minHeight: 38,
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.background,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
      ],
    );
  }

  // ── AVATAR WIDGET (KEPT from v3.0) ────────────────────────
  Widget _buildAvatarWidget(String userName) {
    final String firstInitial =
        userName.isNotEmpty ? userName[0].toUpperCase() : 'U';

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.go(AppRoutes.profile);
      },
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          gradient: AppGradients.emerald,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            firstInitial,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SECTION 8 — GREETING SECTION (KEPT from v3.0)
  // ============================================================

  Widget _buildGreetingSection(String userName) {
    final String firstName =
        userName.contains(' ') ? userName.split(' ').first : userName;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: FadeTransition(
        opacity: _headerFadeAnimation,
        child: SlideTransition(
          position: _headerSlideAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 3,
                    height: 16,
                    decoration: BoxDecoration(
                      gradient: AppGradients.gold,
                      borderRadius: AppRadius.pillRadius,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Assalamu Alaikum',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.accent,
                      letterSpacing: 2.0,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              RichText(
                text: TextSpan(
                  style: AppTextStyles.headlineMedium.copyWith(
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                    color: AppColors.textPrimary,
                  ),
                  children: [
                    TextSpan(text: '$_islamicGreetingEnglish,\n'),
                    TextSpan(
                      text: firstName.isNotEmpty ? firstName : 'Muslim',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    TextSpan(
                      text: '  $_timeBasedEmoji',
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SECTION 9 — 🔄 REDESIGNED: PRAYER COUNTDOWN CARD (CIRCULAR)
  // ============================================================

  Widget _buildPrayerCountdownCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
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
              stops: [0.0, 0.6, 1.0],
            ),
            borderRadius: AppRadius.cardRadiusLarge,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.45),
                blurRadius: 24,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.20),
                blurRadius: 48,
                spreadRadius: 0,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: AppRadius.cardRadiusLarge,
            child: Stack(
              children: [
                // Background decorations
                Positioned(
                  right: -20,
                  top: -20,
                  child: Icon(
                    Icons.mosque_rounded,
                    size: 160,
                    color: AppColors.white.withValues(alpha: 0.06),
                  ),
                ),
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
                Positioned(
                  left: -30,
                  bottom: -30,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.white.withValues(alpha: 0.04),
                    ),
                  ),
                ),

                // Main content
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top row: Next Prayer label + Location
                      _buildPrayerCardTopRow(),

                      const SizedBox(height: AppSpacing.xl2),

                      // 🔄 NEW: Split layout — Prayer name (left) + Ring (right)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Left: Prayer name + time
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildPrayerNameRow(),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'at ${_nextPrayer.prayerTime}',
                                  style: AppTextStyles.bodyLarge.copyWith(
                                    color:
                                        AppColors.white.withValues(alpha: 0.75),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Right: 🆕 CIRCULAR PROGRESS RING
                          AppPrayerCountdownRing(
                            timeRemaining: _timeToNextPrayer,
                            totalDuration: _totalPrayerGap,
                            size: 110,
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
    );
  }

  Widget _buildPrayerCardTopRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.18),
                borderRadius: AppRadius.buttonRadius,
              ),
              child: const Icon(
                Icons.access_time_filled_rounded,
                color: AppColors.white,
                size: 14,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'NEXT PRAYER',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.white.withValues(alpha: 0.90),
                letterSpacing: 2.0,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: () => HapticFeedback.lightImpact(),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.15),
              borderRadius: AppRadius.pillRadius,
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  color: AppColors.white,
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  'Karachi',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 3),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppColors.white.withValues(alpha: 0.70),
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrayerNameRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: Text(
            _nextPrayer.prayerName,
            style: AppTextStyles.displaySmall.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w900,
              height: 1.0,
              letterSpacing: -0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Text(
            _nextPrayer.prayerNameArabic,
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontSize: 20,
              color: AppColors.white,
              fontWeight: FontWeight.w600,
              height: 1.0,
            ),
            textDirection: TextDirection.rtl,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SECTION 10 — ALL PRAYERS STRIP (KEPT from v3.0)
  // ============================================================

  Widget _buildAllPrayersStrip() {
    return SizedBox(
      height: 80,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        physics: const BouncingScrollPhysics(),
        itemCount: _allPrayersList.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final _PrayerInfo prayer = _allPrayersList[index];
          final bool isNext = index == _nextPrayerIndex;
          final bool isDone = index < _nextPrayerIndex;

          return _buildPrayerStripItem(
            prayerItem: prayer,
            isHighlighted: isNext,
            isCompleted: isDone,
          );
        },
      ),
    );
  }

  Widget _buildPrayerStripItem({
    required _PrayerInfo prayerItem,
    required bool isHighlighted,
    required bool isCompleted,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        context.go(AppRoutes.prayer);
      },
      child: AnimatedContainer(
        duration: AppDurations.fast,
        width: 72,
        decoration: BoxDecoration(
          gradient: isHighlighted ? AppGradients.emerald : null,
          color: isHighlighted ? null : AppColors.surface,
          borderRadius: AppRadius.cardRadius,
          border: Border.all(
            color: isHighlighted
                ? Colors.transparent
                : isCompleted
                    ? AppColors.primary.withValues(alpha: 0.30)
                    : AppColors.borderSubtle,
            width: 1,
          ),
          boxShadow: isHighlighted
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.30),
                    blurRadius: 10,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isCompleted ? Icons.check_circle_rounded : prayerItem.prayerIcon,
              size: 18,
              color: isHighlighted
                  ? AppColors.white
                  : isCompleted
                      ? AppColors.primary
                      : AppColors.iconSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              prayerItem.prayerName,
              style: AppTextStyles.labelSmall.copyWith(
                color: isHighlighted
                    ? AppColors.white
                    : isCompleted
                        ? AppColors.primary
                        : AppColors.textSecondary,
                fontWeight: isHighlighted ? FontWeight.w700 : FontWeight.w500,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              prayerItem.prayerTime,
              style: AppTextStyles.labelSmall.copyWith(
                color: isHighlighted
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
  // SECTION 11 — SECTION HEADER + BUTTONS (KEPT + NEW)
  // ============================================================

  Widget _buildSectionHeader({
    required String sectionTitle,
    required IconData sectionIcon,
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
          Icon(sectionIcon, color: AppColors.accent, size: 16),
          const SizedBox(width: AppSpacing.xs),
          Text(
            sectionTitle,
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

  // ── SEE ALL BUTTON (KEPT from v3.0) ──────────────────────
  Widget _buildSeeAllButton({required VoidCallback onTapAction}) {
    return GestureDetector(
      onTap: onTapAction,
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
            width: 1,
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

  // 🆕 NEW: Edit Button (for Quick Access)
  Widget _buildEditButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _showComingSoonSnackbar('Customize quick access coming soon');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.10),
          borderRadius: AppRadius.pillRadius,
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.30),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.edit_outlined,
              color: AppColors.primary,
              size: 10,
            ),
            const SizedBox(width: 3),
            Text(
              'Edit',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SECTION 12 — DATE CARD (KEPT from v3.0)
  // ============================================================

  Widget _buildDateCard() {
    const String hijriDateText = '15 Rabi al-Thani 1446 AH';
    const String specialEventText = 'Jumu\'ah Mubarak!';
    final bool isFriday = DateTime.now().weekday == DateTime.friday;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: AppCard(
        onTap: () {
          HapticFeedback.lightImpact();
          context.go(AppRoutes.islamicCalendar);
        },
        child: Row(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                gradient: AppGradients.gold,
                borderRadius: AppRadius.cardRadius,
                boxShadow: AppShadows.goldGlow,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateTime.now().day.toString(),
                    style: AppTextStyles.titleLarge.copyWith(
                      color: AppColors.background,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                    ),
                  ),
                  Text(
                    _getMonthName(DateTime.now().month)
                        .substring(0, 3)
                        .toUpperCase(),
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.background.withValues(alpha: 0.75),
                      fontWeight: FontWeight.w700,
                      fontSize: 9,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hijriDateText,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _formattedGregorianDate,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  if (isFriday) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppGradients.gold,
                        borderRadius: AppRadius.pillRadius,
                      ),
                      child: Text(
                        specialEventText,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.background,
                          fontWeight: FontWeight.w700,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SECTION 13 — 🔄 ENHANCED: DAILY PROGRESS ROW (MINI BARS)
  // ============================================================

  Widget _buildDailyProgressRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: List.generate(_dailyProgressList.length, (index) {
          final _DailyProgressStat stat = _dailyProgressList[index];
          final bool isLast = index == _dailyProgressList.length - 1;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: isLast ? 0 : AppSpacing.sm),
              child: _buildProgressTile(stat),
            ),
          );
        }),
      ),
    );
  }

  // 🆕 NEW: Vertical progress tile with mini bar
  Widget _buildProgressTile(_DailyProgressStat statItem) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color: statItem.statColor.withValues(alpha: 0.20),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: statItem.statColor.withValues(alpha: 0.08),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon + Label row
          Row(
            children: [
              Icon(
                statItem.statIcon,
                color: statItem.statColor,
                size: 12,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  statItem.statLabel,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: statItem.statColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Value (bold)
          Text(
            statItem.statValue,
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              height: 1.0,
              fontSize: 13,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 6),

          // Mini progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: statItem.progressValue.clamp(0.0, 1.0),
              backgroundColor: statItem.statColor.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(statItem.statColor),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION 14 — 🔄 REDESIGNED: QUICK ACCESS CIRCLES
  // ============================================================

  Widget _buildQuickAccessCircles() {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        physics: const BouncingScrollPhysics(),
        itemCount: _allQuickActions.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          return _buildQuickAccessCircle(
            actionItem: _allQuickActions[index],
            staggerDelay: Duration(milliseconds: 100 + (index * 60)),
          );
        },
      ),
    );
  }

  // 🆕 NEW: Single circular quick access button
  Widget _buildQuickAccessCircle({
    required _QuickActionItem actionItem,
    required Duration staggerDelay,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      builder: (context, value, child) =>
          Transform.scale(scale: value, child: child),
      child: GestureDetector(
        onTapDown: (_) => HapticFeedback.lightImpact(),
        onTap: () {
          HapticFeedback.mediumImpact();
          context.go(actionItem.routePath);
        },
        child: SizedBox(
          width: 70,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Circular icon container
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      actionItem.themeColor.withValues(alpha: 0.20),
                      actionItem.themeColor.withValues(alpha: 0.08),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: actionItem.themeColor.withValues(alpha: 0.35),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: actionItem.themeColor.withValues(alpha: 0.15),
                      blurRadius: 12,
                      spreadRadius: 0,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  actionItem.actionIcon,
                  color: actionItem.themeColor,
                  size: 26,
                ),
              ),

              const SizedBox(height: 6),

              // Label
              Text(
                actionItem.actionTitle,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                  height: 1.0,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SECTION 15 — 🆕 NEW: RECENTLY READ SECTION
  // ============================================================

  Widget _buildRecentlyReadSection() {
    return AppRecentSurahList(
      surahs: _recentlyReadSurahs,
      cardSize: RecentSurahCardSize.standard,
      onSurahTap: (surah) {
        HapticFeedback.mediumImpact();
        _showComingSoonSnackbar('Opening ${surah.surahName} in Phase 8.2');
      },
    );
  }

  // ============================================================
  // SECTION 16 — 🆕 NEW: DAILY VERSE CARD (with mosque bg)
  // ============================================================

  Widget _buildDailyVerseCard() {
    // Use current ayah from rotation for dynamic content
    final _AyahOfDay displayedVerse = _currentAyah;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: AppVerseHeroCard(
        height: 200,
        onTap: () {
          HapticFeedback.lightImpact();
          _showComingSoonSnackbar('Verse details coming soon');
        },
        childPadding: const EdgeInsets.all(AppSpacing.xl2),
        child: FadeTransition(
          opacity: _ayahFadeAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Top: Share button
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: () => HapticFeedback.lightImpact(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.20),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.white.withValues(alpha: 0.30),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.share_outlined,
                      color: AppColors.white,
                      size: 14,
                    ),
                  ),
                ),
              ),

              // Center: Arabic + Translation + Reference
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Arabic text
                  Text(
                    displayedVerse.arabicText,
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 22,
                      color: AppColors.white,
                      fontWeight: FontWeight.w600,
                      height: 1.6,
                    ),
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Translation
                  Text(
                    '"${displayedVerse.translationText}"',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.white.withValues(alpha: 0.90),
                      fontStyle: FontStyle.italic,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const SizedBox(height: AppSpacing.xs),

                  // Reference
                  Text(
                    '— ${displayedVerse.surahNameText} (${displayedVerse.referenceText})',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                    textAlign: TextAlign.center,
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
  // SECTION 17 — 🆕 NEW: LISTEN TO QURAN CARD (with waveform)
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
          _showComingSoonSnackbar('Full audio player coming in Phase 8.2');
        },
      ),
    );
  }

  // ============================================================
  // ⏸️ PART B ENDS HERE — Line count: ~1500
  // ============================================================
  // PART C will contain:
  //   - _buildAyahDotIndicators (kept)
  //   - _buildAyahOfTheDayCard (kept)
  //   - _buildRamadanWidget + sub-widgets (kept)
  //   - _buildNearbyMosqueSection + _buildMosqueCard (kept)
  //   - _buildContinueReadingCard (kept)
  //   - _buildHadithCard (kept)
  //   - 🆕 _buildFeatureGrid
  //   - 🆕 _buildGoldenArabicWatermark
  //   - _buildErrorState (kept)
  //   - _buildEmptyState (kept)
  //   - _buildFeatureChip (kept)
  //   - _showComingSoonSnackbar (kept)
  //   - END OF FILE
  // ============================================================

  // ============================================================
  // SECTION 18 — AYAH DOT INDICATORS (KEPT from v3.0 — bonus)
  // ============================================================

  Widget _buildAyahDotIndicators() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(_allAyahsList.length, (index) {
        final bool isActive = index == _currentAyahIndex;
        return GestureDetector(
          onTap: () => _jumpToAyah(index),
          child: AnimatedContainer(
            duration: AppDurations.fast,
            width: isActive ? 16 : 6,
            height: 6,
            margin: const EdgeInsets.only(left: 3),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.accent
                  : AppColors.accent.withValues(alpha: 0.30),
              borderRadius: AppRadius.pillRadius,
            ),
          ),
        );
      }),
    );
  }

  // ============================================================
  // SECTION 19 — AYAH OF THE DAY CARD (KEPT from v3.0 — bonus)
  // ============================================================

  Widget _buildAyahOfTheDayCard() {
    final _AyahOfDay displayedAyah = _currentAyah;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: FadeTransition(
        opacity: _ayahFadeAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.cardRadiusLarge,
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.20),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.08),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: AppRadius.cardRadiusLarge,
            child: Stack(
              children: [
                Positioned(
                  top: -10,
                  right: -10,
                  child: Icon(
                    Icons.auto_stories_rounded,
                    size: 100,
                    color: AppColors.accent.withValues(alpha: 0.04),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.xl2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 3,
                        decoration: BoxDecoration(
                          gradient: AppGradients.gold,
                          borderRadius: AppRadius.pillRadius,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          displayedAyah.arabicText,
                          style: const TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 26,
                            color: AppColors.textPrimary,
                            height: 2.0,
                            fontWeight: FontWeight.w600,
                          ),
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              color: AppColors.borderSubtle,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                            ),
                            child: Icon(
                              Icons.star_rounded,
                              color: AppColors.accent.withValues(alpha: 0.40),
                              size: 12,
                            ),
                          ),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: AppColors.borderSubtle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        '"${displayedAyah.translationText}"',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.7,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: AppSpacing.xs,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.10),
                              borderRadius: AppRadius.pillRadius,
                              border: Border.all(
                                color: AppColors.accent.withValues(alpha: 0.25),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.bookmark_rounded,
                                  color: AppColors.accent,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${displayedAyah.surahNameText} · ${displayedAyah.referenceText}',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.accent,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {
                                  HapticFeedback.lightImpact();
                                  setState(() {
                                    _isAyahBookmarked = !_isAyahBookmarked;
                                  });
                                },
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: _isAyahBookmarked
                                        ? AppColors.accent
                                            .withValues(alpha: 0.15)
                                        : AppColors.surfaceElevated,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: _isAyahBookmarked
                                          ? AppColors.accent
                                              .withValues(alpha: 0.40)
                                          : AppColors.borderSubtle,
                                      width: 1,
                                    ),
                                  ),
                                  child: Icon(
                                    _isAyahBookmarked
                                        ? Icons.bookmark_rounded
                                        : Icons.bookmark_outline_rounded,
                                    color: _isAyahBookmarked
                                        ? AppColors.accent
                                        : AppColors.iconSecondary,
                                    size: 16,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              GestureDetector(
                                onTap: () => HapticFeedback.lightImpact(),
                                child: Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: AppColors.surfaceElevated,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: AppColors.borderSubtle,
                                      width: 1,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.share_outlined,
                                    color: AppColors.iconSecondary,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ],
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
    );
  }

  // ============================================================
  // SECTION 20 — RAMADAN WIDGET (KEPT from v3.0 — bonus)
  // ============================================================

  Widget _buildRamadanWidget() {
    const _RamadanInfo ramadanData = _currentRamadanInfo;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          _showComingSoonSnackbar('Ramadan calendar coming soon');
        },
        child: Container(
          constraints: const BoxConstraints(
            minHeight: 280,
            maxHeight: 340,
          ),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF6B21A8),
                Color(0xFF4C1D95),
                Color(0xFF1E1B4B),
              ],
              stops: [0.0, 0.6, 1.0],
            ),
            borderRadius: AppRadius.cardRadiusLarge,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6B21A8).withValues(alpha: 0.40),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: AppRadius.cardRadiusLarge,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned.fill(
                  child: _buildDecorativeStars(),
                ),
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

  Widget _buildDecorativeStars() {
    return Stack(
      children: [
        Positioned(
          top: 30,
          left: 40,
          child: Icon(
            Icons.star_rounded,
            size: 10,
            color: const Color(0xFFFFD700).withValues(alpha: 0.60),
          ),
        ),
        Positioned(
          top: 80,
          left: 80,
          child: Icon(
            Icons.star_rounded,
            size: 6,
            color: const Color(0xFFFFD700).withValues(alpha: 0.40),
          ),
        ),
        Positioned(
          top: 120,
          right: 40,
          child: Icon(
            Icons.star_rounded,
            size: 8,
            color: const Color(0xFFFFD700).withValues(alpha: 0.50),
          ),
        ),
        Positioned(
          bottom: 60,
          left: 120,
          child: Icon(
            Icons.auto_awesome,
            size: 12,
            color: const Color(0xFFFFD700).withValues(alpha: 0.30),
          ),
        ),
      ],
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
                  width: 1,
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
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: ramadanData.isRamadanActive
                      ? const Color(0xFF10B981)
                      : AppColors.white.withValues(alpha: 0.70),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Text(
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
            ],
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
        const SizedBox(height: AppSpacing.xs),
        Text(
          ramadanData.hijriRamadanDate,
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.white.withValues(alpha: 0.75),
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
          width: 1,
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
        Expanded(
          child: Column(
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
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SECTION 21 — NEARBY MOSQUE SECTION (KEPT from v3.0 — bonus)
  // ============================================================

  Widget _buildNearbyMosqueSection() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 220,
          width: double.infinity,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            physics: const BouncingScrollPhysics(),
            itemCount: _nearbyMosquesList.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
            itemBuilder: (context, index) {
              return _buildMosqueCard(_nearbyMosquesList[index], index);
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _showComingSoonSnackbar('Mosque map view coming soon');
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.cardRadius,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.30),
                  width: 1,
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
    final List<Color> cardGradients = [
      const Color(0xFF004D2E),
      const Color(0xFF003D26),
      const Color(0xFF1A3A2A),
    ];

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        _showComingSoonSnackbar('Mosque details coming soon');
      },
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.cardRadiusLarge,
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.20),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.08),
              blurRadius: 12,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
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
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      cardGradients[index % cardGradients.length],
                      AppColors.primary.withValues(alpha: 0.80),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -10,
                      bottom: -10,
                      child: Icon(
                        Icons.mosque_rounded,
                        size: 90,
                        color: AppColors.white.withValues(alpha: 0.10),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: mosque.isOpen
                                      ? const Color(0xFF10B981)
                                          .withValues(alpha: 0.25)
                                      : AppColors.error.withValues(alpha: 0.25),
                                  borderRadius: AppRadius.pillRadius,
                                  border: Border.all(
                                    color: mosque.isOpen
                                        ? const Color(0xFF10B981)
                                            .withValues(alpha: 0.60)
                                        : AppColors.error
                                            .withValues(alpha: 0.60),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  mosque.isOpen ? 'OPEN' : 'CLOSED',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: mosque.isOpen
                                        ? const Color(0xFF10B981)
                                        : AppColors.error,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 8,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.white.withValues(alpha: 0.18),
                                  borderRadius: AppRadius.pillRadius,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.near_me_rounded,
                                      color: AppColors.white,
                                      size: 10,
                                    ),
                                    const SizedBox(width: 3),
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
                            ],
                          ),
                          Row(
                            children: [
                              ...List.generate(5, (starIndex) {
                                return Icon(
                                  starIndex < mosque.rating.floor()
                                      ? Icons.star_rounded
                                      : starIndex < mosque.rating
                                          ? Icons.star_half_rounded
                                          : Icons.star_outline_rounded,
                                  color: const Color(0xFFFFD700),
                                  size: 12,
                                );
                              }),
                              const SizedBox(width: 4),
                              Text(
                                mosque.rating.toString(),
                                style: AppTextStyles.labelSmall.copyWith(
                                  color:
                                      AppColors.white.withValues(alpha: 0.85),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 10,
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
              SizedBox(
                height: 130,
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
                          height: 1.2,
                        ),
                        textDirection: TextDirection.rtl,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: AppColors.textTertiary,
                            size: 11,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              mosque.mosqueAddress,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textTertiary,
                                fontSize: 10,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.10),
                          borderRadius: AppRadius.buttonRadius,
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.access_time_filled_rounded,
                              color: AppColors.primary,
                              size: 11,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'Next: ${mosque.nextJamaat}',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ],
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
  // SECTION 22 — CONTINUE READING CARD (KEPT from v3.0 — bonus)
  // ============================================================

  Widget _buildContinueReadingCard() {
    const double progress = 0.35;
    const String surahName = 'Surah Al-Baqarah';
    const String ayahDetail = 'Ayah 255 · Al-Kursi';
    const String ayahArabic = 'ٱللَّهُ لَآ إِلَـٰهَ إِلَّا هُوَ';
    const int totalAyahs = 286;
    const int currentAyah = 255;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          context.go(AppRoutes.quran);
        },
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.cardRadiusLarge,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.20),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.08),
                blurRadius: 20,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: AppRadius.cardRadiusLarge,
            child: Column(
              children: [
                const LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.borderSubtle,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  minHeight: 3,
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 64,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.10),
                          borderRadius: AppRadius.cardRadius,
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.25),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.bookmark_rounded,
                              color: AppColors.primary,
                              size: 22,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Pg ${(currentAyah / 15).ceil()}',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 8,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CONTINUE READING',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.primary,
                                letterSpacing: 1.5,
                                fontWeight: FontWeight.w700,
                                fontSize: 9,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              surahName,
                              style: AppTextStyles.titleSmall.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              ayahDetail,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            const Text(
                              ayahArabic,
                              style: TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: 14,
                                color: AppColors.accent,
                                fontWeight: FontWeight.w600,
                                height: 1.5,
                              ),
                              textDirection: TextDirection.rtl,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: AppRadius.pillRadius,
                                    child: const LinearProgressIndicator(
                                      value: progress,
                                      backgroundColor: AppColors.borderSubtle,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        AppColors.primary,
                                      ),
                                      minHeight: 5,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Text(
                                  '${(progress * 100).toStringAsFixed(0)}%',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '$currentAyah of $totalAyahs ayahs',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textTertiary,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: AppGradients.emerald,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.40),
                              blurRadius: 10,
                              spreadRadius: 0,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: AppColors.white,
                          size: 22,
                        ),
                      ),
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

  // ============================================================
  // SECTION 23 — HADITH CARD (KEPT from v3.0 — bonus)
  // ============================================================

  Widget _buildHadithCard() {
    const String narrator = 'Abu Hurairah (RA)';
    const String collection = 'Sahih al-Bukhari · 6477';
    const String hadithBody =
        'The Prophet ﷺ said: "Whoever believes in Allah and the Last Day should speak a good word or remain silent. And whoever believes in Allah and the Last Day should show hospitality to his neighbor."';
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
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFB45309).withValues(alpha: 0.07),
                blurRadius: 16,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: AppRadius.cardRadiusLarge,
            child: Stack(
              children: [
                Positioned(
                  top: -5,
                  left: -5,
                  child: Icon(
                    Icons.format_quote_rounded,
                    size: 80,
                    color: const Color(0xFFB45309).withValues(alpha: 0.05),
                  ),
                ),
                Padding(
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
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFB45309)
                                  .withValues(alpha: 0.10),
                              borderRadius: AppRadius.pillRadius,
                              border: Border.all(
                                color: const Color(0xFFB45309)
                                    .withValues(alpha: 0.25),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              collection,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: const Color(0xFFB45309),
                                fontWeight: FontWeight.w700,
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color:
                              const Color(0xFFB45309).withValues(alpha: 0.05),
                          borderRadius: AppRadius.cardRadius,
                          border: Border.all(
                            color:
                                const Color(0xFFB45309).withValues(alpha: 0.12),
                            width: 1,
                          ),
                        ),
                        child: const Text(
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
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        hadithBody,
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.7,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFB45309)
                                      .withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.person_outline_rounded,
                                  color: Color(0xFFB45309),
                                  size: 14,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                narrator,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ],
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SECTION 24 — 🆕 NEW: FEATURE GRID (6 3D cards)
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
            _showComingSoonSnackbar('${feature.title} opening soon');
          },
        );
      }).toList(),
      cardSize: FeatureCardSize.standard,
    );
  }

  // ============================================================
  // SECTION 25 — 🆕 NEW: GOLDEN ARABIC WATERMARK
  // ============================================================

  Widget _buildGoldenArabicWatermark() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          // Divider with star
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

          // Arabic calligraphy
          ShaderMask(
            shaderCallback: (bounds) => LinearGradient(
              colors: [
                const Color(0xFFFFD700),
                const Color(0xFFB8960C),
                const Color(0xFFFFD700).withValues(alpha: 0.80),
              ],
              stops: const [0.0, 0.5, 1.0],
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

          // English translation
          Text(
            'May Allah reward you',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.accent.withValues(alpha: 0.70),
              fontStyle: FontStyle.italic,
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),

          const SizedBox(height: AppSpacing.sm),

          // App name subtle
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
  // SECTION 26 — ERROR STATE (KEPT from v3.0 — Option B)
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
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.wifi_off_rounded,
                      color: AppColors.error,
                      size: 40,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '!',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl2),
              const Text(
                'لَا تَيْأَسُوا',
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 28,
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Something went wrong',
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'We couldn\'t load your dashboard. Please check your connection and try again.',
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
              const SizedBox(height: AppSpacing.md),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _clearSpecialState();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.buttonRadius,
                    border: Border.all(
                      color: AppColors.borderSubtle,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Continue Offline',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl2),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.textTertiary,
                    size: 14,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Error code: NET_001',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                      fontSize: 10,
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
  // SECTION 27 — EMPTY STATE (KEPT from v3.0 — Option B)
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
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
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
              const Text(
                'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 22,
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                  height: 1.8,
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Welcome to QIBRA AI',
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Your Islamic companion is ready. Complete your profile setup to personalize your experience.',
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
                        Icons.auto_awesome_rounded,
                        color: AppColors.white,
                        size: 18,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Get Started',
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  _clearSpecialState();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.buttonRadius,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.30),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    'Explore Features',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl2),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _buildFeatureChip(
                    Icons.menu_book_rounded,
                    'Quran',
                  ),
                  _buildFeatureChip(
                    Icons.access_time_filled_rounded,
                    'Prayer',
                  ),
                  _buildFeatureChip(
                    Icons.explore_rounded,
                    'Qibla',
                  ),
                  _buildFeatureChip(
                    Icons.auto_awesome_rounded,
                    'AI Chat',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── FEATURE CHIP (KEPT from v3.0) ────────────────────────
  Widget _buildFeatureChip(IconData chipIcon, String chipLabel) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.pillRadius,
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(chipIcon, color: AppColors.primary, size: 13),
          const SizedBox(width: AppSpacing.xs),
          Text(
            chipLabel,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION 28 — HELPERS (KEPT from v3.0)
  // ============================================================

  void _showComingSoonSnackbar(String messageText) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.hourglass_empty_rounded,
              color: AppColors.white,
              size: 18,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                messageText,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.buttonRadius,
        ),
      ),
    );
  }
} // ← END of _HomeScreenState

// ============================================================
// END OF FILE — home_screen.dart (Premium v4.0 — Reference Match!)
// ============================================================
