// lib/features/hadith/data/services/hadith_database_service.dart
// ============================================================
// QIBRA AI — LOCAL HADITH DATABASE SERVICE (Multi-Book & Multi-Language)
// Singleton instance to prevent multiple re-decoding passes.
// ============================================================

import 'dart:convert';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/search_normalizer.dart';
import '../hadith_availability.dart';


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
// LOCAL HADITH MODEL
// ============================================================

class LocalHadith {
  final int hadithNumber;
  final int arabicNumber;
  final String textArabic;
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

  const LocalHadith({
    required this.hadithNumber,
    required this.arabicNumber,
    required this.textArabic,
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
  });

  String get id => '${bookSlug}_$hadithNumber';
  String get displayReference => '$bookName $hadithNumber';

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
    if (textArabic.length <= 120) return textArabic;
    return '${textArabic.substring(0, 120)}...';
  }

  bool get hasArabic => textArabic.trim().isNotEmpty;
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
    debugPrint('[HADITH_DB] Initializing database...');
    final stopwatch = Stopwatch()..start();

    try {
      for (final entry in _bookNames.entries) {
        await _loadBook(entry.key, entry.value);
      }

      _isInitialized = true;
      stopwatch.stop();
      debugPrint(
        '[HADITH_DB] Initialized in ${stopwatch.elapsedMilliseconds}ms '
        '- $totalHadiths hadiths loaded across ${_bookData.length} collections',
      );
    } catch (e) {
      debugPrint('[HADITH_DB] Initialization error: $e');
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

  // ─── LOAD SINGLE BOOK ────────────────────────────────────

  Future<void> _loadBook(String slug, String name) async {
    try {
      // Phase B: the four new language editions load in the SAME
      // per-book Future.wait batch as the originals (existing pattern
      // deliberately kept — see Phase B report; no new isolate exists
      // for loading in this service today).
      final newLangs = HadithAvailability.newLanguageFiles.entries.toList();
      final results = await Future.wait([
        _loadJsonAsset('assets/data/hadith/$slug/english.json'),
        _loadJsonAsset('assets/data/hadith/$slug/arabic.json'),
        _loadJsonAsset('assets/data/hadith/$slug/urdu.json'),
        for (final lang in newLangs)
          _loadJsonAsset('assets/data/hadith/$slug/${lang.value}.json'),
      ]);

      final englishData = results[0];
      final arabicData = results[1];
      final urduData = results[2];

      if (englishData == null && arabicData == null && urduData == null) {
        return;
      }

      final baseData = englishData ?? arabicData ?? urduData;
      if (baseData == null) return;

      final metadata = baseData['metadata'] as Map<String, dynamic>?;
      final sections = <String, String>{};
      if (metadata != null) {
        final sectionsData = metadata['sections'] as Map<String, dynamic>?;
        sectionsData?.forEach((key, value) {
          sections[key] = value.toString();
        });
      }

      final englishHadiths = englishData?['hadiths'] as List<dynamic>? ?? [];
      final arabicHadiths = arabicData?['hadiths'] as List<dynamic>? ?? [];
      final urduHadiths = urduData?['hadiths'] as List<dynamic>? ?? [];

      // Build lookup maps
      final arabicMap = <int, String>{};
      for (final h in arabicHadiths) {
        try {
          final map = h as Map<String, dynamic>;
          final hNum = _parseHadithNumber(map['hadithnumber']);
          arabicMap[hNum] = map['text']?.toString() ?? '';
        } catch (_) {
          continue;
        }
      }

      final urduMap = <int, String>{};
      for (final h in urduHadiths) {
        try {
          final map = h as Map<String, dynamic>;
          final hNum = _parseHadithNumber(map['hadithnumber']);
          urduMap[hNum] = map['text']?.toString() ?? '';
        } catch (_) {
          continue;
        }
      }

      // Phase B language joins: keyed by the (hadithnumber,
      // arabicnumber) PAIR — never by array index — because our shipped
      // record sets differ from the dataset's (bukhari 7,589 raw vs
      // 7,563 keyed; tirmidhi 3,998 vs 3,956; muslim's fractional
      // arabicnumbers). A missing pair means the language has nothing
      // for that hadith -> '' -> hasX false.
      final langIndices = <String, Map<(int, int), String>>{
        for (var i = 0; i < newLangs.length; i++)
          newLangs[i].key: pairTextIndex(
            results[3 + i]?['hadiths'] as List<dynamic>? ?? const [],
          ),
      };

      final primaryHadiths = englishHadiths.isNotEmpty
          ? englishHadiths
          : (arabicHadiths.isNotEmpty ? arabicHadiths : urduHadiths);

      final hadiths = <LocalHadith>[];
      for (final h in primaryHadiths) {
        try {
          final map = h as Map<String, dynamic>;
          final hadithNum = _parseHadithNumber(map['hadithnumber']);
          final ref = map['reference'] as Map<String, dynamic>?;
          final bookNum = _parseHadithNumber(ref?['book']);
          final chapterHadithNum = _parseHadithNumber(ref?['hadith']);

          final grades = map['grades'] as List<dynamic>? ?? [];
          String gradeStr = '';
          if (grades.isNotEmpty) {
            final firstGrade = grades.first;
            if (firstGrade is Map<String, dynamic>) {
              gradeStr = firstGrade['grade']?.toString() ?? '';
            }
          }

          final chapterName = sections[bookNum.toString()] ?? '';
          final arabicNum = _parseHadithNumber(map['arabicnumber']);
          final pair = pairKey(hadithNum, arabicNum);

          hadiths.add(LocalHadith(
            hadithNumber: hadithNum,
            arabicNumber: arabicNum == 0 ? hadithNum : arabicNum,
            textEnglish: map['text']?.toString() ?? '',
            textArabic: arabicMap[hadithNum] ?? '',
            textUrdu: urduMap[hadithNum] ?? '',
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
          ));
        } catch (_) {
          continue;
        }
      }

      _bookData[slug] = hadiths;
      _bookInfo[slug] = LocalBookInfo(
        slug: slug,
        name: name,
        sections: sections,
        totalHadiths: hadiths.length,
      );

      debugPrint('[HADITH_DB] Loaded $name: ${hadiths.length} hadiths');
    } catch (e) {
      debugPrint('[HADITH_DB] Error loading $slug: $e');
    }
  }

  Future<Map<String, dynamic>?> _loadJsonAsset(String path) async {
    try {
      final jsonString = await rootBundle.loadString(path);
      return jsonDecode(jsonString) as Map<String, dynamic>;
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

        if (SearchNormalizer.contains(hadith.textArabic, query)) {
          const arabicRelevance = 0.9;
          if (arabicRelevance > relevance) {
            relevance = arabicRelevance;
            matchedIn = 'arabic';
          }
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
        // Arabic/Urdu fixed-relevance precedence is untouched.
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
  Future<List<List<LocalSearchResult>>> searchBatchOffMain(
    List<String> queries, {
    int maxPerQuery = 3,
  }) async {
    if (queries.isEmpty) return [for (final _ in queries) <LocalSearchResult>[]];
    if (!_isInitialized) return [for (final _ in queries) <LocalSearchResult>[]];
    final booksSnapshot = Map<String, List<LocalHadith>>.of(_bookData);
    final terms = queries.map((q) => q.toLowerCase().trim()).toList();
    return Isolate.run(() {
      final hits = <List<LocalSearchResult>>[
        for (final _ in queries) <LocalSearchResult>[],
      ];
      for (final entry in booksSnapshot.entries) {
        for (final hadith in entry.value) {
          for (var qi = 0; qi < queries.length; qi++) {
            if (hits[qi].length >= maxPerQuery * 4) continue;
            final q = queries[qi];
            final lq = terms[qi];
            double relevance = 0;
            String matchedIn = '';
            if (SearchNormalizer.contains(hadith.textEnglish, q)) {
              relevance = hadithRelevanceFor(hadith.textEnglish, lq);
              matchedIn = 'english';
            }
            if (SearchNormalizer.contains(hadith.textArabic, q) &&
                0.9 > relevance) {
              relevance = 0.9;
              matchedIn = 'arabic';
            }
            if (SearchNormalizer.contains(hadith.textUrdu, q) &&
                0.85 > relevance) {
              relevance = 0.85;
              matchedIn = 'urdu';
            }
            if (SearchNormalizer.contains(hadith.chapterName, q) &&
                relevance == 0) {
              relevance = 0.5;
              matchedIn = 'chapter';
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
    });
  }

  /// Pair key used by the Phase B language join — the exact same
  /// normalization the primary loop applies to a base record's
  /// (hadithNumber, arabicNumber) (arabic 0 falls back to hadith num,
  /// mirroring LocalHadith.arabicNumber). @visibleForTesting so the
  /// multilang test pins join semantics without booting Flutter.
  @visibleForTesting
  static (int, int) pairKey(int hadithNumber, int arabicNumber) =>
      (hadithNumber, arabicNumber == 0 ? hadithNumber : arabicNumber);

  /// Index a raw `hadiths` list by [pairKey]. Empty/whitespace texts are
  /// skipped (they must NOT shadow nothing with garbage); duplicate keys
  /// keep the FIRST record, matching scripts/extract_hadith_languages.py.
  @visibleForTesting
  static Map<(int, int), String> pairTextIndex(List<dynamic> raws) {
    final out = <(int, int), String>{};
    for (final h in raws) {
      try {
        final map = h as Map<String, dynamic>;
        final text = map['text']?.toString() ?? '';
        if (text.trim().isEmpty) continue;
        out.putIfAbsent(
          pairKey(
            _parseHadithNumber(map['hadithnumber']),
            _parseHadithNumber(map['arabicnumber']),
          ),
          () => text,
        );
      } catch (_) {
        continue;
      }
    }
    return out;
  }

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
