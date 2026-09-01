import 'package:flutter/material.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/qibra_colors.dart';
import '../logic/habit_defaults.dart';
import '../../../shared/widgets/qibra_ui.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class HabitTrackerScreen extends StatefulWidget {
  const HabitTrackerScreen({super.key});

  @override
  State<HabitTrackerScreen> createState() => _HabitTrackerScreenState();
}

class _HabitTrackerScreenState extends State<HabitTrackerScreen> {
  List<IslamicHabit> _habits = [];
  static const String _storageKey = 'islamic_habits';

  final List<HabitTemplate> _templates = buildHabitTemplates();

  @override
  void initState() {
    super.initState();
    _loadHabits();
  }

  Future<void> _loadHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_storageKey);
    if (data != null) {
      final List<dynamic> list = jsonDecode(data) as List<dynamic>;
      setState(() {
        _habits = list
            .map((e) => IslamicHabit.fromJson(e as Map<String, dynamic>))
            .toList();
        _cleanOldDays();
      });
    } else {
      // Default habits
      setState(() {
        _habits = buildDefaultHabits();
      });
      _saveHabits();
    }
  }

  void _cleanOldDays() {
    final today = _todayKey();
    for (final h in _habits) {
      h.completedDays.removeWhere((key, _) {
        final diff =
            DateTime.parse(today).difference(DateTime.parse(key)).inDays;
        return diff > 30;
      });
    }
  }

  Future<void> _saveHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final data = jsonEncode(_habits.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, data);
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  void _toggleHabit(int index) {
    HapticFeedback.lightImpact();
    final key = _todayKey();
    setState(() {
      if (_habits[index].completedDays.containsKey(key)) {
        _habits[index].completedDays.remove(key);
      } else {
        _habits[index].completedDays[key] = true;
      }
    });
    _saveHabits();
  }

  void _deleteHabit(int index) {
    HapticFeedback.mediumImpact();
    setState(() => _habits.removeAt(index));
    _saveHabits();
  }

  int _getStreak(IslamicHabit habit) {
    int streak = 0;
    DateTime day = DateTime.now();
    while (true) {
      final key =
          '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      if (habit.completedDays.containsKey(key)) {
        streak++;
        day = day.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }
    return streak;
  }

  int _getCompletedToday() {
    final key = _todayKey();
    return _habits.where((h) => h.completedDays.containsKey(key)).length;
  }

  double _getTodayProgress() {
    if (_habits.isEmpty) return 0;
    return _getCompletedToday() / _habits.length;
  }

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    final progress = _getTodayProgress();
    final completed = _getCompletedToday();

    return Scaffold(
      backgroundColor: colors.background,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddHabitSheet,
        backgroundColor: colors.primarySoft,
        child: Icon(Icons.add_rounded, color: colors.textPrimary),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(),
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildProgressCard(progress, completed),
                const SizedBox(height: 20),
                _buildWeekView(),
                const SizedBox(height: 24),
                _buildHabitsHeader(),
                const SizedBox(height: 12),
                if (_habits.isEmpty) _buildEmptyState(),
                ..._habits.asMap().entries.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildHabitCard(e.value, e.key),
                      ),
                    ),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ─── App Bar ────────────────────────────────────────────────
  SliverAppBar _buildAppBar() {
    final colors = QibraColors.of(context);
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: colors.background,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colors.textPrimary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.arrow_back_rounded,
              color: colors.textPrimary, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            color: colors.surface,
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(60, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'عَادَات',
                    style: AppArabicStyles.quranMedium.copyWith(
                      fontSize: 22,
                      color: colors.primary,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                  Text(
                    'Islamic Habits',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── Progress Card ──────────────────────────────────────────
  Widget _buildProgressCard(double progress, int completed) {
    final colors = QibraColors.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: colors.primary.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          // Progress Circle
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  backgroundColor: colors.surfaceElevated,
                  valueColor: AlwaysStoppedAnimation(colors.primary),
                ),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Today's Progress",
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$completed of ${_habits.length} habits',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  progress == 1.0
                      ? 'MashaAllah — every habit checked off today.'
                      : progress > 0.5
                          ? 'Almost there — keep going.'
                          : 'Start your day right.',
                  style: TextStyle(
                    color: colors.textTertiary,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Week View ──────────────────────────────────────────────
  Widget _buildWeekView() {
    final colors = QibraColors.of(context);
    final now = DateTime.now();
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.textPrimary.withValues(alpha: 0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(7, (i) {
          final day = now.subtract(Duration(days: now.weekday - 1 - i));
          final key =
              '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
          final isToday = key == _todayKey();

          int completedCount = 0;
          for (final h in _habits) {
            if (h.completedDays.containsKey(key)) completedCount++;
          }

          final allDone =
              _habits.isNotEmpty && completedCount == _habits.length;
          final someDone = completedCount > 0 && !allDone;

          return Column(
            children: [
              Text(
                days[i],
                style: TextStyle(
                  color: isToday
                      ? colors.primary
                      : colors.textTertiary,
                  fontSize: 10,
                  fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: allDone
                      ? colors.primary
                      : someDone
                          ? colors.primary.withValues(alpha: 0.12)
                          : isToday
                              ? colors.primary.withValues(alpha: 0.08)
                              : colors.surface,
                  shape: BoxShape.circle,
                  border: isToday
                      ? Border.all(color: colors.primary, width: 1.5)
                      : null,
                ),
                child: Center(
                  child: allDone
                      ? Icon(Icons.check_rounded,
                          color: colors.onPrimary, size: 16)
                      : Text(
                          '${day.day}',
                          style: TextStyle(
                            color: isToday
                                ? colors.primary
                                : colors.textTertiary,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // ─── Habits Header ──────────────────────────────────────────
  Widget _buildHabitsHeader() {
    final colors = QibraColors.of(context);
    return Row(
      children: [
        Icon(Icons.insights_rounded, size: 16,
            color: colors.textSecondary),
        const SizedBox(width: 8),
        Text(
          'YOUR HABITS',
          style: TextStyle(
            color: colors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
          ),
        ),
        const Spacer(),
        Text(
          '${_habits.length} habits',
          style: TextStyle(
            color: colors.textTertiary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  // ─── Empty State ────────────────────────────────────────────
  Widget _buildEmptyState() {
    return QibraEmptyState(
      icon: Icons.fact_check_outlined,
      title: 'No Habits Yet',
      message: 'Add your first habit and this screen will start '
          'tracking your daily streak.',
      actionLabel: 'Add a habit',
      onAction: _showAddHabitSheet,
    );
  }

  // ─── Habit Card ─────────────────────────────────────────────
  Widget _buildHabitCard(IslamicHabit habit, int index) {
    final colors = QibraColors.of(context);
    final todayDone = habit.completedDays.containsKey(_todayKey());
    final streak = _getStreak(habit);
    // The stored int color is legacy seed data; presentation derives
    // from context tokens instead (invisible tones were persisted).
    final color = colors.primary;

    return Dismissible(
      key: Key(habit.name + index.toString()),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteHabit(index),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: colors.error.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(Icons.delete_rounded,
            color: colors.error, size: 22),
      ),
      child: GestureDetector(
        onTap: () => _toggleHabit(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: todayDone
                ? color.withValues(alpha: 0.08)
                : colors.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: todayDone
                  ? color.withValues(alpha: 0.16)
                  : colors.border,
            ),
          ),
          child: Row(
            children: [
              // Check Circle
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: todayDone ? color : colors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: todayDone ? color : color.withValues(alpha: 0.16),
                    width: 2,
                  ),
                ),
                child: todayDone
                    ? Icon(Icons.check_rounded,
                        color: colors.onPrimary, size: 20)
                    : const SizedBox.shrink(),
              ),
              const SizedBox(width: 14),

              // Name + Streak
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      habit.name,
                      style: TextStyle(
                        color: todayDone ? color : colors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        decoration:
                            todayDone ? TextDecoration.lineThrough : null,
                        decorationColor: color,
                      ),
                    ),
                    if (streak > 0)
                      Row(
                        children: [
                          Icon(Icons.local_fire_department_rounded,
                              color: colors.accent, size: 12),
                          const SizedBox(width: 3),
                          Text(
                            '$streak day streak',
                            style: TextStyle(
                              color: colors.accent,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              // Mini week dots
              Row(
                children: List.generate(7, (i) {
                  final day = DateTime.now().subtract(Duration(days: 6 - i));
                  final key =
                      '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
                  final done = habit.completedDays.containsKey(key);
                  return Padding(
                    padding: const EdgeInsets.only(left: 3),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: done ? color : color.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Add Habit Sheet ────────────────────────────────────────
  void _showAddHabitSheet() {
    final colors = QibraColors.of(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.7,
        ),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
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
            const SizedBox(height: 16),
            Text(
              'Add Islamic Habit',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Choose from templates or create your own',
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 20),

            // Templates
            Expanded(
              child: ListView.builder(
                itemCount: _templates.length,
                itemBuilder: (ctx, i) {
                  final t = _templates[i];
                  final alreadyAdded = _habits.any((h) => h.name == t.name);
                  return GestureDetector(
                    onTap: alreadyAdded
                        ? null
                        : () {
                            HapticFeedback.mediumImpact();
                            setState(() {
                              _habits.add(IslamicHabit(
                                name: t.name,
                                emoji: t.emoji,
                                color: t.color.toARGB32(),
                              ));
                            });
                            _saveHabits();
                            Navigator.pop(ctx);
                          },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: alreadyAdded
                            ? colors.surface
                            : colors.primary.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: alreadyAdded
                              ? colors.border
                              : colors.primary.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.add_task_rounded,
                              size: 20, color: colors.primary),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              t.name,
                              style: TextStyle(
                                color: alreadyAdded
                                    ? colors.textTertiary
                                    : colors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (alreadyAdded)
                            Icon(Icons.check_circle_rounded,
                                color: colors.textTertiary, size: 20)
                          else
                            Icon(Icons.add_circle_outline_rounded,
                                color: colors.primary, size: 20),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

