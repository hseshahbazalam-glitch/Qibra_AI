// lib/features/prayer/presentation/widgets/prayer_hero_card.dart
// Premium Prayer Hero Card with mountain background

import 'package:flutter/material.dart';
import '../../../../shared/widgets/media/safe_image.dart';
import 'package:qibra_ai/core/design_system/qibra_colors.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';

class PrayerHeroCard extends StatelessWidget {
  final String prayerName;
  final String prayerNameArabic;
  final String countdown;
  final String? temperature;
  final String? qiblaDirection;
  final String? gregorianDate;
  final String? locationName;
  final VoidCallback? onTap;

  const PrayerHeroCard({
    super.key,
    required this.prayerName,
    required this.prayerNameArabic,
    required this.countdown,
    this.temperature,
    this.qiblaDirection,
    this.gregorianDate,
    this.locationName,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    final safeCountdown = countdown.split(':');
    final hours = safeCountdown.isNotEmpty ? safeCountdown[0] : '00';
    final minutes = safeCountdown.length > 1 ? safeCountdown[1] : '00';
    final seconds = safeCountdown.length > 2 ? safeCountdown[2] : '00';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 286,
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        decoration: BoxDecoration(
          borderRadius: AppRadius.cardRadiusLarge,
          boxShadow: [
            BoxShadow(
              color: colors.primary.withValues(alpha: 0.28),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: AppRadius.cardRadiusLarge,
          child: Stack(
            fit: StackFit.expand,
            children: [
              SafeImage(
                assetPath: 'assets/images/hero/mosque_night.png',
                fit: BoxFit.cover,
                fallback: SafeImageFallback.mosque,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colors.primary.withValues(alpha: 0.28),
                      colors.primary.withValues(alpha: 0.88),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 14,
                left: 14,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_on_rounded,
                        color: colors.primary, size: 16),
                    const SizedBox(width: 4),
                    SizedBox(
                      width: 118,
                      child: Text(
                        locationName ?? 'Location unavailable',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 14,
                right: 18,
                child: Icon(Icons.nightlight_round,
                    color: colors.accent, size: 30),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 53, 18, 14),
                child: Column(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('NEXT PRAYER',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: colors.primary,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.1,
                                    )),
                                const SizedBox(height: 7),
                                Text(prayerName,
                                    style: TextStyle(
                                      color: colors.textPrimary,
                                      fontSize: 34,
                                      fontWeight: FontWeight.w900,
                                      height: 1,
                                    )),
                                Text(prayerNameArabic,
                                    textDirection: TextDirection.rtl,
                                    style: TextStyle(
                                      color: colors.primary,
                                      fontFamily: 'Amiri',
                                      fontSize: 19,
                                      fontWeight: FontWeight.w700,
                                    )),
                                const SizedBox(height: 12),
                                Text('Starts in',
                                    style: AppTextStyles.labelSmall.copyWith(
                                      color: colors.textPrimary.withValues(alpha: 0.6),
                                    )),
                                const SizedBox(height: 3),
                                Text('$hours : $minutes : $seconds',
                                    style: TextStyle(
                                      color: colors.textPrimary,
                                      fontFamily: 'monospace',
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                    )),
                                Text('Hrs       Mins      Secs',
                                    style: AppTextStyles.labelXSmall.copyWith(
                                      color: colors.textPrimary.withValues(alpha: 0.5),
                                    )),
                              ],
                            ),
                          ),
                          _PrayerCountdownRing(countdown: countdown),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                            child: _buildInfoChip(
                          icon: Icons.calendar_month_rounded,
                          label: gregorianDate ?? 'Today',
                          iconColor: colors.primary,
                        )),
                        const SizedBox(width: 7),
                        Expanded(
                            child: _buildInfoChip(
                          icon: Icons.wb_sunny_rounded,
                          label: temperature ?? 'Weather unavailable',
                          iconColor: colors.accent,
                        )),
                        const SizedBox(width: 7),
                        Expanded(
                            child: _buildInfoChip(
                          icon: Icons.explore_rounded,
                          label: qiblaDirection ?? 'Qibla',
                          iconColor: colors.primary,
                        )),
                      ],
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

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: colors.onPrimary.withValues(alpha: 0.1),
        borderRadius: AppRadius.buttonRadius,
        border: Border.all(
          color: colors.onPrimary.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 14),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: colors.onPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrayerCountdownRing extends StatelessWidget {
  const _PrayerCountdownRing({required this.countdown});

  final String countdown;

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    final parts = countdown.split(':').map(int.tryParse).toList();
    final hours = parts.isNotEmpty ? (parts[0] ?? 0) : 0;
    final minutes = parts.length > 1 ? (parts[1] ?? 0) : 0;
    final seconds = parts.length > 2 ? (parts[2] ?? 0) : 0;
    final remainingSeconds = hours * 3600 + minutes * 60 + seconds;
    const maxIntervalSeconds = 6 * 3600;
    final progress =
        (1 - remainingSeconds / maxIntervalSeconds).clamp(0.0, 1.0);

    return SizedBox(
      width: 102,
      height: 102,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 6,
              backgroundColor: const Color(0x3348E6A1),
              valueColor: AlwaysStoppedAnimation(colors.primary),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${(progress * 100).round()}%',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  )),
              Text('until prayer',
                  style: AppTextStyles.labelXSmall.copyWith(
                    color: colors.textPrimary.withValues(alpha: 0.55),
                  )),
            ],
          ),
        ],
      ),
    );
  }
}
