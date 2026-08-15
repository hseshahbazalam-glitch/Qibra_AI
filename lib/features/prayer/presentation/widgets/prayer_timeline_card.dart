import 'package:flutter/material.dart';
import 'package:qibra_ai/core/design_system/app_colors.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';

class PrayerTimelineItemData {
  const PrayerTimelineItemData({
    required this.label,
    required this.arabicLabel,
    required this.time,
    required this.icon,
    required this.color,
    this.isNext = false,
  });

  final String label;
  final String arabicLabel;
  final String time;
  final IconData icon;
  final Color color;
  final bool isNext;
}

class PrayerTimelineCard extends StatelessWidget {
  const PrayerTimelineCard({
    super.key,
    required this.items,
    required this.onViewAll,
  });

  final List<PrayerTimelineItemData> items;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadiusLarge,
        border: Border.all(
          color: AppColors.borderSubtle,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.timelapse_rounded,
                color: Color(0xFF00E676),
                size: 17,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  "TODAY'S PRAYER TIMES",
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
              TextButton(
                onPressed: onViewAll,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF00E676),
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                ),
                child: const Text('View all'),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ...items.map(_buildPrayerTile),
        ],
      ),
    );
  }

  Widget _buildPrayerTile(PrayerTimelineItemData item) {
    return Container(
      margin: const EdgeInsets.only(top: 7),
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: item.isNext
            ? item.color.withValues(alpha: 0.12)
            : AppColors.background.withValues(alpha: 0.55),
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color: item.isNext
              ? item.color.withValues(alpha: 0.62)
              : AppColors.borderSubtle,
          width: item.isNext ? 1.3 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(
              item.icon,
              color: item.color,
              size: 17,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        item.label,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (item.isNext) ...[
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: item.color.withValues(alpha: 0.15),
                          borderRadius: AppRadius.pillRadius,
                        ),
                        child: Text(
                          'NEXT',
                          style: AppTextStyles.labelXSmall.copyWith(
                            color: item.color,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  item.arabicLabel,
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 13,
                    color: item.color,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            item.time,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
