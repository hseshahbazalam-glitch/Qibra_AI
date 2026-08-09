// lib/features/quran/data/repository/reading_progress_repository.dart
// ============================================================
// QIBRA AI — Reading Progress Repository
// Auto-saves reading position — No button needed
// Uses: SharedPreferences (already in pubspec)
// Reuses: LastReadModel, ReadingProgressModel (existing models)
// ============================================================

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/quran_models.dart';

// ============================================================
// MUSHAF PAGE MODEL — New (page-level tracking)
// ============================================================

class MushafPageModel {
  final int pageNumber; // 1–604
  final int surahNumber; // Which surah starts on this page
  final String surahName; // Surah name
  final int ayahNumber; // Which ayah on this page
  final int juzNumber; // 1–30
  final int hizbNumber; // 1–60
  final DateTime savedAt;
  final int totalReadingSeconds; // Total time spent reading

  const MushafPageModel({
    required this.pageNumber,
    required this.surahNumber,
    required this.surahName,
    required this.ayahNumber,
    required this.juzNumber,
    required this.hizbNumber,
    required this.savedAt,
    this.totalReadingSeconds = 0,
  });

  // Progress percentage (0.0 to 1.0)
  double get overallProgress => pageNumber / 604;

  // Human readable progress
  String get progressText => '${(overallProgress * 100).toStringAsFixed(1)}%';

  // Time ago string
  String get timeAgo {
    final diff = DateTime.now().difference(savedAt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${savedAt.day}/${savedAt.month}/${savedAt.year}';
  }

  // Reading time formatted
  String get readingTimeText {
    if (totalReadingSeconds < 60) return '${totalReadingSeconds}s';
    final mins = totalReadingSeconds ~/ 60;
    if (mins < 60) return '$mins min';
    return '${mins ~/ 60}h ${mins % 60}m';
  }

  Map<String, dynamic> toJson() => {
        'pageNumber': pageNumber,
        'surahNumber': surahNumber,
        'surahName': surahName,
        'ayahNumber': ayahNumber,
        'juzNumber': juzNumber,
        'hizbNumber': hizbNumber,
        'savedAt': savedAt.toIso8601String(),
        'totalReadingSeconds': totalReadingSeconds,
      };

  factory MushafPageModel.fromJson(Map<String, dynamic> json) =>
      MushafPageModel(
        pageNumber: (json['pageNumber'] as num?)?.toInt() ?? 1,
        surahNumber: (json['surahNumber'] as num?)?.toInt() ?? 1,
        surahName: json['surahName'] as String? ?? 'Al-Fatihah',
        ayahNumber: (json['ayahNumber'] as num?)?.toInt() ?? 1,
        juzNumber: (json['juzNumber'] as num?)?.toInt() ?? 1,
        hizbNumber: (json['hizbNumber'] as num?)?.toInt() ?? 1,
        savedAt: DateTime.tryParse(json['savedAt'] as String? ?? '') ??
            DateTime.now(),
        totalReadingSeconds:
            (json['totalReadingSeconds'] as num?)?.toInt() ?? 0,
      );

  MushafPageModel copyWith({
    int? pageNumber,
    int? surahNumber,
    String? surahName,
    int? ayahNumber,
    int? juzNumber,
    int? hizbNumber,
    DateTime? savedAt,
    int? totalReadingSeconds,
  }) =>
      MushafPageModel(
        pageNumber: pageNumber ?? this.pageNumber,
        surahNumber: surahNumber ?? this.surahNumber,
        surahName: surahName ?? this.surahName,
        ayahNumber: ayahNumber ?? this.ayahNumber,
        juzNumber: juzNumber ?? this.juzNumber,
        hizbNumber: hizbNumber ?? this.hizbNumber,
        savedAt: savedAt ?? this.savedAt,
        totalReadingSeconds: totalReadingSeconds ?? this.totalReadingSeconds,
      );
}

// ============================================================
// READING STREAK MODEL
// ============================================================

class ReadingStreakModel {
  final int currentStreak; // Days in a row
  final int longestStreak; // Best ever streak
  final DateTime? lastReadDate;
  final int totalDaysRead;

  const ReadingStreakModel({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastReadDate,
    this.totalDaysRead = 0,
  });

  Map<String, dynamic> toJson() => {
        'currentStreak': currentStreak,
        'longestStreak': longestStreak,
        'lastReadDate': lastReadDate?.toIso8601String(),
        'totalDaysRead': totalDaysRead,
      };

