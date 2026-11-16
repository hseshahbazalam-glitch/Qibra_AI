// lib/features/hadith/data/services/hadith_database_service.dart
// ============================================================
// QIBRA AI — LOCAL HADITH DATABASE SERVICE (Multi-Book & Multi-Language)
// Singleton instance to prevent multiple re-decoding passes.
// ============================================================

import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'package:qibra_ai/core/utils/search_normalizer.dart';
import '../hadith_availability.dart';
import 'hadith_search_worker.dart';


// Top-level so Isolate.run closures can capture it (owner ANR fix 2026-09-02).
double hadithRelevanceFor(String text, String query) {
  final lowerText = text.toLowerCase();

  if (lowerText.startsWith(query)) return 1.0;
  if (lowerText.contains(' $query ')) return 0.9;
  if (lowerText.contains(' $query')) return 0.85;

  final occurrences = query.allMatches(lowerText).length;
  return (0.5 + (occurrences * 0.1)).clamp(0.0, 0.8);
}

// ============================================================
// PASS HR-1 — THE PER-BOOK DERIVATION, PURE AND SHARED
// ============================================================

/// A book, assembled: the rows plus the section names they were labeled from.
typedef HadithAssembledBook =
    ({List<LocalHadith> hadiths, Map<String, String> sections});

/// Everything a book's texts mean, as ONE pure function of the decoded
/// editions (HR-2.1: two per book — English and Urdu; three until the Arabic
/// edition was unbundled) plus the folded language indices. Extracted VERBATIM out of
/// `_loadBook` by PASS HR-1 so the main isolate (which renders) and the
/// persistent search worker (which scans) assemble byte-identical rows from
/// byte-identical raw text — two implementations of the join is exactly how a
/// fractional 402.2 once landed on its parent 402, and a worker whose input
/// differed from the rendered text would be a search that lies.
///
/// Isolate-safe by construction: no rootBundle, no providers, no `this`, no
/// Flutter API. The only cross-references are the class's own pure static key
/// helpers.
HadithAssembledBook? assembleHadithBook({
  required Map<String, dynamic>? englishData,
  required Map<String, dynamic>? urduData,
  required Map<String, Map<String, String>> langIndices,
  required String slug,
  required String name,
}) {
    // HR-2.1: the spine used to be english ?? arabic ?? urdu; the Arabic
    // edition is unbundled, so it is english ?? urdu. Every book ships
    // english.json, so the row set is the English list exactly, before and
    // after this pass — that is the no-row-lost proof.
    final baseData = englishData ?? urduData;
    if (baseData == null) return null;

    final metadata = baseData['metadata'] as Map<String, dynamic>?;
    final sections = <String, String>{};
    if (metadata != null) {
      final sectionsData = metadata['sections'] as Map<String, dynamic>?;
      sectionsData?.forEach((key, value) {
        sections[key] = value.toString();
      });
    }

    final englishHadiths = englishData?['hadiths'] as List<dynamic>? ?? [];
    final urduHadiths = urduData?['hadiths'] as List<dynamic>? ?? [];

    // Build lookup maps. HR-2.1 deleted the Arabic map with its file and left the
    // Urdu one exactly as it had always joined: floored `hadithnumber` key, LAST
    // write wins, `?? ''` for a miss. HR-2.2 keeps that map as the primary source of
    // a row's Urdu — every text any reader has ever been shown stays word for word —
    // and puts the pair index beside it, consulted ONLY where the number map has
    // nothing to give: a key the Urdu file does not carry, or a real text that a
    // later blank record overwrote. That is the entire change, and it is +52 rows of
    // Urdu, 0 rows blanked, 0 rows re-attributed, measured row by row over all 36,390
    // spine rows by test/features/hadith/hadith_hotfix_hr22_pair_parity_test.dart and
    // printed by scripts/hr22_pairkey_parity.py BEFORE this code existed (§ HR-2.2).
    final urduMap = <int, String>{};
    for (final h in urduHadiths) {
      try {
        final map = h as Map<String, dynamic>;
        final hNum = HadithDatabaseService._parseHadithNumber(map['hadithnumber']);
        urduMap[hNum] = map['text']?.toString() ?? '';
      } catch (_) {
        continue;
      }
    }

    // The HR-2.2 rescue index: `pairTextIndex` is the SAME function the Phase-B
    // languages below already use (exact pair key, blank texts skipped, first record
    // wins), applied to the Urdu rows. It is never an override: two of the seven
    // Urdu files do not share the English file's numbering space, so a pair hit in
    // those books is not evidence the text belongs to the row (measured: index-level
    // `hadithnumber` agreement is 631/1,858 for malik and 0/7,563 for muslim).
    final urduPairIndex = HadithDatabaseService.pairTextIndex(urduHadiths);

    // Phase B language joins: keyed by the (hadithnumber,
    // arabicnumber) PAIR — never by array index — because our shipped
    // record sets differ from the dataset's (bukhari 7,589 raw vs
    // 7,563 keyed; tirmidhi 3,998 vs 3,956; muslim's fractional
    // arabicnumbers). A missing pair means the language has nothing
    // for that hadith -> '' -> hasX false.
    final primaryHadiths =
        englishHadiths.isNotEmpty ? englishHadiths : urduHadiths;

    final hadiths = <LocalHadith>[];
    for (final h in primaryHadiths) {
      try {
        final map = h as Map<String, dynamic>;
        final hadithNum = HadithDatabaseService._parseHadithNumber(map['hadithnumber']);
        final ref = map['reference'] as Map<String, dynamic>?;
        final bookNum = HadithDatabaseService._parseHadithNumber(ref?['book']);
        final chapterHadithNum = HadithDatabaseService._parseHadithNumber(ref?['hadith']);

        final grades = map['grades'] as List<dynamic>? ?? [];
        String gradeStr = '';
        if (grades.isNotEmpty) {
          final firstGrade = grades.first;
          if (firstGrade is Map<String, dynamic>) {
            gradeStr = firstGrade['grade']?.toString() ?? '';
          }
        }

        final chapterName = sections[bookNum.toString()] ?? '';
        final arabicNum = HadithDatabaseService._parseHadithNumber(map['arabicnumber']);
        // Exact, fractional-aware join key from the RAW record values
        // (Rev. 2: 402.2 must never merge onto 402).
        final pair = HadithDatabaseService.pairKey(map['hadithnumber'], map['arabicnumber']);

        hadiths.add(LocalHadith(
          hadithNumber: hadithNum,
          arabicNumber: arabicNum == 0 ? hadithNum : arabicNum,
          textEnglish: map['text']?.toString() ?? '',
          textUrdu: HadithDatabaseService.urduJoinText(
            byNumber: urduMap[hadithNum] ?? '',
            byPair: urduPairIndex[pair] ?? '',
          ),
          textBengali: langIndices['bn']?[pair] ?? '',
          textTurkish: langIndices['tr']?[pair] ?? '',
          textIndonesian: langIndices['id']?[pair] ?? '',
          textFrench: langIndices['fr']?[pair] ?? '',
          bookSlug: slug,
          bookName: name,
          bookNumber: bookNum,
          chapterHadithNumber: chapterHadithNum,
          chapterName: chapterName,
          grade: gradeStr,
          pairKey: pair,
        ));
      } catch (_) {
        continue;
      }
    }
  return (hadiths: hadiths, sections: sections);
}

