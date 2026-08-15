import 'package:flutter/material.dart';
import 'package:qibra_ai/features/prayer/data/models/prayer_models.dart';
import 'package:qibra_ai/features/prayer/presentation/widgets/prayer_insight_cards.dart';
import 'package:qibra_ai/features/prayer/presentation/widgets/prayer_timeline_card.dart';

class PrayerDashboardSection extends StatelessWidget {
  const PrayerDashboardSection({
    super.key,
    required this.items,
    required this.streakDays,
    required this.weekCompleted,
    required this.ishaTime,
    required this.completedToday,
    required this.onViewSchedule,
    required this.onTahajjud,
    required this.onStatistics,
  });

  final List<PrayerTimelineItemData> items;
  final int streakDays;
  final int weekCompleted;
  final String ishaTime;
  final int completedToday;
  final VoidCallback onViewSchedule;
  final VoidCallback onTahajjud;
  final VoidCallback onStatistics;

  @override
  Widget build(BuildContext context) {
    final timeline =
        PrayerTimelineCard(items: items, onViewAll: onViewSchedule);
    final insights = Column(
      children: [
        PrayerInsightCards.tahajjud(startsIn: ishaTime, onTap: onTahajjud),
        const SizedBox(height: 12),
        PrayerInsightCards.streak(
          days: streakDays,
          completed: weekCompleted.clamp(0, 7).toInt(),
          onTap: onStatistics,
        ),
        const SizedBox(height: 12),
        PrayerInsightCards.progress(
            completed: completedToday.clamp(0, 5).toInt(), onTap: onStatistics),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 390) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 54, child: timeline),
              const SizedBox(width: 12),
              Expanded(flex: 46, child: insights),
            ],
          );
        }

        return Column(
          children: [
            timeline,
            const SizedBox(height: 16),
            insights,
          ],
        );
      },
    );
  }
}
