import 'package:flutter/material.dart';
import '../../../core/design_system/qibra_colors.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class HabitTrackerScreen extends StatefulWidget {
  const HabitTrackerScreen({super.key});

  @override
  State<HabitTrackerScreen> createState() => _HabitTrackerScreenState();
}

class _HabitTrackerScreenState extends State<HabitTrackerScreen> {
  List<_IslamicHabit> _habits = [];
  static const String _storageKey = 'islamic_habits';

  final List<_HabitTemplate> _templates = [
    _HabitTemplate('Fajr on Time', '🌅', QibraColors.light.accent),
    _HabitTemplate('Read Quran', '📖', QibraColors.light.primary),
    _HabitTemplate('Morning Adhkar', '🌤️', QibraColors.light.accent),
    _HabitTemplate('Evening Adhkar', '🌙', QibraColors.light.accent),
    _HabitTemplate('Tahajjud', '🕌', QibraColors.light.primarySoft),
    _HabitTemplate('Give Sadaqah', '💚', QibraColors.light.primarySoft),
    _HabitTemplate('Fast Monday', '🗓️', QibraColors.light.accent),
    _HabitTemplate('Fast Thursday', '🗓️', QibraColors.light.accent),
    _HabitTemplate('Surah Mulk', '📜', QibraColors.light.primarySoft),
    _HabitTemplate('Surah Kahf (Fri)', '📜', QibraColors.light.primarySoft),
    _HabitTemplate('Durood 100x', '💛', QibraColors.light.accent),
    _HabitTemplate('Istighfar 100x', '🤲', QibraColors.light.primarySoft),
    _HabitTemplate('No Backbiting', '🤐', QibraColors.light.error),
    _HabitTemplate('Lower Gaze', '👁️', Color(0xFF6B7280)),
    _HabitTemplate('Help Someone', '🤝', QibraColors.light.primary),
    _HabitTemplate('Learn 1 Hadith', '📚', QibraColors.light.primarySoft),
  ];

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
            .map((e) => _IslamicHabit.fromJson(e as Map<String, dynamic>))
            .toList();
        _cleanOldDays();
      });
    } else {
      // Default habits
      setState(() {
        _habits = [
          _IslamicHabit(name: 'Fajr on Time', emoji: '🌅', color: 0xFFC6A15B),
          _IslamicHabit(name: 'Read Quran', emoji: '📖', color: 0xFF123F36),
          _IslamicHabit(
              name: 'Morning Adhkar', emoji: '🌤️', color: 0xFFC6A15B),
          _IslamicHabit(name: 'Evening Adhkar', emoji: '🌙', color: 0xFFC6A15B),
          _IslamicHabit(name: 'Tahajjud', emoji: '🕌', color: 0xFF2F6B5D),
        ];
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

  int _getStreak(_IslamicHabit habit) {
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
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colors.backgroundSecondary, colors.background],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(60, 8, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'عَادَات',
                    style: TextStyle(
                      color: colors.primarySoft,
                      fontSize: 22,
                      fontFamily: 'Amiri',
                    ),
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.backgroundSecondary, colors.card],
        ),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: colors.primarySoft.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: colors.primarySoft.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
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
                  backgroundColor:
                      colors.primarySoft.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation(colors.primarySoft),
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
                    color: colors.primarySoft,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$completed of ${_habits.length} habits',
                  style: TextStyle(
                    color: colors.textPrimary.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  progress == 1.0
                      ? 'MashaAllah! All done! 🎉'
                      : progress > 0.5
                          ? 'Almost there! Keep going 💪'
                          : 'Start your day right! 🌅',
                  style: TextStyle(
                    color: colors.textPrimary.withValues(alpha: 0.5),
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
                      ? colors.primarySoft
                      : colors.textPrimary.withValues(alpha: 0.3),
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
                      ? colors.primarySoft
                      : someDone
                          ? colors.primarySoft.withValues(alpha: 0.2)
                          : isToday
                              ? colors.primarySoft.withValues(alpha: 0.1)
                              : colors.textPrimary.withValues(alpha: 0.03),
                  shape: BoxShape.circle,
                  border: isToday
                      ? Border.all(color: colors.primarySoft, width: 1.5)
                      : null,
                ),
                child: Center(
                  child: allDone
                      ? Icon(Icons.check_rounded,
                          color: colors.textPrimary, size: 16)
                      : Text(
                          '${day.day}',
                          style: TextStyle(
                            color: isToday
                                ? colors.primarySoft
                                : colors.textPrimary.withValues(alpha: 0.4),
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
        const Text('📊', style: TextStyle(fontSize: 14)),
        const SizedBox(width: 8),
        Text(
          'YOUR HABITS',
          style: TextStyle(
            color: colors.textPrimary.withValues(alpha: 0.5),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 2.0,
          ),
        ),
        const Spacer(),
        Text(
          '${_habits.length} habits',
          style: TextStyle(
            color: colors.textPrimary.withValues(alpha: 0.3),
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  // ─── Empty State ────────────────────────────────────────────
  Widget _buildEmptyState() {
    final colors = QibraColors.of(context);
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Text('📊', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text(
            'No Habits Yet',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tap + to add Islamic habits',
            style: TextStyle(
              color: colors.textPrimary.withValues(alpha: 0.4),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Habit Card ─────────────────────────────────────────────
  Widget _buildHabitCard(_IslamicHabit habit, int index) {
    final colors = QibraColors.of(context);
    final todayDone = habit.completedDays.containsKey(_todayKey());
    final streak = _getStreak(habit);
    final color = Color(habit.color);

    return Dismissible(
      key: Key(habit.name + index.toString()),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteHabit(index),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: colors.error.withValues(alpha: 0.2),
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
                  ? color.withValues(alpha: 0.3)
                  : colors.textPrimary.withValues(alpha: 0.05),
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
                  color: todayDone ? color : color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: todayDone ? color : color.withValues(alpha: 0.3),
                    width: 2,
                  ),
                ),
                child: todayDone
                    ? Icon(Icons.check_rounded,
                        color: colors.textPrimary, size: 20)
                    : Center(
                        child: Text(habit.emoji,
                            style: const TextStyle(fontSize: 16)),
                      ),
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
                        decorationColor: color.withValues(alpha: 0.5),
                      ),
                    ),
                    if (streak > 0)
                      Row(
                        children: [
                          Icon(Icons.local_fire_department_rounded,
                              color: color.withValues(alpha: 0.7), size: 12),
                          const SizedBox(width: 3),
                          Text(
                            '$streak day streak',
                            style: TextStyle(
                              color: color.withValues(alpha: 0.6),
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
                  color: colors.textPrimary.withValues(alpha: 0.2),
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
                color: colors.textPrimary.withValues(alpha: 0.4),
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
                              _habits.add(_IslamicHabit(
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
                            ? colors.textPrimary.withValues(alpha: 0.02)
                            : t.color.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: alreadyAdded
                              ? colors.textPrimary.withValues(alpha: 0.03)
                              : t.color.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(t.emoji, style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              t.name,
                              style: TextStyle(
                                color: alreadyAdded
                                    ? colors.textPrimary.withValues(alpha: 0.25)
                                    : colors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (alreadyAdded)
                            Icon(Icons.check_circle_rounded,
                                color: t.color.withValues(alpha: 0.4), size: 20)
                          else
                            Icon(Icons.add_circle_outline_rounded,
                                color: t.color, size: 20),
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

// ─── Models ───────────────────────────────────────────────────
class _IslamicHabit {
  final String name;
  final String emoji;
  final int color;
  final Map<String, bool> completedDays;

  _IslamicHabit({
    required this.name,
    required this.emoji,
    required this.color,
    Map<String, bool>? completedDays,
  }) : completedDays = completedDays ?? {};

  Map<String, dynamic> toJson() => {
        'name': name,
        'emoji': emoji,
        'color': color,
        'completedDays': completedDays,
      };

  factory _IslamicHabit.fromJson(Map<String, dynamic> json) => _IslamicHabit(
        name: json['name'] as String,
        emoji: json['emoji'] as String,
        color: json['color'] as int,
        completedDays: Map<String, bool>.from(json['completedDays'] as Map),
      );
}

class _HabitTemplate {
  final String name;
  final String emoji;
  final Color color;
  const _HabitTemplate(this.name, this.emoji, this.color);
}
