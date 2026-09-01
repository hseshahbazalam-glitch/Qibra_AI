// lib/features/prayer/presentation/salah_schedule_screen.dart
// Full Salah Schedule — All Coming Soons Fixed

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hijri/hijri_calendar.dart';

import 'package:qibra_ai/core/constants/app_constants.dart';
import 'package:qibra_ai/core/design_system/qibra_colors.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';
import '../../../shared/widgets/controls/app_switch_tile.dart';

import '../providers/prayer_provider.dart';
import '../data/models/prayer_models.dart';
import 'widgets/schedule_prayer_tile.dart';

class SalahScheduleScreen extends ConsumerStatefulWidget {
  const SalahScheduleScreen({super.key});

  @override
  ConsumerState<SalahScheduleScreen> createState() =>
      _SalahScheduleScreenState();
}

class _SalahScheduleScreenState extends ConsumerState<SalahScheduleScreen> {
  final Map<PrayerType, bool> _notifications = {
    PrayerType.fajr: true,
    PrayerType.sunrise: false,
    PrayerType.dhuhr: true,
    PrayerType.asr: true,
    PrayerType.maghrib: true,
    PrayerType.isha: true,
  };

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
    final colors = QibraColors.of(context);
    final nextPrayerInfo = ref.watch(nextPrayerProvider);
    final dailyTimes = ref.watch(dailyPrayerTimesProvider);
    final location = ref.watch(locationProvider);
    final settings = ref.watch(prayerSettingsProvider);

    final now = DateTime.now();
    final hijri = HijriCalendar.now();
    final displayType = nextPrayerInfo?.prayer.type;
    final displayName = displayType == null ? '—' : _getName(displayType);
    final displayArabic = displayType == null ? '' : _getArabicName(displayType);
    final displayTime = nextPrayerInfo?.prayer.formattedTime ?? '—';
    final displayCountdown = nextPrayerInfo?.countdown;

