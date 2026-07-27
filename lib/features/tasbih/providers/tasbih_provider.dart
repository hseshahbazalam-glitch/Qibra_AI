// lib/features/tasbih/providers/tasbih_provider.dart

// ============================================================
// QIBRA AI — TASBIH PROVIDER (v2.0 - PREMIUM)
// ============================================================

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================
// DHIKR MODEL
// ============================================================

class Dhikr {
  final String id;
  final String arabic;
  final String transliteration;
  final String translation;
  final int defaultTarget;

  const Dhikr({
    required this.id,
    required this.arabic,
    required this.transliteration,
    required this.translation,
    required this.defaultTarget,
  });
}

// ============================================================
// PREDEFINED DHIKRS (ALL FIXED!)
// ============================================================

class Dhikrs {
  static const Dhikr subhanAllah = Dhikr(
    id: 'subhan_allah',
    arabic: 'سُبْحَانَ اللَّهِ',
    transliteration: 'SubhanAllah',
    translation: 'Glory be to Allah',
    defaultTarget: 33,
  );

  static const Dhikr alhamdulillah = Dhikr(
    id: 'alhamdulillah',
    arabic: 'الْحَمْدُ لِلَّهِ',
    transliteration: 'Alhamdulillah',
    translation: 'All praise is due to Allah',
    defaultTarget: 33,
  );

  static const Dhikr allahuAkbar = Dhikr(
    id: 'allahu_akbar',
    arabic: 'اللَّهُ أَكْبَرُ',
    transliteration: 'Allahu Akbar',
    translation: 'Allah is the Greatest',
    defaultTarget: 34,
  );

  static const Dhikr laIlahaIllallah = Dhikr(
    id: 'la_ilaha_illallah',
    arabic: 'لَا إِلَٰهَ إِلَّا اللَّهُ',
    transliteration: 'La ilaha illa Allah',
    translation: 'There is no god but Allah',
    defaultTarget: 100,
  );

  static const Dhikr astaghfirullah = Dhikr(
    id: 'astaghfirullah',
    arabic: 'أَسْتَغْفِرُ اللَّهَ',
    transliteration: 'Astaghfirullah',
    translation: 'I seek forgiveness from Allah',
    defaultTarget: 100,
  );

  static const Dhikr salawat = Dhikr(
    id: 'salawat',
    arabic: 'اللَّهُمَّ صَلِّ عَلَىٰ مُحَمَّدٍ',
    transliteration: 'Allahumma Salli Ala Muhammad',
    translation: 'O Allah, send prayers upon Muhammad',
    defaultTarget: 100,
  );

  static const Dhikr laHawla = Dhikr(
    id: 'la_hawla',
    arabic: 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
    transliteration: 'La hawla wa la quwwata illa billah',
    translation: 'There is no power except with Allah',
    defaultTarget: 100,
  );

  static const List<Dhikr> all = [
    subhanAllah,
    alhamdulillah,
    allahuAkbar,
    laIlahaIllallah,
    astaghfirullah,
    salawat,
    laHawla,
  ];
}

// ============================================================
// HISTORY ENTRY (NEW)
// ============================================================

class TasbihHistoryEntry {
  final String date; // yyyy-MM-dd
  final String dhikrId;
  final int count;
  final DateTime completedAt;

  const TasbihHistoryEntry({
    required this.date,
    required this.dhikrId,
    required this.count,
    required this.completedAt,
  });

  Map<String, dynamic> toJson() => {
        'date': date,
        'dhikrId': dhikrId,
        'count': count,
        'completedAt': completedAt.toIso8601String(),
      };

  factory TasbihHistoryEntry.fromJson(Map<String, dynamic> json) {
    return TasbihHistoryEntry(
      date: json['date'] as String,
      dhikrId: json['dhikrId'] as String,
      count: json['count'] as int,
      completedAt: DateTime.parse(json['completedAt'] as String),
    );
  }
}

// ============================================================
// TASBIH STATE (Enhanced)
// ============================================================

class TasbihState {
  final Dhikr currentDhikr;
  final int count;
  final int target;
  final int totalCount;
  final int todayCount;
  final int dailyGoal;
  final int currentStreak;
  final int bestStreak;
  final bool vibrationEnabled;
  final bool soundEnabled;
  final List<TasbihHistoryEntry> history;
  final String lastActiveDate;

  const TasbihState({
    this.currentDhikr = Dhikrs.subhanAllah,
    this.count = 0,
    this.target = 33,
    this.totalCount = 0,
    this.todayCount = 0,
    this.dailyGoal = 100,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.vibrationEnabled = true,
    this.soundEnabled = false,
    this.history = const [],
    this.lastActiveDate = '',
  });

