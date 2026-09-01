// lib/features/hadith/data/services/hadith_database_service.dart
// ============================================================
// QIBRA AI — LOCAL HADITH DATABASE SERVICE (Multi-Book & Multi-Language)
// Singleton instance to prevent multiple re-decoding passes.
// ============================================================

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../../../../core/utils/search_normalizer.dart';

// ============================================================
// LOCAL HADITH MODEL
// ============================================================

class LocalHadith {
  final int hadithNumber;
  final int arabicNumber;
  final String textArabic;
  final String textEnglish;
  final String textUrdu;
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
    if (textArabic.length <= 120) return textArabic;
    return '${textArabic.substring(0, 120)}...';
  }

  bool get hasArabic => textArabic.trim().isNotEmpty;
  bool get hasEnglish => textEnglish.trim().isNotEmpty;
  bool get hasUrdu => textUrdu.trim().isNotEmpty;
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
      final results = await Future.wait([
        _loadJsonAsset('assets/data/hadith/$slug/english.json'),
        _loadJsonAsset('assets/data/hadith/$slug/arabic.json'),
        _loadJsonAsset('assets/data/hadith/$slug/urdu.json'),
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

          hadiths.add(LocalHadith(
            hadithNumber: hadithNum,
            arabicNumber: arabicNum == 0 ? hadithNum : arabicNum,
            textEnglish: map['text']?.toString() ?? '',
            textArabic: arabicMap[hadithNum] ?? '',
            textUrdu: urduMap[hadithNum] ?? '',
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

  LocalHadith? getDailyHadith() {
    final bukhariHadiths = _bookData['bukhari'];
    if (bukhariHadiths != null && bukhariHadiths.isNotEmpty) {
      final now = DateTime.now();
      final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
      final index = dayOfYear % bukhariHadiths.length;
      return bukhariHadiths[index];
    }
    final allHadiths = _getAllHadiths();
    if (allHadiths.isEmpty) return null;

    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
    final index = dayOfYear % allHadiths.length;
    return allHadiths[index];
  }

  LocalHadith? getRandomHadith() {
    final allHadiths = _getAllHadiths();
    if (allHadiths.isEmpty) return null;

    final index = DateTime.now().millisecondsSinceEpoch % allHadiths.length;
    return allHadiths[index];
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

  double _calculateRelevance(String text, String query) {
    final lowerText = text.toLowerCase();

    if (lowerText.startsWith(query)) return 1.0;
    if (lowerText.contains(' $query ')) return 0.9;
    if (lowerText.contains(' $query')) return 0.85;

    final occurrences = query.allMatches(lowerText).length;
    return (0.5 + (occurrences * 0.1)).clamp(0.0, 0.8);
  }

  int _parseHadithNumber(dynamic value) {
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

  // ─── STATISTICS ──────────────────────────────────────────

  Map<String, dynamic> get statistics {
    return {
      'isInitialized': _isInitialized,
      'totalBooks': _bookData.length,
      'totalHadiths': totalHadiths,
      'books': _bookInfo.map((key, value) => MapEntry(key, {
            'name': value.name,
            'hadiths': value.totalHadiths,
            'chapters': value.sections.length,
          })),
    };
  }

  void dispose() {
    // Retain cached data in singleton
  }
}
