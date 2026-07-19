// lib/features/prayer/presentation/prayer_times_screen.dart

// ============================================================
// QIBRA AI — PRAYER TIMES SCREEN (v1.0)
// Phase: 9 — Premium Prayer UI
// ============================================================
import 'prayer_settings_screen.dart';
import 'prayer_tracker_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';

import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_design_system.dart';
import '../../../core/design_system/app_typography.dart';
import '../data/models/prayer_models.dart';
import '../providers/prayer_provider.dart';

// ============================================================
// MAIN SCREEN
// ============================================================

class PrayerTimesScreen extends ConsumerStatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  ConsumerState<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends ConsumerState<PrayerTimesScreen>
    with TickerProviderStateMixin {
  late final AnimationController _headerAnim;
  late final AnimationController _pulseAnim;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _headerAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _pulseAnim = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _fadeAnim = CurvedAnimation(
      parent: _headerAnim,
      curve: Curves.easeOutCubic,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _headerAnim,
        curve: Curves.easeOutCubic,
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _headerAnim.forward();
        _initializeLocation();
      }
    });
  }

  @override
  void dispose() {
    _headerAnim.dispose();
    _pulseAnim.dispose();
    super.dispose();
  }

  void _initializeLocation() {
    final locationState = ref.read(locationProvider);
    if (locationState.location == null) {
      ref.read(locationProvider.notifier).fetchCurrentLocation();
    }
  }

  Future<void> _refresh() async {
    HapticFeedback.mediumImpact();
    await ref.read(locationProvider.notifier).fetchCurrentLocation();
  }

  void _showLocationRequest() {
    HapticFeedback.selectionClick();
    ref.read(locationProvider.notifier).fetchCurrentLocation();
  }

  void _markPrayer(PrayerTime prayer, PrayerStatus status) {
    HapticFeedback.mediumImpact();
    ref.read(prayerRecordsProvider.notifier).markPrayer(
          date: DateTime.now(),
          type: prayer.type,
          status: status,
        );

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(status.icon, color: Colors.white, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Text(
              '${prayer.type.name} marked as ${status.label}',
              style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: status.color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        margin: const EdgeInsets.all(AppSpacing.lg),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showMarkOptions(PrayerTime prayer) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _MarkPrayerSheet(
        prayer: prayer,
        onSelect: (status) {
          Navigator.of(context).pop();
          _markPrayer(prayer, status);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(azanSchedulerProvider); // ← YEH LINE ADD KARO

    // Baaki jo pehle se code tha
    final locationState = ref.watch(locationProvider);
    final times = ref.watch(dailyPrayerTimesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withValues(alpha: 0.14),
              AppColors.background,
              AppColors.background,
            ],
            stops: const [0.0, 0.30, 1.0],
          ),
        ),
        child: SafeArea(
          child: _buildContent(locationState, times),
        ),
      ),
    );
  }

  Widget _buildContent(LocationState locationState, DailyPrayerTimes? times) {
    // Loading state
    if (locationState.isLoading && locationState.location == null) {
      return _buildLoadingState();
    }

    // No location
    if (locationState.location == null) {
      return _buildLocationRequestState(locationState);
    }

    // No times calculated
    if (times == null) {
      return _buildCalculatingState();
    }

    // Main content
    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppColors.primary,
      backgroundColor: AppColors.surfaceElevated,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTopBar(times.location),
                      const SizedBox(height: AppSpacing.lg),
                      _buildDateCard(),
                      const SizedBox(height: AppSpacing.lg),
                      _buildNextPrayerHero(),
                      const SizedBox(height: AppSpacing.lg),
                      _buildLocationCard(times.location),
                      const SizedBox(height: AppSpacing.xl),
                      _buildTimelineHeader(),
                      const SizedBox(height: AppSpacing.md),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.xl3 + AppSpacing.xl2,
            ),
            sliver: SliverList.separated(
              itemCount: times.prayers.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final prayer = times.prayers[index];
                return _PrayerCard(
                  prayer: prayer,
                  onMark: () => _showMarkOptions(prayer),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Top Bar ────────────────────────────────────────────────

  Widget _buildTopBar(PrayerLocation location) {
    return Row(
      children: [
        _CircleButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).maybePop();
          },
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PRAYER TIMES',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.4,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Salah Schedule',
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        _CircleButton(
          icon: Icons.analytics_rounded,
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const PrayerTrackerScreen(),
              ),
            );
          },
        ),
        const SizedBox(width: AppSpacing.sm),
        _CircleButton(
          icon: Icons.settings_rounded,
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const PrayerSettingsScreen(),
              ),
            );
          },
        ),
      ],
    );
  }
  // ── Date Card ──────────────────────────────────────────────

  Widget _buildDateCard() {
    final now = DateTime.now();
    final hijri = HijriCalendar.fromDate(now);
    final weekday = _weekdayName(now.weekday);
    final month = _monthName(now.month);
    final hijriMonth = _hijriMonthName(hijri.hMonth);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_today_rounded,
            color: AppColors.primary,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$weekday, ${now.day} $month ${now.year}',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${hijri.hDay} $hijriMonth ${hijri.hYear} AH',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Next Prayer Hero ───────────────────────────────────────

  Widget _buildNextPrayerHero() {
    final nextInfo = ref.watch(nextPrayerProvider);

    if (nextInfo == null) {
      return const SizedBox.shrink();
    }

    final prayer = nextInfo.prayer;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            prayer.type.color.withValues(alpha: 0.30),
            prayer.type.color.withValues(alpha: 0.18),
            AppColors.primary.withValues(alpha: 0.20),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl3),
        border: Border.all(
          color: prayer.type.color.withValues(alpha: 0.30),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: prayer.type.color.withValues(alpha: 0.20),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Icon with pulse
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (context, child) {
                  return Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          prayer.type.color,
                          prayer.type.color.withValues(alpha: 0.70),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: prayer.type.color.withValues(
                            alpha: 0.30 + (_pulseAnim.value * 0.30),
                          ),
                          blurRadius: 20 + (_pulseAnim.value * 15),
                          spreadRadius: _pulseAnim.value * 3,
                        ),
                      ],
                    ),
                    child: Icon(
                      prayer.type.icon,
                      color: Colors.white,
                      size: 28,
                    ),
                  );
                },
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                      ),
                      child: Text(
                        'NEXT PRAYER',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 9,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs + 2),
                    Text(
                      prayer.type.name,
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      prayer.type.arabicName,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 22,
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              // Prayer time
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    prayer.formattedTime,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    prayer.type.description,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),

          // Countdown
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.24),
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.timer_rounded,
                  color: AppColors.accent,
                  size: 20,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'in ',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  nextInfo.formattedCountdown,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: nextInfo.progress,
              minHeight: 6,
              backgroundColor: Colors.black.withValues(alpha: 0.30),
              valueColor: AlwaysStoppedAnimation<Color>(prayer.type.color),
            ),
          ),
        ],
      ),
    );
  }

  // ── Location Card ──────────────────────────────────────────

  Widget _buildLocationCard(PrayerLocation location) {
    final settings = ref.watch(prayerSettingsProvider);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.80),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(
              location.isManuallySet
                  ? Icons.push_pin_rounded
                  : Icons.my_location_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  location.displayName,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${settings.calculationMethod.shortName} • ${settings.asrMethod.shortName}',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }

  // ── Timeline Header ────────────────────────────────────────

  Widget _buildTimelineHeader() {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          "TODAY'S SCHEDULE",
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  // ── Loading State ──────────────────────────────────────────

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              color: AppColors.primary,
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Detecting your location...',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalculatingState() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  // ── Location Request State ─────────────────────────────────

  Widget _buildLocationRequestState(LocationState state) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Row(
            children: [
              _CircleButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
          const Spacer(),
          Center(
            child: Column(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.20),
                        AppColors.primary.withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                  child: Icon(
                    state.status == LocationStatus.denied
                        ? Icons.location_off_rounded
                        : Icons.location_on_rounded,
                    size: 50,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  state.status == LocationStatus.denied
                      ? 'Location Access Denied'
                      : state.status == LocationStatus.disabled
                          ? 'Location Services Off'
                          : 'Enable Location',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  state.error ??
                      'We need your location\nto calculate accurate prayer times',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                ElevatedButton.icon(
                  onPressed: _showLocationRequest,
                  icon: const Icon(Icons.location_searching_rounded, size: 20),
                  label: Text(
                    'Enable Location',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    elevation: 0,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    ref.read(locationProvider.notifier).resetToDefault();
                  },
                  child: Text(
                    'Use Makkah instead',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  // ── Helpers ────────────────────────────────────────────────

  String _weekdayName(int weekday) {
    return switch (weekday) {
      1 => 'Monday',
      2 => 'Tuesday',
      3 => 'Wednesday',
      4 => 'Thursday',
      5 => 'Friday',
      6 => 'Saturday',
      7 => 'Sunday',
      _ => '',
    };
  }

  String _monthName(int month) {
    const names = [
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
      'December'
    ];
    return names[month - 1];
  }

  String _hijriMonthName(int month) {
    const names = [
      'Muharram',
      'Safar',
      'Rabi\' I',
      'Rabi\' II',
      'Jumada I',
      'Jumada II',
      'Rajab',
      'Sha\'ban',
      'Ramadan',
      'Shawwal',
      'Dhul-Qadah',
      'Dhul-Hijjah'
    ];
    return names[month - 1];
  }
}

// ============================================================
// PRAYER CARD
// ============================================================

class _PrayerCard extends ConsumerWidget {
  const _PrayerCard({
    required this.prayer,
    required this.onMark,
  });

  final PrayerTime prayer;
  final VoidCallback onMark;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = ref.watch(currentTimeProvider).value ?? DateTime.now();
    final isPast = prayer.isPast(now);
    final nextInfo = ref.watch(nextPrayerProvider);
    final isNext = nextInfo?.prayer.type == prayer.type;

    final record = ref.watch(prayerRecordsProvider.notifier).getRecord(
          now,
          prayer.type,
        );
    final hasRecord = record != null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: prayer.type.isObligatory ? onMark : null,
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        splashColor: prayer.type.color.withValues(alpha: 0.10),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated.withValues(alpha: 0.90),
            borderRadius: BorderRadius.circular(AppRadius.xl2),
            border: Border.all(
              color: isNext
                  ? prayer.type.color.withValues(alpha: 0.40)
                  : AppColors.primary.withValues(alpha: 0.10),
              width: isNext ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
              if (isNext)
                BoxShadow(
                  color: prayer.type.color.withValues(alpha: 0.14),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: prayer.type.color.withValues(alpha: 0.16),
                    border: Border.all(
                      color: prayer.type.color.withValues(alpha: 0.30),
                    ),
                  ),
                  child: Icon(
                    prayer.type.icon,
                    color: prayer.type.color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // Name & description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            prayer.type.name,
                            style: AppTextStyles.titleSmall.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          if (isNext)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    prayer.type.color.withValues(alpha: 0.20),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.sm),
                              ),
                              child: Text(
                                'NEXT',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: prayer.type.color,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 9,
                                ),
                              ),
                            ),
                        ],
                      ),
                      Text(
                        prayer.type.arabicName,
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 14,
                          color: AppColors.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Time & status
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      prayer.formattedTime,
                      style: AppTextStyles.titleSmall.copyWith(
                        color: isPast
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        decoration: hasRecord ? null : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    if (hasRecord)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: record.status.color.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              record.status.icon,
                              color: record.status.color,
                              size: 10,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              record.status.label,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: record.status.color,
                                fontWeight: FontWeight.w800,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      )
                    else if (prayer.type.isObligatory && isPast)
                      Text(
                        'Tap to mark',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textTertiary,
                          fontSize: 9,
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
}

// ============================================================
// MARK PRAYER BOTTOM SHEET
// ============================================================

class _MarkPrayerSheet extends StatelessWidget {
  const _MarkPrayerSheet({
    required this.prayer,
    required this.onSelect,
  });

  final PrayerTime prayer;
  final ValueChanged<PrayerStatus> onSelect;

  @override
  Widget build(BuildContext context) {
    final options = [
      PrayerStatus.prayed,
      PrayerStatus.prayedInMosque,
      PrayerStatus.missed,
      PrayerStatus.makeup,
    ];

    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.xl2),
      decoration: BoxDecoration(
        color: AppColors.surfaceSheet,
        borderRadius: BorderRadius.circular(AppRadius.xl3),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textTertiary.withValues(alpha: 0.40),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Icon(prayer.type.icon, color: prayer.type.color),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Mark ${prayer.type.name}',
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                prayer.formattedTime,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ...options.map((status) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onSelect(status),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated.withValues(alpha: 0.70),
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      border: Border.all(
                        color: status.color.withValues(alpha: 0.20),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: status.color.withValues(alpha: 0.16),
                            shape: BoxShape.circle,
                          ),
                          child:
                              Icon(status.icon, color: status.color, size: 20),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            status.label,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.textTertiary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ============================================================
// CIRCLE BUTTON
// ============================================================

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.14),
            ),
          ),
          child: Icon(icon, size: 20, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

// ============================================================
// END OF FILE — prayer_times_screen.dart
// ============================================================
