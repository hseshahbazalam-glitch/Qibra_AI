// lib/features/quran/providers/quran_provider.dart

// ============================================================
// QIBRA AI — QURAN PROVIDERS (v1.0)
// Phase: 8.2 — Real Quran Data Integration
// ============================================================
// Description: Riverpod providers for Quran data
//
// Providers:
//   1. quranRepositoryProvider - Repository instance
//   2. quranInitProvider - Auto-initialize on app start
//   3. allSurahsProvider - All 114 surahs metadata
//   4. surahDetailProvider - Get specific surah with ayahs
//   5. randomAyahProvider - Daily verse (auto-rotate)
//   6. popularSurahsProvider - Recommended surahs
//   7. meccanSurahsProvider - Meccan only
//   8. medinanSurahsProvider - Medinan only
//   9. searchQuranProvider - Search Quran
//   10. searchSurahProvider - Search surahs by name
//   11. currentSurahIndexProvider - Selected surah state
//   12. lastReadProvider - Last read position
//   13. bookmarksProvider - User bookmarks
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/quran_models.dart';
import '../data/repository/quran_repository.dart';

// ============================================================
// SECTION 1 — REPOSITORY PROVIDER
// ============================================================

/// Repository instance provider (singleton)
final quranRepositoryProvider = Provider<QuranRepository>((ref) {
  return QuranRepository();
});

// ============================================================
// SECTION 2 — INITIALIZATION PROVIDER
// ============================================================

/// Auto-initialize Quran data on first access
///
/// Use this in splash screen or main.dart to preload data
final quranInitProvider = FutureProvider<bool>((ref) async {
  final repository = ref.read(quranRepositoryProvider);
  await repository.initialize();
  return true;
});

// ============================================================
// SECTION 3 — SURAHS LIST PROVIDERS
// ============================================================

/// Get all 114 surahs (metadata only — fast!)
final allSurahsProvider = FutureProvider<List<SurahInfoModel>>((ref) async {
  final repository = ref.read(quranRepositoryProvider);
  return await repository.getAllSurahsInfo();
});

/// Get popular/recommended surahs (8 surahs)
final popularSurahsProvider = FutureProvider<List<SurahInfoModel>>((ref) async {
  final repository = ref.read(quranRepositoryProvider);
  return await repository.getPopularSurahs();
});

/// Get Meccan surahs only
final meccanSurahsProvider = FutureProvider<List<SurahInfoModel>>((ref) async {
  final repository = ref.read(quranRepositoryProvider);
  return await repository.getMeccanSurahs();
});

/// Get Medinan surahs only
final medinanSurahsProvider = FutureProvider<List<SurahInfoModel>>((ref) async {
  final repository = ref.read(quranRepositoryProvider);
  return await repository.getMedinanSurahs();
});

// ============================================================
// SECTION 4 — SPECIFIC SURAH PROVIDERS
// ============================================================

/// Get specific surah by number (with all ayahs)
///
/// Usage:
/// ```dart
/// final surahAsync = ref.watch(surahDetailProvider(1)); // Al-Fatihah
/// ```
final surahDetailProvider =
    FutureProvider.family<SurahModel?, int>((ref, surahNumber) async {
  final repository = ref.read(quranRepositoryProvider);
  return await repository.getSurah(surahNumber);
});

/// Get specific surah info (metadata only)
final surahInfoProvider =
    FutureProvider.family<SurahInfoModel?, int>((ref, surahNumber) async {
  final repository = ref.read(quranRepositoryProvider);
  return await repository.getSurahInfo(surahNumber);
});

/// Get specific ayah
final ayahProvider = FutureProvider.family<AyahModel?, ({int surah, int ayah})>(
    (ref, params) async {
  final repository = ref.read(quranRepositoryProvider);
  return await repository.getAyah(params.surah, params.ayah);
});

// ============================================================
// SECTION 5 — RANDOM/DAILY VERSE PROVIDERS
// ============================================================

/// Get random ayah (for daily verse)
///
/// Refreshes when invalidated
final randomAyahProvider = FutureProvider<AyahModel?>((ref) async {
  final repository = ref.read(quranRepositoryProvider);
  return await repository.getRandomAyah();
});

