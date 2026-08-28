import 'package:flutter/material.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';
import 'package:qibra_ai/core/design_system/qibra_colors.dart';

class PrayerInsightCards {
  PrayerInsightCards._();

  static Widget tahajjud(
      {required String startsIn, required VoidCallback onTap}) {
    return Builder(
      builder: (context) {
        final colors = QibraColors.of(context);
        return _Card(
          onTap: onTap,
          colors: [colors.primary, colors.primarySoft],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.nightlight_round, color: colors.accent),
              const SizedBox(height: 10),
              Text(
                'TAHAJJUD COUNTDOWN',
                style: TextStyle(
                  color: colors.goldText,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Tahajjud',
                style: TextStyle(
                  color: colors.onPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'قيام الليل',
                style: TextStyle(
                  color: colors.goldText,
                  fontFamily: 'Amiri',
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                startsIn,
                style: TextStyle(
                  color: colors.onPrimary,
                  fontFamily: 'monospace',
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Available after Isha',
                style: AppTextStyles.labelXSmall.copyWith(
                  color: colors.onPrimary.withValues(alpha: 0.75),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget streak(
      {required int days, required int completed, required VoidCallback onTap}) {
    return Builder(
      builder: (context) {
        final colors = QibraColors.of(context);
        return _Card(
          onTap: onTap,
          colors: [colors.primary, colors.primarySoft],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.local_fire_department_rounded, color: colors.accent),
                  const SizedBox(width: 6),
                  Text(
                    'PRAYER STREAK',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: colors.goldText,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$days',
                    style: TextStyle(
                      color: colors.onPrimary,
                      fontSize: 27,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    ' days',
                    style: TextStyle(color: colors.onPrimary.withValues(alpha: 0.7)),
                  ),
                ],
              ),
              Text(
                'Keep it up! May Allah accept.',
                style: AppTextStyles.labelXSmall.copyWith(
                  color: colors.onPrimary.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(
                  7,
                  (i) => Icon(
                    i < completed
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                    color: i < completed
                        ? colors.accent
                        : colors.onPrimary.withValues(alpha: 0.35),
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  static Widget progress(
      {required int completed, required VoidCallback onTap}) {
    return Builder(
      builder: (context) {
        final colors = QibraColors.of(context);
        return _Card(
          onTap: onTap,
          colors: [colors.primary, colors.primarySoft],
          child: Row(
            children: [
              SizedBox(
                width: 68,
                height: 68,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: (completed / 5).clamp(0, 1).toDouble(),
                      strokeWidth: 6,
                      color: colors.accent,
                      backgroundColor: colors.onPrimary.withValues(alpha: 0.2),
                    ),
                    Text(
                      '$completed/5',
                      style: TextStyle(
                        color: colors.onPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "TODAY'S PROGRESS",
                      style: AppTextStyles.labelSmall.copyWith(
                        color: colors.goldText,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$completed of 5 prayers completed',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: colors.onPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.colors, required this.child, required this.onTap});
  final List<Color> colors;
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = QibraColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 142),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: colors,
          ),
          borderRadius: AppRadius.cardRadiusLarge,
          border: Border.all(color: theme.border),
        ),
        child: child,
      ),
    );
  }
}
