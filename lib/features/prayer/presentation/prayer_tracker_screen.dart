// lib/features/prayer/presentation/prayer_tracker_screen.dart

// ============================================================
// QIBRA AI — PRAYER TRACKER SCREEN (v1.0)
// Phase: 9 — Prayer Statistics & History
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_design_system.dart';
import '../../../core/design_system/app_typography.dart';
import '../data/models/prayer_models.dart';
import '../providers/prayer_provider.dart';

class PrayerTrackerScreen extends ConsumerStatefulWidget {
  const PrayerTrackerScreen({super.key});

  @override
  ConsumerState<PrayerTrackerScreen> createState() =>
      _PrayerTrackerScreenState();
}

class _PrayerTrackerScreenState extends ConsumerState<PrayerTrackerScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _animController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _confirmClearAll() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceSheet,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl2),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_rounded, color: AppColors.error),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Clear All Records?',
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          'This will delete all your prayer history. This action cannot be undone.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(prayerRecordsProvider.notifier).clearAll();
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'All records cleared',
                    style:
                        AppTextStyles.bodySmall.copyWith(color: Colors.white),
                  ),
                  backgroundColor: AppColors.error,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
            child: Text(
              'Clear All',
              style: AppTextStyles.labelMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(prayerStatisticsProvider);
    final records = ref.watch(prayerRecordsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withValues(alpha: 0.14),
              AppColors.background,
              AppColors.background,
            ],
            stops: const [0.0, 0.30, 1.0],
          ),
        ),
        child: SafeArea(
          child: records.isEmpty ? _buildEmptyState() : _buildContent(stats),
        ),
      ),
    );
  }

  Widget _buildContent(PrayerStatistics stats) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopBar(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildHeroStats(stats),
                    const SizedBox(height: AppSpacing.lg),
                    _buildStreakCards(stats),
                    const SizedBox(height: AppSpacing.xl),
                    _buildSectionHeader('BY PRAYER TYPE'),
                    const SizedBox(height: AppSpacing.md),
                    _buildByTypeChart(stats),
                    const SizedBox(height: AppSpacing.xl),
                    _buildSectionHeader('LAST 7 DAYS'),
                    const SizedBox(height: AppSpacing.md),
                    _buildWeeklyOverview(),
                    const SizedBox(height: AppSpacing.xl),
                    _buildSectionHeader('MOTIVATION'),
                    const SizedBox(height: AppSpacing.md),
                    _buildMotivationCard(stats),
                    const SizedBox(height: AppSpacing.xl3),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Top Bar ────────────────────────────────────────────────

  Widget _buildTopBar() {
    return Row(
      children: [
        _CircleButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).maybePop();
          },
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'YOUR PROGRESS',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Prayer Tracker',
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        _CircleButton(
          icon: Icons.delete_sweep_rounded,
          onTap: _confirmClearAll,
          color: AppColors.error,
        ),
      ],
    );
  }

  // ── Hero Stats ─────────────────────────────────────────────

  Widget _buildHeroStats(PrayerStatistics stats) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.30),
            AppColors.accent.withValues(alpha: 0.18),
            AppColors.primary.withValues(alpha: 0.14),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl3),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.24),
          width: 1.2,
        ),
      ),
      child: Column(
        children: [
          Text(
            'CONSISTENCY',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                stats.consistencyPercentage.toStringAsFixed(0),
                style: const TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  height: 1.0,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  '%',
                  style: AppTextStyles.headlineSmall.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs + 2,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface.withValues(alpha: 0.40),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: Text(
              stats.consistencyLabel,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.full),
            child: LinearProgressIndicator(
              value: stats.consistencyPercentage / 100,
              minHeight: 10,
              backgroundColor: Colors.black.withValues(alpha: 0.30),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.accent,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Bottom stats
          Row(
            children: [
              _HeroStatItem(
                icon: Icons.check_circle_rounded,
                value: stats.prayedCount.toString(),
                label: 'Prayed',
                color: AppColors.primary,
              ),
              _HeroDivider(),
              _HeroStatItem(
                icon: Icons.mosque_rounded,
                value: stats.inMosqueCount.toString(),
                label: 'In Mosque',
                color: AppColors.accent,
              ),
              _HeroDivider(),
              _HeroStatItem(
                icon: Icons.cancel_rounded,
                value: stats.missedCount.toString(),
                label: 'Missed',
                color: AppColors.error,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Streak Cards ───────────────────────────────────────────

  Widget _buildStreakCards(PrayerStatistics stats) {
    return Row(
      children: [
        Expanded(
          child: _StreakCard(
            icon: Icons.local_fire_department_rounded,
            iconColor: const Color(0xFFFF7043),
            title: 'Current Streak',
            value: stats.currentStreak.toString(),
            unit: 'days',
            gradient: [
              const Color(0xFFFF7043).withValues(alpha: 0.24),
              const Color(0xFFFF7043).withValues(alpha: 0.10),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StreakCard(
            icon: Icons.emoji_events_rounded,
            iconColor: AppColors.accent,
            title: 'Longest Streak',
            value: stats.longestStreak.toString(),
            unit: 'days',
            gradient: [
              AppColors.accent.withValues(alpha: 0.24),
              AppColors.accent.withValues(alpha: 0.10),
            ],
          ),
        ),
      ],
    );
  }

  // ── Section Header ─────────────────────────────────────────

  Widget _buildSectionHeader(String title) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: AppTextStyles.labelLarge.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  // ── By Type Chart ──────────────────────────────────────────

  Widget _buildByTypeChart(PrayerStatistics stats) {
    final maxCount = stats.byType.values.isEmpty
        ? 1
        : stats.byType.values.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.80),
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        children: PrayerType.obligatoryPrayers.map((type) {
          final count = stats.byType[type] ?? 0;
          final percentage = maxCount > 0 ? count / maxCount : 0.0;
          final isLast = type == PrayerType.obligatoryPrayers.last;

          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.md),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: type.color.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(type.icon, color: type.color, size: 16),
                ),
                const SizedBox(width: AppSpacing.md),
                SizedBox(
                  width: 60,
                  child: Text(
                    type.name,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.full),
                      child: LinearProgressIndicator(
                        value: percentage,
                        minHeight: 8,
                        backgroundColor: type.color.withValues(alpha: 0.10),
                        valueColor: AlwaysStoppedAnimation<Color>(type.color),
                      ),
                    ),
                  ),
                ),
                Container(
                  constraints: const BoxConstraints(minWidth: 30),
                  child: Text(
                    count.toString(),
                    textAlign: TextAlign.right,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: type.color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Weekly Overview ────────────────────────────────────────

  Widget _buildWeeklyOverview() {
    final now = DateTime.now();
    final days = <DateTime>[];
    for (int i = 6; i >= 0; i--) {
      days.add(DateTime(now.year, now.month, now.day - i));
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.80),
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.10),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: days.map((day) {
              return _buildDayColumn(day);
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.md),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: AppColors.primary, label: 'Prayed'),
              SizedBox(width: AppSpacing.md),
              _LegendDot(color: AppColors.accent, label: 'Mosque'),
              SizedBox(width: AppSpacing.md),
              _LegendDot(color: AppColors.error, label: 'Missed'),
              SizedBox(width: AppSpacing.md),
              _LegendDot(
                color: AppColors.textTertiary,
                label: 'Pending',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayColumn(DateTime date) {
    final records = ref.watch(prayerRecordsProvider);
    final dayRecords = records.where((r) {
      return r.date.year == date.year &&
          r.date.month == date.month &&
          r.date.day == date.day;
    }).toList();

    final isToday = _isSameDay(date, DateTime.now());
    final weekdayShort = _weekdayShort(date.weekday);

    return Column(
      children: [
        Container(
          width: 36,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: isToday
                ? AppColors.primary.withValues(alpha: 0.20)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Column(
            children: [
              Text(
                weekdayShort,
                style: AppTextStyles.labelSmall.copyWith(
                  color: isToday ? AppColors.primary : AppColors.textSecondary,
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                ),
              ),
              Text(
                date.day.toString(),
                style: AppTextStyles.labelSmall.copyWith(
                  color: isToday ? AppColors.primary : AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Column(
          children: PrayerType.obligatoryPrayers.map((type) {
            PrayerRecord? record;
            try {
              record = dayRecords.firstWhere((r) => r.type == type);
            } catch (_) {
              record = null;
            }

            Color color;
            if (record == null) {
              color = AppColors.textTertiary.withValues(alpha: 0.30);
            } else {
              color = record.status.color;
            }

            return Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Motivation Card ────────────────────────────────────────

  Widget _buildMotivationCard(PrayerStatistics stats) {
    String message;
    String emoji;
    IconData icon;
    Color color;

    if (stats.currentStreak >= 30) {
      message =
          'Masha\'Allah! ${stats.currentStreak} days of consistency!\nMay Allah reward your dedication.';
      emoji = '🌟';
      icon = Icons.emoji_events_rounded;
      color = AppColors.accent;
    } else if (stats.currentStreak >= 7) {
      message =
          'Great job! ${stats.currentStreak} days in a row.\nKeep the momentum going!';
      emoji = '💚';
      icon = Icons.local_fire_department_rounded;
      color = const Color(0xFFFF7043);
    } else if (stats.consistencyPercentage >= 80) {
      message =
          'You\'re doing amazing!\n${stats.consistencyPercentage.toStringAsFixed(0)}% consistency is excellent.';
      emoji = '🎯';
      icon = Icons.check_circle_rounded;
      color = AppColors.primary;
    } else if (stats.consistencyPercentage >= 50) {
      message =
          'Good progress! Keep improving.\nEvery prayer counts, don\'t give up.';
      emoji = '📈';
      icon = Icons.trending_up_rounded;
      color = const Color(0xFF42A5F5);
    } else {
      message =
          'Bismillah, let\'s make today count.\n"Verily, prayer prevents wrongdoing."';
      emoji = '🤲';
      icon = Icons.self_improvement_rounded;
      color = const Color(0xFF7C4DFF);
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.20),
            color.withValues(alpha: 0.06),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        border: Border.all(
          color: color.withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.20),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                emoji,
                style: const TextStyle(fontSize: 28),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Empty State ────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: _buildTopBar(),
        ),
        const Spacer(),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.20),
                        AppColors.primary.withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                  child: Icon(
                    Icons.analytics_rounded,
                    size: 60,
                    color: AppColors.primary.withValues(alpha: 0.80),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'No Prayer Records',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Start marking your daily prayers\nto see your progress here',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).maybePop();
                  },
                  icon: const Icon(Icons.mosque_rounded, size: 20),
                  label: Text(
                    'Go to Prayer Times',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }

  // ── Helpers ────────────────────────────────────────────────

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _weekdayShort(int weekday) {
    return switch (weekday) {
      1 => 'MON',
      2 => 'TUE',
      3 => 'WED',
      4 => 'THU',
      5 => 'FRI',
      6 => 'SAT',
      7 => 'SUN',
      _ => '',
    };
  }
}

// ============================================================
// HERO STAT ITEM
// ============================================================

class _HeroStatItem extends StatelessWidget {
  const _HeroStatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 44,
      color: Colors.white.withValues(alpha: 0.14),
    );
  }
}

// ============================================================
// STREAK CARD
// ============================================================

class _StreakCard extends StatelessWidget {
  const _StreakCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.unit,
    required this.gradient,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String unit;
  final List<Color> gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        border: Border.all(
          color: iconColor.withValues(alpha: 0.24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  height: 1.0,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                unit,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// LEGEND DOT
// ============================================================

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// CIRCLE BUTTON
// ============================================================

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: (color ?? AppColors.primary).withValues(alpha: 0.14),
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// END OF FILE — prayer_tracker_screen.dart
// ============================================================
