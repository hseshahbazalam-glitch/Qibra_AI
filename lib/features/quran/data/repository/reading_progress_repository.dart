// lib/features/quran/data/repository/reading_progress_repository.dart
// ============================================================
// QIBRA AI — Reading Progress Repository
// Auto-saves reading position — No button needed
// Uses: SharedPreferences (already in pubspec)
// Reuses: LastReadModel (existing model)
// ============================================================

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/quran_models.dart';
import 'quran_meta.dart';

// ============================================================
// KHATM COVERAGE — honest high-water metric (Pass Q2)
// ============================================================
// METRIC DEFINITION (the one, exact — mirrors the tests):
//  • An ayah is SEEN when the reader records it: its options card was
//    opened, the recitation player advanced onto it, or it is the
//    visit's final last-read position (the documented tracking signals
//    — nothing more, nothing invented).
//  • Per surah, the HIGH-WATER is the longest CONTIGUOUS run 1..k of
//    seen ayahs. Seen ayahs beyond a gap NEVER count — they wait in
//    the frontier until the gap fills (explicit no-fake rule).
//  • A surah counts toward the ring (X) only when its contiguous run
//    reaches QuranMeta.ayahCount(surah) — i.e. reached the last ayah.
//  • Coverage Z = Σ contiguous runs / 6236 — displayed EXACTLY as
//    high-water coverage, never as 'completed'.
// Storage: one SharedPreferences JSON map, per surah {c, s:[...]} —
// bounded by what the user actually touched; no 6236-entry structure.
class KhatmStats {
  const KhatmStats({
    required this.openedSurahs,
    required this.surahsReachedEnd,
    required this.ayahsHighWater,
  });

  const KhatmStats.empty()
      : openedSurahs = 0,
        surahsReachedEnd = 0,
        ayahsHighWater = 0;

  /// Surahs with ANY seen ayah (kept for honest context; the ring's X
  /// is [surahsReachedEnd], per the strict definition above).
  final int openedSurahs;
  final int surahsReachedEnd;
  final int ayahsHighWater;

  static int get totalSurahs => QuranMeta.totalSurahs;
  static int get totalAyahs => QuranMeta.totalAyahs;

