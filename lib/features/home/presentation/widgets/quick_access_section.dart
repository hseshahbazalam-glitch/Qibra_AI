// lib/features/home/presentation/widgets/quick_access_section.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:qibra_ai/core/constants/app_constants.dart';
import 'package:qibra_ai/core/design_system/app_colors.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';

class _QuickItem {
  final IconData icon;
  final String label;
  final Color color;
  final String route;

  const _QuickItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.route,
  });
}

const List<_QuickItem> _items = [
  _QuickItem(
    icon: Icons.menu_book_rounded,
    label: 'Quran',
    color: AppColors.primary,
    route: AppRoutes.quran,
  ),
  _QuickItem(
    icon: Icons.collections_bookmark_rounded,
    label: 'Hadith',
    color: Color(0xFFB45309),
    route: AppRoutes.hadith,
  ),
  _QuickItem(
    icon: Icons.explore_rounded,
    label: 'Qibla',
    color: Color(0xFF7C3AED),
    route: AppRoutes.qibla,
  ),
  _QuickItem(
    icon: Icons.grain_rounded,
    label: 'Tasbih',
    color: AppColors.accent,
    route: AppRoutes.tasbih,
  ),
  _QuickItem(
    icon: Icons.volunteer_activism_rounded,
    label: 'Duas',
    color: Color(0xFF0891B2),
    route: AppRoutes.dua,
  ),
  _QuickItem(
    icon: Icons.apps_rounded,
    label: 'More',
    color: Color(0xFF6B7280),
    route: AppRoutes.settings,
  ),
];

class HomeQuickAccessSection extends StatelessWidget {
  const HomeQuickAccessSection({super.key});

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
                Icons.grid_view_rounded,
                color: AppColors.accent,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                'QUICK ACCESS',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.accent,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _items.map((item) => _buildIcon(context, item)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildIcon(BuildContext context, _QuickItem item) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        context.go(item.route);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  item.color.withValues(alpha: 0.20),
                  item.color.withValues(alpha: 0.08),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: item.color.withValues(alpha: 0.35),
                width: 1.5,
              ),
            ),
            child: Icon(item.icon, color: item.color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            item.label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
