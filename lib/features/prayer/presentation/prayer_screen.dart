// lib/features/prayer/presentation/prayer_screen.dart
// ============================================================
// QIBRA AI — PRAYER TIMES SCREEN (PREMIUM v1.1)
// Phase: 7
// Bug Fix v1.1:
//   - Timer.periodic 1s → 30s (scroll-stuck fix)
//   - _sunPulseAnimation unused field removed
//   - _clockUpdateTimer unused field removed
// ============================================================

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qibra_ai/core/constants/app_constants.dart';
import 'package:qibra_ai/core/design_system/app_colors.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';
import 'package:qibra_ai/shared/widgets/cards/app_card.dart';

// ============================================================
// SECTION 1 — DATA MODELS
// ============================================================

/// Prayer time model — ek prayer ka complete data
class _PrayerTimeItem {
  final String prayerName;
  final String prayerNameArabic;
  final String prayerTime;
  final DateTime prayerDateTime;
  final IconData prayerIcon;
  final bool isAdhanEnabled;
  final bool isReminderEnabled;

  const _PrayerTimeItem({
    required this.prayerName,
    required this.prayerNameArabic,
    required this.prayerTime,
    required this.prayerDateTime,
    required this.prayerIcon,
    this.isAdhanEnabled = true,
    this.isReminderEnabled = false,
  });

  _PrayerTimeItem copyWith({
    bool? isAdhanEnabled,
    bool? isReminderEnabled,
  }) {
    return _PrayerTimeItem(
      prayerName: prayerName,
      prayerNameArabic: prayerNameArabic,
      prayerTime: prayerTime,
      prayerDateTime: prayerDateTime,
      prayerIcon: prayerIcon,
      isAdhanEnabled: isAdhanEnabled ?? this.isAdhanEnabled,
      isReminderEnabled: isReminderEnabled ?? this.isReminderEnabled,
    );
  }
}

/// Calculation method model
class _CalculationMethod {
  final String methodShortCode;
  final String methodFullName;
  final String methodDescription;

  const _CalculationMethod({
    required this.methodShortCode,
    required this.methodFullName,
    required this.methodDescription,
  });
}

/// Asr calculation method model
class _AsrMethod {
  final String asrShortName;
  final String asrFullName;
  final String asrDescription;

  const _AsrMethod({
    required this.asrShortName,
    required this.asrFullName,
    required this.asrDescription,
  });
}

// ============================================================
// SECTION 2 — STATIC DATA
// ============================================================

const List<_CalculationMethod> _allCalculationMethods = [
  _CalculationMethod(
    methodShortCode: 'MWL',
    methodFullName: 'Muslim World League',
    methodDescription: 'Standard for Europe, Far East, USA',
  ),
  _CalculationMethod(
    methodShortCode: 'ISNA',
    methodFullName: 'Islamic Society of North America',
    methodDescription: 'North America standard',
  ),
  _CalculationMethod(
    methodShortCode: 'EGYPT',
    methodFullName: 'Egyptian General Authority',
    methodDescription: 'Africa, Syria, Iraq, Lebanon, Malaysia',
  ),
  _CalculationMethod(
    methodShortCode: 'MAKKAH',
    methodFullName: 'Umm Al-Qura, Makkah',
    methodDescription: 'Arabian Peninsula',
  ),
  _CalculationMethod(
    methodShortCode: 'KARACHI',
    methodFullName: 'University of Islamic Sciences',
    methodDescription: 'Pakistan, Bangladesh, India, Afghanistan',
  ),
  _CalculationMethod(
    methodShortCode: 'TEHRAN',
    methodFullName: 'Institute of Geophysics, Tehran',
    methodDescription: 'Iran, Some Shia communities',
  ),
];

const List<_AsrMethod> _allAsrMethods = [
  _AsrMethod(
    asrShortName: 'Standard',
    asrFullName: 'Standard (Shafi\'i, Maliki, Hanbali)',
    asrDescription: 'Shadow length = object length',
  ),
  _AsrMethod(
    asrShortName: 'Hanafi',
    asrFullName: 'Hanafi',
    asrDescription: 'Shadow length = 2× object length',
  ),
];

// ============================================================
// SECTION 3 — SUN ARC CUSTOM PAINTER
// ============================================================

class _SunArcPainter extends CustomPainter {
  final double dayProgressFraction;
  final Color arcBackgroundColor;
  final Color arcActiveColor;
  final Color sunGlowColor;

