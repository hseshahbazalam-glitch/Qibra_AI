// lib/features/home/presentation/widgets/daily_progress_section.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:qibra_ai/core/constants/app_constants.dart';
import 'package:qibra_ai/core/design_system/app_colors.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';

class _ProgressStat {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final double progress;
  final String route;

  const _ProgressStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.progress,
    required this.route,
  });
}

const List<_ProgressStat> _stats = [
  _ProgressStat(
    label: 'Prayer',
    value: '4/5',
    icon: Icons.mosque_rounded,
    color: AppColors.primary,
    progress: 0.80,
    route: AppRoutes.prayer,
  ),
  _ProgressStat(
    label: 'Quran',
    value: '20 min',
    icon: Icons.menu_book_rounded,
    color: AppColors.accent,
    progress: 0.66,
    route: AppRoutes.quran,
  ),
  _ProgressStat(
    label: 'Tasbih',
    value: '66/200',
    icon: Icons.grain_rounded,
    color: Color(0xFF7C3AED),
    progress: 0.33,
    route: AppRoutes.tasbih,
  ),
  _ProgressStat(
    label: 'Duas',
    value: '12/40',
    icon: Icons.volunteer_activism_rounded,
    color: Color(0xFFEF4444),
    progress: 0.30,
    route: AppRoutes.dua,
  ),
];

class HomeDailyProgressSection extends StatelessWidget {
  const HomeDailyProgressSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
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
              const SizedBox(width: AppSpacing.sm),
              const Icon(
                Icons.insights_rounded,
                color: AppColors.accent,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                "TODAY'S PROGRESS",
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.accent,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.go(AppRoutes.prayer);
                },
                child: Text(
                  'View All',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: List.generate(_stats.length, (index) {
              final stat = _stats[index];
              final isLast = index == _stats.length - 1;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: isLast ? 0 : AppSpacing.sm),
                  child: _buildTile(context, stat),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildTile(BuildContext context, _ProgressStat stat) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.go(stat.route);
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.cardRadius,
          border: Border.all(color: stat.color.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
              color: stat.color.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(stat.icon, color: stat.color, size: 16),
            const SizedBox(height: 6),
            Text(
              stat.label,
              style: AppTextStyles.labelSmall.copyWith(
                color: stat.color,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              stat.value,
              style: AppTextStyles.titleSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              stat.progress >= 1.0
                  ? 'Completed'
                  : stat.progress >= 0.5
                      ? 'On Track'
                      : 'Daily Goal',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textTertiary,
                fontSize: 8,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: stat.progress.clamp(0.0, 1.0),
                backgroundColor: stat.color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(stat.color),
                minHeight: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