  factory ReadingStreakModel.fromJson(Map<String, dynamic> json) =>
      ReadingStreakModel(
        currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
        longestStreak: (json['longestStreak'] as num?)?.toInt() ?? 0,
        lastReadDate: json['lastReadDate'] != null
            ? DateTime.tryParse(json['lastReadDate'] as String)
            : null,
        totalDaysRead: (json['totalDaysRead'] as num?)?.toInt() ?? 0,
      );

  ReadingStreakModel copyWith({
    int? currentStreak,
    int? longestStreak,
    DateTime? lastReadDate,
    int? totalDaysRead,
  }) =>
      ReadingStreakModel(
        currentStreak: currentStreak ?? this.currentStreak,
        longestStreak: longestStreak ?? this.longestStreak,
        lastReadDate: lastReadDate ?? this.lastReadDate,
        totalDaysRead: totalDaysRead ?? this.totalDaysRead,
      );
}

// ============================================================
// MAIN REPOSITORY
// ============================================================

class ReadingProgressRepository {
  ReadingProgressRepository._();
  static final ReadingProgressRepository instance =
      ReadingProgressRepository._();

  // SharedPreferences Keys
  static const String _keyMushafPage = 'mushaf_current_page';
  static const String _keyLastRead = 'last_read_position';
  static const String _keyStreak = 'reading_streak';
  static const String _keyTotalPages = 'total_pages_read';
  static const String _keyReadingHistory = 'reading_history';
  static const String _keyDailyGoal = 'daily_reading_goal_pages';
  static const String _keyTodayPages = 'today_pages_read';
  static const String _keyTodayDate = 'today_date';

  SharedPreferences? _prefs;

  // ── Initialize ─────────────────────────────────────────────
  Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
    debugPrint('[READING_PROGRESS] ✅ Repository initialized');
  }

  Future<SharedPreferences> get _p async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ============================================================
  // SAVE CURRENT PAGE (Auto-called when page changes)
  // ============================================================

  Future<void> saveCurrentPage(MushafPageModel page) async {
    try {
      final prefs = await _p;
      final json = jsonEncode(page.toJson());
      await prefs.setString(_keyMushafPage, json);

      // Update reading history
      await _updateReadingHistory(page);

      // Update streak
      await _updateStreak();

      // Update today's pages
      await _updateTodayPages();

      debugPrint('[READING_PROGRESS] 💾 Saved page ${page.pageNumber}');
    } catch (e) {
      debugPrint('[READING_PROGRESS] ❌ Save error: $e');
    }
  }

  // ============================================================
  // GET CURRENT PAGE (Returns null if never read)
  // ============================================================

