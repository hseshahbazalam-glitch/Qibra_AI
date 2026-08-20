// lib/features/home/presentation/home_screen.dart
// ============================================================
// QIBRA AI — HOME DASHBOARD (v22.0 — Fully Corrected)
// ============================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hijri/hijri_calendar.dart';

import 'package:qibra_ai/core/constants/app_constants.dart';
import 'package:qibra_ai/core/design_system/app_colors.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';
import 'package:qibra_ai/core/providers/auth_provider.dart';

import '../../quran/presentation/quran_search_screen.dart';
import '../../prayer/providers/prayer_provider.dart';
import '../../prayer/data/models/prayer_models.dart';
import 'package:qibra_ai/features/quran/providers/quran_provider.dart'
    hide readingProgressProvider;
import 'package:qibra_ai/features/quran/providers/reading_progress_provider.dart';

import 'widgets/error_empty_states.dart';
import 'widgets/daily_progress_section.dart';
import 'widgets/hadith_card.dart';

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
        PrayerType.fajr => 'الفَجر',
        PrayerType.sunrise => 'الشروق',
        PrayerType.dhuhr => 'الظُهر',
        PrayerType.asr => 'العَصر',
        PrayerType.maghrib => 'المَغرب',
        PrayerType.isha => 'العِشَاء',
      };

  IconData get uiIcon => switch (this) {
        PrayerType.fajr => Icons.wb_twilight_rounded,
        PrayerType.sunrise => Icons.wb_sunny_outlined,
        PrayerType.dhuhr => Icons.wb_sunny_rounded,
        PrayerType.asr => Icons.cloud_rounded,
        PrayerType.maghrib => Icons.nights_stay_rounded,
        PrayerType.isha => Icons.brightness_2_rounded,
      };
}

// ============================================================
// RAMADAN CALCULATOR
// ============================================================

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