  double get progress {
    if (target == 0) return 0.0;
    return (count / target).clamp(0.0, 1.0);
  }

  double get dailyProgress {
    if (dailyGoal == 0) return 0.0;
    return (todayCount / dailyGoal).clamp(0.0, 1.0);
  }

  int get remaining => (target - count).clamp(0, target);
  bool get isComplete => count >= target;
  bool get isDailyGoalComplete => todayCount >= dailyGoal;
  int get rounds => count ~/ target;

  // Achievements
  int get achievementLevel {
    if (totalCount >= 100000) return 6; // Master
    if (totalCount >= 50000) return 5; // Expert
    if (totalCount >= 10000) return 4; // Advanced
    if (totalCount >= 5000) return 3; // Intermediate
    if (totalCount >= 1000) return 2; // Beginner+
    if (totalCount >= 100) return 1; // Beginner
    return 0; // Starter
  }

  String get achievementTitle {
    switch (achievementLevel) {
      case 6:
        return 'Master 🏆';
      case 5:
        return 'Expert ⭐';
      case 4:
        return 'Advanced 🌟';
      case 3:
        return 'Intermediate 💎';
      case 2:
        return 'Rising Star 🌱';
      case 1:
        return 'Beginner 🌸';
      default:
        return 'Starter';
    }
  }

  TasbihState copyWith({
    Dhikr? currentDhikr,
    int? count,
    int? target,
    int? totalCount,
    int? todayCount,
    int? dailyGoal,
    int? currentStreak,
    int? bestStreak,
    bool? vibrationEnabled,
    bool? soundEnabled,
    List<TasbihHistoryEntry>? history,
    String? lastActiveDate,
  }) {
    return TasbihState(
      currentDhikr: currentDhikr ?? this.currentDhikr,
      count: count ?? this.count,
      target: target ?? this.target,
      totalCount: totalCount ?? this.totalCount,
      todayCount: todayCount ?? this.todayCount,
      dailyGoal: dailyGoal ?? this.dailyGoal,
      currentStreak: currentStreak ?? this.currentStreak,
      bestStreak: bestStreak ?? this.bestStreak,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      soundEnabled: soundEnabled ?? this.soundEnabled,
      history: history ?? this.history,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
    );
  }
}

// ============================================================
// TASBIH NOTIFIER (Enhanced)
// ============================================================

class TasbihNotifier extends StateNotifier<TasbihState> {
  TasbihNotifier() : super(const TasbihState()) {
    _loadPersistedData();
  }

  static const String _keyTotalCount = 'tasbih_total_count';
  static const String _keyTodayCount = 'tasbih_today_count';
  static const String _keyLastDhikr = 'tasbih_last_dhikr';
  static const String _keyVibration = 'tasbih_vibration';
  static const String _keyDailyGoal = 'tasbih_daily_goal';
  static const String _keyStreak = 'tasbih_streak';
  static const String _keyBestStreak = 'tasbih_best_streak';
  static const String _keyLastDate = 'tasbih_last_date';
  static const String _keyHistory = 'tasbih_history';