/// Auto-refreshing random ayah (changes every N seconds)
///
/// Use this for auto-rotating daily verse
final autoRotatingAyahProvider =
    StreamProvider.autoDispose<AyahModel?>((ref) async* {
  final repository = ref.read(quranRepositoryProvider);

  // Yield initial ayah
  yield await repository.getRandomAyah();

  // Rotate every 10 seconds
  while (true) {
    await Future.delayed(const Duration(seconds: 10));
    yield await repository.getRandomAyah();
  }
});

// ============================================================
// SECTION 6 — SEARCH PROVIDERS
// ============================================================

/// Search state notifier
class SearchState {
  final String query;
  final List<SearchResultModel> results;
  final bool isLoading;
  final String? error;

  const SearchState({
    this.query = '',
    this.results = const [],
    this.isLoading = false,
    this.error,
  });

  SearchState copyWith({
    String? query,
    List<SearchResultModel>? results,
    bool? isLoading,
    String? error,
  }) {
    return SearchState(
      query: query ?? this.query,
      results: results ?? this.results,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Search state controller
class SearchNotifier extends StateNotifier<SearchState> {
  final QuranRepository _repository;

  SearchNotifier(this._repository) : super(const SearchState());

  /// Perform search
  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      state = const SearchState();
      return;
    }

    state = state.copyWith(query: query, isLoading: true, error: null);

    try {
      final results = await _repository.search(query);
      state = state.copyWith(
        results: results,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Clear search
  void clear() {
    state = const SearchState();
  }
}

/// Search provider
final searchQuranProvider =
    StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  final repository = ref.read(quranRepositoryProvider);
  return SearchNotifier(repository);
});

/// Search surahs by name (simpler, for surah list)
final searchSurahProvider =
    FutureProvider.family<List<SurahInfoModel>, String>((ref, query) async {
  if (query.trim().isEmpty) return [];
  final repository = ref.read(quranRepositoryProvider);
  return await repository.searchSurahs(query);
});

// ============================================================
// SECTION 7 — CURRENT SURAH STATE
// ============================================================

/// Currently selected surah number (default: 1 = Al-Fatihah)
final currentSurahIndexProvider = StateProvider<int>((ref) => 1);

/// Currently selected ayah number
final currentAyahIndexProvider = StateProvider<int>((ref) => 1);

// ============================================================
// SECTION 8 — LAST READ POSITION
// ============================================================

/// Last read state notifier
class LastReadNotifier extends StateNotifier<LastReadModel?> {
  LastReadNotifier() : super(null);

  /// Update last read position
  void updateLastRead({
    required int surahNumber,
    required int ayahNumber,
    required String surahName,
    required int totalAyahsInSurah,
  }) {
    state = LastReadModel(
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      surahName: surahName,
      lastReadAt: DateTime.now(),
      totalAyahsInSurah: totalAyahsInSurah,
    );
  }

  /// Clear last read
  void clear() {
    state = null;
  }
}

/// Last read provider
final lastReadProvider =
    StateNotifierProvider<LastReadNotifier, LastReadModel?>((ref) {
  return LastReadNotifier();
});

// ============================================================
// SECTION 9 — BOOKMARKS
// ============================================================

/// Bookmarks state notifier
class BookmarksNotifier extends StateNotifier<List<BookmarkModel>> {
  BookmarksNotifier() : super([]);

  /// Add bookmark
  void addBookmark(BookmarkModel bookmark) {
    // Check if already bookmarked
    final existing = state.any((b) =>
        b.surahNumber == bookmark.surahNumber &&
        b.ayahNumber == bookmark.ayahNumber);
    if (existing) return;

    state = [...state, bookmark];
  }

  /// Remove bookmark
  void removeBookmark(int surahNumber, int ayahNumber) {
    state = state
        .where((b) =>
            !(b.surahNumber == surahNumber && b.ayahNumber == ayahNumber))
        .toList();
  }

  /// Toggle bookmark
  void toggleBookmark(BookmarkModel bookmark) {
    final exists = state.any((b) =>
        b.surahNumber == bookmark.surahNumber &&
        b.ayahNumber == bookmark.ayahNumber);

    if (exists) {
      removeBookmark(bookmark.surahNumber, bookmark.ayahNumber);
    } else {
      addBookmark(bookmark);
    }
  }

  /// Check if ayah is bookmarked
  bool isBookmarked(int surahNumber, int ayahNumber) {
    return state
        .any((b) => b.surahNumber == surahNumber && b.ayahNumber == ayahNumber);
  }

  /// Update note for a bookmark
  void updateNote(int surahNumber, int ayahNumber, String? note) {
    state = state.map((b) {
      if (b.surahNumber == surahNumber && b.ayahNumber == ayahNumber) {
        return b.copyWithNote(note);
      }
      return b;
    }).toList();
  }

  /// Clear all bookmarks
  void clearAll() {
    state = [];
  }
}

/// Bookmarks provider
final bookmarksProvider =
    StateNotifierProvider<BookmarksNotifier, List<BookmarkModel>>((ref) {
  return BookmarksNotifier();
});

/// Bookmarks count
final bookmarksCountProvider = Provider<int>((ref) {
  return ref.watch(bookmarksProvider).length;
});

/// Check if specific ayah is bookmarked
final isBookmarkedProvider =
    Provider.family<bool, ({int surah, int ayah})>((ref, params) {
  final bookmarks = ref.watch(bookmarksProvider);
  return bookmarks
      .any((b) => b.surahNumber == params.surah && b.ayahNumber == params.ayah);
});

// ============================================================
// SECTION 10 — READING PROGRESS
// ============================================================

/// Reading progress state notifier
class ReadingProgressNotifier extends StateNotifier<ReadingProgressModel> {
  ReadingProgressNotifier() : super(ReadingProgressModel.empty());

  /// Increment ayahs read
  void incrementAyahsRead(int count) {
    state = state.copyWith(
      totalAyahsRead: state.totalAyahsRead + count,
      lastReadDate: DateTime.now(),
    );
  }

  /// Update current position
  void updatePosition({
    required int surahNumber,
    required int juz,
  }) {
    state = state.copyWith(
      currentSurah: surahNumber,
      currentJuz: juz,
      lastReadDate: DateTime.now(),
    );
  }

  /// Increment streak
  void incrementStreak() {
    state = state.copyWith(
      daysStreak: state.daysStreak + 1,
    );
  }

  /// Add reading time
  void addReadingTime(int minutes) {
    state = state.copyWith(
      totalMinutesRead: state.totalMinutesRead + minutes,
    );
  }

  /// Reset progress
  void reset() {
    state = ReadingProgressModel.empty();
  }
}

/// Reading progress provider
final readingProgressProvider =
    StateNotifierProvider<ReadingProgressNotifier, ReadingProgressModel>((ref) {
  return ReadingProgressNotifier();
});

// ============================================================
// SECTION 11 — STATISTICS PROVIDER
// ============================================================

/// Quran statistics (surahs count, ayahs count, etc.)
final quranStatisticsProvider = Provider<Map<String, dynamic>>((ref) {
  final repository = ref.read(quranRepositoryProvider);
  return repository.statistics;
});

// ============================================================
// SECTION 12 — HELPER PROVIDERS
// ============================================================

/// Check if Quran data is loaded
final isQuranLoadedProvider = Provider<bool>((ref) {
  final initState = ref.watch(quranInitProvider);
  return initState.value ?? false;
});

/// Get current surah based on lastReadProvider
final currentReadingSurahProvider = FutureProvider<SurahModel?>((ref) async {
  final lastRead = ref.watch(lastReadProvider);
  if (lastRead == null) {
    // Default to Al-Fatihah
    final repository = ref.read(quranRepositoryProvider);
    return await repository.getSurah(1);
  }

  final repository = ref.read(quranRepositoryProvider);
  return await repository.getSurah(lastRead.surahNumber);
});

// ============================================================
// END OF FILE — quran_provider.dart
// ============================================================
