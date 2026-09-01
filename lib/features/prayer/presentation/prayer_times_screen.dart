// lib/features/prayer/presentation/prayer_times_screen.dart
// ============================================================
// QIBRA AI — PRAYER (midnight navy rebuild, Stage 2)
// Cinematic night hero with live countdown ring, transparent
// calculation context and a "Why are my times different?"
// explainer grounded in the user's actual settings. No fake
// data; prayer tracking toggles remain local-first.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hijri/hijri_calendar.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/qibra_colors.dart';
import '../../../core/design_system/qibra_navy.dart';
import '../../../core/utils/countdown_format.dart';
import '../../../shared/widgets/qibra_countdown_ring.dart';
import '../../../shared/widgets/qibra_night_sky.dart';
import '../../../shared/widgets/qibra_status.dart';
import '../../../shared/widgets/qibra_ui.dart';
import '../data/models/prayer_models.dart';
import '../providers/prayer_provider.dart';

class PrayerTimesScreen extends ConsumerWidget {
  const PrayerTimesScreen({super.key});

  String _locationLabel(LocationState location) {
    final loc = location.location;
    if (loc == null) return 'Location not set';
    if (loc.city == 'UNKNOWN' || loc.country == 'UNKNOWN') return 'UNKNOWN';
    return loc.displayName;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = QibraColors.of(context);
    final nextPrayer = ref.watch(nextPrayerInfoProvider);
    final currentPrayerName = ref.watch(
      currentPrayerProvider.select((p) => p?.type.name),
    );
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
            // ── Cinematic night hero ────────────────────────────
            QibraNightSkyBackdrop(
              borderRadius: 24,
              child: _PrayerHeroBody(
                nextPrayer: nextPrayer,
                currentPrayerName: currentPrayerName,
                dailyTimes: dailyTimes,
                settings: settings,
                locationLabel: _locationLabel(location),
                hasLocation: location.hasLocation,
                isLoading: location.isLoading,
                onUpdateLocation: () {
                  HapticFeedback.selectionClick();
                  ref
                      .read(locationProvider.notifier)
                      .fetchCurrentLocation();
                },
              ),
            ),
            const SizedBox(height: 24),

            // ── Today's times ────────────────────────────────────
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
                      if (prayer.type.isObligatory)
                        _PrayerRow(
                          prayer: prayer,
                          isNext: nextPrayer?.prayer.type == prayer.type,
                          isCurrent: currentPrayerName == prayer.type.name,
                          record: _recordFor(records, prayer.type),
                          onToggle: () => _togglePrayer(ref, prayer.type),
                        )
                      else if (settings.showSunrise &&
                          prayer.type == PrayerType.sunrise)
                        _SunriseRow(prayer: prayer),
                  ],
                ),
              ),
            const SizedBox(height: 16),

            // ── Adhan notifications ──────────────────────────────
            QibraCard(
              child: SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Adhan notifications',
                  style: AppTextStyles.titleSmall
                      .copyWith(color: colors.textPrimary),
                ),
                subtitle: Text(
                  settings.enableAdhan
                      ? 'Azan alerts are on'
                      : 'Azan alerts are off',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: colors.textSecondary),
                ),
                value:
                    settings.enableAdhan && settings.enableNotifications,
                activeThumbColor: colors.primary,
                onChanged: (value) {
                  ref
                      .read(prayerSettingsProvider.notifier)
                      .toggleNotifications(value);
                  ref
                      .read(prayerSettingsProvider.notifier)
                      .toggleAdhan(value);
                },
              ),
            ),
            const SizedBox(height: 12),

            // ── Calculation transparency ─────────────────────────
            QibraCard(
              onTap: () => _showWhySheet(context, ref),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: QibraNavy.blue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color:
                              QibraNavy.blue.withValues(alpha: 0.35)),
                    ),
                    child: Icon(Icons.help_outline_rounded,
                        color: QibraNavy.blue, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Why is my prayer time different?',
                          style: AppTextStyles.titleSmall.copyWith(
                              color: colors.textPrimary),
                        ),
                        Text(
                          'Method, Asr, high latitude and adjustments — '
                          'see exactly what this app used today.',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                              color: colors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded,
                      color: colors.textTertiary),
                ],
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
                  QibraSoftButton(
                    label: 'Mosques',
                    icon: Icons.mosque,
                    onTap: () => context.push(AppRoutes.mosques),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Tracking helpers (local-first; behavior preserved) ────

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

  // ─── Sheets ─────────────────────────────────────────────────

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
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8),
                child: Text(
                  'Calculation method',
                  style: AppTextStyles.titleMedium
                      .copyWith(color: colors.textPrimary),
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
                subtitle: const Text(
                    'Later Asr time (shadow ratio 2 instead of 1)'),
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

  void _showWhySheet(BuildContext context, WidgetRef ref) {
    final colors = QibraColors.of(context);
    final settings = ref.read(prayerSettingsProvider);
    final location = ref.read(locationProvider).location;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        final adjustments = settings.adjustments.entries
            .map((e) => '${e.key.name} ${e.value > 0 ? '+' : ''}${e.value}m')
            .join(' · ');
        return SafeArea(
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.72,
            minChildSize: 0.4,
            maxChildSize: 0.95,
            builder: (_, controller) {
              return ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Why is my prayer time different?',
                    style: AppTextStyles.titleLarge
                        .copyWith(color: colors.textPrimary),
                  ),
                  const SizedBox(height: 12),
                  _WhyRow(
                    icon: Icons.calculate_outlined,
                    title: 'Calculation method',
                    body:
                        '${settings.calculationMethod.fullName} — '
                        'Fajr angle ${settings.calculationMethod.fajrAngle}°, '
                        'Isha '
                        '${settings.calculationMethod.useIshaInterval ? '${settings.calculationMethod.ishaIntervalMinutes} min after Maghrib' : '${settings.calculationMethod.ishaAngle}°'}.',
                  ),
                  _WhyRow(
                    icon: Icons.shield_outlined,
                    title: 'Asr (madhab) setting',
                    body: settings.asrMethod == AsrMethod.hanafi
                        ? 'Hanafi — shadow ratio 2, so Asr is later.'
                        : 'Standard (Shafi\u2019i/Maliki/Hanbali) — '
                            'shadow ratio 1.',
                  ),
                  _WhyRow(
                    icon: Icons.wb_twilight_rounded,
                    title: 'High-latitude rule',
                    body:
                        'Rule applied when the sun never reaches the Fajr/'
                        'Isha angle: ${settings.highLatitudeMethod.name} '
                        '(none means no correction is applied).',
                  ),
                  _WhyRow(
                    icon: Icons.tune_rounded,
                    title: 'Manual adjustments',
                    body: adjustments.isEmpty
                        ? 'None — times shown are pure calculated values.'
                        : adjustments,
                  ),
                  _WhyRow(
                    icon: Icons.schedule_rounded,
                    title: 'Timezone',
                    body: (location?.timezone != null &&
                            location!.timezone!.isNotEmpty)
                        ? 'Times use ${location.timezone} resolved from your '
                            'location (daylight-saving handled by the '
                            'timezone database).'
                        : 'Device timezone (no city timezone resolved).',
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: QibraNavy.blue.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: QibraNavy.blue.withValues(alpha: 0.35)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded,
                            size: 18, color: QibraNavy.blue),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Mosque calendars round times and follow local '
                            'ijtihad, so a minute or two of difference is '
                            'normal. For your local jamaat schedule, ask '
                            'your mosque.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: colors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _PrayerHeroBody extends ConsumerWidget {
  const _PrayerHeroBody({
    required this.nextPrayer,
    required this.currentPrayerName,
    required this.dailyTimes,
    required this.settings,
    required this.locationLabel,
    required this.hasLocation,
    required this.isLoading,
    required this.onUpdateLocation,
  });

  final NextPrayerInfo? nextPrayer;
  final String? currentPrayerName;
  final DailyPrayerTimes? dailyTimes;
  final PrayerSettings settings;
  final String locationLabel;
  final bool hasLocation;
  final bool isLoading;
  final VoidCallback onUpdateLocation;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only this small hero body subscribes to the 1s tick (P0 pattern);
    // the tab-level ListView rebuilds at minute cadence only.
    final tick = ref.watch(currentTimeProvider.select((a) => a.value));
    final colors = QibraColors.of(context);
    if (isLoading) {
      return QibraStatus.skeleton(height: 148);
    }
    final info = nextPrayer;
    if (info == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Next prayer',
            style: AppTextStyles.labelMedium
                .copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            '—',
            style: AppTextStyles.displaySmall
                .copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            hasLocation
                ? 'Times will appear once they can be calculated.'
                : 'Enable location to calculate prayer times.',
            style:
                AppTextStyles.bodySmall.copyWith(color: colors.textSecondary),
          ),
        ],
      );
    }
    final prayer = info.prayer;
    final remaining =
        prayer.adjustedTime.difference(tick ?? DateTime.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'NEXT PRAYER',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: colors.textSecondary,
                      letterSpacing: 1.8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        prayer.type.name,
                        style: AppTextStyles.headlineLarge
                            .copyWith(color: colors.textPrimary),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        prayer.type.arabicName,
                        style: AppArabicStyles.quranMedium
                            .copyWith(color: colors.textPrimary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'at ${prayer.formattedTime}',
                    style: AppTextStyles.titleSmall
                        .copyWith(color: colors.textSecondary),
                  ),
                  if (currentPrayerName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Current window: $currentPrayerName',
                      style: AppTextStyles.labelSmall
                          .copyWith(color: colors.textTertiary),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Semantics(
              label: 'Countdown to ${prayer.type.name}: '
                  '${formatCountdownCompact(remaining)}',
              child: QibraCountdownRing(
                progress: info.progress,
                size: 108,
                strokeWidth: 8,
                child: Text(
                  formatCountdownCompact(remaining),
                  style: AppTextStyles.titleMedium.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          height: 1,
          color: colors.border.withValues(alpha: 0.7),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _HeroChip(
              icon: Icons.place_outlined,
              label: locationLabel,
              tooltip: 'Tap to update location from GPS',
              onTap: onUpdateLocation,
            ),
            if (dailyTimes != null)
              _HeroChip(
                  icon: Icons.calculate_outlined,
                  label:
                      '${dailyTimes!.method.shortName} · '
                      '${settings.asrMethod == AsrMethod.hanafi ? 'Hanafi' : 'Standard'} Asr'),
            _HeroChip(
              icon: settings.enableNotifications && settings.enableAdhan
                  ? Icons.notifications_outlined
                  : Icons.notifications_off,
              label: settings.enableNotifications && settings.enableAdhan
                  ? 'Adhan alerts on'
                  : 'Adhan alerts off',
            ),
          ],
        ),
      ],
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({
    required this.icon,
    required this.label,
    this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Widget chip = Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? colors.background.withValues(alpha: 0.72)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: colors.textSecondary),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 220),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSmall.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (onTap == null) return chip;
    chip = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: chip,
      ),
    );
    if (tooltip != null) {
      chip = Tooltip(message: tooltip!, child: chip);
    }
    return chip;
  }
}

