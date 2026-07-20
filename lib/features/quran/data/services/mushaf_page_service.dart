// lib/features/quran/data/services/mushaf_page_service.dart
// ============================================================
// QIBRA AI — Mushaf Page Service v2.0
// Uses `quran` package for perfect Mushaf pages
// ============================================================

import 'package:flutter/foundation.dart';
import 'package:quran/quran.dart' as quran;

// ============================================================
// MODELS
// ============================================================

class MushafAyah {
  final int surahNumber;
  final String surahName;
  final String surahNameEnglish;
  final int ayahNumber;
  final String arabicText;
  final int juz;
  final int page;
  final bool isBismillah;

  const MushafAyah({
    required this.surahNumber,
    required this.surahName,
    required this.surahNameEnglish,
    required this.ayahNumber,
    required this.arabicText,
    required this.juz,
    required this.page,
    this.isBismillah = false,
  });
}

class MushafPageData {
  final int pageNumber;
  final int juz;
  final String primarySurahName;
  final String primarySurahNameEnglish;
  final int primarySurahNumber;
  final List<MushafAyah> ayahs;
  final Map<int, String> surahsOnPage;

  const MushafPageData({
    required this.pageNumber,
    required this.juz,
    required this.primarySurahName,
    required this.primarySurahNameEnglish,
    required this.primarySurahNumber,
    required this.ayahs,
    required this.surahsOnPage,
  });
}

// ============================================================
// SERVICE
// ============================================================

class MushafPageService {
  MushafPageService._();
  static final MushafPageService instance = MushafPageService._();

  final Map<int, MushafPageData> _pageCache = {};
  bool _isLoaded = false;

  Future<void> initialize() async {
    if (_isLoaded) return;

    try {
      debugPrint('[MUSHAF] Loading Quran pages from package...');

      // Load all 604 pages
      for (int pageNum = 1; pageNum <= 604; pageNum++) {
        _pageCache[pageNum] = _loadPage(pageNum);
      }

      _isLoaded = true;
      debugPrint('[MUSHAF] ✅ Loaded ${_pageCache.length} pages');
    } catch (e, st) {
      debugPrint('[MUSHAF] ❌ Load error: $e\n$st');
    }
  }

  MushafPageData _loadPage(int pageNumber) {
    // Get all verses on this page
    final pageVerses = quran.getVersesTextByPage(
      pageNumber,
      verseEndSymbol: false,
    );

    final ayahs = <MushafAyah>[];
    final surahsMap = <int, String>{};

    // Get raw page data (includes surah/ayah info)
    final pageData = quran.getPageData(pageNumber);

    for (final surahData in pageData) {
      final surahNumber = surahData['surah'] as int;
      final startAyah = surahData['start'] as int;
      final endAyah = surahData['end'] as int;

      final surahNameEn = quran.getSurahName(surahNumber);
      final surahNameAr = quran.getSurahNameArabic(surahNumber);

      surahsMap[surahNumber] = surahNameEn;

      for (int ayahNum = startAyah; ayahNum <= endAyah; ayahNum++) {
        final arabicText = quran.getVerse(
          surahNumber,
          ayahNum,
          verseEndSymbol: false,
        );

        // Check if this is start of surah (needs bismillah)
        final isBismillah =
            ayahNum == 1 && surahNumber != 1 && surahNumber != 9;

        ayahs.add(MushafAyah(
          surahNumber: surahNumber,
          surahName: surahNameAr,
          surahNameEnglish: surahNameEn,
          ayahNumber: ayahNum,
          arabicText: arabicText,
          juz: quran.getJuzNumber(surahNumber, ayahNum),
          page: pageNumber,
          isBismillah: isBismillah,
        ));
      }
    }

    // Primary surah on this page (first one)
    final primary = ayahs.isNotEmpty ? ayahs.first : null;

    return MushafPageData(
      pageNumber: pageNumber,
      juz: primary?.juz ?? 1,
      primarySurahName: primary?.surahName ?? '',
      primarySurahNameEnglish: primary?.surahNameEnglish ?? '',
      primarySurahNumber: primary?.surahNumber ?? 1,
      ayahs: ayahs,
      surahsOnPage: surahsMap,
    );
  }

  Future<MushafPageData?> getPage(int pageNumber) async {
    if (!_isLoaded) await initialize();
    return _pageCache[pageNumber];
  }

  MushafPageData? getPageSync(int pageNumber) {
    return _pageCache[pageNumber];
  }

  bool get isLoaded => _isLoaded;
  int get totalPages => _pageCache.length;
}
