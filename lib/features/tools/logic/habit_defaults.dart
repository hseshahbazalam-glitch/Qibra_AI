// Data side of the habit tracker: templates + first-run seeds.
// Emoji and legacy color ints live here deliberately — they persist in
// SharedPreferences JSON (migration-free round-trip), but the screens
// never render them; presentation derives icons and tones from theme
// tokens (see habit_tracker_screen.dart).
import 'package:flutter/material.dart';

import '../../../core/design_system/qibra_colors.dart';

class HabitTemplate {
  final String name;
  final String emoji;
  final Color color;
  const HabitTemplate(this.name, this.emoji, this.color);
}

List<HabitTemplate> buildHabitTemplates() => [
    HabitTemplate('Fajr on Time', '🌅', QibraColors.light.accent),
    HabitTemplate('Read Quran', '📖', QibraColors.light.primary),
    HabitTemplate('Morning Adhkar', '🌤️', QibraColors.light.accent),
    HabitTemplate('Evening Adhkar', '🌙', QibraColors.light.accent),
    HabitTemplate('Tahajjud', '🕌', QibraColors.light.primarySoft),
    HabitTemplate('Give Sadaqah', '💚', QibraColors.light.primarySoft),
    HabitTemplate('Fast Monday', '🗓️', QibraColors.light.accent),
    HabitTemplate('Fast Thursday', '🗓️', QibraColors.light.accent),
    HabitTemplate('Surah Mulk', '📜', QibraColors.light.primarySoft),
    HabitTemplate('Surah Kahf (Fri)', '📜', QibraColors.light.primarySoft),
    HabitTemplate('Durood 100x', '💛', QibraColors.light.accent),
    HabitTemplate('Istighfar 100x', '🤲', QibraColors.light.primarySoft),
    HabitTemplate('No Backbiting', '🤐', QibraColors.light.error),
    HabitTemplate('Lower Gaze', '👁️', QibraColors.light.primary),
    HabitTemplate('Help Someone', '🤝', QibraColors.light.primary),
    HabitTemplate('Learn 1 Hadith', '📚', QibraColors.light.primarySoft),
];

List<IslamicHabit> buildDefaultHabits() => [
          IslamicHabit(name: 'Fajr on Time', emoji: '🌅', color: 0xFFC6A15B),
          IslamicHabit(name: 'Read Quran', emoji: '📖', color: 0xFF123F36),
          IslamicHabit(
              name: 'Morning Adhkar', emoji: '🌤️', color: 0xFFC6A15B),
          IslamicHabit(name: 'Evening Adhkar', emoji: '🌙', color: 0xFFC6A15B),
          IslamicHabit(name: 'Tahajjud', emoji: '🕌', color: 0xFF2F6B5D),
];

// ─── Models ───────────────────────────────────────────────────
class IslamicHabit {
  final String name;
  final String emoji;
  final int color;
  final Map<String, bool> completedDays;

  IslamicHabit({
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

  factory IslamicHabit.fromJson(Map<String, dynamic> json) => IslamicHabit(
        name: json['name'] as String,
        emoji: json['emoji'] as String,
        color: json['color'] as int,
        completedDays: Map<String, bool>.from(json['completedDays'] as Map),
      );
}

class HabitTemplate {
  final String name;
  final String emoji;
  final Color color;
  const HabitTemplate(this.name, this.emoji, this.color);
}
