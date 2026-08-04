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
    icon: Icons.import_contacts_rounded,
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
    icon: Icons.blur_circular_rounded,
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
    icon: Icons.grid_view_rounded,
    label: 'More',
    color: Color(0xFF9CA3AF),
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
              Text(
                'QUICK ACCESS',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Edit',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: const Color(0xFF00E676),
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(Icons.arrow_forward_ios_rounded,
                        color: Color(0xFF00E676), size: 10),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
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
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: item.color.withValues(alpha: 0.30),
                width: 1.2,
              ),
            ),
            child: Icon(item.icon, color: item.color, size: 22),
          ),
          const SizedBox(height: 6),
          Text(
            item.label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
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
