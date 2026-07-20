// lib/features/quran/providers/reading_progress_provider.dart
// ============================================================
// QIBRA AI — Reading Progress Riverpod Provider
// Connects Repository to UI
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/repository/reading_progress_repository.dart';

// ============================================================
// STATE MODEL
// ============================================================

class ReadingProgressState {
  final MushafPageModel? currentPage;
  final ReadingStreakModel streak;
  final int todayPagesRead;
  final int dailyGoalPages;
  final int totalPagesRead;
  final List<MushafPageModel> readingHistory;
  final bool isLoading;

  const ReadingProgressState({
    this.currentPage,
    this.streak = const ReadingStreakModel(),
    this.todayPagesRead = 0,
    this.dailyGoalPages = 5,
    this.totalPagesRead = 0,
    this.readingHistory = const [],
    this.isLoading = false,
  });

  // Daily goal progress (0.0 to 1.0)
  double get dailyGoalProgress {
    if (dailyGoalPages == 0) return 0.0;
    return (todayPagesRead / dailyGoalPages).clamp(0.0, 1.0);
  }

  // Has user read today?
  bool get hasReadToday {
    if (streak.lastReadDate == null) return false;
    final now = DateTime.now();
    final last = streak.lastReadDate!;
    return last.year == now.year &&
        last.month == now.month &&
        last.day == now.day;
  }

  // Overall Quran progress
  double get overallProgress {
    if (currentPage == null) return 0.0;
    return currentPage!.overallProgress;
  }

  ReadingProgressState copyWith({
    MushafPageModel? currentPage,
    ReadingStreakModel? streak,
    int? todayPagesRead,
    int? dailyGoalPages,
    int? totalPagesRead,
    List<MushafPageModel>? readingHistory,
    bool? isLoading,
  }) {
    return ReadingProgressState(
      currentPage: currentPage ?? this.currentPage,
      streak: streak ?? this.streak,
      todayPagesRead: todayPagesRead ?? this.todayPagesRead,
      dailyGoalPages: dailyGoalPages ?? this.dailyGoalPages,
      totalPagesRead: totalPagesRead ?? this.totalPagesRead,
      readingHistory: readingHistory ?? this.readingHistory,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// ============================================================
// NOTIFIER
// ============================================================

class ReadingProgressNotifier extends StateNotifier<ReadingProgressState> {
  ReadingProgressNotifier()
      : super(const ReadingProgressState(isLoading: true)) {
    _init();
  }

  final _repo = ReadingProgressRepository.instance;

  // ── Initialize — Load all saved data ──────────────────────
  Future<void> _init() async {
    await _repo.initialize();
    await _loadAll();
  }

  Future<void> _loadAll() async {
    state = state.copyWith(isLoading: true);

    final currentPage = await _repo.getCurrentPage();
    final streak = await _repo.getStreak();
    final todayPages = await _repo.getTodayPagesRead();
    final dailyGoal = await _repo.getDailyGoalPages();
    final totalPages = await _repo.getTotalPagesRead();
    final history = await _repo.getReadingHistory();

    state = ReadingProgressState(
      currentPage: currentPage,
      streak: streak,
      todayPagesRead: todayPages,
      dailyGoalPages: dailyGoal,
      totalPagesRead: totalPages,
      readingHistory: history,
      isLoading: false,
    );
  }

  // ── Save Page (called automatically when page changes) ────
  Future<void> savePage(MushafPageModel page) async {
    await _repo.saveCurrentPage(page);
    await _repo.incrementTotalPages();

    // Update state immediately (no reload needed)
    final todayPages = await _repo.getTodayPagesRead();
    final streak = await _repo.getStreak();
    final totalPages = await _repo.getTotalPagesRead();
    final history = await _repo.getReadingHistory();

    state = state.copyWith(
      currentPage: page,
      todayPagesRead: todayPages,
      streak: streak,
      totalPagesRead: totalPages,
      readingHistory: history,
    );
  }

  // ── Set Daily Goal ────────────────────────────────────────
  Future<void> setDailyGoal(int pages) async {
    await _repo.setDailyGoalPages(pages);
    state = state.copyWith(dailyGoalPages: pages);
  }

  // ── Refresh (pull to refresh) ─────────────────────────────
  Future<void> refresh() async {
    await _loadAll();
  }

  // ── Clear All (for testing/reset) ────────────────────────
  Future<void> clearAll() async {
    await _repo.clearAll();
    state = const ReadingProgressState();
  }
}

// ============================================================
// PROVIDERS
// ============================================================

// Main provider — use this everywhere
final readingProgressProvider =
    StateNotifierProvider<ReadingProgressNotifier, ReadingProgressState>(
  (ref) => ReadingProgressNotifier(),
);

// Convenience providers (derived)
final currentMushafPageProvider = Provider<MushafPageModel?>((ref) {
  return ref.watch(readingProgressProvider).currentPage;
});

final readingStreakProvider = Provider<ReadingStreakModel>((ref) {
  return ref.watch(readingProgressProvider).streak;
});

final dailyGoalProgressProvider = Provider<double>((ref) {
  return ref.watch(readingProgressProvider).dailyGoalProgress;
});

final hasReadTodayProvider = Provider<bool>((ref) {
  return ref.watch(readingProgressProvider).hasReadToday;
});

final overallQuranProgressProvider = Provider<double>((ref) {
  return ref.watch(readingProgressProvider).overallProgress;
});
