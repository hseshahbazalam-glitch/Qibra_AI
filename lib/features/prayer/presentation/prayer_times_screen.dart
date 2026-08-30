// lib/features/prayer/presentation/prayer_times_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hijri/hijri_calendar.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/qibra_colors.dart';
import '../../../shared/widgets/qibra_ui.dart';
import '../data/models/prayer_models.dart';
import '../providers/prayer_provider.dart';

class PrayerTimesScreen extends ConsumerWidget {
  const PrayerTimesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = QibraColors.of(context);
    final nextPrayer = ref.watch(nextPrayerProvider);
    final currentPrayer = ref.watch(currentPrayerProvider);
    final dailyTimes = ref.watch(dailyPrayerTimesProvider);
    final location = ref.watch(locationProvider);
    final settings = ref.watch(prayerSettingsProvider);
    final records = ref.watch(prayerRecordsProvider);
    final hijri = HijriCalendar.now();

    return QibraPage(
      title: 'Prayer',
      subtitle: '${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear} AH',
      actions: [
        QibraIconButton(
          icon: Icons.notifications_none_rounded,
          tooltip: 'Notifications',
          onTap: () => context.push('/settings/notifications'),
        ),
        QibraIconButton(
          icon: Icons.explore_outlined,
          tooltip: 'Qibla',
          onTap: () => context.go(AppRoutes.qibla),
        ),
      ],
      child: RefreshIndicator(
          color: colors.primary,
          onRefresh: () async {
            await ref.read(locationProvider.notifier).fetchCurrentLocation();
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
            children: [
              QibraCard(
                filled: true,
                child: nextPrayer == null
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Next prayer',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: colors.onPrimary.withValues(alpha: 0.75),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '—',
                            style: AppTextStyles.displaySmall.copyWith(
                              color: colors.onPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            location.hasLocation
                                ? 'Times will appear once they can be calculated.'
                                : 'Enable location to calculate prayer times.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: colors.onPrimary.withValues(alpha: 0.8),
                            ),
                          ),
                          if (!location.hasLocation) ...[
                            const SizedBox(height: 12),
                            FilledButton.tonal(
                              onPressed: () {
                                ref
                                    .read(locationProvider.notifier)
                                    .fetchCurrentLocation();
                              },
                              child: const Text('Use current location'),
                            ),
                          ],
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Next prayer',
                            style: AppTextStyles.labelMedium.copyWith(
                              color: colors.onPrimary.withValues(alpha: 0.75),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            nextPrayer.prayer.type.name,
                            style: AppTextStyles.displaySmall.copyWith(
                              color: colors.onPrimary,
                            ),
                          ),
                          Text(
                            nextPrayer.prayer.type.arabicName,
                            style: AppArabicStyles.quranMedium.copyWith(
                              color: colors.onPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Text(
                                nextPrayer.prayer.formattedTime,
                                style: AppTextStyles.titleLarge.copyWith(
                                  color: colors.onPrimary,
                                ),
                              ),
                              const Spacer(),
                              Text(
                                nextPrayer.formattedCountdown,
                                style: AppTextStyles.titleMedium.copyWith(
                                  color: colors.onPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 12),
              QibraCard(
                child: Row(
                  children: [
                    Icon(Icons.place_outlined, color: colors.primary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        location.location?.displayName ?? 'Location not set',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ref
                            .read(locationProvider.notifier)
                            .fetchCurrentLocation();
                      },
                      child: const Text('Update'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              QibraSectionHeader(
                title: "Today's times",
                actionLabel: settings.calculationMethod.shortName,
                onAction: () => _showMethodSheet(context, ref),
              ),
              if (dailyTimes == null)
                const QibraEmptyState(
                  icon: Icons.access_time,
                  title: 'Times unavailable',
                  message: 'Prayer times appear after a location is set.',
                )
              else
                QibraCard(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    children: [
                      for (final prayer in dailyTimes.prayers)
                        if (prayer.type.isObligatory || settings.showSunrise)
                          _PrayerRow(
                            prayer: prayer,
                            isNext: nextPrayer?.prayer.type == prayer.type,
                            isCurrent: currentPrayer?.type == prayer.type,
                            record: _recordFor(records, prayer.type),
                            onToggle: () => _togglePrayer(ref, prayer.type),
                          ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              QibraCard(
                child: SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    'Adhan notifications',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    settings.enableAdhan
                        ? 'Azan alerts are on'
                        : 'Azan alerts are off',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  value: settings.enableAdhan && settings.enableNotifications,
                  activeThumbColor: colors.primary,
                  onChanged: (value) {
                    ref
                        .read(prayerSettingsProvider.notifier)
                        .toggleNotifications(value);
                    ref.read(prayerSettingsProvider.notifier).toggleAdhan(value);
                  },
                ),
              ),
              const SizedBox(height: 24),
              const QibraSectionHeader(title: 'Also in Prayer'),
              QibraCard(
                child: Row(
                  children: [
                    QibraSoftButton(
                      label: 'Schedule',
                      icon: Icons.calendar_view_day_outlined,
                      onTap: () => context.push(AppRoutes.prayerSchedule),
                    ),
                    QibraSoftButton(
                      label: 'Statistics',
                      icon: Icons.bar_chart_rounded,
                      onTap: () => context.push(AppRoutes.prayerStatistics),
                    ),
                    QibraSoftButton(
                      label: 'Tahajjud',
                      icon: Icons.nights_stay_outlined,
                      onTap: () => context.push(AppRoutes.tahajjud),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
    );
  }

  PrayerRecord? _recordFor(List<PrayerRecord> records, PrayerType type) {
    final now = DateTime.now();
    try {
      return records.firstWhere(
        (record) =>
            record.type == type &&
            record.date.year == now.year &&
            record.date.month == now.month &&
            record.date.day == now.day,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _togglePrayer(WidgetRef ref, PrayerType type) async {
    HapticFeedback.selectionClick();
    final existing = _recordFor(ref.read(prayerRecordsProvider), type);
    final nextStatus = existing?.status == PrayerStatus.prayed
        ? PrayerStatus.pending
        : PrayerStatus.prayed;
    await ref.read(prayerRecordsProvider.notifier).markPrayer(
          date: DateTime.now(),
          type: type,
          status: nextStatus,
        );
  }

  void _showMethodSheet(BuildContext context, WidgetRef ref) {
    final colors = QibraColors.of(context);
    final current = ref.read(prayerSettingsProvider);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 24),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Calculation method',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
              for (final method in CalculationMethod.values)
                RadioListTile<CalculationMethod>(
                  value: method,
                  groupValue: current.calculationMethod,
                  activeColor: colors.primary,
                  title: Text(method.fullName),
                  subtitle: Text(method.description),
                  onChanged: (value) {
                    if (value == null) return;
                    ref
                        .read(prayerSettingsProvider.notifier)
                        .setCalculationMethod(value);
                    Navigator.pop(sheetContext);
                  },
                ),
              const Divider(),
              SwitchListTile.adaptive(
                title: const Text('Hanafi Asr'),
                value: current.asrMethod == AsrMethod.hanafi,
                activeThumbColor: colors.primary,
                onChanged: (value) {
                  ref.read(prayerSettingsProvider.notifier).setAsrMethod(
                        value ? AsrMethod.hanafi : AsrMethod.standard,
                      );
                  Navigator.pop(sheetContext);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PrayerRow extends StatelessWidget {
  const _PrayerRow({
    required this.prayer,
    required this.isNext,
    this.isCurrent = false,
    required this.record,
    required this.onToggle,
  });

  final PrayerTime prayer;
  final bool isNext;
  final bool isCurrent;
  final PrayerRecord? record;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    final prayed = record?.status == PrayerStatus.prayed ||
        record?.status == PrayerStatus.prayedInMosque ||
        record?.status == PrayerStatus.makeup;

    return ListTile(
      onTap: onToggle,
      leading: Icon(
        prayer.type.icon,
        color: isNext ? colors.primary : colors.textSecondary,
      ),
      title: Row(
        children: [
          Text(
            prayer.type.name,
            style: AppTextStyles.titleSmall.copyWith(
              color: colors.textPrimary,
              fontWeight: isNext ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
          if (isNext) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Next',
                style: AppTextStyles.labelSmall.copyWith(color: colors.primary),
              ),
            ),
          ],
        ],
      ),
      subtitle: Text(
        prayer.type.arabicName,
        style: AppArabicStyles.quranSmall.copyWith(
          color: colors.textSecondary,
          fontSize: 14,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            prayer.formattedTime,
            style: AppTextStyles.titleSmall.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(width: 10),
          Icon(
            prayed ? Icons.check_circle_rounded : Icons.circle_outlined,
            color: prayed ? colors.primary : colors.textTertiary,
          ),
        ],
      ),
    );
  }
}