/// One hadith asset as the loader saw it: the raw text AND the off-main decode.
///
/// PASS HR-1 added `raw` — the persistent search worker assembles its OWN copy
/// of the corpus from the same bytes the main isolate decoded, so an asset is
/// read from the bundle exactly once per session per file, and the only thing
/// that crosses the isolate boundary is that one memcpy.
class _HadithAsset {
  const _HadithAsset({required this.raw, required this.data});

  final String raw;
  final Map<String, dynamic> data;
}


// ============================================================
// PASS HR-1 — THE BATCH SCAN, AS A PURE FUNCTION OF (corpus, queries)
// ============================================================

/// HOTFIX HR-1.3 — the corpus fold, moved out of the scan and paid once.
///
/// The pair below is ONE ranking rule in TWO declarations, deliberately:
///
///  * [scanFoldedHadithCorpus] is the body. It takes the corpus AND its folded
///    mirror, and its loop contains no fold at all — matching is `indexOf` on
///    cached strings, so a keystroke costs what the text costs, once, instead
///    of what the text costs x fields x queries.
///  * [scanHadithCorpus] is the pre-HR-1.3 signature (rows, queries), kept for
///    its pinned callers, and it is now one line: fold the corpus, run the
///    body. It is the REFERENCE that the parity test measures the mirror
///    against, which is why the rule is not written twice.
///
/// Why this exists at all, in one line of device evidence: six
/// `scan request N, budget 90s (first after a spawn)` and zero `scan N
/// answered` — the scan never finished on real text, because
/// `SearchNormalizer.contains(raw, q)` folds `raw` per row per field per query.
///
/// The rules themselves are unchanged and still pinned by
/// test/features/hadith/hadith_h4_search_test.dart and test/features/ai/*: the
/// RAW query text is matched verbatim (folded by [SearchNormalizer], which is
/// the only normalization the hadith path allows), english scores through
/// [hadithRelevanceFor], urdu upgrades to 0.85, the chapter name
/// only ever scores 0.5 when nothing else matched (HR-2.1: the arabic 0.9
/// arm left with the edition), the four Phase B candidates
/// are upgrade-only and skip empty text, each term list is capped, then sorted
/// by relevance descending.

/// HOTFIX HR-1.3 — one row, as the scan wants it: every field it reads,
/// ALREADY folded. Real hadith text is 300-2,000 chars
/// (measured in the shipped bundle: english mean 423 chars, p95 1,134, max
/// 24,676), so folding it per row per field per query is minutes, not
/// milliseconds.
///
/// The mirror holds the worker's own copy of the corpus's TEXT ONLY — the rows
/// stay untouched, because a result must point at the real row.
class FoldedHadith {
  const FoldedHadith({
    required this.english,
    required this.urdu,
    required this.chapter,
    required this.bengali,
    required this.turkish,
    required this.indonesian,
    required this.french,
  });

  final String english;
  final String urdu;
  final String chapter;

  /// The Phase-B fields are mirrored too, not skipped: `foldLanguageIntoRows`
  /// DOES put real text into them whenever a Phase-B language is active, and a
  /// cache that stopped at three languages would quietly make those languages
  /// unsearchable in the worker.
  final String bengali;
  final String turkish;
  final String indonesian;
  final String french;

  /// Retained chars, for the RAM disclosure in the pass report: this is what
  /// the mirror costs on top of the rows, measured rather than estimated.
  int get foldedChars => english.length +
      urdu.length +
      chapter.length +
      bengali.length +
      turkish.length +
      indonesian.length +
      french.length;
}

/// Fold one row. An empty field keeps the canonical `''` instead of a
/// fold-shaped copy of nothing: in the shipped bundle most fields per row are
/// empty, and `''` is shared, so the mirror costs no object per absent field.
FoldedHadith foldHadithRow(LocalHadith hadith) {
  String fold(String text) =>
      text.isEmpty ? '' : SearchNormalizer.foldText(text);
  return FoldedHadith(
    english: fold(hadith.textEnglish),
    urdu: fold(hadith.textUrdu),
    chapter: fold(hadith.chapterName),
    bengali: fold(hadith.textBengali),
    turkish: fold(hadith.textTurkish),
    indonesian: fold(hadith.textIndonesian),
    french: fold(hadith.textFrench),
  );
}

/// THE pre-pass: fold a whole book once, off the main isolate, at hand-off.
/// One fold per row per non-empty field, paid ONCE — the scan below pays zero.
List<FoldedHadith> foldHadithBook(List<LocalHadith> rows) => [
      for (final h in rows) foldHadithRow(h),
    ];

/// The same, book by book, in the shape the worker keeps (`books`).
Map<String, List<FoldedHadith>> foldHadithCorpus(
  Map<String, List<LocalHadith>> books,
) =>
    {
      for (final entry in books.entries)
        entry.key: foldHadithBook(entry.value),
    };