    final totalSeconds = displayCountdown?.inSeconds.abs() ?? 0;
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    final formattedCountdown = displayCountdown == null
        ? '—'
        : '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: colors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 100,
            pinned: true,
            backgroundColor: colors.background,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.border),
                ),
                child: Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: colors.textPrimary,
                ),
              ),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoutes.prayer);
                }
              },
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PRAYER TIMES',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.0,
                    fontSize: 10,
                  ),
                ),
                Text(
                  'Salah Schedule',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.border),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.bar_chart_rounded,
                      color: colors.textPrimary,
                      size: 20,
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      context.push(AppRoutes.prayerStatistics);
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.border),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: Icon(
                      Icons.settings_rounded,
                      color: colors.textPrimary,
                      size: 20,
                    ),
                    onPressed: () => _showPrayerSettings(),
                  ),
                ),
              ),
            ],
          ),

          // Date Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: AppRadius.cardRadius,
                  border: Border.all(color: colors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.calendar_month_rounded,
                        color: colors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_getDayName(now.weekday)}, ${now.day} ${_getMonth(now.month)} ${now.year}',
                            style: AppTextStyles.titleSmall.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear} AH',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: colors.accent,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.expand_more_rounded,
                      color: colors.textSecondary,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Next Prayer Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF1A2748),
                      Color(0xFFEEF1EA),
                    ],
                  ),
                  borderRadius: AppRadius.cardRadiusLarge,
                  border: Border.all(
                    color: const Color(0xFF2F6B5D).withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF2F6B5D).withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF2F6B5D),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            displayType == null
                                ? Icons.access_time_rounded
                                : _getIcon(displayType),
                            color: const Color(0xFF2F6B5D),
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color:
                                      colors.onPrimary.withValues(alpha: 0.15),
                                  borderRadius: AppRadius.pillRadius,
                                ),
                                child: Text(
                                  'NEXT PRAYER',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: colors.onPrimary,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 9,
                                    letterSpacing: 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    displayName,
                                    style:
                                        AppTextStyles.headlineMedium.copyWith(
                                      color: colors.onPrimary,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text(
                                      displayArabic,
                                      style: const TextStyle(
                                        fontFamily: 'Amiri',
                                        fontSize: 20,
                                        color: Color(0xFFC6A15B),
                                        fontWeight: FontWeight.w700,
                                      ),
                                      textDirection: TextDirection.rtl,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              displayTime,
                              style: AppTextStyles.titleLarge.copyWith(
                                color: colors.onPrimary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              displayType?.description ?? '',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: colors.onPrimary.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.3),
                        borderRadius: AppRadius.buttonRadius,
                        border: Border.all(
                          color: colors.onPrimary.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.timer_outlined,
                            color: Color(0xFFC6A15B),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'in ',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: colors.onPrimary.withValues(alpha: 0.7),
                            ),
                          ),
                          Text(
                            formattedCountdown,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 20,
                              color: const Color(0xFFC6A15B),
                              fontWeight: FontWeight.w900,
                              shadows: [
                                Shadow(
                                  color: const Color(0xFFC6A15B)
                                      .withValues(alpha: 0.5),
                                  blurRadius: 8,
                                ),
                              ],
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

          // Method Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              child: _buildInfoCard(
                icon: Icons.tune_rounded,
                iconColor: const Color(0xFF2F6B5D),
                title: 'Method: ${_getMethodName(settings.calculationMethod)}',
                onTap: _showMethodSelector,
              ),
            ),
          ),

          // Location Card
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
              child: _buildInfoCard(
                icon: Icons.location_on_rounded,
                iconColor: const Color(0xFFC6A15B),
                title: 'My Location',
                subtitle: location.location?.displayName ?? 'Auto-detected',
                onTap: _showLocationOptions,
              ),
            ),
          ),

          // Section Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
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
                    "TODAY'S SCHEDULE",
                    style: AppTextStyles.labelSmall.copyWith(
                      color: colors.accent,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Prayer List
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildPrayerList(dailyTimes, nextPrayerInfo),
            ),
          ),

          // Manage Notifications Button
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: _showNotificationsSheet,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.1),
                    borderRadius: AppRadius.cardRadius,
                    border: Border.all(
                      color: colors.primary.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_active_rounded,
                        color: colors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Manage Prayer Notifications',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  // ============================================================
  // METHOD SELECTOR
  // ============================================================

  void _showMethodSelector() {
    final colors = QibraColors.of(context);
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final settings = ref.watch(prayerSettingsProvider);
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.textTertiary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Calculation Method',
                style: AppTextStyles.titleLarge.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              ...CalculationMethod.values.map((method) {
                final isSelected = settings.calculationMethod == method;
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    isSelected
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    color:
                        isSelected ? colors.primary : colors.textTertiary,
                  ),
                  title: Text(
                    _getMethodName(method),
                    style: AppTextStyles.titleSmall.copyWith(
                      color: colors.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                    ),
                  ),
                  onTap: () async {
                    HapticFeedback.selectionClick();
                    await ref
                        .read(prayerSettingsProvider.notifier)
                        .setCalculationMethod(method);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                );
              }),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // LOCATION OPTIONS
  // ============================================================

  void _showLocationOptions() {
    final colors = QibraColors.of(context);
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.textTertiary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Location Settings',
                style: AppTextStyles.titleLarge.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.my_location_rounded,
                    color: colors.primary,
                  ),
                ),
                title: Text(
                  'Auto-detect Location',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  'Use GPS to detect your location',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                onTap: () async {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(ctx);
                  await ref
                      .read(locationProvider.notifier)
                      .fetchCurrentLocation();
                },
              ),
              Divider(color: colors.border),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: colors.accent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.mosque_rounded,
                    color: colors.accent,
                  ),
                ),
                title: Text(
                  'Reset to Makkah',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  'Use Makkah as default location',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                onTap: () async {
                  HapticFeedback.mediumImpact();
                  Navigator.pop(ctx);
                  await ref.read(locationProvider.notifier).resetToDefault();
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // NOTIFICATIONS SHEET
  // ============================================================

  void _showNotificationsSheet() {
    final colors = QibraColors.of(context);
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.textTertiary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Prayer Notifications',
                    style: AppTextStyles.titleLarge.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Toggle azan alerts for each prayer',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ..._notifications.entries.map((entry) {
                    return AppSwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        _getName(entry.key),
                        style: AppTextStyles.titleSmall.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        _getArabicName(entry.key),
                        style: const TextStyle(
                          fontFamily: 'Amiri',
                          color: Color(0xFFC6A15B),
                          fontSize: 13,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      value: entry.value,
                      onChanged: (val) {
                        HapticFeedback.selectionClick();
                        setModalState(() {
                          _notifications[entry.key] = val;
                        });
                        setState(() {});
                      },
                    );
                  }),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // PRAYER SETTINGS SHEET
  // ============================================================

  void _showPrayerSettings() {
    final colors = QibraColors.of(context);
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final settings = ref.watch(prayerSettingsProvider);
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.textTertiary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Prayer Settings',
                style: AppTextStyles.titleLarge.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 20),
              AppSwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Enable Adhan',
                    style: TextStyle(color: colors.textPrimary)),
                subtitle: Text('Play adhan sound',
                    style: TextStyle(
                        color: colors.textSecondary, fontSize: 12)),
                value: settings.enableAdhan,
                activeColor: colors.primary,
                onChanged: (v) async {
                  await ref
                      .read(prayerSettingsProvider.notifier)
                      .toggleAdhan(v);
                },
              ),
              AppSwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('Show Sunrise',
                    style: TextStyle(color: colors.textPrimary)),
                subtitle: Text('Display sunrise in schedule',
                    style: TextStyle(
                        color: colors.textSecondary, fontSize: 12)),
                value: settings.showSunrise,
                activeColor: colors.primary,
                onChanged: (v) async {
                  await ref
                      .read(prayerSettingsProvider.notifier)
                      .toggleSunrise(v);
                },
              ),
              AppSwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text('24-Hour Format',
                    style: TextStyle(color: colors.textPrimary)),
                subtitle: Text('Use 24-hour time',
                    style: TextStyle(
                        color: colors.textSecondary, fontSize: 12)),
                value: settings.use24HourFormat,
                activeColor: colors.primary,
                onChanged: (v) async {
                  await ref
                      .read(prayerSettingsProvider.notifier)
                      .set24HourFormat(v);
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) {
    final colors = QibraColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: AppRadius.cardRadius,
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: colors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colors.textTertiary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerList(
    DailyPrayerTimes? dailyTimes,
    NextPrayerInfo? nextInfo,
  ) {
    final colors = QibraColors.of(context);
    final nextType = nextInfo?.prayer.type;

    final prayers = [
      _makePrayer(
        PrayerType.fajr,
        dailyTimes?.getPrayer(PrayerType.fajr)?.formattedTime ?? '—',
        nextType == PrayerType.fajr,
      ),
      _makePrayer(
        PrayerType.sunrise,
        dailyTimes?.getPrayer(PrayerType.sunrise)?.formattedTime ?? '—',
        false,
      ),
      _makePrayer(
        PrayerType.dhuhr,
        dailyTimes?.getPrayer(PrayerType.dhuhr)?.formattedTime ?? '—',
        nextType == PrayerType.dhuhr,
      ),
      _makePrayer(
        PrayerType.asr,
        dailyTimes?.getPrayer(PrayerType.asr)?.formattedTime ?? '—',
        nextType == PrayerType.asr,
      ),
      _makePrayer(
        PrayerType.maghrib,
        dailyTimes?.getPrayer(PrayerType.maghrib)?.formattedTime ?? '—',
        nextType == PrayerType.maghrib,
      ),
      _makePrayer(
        PrayerType.isha,
        dailyTimes?.getPrayer(PrayerType.isha)?.formattedTime ?? '—',
        nextType == PrayerType.isha,
      ),
    ];

    return Column(children: prayers);
  }

  Widget _makePrayer(PrayerType type, String time, bool isNext) {
    return SchedulePrayerTile(
      icon: _getIcon(type),
      iconColor: _getColor(type),
      name: _getName(type),
      nameArabic: _getArabicName(type),
      time: time,
      isNext: isNext,
      notificationEnabled: _notifications[type] ?? true,
      onBellTap: () {
        setState(() {
          _notifications[type] = !(_notifications[type] ?? true);
        });
      },
    );
  }

  String _getMethodName(CalculationMethod method) {
    // Fallback: any enum name to readable text
    final name = method.name;
    switch (name) {
      case 'muslimWorldLeague':
        return 'MWL (Muslim World League)';
      case 'egyptian':
        return 'Egyptian';
      case 'karachi':
        return 'University of Karachi';
      case 'ummAlQura':
        return 'Umm Al-Qura (Makkah)';
      case 'tehran':
        return 'Tehran';
      case 'singapore':
        return 'Singapore';
      case 'islamicSociety':
        return 'ISNA (Islamic Society)';
      default:
        return name;
    }
  }

  String _getName(PrayerType type) {
    switch (type) {
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
        return const Color(0xFF2F6B5D);
      case PrayerType.sunrise:
        return const Color(0xFFC6A15B);
      case PrayerType.dhuhr:
        return const Color(0xFFC6A15B);
      case PrayerType.asr:
        return QibraColors.light.error;
      case PrayerType.maghrib:
        return const Color(0xFFC6A15B);
      case PrayerType.isha:
        return const Color(0xFF2F6B5D);
    }
  }

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

  String _getMonth(int month) {
    const months = [
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
}
