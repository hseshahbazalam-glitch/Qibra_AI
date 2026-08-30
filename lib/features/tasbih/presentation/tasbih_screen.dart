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
              'MashaAllah! Target achieved 🎉',
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
                '🏆 Daily Goal Complete! Barakallahu feek!',
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
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colors.primary.withValues(alpha: 0.15),
              colors.background,
              colors.background,
            ],
            stops: const [0.0, 0.35, 1.0],
          ),
        ),
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
                color: colors.surface.withValues(alpha: 0.60),
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.20),
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
                  style: TextStyle(
                    fontFamily: 'Amiri',
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
                color: colors.surface.withValues(alpha: 0.60),
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.20),
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
                color: colors.surface.withValues(alpha: 0.60),
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors.primary.withValues(alpha: 0.20),
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
                        ? colors.primary.withValues(alpha: 0.20)
                        : colors.surface.withValues(alpha: 0.60),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    vibrationEnabled
                        ? Icons.vibration_rounded
                        : Icons.smartphone_rounded,
                    color: vibrationEnabled
                        ? colors.primary
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
        gradient: LinearGradient(
          colors: [
            colors.accent.withValues(alpha: 0.15),
            colors.accent.withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border:
            Border.all(color: colors.accent.withValues(alpha: 0.30)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.accent, Color(0xFFB8860B)],
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.emoji_events_rounded,
              color: colors.textPrimary,
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
                  const Text('🏆', style: TextStyle(fontSize: 18)),
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
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colors.primary.withValues(alpha: 0.20),
              colors.primary.withValues(alpha: 0.10),
            ],
          ),
          borderRadius: BorderRadius.circular(AppRadius.xl2),
          border: Border.all(color: colors.primary.withValues(alpha: 0.30)),
        ),
        child: Column(
          children: [
            Text(
              state.currentDhikr.arabic,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 32,
                color: colors.primary,
                fontWeight: FontWeight.w700,
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
                gradient: RadialGradient(
                  colors: [
                    colors.primary.withValues(alpha: 0.30),
                    colors.primary.withValues(alpha: 0.10),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: colors.primary.withValues(alpha: 0.40),
                    blurRadius: 40,
                    spreadRadius: 5,
                  ),
                ],
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
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [colors.primary, colors.accent],
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${state.count}',
                            style: TextStyle(
                              fontSize: 80,
                              color: colors.card,
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
                              color: colors.card.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '/ ${state.target}',
                              style: AppTextStyles.labelMedium.copyWith(
                                color: colors.card,
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
                  color: colors.primarySoft,
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

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _ProgressRingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final colors = QibraColors.light;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final bgPaint = Paint()
      ..color = color.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final rect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawArc(
      rect,
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

// ============================================================
// STAT CARD
// ============================================================

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.sm + 2,
        horizontal: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.titleSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: colors.textSecondary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ACTION BUTTON
// ============================================================

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    final btnColor = color ?? colors.primary;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          decoration: BoxDecoration(
            color: btnColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: btnColor.withValues(alpha: 0.30)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: btnColor, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                label,
                style: AppTextStyles.labelLarge.copyWith(
                  color: btnColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// DHIKR SELECTOR SHEET
// ============================================================

class _DhikrSelectorSheet extends ConsumerWidget {
  const _DhikrSelectorSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = QibraColors.of(context);
    final currentDhikr = ref.watch(tasbihProvider).currentDhikr;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xl2)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Select Dhikr',
              style: AppTextStyles.titleMedium
                  .copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.lg),
            ...Dhikrs.all.map((dhikr) {
              final isSelected = dhikr.id == currentDhikr.id;
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: InkWell(
                  onTap: () {
                    ref.read(tasbihProvider.notifier).setDhikr(dhikr);
                    HapticFeedback.selectionClick();
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colors.primary.withValues(alpha: 0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(
                        color: isSelected
                            ? colors.primary
                            : colors.border,
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dhikr.arabic,
                                textDirection: TextDirection.rtl,
                                style: TextStyle(
                                  fontFamily: 'Amiri',
                                  fontSize: 22,
                                  color: colors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                dhikr.transliteration,
                                style: AppTextStyles.titleSmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                dhikr.translation,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: colors.textSecondary,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: colors.accent.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${dhikr.defaultTarget}',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: colors.goldText,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Icon(
                            Icons.check_circle_rounded,
                            color: colors.primary,
                            size: 20,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// TARGET SELECTOR SHEET
// ============================================================

class _TargetSelectorSheet extends ConsumerWidget {
  const _TargetSelectorSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = QibraColors.of(context);
    final currentTarget = ref.watch(tasbihProvider).target;
    final presets = [33, 99, 100, 500, 1000];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xl2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Set Target',
            style:
                AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: presets.map((preset) {
              final isSelected = preset == currentTarget;
              return InkWell(
                onTap: () {
                  ref.read(tasbihProvider.notifier).setTarget(preset);
                  HapticFeedback.selectionClick();
                  Navigator.pop(context);
                },
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colors.primary
                        : colors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text(
                    '$preset',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: isSelected ? colors.onPrimary : colors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

// ============================================================
// DAILY GOAL SHEET (NEW)
// ============================================================

class _DailyGoalSheet extends ConsumerWidget {
  const _DailyGoalSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = QibraColors.of(context);
    final currentGoal = ref.watch(tasbihProvider).dailyGoal;
    final goals = [50, 100, 300, 500, 1000, 2000];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppRadius.xl2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Set Daily Goal',
            style:
                AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Total dhikr count target per day',
            style: AppTextStyles.labelSmall
                .copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: goals.map((goal) {
              final isSelected = goal == currentGoal;
              return InkWell(
                onTap: () {
                  ref.read(tasbihProvider.notifier).setDailyGoal(goal);
                  HapticFeedback.selectionClick();
                  Navigator.pop(context);
                },
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? LinearGradient(
                            colors: [colors.primary, colors.accent],
                          )
                        : null,
                    color: isSelected
                        ? null
                        : colors.primary.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Text(
                    '$goal',
                    style: AppTextStyles.titleSmall.copyWith(
                      color: isSelected ? colors.onPrimary : colors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}

// ============================================================
// STATISTICS SCREEN (NEW)
// ============================================================

class _StatisticsScreen extends ConsumerWidget {
  const _StatisticsScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = QibraColors.of(context);
    final state = ref.watch(tasbihProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        title: Text(
          'Statistics',
          style:
              AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Achievement Card
              Container(
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [colors.accent, Color(0xFFB8860B)],
                  ),
                  borderRadius: BorderRadius.circular(AppRadius.xl2),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.emoji_events_rounded,
                      color: colors.textPrimary,
                      size: 48,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      state.achievementTitle,
                      style: AppTextStyles.titleLarge.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${state.totalCount} total dhikr',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: colors.textPrimary.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              // Stats Grid
              Row(
                children: [
                  Expanded(
                    child: _bigStatCard(
                      context,
                      icon: Icons.today_rounded,
                      label: 'Today',
                      value: '${state.todayCount}',
                      color: colors.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _bigStatCard(
                      context,
                      icon: Icons.local_fire_department_rounded,
                      label: 'Streak',
                      value: '${state.currentStreak}',
                      color: colors.error,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: _bigStatCard(
                      context,
                      icon: Icons.star_rounded,
                      label: 'Best Streak',
                      value: '${state.bestStreak}',
                      color: colors.accent,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: _bigStatCard(
                      context,
                      icon: Icons.flag_rounded,
                      label: 'Daily Goal',
                      value: '${state.dailyGoal}',
                      color: colors.primarySoft,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              // Achievement Levels
              Text(
                'Achievement Levels',
                style: AppTextStyles.titleSmall
                    .copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.md),
              _achievementRow(context, 'Starter', 0, state.totalCount,
                  state.achievementLevel >= 0),
              _achievementRow(context, 'Beginner 🌸', 100, state.totalCount,
                  state.achievementLevel >= 1),
              _achievementRow(context, 'Rising Star 🌱', 1000, state.totalCount,
                  state.achievementLevel >= 2),
              _achievementRow(context, 'Intermediate 💎', 5000, state.totalCount,
                  state.achievementLevel >= 3),
              _achievementRow(context, 'Advanced 🌟', 10000, state.totalCount,
                  state.achievementLevel >= 4),
              _achievementRow(context, 'Expert ⭐', 50000, state.totalCount,
                  state.achievementLevel >= 5),
              _achievementRow(context, 'Master 🏆', 100000, state.totalCount,
                  state.achievementLevel >= 6),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bigStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final colors = QibraColors.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.headlineSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _achievementRow(
    BuildContext context,
    String title,
    int target,
    int current,
    bool unlocked,
  ) {
    final colors = QibraColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: unlocked
            ? colors.primary.withValues(alpha: 0.10)
            : colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: unlocked ? colors.primary : colors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(
            unlocked ? Icons.check_circle_rounded : Icons.lock_outline_rounded,
            color: unlocked ? colors.primary : colors.textTertiary,
            size: 24,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: unlocked
                        ? colors.textPrimary
                        : colors.textSecondary,
                  ),
                ),
                Text(
                  target > 0 ? '$target dhikr required' : 'Just start!',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (unlocked)
            Text(
              '✓',
              style: TextStyle(
                color: colors.primary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}

// ============================================================
// HISTORY SCREEN (NEW)
// ============================================================

class _HistoryScreen extends ConsumerWidget {
  const _HistoryScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = QibraColors.of(context);
    final history = ref.watch(tasbihProvider).history;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        elevation: 0,
        title: Text(
          'History',
          style:
              AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: history.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 80,
                      color: colors.textTertiary,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'No history yet',
                      style: AppTextStyles.titleMedium
                          .copyWith(color: colors.textSecondary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Complete a target to see history',
                      style: AppTextStyles.bodySmall
                          .copyWith(color: colors.textTertiary),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(AppSpacing.lg),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  final entry = history[index];
                  final dhikr = Dhikrs.all.firstWhere(
                    (d) => d.id == entry.dhikrId,
                    orElse: () => Dhikrs.subhanAllah,
                  );

                  return Container(
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      border: Border.all(color: colors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: colors.primary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.check_circle_rounded,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dhikr.transliteration,
                                style: AppTextStyles.titleSmall.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${entry.count} times • ${entry.date}',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          _timeAgo(entry.completedAt),
                          style: AppTextStyles.labelSmall.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }

  String _timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${(diff.inDays / 7).floor()}w';
  }
}
