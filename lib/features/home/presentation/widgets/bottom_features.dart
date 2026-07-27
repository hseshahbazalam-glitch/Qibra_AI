// lib/features/home/presentation/widgets/bottom_features.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:qibra_ai/core/constants/app_constants.dart';
import 'package:qibra_ai/core/design_system/app_colors.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';

class _BottomFeature {
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;

  const _BottomFeature({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
  });
}

const List<_BottomFeature> _bottomFeatures = [
  _BottomFeature(
    label: 'Quran',
    subtitle: 'Read & Explore',
    icon: Icons.menu_book_rounded,
    color: AppColors.primary,
    route: AppRoutes.quran,
  ),
  _BottomFeature(
    label: 'Translations',
    subtitle: '50+ languages',
    icon: Icons.translate_rounded,
    color: Color(0xFF0891B2),
    route: AppRoutes.quran,
  ),
  _BottomFeature(
    label: 'Bookmarks',
    subtitle: 'Saved verses',
    icon: Icons.bookmark_rounded,
    color: Color(0xFF7C3AED),
    route: AppRoutes.quran,
  ),
];

class HomeBottomFeatures extends StatelessWidget {
  const HomeBottomFeatures({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: List.generate(_bottomFeatures.length, (index) {
          final feature = _bottomFeatures[index];
          final isLast = index == _bottomFeatures.length - 1;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: isLast ? 0 : AppSpacing.sm),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  context.go(feature.route);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: AppRadius.cardRadius,
                    border: Border.all(
                      color: feature.color.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              feature.color.withValues(alpha: 0.20),
                              feature.color.withValues(alpha: 0.08),
                            ],
                          ),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: feature.color.withValues(alpha: 0.30),
                          ),
                        ),
                        child: Icon(
                          feature.icon,
                          color: feature.color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        feature.label,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        feature.subtitle,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: feature.color,
                          fontWeight: FontWeight.w600,
                          fontSize: 8,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