/// The batch scan, HOTFIX HR-1.3 shape: (rows, folded mirror, queries) in,
/// relevance-ranked top-N out. Every rule is [scanHadithCorpus]'s and lives
/// nowhere else: english scores through [hadithRelevanceFor] on the RAW text,
/// urdu upgrades to 0.85, the chapter name only ever scores 0.5
/// when nothing else matched, the four Phase-B candidates are upgrade-only and
/// skip empty text, each term list is capped at maxPerQuery * 4, then sorted by
/// relevance descending and truncated. What changed is only WHERE the folding
/// happens: the corpus side arrives pre-folded, so the loop below does
/// `indexOf` on strings and folds exactly one thing — the query, once each.
List<List<LocalSearchResult>> scanFoldedHadithCorpus(
  Map<String, List<LocalHadith>> books,
  Map<String, List<FoldedHadith>> folded,
  List<String> queries, {
  int maxPerQuery = 3,
}) {
  final terms = queries.map((q) => q.toLowerCase().trim()).toList();
  final patterns = [
    for (final q in queries) SearchNormalizer.foldQuery(q),
  ];
  final hits = <List<LocalSearchResult>>[
    for (final _ in queries) <LocalSearchResult>[],
  ];
  for (final entry in books.entries) {
    final rows = entry.value;
    // A mirror that is missing, or whose length differs, is not the mirror of
    // THESE rows — and matching a stale string is worse than folding slowly: it
    // drops a hit no device would ever see. So the mirror is used only when it
    // matches, and otherwise the row is folded here, the old way. That window
    // is real but narrow: main has handed a book and not yet settled, or a
    // language fold replaced the rows. Never for a settled corpus, which is
    // what the worker's flush branch guarantees.
    //
    // The nullable local (rather than a `mirrored` bool plus `mirror!`) is
    // deliberate: the null test is the promotion, so there is no `!` for the
    // analyzer to call unnecessary and no way to dereference a mirror that was
    // not the right size.
    final mirror = folded[entry.key];
    final mirrored =
        mirror != null && mirror.length == rows.length ? mirror : null;
    for (var r = 0; r < rows.length; r++) {
      final hadith = rows[r];
      final text = mirrored != null ? mirrored[r] : foldHadithRow(hadith);
      for (var qi = 0; qi < queries.length; qi++) {
        if (hits[qi].length >= maxPerQuery * 4) continue;
        // An empty PATTERN is a miss, not a hit on everything: `indexOf('')`
        // answers 0 for every row, while `firstMatch` — the pre-fix shape —
        // returns null as soon as the folded query is empty. A query of pure
        // tashkeel or spaces must still find nothing.
        final q = patterns[qi];
        if (q.isEmpty) continue;
        final lq = terms[qi];
        double relevance = 0;
        String matchedIn = '';
        if (text.english.indexOf(q) >= 0) {
          relevance = hadithRelevanceFor(hadith.textEnglish, lq);
          matchedIn = 'english';
        }
        if (text.urdu.indexOf(q) >= 0 && 0.85 > relevance) {
          relevance = 0.85;
          matchedIn = 'urdu';
        }
        if (text.chapter.indexOf(q) >= 0 && relevance == 0) {
          relevance = 0.5;
          matchedIn = 'chapter';
        }
        // Pass H4: the Phase-B languages join the OFF-MAIN scan with the EXACT
        // rule the main-isolate search() already uses — scored position-aware,
        // upgrade-only, empty text skipped. Their folded side comes from the
        // mirror like every other field, so no field is matched twice in two
        // different ways.
        for (final candidate in [
          (text.bengali, hadith.textBengali, 'bengali'),
          (text.turkish, hadith.textTurkish, 'turkish'),
          (text.indonesian, hadith.textIndonesian, 'indonesian'),
          (text.french, hadith.textFrench, 'french'),
        ]) {
          if (candidate.$2.trim().isEmpty) continue;
          if (candidate.$1.indexOf(q) >= 0) {
            final candidateRelevance = hadithRelevanceFor(candidate.$2, lq);
            if (candidateRelevance > relevance) {
              relevance = candidateRelevance;
              matchedIn = candidate.$3;
            }
          }
        }
        if (relevance > 0) {
          hits[qi].add(LocalSearchResult(
            hadith: hadith,
            relevance: relevance,
            matchedIn: matchedIn,
          ));
        }
      }
    }
  }
  for (var qi = 0; qi < queries.length; qi++) {
    hits[qi].sort((a, b) => b.relevance.compareTo(a.relevance));
    if (hits[qi].length > maxPerQuery) {
      hits[qi] = hits[qi].sublist(0, maxPerQuery);
    }
  }
  return hits;
}

/// The pre-HR-1.3 entry point, kept EXACTLY as it was signed because HR-1 pins
/// it (row identity, the benchmark) and `ai_responsiveness_test` pins its use:
/// it is now the REFERENCE implementation of the ranking rule, and it is one
/// line — fold the corpus, then run the one body. Two implementations of one
/// ranking rule is how a cache starts disagreeing with the truth quietly, so
/// the fold is hoisted out of the loop instead of duplicated into it.
///
/// Nothing on the typing path calls this any more: the worker answers from its
/// cached mirror (see `_hadithSearchWorkerEntry`). Tests and the main-isolate
/// one-shot paths may, and they pay the fold per call — which is the whole
/// point of HR-1.3.
List<List<LocalSearchResult>> scanHadithCorpus(
  Map<String, List<LocalHadith>> booksSnapshot,
  List<String> queries, {
  int maxPerQuery = 3,
}) =>
    scanFoldedHadithCorpus(
      booksSnapshot,
      foldHadithCorpus(booksSnapshot),
      queries,
      maxPerQuery: maxPerQuery,
    );

/// Pass X1's late-language fold, as a pure function (PASS HR-1): a NEW
/// immutable row per hadith, joined on the exact pair key the row already
/// carries, plus the count of rows that ended up with non-empty text — the
/// coverage marker. Both the main isolate and the search worker call THIS, so
/// the two copies of the corpus can never disagree about a warmed language.
({List<LocalHadith> rows, int nonEmpty}) foldLanguageIntoRows({
  required List<LocalHadith> rows,
  required String code,
  required Map<String, String> index,
}) {
  final updated = List<LocalHadith>.filled(rows.length, rows.first);
  var nonEmpty = 0;
  for (var i = 0; i < rows.length; i++) {
    final text = index[rows[i].pairKey] ?? '';
    if (text.trim().isNotEmpty) nonEmpty++;
    updated[i] = rows[i].withLanguageText(code, text);
  }
  return (rows: updated, nonEmpty: nonEmpty);
}
// ============================================================
// LOCAL HADITH MODEL
// ============================================================

class LocalHadith {
  final int hadithNumber;
  final int arabicNumber;
  // HR-2.1: `textArabic` is GONE with the unbundled edition. `arabicNumber`
  // above stays — it is the reference NUMBER of the hadith (a join key), not
  // Arabic text, and `pairKey`/`LocalHadith.numberLabel` still ride it.
  final String textEnglish;
  final String textUrdu;
  // Phase B (2026-09-05): texts joined by the (hadithnumber,
  // arabicnumber) pair against the extracted language files; a hadith
  // with no key-match simply carries '' -> hasX false -> the UI shows
  // the honest "unavailable" fallback. Never positionally joined.
  final String textBengali;
  final String textTurkish;
  final String textIndonesian;
  final String textFrench;
  final String bookSlug;
  final String bookName;
  final int bookNumber;
  final int chapterHadithNumber;
  final String chapterName;
  final String grade;
  /// PASS X1: the exact (hadithnumber, arabicnumber) join key this row was
  /// built with, kept on the row so a language folded LATER ([warmLanguage])
  /// joins on the identical key instead of re-parsing numbers — a truncated
  /// int can never re-derive `402.2`, and re-deriving wrongly is the bug that
  /// H4's fractional-key test exists to prevent.
  final String pairKey;

  const LocalHadith({
    required this.hadithNumber,
    required this.arabicNumber,
    required this.textEnglish,
    required this.textUrdu,
    this.textBengali = '',
    this.textTurkish = '',
    this.textIndonesian = '',
    this.textFrench = '',
    required this.bookSlug,
    required this.bookName,
    required this.bookNumber,
    required this.chapterHadithNumber,
    required this.chapterName,
    required this.grade,
    this.pairKey = '',
  });

