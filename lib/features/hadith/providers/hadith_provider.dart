// lib/features/hadith/providers/hadith_provider.dart

// ============================================================
// QIBRA AI — HADITH PROVIDER
// Version: 2.0.0 — Local Database Integration
// Description: Uses local database (34,395 hadiths).
//              API service as fallback for future features.
// ============================================================

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/hadith_models.dart';
import '../data/services/hadith_api_service.dart';
import '../data/services/hadith_database_service.dart';

// ============================================================
// SECTION 1: DATABASE SERVICE PROVIDER
// ============================================================

/// Local hadith database — 34,395 authentic hadiths
final hadithDatabaseProvider = Provider<HadithDatabaseService>((ref) {
  final service = HadithDatabaseService();

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// API service provider (fallback for future features)
final hadithApiServiceProvider = Provider<HadithApiService>((ref) {
  return HadithApiService();
});

// ============================================================
// SECTION 2: DATABASE INITIALIZATION
// ============================================================

/// Initialize database on app start
/// Loads all 6 books from local JSON files
final hadithDatabaseInitProvider = FutureProvider<bool>((ref) async {
  final db = ref.watch(hadithDatabaseProvider);
  await db.initialize();
  return db.isInitialized;
});

// ============================================================
// SECTION 3: BOOKS PROVIDERS
// ============================================================

/// All hadith books with metadata
final hadithBooksProvider = FutureProvider<List<HadithBook>>((ref) async {
  // Ensure database is initialized
  await ref.watch(hadithDatabaseInitProvider.future);

  final db = ref.watch(hadithDatabaseProvider);
  final bookInfos = db.getAllBookInfos();

  // Convert LocalBookInfo to HadithBook using existing model
  return bookInfos.map((info) {
    final popularBook = popularHadithBooks.firstWhere(
      (b) => b.slug.contains(info.slug) || info.slug.contains(b.id),
      orElse: () => popularHadithBooks.first,
    );

    return popularBook.copyWith(
      slug: info.slug,
      name: info.name,
      totalHadiths: info.totalHadiths,
      totalChapters: info.sections.length,
    );
  }).toList();
});

/// Single book by slug
final hadithBookProvider =
    FutureProvider.family<HadithBook?, String>((ref, slug) async {
  final books = await ref.watch(hadithBooksProvider.future);
  try {
    return books.firstWhere((b) => b.slug == slug);
  } catch (_) {
    return null;
  }
});

// ============================================================
// SECTION 4: DAILY HADITH PROVIDER
// ============================================================

/// Convert LocalHadith to HadithModel
HadithModel _localToHadithModel(LocalHadith local) {
  return HadithModel(
    id: local.id,
    hadithNumber: local.hadithNumber,
    bookSlug: local.bookSlug,
    bookName: local.bookName,
    chapterNumber: local.bookNumber,
    chapterName: local.chapterName,
    textArabic: local.textArabic,
    textEnglish: local.textEnglish,
    textUrdu: local.textUrdu,
    grade: HadithGrade.fromString(local.grade),
    narrator: const HadithNarrator(name: ''),
    reference: local.displayReference,
  );
}

/// Today's hadith (deterministic — same all day)
final dailyHadithProvider = FutureProvider<HadithModel?>((ref) async {
  await ref.watch(hadithDatabaseInitProvider.future);
  final db = ref.watch(hadithDatabaseProvider);
  final local = db.getDailyHadith();
  if (local == null) return null;
  return _localToHadithModel(local);
});

/// Random hadith
final randomHadithProvider = FutureProvider<HadithModel?>((ref) async {
  await ref.watch(hadithDatabaseInitProvider.future);
  final db = ref.watch(hadithDatabaseProvider);
  final local = db.getRandomHadith();
  if (local == null) return null;
  return _localToHadithModel(local);
});

// ============================================================
// SECTION 5: CHAPTERS PROVIDER
// ============================================================

final hadithChaptersProvider =
    FutureProvider.family<List<HadithChapter>, String>((ref, bookSlug) async {
  await ref.watch(hadithDatabaseInitProvider.future);
  final db = ref.watch(hadithDatabaseProvider);
  final bookInfo = db.getBookInfo(bookSlug);

  if (bookInfo == null) return [];

  return bookInfo.sections.entries.map((entry) {
    final chapterNum = int.tryParse(entry.key) ?? 0;
    return HadithChapter(
      id: 'ch_${bookSlug}_$chapterNum',
      number: chapterNum,
      name: entry.value,
      nameArabic: '',
      bookSlug: bookSlug,
      hadithCount: db.getChapterHadiths(bookSlug, chapterNum).length,
    );
  }).toList();
});

// ============================================================
// SECTION 6: HADITHS PROVIDER
// ============================================================

class HadithsParams {
  final String bookSlug;
  final int? chapterNumber;
  final int page;

  const HadithsParams({
    required this.bookSlug,
    this.chapterNumber,
    this.page = 1,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HadithsParams &&
        other.bookSlug == bookSlug &&
        other.chapterNumber == chapterNumber &&
        other.page == page;
  }

  @override
  int get hashCode => Object.hash(bookSlug, chapterNumber, page);
}

final hadithsProvider = FutureProvider.family<List<HadithModel>, HadithsParams>(
    (ref, params) async {
  await ref.watch(hadithDatabaseInitProvider.future);
  final db = ref.watch(hadithDatabaseProvider);

  List<LocalHadith> locals;
  if (params.chapterNumber != null) {
    locals = db.getChapterHadiths(params.bookSlug, params.chapterNumber!);
  } else {
    locals = db.getHadiths(params.bookSlug);
    // Pagination — 25 per page
    final start = (params.page - 1) * 25;
    final end = (start + 25).clamp(0, locals.length);
    if (start >= locals.length) {
      locals = [];
    } else {
      locals = locals.sublist(start, end);
    }
  }

  return locals.map(_localToHadithModel).toList();
});

// ============================================================
// SECTION 7: SEARCH PROVIDER
// ============================================================

final hadithSearchQueryProvider = StateProvider<String>((ref) => '');
final hadithSearchBookFilterProvider = StateProvider<String?>((ref) => null);

final hadithSearchResultsProvider =
    FutureProvider<List<HadithSearchResult>>((ref) async {
  final query = ref.watch(hadithSearchQueryProvider);
  final bookFilter = ref.watch(hadithSearchBookFilterProvider);

  if (query.trim().isEmpty) return [];

  await ref.watch(hadithDatabaseInitProvider.future);
  final db = ref.watch(hadithDatabaseProvider);
  final results = db.search(query, bookSlug: bookFilter, maxResults: 50);

  return results.map((r) {
    return HadithSearchResult(
      hadith: _localToHadithModel(r.hadith),
      matchType: _matchTypeFromString(r.matchedIn),
      matchedText: query,
      relevanceScore: r.relevance,
    );
  }).toList();
});

HadithMatchType _matchTypeFromString(String s) {
  switch (s) {
    case 'arabic':
      return HadithMatchType.arabic;
    case 'urdu':
      return HadithMatchType.urdu;
    default:
      return HadithMatchType.english;
  }
}

// ============================================================
// SECTION 8: BOOKMARKS NOTIFIER
// ============================================================

class HadithBookmarksNotifier extends StateNotifier<List<HadithBookmark>> {
  HadithBookmarksNotifier() : super([]);

  void addBookmark(HadithModel hadith, {String? note}) {
    if (state.any((b) => b.hadithId == hadith.id)) return;

    final bookmark = HadithBookmark(
      id: 'bm_${DateTime.now().millisecondsSinceEpoch}',
      hadithId: hadith.id,
      bookSlug: hadith.bookSlug,
      bookName: hadith.bookName,
      hadithNumber: hadith.hadithNumber,
      chapterName: hadith.chapterName,
      textPreview: hadith.shortText,
      createdAt: DateTime.now(),
      note: note,
    );

    state = [...state, bookmark];
  }

  void removeBookmark(String hadithId) {
    state = state.where((b) => b.hadithId != hadithId).toList();
  }

  bool isBookmarked(String hadithId) {
    return state.any((b) => b.hadithId == hadithId);
  }

  void toggleBookmark(HadithModel hadith) {
    if (isBookmarked(hadith.id)) {
      removeBookmark(hadith.id);
    } else {
      addBookmark(hadith);
    }
  }

  void clearAll() {
    state = [];
  }
}

final hadithBookmarksProvider =
    StateNotifierProvider<HadithBookmarksNotifier, List<HadithBookmark>>((ref) {
  return HadithBookmarksNotifier();
});

// ============================================================
// SECTION 9: CONVENIENCE PROVIDERS
// ============================================================

final isHadithBookmarkedProvider =
    Provider.family<bool, String>((ref, hadithId) {
  final bookmarks = ref.watch(hadithBookmarksProvider);
  return bookmarks.any((b) => b.hadithId == hadithId);
});

final bookmarkCountProvider = Provider<int>((ref) {
  return ref.watch(hadithBookmarksProvider).length;
});

/// Database statistics
final hadithStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final db = ref.watch(hadithDatabaseProvider);
  return db.statistics;
});
