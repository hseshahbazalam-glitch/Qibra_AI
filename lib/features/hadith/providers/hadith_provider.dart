// lib/features/hadith/providers/hadith_provider.dart
// ============================================================
// QIBRA AI — HADITH PROVIDER
// Version: 2.1.0 — Singleton Database Integration with Instant Load
// ============================================================

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qibra_ai/core/design_system/qibra_navy.dart';
import 'package:qibra_ai/features/ai/domain/rag_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/hadith_availability.dart';
import '../data/hadith_kitab_names.dart';
import '../data/models/hadith_models.dart';
import '../data/services/hadith_database_service.dart';
import '../data/services/hadith_view_history.dart';

/// Hadith display language is independent of UI locale.
/// Only bundled languages: en, ar, ur. Hindi and others stay unresolved.
class HadithLanguageNotifier extends StateNotifier<String> {
  // PASS X1: the ref is needed for ONE thing — refreshing the surfaces whose
  // models snapshot a translation's text, after that language folds in.
  HadithLanguageNotifier(this._ref) : super('en') {
    _load();
  }

  final Ref _ref;

  static const _key = 'hadith_display_language_v1';
  // Phase B: DERIVED from the availability matrix (single source of
  // truth, pinned to disk data by test/features/hadith/hadith_multilang_test.dart) —
  // this list may not be hardcoded here again.
  static const supported = {...HadithAvailability.languageCodes};

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
    // PASS X1: the boot batch carries english/arabic/urdu only, so the
    // selected translation is folded on the way in. Single-flight, and a
    // no-op for the three eager languages and for anything already in
    // memory — the two language sheets stay instant. Read through the
    // factory rather than the provider: `hadithDatabaseProvider` hands out
    // that same singleton, and a test double overriding it simply has nothing
    // folded (empty cache → warmLanguage false → no invalidation).
    if (await HadithDatabaseService().warmLanguage(code)) {
      // hadithsProvider maps LocalHadith → HadithModel ONCE at build, so the
      // rows it published still carry '' for the freshly folded language.
      // `mounted` because the fold is awaited: a sheet closed while it ran
      // must not invalidate a container that is already gone.
      if (mounted) {
        _ref.invalidate(hadithsProvider);
        _ref.invalidate(hadithLanguageCoverageProvider);
      }
    }
  }
}

final hadithLanguageProvider =
    StateNotifierProvider<HadithLanguageNotifier, String>(
  (ref) => HadithLanguageNotifier(ref),
);

String? hadithTextForLanguage(HadithModel hadith, String language) {
  switch (language) {
    case 'ar':
      return hadith.hasArabic ? hadith.textArabic : null;
    case 'ur':
      return hadith.hasUrdu ? hadith.textUrdu : null;
    case 'en':
      return hadith.hasEnglish ? hadith.textEnglish : null;
    case 'bn':
      return hadith.hasBengali ? hadith.textBengali : null;
    case 'tr':
      return hadith.hasTurkish ? hadith.textTurkish : null;
    case 'id':
      return hadith.hasIndonesian ? hadith.textIndonesian : null;
    case 'fr':
      return hadith.hasFrench ? hadith.textFrench : null;
    default:
      return null;
  }
}

/// Same selection over the raw local rows (the related-hadith strip
/// renders LocalHadith, not HadithModel — one rule for every surface:
/// a translation is only ever shown when its key-matched text exists).
String? localHadithTextForLanguage(LocalHadith local, String language) {
  switch (language) {
    case 'ar':
      return local.hasArabic ? local.textArabic : null;
    case 'ur':
      return local.hasUrdu ? local.textUrdu : null;
    case 'en':
      return local.hasEnglish ? local.textEnglish : null;
    case 'bn':
      return local.hasBengali ? local.textBengali : null;
    case 'tr':
      return local.hasTurkish ? local.textTurkish : null;
    case 'id':
      return local.hasIndonesian ? local.textIndonesian : null;
    case 'fr':
      return local.hasFrench ? local.textFrench : null;
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
    // PASS X1 — the reader's PERSISTED language rides the tail of the boot
    // sequence (the corpus itself now loads only the base trio). Awaiting it
    // here is what keeps the first painted hadith honest: a bn/tr/id/fr
    // reader gets its translation on the first frame instead of the
    // 'unavailable' fallback for a second (en/ar/ur need no fold at all, so
    // warmLanguage returns false and touches no asset). Reads (not watches)
    // the language:
    // a later switch is handled by setLanguage, and re-running this
    // provider would drop every hadith list back to its loader.
    if (db.isInitialized) {
      await db.warmLanguage(ref.read(hadithLanguageProvider));
    }
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
    textBengali: local.textBengali,
    textTurkish: local.textTurkish,
    textIndonesian: local.textIndonesian,
    textFrench: local.textFrench,
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
      // Pass H1: the accessor is the one honest window onto the name
      // map (trim-aware); 'no name' arrives as '' and the chip renders
      // the i18n 'Book {n}' fallback — nothing downstream guesses.
      name: HadithKitabNames.name(bookInfo.sections, chapterNum) ?? '',
      nameArabic: '',
      bookSlug: bookSlug,
      hadithCount: db.getChapterHadiths(bookSlug, chapterNum).length,
    );
  }).toList();
});

// ============================================================
// SECTION 5b: LANGUAGE COVERAGE (Pass H1 parity disclosure)
// ============================================================