  _SunArcPainter({
    required this.dayProgressFraction,
    required this.arcBackgroundColor,
    required this.arcActiveColor,
    required this.sunGlowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double centerY = size.height;
    final double arcRadius = size.width / 2 - 20;

    final Rect arcRect = Rect.fromCircle(
      center: Offset(centerX, centerY),
      radius: arcRadius,
    );

    // ── BACKGROUND ARC ───────────────────────────────────
    final Paint backgroundArcPaint = Paint()
      ..color = arcBackgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(arcRect, math.pi, math.pi, false, backgroundArcPaint);

    // ── ACTIVE ARC (progress) ────────────────────────────
    final Paint activeArcPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          arcActiveColor.withValues(alpha: 0.60),
          arcActiveColor,
          sunGlowColor,
        ],
      ).createShader(arcRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      arcRect,
      math.pi,
      math.pi * dayProgressFraction,
      false,
      activeArcPaint,
    );

    // ── PRAYER TICK MARKS (5 positions) ─────────────────
    final Paint tickPaint = Paint()
      ..color = arcBackgroundColor.withValues(alpha: 0.50)
      ..style = PaintingStyle.fill;

    const List<double> prayerPositions = [0.05, 0.35, 0.55, 0.78, 0.95];

    for (final double pos in prayerPositions) {
      final double angle = math.pi + (math.pi * pos);
      final double dotX = centerX + arcRadius * math.cos(angle);
      final double dotY = centerY + arcRadius * math.sin(angle);
      canvas.drawCircle(Offset(dotX, dotY), 3, tickPaint);
    }

    // ── SUN POSITION (moving glow dot) ──────────────────
    final double sunAngle = math.pi + (math.pi * dayProgressFraction);
    final double sunX = centerX + arcRadius * math.cos(sunAngle);
    final double sunY = centerY + arcRadius * math.sin(sunAngle);

    // Outer glow
    final Paint sunGlowPaint = Paint()
      ..color = sunGlowColor.withValues(alpha: 0.30)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 15);
    canvas.drawCircle(Offset(sunX, sunY), 18, sunGlowPaint);

    // Middle glow
    final Paint sunMidPaint = Paint()
      ..color = sunGlowColor.withValues(alpha: 0.60)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(sunX, sunY), 12, sunMidPaint);

    // Sun core
    final Paint sunCorePaint = Paint()
      ..shader = RadialGradient(
        colors: [Colors.white, sunGlowColor],
      ).createShader(
        Rect.fromCircle(center: Offset(sunX, sunY), radius: 8),
      );
    canvas.drawCircle(Offset(sunX, sunY), 8, sunCorePaint);
  }

  @override
  bool shouldRepaint(covariant _SunArcPainter oldDelegate) {
    return oldDelegate.dayProgressFraction != dayProgressFraction ||
        oldDelegate.arcActiveColor != arcActiveColor;
  }
}

// ============================================================
// SECTION 4 — PRAYER SCREEN WIDGET
// ============================================================

class PrayerScreen extends ConsumerStatefulWidget {
  const PrayerScreen({super.key});

  @override
  ConsumerState<PrayerScreen> createState() => _PrayerScreenState();
}

// ============================================================
// SECTION 5 — STATE CLASS
// ============================================================