  /// PASS X1: a lazily-loaded edition produces a NEW row (the model stays
  /// immutable); every other field rides along untouched.
  LocalHadith withLanguageText(String code, String text) => LocalHadith(
        hadithNumber: hadithNumber,
        arabicNumber: arabicNumber,
        textEnglish: textEnglish,
        textUrdu: textUrdu,
        textBengali: code == 'bn' ? text : textBengali,
        textTurkish: code == 'tr' ? text : textTurkish,
        textIndonesian: code == 'id' ? text : textIndonesian,
        textFrench: code == 'fr' ? text : textFrench,
        bookSlug: bookSlug,
        bookName: bookName,
        bookNumber: bookNumber,
        chapterHadithNumber: chapterHadithNumber,
        chapterName: chapterName,
        grade: grade,
        pairKey: pairKey,
      );

  String get id => '${bookSlug}_$hadithNumber';
  /// PASS X6 (H1c): the edition's own number string, from the exact pair key
  /// ([hadithNumber] is an int by contract and truncates 402.2 onto 402).
  String get numberLabel {
    final exact = pairKey.split('|').first.trim();
    return exact.isEmpty ? '$hadithNumber' : exact;
  }

  String get displayReference => '$bookName $numberLabel';

  String get shortText {
    if (textEnglish.isNotEmpty) {
      if (textEnglish.length <= 120) return textEnglish;
      return '${textEnglish.substring(0, 120)}...';
    }
    if (textUrdu.isNotEmpty) {
      if (textUrdu.length <= 120) return textUrdu;
      return '${textUrdu.substring(0, 120)}...';
    }
    for (final extra in [textBengali, textTurkish, textIndonesian, textFrench]) {
      if (extra.isNotEmpty) {
        if (extra.length <= 120) return extra;
        return '${extra.substring(0, 120)}...';
      }
    }
    // HR-2.1: the Arabic tail that used to end this chain answered `''` for
    // every row of the shipped bundle anyway (a row only exists when its
    // spine text is there, and the Arabic field was the same emptiness), so
    // the empty string IS the preserved behaviour — never a fabricated
    // preview. An empty preview is what the reader's fallback line renders.
    return '';
  }

  bool get hasEnglish => textEnglish.trim().isNotEmpty;
  bool get hasUrdu => textUrdu.trim().isNotEmpty;
  bool get hasBengali => textBengali.trim().isNotEmpty;
  bool get hasTurkish => textTurkish.trim().isNotEmpty;
  bool get hasIndonesian => textIndonesian.trim().isNotEmpty;
  bool get hasFrench => textFrench.trim().isNotEmpty;
}

// ============================================================
// BOOK METADATA
// ============================================================

class LocalBookInfo {
  final String slug;
  final String name;
  final Map<String, String> sections;
  final int totalHadiths;

  const LocalBookInfo({
    required this.slug,
    required this.name,
    required this.sections,
    required this.totalHadiths,
  });

  String getChapterName(int chapterNumber) {
    return sections[chapterNumber.toString()] ?? 'Chapter $chapterNumber';
  }
}

// ============================================================
// SEARCH RESULT
// ============================================================

class LocalSearchResult {
  final LocalHadith hadith;
  final double relevance;
  final String matchedIn;

  const LocalSearchResult({
    required this.hadith,
    required this.relevance,
    required this.matchedIn,
  });
}

// ============================================================
// DATABASE SERVICE (Singleton)
// ============================================================

class HadithDatabaseService {
  static final HadithDatabaseService _instance =
      HadithDatabaseService._internal();
  factory HadithDatabaseService() => _instance;
  HadithDatabaseService._internal();

  /// Test-only: the singleton factory cannot be implicitly subclassed
  /// (CI 34257996787: non_generative_implicit_constructor); fixture
  /// stubs in test/features/ai/ai_revival_test.dart chain this. App code keeps
  /// hitting the factory singleton — zero behavior change.
  @visibleForTesting
  HadithDatabaseService.testFixture();

  static const Map<String, String> _bookNames = {
    'bukhari': 'Sahih al-Bukhari',
    'muslim': 'Sahih Muslim',
    'nasai': 'Sunan an-Nasa\'i',
    'abudawud': 'Sunan Abi Dawud',
    'tirmidhi': 'Jami` at-Tirmidhi',
    'ibnmajah': 'Sunan Ibn Majah',
    'malik': 'Muwatta Malik',
  };

  final Map<String, List<LocalHadith>> _bookData = {};
  final Map<String, LocalBookInfo> _bookInfo = {};
  final Map<String, Map<String, ({int nonEmpty, int total})>>
      _languageCoverage = {};

  // PASS X1 (device-fat cut, 2026-09-02) — the corpus used to arrive in full
  // at boot: [initialize] awaited SEVEN files per book (the base trio plus a
  // per-book pair-text index for each of the four Phase B languages), i.e. 49
  // rootBundle strings + 49 isolate decodes, ~228 MB read into transient JSON
  // and ~7× the hadith corpus resident afterwards, on a device that displays
  // exactly ONE of those seven. The boot batch is now the base trio (en/ar/ur
  // — the only editions carrying a `grades` block, and the ones
  // [primaryHadiths] falls back through); a translation folds when it is
  // SELECTED, and the reader's persisted language is folded at the tail of
  // hadithDatabaseInitProvider so the first painted hadith already has it.
  /// Languages this session has asked for (Settings / reader sheet). The set
  /// drives two things: [warmLanguage] folds the books already in memory, and
  /// [_loadBook] includes the same languages in a later book's batch — so a
  /// book opened after the switch never needs a second pass. The folded index
  /// maps are NOT retained (their texts are baked into the rows); keeping them
  /// would be precisely the RAM this cut exists to free.
  final Set<String> _languagesRequested = {};

  /// Single-flight per language: two sheets opening at once fold once.
  final Map<String, Future<bool>> _languageWarm = {};

  /// Pass H1 parity math source: per book, per language — rows with
  /// joined non-empty text over loaded rows. Populated by _loadBook;
  /// empty before init (surfaces must hide notes then, never guess).
  Map<String, Map<String, ({int nonEmpty, int total})>>
      get languageCoverage => _languageCoverage;
  bool _isInitialized = false;
  bool _isLoading = false;

  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;

  int get totalHadiths {
    int total = 0;
    for (final book in _bookData.values) {
      total += book.length;
    }
    return total;
  }

  List<String> get loadedBooks => _bookData.keys.toList();

  // ─── INITIALIZE ──────────────────────────────────────────