/// Per book, per language translation counts from the REAL loaded
/// corpus (never a shipped number). Unresolved while the database
/// initializes — selector surfaces omit depth notes until it resolves,
/// so nothing ever renders a placeholder 0% or 100%.
final hadithLanguageCoverageProvider = FutureProvider<
    Map<String, Map<String, ({int nonEmpty, int total})>>>((ref) async {
  await ref.watch(hadithDatabaseInitProvider.future);
  return ref.watch(hadithDatabaseProvider).languageCoverage;
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
// World-class hadith pass H4 (2026-09-01): the query is BRIDGE-EXPANDED
// through the ONE RomanUrduBridge (RagService.expandQuery — this file owns
// no lexicon of its own) and the per-term hits are merged into a matched-
// token DENSITY ranking. Both halves are pure so they unit-test without
// the corpus: hadithSearchTerms (P1), rankHadithSearchMerge (P2).

final hadithSearchQueryProvider = StateProvider<String>((ref) => '');
final hadithSearchBookFilterProvider = StateProvider<String?>((ref) => null);

/// P1 · Terms a hadith query is searched under: the RAW trimmed query
/// FIRST (the additive rule — the raw search itself is untouched, the
/// bridge only ADDS candidate pools), then the RomanUrduBridge variants
/// verbatim ('namaz' → prayer / salah / salat / صلاة via
/// [RagService.expandQuery]).
List<String> hadithSearchTerms(String query) {
  final raw = query.trim();
  if (raw.isEmpty) return const [];
  return [raw, ...RagService.expandQuery(raw)];
}

/// P2 · Kitab weight for the ranking tie-break: the two universally
/// Sahih-graded books lead, everything else shares one rank — no
/// fabricated tiering beyond that single, documented fact.
int hadithBookWeight(String slug) => switch (slug) {
      'bukhari' => 0,
      'muslim' => 1,
      _ => 2,
    };

/// P2 · Merge per-term hit lists (index-aligned with [hadithSearchTerms]
/// output) into ONE ranked list. Order:
///   1. density — how many DISTINCT terms hit the hadith (desc);
///   2. best relevance across those terms (desc);
///   3. kitab weight (asc);
///   4. hadith number (asc — canonical order).
/// A hadith hit by several terms collapses to a single row carrying its
/// BEST-scoring match channel. Capped at [maxResults].
// (The service import stays RELATIVE like its four siblings: the static
// batteries G2 import-graph walk resolves package-form URIs only for this
// file, so converting the one import would DELETE 3 of its 14 pre-existing
// "referenced but not provided" advisories — a zero-delta audit must not move
// the numbers in either direction.)
List<LocalSearchResult> rankHadithSearchMerge({
  required List<List<LocalSearchResult>> termResults,
  int maxResults = 50,
}) {
  final agg = <String, _HadithHitAgg>{};
  for (final termHits in termResults) {
    for (final hit in termHits) {
      final entry = agg.putIfAbsent(hit.hadith.id, () => _HadithHitAgg(hit));
      if (!identical(entry.best, hit)) entry.absorb(hit);
    }
  }
  final rows = agg.values.toList();
  rows.sort((a, b) {
    final byDensity = b.terms.compareTo(a.terms);
    if (byDensity != 0) return byDensity;
    final byRelevance = b.bestRelevance.compareTo(a.bestRelevance);
    if (byRelevance != 0) return byRelevance;
    final byBook =
        hadithBookWeight(a.slug).compareTo(hadithBookWeight(b.slug));
    if (byBook != 0) return byBook;
    return a.hadithNumber.compareTo(b.hadithNumber);
  });
  return [for (final entry in rows.take(maxResults)) entry.best];
}

class _HadithHitAgg {
  _HadithHitAgg(this.best)
      : terms = 1,
        bestRelevance = best.relevance,
        slug = best.hadith.bookSlug,
        hadithNumber = best.hadith.hadithNumber;

  /// The row kept for display: best relevance wins, so its match-channel
  /// pill states the strongest language the hit came through.
  LocalSearchResult best;

  /// DISTINCT terms that hit this hadith (the merge key is the hadith id,
  /// and each term list carries a hadith at most once — density == count).
  int terms;
  double bestRelevance;
  final String slug;
  final int hadithNumber;

  void absorb(LocalSearchResult other) {
    terms += 1;
    if (other.relevance > bestRelevance) {
      bestRelevance = other.relevance;
      best = other;
    }
  }
}

final hadithSearchResultsProvider =
    FutureProvider<List<HadithSearchResult>>((ref) async {
  final query = ref.watch(hadithSearchQueryProvider);
  final bookFilter = ref.watch(hadithSearchBookFilterProvider);
  final terms = hadithSearchTerms(query);
  if (terms.isEmpty) return [];

  await ref.watch(hadithDatabaseInitProvider.future);
  final db = ref.watch(hadithDatabaseProvider);
  // ONE batched off-main scan over the whole bridge plan (the ANR-safe
  // entry the AI retrieve path already uses) instead of a synchronous
  // per-term scan storm. The book filter narrows the MERGED hits, so a
  // selected kitab can never make the scan miss bridge candidates.
  final batches = await db.searchBatchOffMain(terms, maxPerQuery: 50);
  final ranked = rankHadithSearchMerge(
    termResults: [
      for (final batch in batches)
        if (bookFilter == null)
          batch
        else
          batch.where((r) => r.hadith.bookSlug == bookFilter).toList(),
    ],
  );

  return ranked.map((r) {
    return HadithSearchResult(
      hadith: localToHadithModel(r.hadith),
      matchType: _matchTypeFromString(r.matchedIn),
      matchedText: query.trim(),
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
    case 'bengali':
      return HadithMatchType.bengali;
    case 'turkish':
      return HadithMatchType.turkish;
    case 'indonesian':
      return HadithMatchType.indonesian;
    case 'french':
      return HadithMatchType.french;
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
    } catch (_) {
      // Pass P3 honest-silence: corrupt bookmark JSON → start empty rather than crash (the next save rewrites it)
    }
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