  /// 0.0–1.0 honest fraction of the WHOLE Quran (6236 ayahs).
  double get coverageFraction =>
      (ayahsHighWater / totalAyahs).clamp(0.0, 1.0);
}

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

  // (Removed dead getters timeAgo / readingTimeText — zero references
  // in lib/ or test/; savedAt remains stored for the model contract.)

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
    debugPrint('[READING_PROGRESS] repository initialized');
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

      debugPrint('[READING_PROGRESS] saved page ${page.pageNumber}');
    } catch (e) {
      debugPrint('[READING_PROGRESS] save error: $e');
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
      debugPrint('[READING_PROGRESS] get page error: $e');
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
      debugPrint('[READING_PROGRESS] LastRead saved');
    } catch (e) {
      debugPrint('[READING_PROGRESS] last-read save error: $e');
    }
  }

  Future<void> clearLastRead() async {
    try {
      final prefs = await _p;
      await prefs.remove(_keyLastRead);
    } catch (e) {
      debugPrint('[READING_PROGRESS] last-read clear error: $e');
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
      debugPrint('[READING_PROGRESS] streak update error: $e');
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
      debugPrint('[READING_PROGRESS] history update error: $e');
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
      debugPrint('[READING_PROGRESS] today pages error: $e');
    }
  }

  // ============================================================
  // PASS Q2 — PER-SURAH AYAH HIGH-WATER
  // ============================================================

  static const String _keyAyahHighWater = 'ayah_high_water_v1';

  /// null = not loaded yet; entries are (c: contiguous run, seen: the
  /// frontier of seen ayahs BEYOND the run, waiting to close gaps).
  Map<int, ({int c, Set<int> seen})>? _hwCache;

  /// PURE absorb step (unit-tested directly): mark [ayah] seen against
  /// a surah's record and grow the contiguous run as far as it reaches.
  /// A gap left open by [ayah] stops the growth exactly there.
  static ({int c, Set<int> seen}) hwApplySeen({
    required int contiguous,
    required Set<int> seen,
    required int ayah,
  }) {
    var c = contiguous;
    final s = Set<int>.of(seen)..add(ayah);
    while (s.remove(c + 1)) {
      c++;
    }
    return (c: c, seen: s);
  }

  /// PURE tally over contiguous-run snapshots — the ring's numbers are
  /// defined as EXACTLY this (coverage X/Z rules above).
  static KhatmStats khatmFrom(Map<int, ({int c, Set<int> seen})> perSurah) {
    var reachedEnd = 0;
    var highWater = 0;
    var opened = 0;
    perSurah.forEach((surah, e) {
      if (e.c > 0 || e.seen.isNotEmpty) opened++;
      highWater += e.c;
      if (e.c >= QuranMeta.ayahCount(surah)) reachedEnd++;
    });
    return KhatmStats(
      openedSurahs: opened,
      surahsReachedEnd: reachedEnd,
      ayahsHighWater: highWater,
    );
  }

  /// PURE disk parse (public for direct testing): tolerant of garbage —
  /// stale/foreign entries are DROPPED, never trusted, never fatal.
  static Map<int, ({int c, Set<int> seen})> parseHighWater(String? raw) {
    final map = <int, ({int c, Set<int> seen})>{};
    try {
      if (raw == null || raw.isEmpty) return map;
      final json = jsonDecode(raw);
      if (json is Map<String, dynamic>) {
        json.forEach((k, v) {
          final surah = int.tryParse(k);
          if (surah == null ||
              surah < 1 ||
              surah > QuranMeta.totalSurahs ||
              v is! Map) {
            return; // stale/foreign entry: dropped, never trusted
          }
          final c = (v['c'] as num?)?.toInt() ?? 0;
          final maxA = QuranMeta.ayahCount(surah);
          if (c > maxA) return; // impossible → garbage → the WHOLE entry
          // is untrusted (a clamped 'full surah' would fake coverage)
          final seenRaw = v['s'];
          final seen = <int>{
            if (seenRaw is List)
              for (final e in seenRaw)
                if (e is num && e.toInt() > 0 && e.toInt() <= maxA)
                  e.toInt(),
          };
          map[surah] = (c: c < 0 ? 0 : c, seen: seen);
        });
      }
    } catch (_) {
      // Unparseable blob: start clean rather than crash the section.
      return <int, ({int c, Set<int> seen})>{};
    }
    return map;
  }

  Future<Map<int, ({int c, Set<int> seen})>> _hwLoad() async {
    if (_hwCache != null) return _hwCache!;
    String? raw;
    try {
      final prefs = await _p;
      raw = prefs.getString(_keyAyahHighWater);
    } catch (e) {
      debugPrint('[READING_PROGRESS] high-water load error: $e');
    }
    return _hwCache = parseHighWater(raw);
  }

  /// Mark one ayah seen for [surah] (persisted only when it actually
  /// changes the record — re-taps / repeat loops are no-ops, no churn).
  Future<void> markAyahSeen(int surah, int ayah) async {
    if (surah < 1 || surah > QuranMeta.totalSurahs || ayah < 1) return;
    if (ayah > QuranMeta.ayahCount(surah)) return; // impossible → ignored
    try {
      final map = await _hwLoad();
      final prev = map[surah];
      final had = prev != null && (ayah <= prev.c || prev.seen.contains(ayah));
      if (had) return; // already credited — nothing to write
      final base = prev ?? (c: 0, seen: const <int>{});
      final next = hwApplySeen(
          contiguous: base.c, seen: base.seen, ayah: ayah);
      map[surah] = next;
      final prefs = await _p;
      await prefs.setString(_keyAyahHighWater, jsonEncode({
        for (final e in map.entries)
          '${e.key}': {
            'c': e.value.c,
            's': e.value.seen.toList()..sort(),
          },
      }));
    } catch (e) {
      debugPrint('[READING_PROGRESS] high-water mark error: $e');
    }
  }

  /// Fresh stats straight from the (cached, disk-backed) store.
  Future<KhatmStats> getKhatmStats() async => khatmFrom(await _hwLoad());

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
    await prefs.remove(_keyAyahHighWater);
    _hwCache = null;
    debugPrint('[READING_PROGRESS] all data cleared');
  }
}
