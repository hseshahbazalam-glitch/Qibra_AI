// lib/features/hadith/providers/hadith_provider.dart
// ============================================================
// QIBRA AI — HADITH PROVIDER
// Version: 2.1.0 — Singleton Database Integration with Instant Load
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/hadith_models.dart';
import '../data/services/hadith_database_service.dart';

// ============================================================
// SECTION 1: DATABASE SERVICE PROVIDER
// ============================================================

final hadithDatabaseProvider = Provider<HadithDatabaseService>((ref) {
  return HadithDatabaseService();
});

// ============================================================
// SECTION 2: DATABASE INITIALIZATION
// ============================================================

final hadithDatabaseInitProvider = FutureProvider<bool>((ref) async {
  final db = ref.watch(hadithDatabaseProvider);
  if (!db.isInitialized) {
    await db.initialize();
  }
  return db.isInitialized;
});

// ============================================================
// SECTION 3: BOOKS PROVIDERS
// ============================================================

final hadithBooksProvider = FutureProvider<List<HadithBook>>((ref) async {
  await ref.watch(hadithDatabaseInitProvider.future);

  final db = ref.watch(hadithDatabaseProvider);
  final bookInfos = db.getAllBookInfos();

  return bookInfos.map((info) {
    final popularBook = popularHadithBooks.firstWhere(
      (b) => b.slug.contains(info.slug) || info.slug.contains(b.id),
      orElse: () => HadithBook(
        id: info.slug,
        slug: info.slug,
        name: info.name,
        nameArabic: '',
        author: '—',
        authorArabic: '',
        totalHadiths: info.totalHadiths,
        totalChapters: info.sections.length,
        description: 'Authentic Hadith collection',
        color: const Color(0xFF123F36),
      ),
    );

    return popularBook.copyWith(
      slug: info.slug,
      name: info.name,
      totalHadiths: info.totalHadiths,
      totalChapters: info.sections.length,
    );
  }).toList();
});

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
// SECTION 4: CONVERTERS & HELPERS
// ============================================================

/// Maps a [LocalHadith] to its canonical [HadithGrade].
///
/// Books of the Kutub al-Sittah + Muwatta' contain a mix of grades, so we
/// never blanket-label everything as Sahih. Only Sahih al-Bukhari and Sahih
/// Muslim are universally graded Sahih across their entire collections; all
/// other books default to [HadithGrade.unknown] when the per-hadith tag is
/// absent, so the UI can show "Not graded" instead of a misleading label.
HadithGrade gradeForLocalHadith(LocalHadith local) {
  final rawGrade = local.grade.trim();

  if (rawGrade.isNotEmpty && rawGrade.toLowerCase() != 'unknown') {
    return HadithGrade.fromString(rawGrade);
  }

  // Only the two "Sahih" collections are authentic by consensus.
  if (local.bookSlug == 'bukhari' || local.bookSlug == 'muslim') {
    return HadithGrade.sahih;
  }

  return HadithGrade.unknown;
}

HadithModel localToHadithModel(LocalHadith local) {
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
    grade: gradeForLocalHadith(local),
    narrator: const HadithNarrator(name: ''),
    reference: local.displayReference,
  );
}

final dailyHadithProvider = FutureProvider<HadithModel?>((ref) async {
  await ref.watch(hadithDatabaseInitProvider.future);
  final db = ref.watch(hadithDatabaseProvider);
  final local = db.getDailyHadith();
  if (local == null) return null;
  return localToHadithModel(local);
});

final randomHadithProvider = FutureProvider<HadithModel?>((ref) async {
  await ref.watch(hadithDatabaseInitProvider.future);
  final db = ref.watch(hadithDatabaseProvider);
  final local = db.getRandomHadith();
  if (local == null) return null;
  return localToHadithModel(local);
});

final featuredHadithsProvider =
    FutureProvider.family<List<HadithModel>, String?>((ref, bookSlug) async {
  await ref.watch(hadithDatabaseInitProvider.future);
  final db = ref.watch(hadithDatabaseProvider);
  final locals = db.getFeaturedHadiths(limit: 10, bookSlug: bookSlug);
  return locals.map(localToHadithModel).toList();
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
// SECTION 6: HADITHS PROVIDER (With Pagination)
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
  if (params.chapterNumber != null && params.chapterNumber! > 0) {
    locals = db.getChapterHadiths(params.bookSlug, params.chapterNumber!);
  } else {
    locals = db.getHadiths(params.bookSlug);
    final start = (params.page - 1) * 50;
    final end = (start + 50).clamp(0, locals.length);
    if (start >= locals.length) {
      locals = [];
    } else {
      locals = locals.sublist(start, end);
    }
  }

  return locals.map(localToHadithModel).toList();
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
      hadith: localToHadithModel(r.hadith),
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

final hadithStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final db = ref.watch(hadithDatabaseProvider);
  return db.statistics;
});
