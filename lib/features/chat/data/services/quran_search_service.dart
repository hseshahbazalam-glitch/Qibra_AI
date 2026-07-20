// lib/features/chat/data/services/quran_search_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class QuranSearchResult {
  final int surahNumber;
  final int ayahNumber;
  final String arabic;
  final String urdu;
  final String english;
  final String romanUrdu;
  final double relevance;
  final String matchedIn;

  const QuranSearchResult({
    required this.surahNumber,
    required this.ayahNumber,
    required this.arabic,
    required this.urdu,
    required this.english,
    required this.romanUrdu,
    required this.relevance,
    required this.matchedIn,
  });

  String get reference => 'Quran $surahNumber:$ayahNumber';
}

class QuranSearchService {
  QuranSearchService._();
  static final QuranSearchService instance = QuranSearchService._();

  // Unified index: key = "surah:ayah"
  final Map<String, _AyahData> _index = {};
  bool _isLoaded = false;

  Future<void> initialize() async {
    if (_isLoaded) return;

    try {
      debugPrint('[QURAN_SEARCH] Loading Quran data...');

      final results = await Future.wait([
        _loadJson('assets/data/quran/quran_arabic.json'),
        _loadJson('assets/data/quran/translation_ur_junagarhi.json'),
        _loadJson('assets/data/quran/translation_en.json'),
        _loadJson('assets/data/quran/translation_ur_maududi_roman.json'),
      ]);

      _parseNestedStructure(results[0], 'arabic');
      _parseNestedStructure(results[1], 'urdu');
      _parseNestedStructure(results[2], 'english');
      _parseFlatStructure(results[3], 'roman');

      _isLoaded = true;
      debugPrint('[QURAN_SEARCH] ✅ Loaded ${_index.length} ayahs');
    } catch (e, st) {
      debugPrint('[QURAN_SEARCH] ❌ Failed: $e');
      debugPrint(st.toString());
    }
  }

  Future<Map<String, dynamic>?> _loadJson(String path) async {
    try {
      final str = await rootBundle.loadString(path);
      return jsonDecode(str) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[QURAN_SEARCH] Failed to load $path: $e');
      return null;
    }
  }

  // ============================================================
  // PARSER 1: Nested structure (Arabic, Urdu, English)
  // ============================================================

  void _parseNestedStructure(Map<String, dynamic>? data, String lang) {
    if (data == null) return;

    try {
      final root = data['data'] as Map<String, dynamic>?;
      if (root == null) return;

      final surahs = root['surahs'] as List<dynamic>?;
      if (surahs == null) return;

      for (final surah in surahs) {
        final surahMap = surah as Map<String, dynamic>;
        final surahNum = (surahMap['number'] as num).toInt();
        final ayahs = surahMap['ayahs'] as List<dynamic>? ?? [];

        for (final ayah in ayahs) {
          final ayahMap = ayah as Map<String, dynamic>;
          final ayahNum = (ayahMap['numberInSurah'] as num).toInt();
          final text = ayahMap['text']?.toString() ?? '';

          final key = '$surahNum:$ayahNum';
          final existing = _index[key] ?? _AyahData(surahNum, ayahNum);

          switch (lang) {
            case 'arabic':
              existing.arabic = text;
              break;
            case 'urdu':
              existing.urdu = text;
              break;
            case 'english':
              existing.english = text;
              break;
          }

          _index[key] = existing;
        }
      }
    } catch (e) {
      debugPrint('[QURAN_SEARCH] Parse error ($lang): $e');
    }
  }

  // ============================================================
  // PARSER 2: Flat structure (Roman Urdu)
  // ============================================================