  Future<MushafPageModel?> getCurrentPage() async {
    try {
      final prefs = await _p;
      final json = prefs.getString(_keyMushafPage);
      if (json == null) return null;
      return MushafPageModel.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (e) {
      debugPrint('[READING_PROGRESS] ❌ Get page error: $e');
      return null;
    }
  }

  // ============================================================
  // SAVE LAST READ (Surah/Ayah level — reuses existing model)
  // ============================================================

  Future<void> saveLastRead(LastReadModel lastRead) async {
    try {
      final prefs = await _p;
      await prefs.setString(_keyLastRead, jsonEncode(lastRead.toJson()));
      debugPrint(
          '[READING_PROGRESS] 💾 LastRead: ${lastRead.surahName} ${lastRead.ayahNumber}');
    } catch (e) {
      debugPrint('[READING_PROGRESS] ❌ LastRead save error: $e');
    }
  }

  // ============================================================
  // GET LAST READ
  // ============================================================

  Future<LastReadModel?> getLastRead() async {
    try {
      final prefs = await _p;
      final json = prefs.getString(_keyLastRead);
      if (json == null) return null;
      return LastReadModel.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (e) {
      return null;
    }
  }

  // ============================================================
  // READING STREAK
  // ============================================================

  Future<ReadingStreakModel> getStreak() async {
    try {
      final prefs = await _p;
      final json = prefs.getString(_keyStreak);
      if (json == null) return const ReadingStreakModel();
      return ReadingStreakModel.fromJson(
          jsonDecode(json) as Map<String, dynamic>);
    } catch (e) {
      return const ReadingStreakModel();
    }
  }

  Future<void> _updateStreak() async {
    try {
      final prefs = await _p;
      final streak = await getStreak();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      ReadingStreakModel updated;

      if (streak.lastReadDate == null) {
        // First time reading
        updated = ReadingStreakModel(
          currentStreak: 1,
          longestStreak: 1,
          lastReadDate: today,
          totalDaysRead: 1,
        );
      } else {
        final lastDate = DateTime(
          streak.lastReadDate!.year,
          streak.lastReadDate!.month,
          streak.lastReadDate!.day,
        );
        final diff = today.difference(lastDate).inDays;

        if (diff == 0) {
          // Same day — no change
          updated = streak;
        } else if (diff == 1) {
          // Consecutive day — increment streak
          final newStreak = streak.currentStreak + 1;
          updated = streak.copyWith(
            currentStreak: newStreak,
            longestStreak: newStreak > streak.longestStreak
                ? newStreak
                : streak.longestStreak,
            lastReadDate: today,
            totalDaysRead: streak.totalDaysRead + 1,
          );
        } else {
          // Streak broken
          updated = streak.copyWith(
            currentStreak: 1,
            lastReadDate: today,
            totalDaysRead: streak.totalDaysRead + 1,
          );
        }
      }

      await prefs.setString(_keyStreak, jsonEncode(updated.toJson()));
    } catch (e) {
      debugPrint('[READING_PROGRESS] ❌ Streak update error: $e');
    }
  }

  // ============================================================
  // READING HISTORY (Last 10 sessions)
  // ============================================================

  Future<List<MushafPageModel>> getReadingHistory() async {
    try {
      final prefs = await _p;
      final json = prefs.getString(_keyReadingHistory);
      if (json == null) return [];

      final list = jsonDecode(json) as List<dynamic>;
      return list
          .map((e) => MushafPageModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _updateReadingHistory(MushafPageModel page) async {
    try {
      final prefs = await _p;
      final history = await getReadingHistory();

      // Add new entry at start
      final updated = [page, ...history];

      // Keep only last 10 sessions
      final trimmed = updated.take(10).toList();

      await prefs.setString(_keyReadingHistory,
          jsonEncode(trimmed.map((e) => e.toJson()).toList()));
    } catch (e) {
      debugPrint('[READING_PROGRESS] ❌ History update error: $e');
    }
  }

  // ============================================================
  // TODAY'S READING GOAL
  // ============================================================

  Future<int> getDailyGoalPages() async {
    final prefs = await _p;
    return prefs.getInt(_keyDailyGoal) ?? 5; // Default 5 pages/day
  }

  Future<void> setDailyGoalPages(int pages) async {
    final prefs = await _p;
    await prefs.setInt(_keyDailyGoal, pages);
  }

  Future<int> getTodayPagesRead() async {
    try {
      final prefs = await _p;
      final savedDate = prefs.getString(_keyTodayDate);
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month}-${today.day}';

      // Reset if new day
      if (savedDate != todayStr) {
        await prefs.setString(_keyTodayDate, todayStr);
        await prefs.setInt(_keyTodayPages, 0);
        return 0;
      }

      return prefs.getInt(_keyTodayPages) ?? 0;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _updateTodayPages() async {
    try {
      final prefs = await _p;
      final today = DateTime.now();
      final todayStr = '${today.year}-${today.month}-${today.day}';
      final savedDate = prefs.getString(_keyTodayDate);

      if (savedDate != todayStr) {
        await prefs.setString(_keyTodayDate, todayStr);
        await prefs.setInt(_keyTodayPages, 1);
      } else {
        final current = prefs.getInt(_keyTodayPages) ?? 0;
        await prefs.setInt(_keyTodayPages, current + 1);
      }
    } catch (e) {
      debugPrint('[READING_PROGRESS] ❌ Today pages error: $e');
    }
  }

  // ============================================================
  // TOTAL STATS
  // ============================================================

  Future<int> getTotalPagesRead() async {
    final prefs = await _p;
    return prefs.getInt(_keyTotalPages) ?? 0;
  }

  Future<void> incrementTotalPages() async {
    final prefs = await _p;
    final current = prefs.getInt(_keyTotalPages) ?? 0;
    await prefs.setInt(_keyTotalPages, current + 1);
  }

  // ============================================================
  // CLEAR ALL (for testing)
  // ============================================================

  Future<void> clearAll() async {
    final prefs = await _p;
    await prefs.remove(_keyMushafPage);
    await prefs.remove(_keyLastRead);
    await prefs.remove(_keyStreak);
    await prefs.remove(_keyTotalPages);
    await prefs.remove(_keyReadingHistory);
    await prefs.remove(_keyTodayPages);
    await prefs.remove(_keyTodayDate);
    debugPrint('[READING_PROGRESS] 🗑️ All data cleared');
  }
}
