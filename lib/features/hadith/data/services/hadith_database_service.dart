// lib/features/hadith/data/services/hadith_database_service.dart

// ============================================================
// QIBRA AI — LOCAL HADITH DATABASE SERVICE
// Version: 1.0.2 — Handles String hadith numbers (1a, 1b)
// ============================================================

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

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
    if (textEnglish.length <= 120) return textEnglish;
    return '${textEnglish.substring(0, 120)}...';
  }

  bool get hasArabic => textArabic.isNotEmpty;
  bool get hasEnglish => textEnglish.isNotEmpty;
  bool get hasUrdu => textUrdu.isNotEmpty;
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
// DATABASE SERVICE
// ============================================================

class HadithDatabaseService {
  HadithDatabaseService();

  static const Map<String, String> _bookNames = {
    'bukhari': 'Sahih al-Bukhari',
    'muslim': 'Sahih Muslim',
    'abudawud': 'Sunan Abu Dawud',
    'tirmidhi': 'Jami at-Tirmidhi',
    'nasai': "Sunan an-Nasa'i",
    'ibnmajah': 'Sunan Ibn Majah',
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
    if (_isInitialized || _isLoading) return;
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
        '- $totalHadiths hadiths loaded',
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
      debugPrint('[HADITH_DB] Loading $name...');

      final results = await Future.wait([
        _loadJsonAsset('assets/data/hadith/$slug/english.json'),
        _loadJsonAsset('assets/data/hadith/$slug/arabic.json'),
        _loadJsonAsset('assets/data/hadith/$slug/urdu.json'),
      ]);

      final englishData = results[0];
      final arabicData = results[1];
      final urduData = results[2];

      if (englishData == null) {
        debugPrint('[HADITH_DB] Failed to load English data for $slug');
        return;
      }

      final metadata = englishData['metadata'] as Map<String, dynamic>?;
      final sections = <String, String>{};
      if (metadata != null) {
        final sectionsData = metadata['sections'] as Map<String, dynamic>?;
        sectionsData?.forEach((key, value) {
          sections[key] = value.toString();
        });
      }

      final englishHadiths = englishData['hadiths'] as List<dynamic>? ?? [];
      final arabicHadiths = arabicData?['hadiths'] as List<dynamic>? ?? [];
      final urduHadiths = urduData?['hadiths'] as List<dynamic>? ?? [];

      // Build lookup maps (handles String/int hadith numbers)
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

      // Merge all languages
      final hadiths = <LocalHadith>[];
      for (final h in englishHadiths) {
        try {
          final map = h as Map<String, dynamic>;
          final hadithNum = _parseHadithNumber(map['hadithnumber']);
          final ref = map['reference'] as Map<String, dynamic>?;
          final bookNum = _parseHadithNumber(ref?['book']);
          final chapterHadithNum = _parseHadithNumber(ref?['hadith']);

          // Get grade
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
        } catch (e) {
          // Skip malformed hadith entries
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
    } catch (e) {
      debugPrint('[HADITH_DB] Failed to load $path: $e');
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
    try {
      return hadiths.firstWhere((h) => h.hadithNumber == hadithNumber);
    } catch (_) {
      return null;
    }
  }

  LocalBookInfo? getBookInfo(String bookSlug) {
    return _bookInfo[bookSlug];
  }

  List<LocalBookInfo> getAllBookInfos() {
    return _bookInfo.values.toList();
  }

  // ─── DAILY / RANDOM HADITH ──────────────────────────────

  LocalHadith? getDailyHadith() {
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

        if (hadith.textEnglish.toLowerCase().contains(lowerQuery)) {
          relevance = _calculateRelevance(hadith.textEnglish, lowerQuery);
          matchedIn = 'english';
        }

        if (hadith.textArabic.contains(query)) {
          const arabicRelevance = 0.9;
          if (arabicRelevance > relevance) {
            relevance = arabicRelevance;
            matchedIn = 'arabic';
          }
        }

        if (hadith.textUrdu.contains(query)) {
          const urduRelevance = 0.85;
          if (urduRelevance > relevance) {
            relevance = urduRelevance;
            matchedIn = 'urdu';
          }
        }

        if (hadith.chapterName.toLowerCase().contains(lowerQuery)) {
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

  String searchForAI(String query, {int maxResults = 5}) {
    final results = search(query, maxResults: maxResults);

    if (results.isEmpty) {
      return 'No hadith found for query: "$query"';
    }

    final buffer = StringBuffer();
    buffer.writeln('Found ${results.length} relevant hadith(s):');
    buffer.writeln('');

    for (int i = 0; i < results.length; i++) {
      final h = results[i].hadith;
      buffer.writeln('--- Hadith ${i + 1} ---');
      buffer.writeln('Book: ${h.bookName}');
      buffer.writeln('Hadith Number: ${h.hadithNumber}');
      buffer.writeln('Chapter: ${h.chapterName}');
      if (h.grade.isNotEmpty) buffer.writeln('Grade: ${h.grade}');
      buffer.writeln('English: ${h.textEnglish}');
      if (h.hasArabic) buffer.writeln('Arabic: ${h.textArabic}');
      if (h.hasUrdu) buffer.writeln('Urdu: ${h.textUrdu}');
      buffer.writeln('Reference: ${h.displayReference}');
      buffer.writeln('');
    }

    return buffer.toString();
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

  // ─── HELPER: Parse hadith number (handles String/int) ────
  /// Handles various formats:
  /// - int: 123
  /// - String number: "123"
  /// - String with letter: "1a", "1b", "123c"
  int _parseHadithNumber(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toInt();
    if (value is String) {
      // Extract leading digits (handles "1a", "1b" formats)
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
    _bookData.clear();
    _bookInfo.clear();
    _isInitialized = false;
    debugPrint('[HADITH_DB] Database disposed');
  }
}
