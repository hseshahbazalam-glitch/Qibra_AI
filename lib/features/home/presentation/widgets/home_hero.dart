// lib/features/home/presentation/widgets/home_hero.dart
// ============================================================
// QIBRA AI — HOME NIGHT HERO
// Command-center hero: greeting, Hijri + location context,
// next prayer with live countdown ring, calculation &
// notification state. No weather (no real source is wired —
// showing invented weather is forbidden). No audio chrome
// (recitation is not bundled).
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hijri/hijri_calendar.dart';

import '../../../../core/design_system/app_typography.dart';
import '../../../../core/design_system/qibra_colors.dart';
import '../../../../core/design_system/qibra_navy.dart';
import '../../../../shared/widgets/qibra_countdown_ring.dart';
import '../../../../shared/widgets/qibra_night_sky.dart';
import '../../../prayer/data/models/prayer_models.dart';
import '../../../prayer/providers/prayer_provider.dart'
    show
        currentPrayerProvider,
        currentTimeProvider,
        nextPrayerInfoProvider;

class HomeNightHero extends StatelessWidget {
  const HomeNightHero({
    super.key,
    required this.name,
    required this.now,
    required this.locationLabel,
    required this.methodShortName,
    required this.notificationsOn,
    required this.onTap,
    this.isLoading = false,
    this.hasLocation = true,
  });

  final String name;
  final DateTime now;
  final String locationLabel;
  final String? methodShortName;
  final bool notificationsOn;
  final VoidCallback onTap;
  final bool isLoading;
  final bool hasLocation;

  String get _greeting {
    final hour = now.hour;
    if (hour < 4) return 'Peaceful night';
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    final hijri = HijriCalendar.now();
    final hijriLabel =
        '${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear} AH';

    return QibraNightSkyBackdrop(
      semanticsLabel: 'Next prayer — open the prayer schedule',
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Greeting ──────────────────────────────────────────
          Text(
            'Assalamu Alaikum',
            style: AppTextStyles.labelMedium.copyWith(
              color: colors.goldText,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: '$_greeting, ',
                  style: AppTextStyles.headlineSmall
                      .copyWith(color: colors.textSecondary),
                ),
                TextSpan(
                  text: name,
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),

          // ── Context chips: location + Hijri date (no weather) ─
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              HomeContextChip(
                icon: Icons.place_outlined,
                label: locationLabel,
              ),
              HomeContextChip(
                icon: Icons.calendar_month,
                label: hijriLabel,
                accent: colors.accent,
              ),
              HomeContextChip(
                icon: notificationsOn
                    ? Icons.notifications_outlined
                    : Icons.notifications_off,
                label: notificationsOn ? 'Adhan alerts on' : 'Alerts off',
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ── Next prayer ───────────────────────────────────────
          _NextPrayerBody(
            methodShortName: methodShortName,
            isLoading: isLoading,
            hasLocation: hasLocation,
          ),
        ],
      ),
    );
  }
}

class _NextPrayerBody extends ConsumerWidget {
  const _NextPrayerBody({
    required this.methodShortName,
    required this.isLoading,
    required this.hasLocation,
  });

  final String? methodShortName;
  final bool isLoading;
  final bool hasLocation;

  static String _fmt(Duration d) {
    if (d.isNegative) return 'Now';
    if (d.inHours >= 1) {
      return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
    }
    if (d.inMinutes >= 1) {
      return '${d.inMinutes}m '
          '${d.inSeconds.remainder(60)}s';
    }
    return '${d.inSeconds}s';
  }

  /// The ONLY Home widget subscribed to the 1-second ticker. Schedule
  /// data comes from the minute-granular provider; the countdown label
  /// is recomputed from the tick locally so only this small body
  /// rebuilds each second.
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = QibraColors.of(context);
    final info = ref.watch(nextPrayerInfoProvider);
    final currentName = ref.watch(
      currentPrayerProvider.select((p) => p?.type.name),
    );
    final tick = ref.watch(currentTimeProvider.select((a) => a.value));
    final divider = Container(
      height: 1,
      color: colors.border.withValues(alpha: 0.7),
    );

    if (isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          divider,
          const SizedBox(height: 14),
          Container(
            height: 66,
            decoration: BoxDecoration(
              color: colors.textSecondary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      );
    }

    if (info == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          divider,
          const SizedBox(height: 12),
          Text(
            'Next prayer',
            style:
                AppTextStyles.labelMedium.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            hasLocation
                ? 'Prayer times are unavailable right now.'
                : 'Set your location to see prayer times.',
            style:
                AppTextStyles.bodySmall.copyWith(color: colors.textSecondary),
          ),
        ],
      );
    }

    final prayer = info.prayer;
    final remaining =
        prayer.adjustedTime.difference(tick ?? DateTime.now());
    final countdownLabel = _fmt(remaining);
    final semanticsLabel =
        'Next prayer ${prayer.type.name} at ${prayer.formattedTime}, '
        'countdown $countdownLabel remaining';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        divider,
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: _PrayerIdentity(
                prayer: prayer,
                currentName: currentName,
                methodShortName: methodShortName,
              ),
            ),
            const SizedBox(width: 12),
            Semantics(
              label: semanticsLabel,
              child: QibraCountdownRing(
                progress: info.progress,
                size: 92,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      countdownLabel,
                      style: AppTextStyles.titleSmall.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      'left',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: colors.textTertiary,
                        fontSize: 9.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: Text(
                'Tap for full prayer schedule',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelSmall
                    .copyWith(color: colors.textTertiary),
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                size: 15, color: colors.textTertiary),
          ],
        ),
      ],
    );
  }
}

class _PrayerIdentity extends StatelessWidget {
  const _PrayerIdentity({
    required this.prayer,
    required this.currentName,
    required this.methodShortName,
  });

  final PrayerTime prayer;
  final String? currentName;
  final String? methodShortName;

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.primary,
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.6),
                    blurRadius: 8,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'NEXT PRAYER',
              style: AppTextStyles.labelSmall.copyWith(
                color: colors.textSecondary,
                letterSpacing: 1.6,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (currentName != null) ...[
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  '· now $currentName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSmall
                      .copyWith(color: colors.textTertiary),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              prayer.type.name,
              style: AppTextStyles.displaySmall.copyWith(
                color: colors.textPrimary,
                height: 1.05,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              prayer.type.arabicName,
              style: AppArabicStyles.quranSmall.copyWith(
                color: colors.goldText,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(Icons.schedule, size: 15, color: colors.textTertiary),
            const SizedBox(width: 4),
            Text(
              prayer.formattedTime,
              style:
                  AppTextStyles.titleMedium.copyWith(color: colors.textPrimary),
            ),
            if (methodShortName != null) ...[
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: QibraNavy.blue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: QibraNavy.blue.withValues(alpha: 0.35),
                  ),
                ),
                child: Text(
                  methodShortName!,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: QibraNavy.blue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class HomeContextChip extends StatelessWidget {
  const HomeContextChip({
    super.key,
    required this.icon,
    required this.label,
    this.accent,
  });

  final IconData icon;
  final String label;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    final tint = accent ?? colors.textSecondary;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: isDark ? 0.05 : 0.6),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: colors.border.withValues(alpha: 0.8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: tint),
          const SizedBox(width: 5),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 170),
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
  }
}
