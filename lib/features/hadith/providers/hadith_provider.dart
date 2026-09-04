// lib/features/hadith/providers/hadith_provider.dart
// ============================================================
// QIBRA AI — HADITH PROVIDER
// Version: 2.1.0 — Singleton Database Integration with Instant Load
// ============================================================

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qibra_ai/core/design_system/qibra_navy.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/hadith_models.dart';
import '../data/services/hadith_database_service.dart';
import '../data/services/hadith_view_history.dart';

/// Hadith display language is independent of UI locale.
/// Only bundled languages: en, ar, ur. Hindi and others stay unresolved.
class HadithLanguageNotifier extends StateNotifier<String> {
  HadithLanguageNotifier() : super('en') {
    _load();
  }

  static const _key = 'hadith_display_language_v1';
  static const supported = {'en', 'ar', 'ur'};

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key) ?? 'en';
    state = supported.contains(saved) ? saved : 'en';
  }

  Future<void> setLanguage(String code) async {
    if (!supported.contains(code)) return;
    state = code;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, code);
  }
}

final hadithLanguageProvider =
    StateNotifierProvider<HadithLanguageNotifier, String>(
  (ref) => HadithLanguageNotifier(),
);

String? hadithTextForLanguage(HadithModel hadith, String language) {
  switch (language) {
    case 'ar':
      return hadith.hasArabic ? hadith.textArabic : null;
    case 'ur':
      return hadith.hasUrdu ? hadith.textUrdu : null;
    case 'en':
      return hadith.hasEnglish ? hadith.textEnglish : null;
    default:
      return null;
  }
}

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
        description: '',
        color: QibraNavy.emeraldDeep,
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

// ============================================================
// RECENTLY READ (P1 · Item 4)
// ============================================================
// Reflects the persisted LRU list; refs that no longer resolve in the
// bundled corpus are dropped silently (honest: nothing ghost-shown).

final hadithHistoryProvider = FutureProvider<List<HadithModel>>((ref) async {
  await ref.watch(hadithDatabaseInitProvider.future);
  final db = ref.watch(hadithDatabaseProvider);
  final out = <HadithModel>[];
  for (final raw in await HadithViewHistory.entries()) {
    final r = HadithViewHistory.parseRef(raw);
    if (r == null) continue;
    final local = db.getHadith(r.bookSlug, r.hadithNumber);
    if (local != null) out.add(localToHadithModel(local));
  }
  return out;
});

/// Single recording seam for "a hadith detail was opened": persists the
/// LRU entry and refreshes any listener (e.g. the home Recently Read row).
Future<void> recordHadithView(WidgetRef ref, HadithModel hadith) async {
  await HadithViewHistory.record(hadith.bookSlug, hadith.hadithNumber);
  ref.invalidate(hadithHistoryProvider);
}

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
  HadithBookmarksNotifier() : super([]) {
    _load();
  }

  static const _storageKey = 'hadith_bookmarks_v1';

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      state = list
          .map((e) => HadithBookmark.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {}
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode(state.map((b) => b.toJson()).toList()),
    );
  }

  /// Pure dedupe-on-add used by the bookmarks manager: same hadith id
  /// already saved -> the list is returned UNCHANGED (identical object)
  /// so the caller can skip persistence. Unit-tested (item 5).
  static List<HadithBookmark> addIfAbsent(
    List<HadithBookmark> current,
    HadithBookmark bookmark,
  ) {
    if (current.any((b) => b.hadithId == bookmark.hadithId)) return current;
    return [...current, bookmark];
  }

  void addBookmark(HadithModel hadith, {String? note}) {

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

    final next = addIfAbsent(state, bookmark);
    if (identical(next, state)) return;
    state = next;
    _persist();
  }

  void removeBookmark(String hadithId) {
    state = state.where((b) => b.hadithId != hadithId).toList();
    _persist();
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
    _persist();
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

// ============================================================
// SECTION 10: SEARCH RECENTS (world-class hadith pass, item 2 —
// mirror of the Quran pass store, separate key so the two surfaces
// never cross-contaminate). Book RESUME (item 3) deliberately has NO
// store here: the persisted HadithViewHistory LRU already records
// "last opened detail" per reference and is pinned by its own test —
// a second store would fork the truth.
// ============================================================

/// Last 10 distinct hadith-search queries, persisted. Same semantics as
/// the Quran pass: trim, drop empties, dedupe-newest-first, cap 10; the
/// pure [applyRecent] is unit-tested; storage is best-effort both ways.
class HadithRecentSearchesNotifier extends StateNotifier<List<String>> {
  HadithRecentSearchesNotifier() : super(const []) {
    _load();
  }

  static const _prefsKey = 'hadith_recent_searches_v1';

  /// At most this many distinct recent queries persist (owner: last 10).
  static const int cap = 10;

  /// Pure update — unit-tested: trim, drop empties, dedupe (newest wins
  /// position), newest first, capped at [cap].
  static List<String> applyRecent(List<String> current, String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return List.unmodifiable(current);
    final out = [trimmed, ...current.where((q) => q != trimmed)];
    return List.unmodifiable(out.length > cap ? out.sublist(0, cap) : out);
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList(_prefsKey);
      if (saved == null || saved.isEmpty) return;
      if (mounted) state = List.unmodifiable(saved);
    } catch (_) {
      // Storage unreadable: an empty recent list is the honest state.
    }
  }

  Future<void> _save() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_prefsKey, state);
    } catch (_) {
      // Persisting is best-effort; the in-session list stays truthful.
    }
  }

  void add(String query) {
    final next = applyRecent(state, query);
    if (next.length == state.length &&
        List.generate(next.length, (i) => next[i] == state[i])
            .every((b) => b)) {
      return; // unchanged — no pointless write
    }
    state = next;
    _save();
  }

  void remove(String query) {
    state = List.unmodifiable(state.where((q) => q != query));
    _save();
  }

  void clear() {
    state = const [];
    _save();
  }
}

final hadithRecentSearchesProvider =
    StateNotifierProvider<HadithRecentSearchesNotifier, List<String>>((ref) {
  return HadithRecentSearchesNotifier();
});