  void _parseFlatStructure(Map<String, dynamic>? data, String lang) {
    if (data == null) return;

    try {
      final list = data['quran'] as List<dynamic>?;
      if (list == null) return;

      for (final item in list) {
        final map = item as Map<String, dynamic>;
        final surahNum = (map['chapter'] as num).toInt();
        final ayahNum = (map['verse'] as num).toInt();
        final text = map['text']?.toString() ?? '';

        final key = '$surahNum:$ayahNum';
        final existing = _index[key] ?? _AyahData(surahNum, ayahNum);

        if (lang == 'roman') {
          existing.romanUrdu = text;
        }

        _index[key] = existing;
      }
    } catch (e) {
      debugPrint('[QURAN_SEARCH] Parse error ($lang): $e');
    }
  }

  // ============================================================
  // SEARCH — keyword based
  // ============================================================

  List<QuranSearchResult> search(String query, {int maxResults = 5}) {
    if (!_isLoaded || query.isEmpty) return [];

    final lowerQuery = query.toLowerCase().trim();
    final keywords = _extractKeywords(lowerQuery);

    if (keywords.isEmpty) return [];

    final scores = <String, double>{};

    for (final entry in _index.entries) {
      final ayah = entry.value;
      double score = 0;

      for (final kw in keywords) {
        if (ayah.english.toLowerCase().contains(kw)) {
          score += 1.0;
        }
        if (ayah.romanUrdu.toLowerCase().contains(kw)) {
          score += 1.2;
        }
        if (ayah.urdu.contains(kw)) {
          score += 1.0;
        }
        if (ayah.arabic.contains(kw)) {
          score += 1.5;
        }
      }

      if (score > 0) {
        scores[entry.key] = score;
      }
    }

    final sorted = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final results = <QuranSearchResult>[];
    for (int i = 0; i < sorted.length && i < maxResults; i++) {
      final ayah = _index[sorted[i].key]!;
      results.add(QuranSearchResult(
        surahNumber: ayah.surahNumber,
        ayahNumber: ayah.ayahNumber,
        arabic: ayah.arabic,
        urdu: ayah.urdu,
        english: ayah.english,
        romanUrdu: ayah.romanUrdu,
        relevance: sorted[i].value,
        matchedIn: 'match',
      ));
    }

    return results;
  }

  // ============================================================
  // GET VERSE — Direct lookup by Surah:Ayah
  // ============================================================

  QuranSearchResult? getVerse(int surah, int ayah) {
    if (!_isLoaded) return null;

    final key = '$surah:$ayah';
    final data = _index[key];
    if (data == null) return null;

    return QuranSearchResult(
      surahNumber: data.surahNumber,
      ayahNumber: data.ayahNumber,
      arabic: data.arabic,
      urdu: data.urdu,
      english: data.english,
      romanUrdu: data.romanUrdu,
      relevance: 10.0,
      matchedIn: 'direct',
    );
  }

  List<String> _extractKeywords(String query) {
    const stopwords = {
      'the',
      'is',
      'are',
      'was',
      'were',
      'a',
      'an',
      'to',
      'of',
      'in',
      'on',
      'at',
      'for',
      'and',
      'or',
      'but',
      'what',
      'when',
      'where',
      'why',
      'how',
      'who',
      'which',
      'this',
      'that',
      'these',
      'those',
      'kya',
      'hai',
      'ka',
      'ki',
      'ke',
      'se',
      'mein',
      'aur',
      'ya',
      'batao',
      'batayen',
      'kaise',
      'kaisi',
      'importance',
    };

    final words = query
        .split(RegExp(r'\s+'))
        .map((w) => w.replaceAll(RegExp(r'[^\w\u0600-\u06FF]'), ''))
        .where((w) => w.length > 2 && !stopwords.contains(w.toLowerCase()))
        .toList();

    return words;
  }

  bool get isLoaded => _isLoaded;
  int get totalAyahs => _index.length;
}

// Internal helper class
class _AyahData {
  final int surahNumber;
  final int ayahNumber;
  String arabic = '';
  String urdu = '';
  String english = '';
  String romanUrdu = '';

  _AyahData(this.surahNumber, this.ayahNumber);
}