class _RamadanCalculator {
  static _RamadanInfo calculate({String? sehri, String? iftar}) {
    final now = DateTime.now();
    final hijriNow = HijriCalendar.fromDate(now);

    // FIX: Added null safety and bounds checking for hMonth
    if (hijriNow.hMonth == 9) {
      final currentDay = hijriNow.hDay;
      return _RamadanInfo(
        isRamadanActive: true,
        daysRemaining: (30 - currentDay).clamp(0, 30),
        currentRamadanDay: currentDay,
        sehriTime: sehri ?? 'Unavailable',
        iftarTime: iftar ?? 'Unavailable',
        hijriRamadanDate: '$currentDay Ramadan ${hijriNow.hYear} AH',
      );
    }

    int targetYear = hijriNow.hYear;
    if (hijriNow.hMonth > 9) targetYear += 1;

    // FIX: Properly construct HijriCalendar and convert to Gregorian
    final nextRamadan = HijriCalendar()
      ..hYear = targetYear
      ..hMonth = 9
      ..hDay = 1;

    final nextRamadanG = nextRamadan.hijriToGregorian(targetYear, 9, 1);
    final daysUntil = nextRamadanG.difference(now).inDays;

    return _RamadanInfo(
      isRamadanActive: false,
      daysRemaining: daysUntil > 0 ? daysUntil : 0,
      currentRamadanDay: 0,
      sehriTime: sehri ?? 'Unavailable',
      iftarTime: iftar ?? 'Unavailable',
      hijriRamadanDate: '1 Ramadan $targetYear AH',
    );
  }
}

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
  late final AnimationController _headerAnimationController;
  late final AnimationController _pulseAnimationController;
  late final Animation<double> _headerFadeAnimation;
  late final Animation<Offset> _headerSlideAnimation;

  bool _hasLoadingError = false;
  bool _isContentEmpty = false;

  // FIX: Made ScrollController nullable and disposed properly
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    _headerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _pulseAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: Curves.easeOut,
      ),
    );

    _headerSlideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _headerAnimationController.forward();

    // FIX: Use addPostFrameCallback safely
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _detectLocation();
    });
  }

  Future<void> _detectLocation() async {
    // FIX: Added mounted check before reading providers
    if (!mounted) return;

    final locationState = ref.read(locationProvider);
    if (locationState.location == null) {
      try {
        await ref
            .read(locationProvider.notifier)
            .fetchCurrentLocation()
            .timeout(const Duration(seconds: 20));
      } catch (_) {
        // LocationNotifier already stores an honest denied/disabled/error state.
        // Never replace an unavailable location with a fabricated default city.
      }
    }
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.mediumImpact();
    if (!mounted) return;

    setState(() => _hasLoadingError = false);

    // FIX: Invalidate providers only when mounted
    ref.invalidate(dailyAyahProvider);
    ref.invalidate(dailyPrayerTimesProvider);
    ref.invalidate(nextPrayerProvider);
    ref.invalidate(readingProgressProvider);

    await Future.delayed(const Duration(milliseconds: 1200));
  }

  void _clearSpecialState() {
    if (!mounted) return;
    setState(() {
      _hasLoadingError = false;
      _isContentEmpty = false;
    });
  }

  // FIX: Extracted greeting logic to avoid repetition
  String _getGreeting() {
    final h = DateTime.now().hour;
    if (h < 5) return 'As-Salaam Alaikum';
    if (h < 12) return 'Good Morning,';
    if (h < 17) return 'Good Afternoon,';
    if (h < 20) return 'Good Evening,';
    return 'Good Night,';
  }

  String _getGreetingSubtitle() {
    final h = DateTime.now().hour;
    if (h < 12) return 'May Allah bless your day';
    if (h < 17) return 'May Allah guide you today';
    if (h < 20) return 'May Allah accept your deeds';
    return 'May Allah give you peaceful night';
  }

  // FIX: Bounds checking added — month index 1..12 is now safe
  String _hijriMonthAbbr(int m) {
    const months = [
      'Muharram',
      'Safar',
      'Rabi I',
      'Rabi II',
      'Jumada I',
      'Jumada II',
      'Rajab',
      'Shaban',
      'Ramadan',
      'Shawwal',
      'Dhul Qadah',
      'Dhul Hijjah',
    ];
    if (m < 1 || m > 12) return '';
    return months[m - 1];
  }

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _pulseAnimationController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ============================================================
  // BUILD
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
                bottom: 110,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildTopBar(),
                  const SizedBox(height: AppSpacing.md),
                  _buildHeroSection(userName),
                  const SizedBox(height: AppSpacing.md),
                  // Primary daily dashboard flow: prayer overview first,
                  // followed by quick actions and Quran progress.
                  const _PrayerTimesCard(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildQuickAccessSection(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildProgressAndStreakRow(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildContinueReadingCard(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildVerseAndHadithRow(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildRamadanQiblaMosqueRow(),
                  const SizedBox(height: AppSpacing.lg),
                  _buildAIAssistantBanner(),
                  const SizedBox(height: AppSpacing.xl),
                  _buildAllFeaturesSection(),
                  const SizedBox(height: AppSpacing.xl3),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TOP BAR
  // ============================================================

  Widget _buildTopBar() {
    final hijriDate = HijriCalendar.fromDate(DateTime.now());
    final now = DateTime.now();

    // FIX: Use safe weekday/month arrays
    const weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const gregMonths = [
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

    final hijriStr =
        '${hijriDate.hDay} ${_hijriMonthAbbr(hijriDate.hMonth)} ${hijriDate.hYear} AH';
    final gregorianStr = '${weekDays[(now.weekday - 1).clamp(0, 6)]}, '
        '${now.day} ${gregMonths[(now.month - 1).clamp(0, 11)]} ${now.year}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          // Menu button
          _iconButton(Icons.menu_rounded),
          const SizedBox(width: 8),

          // Brand
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: const [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'QIBRA',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      height: 1.0,
                    ),
                  ),
                  SizedBox(width: 3),
                  Text(
                    'AI',
                    style: TextStyle(
                      color: Color(0xFF00E676),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Your Islamic Companion',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 8.5,
                      fontWeight: FontWeight.w500,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Text('✨', style: TextStyle(fontSize: 8)),
                ],
              ),
            ],
          ),
          const SizedBox(width: 8),

          // Date pill
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.calendar_month_rounded,
                    color: Color(0xFF00E676),
                    size: 14,
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          hijriStr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            height: 1.1,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 1),
                        Text(
                          gregorianStr,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 8,
                            fontWeight: FontWeight.w500,
                            height: 1.0,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Search button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const QuranSearchScreen()),
              );
            },
            child: _iconButton(Icons.search_rounded),
          ),
          const SizedBox(width: 6),

          // Notification button with badge
          Stack(
            children: [
              _iconButton(Icons.notifications_outlined),
              Positioned(
                right: 9,
                top: 9,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00E676),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.background, width: 1.5),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 6),

          // Avatar
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                ),
                child: ClipOval(
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1A2744), Color(0xFF0A1628)],
                      ),
                    ),
                    child: const Center(
                      child: Text('🕌', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFFD4AF37),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.background, width: 1.5),
                  ),
                  child: const Icon(
                    Icons.workspace_premium_rounded,
                    color: Color(0xFF0A1628),
                    size: 9,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // FIX: Extracted reusable icon button widget to reduce duplication
  Widget _iconButton(IconData icon) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  // ============================================================
  // HERO SECTION
  // ============================================================

  Widget _buildHeroSection(String userName) {
    final loc = ref.watch(locationProvider);
    final greeting = _getGreeting();
    final subtitle = _getGreetingSubtitle();

    // FIX: Resolve display name once
    final displayName =
        (userName.isEmpty || userName == 'QIBRA User') ? 'Guest' : userName;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: FadeTransition(
        opacity: _headerFadeAnimation,
        child: SlideTransition(
          position: _headerSlideAnimation,
          child: Container(
            // Keeps the next-prayer card fully inside the hero on compact phones.
            height: 320,
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
                  // Background image with fallback
                  Image.asset(
                    'assets/images/hero/mosque_night.png',
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
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
                    ),
                  ),

                  // Gradient overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.25),
                          Colors.black.withValues(alpha: 0.75),
                        ],
                      ),
                    ),
                  ),

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      children: [
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: const [
                                    Row(
                                      children: [
                                        Text(
                                          'Assalamu Alaikum',
                                          style: TextStyle(
                                            color: Color(0xFF00E676),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          '👋',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      greeting,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w800,
                                        height: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            displayName,
                                            style: const TextStyle(
                                              color: Color(0xFF00E676),
                                              fontSize: 22,
                                              fontWeight: FontWeight.w800,
                                              height: 1.1,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Text(
                                          '💚',
                                          style: TextStyle(fontSize: 18),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      subtitle,
                                      style: TextStyle(
                                        color: Colors.white.withValues(
                                          alpha: 0.85,
                                        ),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 10),
                              _NextPrayerOverlayCard(
                                pulseController: _pulseAnimationController,
                              ),
                            ],
                          ),
                        ),
                        _buildHeroBottomBar(loc.location?.displayName),
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

  Widget _buildHeroBottomBar(String? locationName) {
    // FIX: Compute Hijri date once to avoid multiple calls
    final hijri = HijriCalendar.fromDate(DateTime.now());
    final hijriStr =
        '${hijri.hDay} ${_hijriMonthAbbr(hijri.hMonth)} ${hijri.hYear} AH';
    final quranProgress =
        ref.watch(readingProgressProvider).overallProgress.clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.40),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.location_on_rounded,
            color: Color(0xFF00E676),
            size: 14,
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  locationName ?? 'Location unavailable',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  locationName == null
                      ? 'Set location for accurate times'
                      : 'Auto-detected',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 8,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _divider(),
          const Icon(
            Icons.menu_book_rounded,
            color: Color(0xFF00E676),
            size: 14,
          ),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${(quranProgress * 100).round()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                'Quran goal',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 8,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          _divider(),
          const Icon(
            Icons.calendar_month_rounded,
            color: Colors.white70,
            size: 13,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              hijriStr,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // FIX: Extracted vertical divider to avoid repetition
  Widget _divider() {
    return Container(
      width: 1,
      height: 22,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: Colors.white.withValues(alpha: 0.15),
    );
  }
// ============================================================
// QUICK ACCESS SECTION (6 icons horizontal)
// ============================================================

  Widget _buildQuickAccessSection() {
    final quickItems = [
      (
        Icons.menu_book_rounded,
        'Quran',
        const Color(0xFF00E676),
        AppRoutes.quran,
      ),
      (
        Icons.import_contacts_rounded,
        'Hadith',
        const Color(0xFFFFD700),
        AppRoutes.hadith,
      ),
      (
        Icons.explore_rounded,
        'Qibla',
        const Color(0xFF8B5CF6),
        AppRoutes.qibla,
      ),
      (
        Icons.radio_button_checked_rounded,
        'Tasbih',
        const Color(0xFF00E676),
        AppRoutes.tasbih,
      ),
      (
        Icons.volunteer_activism_rounded,
        'Duas',
        const Color(0xFF74C0FC),
        AppRoutes.dua,
      ),
      (
        Icons.apps_rounded,
        'More',
        Colors.white.withValues(alpha: 0.7),
        AppRoutes.tools,
      ),
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.cardRadiusLarge,
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Text(
                  'QUICK ACCESS',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.go(AppRoutes.tools);
                  },
                  child: Row(
                    children: [
                      Text(
                        'See all',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: const Color(0xFF00E676),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 3),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Color(0xFF00E676),
                        size: 10,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 6 icons horizontal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(quickItems.length, (i) {
                final item = quickItems[i];
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.go(item.$4);
                    },
                    behavior: HitTestBehavior.opaque,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: item.$3.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: item.$3.withValues(alpha: 0.25),
                              width: 1.2,
                            ),
                          ),
                          child: Icon(item.$1, color: item.$3, size: 22),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.$2,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
  // ============================================================
  // PROGRESS + STREAK ROW
  // ============================================================

  Widget _buildProgressAndStreakRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: SizedBox(
        height: 210,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Expanded(flex: 62, child: HomeDailyProgressSection()),
            const SizedBox(width: 10),
            Expanded(flex: 38, child: _buildPrayerStreakCard()),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerStreakCard() {
    final prayerStatistics = ref.watch(prayerStatisticsProvider);
    final records = ref.watch(prayerRecordsProvider);
    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday % 7));
    const requiredPrayers = {
      PrayerType.fajr,
      PrayerType.dhuhr,
      PrayerType.asr,
      PrayerType.maghrib,
      PrayerType.isha,
    };

    bool isCompletedStatus(PrayerStatus status) =>
        status == PrayerStatus.prayed ||
        status == PrayerStatus.prayedInMosque ||
        status == PrayerStatus.makeup;

    final weekDone = List<bool>.generate(7, (index) {
      final day = DateTime(
        weekStart.year,
        weekStart.month,
        weekStart.day + index,
      );
      final completed = records
          .where((record) =>
              record.date.year == day.year &&
              record.date.month == day.month &&
              record.date.day == day.day &&
              isCompletedStatus(record.status))
          .map((record) => record.type)
          .toSet();
      return completed.containsAll(requiredPrayers);
    });

    final displayStreak = prayerStatistics.currentStreak;

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        context.go(AppRoutes.prayer);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.cardRadiusLarge,
          border: Border.all(
            color: const Color(0xFFF97316).withValues(alpha: 0.30),
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.local_fire_department_rounded,
                  color: Color(0xFFF97316),
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  'PRAYER STREAK',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFF97316)],
              ).createShader(b),
              child: Text(
                '$displayStreak',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 30,
                  height: 1.0,
                ),
              ),
            ),
            Text(
              'days',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final done = weekDone[i];
                return Column(
                  children: [
                    Text(
                      'SMTWTFS'[i],
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 7,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color:
                            done ? const Color(0xFFF97316) : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: done
                              ? const Color(0xFFF97316)
                              : AppColors.borderSubtle,
                        ),
                      ),
                      child: done
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 9,
                            )
                          : null,
                    ),
                  ],
                );
              }),
            ),
            const SizedBox(height: 6),
            Text(
              displayStreak > 0
                  ? "Keep it up! You're building consistency."
                  : 'Complete all five daily prayers to begin your streak.',
              style: TextStyle(
                color: const Color(0xFFF97316).withValues(alpha: 0.9),
                fontSize: 8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // CONTINUE READING CARD
  // ============================================================

  Widget _buildContinueReadingCard() {
    final ps = ref.watch(readingProgressProvider);
    final cp = ps.currentPage;

    final hasReadingProgress = cp != null;
    final surahName = cp?.surahName ?? 'Start your Quran journey';
    final juz = cp?.juzNumber;
    final page = cp?.pageNumber ?? 1;

    // Do not display fabricated reading progress to a new user.
    final progress =
        hasReadingProgress ? ps.overallProgress.clamp(0.0, 1.0) : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          context.push('${AppRoutes.mushafReader}?page=$page');
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF064E3B), Color(0xFF065F46)],
            ),
            borderRadius: AppRadius.cardRadiusLarge,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.30),
              width: 1.2,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CONTINUE READING',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: const Color(0xFF6EE7B7),
                            fontWeight: FontWeight.w700,
                            fontSize: 9,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          surahName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          hasReadingProgress
                              ? 'Juz $juz • Page $page'
                              : 'Open the Quran and choose where to begin',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E676),
                      borderRadius: AppRadius.pillRadius,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          hasReadingProgress ? 'Continue' : 'Start',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: const Color(0xFF04231A),
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Color(0xFF04231A),
                          size: 13,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 5,
                  backgroundColor: Colors.white.withValues(alpha: 0.15),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF00E676)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // VERSE + HADITH ROW
  // ============================================================

  Widget _buildVerseAndHadithRow() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            'DAILY REFLECTIONS',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: const [
                Expanded(child: _DailyVerseCard()),
                SizedBox(width: 10),
                Expanded(child: HomeHadithCard()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // RAMADAN + QIBLA + MOSQUES ROW
  // ============================================================

  Widget _buildRamadanQiblaMosqueRow() {
    // FIX: Calculate once and pass down
    final data = _RamadanCalculator.calculate();

    // These information-dense cards were previously forced into three narrow
    // columns. A horizontal rail preserves readable labels and tap targets on
    // compact phones while still showing the next card as an affordance.
    return SizedBox(
      height: 175,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        children: [
          SizedBox(width: 196, child: _buildRamadanCountdownCard(data)),
          const SizedBox(width: 10),
          SizedBox(width: 156, child: _buildQiblaDirectionCard()),
          const SizedBox(width: 10),
          SizedBox(width: 156, child: _buildNearbyMosquesCard()),
        ],
      ),
    );
  }

  Widget _buildRamadanCountdownCard(_RamadanInfo data) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        context.go(AppRoutes.islamicCalendar);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0A0E27), Color(0xFF1B1B3A), Color(0xFF2D1B4E)],
          ),
          borderRadius: AppRadius.cardRadiusLarge,
          border: Border.all(
            color: const Color(0xFFFFD700).withValues(alpha: 0.30),
            width: 1.2,
          ),
        ),
        child: ClipRRect(
          borderRadius: AppRadius.cardRadiusLarge,
          child: Stack(
            children: [
              const Positioned.fill(
                child: RepaintBoundary(child: _StarsPainterWidget()),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.nightlight_round,
                        color: Color(0xFFFFD700),
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          'RAMADAN COUNTDOWN',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: const Color(0xFFFFD700),
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${data.daysRemaining}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 32,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5),
                        child: Text(
                          'days',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.75),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text(
                    data.isRamadanActive
                        ? 'of Ramadan remaining'
                        : 'until Ramadan Mubarak',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 9,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'رَمَضَان مُبَارَك',
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 16,
                      color: Color(0xFFFFD700),
                      fontWeight: FontWeight.w700,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.20),
                      borderRadius: AppRadius.pillRadius,
                      border: Border.all(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.40),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View Calendar',
                          style: TextStyle(
                            color: const Color(0xFFB794F6),
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: Color(0xFFB794F6),
                          size: 10,
                        ),
                      ],
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

  String _bearingLabel(double bearing) {
    const directions = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    return directions[((bearing % 360 + 22.5) ~/ 45) % 8];
  }

  Widget _buildQiblaDirectionCard() {
    final bearing = ref.watch(qiblaDirectionProvider);
    final bearingLabel = bearing == null
        ? 'Set location'
        : '${bearing.round()}° ${_bearingLabel(bearing)}';

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        context.go(AppRoutes.qibla);
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.cardRadiusLarge,
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  color: Color(0xFF00E676),
                  size: 13,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'QIBLA DIRECTION',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 7.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: Center(
                child: SizedBox(
                  width: 62,
                  height: 62,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Icon(
                        bearing == null
                            ? Icons.location_off_rounded
                            : Icons.explore_rounded,
                        color: bearing == null
                            ? AppColors.textTertiary
                            : const Color(0xFF00E676),
                        size: 30,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Center(
              child: Text(
                bearingLabel,
                style: TextStyle(
                  color: bearing == null
                      ? AppColors.textTertiary
                      : const Color(0xFF00E676),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNearbyMosquesCard() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        context.go(AppRoutes.mosques);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppRadius.cardRadiusLarge,
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: ClipRRect(
          borderRadius: AppRadius.cardRadiusLarge,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/hero/mosque_night.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: const Color(0xFF0A2540)),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.35),
                      Colors.black.withValues(alpha: 0.80),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.mosque_rounded,
                          color: Colors.white,
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'MOSQUE FINDER',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Colors.white,
                              fontSize: 7.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Text(
                      'Find mosques\nnear you',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E676),
                        borderRadius: AppRadius.pillRadius,
                      ),
                      child: const Text(
                        'View',
                        style: TextStyle(
                          color: Color(0xFF04231A),
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
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
  // AI ASSISTANT BANNER
  // ============================================================

  Widget _buildAIAssistantBanner() {
    const aiAvailable = AppApi.isBackendEnabled;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          context.go(AppRoutes.aiChat);
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF064E3B), Color(0xFF065F46)],
            ),
            borderRadius: AppRadius.cardRadiusLarge,
            border: Border.all(
              color: const Color(0xFF00E676).withValues(alpha: 0.30),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withValues(alpha: 0.20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.smart_toy_rounded,
                  color: Color(0xFF00E676),
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          aiAvailable
                              ? 'AI ISLAMIC ASSISTANT'
                              : 'AI ASSISTANT — PREVIEW',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Text('✨', style: TextStyle(fontSize: 10)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      aiAvailable
                          ? 'Ask about Islam, Quran, and Hadith with verified-source guidance.'
                          : 'AI chat is being prepared. Quran, Prayer, Duas, and Hadith remain available offline.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.70),
                        fontSize: 10,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676),
                  borderRadius: AppRadius.pillRadius,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      aiAvailable ? 'Ask now' : 'View status',
                      style: TextStyle(
                        color: Color(0xFF04231A),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(width: 3),
                    Text('✨', style: TextStyle(fontSize: 9)),
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
  // ALL FEATURES SECTION
  // ============================================================

  Widget _buildAllFeaturesSection() {
    // FIX: Use a typed record list for clarity and type safety
    final List<(IconData, String, String, Color, String)> features = [
      (
        Icons.access_time_rounded,
        'Prayer Times',
        'Accurate timings with countdown',
        const Color(0xFFF59E0B),
        AppRoutes.prayer,
      ),
      (
        Icons.menu_book_rounded,
        'Quran',
        'Read & understand the Holy Quran',
        const Color(0xFF00E676),
        AppRoutes.quran,
      ),
      (
        Icons.import_contacts_rounded,
        'Hadith',
        'Authentic hadith collections',
        const Color(0xFFEF4444),
        AppRoutes.hadith,
      ),
      (
        Icons.favorite_rounded,
        'Islamic Tools',
        'Zakat, Hajj, Ramadan & more',
        const Color(0xFF8B5CF6),
        AppRoutes.islamicCalendar,
      ),
      (
        Icons.translate_rounded,
        'Translations',
        '50+ languages available',
        const Color(0xFF0EA5E9),
        AppRoutes.quran,
      ),
      (
        Icons.bookmark_rounded,
        'Bookmarks',
        'Save your favorite verses',
        const Color(0xFF8B5CF6),
        AppRoutes.quran,
      ),
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
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
              const Icon(Icons.apps_rounded, color: AppColors.accent, size: 16),
              const SizedBox(width: 6),
              Text(
                'ALL FEATURES',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.accent,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                'View All',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: features.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.85,
            ),
            itemBuilder: (context, i) {
              final f = features[i];
              return GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.go(f.$5);
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.cardRadius,
                    border: Border.all(color: f.$4.withValues(alpha: 0.25)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: f.$4.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(f.$1, color: f.$4, size: 17),
                      ),
                      const Spacer(),
                      Text(
                        f.$2,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        f.$3,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textTertiary,
                          fontSize: 8.5,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ============================================================
// NEXT PRAYER OVERLAY CARD
// ============================================================

class _NextPrayerOverlayCard extends ConsumerWidget {
  final AnimationController pulseController;
  const _NextPrayerOverlayCard({required this.pulseController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nextPrayerInfo = ref.watch(nextPrayerProvider);
    final displayType = nextPrayerInfo?.prayer.type ?? PrayerType.fajr;
    final displayTime = nextPrayerInfo?.prayer.formattedTime ?? '04:55 AM';
    final displayCountdown = nextPrayerInfo?.countdown ??
        const Duration(hours: 1, minutes: 34, seconds: 56);

    // FIX: Use abs() defensively, ensure no negative display
    final totalSeconds = displayCountdown.inSeconds.abs();
    final h = (totalSeconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final sec = (totalSeconds % 60).toString().padLeft(2, '0');

    const totalMax = 6 * 3600;
    final progress = 1.0 - (totalSeconds / totalMax).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        context.go(AppRoutes.prayer);
      },
      child: Container(
        width: 132,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF06101F).withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFF00E676).withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'NEXT PRAYER',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.65),
                fontSize: 8,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              displayType.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              displayType.arabicName,
              style: const TextStyle(
                fontFamily: 'Amiri',
                fontSize: 11,
                color: Color(0xFF00E676),
                fontWeight: FontWeight.w600,
              ),
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 82,
              height: 82,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  RepaintBoundary(
                    child: CustomPaint(
                      size: const Size(82, 82),
                      painter: _CircularProgressPainter(
                        progress: progress,
                        color: const Color(0xFF00E676),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$h:$m:$sec',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'monospace',
                        ),
                      ),
                      Text(
                        'Remaining',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 7,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              displayTime,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            AnimatedBuilder(
              animation: pulseController,
              builder: (_, __) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  borderRadius: AppRadius.pillRadius,
                  border: Border.all(
                    color: const Color(0xFF00E676).withValues(
                      alpha: (0.4 + 0.3 * pulseController.value).clamp(
                        0.0,
                        1.0,
                      ),
                    ),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00E676),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Text(
                      'LIVE',
                      style: TextStyle(
                        color: Color(0xFF00E676),
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Text(
                      '((•))',
                      style: TextStyle(
                        color: Color(0xFF00E676),
                        fontSize: 6,
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
    );
  }
}

// ============================================================
// PRAYER TIMES CARD
// ============================================================

class _PrayerTimesCard extends ConsumerWidget {
  const _PrayerTimesCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dailyTimes = ref.watch(dailyPrayerTimesProvider);
    final nextPrayerInfo = ref.watch(nextPrayerProvider);
    final nextType = nextPrayerInfo?.prayer.type;

    final prayers = dailyTimes != null
        ? [
            dailyTimes.fajr,
            dailyTimes.dhuhr,
            dailyTimes.asr,
            dailyTimes.maghrib,
            dailyTimes.isha,
          ]
        : null;

    // FIX: Extracted default prayers as a constant
    const defaultPrayers = [
      (PrayerType.fajr, '04:55 AM'),
      (PrayerType.dhuhr, '12:30 PM'),
      (PrayerType.asr, '03:46 PM'),
      (PrayerType.maghrib, '06:49 PM'),
      (PrayerType.isha, '08:00 PM'),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadiusLarge,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.access_time_rounded,
                  color: Color(0xFF00E676),
                  size: 13,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "TODAY'S PRAYER TIMES",
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.go(AppRoutes.prayer);
                },
                child: Row(
                  children: [
                    Text(
                      'View All',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: const Color(0xFF00E676),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Color(0xFF00E676),
                      size: 11,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Prayer mini cards — IntrinsicHeight ensures uniform height
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: List.generate(5, (i) {
                final type =
                    prayers != null ? prayers[i].type : defaultPrayers[i].$1;
                final time = prayers != null
                    ? prayers[i].formattedTime
                    : defaultPrayers[i].$2;

                // FIX: Clearer next-prayer logic
                final isNext = nextType != null ? nextType == type : i == 0;

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i == 4 ? 0 : 6),
                    child: _PrayerMiniCard(
                      type: type,
                      time: time,
                      isNext: isNext,
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 10),

          // Progress timeline dots
          Row(
            children: List.generate(5, (i) {
              // FIX: Determine which dot should be active based on nextType
              final isActive = nextType != null
                  ? (prayers != null ? prayers[i].type == nextType : i == 0)
                  : i == 0;

              return Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: isActive
                            ? const Color(0xFF00E676)
                            : Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                    ),
                    if (i < 4)
                      Expanded(
                        child: Container(
                          height: 2,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PRAYER MINI CARD
// ============================================================

class _PrayerMiniCard extends StatelessWidget {
  final PrayerType type;
  final String time;
  final bool isNext;

  const _PrayerMiniCard({
    required this.type,
    required this.time,
    required this.isNext,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        context.go(AppRoutes.prayer);
      },
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
        decoration: BoxDecoration(
          gradient: isNext
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF00E676), Color(0xFF00A86B)],
                )
              : null,
          color: isNext ? null : const Color(0xFF0D1826),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isNext
                ? Colors.transparent
                : Colors.white.withValues(alpha: 0.05),
            width: 1,
          ),
          boxShadow: isNext
              ? [
                  BoxShadow(
                    color: const Color(0xFF00E676).withValues(alpha: 0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              type.uiIcon,
              color:
                  isNext ? Colors.white : Colors.white.withValues(alpha: 0.75),
              size: 18,
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                type.displayName,
                style: TextStyle(
                  color: isNext
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.95),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.0,
                ),
              ),
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                time,
                style: TextStyle(
                  color: isNext
                      ? Colors.white.withValues(alpha: 0.95)
                      : Colors.white.withValues(alpha: 0.60),
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                ),
              ),
            ),
            if (isNext) ...[
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'Upcoming',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 7,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================
// DAILY VERSE CARD
// ============================================================

class _DailyVerseCard extends ConsumerWidget {
  const _DailyVerseCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ayahAsync = ref.watch(dailyAyahProvider);

    return ayahAsync.when(
      data: (ayah) => ayah == null
          ? _verseStatusCard('No verified verse is available right now.')
          : _verseCard(
              ayah.text,
              ayah.translation ?? 'Translation unavailable',
              'Quran • Ayah ${ayah.numberInQuran}',
            ),
      loading: () => _verseStatusCard('Loading verified daily verse…'),
      error: (_, __) =>
          _verseStatusCard('Unable to load a verified daily verse.'),
    );
  }

  Widget _verseStatusCard(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadiusLarge,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Center(
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _verseCard(String arabic, String translation, String reference) {
    const accent = Color(0xFF00E676);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadiusLarge,
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.format_quote_rounded, color: accent, size: 14),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  'DAILY VERSE',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: accent,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            arabic,
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontSize: 15,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
            textDirection: TextDirection.rtl,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            translation,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 10,
              height: 1.3,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  reference,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 9,
                  ),
                ),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: accent,
                  size: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// STARS PAINTER WIDGET
// ============================================================

class _StarsPainterWidget extends StatelessWidget {
  const _StarsPainterWidget();

  @override
  Widget build(BuildContext context) {
    return const CustomPaint(painter: _StarsPainter());
  }
}

class _StarsPainter extends CustomPainter {
  const _StarsPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.3);

    // FIX: Stars defined as offsets relative to canvas size
    final stars = [
      Offset(size.width * 0.10, size.height * 0.15),
      Offset(size.width * 0.25, size.height * 0.35),
      Offset(size.width * 0.40, size.height * 0.10),
      Offset(size.width * 0.55, size.height * 0.30),
      Offset(size.width * 0.70, size.height * 0.20),
      Offset(size.width * 0.85, size.height * 0.40),
      Offset(size.width * 0.15, size.height * 0.55),
      Offset(size.width * 0.35, size.height * 0.75),
      Offset(size.width * 0.50, size.height * 0.60),
      Offset(size.width * 0.75, size.height * 0.85),
      Offset(size.width * 0.90, size.height * 0.65),
      Offset(size.width * 0.05, size.height * 0.85),
    ];

    for (int i = 0; i < stars.length; i++) {
      final radius = (i % 3 == 0) ? 1.5 : 1.0;
      paint.color = Colors.white.withValues(alpha: (i % 3 == 0) ? 0.5 : 0.25);
      canvas.drawCircle(stars[i], radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================
// CIRCULAR PROGRESS PAINTER
// ============================================================

class _CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color color;

  const _CircularProgressPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - 8) / 2;

    // Background track
    final bgPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.10)
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, bgPaint);

    // FIX: Added clamp to prevent invalid arc angles
    final clampedProgress = progress.clamp(0.0, 1.0);
    if (clampedProgress == 0.0) return;

    final progressPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: [
          color.withValues(alpha: 0.5),
          color,
          color.withValues(alpha: 0.9),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * clampedProgress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(_CircularProgressPainter old) =>
      old.progress != progress || old.color != color;
}