  Future<void> initialize() async {
    if (_isInitialized) return;
    if (_isLoading) {
      while (_isLoading) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return;
    }

    _isLoading = true;
    if (kDebugMode) debugPrint('[HADITH_DB] Initializing database...');
    final stopwatch = Stopwatch()..start();

    try {
      // PASS X1 (2026-09-02, device-fat cut): the boot loop used to await
      // SEVEN files per book — the base trio plus a per-book index for each
      // of the four Phase B languages. That was 49 asset strings + 49
      // isolate decodes before the FIRST hadith was ever looked at, with
      // ~175 MB of transient JSON held across the awaits and ~7× the corpus
      // resident afterwards (228 MB of files). The loop now loads only the
      // base pair, which is what every join and every display rule needs to
      // be non-empty; [warmLanguage] folds a translation when that language
      // is actually selected. The four extra languages are still one asset
      // each per book — same join, same isolate, just not at boot.
      for (final entry in _bookNames.entries) {
        await _loadBook(entry.key, entry.value);
      }

      _isInitialized = true;
      stopwatch.stop();
      if (kDebugMode) debugPrint(
        '[HADITH_DB] Initialized in ${stopwatch.elapsedMilliseconds}ms '
        '- $totalHadiths hadiths loaded across ${_bookData.length} collections',
      );
    } catch (e) {
      if (kDebugMode) debugPrint('[HADITH_DB] Initialization error: $e');
    } finally {
      _isLoading = false;
    }
  }

  Future<void> loadBook(String slug) async {
    if (_bookData.containsKey(slug)) return;
    final name = _bookNames[slug];
    if (name == null) return;
    await _loadBook(slug, name);
  }

  /// PASS X1 — fold ONE translation into the books already in memory.
  ///
  /// Called by `HadithLanguageNotifier.setLanguage` (which then refreshes the
  /// reading lists) and at the tail of `hadithDatabaseInitProvider` for the
  /// reader's persisted language. A no-op for the base pair — `english` and
  /// `urdu` always ride the boot batch — and for a language every
  /// loaded book already carries. Single-flight per code, and the request is
  /// remembered so a book opened LATER includes it in its own [Future.wait]
  /// batch instead of needing a second pass.
  ///
  /// Returns true only when new text was actually folded, so the caller can
  /// skip invalidating lists that cannot have changed.
  Future<bool> warmLanguage(String code) async {
    if (!HadithAvailability.newLanguageFiles.containsKey(code)) return false;
    _languagesRequested.add(code);
    final running = _languageWarm.putIfAbsent(code, () => _foldLanguage(code));
    try {
      return await running;
    } finally {
      _languageWarm.remove(code);
    }
  }

  Future<bool> _foldLanguage(String code) async {
    final file = HadithAvailability.newLanguageFiles[code];
    if (file == null) return false;
    // Never race the boot batch: the 50 ms poll is [initialize]'s own cadence.
    while (_isLoading) {
      await Future.delayed(const Duration(milliseconds: 50));
    }
    var folded = false;
    for (final slug in _bookData.keys.toList(growable: false)) {
      final cov = _languageCoverage[slug];
      if (cov == null || cov[code] != null) continue;
      final index =
          await _loadLanguageIndex('assets/data/hadith/$slug/$file.json');
      if (index == null) continue;
      final rows = _bookData[slug]!;
      if (rows.isEmpty) continue;
      final foldedRows = foldLanguageIntoRows(rows: rows, code: code, index: index);
      _bookData[slug] = foldedRows.rows;
      // PASS HR-1: the worker's copy folds the SAME way, from the SAME pure
      // function — a language selected after boot cannot leave the searchable
      // text behind the rendered text. (The FOLD SEAM is closed today:
      // `newLanguageFiles` is empty, so this line is unreachable until an
      // edition is bundled — which is exactly why it is wired now.)
      unawaited(HadithSearchWorker.instance
          .noteFold(slug: slug, code: code, index: index));
      // The coverage entry doubles as the "this book has this language"
      // marker — the index map itself is dropped right here, so a warmed
      // session never holds the translation file a second time.
      cov[code] = (nonEmpty: foldedRows.nonEmpty, total: rows.length);
      folded = true;
    }
    return folded;
  }