class _PrayerScreenState extends ConsumerState<PrayerScreen>
    with TickerProviderStateMixin {
  // ── ANIMATION CONTROLLERS ───────────────────────────────
  late final AnimationController _headerFadeController;
  late final AnimationController _arcAnimationController;
  late final AnimationController _sunPulseController;
  late final AnimationController _cardsStaggerController;

  // ── ANIMATIONS ──────────────────────────────────────────
  // NOTE v1.1: _sunPulseAnimation removed — was unused
  // _sunPulseController still used by AnimatedBuilder in canvas
  late final Animation<double> _headerFadeAnimation;
  late final Animation<double> _arcProgressAnimation;

  // ── TIMERS ──────────────────────────────────────────────
  // NOTE v1.1: _clockUpdateTimer removed — was unused
  Timer? _liveCountdownTimer;

  // ── STATE VARIABLES ─────────────────────────────────────
  bool _is24HourFormat = false;
  int _selectedCalculationIndex = 4; // Karachi default
  int _selectedAsrMethodIndex = 1; // Hanafi default
  String _currentLocationName = 'Karachi, Pakistan';
  DateTime _currentTime = DateTime.now();

  // ── PRAYERS LIST (mutable for toggles) ──────────────────
  late List<_PrayerTimeItem> _todaysPrayers;

  // ── NEXT PRAYER INDEX ────────────────────────────────────
  final int _nextPrayerIndex = 2; // Asr = dummy

  // ── SCROLL CONTROLLER ───────────────────────────────────
  final ScrollController _mainScrollController = ScrollController();

  // ── COMPUTED PROPERTIES ──────────────────────────────────
  _PrayerTimeItem get _nextPrayer => _todaysPrayers[_nextPrayerIndex];

  Duration get _timeToNextPrayer {
    final Duration diff = _nextPrayer.prayerDateTime.difference(_currentTime);
    return diff.isNegative ? Duration.zero : diff;
  }

  double get _dayProgressFraction {
    final DateTime now = _currentTime;
    final DateTime startOfDay = DateTime(now.year, now.month, now.day, 5, 0);
    final DateTime endOfDay = DateTime(now.year, now.month, now.day, 20, 30);
    final double totalMinutes =
        endOfDay.difference(startOfDay).inMinutes.toDouble();
    final double elapsedMinutes =
        now.difference(startOfDay).inMinutes.toDouble();
    return (elapsedMinutes / totalMinutes).clamp(0.0, 1.0);
  }

  // ============================================================
  // INIT STATE
  // ============================================================

  @override
  void initState() {
    super.initState();
    _initializePrayerData();
    _initializeAnimationControllers();
    _startAnimationsSequence();
    _startLiveTimers();
  }

  // ── INITIALIZE PRAYER DATA ───────────────────────────────
  void _initializePrayerData() {
    final DateTime today = DateTime.now();
    final DateTime base = DateTime(today.year, today.month, today.day);

    _todaysPrayers = [
      _PrayerTimeItem(
        prayerName: 'Fajr',
        prayerNameArabic: 'الْفَجْر',
        prayerTime: '5:12 AM',
        prayerDateTime: base.add(const Duration(hours: 5, minutes: 12)),
        prayerIcon: Icons.wb_twilight_outlined,
        isAdhanEnabled: true,
        isReminderEnabled: true,
      ),
      _PrayerTimeItem(
        prayerName: 'Dhuhr',
        prayerNameArabic: 'الظُّهْر',
        prayerTime: '12:30 PM',
        prayerDateTime: base.add(const Duration(hours: 12, minutes: 30)),
        prayerIcon: Icons.wb_sunny_rounded,
        isAdhanEnabled: true,
        isReminderEnabled: false,
      ),
      _PrayerTimeItem(
        prayerName: 'Asr',
        prayerNameArabic: 'الْعَصْر',
        prayerTime: '3:45 PM',
        prayerDateTime: base.add(const Duration(hours: 15, minutes: 45)),
        prayerIcon: Icons.wb_cloudy_outlined,
        isAdhanEnabled: true,
        isReminderEnabled: true,
      ),
      _PrayerTimeItem(
        prayerName: 'Maghrib',
        prayerNameArabic: 'الْمَغْرِب',
        prayerTime: '6:52 PM',
        prayerDateTime: base.add(const Duration(hours: 18, minutes: 52)),
        prayerIcon: Icons.nights_stay_outlined,
        isAdhanEnabled: true,
        isReminderEnabled: false,
      ),
      _PrayerTimeItem(
        prayerName: 'Isha',
        prayerNameArabic: 'الْعِشَاء',
        prayerTime: '8:15 PM',
        prayerDateTime: base.add(const Duration(hours: 20, minutes: 15)),
        prayerIcon: Icons.brightness_2_outlined,
        isAdhanEnabled: true,
        isReminderEnabled: false,
      ),
    ];
  }

  // ── INITIALIZE ANIMATION CONTROLLERS ─────────────────────
  void _initializeAnimationControllers() {
    // Header fade — 700ms
    _headerFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // Sun arc drawing — 1500ms
    _arcAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    // Sun pulse — 2.5s repeating
    // NOTE v1.1: Controller kept for AnimatedBuilder in canvas
    // Animation object (_sunPulseAnimation) removed — was unused
    _sunPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    // Cards stagger — 1200ms
    _cardsStaggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Header fade animation
    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerFadeController,
        curve: Curves.easeOut,
      ),
    );

    // Arc progress animation
    _arcProgressAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _arcAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    // NOTE v1.1: _sunPulseAnimation Tween removed
    // Was: Tween<double>(begin: 1.0, end: 1.15).animate(...)
    // Reason: Declared but never used in build methods
    // _sunPulseController still drives AnimatedBuilder in _buildSunArcCanvas
  }

  // ── START ANIMATIONS IN SEQUENCE ────────────────────────
  void _startAnimationsSequence() {
    _headerFadeController.forward();

    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) _arcAnimationController.forward();
    });

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _cardsStaggerController.forward();
    });
  }

  // ============================================================
  // SECTION 6 — LIVE TIMERS (BUG FIXED v1.1)
  // ============================================================

  void _startLiveTimers() {
    // ── BUG FIX v1.1 ────────────────────────────────────────
    // PEHLE (BUG):
    //   Timer.periodic(const Duration(seconds: 1), (_) {
    //     setState(() { _currentTime = DateTime.now(); });
    //   });
    //   → Har second full widget rebuild → Chrome scroll stuck!
    //
    // AB (FIXED):
    //   Timer.periodic(const Duration(seconds: 30), ...)
    //   → Har 30s update → 97% rebuilds kam → smooth scroll
    //
    // Trade-off: Countdown 30s jump karta hai (acceptable)
    // Real production fix: Use ValueNotifier + RepaintBoundary
    _liveCountdownTimer = Timer.periodic(
      const Duration(seconds: 30), // ✅ FIXED: was seconds: 1
      (_) {
        if (!mounted) return;
        setState(() {
          _currentTime = DateTime.now();
        });
      },
    );
  }

  // ── FORMAT COUNTDOWN HH:MM:SS ─────────────────────────────
  String get _formattedCountdown {
    final int total = _timeToNextPrayer.inSeconds;
    final int h = total ~/ 3600;
    final int m = (total % 3600) ~/ 60;
    final int s = total % 60;
    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }

  // ── CONVERT 12H → 24H ────────────────────────────────────
  String _convertTo24Hour(String time12h) {
    try {
      final List<String> parts = time12h.split(' ');
      final String timePart = parts[0];
      final String period = parts[1];
      final List<String> hm = timePart.split(':');
      int hours = int.parse(hm[0]);
      final int minutes = int.parse(hm[1]);
      if (period == 'PM' && hours != 12) hours += 12;
      if (period == 'AM' && hours == 12) hours = 0;
      return '${hours.toString().padLeft(2, '0')}:'
          '${minutes.toString().padLeft(2, '0')}';
    } catch (_) {
      return time12h;
    }
  }

  // ── GET DISPLAY TIME (format-aware) ─────────────────────
  String _getDisplayableTime(String time12h) {
    return _is24HourFormat ? _convertTo24Hour(time12h) : time12h;
  }

  // ── TOGGLE ADHAN ─────────────────────────────────────────
  void _togglePrayerAdhan(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _todaysPrayers[index] = _todaysPrayers[index].copyWith(
        isAdhanEnabled: !_todaysPrayers[index].isAdhanEnabled,
      );
    });
  }

  // ── TOGGLE REMINDER ──────────────────────────────────────
  void _togglePrayerReminder(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _todaysPrayers[index] = _todaysPrayers[index].copyWith(
        isReminderEnabled: !_todaysPrayers[index].isReminderEnabled,
      );
    });
  }

  // ── SELECT CALCULATION METHOD ────────────────────────────
  void _selectCalculationMethod(int index) {
    HapticFeedback.lightImpact();
    setState(() => _selectedCalculationIndex = index);
    Navigator.pop(context);
  }

  // ── SELECT ASR METHOD ────────────────────────────────────
  void _selectAsrMethod(int index) {
    HapticFeedback.lightImpact();
    setState(() => _selectedAsrMethodIndex = index);
  }

  // ── TOGGLE TIME FORMAT ───────────────────────────────────
  void _toggleTimeFormat() {
    HapticFeedback.lightImpact();
    setState(() => _is24HourFormat = !_is24HourFormat);
  }

  // ── REFRESH LOCATION ─────────────────────────────────────
  Future<void> _refreshLocation() async {
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _currentLocationName = 'Karachi, Pakistan');
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Location updated'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _liveCountdownTimer?.cancel();
    // NOTE: _clockUpdateTimer removed — was never initialized
    _headerFadeController.dispose();
    _arcAnimationController.dispose();
    _sunPulseController.dispose();
    _cardsStaggerController.dispose();
    _mainScrollController.dispose();
    super.dispose();
  }

  // ============================================================
  // SECTION 7 — BUILD METHOD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        controller: _mainScrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildPremiumAppBar(),
          SliverPadding(
            padding: const EdgeInsets.only(bottom: AppSpacing.xl6),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // 1. Location header
                const SizedBox(height: AppSpacing.lg),
                _buildLocationHeaderCard(),

                // 2. Sun arc + next prayer
                const SizedBox(height: AppSpacing.xl2),
                _buildSunArcSection(),

                // 3. Today's prayers header
                const SizedBox(height: AppSpacing.xl3),
                _buildSectionHeader(
                  headerTitle: 'TODAY\'S PRAYERS',
                  headerIcon: Icons.mosque_rounded,
                  trailingAction: _buildTimeFormatToggle(),
                ),

                // 4. All 5 prayers
                const SizedBox(height: AppSpacing.md),
                _buildAllPrayersList(),

                // 5. Calculation method
                const SizedBox(height: AppSpacing.xl3),
                _buildSectionHeader(
                  headerTitle: 'CALCULATION METHOD',
                  headerIcon: Icons.calculate_rounded,
                ),
                const SizedBox(height: AppSpacing.md),
                _buildCalculationMethodCard(),

                // 6. Asr method
                const SizedBox(height: AppSpacing.md),
                _buildAsrMethodCard(),

                // 7. More options
                const SizedBox(height: AppSpacing.xl3),
                _buildSectionHeader(
                  headerTitle: 'MORE',
                  headerIcon: Icons.tune_rounded,
                ),
                const SizedBox(height: AppSpacing.md),
                _buildMoreOptionsCard(),

                const SizedBox(height: AppSpacing.xl6),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION 8 — PREMIUM APP BAR
  // ============================================================

  Widget _buildPremiumAppBar() {
    return SliverAppBar(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      pinned: false,
      floating: true,
      snap: true,
      leadingWidth: 56,
      leading: Padding(
        padding: const EdgeInsets.only(left: AppSpacing.lg),
        child: FadeTransition(
          opacity: _headerFadeAnimation,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              context.pop();
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.borderSubtle,
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.iconSecondary,
                size: 16,
              ),
            ),
          ),
        ),
      ),
      title: FadeTransition(
        opacity: _headerFadeAnimation,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Prayer Times',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'أَوْقَاتُ الصَّلَاة',
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 11,
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
                height: 1.0,
              ),
              textDirection: TextDirection.rtl,
            ),
          ],
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
              border: Border.all(
                color: AppColors.borderSubtle,
                width: 1,
              ),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.explore_rounded,
                color: AppColors.accent,
                size: 20,
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                context.go(AppRoutes.qibla);
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: 38,
                minHeight: 38,
              ),
              tooltip: 'Qibla direction',
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
      ],
    );
  }

  // ============================================================
  // SECTION 9 — LOCATION HEADER CARD
  // ============================================================

  Widget _buildLocationHeaderCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: FadeTransition(
        opacity: _headerFadeAnimation,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.cardRadius,
            border: Border.all(color: AppColors.borderSubtle, width: 1),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppGradients.emerald,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.30),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: AppColors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CURRENT LOCATION',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w600,
                        fontSize: 9,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _currentLocationName,
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              GestureDetector(
                onTap: _refreshLocation,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.30),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.gps_fixed_rounded,
                    color: AppColors.primary,
                    size: 16,
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
  // SECTION 10 — SUN ARC SECTION
  // ============================================================

  Widget _buildSunArcSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF00A86B),
              Color(0xFF006B44),
              Color(0xFF003D26),
            ],
            stops: [0.0, 0.6, 1.0],
          ),
          borderRadius: AppRadius.cardRadiusLarge,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: 24,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: AppRadius.cardRadiusLarge,
          child: Stack(
            children: [
              // Decorative blobs
              Positioned(
                right: -40,
                top: -40,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFD700).withValues(alpha: 0.08),
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
              Column(
                children: [
                  _buildSunArcHeader(),
                  const SizedBox(height: AppSpacing.md),
                  _buildSunArcPrayerName(),
                  const SizedBox(height: AppSpacing.md),
                  _buildSunArcCountdownChip(),
                  const SizedBox(height: AppSpacing.xl2),
                  _buildSunArcCanvas(),
                  const SizedBox(height: AppSpacing.md),
                  _buildSunriseSunsetRow(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSunArcHeader() {
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
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.15),
            borderRadius: AppRadius.pillRadius,
            border: Border.all(
              color: AppColors.white.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Text(
            'Today',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSunArcPrayerName() {
    return Column(
      children: [
        Text(
          _nextPrayer.prayerName,
          style: AppTextStyles.displayMedium.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w900,
            height: 1.0,
            letterSpacing: -1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _nextPrayer.prayerNameArabic,
          style: const TextStyle(
            fontFamily: 'Amiri',
            fontSize: 22,
            color: AppColors.white,
            fontWeight: FontWeight.w600,
            height: 1.0,
          ),
          textDirection: TextDirection.rtl,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'at ${_getDisplayableTime(_nextPrayer.prayerTime)}',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.white.withValues(alpha: 0.75),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildSunArcCountdownChip() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.white.withValues(alpha: 0.15),
        borderRadius: AppRadius.pillRadius,
        border: Border.all(
          color: AppColors.white.withValues(alpha: 0.30),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, color: AppColors.white, size: 16),
          const SizedBox(width: AppSpacing.sm),
          Text(
            'in $_formattedCountdown',
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.white,
              fontWeight: FontWeight.w800,
              fontFamily: 'monospace',
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSunArcCanvas() {
    return AnimatedBuilder(
      // ── NOTE v1.1 ─────────────────────────────────────────
      // _sunPulseAnimation (Tween object) removed — was unused
      // But _sunPulseController still used here via Listenable.merge
      // This gives the subtle canvas repaint for smooth sun glow
      animation: Listenable.merge([
        _arcAnimationController,
        _sunPulseController,
      ]),
      builder: (context, _) {
        final double animatedProgress =
            _dayProgressFraction * _arcProgressAnimation.value;

        return SizedBox(
          height: 130,
          width: double.infinity,
          child: CustomPaint(
            painter: _SunArcPainter(
              dayProgressFraction: animatedProgress,
              arcBackgroundColor: AppColors.white.withValues(alpha: 0.25),
              arcActiveColor: const Color(0xFFFFE082),
              sunGlowColor: const Color(0xFFFFD700),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSunriseSunsetRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildSunTimeInfo(
          iconData: Icons.wb_twilight_rounded,
          labelText: 'Sunrise',
          timeText: _getDisplayableTime('5:45 AM'),
        ),
        Column(
          children: [
            Text(
              '${(_dayProgressFraction * 100).toStringAsFixed(0)}%',
              style: AppTextStyles.titleLarge.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'of day',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.white.withValues(alpha: 0.70),
                fontSize: 9,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        _buildSunTimeInfo(
          iconData: Icons.nights_stay_rounded,
          labelText: 'Sunset',
          timeText: _getDisplayableTime('6:52 PM'),
        ),
      ],
    );
  }

  Widget _buildSunTimeInfo({
    required IconData iconData,
    required String labelText,
    required String timeText,
  }) {
    return Column(
      children: [
        Icon(
          iconData,
          color: AppColors.white.withValues(alpha: 0.85),
          size: 18,
        ),
        const SizedBox(height: 4),
        Text(
          labelText,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.white.withValues(alpha: 0.70),
            fontSize: 9,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          timeText,
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SECTION 11 — SECTION HEADER
  // ============================================================

  Widget _buildSectionHeader({
    required String headerTitle,
    required IconData headerIcon,
    Widget? trailingAction,
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
          Icon(headerIcon, color: AppColors.accent, size: 16),
          const SizedBox(width: AppSpacing.xs),
          Text(
            headerTitle,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.accent,
              letterSpacing: 2.0,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (trailingAction != null) ...[
            const Spacer(),
            trailingAction,
          ],
        ],
      ),
    );
  }

  Widget _buildTimeFormatToggle() {
    return GestureDetector(
      onTap: _toggleTimeFormat,
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
            const Icon(
              Icons.access_time_rounded,
              color: AppColors.accent,
              size: 12,
            ),
            const SizedBox(width: 4),
            Text(
              _is24HourFormat ? '24H' : '12H',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w800,
                fontSize: 10,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
  // ============================================================
  // SECTION 12 — ALL PRAYERS LIST
  // ============================================================

  Widget _buildAllPrayersList() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: List.generate(_todaysPrayers.length, (index) {
          final _PrayerTimeItem prayer = _todaysPrayers[index];
          final bool isNext = index == _nextPrayerIndex;
          final bool isDone = index < _nextPrayerIndex;
          final Duration delay = Duration(milliseconds: 100 + (index * 80));

          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 600) + delay,
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Opacity(
                  opacity: value.clamp(0.0, 1.0),
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - value)),
                    child: child,
                  ),
                );
              },
              child: _buildSinglePrayerCard(
                prayerItem: prayer,
                prayerIndex: index,
                isNext: isNext,
                isCompleted: isDone,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildSinglePrayerCard({
    required _PrayerTimeItem prayerItem,
    required int prayerIndex,
    required bool isNext,
    required bool isCompleted,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: isNext
            ? const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xFF00A86B), Color(0xFF007A4D)],
              )
            : null,
        color: isNext ? null : AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color: isNext
              ? Colors.transparent
              : isCompleted
                  ? AppColors.primary.withValues(alpha: 0.25)
                  : AppColors.borderSubtle,
          width: 1,
        ),
        boxShadow: isNext
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.30),
                  blurRadius: 16,
                  spreadRadius: 0,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.cardRadius,
        child: Stack(
          children: [
            if (isNext)
              Positioned(
                right: -15,
                bottom: -15,
                child: Icon(
                  prayerItem.prayerIcon,
                  size: 100,
                  color: AppColors.white.withValues(alpha: 0.08),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  // Icon container
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isNext
                          ? AppColors.white.withValues(alpha: 0.20)
                          : isCompleted
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : AppColors.surfaceElevated,
                      borderRadius: AppRadius.buttonRadius,
                      border: Border.all(
                        color: isNext
                            ? AppColors.white.withValues(alpha: 0.25)
                            : isCompleted
                                ? AppColors.primary.withValues(alpha: 0.30)
                                : AppColors.borderSubtle,
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      isCompleted
                          ? Icons.check_circle_rounded
                          : prayerItem.prayerIcon,
                      color: isNext
                          ? AppColors.white
                          : isCompleted
                              ? AppColors.primary
                              : AppColors.iconSecondary,
                      size: 22,
                    ),
                  ),

                  const SizedBox(width: AppSpacing.md),

                  // Name + status
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              prayerItem.prayerName,
                              style: AppTextStyles.titleMedium.copyWith(
                                color: isNext
                                    ? AppColors.white
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              prayerItem.prayerNameArabic,
                              style: TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: 16,
                                color: isNext
                                    ? AppColors.white.withValues(alpha: 0.85)
                                    : AppColors.accent,
                                fontWeight: FontWeight.w600,
                                height: 1.0,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isNext
                              ? 'in $_formattedCountdown'
                              : isCompleted
                                  ? 'Completed'
                                  : 'Upcoming',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: isNext
                                ? AppColors.white.withValues(alpha: 0.80)
                                : isCompleted
                                    ? AppColors.primary
                                    : AppColors.textTertiary,
                            fontWeight: FontWeight.w600,
                            fontFamily: isNext ? 'monospace' : null,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: AppSpacing.sm),

                  // Time + toggles
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _getDisplayableTime(prayerItem.prayerTime),
                        style: AppTextStyles.titleMedium.copyWith(
                          color:
                              isNext ? AppColors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'monospace',
                          height: 1.0,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildMiniToggleButton(
                            iconData: prayerItem.isAdhanEnabled
                                ? Icons.volume_up_rounded
                                : Icons.volume_off_rounded,
                            isEnabled: prayerItem.isAdhanEnabled,
                            isOnColoredBg: isNext,
                            onTapAction: () => _togglePrayerAdhan(prayerIndex),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          _buildMiniToggleButton(
                            iconData: prayerItem.isReminderEnabled
                                ? Icons.notifications_active_rounded
                                : Icons.notifications_off_outlined,
                            isEnabled: prayerItem.isReminderEnabled,
                            isOnColoredBg: isNext,
                            onTapAction: () =>
                                _togglePrayerReminder(prayerIndex),
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
    );
  }

  Widget _buildMiniToggleButton({
    required IconData iconData,
    required bool isEnabled,
    required bool isOnColoredBg,
    required VoidCallback onTapAction,
  }) {
    return GestureDetector(
      onTap: onTapAction,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: isOnColoredBg
              ? AppColors.white.withValues(alpha: isEnabled ? 0.25 : 0.10)
              : isEnabled
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : AppColors.surfaceElevated,
          shape: BoxShape.circle,
          border: Border.all(
            color: isOnColoredBg
                ? AppColors.white.withValues(alpha: isEnabled ? 0.40 : 0.20)
                : isEnabled
                    ? AppColors.primary.withValues(alpha: 0.35)
                    : AppColors.borderSubtle,
            width: 1,
          ),
        ),
        child: Icon(
          iconData,
          color: isOnColoredBg
              ? AppColors.white
              : isEnabled
                  ? AppColors.primary
                  : AppColors.textTertiary,
          size: 12,
        ),
      ),
    );
  }

  // ============================================================
  // SECTION 13 — CALCULATION METHOD CARD
  // ============================================================

  Widget _buildCalculationMethodCard() {
    final _CalculationMethod selected =
        _allCalculationMethods[_selectedCalculationIndex];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: AppCard(
        onTap: _openCalculationMethodBottomSheet,
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: AppRadius.buttonRadius,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.30),
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.calculate_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    selected.methodFullName,
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    selected.methodDescription,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                gradient: AppGradients.emerald,
                borderRadius: AppRadius.pillRadius,
              ),
              child: Text(
                selected.methodShortCode,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
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

  void _openCalculationMethodBottomSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _buildCalculationMethodSheet(),
    );
  }

  Widget _buildCalculationMethodSheet() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderSubtle,
                borderRadius: AppRadius.pillRadius,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Title
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
                'CALCULATION METHOD',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.accent,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Choose your region\'s standard',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Methods list
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _allCalculationMethods.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final _CalculationMethod method = _allCalculationMethods[index];
                final bool isSelected = index == _selectedCalculationIndex;
                return _buildCalculationMethodTile(
                  methodItem: method,
                  isSelected: isSelected,
                  onTapAction: () => _selectCalculationMethod(index),
                );
              },
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }

  Widget _buildCalculationMethodTile({
    required _CalculationMethod methodItem,
    required bool isSelected,
    required VoidCallback onTapAction,
  }) {
    return GestureDetector(
      onTap: onTapAction,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.10)
              : AppColors.surfaceElevated,
          borderRadius: AppRadius.cardRadius,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderSubtle,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            // Radio indicator
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      isSelected ? AppColors.primary : AppColors.borderSubtle,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          methodItem.methodFullName,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.surface,
                          borderRadius: AppRadius.pillRadius,
                          border: Border.all(
                            color: isSelected
                                ? Colors.transparent
                                : AppColors.borderSubtle,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          methodItem.methodShortCode,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: isSelected
                                ? AppColors.white
                                : AppColors.textTertiary,
                            fontWeight: FontWeight.w800,
                            fontSize: 9,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    methodItem.methodDescription,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textSecondary,
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

  // ============================================================
  // SECTION 14 — ASR METHOD CARD
  // ============================================================

  Widget _buildAsrMethodCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.cardRadius,
          border: Border.all(color: AppColors.borderSubtle, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.12),
                    borderRadius: AppRadius.buttonRadius,
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.30),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.wb_cloudy_outlined,
                    color: AppColors.accent,
                    size: 18,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Asr Method',
                        style: AppTextStyles.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _allAsrMethods[_selectedAsrMethodIndex].asrDescription,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // iOS-style segmented control
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: AppRadius.buttonRadius,
                border: Border.all(
                  color: AppColors.borderSubtle,
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.all(3),
              child: Row(
                children: List.generate(_allAsrMethods.length, (index) {
                  final _AsrMethod asr = _allAsrMethods[index];
                  final bool isSelected = index == _selectedAsrMethodIndex;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _selectAsrMethod(index),
                      child: AnimatedContainer(
                        duration: AppDurations.fast,
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          gradient: isSelected ? AppGradients.emerald : null,
                          borderRadius: AppRadius.buttonRadius,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary
                                        .withValues(alpha: 0.30),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          asr.asrShortName,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.labelMedium.copyWith(
                            color: isSelected
                                ? AppColors.white
                                : AppColors.textSecondary,
                            fontWeight:
                                isSelected ? FontWeight.w800 : FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SECTION 15 — MORE OPTIONS CARD
  // ============================================================

  Widget _buildMoreOptionsCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.cardRadius,
          border: Border.all(color: AppColors.borderSubtle, width: 1),
        ),
        child: Column(
          children: [
            _buildMoreOptionTile(
              iconData: Icons.mosque_rounded,
              iconColor: AppColors.primary,
              titleText: 'Nearby Mosques',
              subtitleText: 'Find mosques around you',
              onTapAction: () {
                HapticFeedback.lightImpact();
                context.go(AppRoutes.qibla);
              },
            ),
            _buildOptionDivider(),
            _buildMoreOptionTile(
              iconData: Icons.music_note_rounded,
              iconColor: AppColors.accent,
              titleText: 'Adhan Sounds',
              subtitleText: '5+ premium adhan recitations',
              onTapAction: _showComingSoonSnackbar,
            ),
            _buildOptionDivider(),
            _buildMoreOptionTile(
              iconData: Icons.notifications_active_rounded,
              iconColor: const Color(0xFF7C3AED),
              titleText: 'Pre-Adhan Reminder',
              subtitleText: '15 minutes before prayer',
              onTapAction: _showComingSoonSnackbar,
              trailingWidget: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.15),
                  borderRadius: AppRadius.pillRadius,
                ),
                child: Text(
                  '15 min',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: const Color(0xFF7C3AED),
                    fontWeight: FontWeight.w700,
                    fontSize: 9,
                  ),
                ),
              ),
            ),
            _buildOptionDivider(),
            _buildMoreOptionTile(
              iconData: Icons.tune_rounded,
              iconColor: const Color(0xFF0891B2),
              titleText: 'Manual Adjustment',
              subtitleText: 'Fine-tune prayer times',
              onTapAction: _showComingSoonSnackbar,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMoreOptionTile({
    required IconData iconData,
    required Color iconColor,
    required String titleText,
    required String subtitleText,
    required VoidCallback onTapAction,
    Widget? trailingWidget,
  }) {
    return InkWell(
      onTap: onTapAction,
      borderRadius: AppRadius.cardRadius,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: AppRadius.buttonRadius,
                border: Border.all(
                  color: iconColor.withValues(alpha: 0.30),
                  width: 1,
                ),
              ),
              child: Icon(iconData, color: iconColor, size: 18),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titleText,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitleText,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (trailingWidget != null) trailingWidget,
            const SizedBox(width: AppSpacing.xs),
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

  Widget _buildOptionDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Divider(
        color: AppColors.borderSubtle,
        height: 1,
        thickness: 1,
      ),
    );
  }

  void _showComingSoonSnackbar() {
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
            Text(
              'Coming soon in future update',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.white,
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
} // ← END of _PrayerScreenState

// ============================================================
// END OF FILE — prayer_screen.dart (Premium v1.1)
// ============================================================
