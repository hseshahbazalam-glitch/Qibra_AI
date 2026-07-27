// lib/features/prayer/presentation/prayer_times_screen.dart
// ============================================================
// QIBRA AI — Premium Prayer Times Screen v2.1
// ============================================================
import 'tahajjud_details_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'prayer_statistics_screen.dart';
import 'package:qibra_ai/core/constants/app_constants.dart';
import 'package:qibra_ai/core/design_system/app_colors.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';

import '../providers/prayer_provider.dart';
import '../data/models/prayer_models.dart';
import 'salah_schedule_screen.dart';
import 'widgets/prayer_hero_card.dart';
import 'widgets/prayer_quick_action.dart';
import 'widgets/night_worship_card.dart';

class PrayerTimesScreen extends ConsumerStatefulWidget {
  const PrayerTimesScreen({super.key});

  @override
  ConsumerState<PrayerTimesScreen> createState() => _PrayerTimesScreenState();
}

class _PrayerTimesScreenState extends ConsumerState<PrayerTimesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _detectLocation();
    });
  }

  Future<void> _detectLocation() async {
    final locationState = ref.read(locationProvider);
    if (locationState.status == LocationStatus.initial ||
        locationState.status == LocationStatus.disabled) {
      await ref.read(locationProvider.notifier).fetchCurrentLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final nextPrayerInfo = ref.watch(nextPrayerProvider);
    final dailyTimes = ref.watch(dailyPrayerTimesProvider);

    final displayName = nextPrayerInfo?.prayer.type.uiDisplayName ?? 'Fajr';
    final displayArabic =
        _getArabicName(nextPrayerInfo?.prayer.type ?? PrayerType.fajr);
    final displayCountdown =
        nextPrayerInfo?.countdown ?? const Duration(hours: 3, minutes: 52);

    final totalSeconds = displayCountdown.inSeconds.abs();
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    final formattedCountdown =
        '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    final now = DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(dailyPrayerTimesProvider);
          ref.invalidate(nextPrayerProvider);
          await Future.delayed(const Duration(seconds: 1));
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // Status bar safe area
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.of(context).padding.top,
              ),
            ),
            SliverToBoxAdapter(child: _buildTopBar(context)),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 8),
                child: PrayerHeroCard(
                  prayerName: displayName,
                  prayerNameArabic: displayArabic,
                  countdown: formattedCountdown,
                  temperature: '25°C',
                  qiblaDirection: 'Qibla 287°',
                  gregorianDate:
                      '${now.day} ${_getMonthShort(now.month)} ${now.year}',
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    _openSchedule(context);
                  },
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(
              child: PrayerQuickActionsRow(
                actions: [
                  QuickActionItem(
                    icon: Icons.explore_rounded,
                    label: 'Qibla',
                    color: const Color(0xFF10B981),
                    onTap: () => context.go(AppRoutes.qibla),
                  ),
                  QuickActionItem(
                    icon: Icons.grain_rounded,
                    label: 'Tasbeeh',
                    color: const Color(0xFFF59E0B),
                    onTap: () => context.go(AppRoutes.tasbih),
                  ),
                  QuickActionItem(
                    icon: Icons.volunteer_activism_rounded,
                    label: 'Duas',
                    color: const Color(0xFF7C3AED),
                    onTap: () => context.go(AppRoutes.dua),
                  ),
                  QuickActionItem(
                    icon: Icons.calendar_month_rounded,
                    label: 'Calendar',
                    color: const Color(0xFF0891B2),
                    onTap: () => context.go(AppRoutes.islamicCalendar),
                  ),
                  QuickActionItem(
                    icon: Icons.more_horiz_rounded,
                    label: 'More',
                    color: const Color(0xFF6B7280),
                    onTap: () => _openSchedule(context),
                  ),
                ],
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(
              child: _buildSectionHeader(
                "TODAY'S SCHEDULE",
                trailing: GestureDetector(
                  onTap: () => _openSchedule(context),
                  child: Text(
                    'View All',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(
              child: _buildCompactSchedule(dailyTimes, nextPrayerInfo),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
            SliverToBoxAdapter(
              child: _buildSectionHeader('NIGHT WORSHIP'),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            SliverToBoxAdapter(
              child: NightWorshipCard(
                startsIn: '02:15:30',
                onTap: () {
                  HapticFeedback.mediumImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TahajjudDetailsScreen(),
                    ),
                  );
                },
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 20)),
            SliverToBoxAdapter(
              child: PrayerStreakCard(
                streakDays: 12,
                completedDaysThisWeek: 5,
                onTap: () {
                  HapticFeedback.mediumImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PrayerStatisticsScreen(),
                    ),
                  );
                },
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  void _openSchedule(BuildContext context) {
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SalahScheduleScreen(),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: 12,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.waving_hand_rounded,
            color: Color(0xFFF59E0B),
            size: 24,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assalamu Alaikum',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'May Allah bless your day',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.notifications_outlined,
                  color: AppColors.textPrimary,
                  size: 20,
                ),
                Positioned(
                  top: 8,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {Widget? trailing}) {
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
          const SizedBox(width: 8),
          Text(
            title,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.accent,
              letterSpacing: 2.0,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (trailing != null) ...[
            const Spacer(),
            trailing,
          ],
        ],
      ),
    );
  }

  Widget _buildCompactSchedule(
    DailyPrayerTimes? dailyTimes,
    NextPrayerInfo? nextInfo,
  ) {
    final prayers = <_PrayerScheduleItem>[];

    if (dailyTimes != null) {
      final nextType = nextInfo?.prayer.type;
      prayers.addAll([
        _PrayerScheduleItem(
          type: PrayerType.fajr,
          time: dailyTimes.fajr.formattedTime,
          isNext: nextType == PrayerType.fajr,
        ),
        _PrayerScheduleItem(
          type: PrayerType.sunrise,
          time: dailyTimes.sunrise.formattedTime,
          isNext: false,
        ),
        _PrayerScheduleItem(
          type: PrayerType.dhuhr,
          time: dailyTimes.dhuhr.formattedTime,
          isNext: nextType == PrayerType.dhuhr,
        ),
        _PrayerScheduleItem(
          type: PrayerType.asr,
          time: dailyTimes.asr.formattedTime,
          isNext: nextType == PrayerType.asr,
        ),
        _PrayerScheduleItem(
          type: PrayerType.maghrib,
          time: dailyTimes.maghrib.formattedTime,
          isNext: nextType == PrayerType.maghrib,
        ),
        _PrayerScheduleItem(
          type: PrayerType.isha,
          time: dailyTimes.isha.formattedTime,
          isNext: nextType == PrayerType.isha,
        ),
      ]);
    } else {
      prayers.addAll([
        _PrayerScheduleItem(
          type: PrayerType.fajr,
          time: '04:21 AM',
          isNext: true,
        ),
        _PrayerScheduleItem(
          type: PrayerType.sunrise,
          time: '05:38 AM',
          isNext: false,
        ),
        _PrayerScheduleItem(
          type: PrayerType.dhuhr,
          time: '12:00 PM',
          isNext: false,
        ),
        _PrayerScheduleItem(
          type: PrayerType.asr,
          time: '03:21 PM',
          isNext: false,
        ),
        _PrayerScheduleItem(
          type: PrayerType.maghrib,
          time: '06:22 PM',
          isNext: false,
        ),
        _PrayerScheduleItem(
          type: PrayerType.isha,
          time: '07:34 PM',
          isNext: false,
        ),
      ]);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: prayers.map((p) => _buildPrayerTile(p)).toList(),
      ),
    );
  }

  Widget _buildPrayerTile(_PrayerScheduleItem item) {
    final color = _getColor(item.type);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: item.isNext ? color.withValues(alpha: 0.1) : AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color: item.isNext
              ? color.withValues(alpha: 0.5)
              : AppColors.borderSubtle,
          width: item.isNext ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(_getIcon(item.type), color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.type.uiDisplayName,
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    if (item.isNext) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.2),
                          borderRadius: AppRadius.pillRadius,
                        ),
                        child: Text(
                          'NEXT',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: color,
                            fontWeight: FontWeight.w800,
                            fontSize: 8,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  _getArabicName(item.type),
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 12,
                    color: Color(0xFFFFD700),
                    fontWeight: FontWeight.w600,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
          ),
          Text(
            item.time,
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  String _getArabicName(PrayerType type) {
    switch (type) {
      case PrayerType.fajr:
        return 'الفجر';
      case PrayerType.sunrise:
        return 'الشروق';
      case PrayerType.dhuhr:
        return 'الظهر';
      case PrayerType.asr:
        return 'العصر';
      case PrayerType.maghrib:
        return 'المغرب';
      case PrayerType.isha:
        return 'العشاء';
    }
  }

  IconData _getIcon(PrayerType type) {
    switch (type) {
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

  Color _getColor(PrayerType type) {
    switch (type) {
      case PrayerType.fajr:
        return const Color(0xFF7C3AED);
      case PrayerType.sunrise:
        return const Color(0xFFF59E0B);
      case PrayerType.dhuhr:
        return const Color(0xFFFBBF24);
      case PrayerType.asr:
        return const Color(0xFFEF4444);
      case PrayerType.maghrib:
        return const Color(0xFF7C3AED);
      case PrayerType.isha:
        return const Color(0xFF0891B2);
    }
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

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.buttonRadius,
        ),
      ),
    );
  }
}

class _PrayerScheduleItem {
  final PrayerType type;
  final String time;
  final bool isNext;

  _PrayerScheduleItem({
    required this.type,
    required this.time,
    required this.isNext,
  });
}

extension _PrayerTypeName on PrayerType {
  String get uiDisplayName {
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
}
