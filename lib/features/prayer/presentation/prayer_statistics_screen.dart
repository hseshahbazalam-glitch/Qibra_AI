// lib/features/prayer/presentation/prayer_statistics_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:qibra_ai/core/constants/app_constants.dart';
import 'package:qibra_ai/core/design_system/qibra_colors.dart';
import '../../../core/design_system/qibra_navy.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';

import '../data/models/prayer_models.dart';
import '../providers/prayer_provider.dart';

enum StatsPeriod { thisWeek, thisMonth, allTime }

class PrayerStatisticsScreen extends ConsumerStatefulWidget {
  const PrayerStatisticsScreen({super.key});

  @override
  ConsumerState<PrayerStatisticsScreen> createState() =>
      _PrayerStatisticsScreenState();
}

class _PrayerStatisticsScreenState
    extends ConsumerState<PrayerStatisticsScreen> {
  StatsPeriod _selectedPeriod = StatsPeriod.thisWeek;

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    final records = ref.watch(prayerRecordsProvider);
    final lifetime = ref.watch(prayerStatisticsProvider);
    final filtered = _recordsForPeriod(records);
    final periodStats = _statsFrom(filtered);
    final weekly = _weeklyCounts(records);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverAppBar(
              expandedHeight: 80,
              pinned: true,
              backgroundColor: colors.background,
              elevation: 0,
              leading: IconButton(
                icon: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.border),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 18,
                    color: colors.textPrimary,
                  ),
                ),
                onPressed: () {
                  if (context.canPop()) {
                    context.pop();
                  } else {
                    context.go(AppRoutes.prayerSchedule);
                  }
                },
              ),
              centerTitle: true,
              title: Text(
                'Prayer Statistics',
                style: AppTextStyles.titleLarge.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: _buildPeriodSelector(),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _buildCompletionCard(periodStats),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.check_circle_rounded,
                        label: 'Prayed',
                        value: '${periodStats.prayedCount}',
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.mosque_rounded,
                        label: 'In mosque',
                        value: '${periodStats.inMosqueCount}',
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildStatCard(
                        icon: Icons.cancel_rounded,
                        label: 'Missed',
                        value: '${periodStats.missedCount}',
                        color: QibraNavy.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _buildStreakCard(lifetime),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _buildWeeklyChart(weekly),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: _buildAchievementsCard(lifetime),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  List<PrayerRecord> _recordsForPeriod(List<PrayerRecord> records) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (_selectedPeriod) {
      case StatsPeriod.thisWeek:
        final start = today.subtract(const Duration(days: 6));
        return records.where((record) => !record.date.isBefore(start)).toList();
      case StatsPeriod.thisMonth:
        return records
            .where((record) =>
                record.date.year == now.year && record.date.month == now.month)
            .toList();
      case StatsPeriod.allTime:
        return records;
    }
  }

  PrayerStatistics _statsFrom(List<PrayerRecord> records) {
    if (records.isEmpty) return PrayerStatistics.empty();
    var prayed = 0;
    var missed = 0;
    var inMosque = 0;
    final byType = <PrayerType, int>{};
    for (final record in records) {
      switch (record.status) {
        case PrayerStatus.prayed:
        case PrayerStatus.makeup:
          prayed++;
          byType[record.type] = (byType[record.type] ?? 0) + 1;
        case PrayerStatus.prayedInMosque:
          prayed++;
          inMosque++;
          byType[record.type] = (byType[record.type] ?? 0) + 1;
        case PrayerStatus.missed:
          missed++;
        case PrayerStatus.pending:
          break;
      }
    }
    return PrayerStatistics(
      totalPrayers: records.length,
      prayedCount: prayed,
      missedCount: missed,
      inMosqueCount: inMosque,
      currentStreak: 0,
      longestStreak: 0,
      byType: byType,
    );
  }

  List<_DayCount> _weeklyCounts(List<PrayerRecord> records) {
    final now = DateTime.now();
    return List.generate(7, (index) {
      final day = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: 6 - index));
      final count = records.where((record) {
        return record.date.year == day.year &&
            record.date.month == day.month &&
            record.date.day == day.day &&
            (record.status == PrayerStatus.prayed ||
                record.status == PrayerStatus.prayedInMosque ||
                record.status == PrayerStatus.makeup);
      }).length;
      const labels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return _DayCount(label: labels[day.weekday - 1], count: count);
    });
  }

  Widget _buildPeriodSelector() {
    final colors = QibraColors.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.pillRadius,
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          _buildPeriodTab('This Week', StatsPeriod.thisWeek),
          _buildPeriodTab('This Month', StatsPeriod.thisMonth),
          _buildPeriodTab('All Time', StatsPeriod.allTime),
        ],
      ),
    );
  }

  Widget _buildPeriodTab(String label, StatsPeriod period) {
    final colors = QibraColors.of(context);
    final isSelected = _selectedPeriod == period;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedPeriod = period);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            gradient: isSelected ? AppGradients.emerald : null,
            borderRadius: AppRadius.pillRadius,
          ),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: isSelected ? colors.onPrimary : colors.textSecondary,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompletionCard(PrayerStatistics stats) {
    final colors = QibraColors.of(context);
    final percentage = stats.consistencyPercentage.round();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.cardRadiusLarge,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prayer Completion',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          stats.totalPrayers == 0 ? '—' : '$percentage',
                          style: AppTextStyles.displayLarge.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w900,
                            height: 1.0,
                            fontSize: 48,
                          ),
                        ),
                        if (stats.totalPrayers > 0)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text(
                              '%',
                              style: AppTextStyles.titleLarge.copyWith(
                                color: colors.primary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            stats.totalPrayers == 0
                ? 'Mark prayers on the Prayer tab to see completion here.'
                : '${stats.prayedCount} of ${stats.totalPrayers} recorded prayers were marked prayed.',
            style: AppTextStyles.labelSmall.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: stats.totalPrayers == 0 ? 0 : percentage / 100,
              backgroundColor: colors.primary.withValues(alpha: 0.15),
              valueColor:
                  AlwaysStoppedAnimation<Color>(colors.primary),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final colors = QibraColors.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.headlineSmall.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
              fontSize: 24,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 9,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard(PrayerStatistics stats) {
    final colors = QibraColors.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: QibraNavy.emeraldDeep,
        borderRadius: AppRadius.cardRadiusLarge,
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: colors.onPrimary.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.local_fire_department_rounded,
              color: colors.onPrimary,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Prayer Streak',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: colors.onPrimary.withValues(alpha: 0.85),
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${stats.currentStreak}',
                      style: AppTextStyles.displayMedium.copyWith(
                        color: colors.onPrimary,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        stats.currentStreak == 1 ? 'Day' : 'Days',
                        style: AppTextStyles.titleSmall.copyWith(
                          color: colors.onPrimary.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              Text(
                'Best',
                style: AppTextStyles.labelSmall.copyWith(
                  color: colors.onPrimary.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
              ),
              Text(
                '${stats.longestStreak} Days',
                style: AppTextStyles.titleSmall.copyWith(
                  color: colors.onPrimary,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyChart(List<_DayCount> weekly) {
    final colors = QibraColors.of(context);
    const goal = 5.0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.cardRadiusLarge,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Last 7 days',
            style: AppTextStyles.titleSmall.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                for (var i = 0; i < weekly.length; i++)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${weekly[i].count}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: i == weekly.length - 1
                              ? QibraNavy.gold
                              : colors.textSecondary,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 24,
                        height: (100 * (weekly[i].count / goal)).clamp(4, 100),
                        decoration: BoxDecoration(
                          color: i == weekly.length - 1
                              ? QibraNavy.gold
                              : colors.primary,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(6),
                            topRight: Radius.circular(6),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final day in weekly)
                SizedBox(
                  width: 30,
                  child: Text(
                    day.label,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: colors.textTertiary,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsCard(PrayerStatistics stats) {
    final colors = QibraColors.of(context);
    final badges = [
      _Badge('7 Days', stats.longestStreak >= 7),
      _Badge('30 Days', stats.longestStreak >= 30),
      _Badge('First prayer', stats.prayedCount > 0),
      _Badge('100 Days', stats.longestStreak >= 100),
    ];
    final unlocked = badges.where((badge) => badge.unlocked).length;
    return Container(
      padding: const EdgeInsets.all(16),
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
                'Milestones',
                style: AppTextStyles.titleSmall.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              Text(
                '$unlocked/${badges.length}',
                style: AppTextStyles.labelSmall.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (var i = 0; i < badges.length; i++) ...[
                if (i > 0) const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      Icon(
                        badges[i].unlocked
                            ? Icons.emoji_events_rounded
                            : Icons.lock_outline_rounded,
                        color: badges[i].unlocked
                            ? QibraNavy.gold
                            : colors.textTertiary,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        badges[i].label,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: badges[i].unlocked
                              ? colors.textPrimary
                              : colors.textTertiary,
                          fontWeight: FontWeight.w700,
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _DayCount {
  const _DayCount({required this.label, required this.count});
  final String label;
  final int count;
}

class _Badge {
  const _Badge(this.label, this.unlocked);
  final String label;
  final bool unlocked;
}
