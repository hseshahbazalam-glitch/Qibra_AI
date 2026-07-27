// lib/features/prayer/presentation/widgets/prayer_quick_action.dart
// Circular quick action buttons row

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qibra_ai/core/design_system/app_colors.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';

class QuickActionItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const QuickActionItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}

class PrayerQuickActionsRow extends StatelessWidget {
  final List<QuickActionItem> actions;

  const PrayerQuickActionsRow({
    super.key,
    required this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: actions.map((action) {
          return _buildActionButton(action);
        }).toList(),
      ),
    );
  }

  Widget _buildActionButton(QuickActionItem action) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        action.onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Circular icon container
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  action.color.withValues(alpha: 0.25),
                  action.color.withValues(alpha: 0.10),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: action.color.withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: action.color.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              action.icon,
              color: action.color,
              size: 24,
            ),
          ),

          const SizedBox(height: 6),

          // Label
          Text(
            action.label,
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