  String get _todayString {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadPersistedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final totalCount = prefs.getInt(_keyTotalCount) ?? 0;
      final lastDhikrId =
          prefs.getString(_keyLastDhikr) ?? Dhikrs.subhanAllah.id;
      final vibration = prefs.getBool(_keyVibration) ?? true;
      final dailyGoal = prefs.getInt(_keyDailyGoal) ?? 100;
      final streak = prefs.getInt(_keyStreak) ?? 0;
      final bestStreak = prefs.getInt(_keyBestStreak) ?? 0;
      final lastDate = prefs.getString(_keyLastDate) ?? '';

      // Check if today or yesterday
      var currentStreak = streak;
      var todayCount = prefs.getInt(_keyTodayCount) ?? 0;

      if (lastDate != _todayString) {
        // New day - reset today count
        todayCount = 0;

        // Check streak
        final today = DateTime.now();
        if (lastDate.isNotEmpty) {
          try {
            final lastDateTime = DateTime.parse(lastDate);
            final diff = today.difference(lastDateTime).inDays;
            if (diff > 1) {
              // Streak broken
              currentStreak = 0;
            }
          } catch (_) {}
        }
      }

      // Load history
      final historyJson = prefs.getStringList(_keyHistory) ?? [];
      final history = historyJson
          .map((e) {
            try {
              return TasbihHistoryEntry.fromJson(jsonDecode(e));
            } catch (_) {
              return null;
            }
          })
          .whereType<TasbihHistoryEntry>()
          .toList();

      final dhikr = Dhikrs.all.firstWhere(
        (d) => d.id == lastDhikrId,
        orElse: () => Dhikrs.subhanAllah,
      );

      state = state.copyWith(
        currentDhikr: dhikr,
        target: dhikr.defaultTarget,
        totalCount: totalCount,
        todayCount: todayCount,
        dailyGoal: dailyGoal,
        currentStreak: currentStreak,
        bestStreak: bestStreak,
        vibrationEnabled: vibration,
        history: history,
        lastActiveDate: lastDate,
      );
    } catch (_) {}
  }

  Future<void> _saveAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyTotalCount, state.totalCount);
      await prefs.setInt(_keyTodayCount, state.todayCount);
      await prefs.setInt(_keyStreak, state.currentStreak);
      await prefs.setInt(_keyBestStreak, state.bestStreak);
      await prefs.setString(_keyLastDate, state.lastActiveDate);
    } catch (_) {}
  }

  Future<void> _saveHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final historyJson =
          state.history.map((e) => jsonEncode(e.toJson())).toList();
      await prefs.setStringList(_keyHistory, historyJson);
    } catch (_) {}
  }

  Future<void> _saveDhikr(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyLastDhikr, id);
    } catch (_) {}
  }

  Future<void> _saveVibration(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyVibration, enabled);
    } catch (_) {}
  }

  Future<void> _saveDailyGoal(int goal) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyDailyGoal, goal);
    } catch (_) {}
  }

  /// Increment counter
  void increment() {
    final today = _todayString;
    var newStreak = state.currentStreak;
    var newBestStreak = state.bestStreak;

    // If new day and it's continuous (yesterday), extend streak
    if (state.lastActiveDate != today) {
      if (state.lastActiveDate.isNotEmpty) {
        try {
          final lastDate = DateTime.parse(state.lastActiveDate);
          final today = DateTime.now();
          final diff = today.difference(lastDate).inDays;
          if (diff == 1) {
            newStreak = state.currentStreak + 1;
          } else if (diff > 1) {
            newStreak = 1; // Reset streak
          }
        } catch (_) {
          newStreak = 1;
        }
      } else {
        newStreak = 1;
      }

      if (newStreak > newBestStreak) {
        newBestStreak = newStreak;
      }
    }

    state = state.copyWith(
      count: state.count + 1,
      totalCount: state.totalCount + 1,
      todayCount: state.todayCount + 1,
      currentStreak: newStreak,
      bestStreak: newBestStreak,
      lastActiveDate: today,
    );

    _saveAll();

    // Add to history when target completed
    if (state.count == state.target) {
      _addHistoryEntry();
    }
  }

  void _addHistoryEntry() {
    final entry = TasbihHistoryEntry(
      date: _todayString,
      dhikrId: state.currentDhikr.id,
      count: state.target,
      completedAt: DateTime.now(),
    );

    // Keep last 100 entries
    final newHistory = [entry, ...state.history];
    if (newHistory.length > 100) {
      newHistory.removeLast();
    }

    state = state.copyWith(history: newHistory);
    _saveHistory();
  }

  /// Reset current count (keep total)
  void reset() {
    state = state.copyWith(count: 0);
  }

  /// Reset everything
  void resetAll() {
    state = state.copyWith(
      count: 0,
      totalCount: 0,
      todayCount: 0,
      currentStreak: 0,
      bestStreak: 0,
      history: [],
    );
    _saveAll();
    _saveHistory();
  }

  /// Change current dhikr
  void setDhikr(Dhikr dhikr) {
    state = state.copyWith(
      currentDhikr: dhikr,
      target: dhikr.defaultTarget,
      count: 0,
    );
    _saveDhikr(dhikr.id);
  }

  /// Set custom target
  void setTarget(int target) {
    if (target < 1) return;
    state = state.copyWith(target: target);
  }

  /// Set daily goal
  void setDailyGoal(int goal) {
    if (goal < 1) return;
    state = state.copyWith(dailyGoal: goal);
    _saveDailyGoal(goal);
  }

  /// Toggle vibration
  void toggleVibration() {
    final newValue = !state.vibrationEnabled;
    state = state.copyWith(vibrationEnabled: newValue);
    _saveVibration(newValue);
  }
}

// ============================================================
// PROVIDER
// ============================================================

final tasbihProvider =
    StateNotifierProvider<TasbihNotifier, TasbihState>((ref) {
  return TasbihNotifier();
});
