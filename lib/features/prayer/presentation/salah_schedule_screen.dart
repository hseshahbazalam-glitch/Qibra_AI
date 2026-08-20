// lib/features/prayer/presentation/salah_schedule_screen.dart
// Full Salah Schedule — All Coming Soons Fixed

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:qibra_ai/core/design_system/app_colors.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';

import '../providers/prayer_provider.dart';
import '../data/models/prayer_models.dart';
import 'prayer_statistics_screen.dart';
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
    final nextPrayerInfo = ref.watch(nextPrayerProvider);
    final dailyTimes = ref.watch(dailyPrayerTimesProvider);
    final location = ref.watch(locationProvider);
    final settings = ref.watch(prayerSettingsProvider);

    final now = DateTime.now();
    final displayType = nextPrayerInfo?.prayer.type ?? PrayerType.fajr;
    final displayName = _getName(displayType);
    final displayArabic = _getArabicName(displayType);
    final displayTime = nextPrayerInfo?.prayer.formattedTime ?? '04:21 AM';
    final displayCountdown =
        nextPrayerInfo?.countdown ?? const Duration(hours: 3, minutes: 52);

    final totalSeconds = displayCountdown.inSeconds.abs();
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    final formattedCountdown =
        '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 100,
            pinned: true,
            backgroundColor: AppColors.background,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 18,
                  color: AppColors.textPrimary,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PRAYER TIMES',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.0,
                    fontSize: 10,
                  ),
                ),
                Text(
                  'Salah Schedule',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.bar_chart_rounded,
                      color: AppColors.textPrimary,
                      size: 20,
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PrayerStatisticsScreen(),
                        ),
                      );
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.borderSubtle),
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(
                      Icons.settings_rounded,
                      color: AppColors.textPrimary,
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
                  color: AppColors.surface,
                  borderRadius: AppRadius.cardRadius,
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.calendar_month_rounded,
                        color: AppColors.primary,
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
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '7 Safar 1448 AH',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.accent,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.expand_more_rounded,
                      color: AppColors.textSecondary,
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
                      Color(0xFF0F1B36),
                    ],
                  ),
                  borderRadius: AppRadius.cardRadiusLarge,
                  border: Border.all(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
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
                                const Color(0xFF3B82F6).withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: const Color(0xFF3B82F6),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            _getIcon(displayType),
                            color: const Color(0xFF3B82F6),
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
                                      AppColors.white.withValues(alpha: 0.15),
                                  borderRadius: AppRadius.pillRadius,
                                ),
                                child: Text(
                                  'NEXT PRAYER',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: AppColors.white,
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
                                      color: AppColors.white,
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
                                        color: Color(0xFFFFD700),
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
                                color: AppColors.white,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              'Dawn',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.white.withValues(alpha: 0.6),
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
                          color: AppColors.white.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.timer_outlined,
                            color: Color(0xFFFFD700),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'in ',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.white.withValues(alpha: 0.7),
                            ),
                          ),
                          Text(
                            formattedCountdown,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 20,
                              color: const Color(0xFFFFD700),
                              fontWeight: FontWeight.w900,
                              shadows: [
                                Shadow(
                                  color: const Color(0xFFFFD700)
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
                iconColor: const Color(0xFF10B981),
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
                iconColor: const Color(0xFF7C3AED),
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
                      color: AppColors.accent,
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
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: AppRadius.cardRadius,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.notifications_active_rounded,
                        color: AppColors.primary,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Manage Prayer Notifications',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.primary,
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
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
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
                    color: AppColors.textTertiary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Calculation Method',
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.textPrimary,
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
                        isSelected ? AppColors.primary : AppColors.textTertiary,
                  ),
                  title: Text(
                    _getMethodName(method),
                    style: AppTextStyles.titleSmall.copyWith(
                      color: AppColors.textPrimary,
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
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
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
                    color: AppColors.textTertiary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Location Settings',
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.textPrimary,
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
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.my_location_rounded,
                    color: AppColors.primary,
                  ),
                ),
                title: Text(
                  'Auto-detect Location',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  'Use GPS to detect your location',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
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
              const Divider(color: AppColors.borderSubtle),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mosque_rounded,
                    color: AppColors.accent,
                  ),
                ),
                title: Text(
                  'Reset to Makkah',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  'Use Makkah as default location',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
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
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
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
                        color: AppColors.textTertiary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Prayer Notifications',
                    style: AppTextStyles.titleLarge.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Toggle azan alerts for each prayer',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ..._notifications.entries.map((entry) {
                    return SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        _getName(entry.key),
                        style: AppTextStyles.titleSmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        _getArabicName(entry.key),
                        style: const TextStyle(
                          fontFamily: 'Amiri',
                          color: Color(0xFFFFD700),
                          fontSize: 13,
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                      value: entry.value,
                      activeThumbColor: _getColor(entry.key),
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
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
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
                    color: AppColors.textTertiary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Prayer Settings',
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 20),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Enable Adhan',
                    style: TextStyle(color: AppColors.textPrimary)),
                subtitle: const Text('Play adhan sound',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                value: settings.enableAdhan,
                activeThumbColor: AppColors.primary,
                onChanged: (v) async {
                  await ref
                      .read(prayerSettingsProvider.notifier)
                      .toggleAdhan(v);
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Show Sunrise',
                    style: TextStyle(color: AppColors.textPrimary)),
                subtitle: const Text('Display sunrise in schedule',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                value: settings.showSunrise,
                activeThumbColor: AppColors.primary,
                onChanged: (v) async {
                  await ref
                      .read(prayerSettingsProvider.notifier)
                      .toggleSunrise(v);
                },
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('24-Hour Format',
                    style: TextStyle(color: AppColors.textPrimary)),
                subtitle: const Text('Use 24-hour time',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
                value: settings.use24HourFormat,
                activeThumbColor: AppColors.primary,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.cardRadius,
          border: Border.all(color: AppColors.borderSubtle),
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
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
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

  Widget _buildPrayerList(
    DailyPrayerTimes? dailyTimes,
    NextPrayerInfo? nextInfo,
  ) {
    final nextType = nextInfo?.prayer.type;

    final prayers = [
      _makePrayer(
        PrayerType.fajr,
        dailyTimes?.fajr.formattedTime ?? '04:21 AM',
        nextType == PrayerType.fajr,
      ),
      _makePrayer(
        PrayerType.sunrise,
        dailyTimes?.sunrise.formattedTime ?? '05:38 AM',
        false,
      ),
      _makePrayer(
        PrayerType.dhuhr,
        dailyTimes?.dhuhr.formattedTime ?? '12:00 PM',
        nextType == PrayerType.dhuhr,
      ),
      _makePrayer(
        PrayerType.asr,
        dailyTimes?.asr.formattedTime ?? '03:21 PM',
        nextType == PrayerType.asr,
      ),
      _makePrayer(
        PrayerType.maghrib,
        dailyTimes?.maghrib.formattedTime ?? '06:22 PM',
        nextType == PrayerType.maghrib,
      ),
      _makePrayer(
        PrayerType.isha,
        dailyTimes?.isha.formattedTime ?? '07:34 PM',
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
        return const Color(0xFF3B82F6);
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
