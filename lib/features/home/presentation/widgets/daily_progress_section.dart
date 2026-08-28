// lib/features/home/presentation/widgets/daily_progress_section.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:qibra_ai/core/constants/app_constants.dart';
import 'package:qibra_ai/core/design_system/qibra_colors.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';

class _ProgressStat {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final double? progress;
  final String caption;
  final String route;

  const _ProgressStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.caption,
    required this.route,
    this.progress,
  });
}

List<_ProgressStat> _statsFor(QibraColors colors) => [
  _ProgressStat(
    label: 'Prayer',
    value: '—',
    icon: Icons.mosque_rounded,
    color: colors.primary,
    caption: 'Unknown',
    route: AppRoutes.prayer,
  ),
  _ProgressStat(
    label: 'Quran',
    value: '—',
    icon: Icons.menu_book_rounded,
    color: colors.accent,
    caption: 'Unknown',
    route: AppRoutes.quran,
  ),
  _ProgressStat(
    label: 'Tasbih',
    value: '—',
    icon: Icons.blur_circular_rounded,
    color: colors.accent,
    caption: 'Unknown',
    route: AppRoutes.tasbih,
  ),
  _ProgressStat(
    label: 'Duas',
    value: '—',
    icon: Icons.volunteer_activism_rounded,
    color: colors.error,
    caption: 'Unknown',
    route: AppRoutes.dua,
  ),
];

/// Left card only: header + 2x2 grid of progress tiles.
/// Meant to be placed inside an Expanded/Row alongside a streak card.
class HomeDailyProgressSection extends StatelessWidget {
  const HomeDailyProgressSection({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.cardRadiusLarge,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "TODAY'S PROGRESS",
                style: AppTextStyles.labelSmall.copyWith(
                  color: colors.textSecondary,
                  fontSize: 10,
                  letterSpacing: 1.0,
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
                    color: colors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildTile(context, _statsFor(colors)[0])),
              const SizedBox(width: 8),
              Expanded(child: _buildTile(context, _statsFor(colors)[1])),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildTile(context, _statsFor(colors)[2])),
              const SizedBox(width: 8),
              Expanded(child: _buildTile(context, _statsFor(colors)[3])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTile(BuildContext context, _ProgressStat stat) {
    final colors = QibraColors.of(context);
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.go(stat.route);
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(stat.icon, color: stat.color, size: 16),
            const SizedBox(height: 4),
            Text(
              stat.label,
              style: TextStyle(
                color: colors.textPrimary.withValues(alpha: 0.85),
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              stat.value,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 3),
            if (stat.progress != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: stat.progress!.clamp(0.0, 1.0),
                  minHeight: 3,
                  backgroundColor: colors.onPrimary.withValues(alpha: 0.10),
                  valueColor: AlwaysStoppedAnimation<Color>(stat.color),
                ),
              )
            else
              Text(
                stat.caption,
                style: TextStyle(
                  color: stat.color,
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
