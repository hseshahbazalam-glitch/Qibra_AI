// lib/features/tasbih/presentation/tasbih_screen.dart

// ============================================================
// QIBRA AI — TASBIH PREMIUM SCREEN (v2.0)
// Beautiful counter with stats, achievements, history
// ============================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/a11y/app_a11y.dart';
import '../../../core/design_system/qibra_colors.dart';
import '../../../core/design_system/app_design_system.dart';
import '../../../core/design_system/app_typography.dart';
import '../providers/tasbih_provider.dart';

part 'tasbih_screen.detail.dart';

// ============================================================
// TASBIH SCREEN
// ============================================================

class TasbihScreen extends ConsumerStatefulWidget {
  const TasbihScreen({super.key});

  @override
  ConsumerState<TasbihScreen> createState() => _TasbihScreenState();
}

class _TasbihScreenState extends ConsumerState<TasbihScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _bounceAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  void _onCounterTap() {
    final state = ref.read(tasbihProvider);

    _bounceController.forward().then((_) {
      _bounceController.reverse();
    });

    ref.read(tasbihProvider.notifier).increment();

    if (state.vibrationEnabled) {
      HapticFeedback.mediumImpact();
    }

    if (state.count + 1 == state.target) {
      HapticFeedback.heavyImpact();
      _showCompletionMessage();
    }

