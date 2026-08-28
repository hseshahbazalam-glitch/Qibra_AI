// lib/features/prayer/presentation/widgets/night_worship_card.dart
// Night Worship (Tahajjud) + Prayer Streak widgets

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qibra_ai/core/design_system/qibra_colors.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';

// ============================================================
// NIGHT WORSHIP CARD (Tahajjud)
// ============================================================

class NightWorshipCard extends StatelessWidget {
  final String startsIn;
  final String bestTimeText;
  final VoidCallback? onTap;

  const NightWorshipCard({
    super.key,
    required this.startsIn,
    this.bestTimeText = 'Best time: Last third of the night',
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap?.call();
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.backgroundSecondary,
                Color(0xFF312E81),
                colors.backgroundSecondary,
              ],
            ),
            borderRadius: AppRadius.cardRadiusLarge,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF312E81).withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Decorative moon
              Positioned(
                right: -10,
                top: -10,
                child: Icon(
                  Icons.nightlight_round,
                  size: 100,
                  color: colors.accent.withValues(alpha: 0.1),
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: colors.accent.withValues(alpha: 0.2),
                          borderRadius: AppRadius.buttonRadius,
                          border: Border.all(
                            color:
                                colors.accent.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Icon(
                          Icons.nightlight_round,
                          color: colors.accent,
                          size: 14,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'NIGHT WORSHIP',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: colors.goldText,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.0,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tahajjud',
                              style: AppTextStyles.headlineSmall.copyWith(
                                color: colors.onPrimary,
                                fontWeight: FontWeight.w900,
                                fontSize: 22,
                              ),
                            ),
                            Text(
                              'قيام الليل',
                              style: TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: 16,
                                color: colors.goldText,
                                fontWeight: FontWeight.w600,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Starts in',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: colors.onPrimary.withValues(alpha: 0.7),
                              ),
                            ),
                            Text(
                              startsIn,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 20,
                                color: colors.onPrimary,
                                fontWeight: FontWeight.w900,
                                shadows: [
                                  Shadow(
                                    color: colors.goldText
                                        .withValues(alpha: 0.5),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              bestTimeText,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: colors.onPrimary.withValues(alpha: 0.6),
                                fontSize: 10,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Alarm icon
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: colors.accent.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color:
                                colors.accent.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Icon(
                          Icons.alarm_rounded,
                          color: colors.accent,
                          size: 22,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// PRAYER STREAK CARD
// ============================================================

class PrayerStreakCard extends StatelessWidget {
  final int streakDays;
  final int completedDaysThisWeek;
  final VoidCallback? onTap;

  const PrayerStreakCard({
    super.key,
    required this.streakDays,
    required this.completedDaysThisWeek,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap?.call();
        },
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: AppRadius.cardRadiusLarge,
            border: Border.all(
              color: colors.primarySoft.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.primarySoft.withValues(alpha: 0.1),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    Icons.local_fire_department_rounded,
                    color: colors.accent,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'PRAYER STREAK',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: colors.goldText,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$streakDays',
                        style: AppTextStyles.titleLarge.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 2),
                        child: Text(
                          'Days',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Keep it up! May Allah accept.',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: colors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Weekly dots (S M T W T F S)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (index) {
                  const days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
                  final completed = index < completedDaysThisWeek;

                  return Column(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          gradient: completed
                              ? LinearGradient(
                                  colors: [
                                    colors.primarySoft,
                                    colors.primary,
                                  ],
                                )
                              : null,
                          color: completed ? null : colors.surface,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: completed
                                ? colors.primarySoft
                                : colors.border,
                          ),
                        ),
                        child: completed
                            ? Icon(
                                Icons.check_rounded,
                                color: colors.onPrimary,
                                size: 14,
                              )
                            : null,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        days[index],
                        style: AppTextStyles.labelSmall.copyWith(
                          color: completed
                              ? colors.primarySoft
                              : colors.textTertiary,
                          fontWeight: FontWeight.w700,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
