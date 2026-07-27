// lib/features/prayer/presentation/widgets/schedule_prayer_tile.dart
// Timeline prayer tile with notification bell

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qibra_ai/core/design_system/app_colors.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';

class SchedulePrayerTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String name;
  final String nameArabic;
  final String time;
  final bool isNext;
  final bool notificationEnabled;
  final VoidCallback? onBellTap;

  const SchedulePrayerTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.name,
    required this.nameArabic,
    required this.time,
    this.isNext = false,
    this.notificationEnabled = true,
    this.onBellTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: isNext ? iconColor.withValues(alpha: 0.1) : AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color: isNext
              ? iconColor.withValues(alpha: 0.5)
              : AppColors.borderSubtle,
          width: isNext ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Icon circle
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(
                color: iconColor.withValues(alpha: 0.3),
              ),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),

          // Name + Arabic
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    if (isNext) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: iconColor.withValues(alpha: 0.2),
                          borderRadius: AppRadius.pillRadius,
                        ),
                        child: Text(
                          'NEXT',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: iconColor,
                            fontWeight: FontWeight.w800,
                            fontSize: 8,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  nameArabic,
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 13,
                    color: Color(0xFFFFD700),
                    fontWeight: FontWeight.w600,
                  ),
                  textDirection: TextDirection.rtl,
                ),
              ],
            ),
          ),

          // Time
          Text(
            time,
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),

          const SizedBox(width: 10),

          // Notification bell
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onBellTap?.call();
            },
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: notificationEnabled
                    ? iconColor.withValues(alpha: 0.15)
                    : AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: notificationEnabled
                      ? iconColor.withValues(alpha: 0.3)
                      : AppColors.borderSubtle,
                ),
              ),
              child: Icon(
                notificationEnabled
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_off_outlined,
                color: notificationEnabled ? iconColor : AppColors.textTertiary,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