  /// Bounded wait for initialization (AI Revival Stage 1, owner 2026-09-07).
  /// The hadith search path used to answer COLD instantly — silently empty —
  /// while the Quran side self-heals, so any AI query fired inside the boot
  /// window (post runApp-first perf pass) got a bogus no-results refusal:
  /// the intermittent 'namz kiya hai' bug. This waits for the single-flight
  /// load to settle at the SAME cadence [initialize] already polls, capped
  /// hard at [maxWait]; callers then search whatever IS loaded (or honestly
  /// find nothing). Never throws, never blocks longer than the cap, touches
  /// no [HADITH_DB] timing log and spawns no new work.
  Future<void> waitForReady({
    Duration maxWait = const Duration(milliseconds: 2500),
  }) async {
    if (_isInitialized) return;
    final sw = Stopwatch()..start();
    while (!_isInitialized && sw.elapsedMilliseconds < maxWait.inMilliseconds) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  // ─── LOAD SINGLE BOOK ────────────────────────────────────

  Future<void> _loadBook(String slug, String name) async {
    try {
      // Phase B join: every language file the book needs rides the SAME
      // per-book Future.wait batch, so a book's texts arrive in one await
      // (never N serial main-thread hops), each parse running in
      // Isolate.run off-main. The join rules are untouched.
      //
      // PASS X1 (2026-09-02): the batch no longer carries all FOUR Phase B
      // editions for all seven books unconditionally — that was 49 asset
      // strings + 49 isolate decodes at boot on a device that displays one
      // of them. The base pair (english + urdu; HR-2.1 unbundled arabic,
      // which used to be the third member of the trio — the only editions with
      // a `grades` block and the ones `primaryHadiths` falls back through)
      // stays eager; a translation joins the batch only after [warmLanguage]
      // has been asked for it, and the per-book coverage entry is the marker
      // — a book that already carries the language never re-reads it, and a
      // book opened AFTER the switch folds it in its own batch (no second
      // pass over 21 files).
      final wanted = HadithAvailability.newLanguageFiles.entries
          .where((e) =>
              _languagesRequested.contains(e.key) &&
              _languageCoverage[slug]?[e.key] == null)
          .toList(growable: false);
      final results = await Future.wait<Object?>([
        _loadJsonAsset('assets/data/hadith/$slug/english.json'),
        _loadJsonAsset('assets/data/hadith/$slug/urdu.json'),
        for (final lang in wanted)
          _loadLanguageIndex('assets/data/hadith/$slug/${lang.value}.json'),
      ]);

      // HR-2.1: the batch is 2 files per book, not 3 — `results[1]` used to
      // be arabic.json. The Phase-B tail therefore starts at index 2 now.
      final englishAsset = results[0] as _HadithAsset?;
      final urduAsset = results[1] as _HadithAsset?;
      final englishData = englishAsset?.data;
      final urduData = urduAsset?.data;

      if (englishData == null && urduData == null) {
        return;
      }

      // PASS X1: an edition nobody asked for is simply ABSENT from this map,
      // which is what makes its texts '' and its coverage entry unwritten
      // below — never a silently-empty hadith: the reader's existing
      // 'translation unavailable' line is what an absent edition renders as,
      // exactly as a genuinely missing edition has always rendered.
      final langIndices = <String, Map<String, String>>{
        for (var i = 0; i < wanted.length; i++)
          if (results[2 + i] != null)
            wanted[i].key: results[2 + i]! as Map<String, String>,
      };
      final assembled = assembleHadithBook(
        englishData: englishData,
        urduData: urduData,
        langIndices: langIndices,
        slug: slug,
        name: name,
      );
      if (assembled == null) return;
      final hadiths = assembled.hadiths;
      final sections = assembled.sections;
      _bookData[slug] = hadiths;
      // PASS HR-1 — the search worker assembles its own copy of THIS book from
      // the same raw pair. Deliberately NOT awaited: the worker decodes on its
      // own core while main carries on loading the next book, so the first
      // painted hadith screen never waits on it. The payload is 3 strings per
      // book, once — never a capture of `_bookData`.
      unawaited(HadithSearchWorker.instance.noteBook(
        slug: slug,
        name: name,
        rawEnglish: englishAsset?.raw,
        rawUrdu: urduAsset?.raw,
        langIndices: langIndices,
      ));
      _bookInfo[slug] = LocalBookInfo(
        slug: slug,
        name: name,
        sections: sections,
        totalHadiths: hadiths.length,
      );

      // Pass H1 parity disclosure — per language, how many rows of THIS
      // book actually carry joined text, over the loaded row count. The
      // numbers are counted, never shipped: a language file that is
      // absent (French Tirmidhi) contributes 0 non-empty here AND an
      // 'absent' row via the matrix — two honest views of the same fact,
      // no silent substitution at any of the three levels (collection,
      // language, hadith number).
      int nonEmpty(String Function(LocalHadith h) text) =>
          hadiths.where((h) => text(h).trim().isNotEmpty).length;
      _languageCoverage[slug] = {
        'en': (
          nonEmpty: nonEmpty((h) => h.textEnglish),
          total: hadiths.length
        ),
        'ur': (
          nonEmpty: nonEmpty((h) => h.textUrdu),
          total: hadiths.length
        ),
        // PASS X1: only an edition whose index this book actually folded
        // gets a number. `nonEmpty: 0` is a claim that the translation is
        // EMPTY; no key at all means 'not read yet', which is the shape
        // thinCoverage() and both depth notes already render as nothing (the
        // pinned `tirmidhi: const {}` case) — and [_foldLanguage] writes the
        // real number the moment the language warms.
        if (langIndices.containsKey('bn'))
          'bn': (
            nonEmpty: nonEmpty((h) => h.textBengali),
            total: hadiths.length
          ),
        if (langIndices.containsKey('tr'))
          'tr': (
            nonEmpty: nonEmpty((h) => h.textTurkish),
            total: hadiths.length
          ),
        if (langIndices.containsKey('id'))
          'id': (
            nonEmpty: nonEmpty((h) => h.textIndonesian),
            total: hadiths.length
          ),
        if (langIndices.containsKey('fr'))
          'fr': (
            nonEmpty: nonEmpty((h) => h.textFrench),
            total: hadiths.length
          ),
      };

      if (kDebugMode) debugPrint('[HADITH_DB] Loaded $name: ${hadiths.length} hadiths');
    } catch (e) {
      if (kDebugMode) debugPrint('[HADITH_DB] Error loading $slug: $e');
    }
  }

  Future<_HadithAsset?> _loadJsonAsset(String path) async {
    try {
      final raw = await rootBundle.loadString(path);
      final sw = debugLogLoadTiming ? (Stopwatch()..start()) : null;
      final decoded = await Isolate.run(() => decodeHadithAsset(raw));
      _logDecodeTiming(path, sw);
      if (decoded == null) return null;
      return _HadithAsset(raw: raw, data: decoded);
    } catch (_) {
      return null;
    }
  }

  /// Language file → ready (pairKey → text) index, built ENTIRELY inside
  /// one background isolate (perf pass item 1): decode AND the
  /// pairTextIndex fold happen off-main; main only receives the flat
  /// String→String map. Semantics live in the tested [pairTextIndex].
  Future<Map<String, String>?> _loadLanguageIndex(String path) async {
    try {
      final raw = await rootBundle.loadString(path);
      final sw = debugLogLoadTiming ? (Stopwatch()..start()) : null;
      final index = await Isolate.run(() {
        final data = decodeHadithAsset(raw);
        if (data == null) return null;
        return pairTextIndex(data['hadiths'] as List<dynamic>? ?? const []);
      });
      _logDecodeTiming(path, sw);
      return index;
    } catch (_) {
      return null;
    }
  }

  static void _logDecodeTiming(String path, Stopwatch? sw) {
    if (sw == null) return;
    sw.stop();
    if (kDebugMode) debugPrint('[HADITH_DB] decoded '
        '${path.substring(path.lastIndexOf('/') + 1)} in '
        '${sw.elapsedMilliseconds}ms (off-main)');
  }

  /// Per-file decode stopwatches for the owner's boot profiling (perf
  /// pass item 1): on in debug + profile, silent in release. Flip to
  /// force either state. The aggregate '[HADITH_DB] Initialized' line is
  /// unchanged and always logs via debugPrint.
  static bool debugLogLoadTiming = !kReleaseMode;

  /// Pure, isolate-safe decode entry (perf pass item 1). jsonDecode plus
  /// the exact shape check the loader expects — no Flutter APIs, so
  /// test/core/perf_pass_test.dart can pin decode+join semantics on a
  /// fixture WITHOUT spawning isolates in the test.
  ///
  /// NOT `@visibleForTesting` any more, and that is a fact about the code rather
  /// than a relaxation of a rule: PASS HR-1 gave the persistent search worker
  /// the SAME decoder (it decodes the raw asset strings inside the worker), so
  /// this member is production API called from a second library. Leaving the
  /// annotation on would be a warning the analyzer is right to raise — a
  /// production path must not be built on a member that claims to exist only
  /// for tests.
  static Map<String, dynamic>? decodeHadithAsset(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ─── GET HADITHS ─────────────────────────────────────────

  List<LocalHadith> getHadiths(String bookSlug) {
    return _bookData[bookSlug] ?? [];
  }

  List<LocalHadith> getChapterHadiths(String bookSlug, int chapterNumber) {
    final hadiths = _bookData[bookSlug] ?? [];
    return hadiths.where((h) => h.bookNumber == chapterNumber).toList();
  }

  LocalHadith? getHadith(String bookSlug, int hadithNumber) {
    final hadiths = _bookData[bookSlug] ?? [];
    for (final h in hadiths) {
      if (h.hadithNumber == hadithNumber) return h;
    }
    return null;
  }

  /// PASS X6 (H1c): the exact-key twin of [getHadith]. The int lookup cannot
  /// tell a fractional row from its parent — 52 rows across bukhari and
  /// tirmidhi collide on it — so it returns whichever was loaded first, i.e.
  /// a DIFFERENT hadith presented as the hit. Anything that knows the pair
  /// key (a search hit, a focused open) resolves through here instead; an
  /// empty key is not a lookup, it is a miss, and the caller says so.
  LocalHadith? getHadithByKey(String bookSlug, String pairKey) {
    if (pairKey.isEmpty) return null;
    // getHadiths is `_bookData[slug] ?? []` — going through it (not the map)
    // keeps the one corpus view a test fixture can drive.
    for (final h in getHadiths(bookSlug)) {
      if (h.pairKey == pairKey) return h;
    }
    return null;
  }

  LocalBookInfo? getBookInfo(String bookSlug) {
    return _bookInfo[bookSlug];
  }

  List<LocalBookInfo> getAllBookInfos() {
    return _bookInfo.values.toList();
  }

  // ─── DAILY / RANDOM / FEATURED HADITHS ──────────────────

  /// Deterministic "today's hadith" selection (world-class hadith pass,
  /// item 4): the pool is date-seeded, NOT random — the same calendar day
  /// always yields the same index, across rebuilds, app opens and
  /// restarts. Pool documented in [getDailyHadith]: Sahih al-Bukhari when
  /// present (the collection whose authenticity is agreed on), the full
  /// bundled corpus otherwise. Pure + static so the unit test can pin
  /// determinism without loading a corpus.
  static int todayIndexFor(DateTime now, int poolLength) {
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    return dayOfYear % poolLength;
  }

  LocalHadith? getDailyHadith() {
    final bukhariHadiths = _bookData['bukhari'];
    if (bukhariHadiths != null && bukhariHadiths.isNotEmpty) {
      return bukhariHadiths[
          todayIndexFor(DateTime.now(), bukhariHadiths.length)];
    }
    final allHadiths = _getAllHadiths();
    if (allHadiths.isEmpty) return null;
    return allHadiths[todayIndexFor(DateTime.now(), allHadiths.length)];
  }

  List<LocalHadith> getFeaturedHadiths({int limit = 10, String? bookSlug}) {
    if (bookSlug != null && _bookData.containsKey(bookSlug)) {
      final list = _bookData[bookSlug]!;
      return list.take(limit).toList();
    }
    final featured = <LocalHadith>[];
    for (final key in ['bukhari', 'muslim', 'tirmidhi', 'abudawud', 'nasai']) {
      final list = _bookData[key];
      if (list != null && list.isNotEmpty) {
        featured.add(list.first);
        if (list.length > 1 && featured.length < limit) {
          featured.add(list[1]);
        }
      }
      if (featured.length >= limit) break;
    }
    return featured;
  }

  // ─── SEARCH ──────────────────────────────────────────────

  List<LocalSearchResult> search(
    String query, {
    String? bookSlug,
    int maxResults = 50,
  }) {
    if (query.trim().isEmpty) return [];

    final lowerQuery = query.toLowerCase().trim();
    final results = <LocalSearchResult>[];

    final booksToSearch =
        bookSlug != null ? {bookSlug: _bookData[bookSlug] ?? []} : _bookData;

    for (final entry in booksToSearch.entries) {
      for (final hadith in entry.value) {
        double relevance = 0;
        String matchedIn = '';

        if (SearchNormalizer.contains(hadith.textEnglish, query)) {
          relevance = _calculateRelevance(hadith.textEnglish, lowerQuery);
          matchedIn = 'english';
        }

        if (SearchNormalizer.contains(hadith.textUrdu, query)) {
          const urduRelevance = 0.85;
          if (urduRelevance > relevance) {
            relevance = urduRelevance;
            matchedIn = 'urdu';
          }
        }

        // Phase B languages: scored like english (position-aware
        // _calculateRelevance) but only ever UPGRADE an existing hit —
        // the Urdu fixed-relevance precedence is untouched.
        for (final candidate in [
          (hadith.textBengali, 'bengali'),
          (hadith.textTurkish, 'turkish'),
          (hadith.textIndonesian, 'indonesian'),
          (hadith.textFrench, 'french'),
        ]) {
          if (candidate.$1.trim().isEmpty) continue;
          if (SearchNormalizer.contains(candidate.$1, query)) {
            final candidateRelevance =
                _calculateRelevance(candidate.$1, lowerQuery);
            if (candidateRelevance > relevance) {
              relevance = candidateRelevance;
              matchedIn = candidate.$2;
            }
          }
        }

        if (SearchNormalizer.contains(hadith.chapterName, query)) {
          if (relevance == 0) {
            relevance = 0.5;
            matchedIn = 'chapter';
          }
        }

        if (relevance > 0) {
          results.add(LocalSearchResult(
            hadith: hadith,
            relevance: relevance,
            matchedIn: matchedIn,
          ));
        }
      }
    }

    results.sort((a, b) => b.relevance.compareTo(a.relevance));
    return results.take(maxResults).toList();
  }

  // ─── HELPERS ─────────────────────────────────────────────

  List<LocalHadith> _getAllHadiths() {
    final all = <LocalHadith>[];
    for (final hadiths in _bookData.values) {
      all.addAll(hadiths);
    }
    return all;
  }

  double _calculateRelevance(String text, String query) =>
      hadithRelevanceFor(text, query);

  /// Batch search off the main isolate (AI Roman-Urdu bridge, owner
  /// 2026-09-02): all terms in ONE background scan of the 36k-hadith
  /// index; per-term hits, relevance-ranked, capped at [maxPerQuery].
  /// The synchronous per-term scan was the ANR source in chat send.
  /// Batch search, answered by the persistent worker (PASS HR-1).
  ///
  /// The SIGNATURE is unchanged on purpose: `ai_responsiveness_test` pins this
  /// declaration and both call sites (the chat RAG retrieve path and the hadith
  /// tab's `hadithSearchResultsProvider`), and the AI/hadith fakes override it.
  ///
  /// BEFORE: `Map<String, List<LocalHadith>>.of(_bookData)` was captured by an
  /// `Isolate.run` closure, so EVERY call deep-copied all 36,390 rows out of the
  /// main isolate — 14 keystrokes, 14 corpus copies. That is the freeze the
  /// owner measured on a CPH2573 typing "namaz ka tarika", and no CI test could
  /// see it because every hadith search test drives a fake that overrides this
  /// method.
  /// NOW: query strings in, ranked batches out, corpus never crosses.
  ///
  /// When the worker cannot answer — spawn refused, wedged, or the query was
  /// superseded by a newer one — the answer is EMPTY, never a main-isolate
  /// rescan: an empty result is honest and recoverable, a per-keystroke copy of
  /// the corpus is the bug this pass exists to remove. `hadith_pass_hr1_test`
  /// pins that no isolate closure in this feature captures the corpus map.
  Future<List<List<LocalSearchResult>>> searchBatchOffMain(
    List<String> queries, {
    int maxPerQuery = 3,
  }) async {
    if (queries.isEmpty) return [for (final _ in queries) <LocalSearchResult>[]];
    if (!_isInitialized) return [for (final _ in queries) <LocalSearchResult>[]];
    final worker = HadithSearchWorker.instance;
    await worker.start();
    // HR-1.1: a worker that revived after a retirement owns NOTHING while the
    // boot hand-offs are still remembered, so an answered-but-empty search
    // would be the reader's second disappointment. One re-hand, reusing the
    // boot's own `_loadBook` (21 asset reads, off-main decodes, and the SAME
    // unawaited `noteBook` hand-off shape): the corpus is rebuilt where it was
    // built the first time, never copied out of main. The worker's revive
    // cooldown rate-limits this too — a re-hand can only follow a revival, so
    // it cannot fire per keystroke by construction.
    if (worker.corpusStale) {
      if (kDebugMode) {
        debugPrint('[HADITH_DB] worker revived — re-handing '
            '${worker.handedBooks.length} book(s) through the boot loader');
      }
      await rebuildSearchCorpus();
      worker.markCorpusFresh();
    }
    // The boot hands books over without being awaited (first-frame priority),
    // so a query that arrives mid-boot waits for the worker to catch up rather
    // than scanning a half-loaded corpus and calling it a result. Bounded: a
    // worker that cannot settle must not stall the caller either.
    await worker.whenSettled().timeout(
          const Duration(seconds: 8),
          onTimeout: () => null,
        );
    final batches = await worker
        .search(queries, maxPerQuery: maxPerQuery);
    if (batches == null) {
      if (kDebugMode) {
        debugPrint('[HADITH_DB] search batch empty — worker unavailable; the '
            'corpus is never copied for a keystroke');
      }
      return [for (final _ in queries) <LocalSearchResult>[]];
    }
    return batches;
  }

  /// HR-1.1: re-feed the search worker after it came back from a retirement.
  /// Deliberately NOT a new loading path: every book goes back through
  /// [_loadBook], which reads the trio once, decodes off-main and hands the raw
  /// strings to the worker exactly as boot did. No corpus map is built, copied
  /// or captured here — that is the HR-1 ban, and it holds by reuse rather than
  /// by comment.
  Future<void> rebuildSearchCorpus() async {
    for (final entry in _bookNames.entries) {
      if (!_bookData.containsKey(entry.key)) continue;
      await _loadBook(entry.key, entry.value);
    }
  }

  /// Canonical string key for a JSON number that may be an int, a double,
  /// or a string — EXACT, fractional-aware, never floored. Mirrors
  /// scripts/extract_hadith_languages.py::canon_num bit-for-bit so the
  /// extraction join and this runtime join agree by construction.
  /// 402 and 402.2 are DIFFERENT hadith records (sunnah.com uses
  /// fractional numbers for cross-chapter citations and bundles) — a floor
  /// would misattribute text (Phase B Rev. 2, found by the owner's device
  /// test run: 54 of 60 collapsed groups had genuinely different base
  /// texts). Deliberately NOT [_parseHadithNumber], which remains the
  /// DISPLAY normalization for LocalHadith.hadithNumber.
  @visibleForTesting
  static String numberKey(dynamic value) {
    if (value == null || value is bool) return '';
    var s = value is int
        ? value.toString()
        : value is num
            ? (value == value.roundToDouble()
                ? value.toInt().toString()
                : value.toString())
            : value.toString().trim();
    if (s.contains('.')) {
      s = s.replaceAll(RegExp(r'0+$'), '');
      if (s.endsWith('.')) s = s.substring(0, s.length - 1);
    }
    return s;
  }

  @visibleForTesting
  static String pairKey(dynamic hadithNumber, dynamic arabicNumber) {
    final h = numberKey(hadithNumber);
    final a = numberKey(arabicNumber);
    return (a.isEmpty || a == '0') ? '$h|$h' : '$h|$a';
  }

  /// Index a raw `hadiths` list by [pairKey]. Blank/whitespace-only texts
  /// are SKIPPED — an empty dataset text must never win the join and set
  /// hasX=true with empty content (that would break the "unavailable in
  /// this language" fallback). Duplicate keys keep the FIRST record,
  /// matching the extractor.
  @visibleForTesting
  static Map<String, String> pairTextIndex(List<dynamic> raws) {
    final out = <String, String>{};
    for (final h in raws) {
      try {
        final map = h as Map<String, dynamic>;
        final text = map['text']?.toString() ?? '';
        if (text.trim().isEmpty) continue;
        out.putIfAbsent(
          pairKey(map['hadithnumber'], map['arabicnumber']),
          () => text,
        );
      } catch (_) {
        continue;
      }
    }
    return out;
  }

  /// HR-2.2 — the ONE rule that decides a row's Urdu text, named so the renderer,
  /// the worker, the census tests and the content validator all answer to the same
  /// function instead of each restating it. (Two implementations of this join is how
  /// a fractional 402.2 once landed on its parent 402; that is on the record above.)
  ///
  /// The number-key text wins whenever it has content. The pair index rescues a blank
  /// or a missing hit and nothing else — recovering text may not cost text, so this is
  /// deliberately NOT "pair first": a pair-first join finds the same 52 rows and pays
  /// for them by blanking 9 existing translations and re-attributing 28 more
  /// (docs/HADITH_HR_PASS_REPORT.md § HR-2.2 (a) lists all 37 of them, row by row).
  ///
  /// `byPair` is only ever a NON-BLANK text, because `pairTextIndex` skips blanks — so
  /// this can never set `hasUrdu` (which is `textUrdu.isNotEmpty`) on an empty string.
  @visibleForTesting
  static String urduJoinText({
    required String byNumber,
    required String byPair,
  }) =>
      byNumber.trim().isEmpty && byPair.isNotEmpty ? byPair : byNumber;

  static int _parseHadithNumber(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is String) {
      final match = RegExp(r'^(\d+)').firstMatch(value);
      if (match != null) {
        return int.tryParse(match.group(1) ?? '0') ?? 0;
      }
      return int.tryParse(value) ?? 0;
    }
    return 0;
  }

  void dispose() {
    // Retain cached data in singleton
  }
}