    // Check daily goal completion
    if (state.todayCount + 1 == state.dailyGoal) {
      _showDailyGoalMessage();
    }
  }

  void _showCompletionMessage() {
    final colors = QibraColors.of(context);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_rounded,
                color: colors.textPrimary, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'MashaAllah! Target achieved',
              style: AppTextStyles.bodyMedium.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        backgroundColor: colors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        duration: const Duration(seconds: 2),
        margin: const EdgeInsets.all(AppSpacing.lg),
      ),
    );
  }

  void _showDailyGoalMessage() {
    final colors = QibraColors.of(context);
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.emoji_events_rounded,
                color: colors.textPrimary, size: 24),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Daily Goal Complete! Barakallahu feek!',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: colors.accent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(AppSpacing.lg),
      ),
    );
  }

  void _showDhikrSelector() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const _DhikrSelectorSheet(),
    );
  }

  void _showTargetSelector() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _TargetSelectorSheet(),
    );
  }

  void _showDailyGoalSelector() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _DailyGoalSheet(),
    );
  }

  void _showStatistics() {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _StatisticsScreen()),
    );
  }

  void _showHistory() {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _HistoryScreen()),
    );
  }

  void _confirmReset() {
    final colors = QibraColors.of(context);
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        title: Text(
          'Reset Count?',
          style:
              AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Kya aap current count reset karna chahte hain?',
          style:
              AppTextStyles.bodyMedium.copyWith(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: AppTextStyles.labelLarge
                  .copyWith(color: colors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(tasbihProvider.notifier).reset();
              Navigator.pop(context);
            },
            child: Text(
              'Reset',
              style: AppTextStyles.labelLarge.copyWith(
                color: colors.error,
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
    final colors = QibraColors.of(context);
    final state = ref.watch(tasbihProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: Container(
        color: colors.background,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: AppSpacing.sm),
                _buildAchievementBar(state),
                const SizedBox(height: AppSpacing.md),
                _buildDailyGoalCard(state),
                const SizedBox(height: AppSpacing.md),
                _buildDhikrCard(state),
                const SizedBox(height: AppSpacing.lg),
                _buildCounter(state),
                const SizedBox(height: AppSpacing.lg),
                _buildControls(state),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    final colors = QibraColors.of(context);
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).maybePop();
            },
            child: Container(
              width: AppA11y.minTapTarget,
              height: AppA11y.minTapTarget,
              decoration: BoxDecoration(
                color: colors.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors.border,
                ),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: colors.textPrimary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Digital Tasbih',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'تَسْبِيح',
                  textDirection: TextDirection.rtl,
                  style: AppArabicStyles.quranSmall.copyWith(
                    fontSize: 14,
                    color: colors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Statistics button (NEW)
          GestureDetector(
            onTap: _showStatistics,
            child: Container(
              width: AppA11y.minTapTarget,
              height: AppA11y.minTapTarget,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: colors.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors.border,
                ),
              ),
              child: Icon(
                Icons.bar_chart_rounded,
                color: colors.primary,
                size: 20,
              ),
            ),
          ),
          // History button (NEW)
          GestureDetector(
            onTap: _showHistory,
            child: Container(
              width: AppA11y.minTapTarget,
              height: AppA11y.minTapTarget,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: colors.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors.border,
                ),
              ),
              child: Icon(
                Icons.history_rounded,
                color: colors.primary,
                size: 20,
              ),
            ),
          ),
          // Vibration toggle
          Consumer(
            builder: (context, ref, _) {
              final vibrationEnabled =
                  ref.watch(tasbihProvider).vibrationEnabled;
              return GestureDetector(
                onTap: () {
                  ref.read(tasbihProvider.notifier).toggleVibration();
                },
                child: Container(
                  width: AppA11y.minTapTarget,
                  height: AppA11y.minTapTarget,
                  decoration: BoxDecoration(
                    color: vibrationEnabled
                        ? colors.primary
                        : colors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    vibrationEnabled
                        ? Icons.vibration_rounded
                        : Icons.smartphone_rounded,
                    color: vibrationEnabled
                        ? colors.onPrimary
                        : colors.textSecondary,
                    size: 20,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACHIEVEMENT BAR (NEW)
  // ============================================================

  Widget _buildAchievementBar(TasbihState state) {
    final colors = QibraColors.of(context);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border:
            Border.all(color: colors.accent.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.accent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.emoji_events_rounded,
              color: colors.onPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  state.achievementTitle,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colors.textPrimary,
                  ),
                ),
                Text(
                  '${state.totalCount} total dhikr',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.local_fire_department_rounded,
                    color: colors.error,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${state.currentStreak}',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: colors.error,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              Text(
                'day streak',
                style: AppTextStyles.labelSmall.copyWith(
                  color: colors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DAILY GOAL CARD (NEW)
  // ============================================================

  Widget _buildDailyGoalCard(TasbihState state) {
    final colors = QibraColors.of(context);
    return GestureDetector(
      onTap: _showDailyGoalSelector,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.flag_rounded,
                  color: state.isDailyGoalComplete
                      ? colors.primarySoft
                      : colors.primary,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Daily Goal',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: colors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${state.todayCount} / ${state.dailyGoal}',
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w800,
                    color: state.isDailyGoalComplete
                        ? colors.primarySoft
                        : colors.textPrimary,
                  ),
                ),
                const SizedBox(width: 4),
                if (state.isDailyGoalComplete)
                  const Icon(Icons.emoji_events_rounded, size: 18),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: state.dailyProgress,
                backgroundColor: colors.primary.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation(
                  state.isDailyGoalComplete
                      ? colors.primarySoft
                      : colors.primary,
                ),
                minHeight: 6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DHIKR CARD
  // ============================================================

  Widget _buildDhikrCard(TasbihState state) {
    final colors = QibraColors.of(context);
    return GestureDetector(
      onTap: _showDhikrSelector,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(AppRadius.xl2),
          border: Border.all(color: colors.primary.withValues(alpha: 0.16)),
        ),
        child: Column(
          children: [
            Text(
              state.currentDhikr.arabic,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: AppArabicStyles.quranBold.copyWith(
                fontSize: 32,
                color: colors.primary,
                height: 1.6,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              state.currentDhikr.transliteration,
              style: AppTextStyles.titleMedium.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              state.currentDhikr.translation,
              style: AppTextStyles.bodySmall.copyWith(
                color: colors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 4,
              ),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.swap_horiz_rounded,
                    color: colors.primary,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Tap to change',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // COUNTER
  // ============================================================

  Widget _buildCounter(TasbihState state) {
    final colors = QibraColors.of(context);
    return AnimatedBuilder(
      animation: _bounceAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _bounceAnimation.value,
          child: GestureDetector(
            onTap: _onCounterTap,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.surface,
                border: Border.all(
                    color: colors.primary.withValues(alpha: 0.16)),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 260,
                    height: 260,
                    child: CustomPaint(
                      painter: _ProgressRingPainter(
                        progress: state.progress,
                        color: colors.primary,
                        strokeWidth: 8,
                      ),
                    ),
                  ),
                  Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.primary,
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${state.count}',
                            style: TextStyle(
                              fontSize: 80,
                              color: colors.onPrimary,
                              fontWeight: FontWeight.w800,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: colors.onPrimary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '/ ${state.target}',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: colors.onPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // CONTROLS
  // ============================================================

  Widget _buildControls(TasbihState state) {
    final colors = QibraColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          // Stats row
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.refresh_rounded,
                  label: 'Rounds',
                  value: '${state.rounds}',
                  color: colors.textSecondary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatCard(
                  icon: Icons.timer_outlined,
                  label: 'Remaining',
                  value: '${state.remaining}',
                  color: colors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _StatCard(
                  icon: Icons.star_rounded,
                  label: 'Total',
                  value: '${state.totalCount}',
                  color: colors.accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Action buttons
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.tune_rounded,
                  label: 'Target',
                  onTap: _showTargetSelector,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _ActionButton(
                  icon: Icons.refresh_rounded,
                  label: 'Reset',
                  onTap: _confirmReset,
                  color: colors.error,
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
// PROGRESS RING PAINTER
// ============================================================