class _WhyRow extends StatelessWidget {
  const _WhyRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: QibraNavy.blue),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleSmall
                      .copyWith(color: colors.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  body,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SunriseRow extends StatelessWidget {
  const _SunriseRow({required this.prayer});

  final PrayerTime prayer;

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    return ListTile(
      dense: true,
      leading: Icon(prayer.type.icon,
          color: colors.accent.withValues(alpha: 0.85), size: 20),
      title: Text(
        'Sunrise',
        style: AppTextStyles.titleSmall
            .copyWith(color: colors.textSecondary),
      ),
      subtitle: Text(
        'Dhuhr begins after sunrise ends',
        style:
            AppTextStyles.labelSmall.copyWith(color: colors.textTertiary),
      ),
      trailing: Text(
        prayer.formattedTime,
        style: AppTextStyles.titleSmall
            .copyWith(color: colors.textSecondary),
      ),
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

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: isNext ? colors.primary.withValues(alpha: 0.06) : null,
        border: Border.all(
          color:
              isNext ? colors.primary.withValues(alpha: 0.35) : Colors.transparent,
        ),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      child: ListTile(
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Next',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: colors.primary),
                ),
              ),
            ],
            if (isCurrent && !isNext) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Now',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: colors.accent),
                ),
              ),
            ],
          ],
        ),
        subtitle: Text(
          prayer.type.arabicName,
          style: AppArabicStyles.quranSmall
              .copyWith(color: colors.textSecondary, fontSize: 14),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              prayer.formattedTime,
              style: AppTextStyles.titleSmall
                  .copyWith(color: colors.textPrimary),
            ),
            const SizedBox(width: 10),
            Icon(
              prayed ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: prayed ? colors.primary : colors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}
