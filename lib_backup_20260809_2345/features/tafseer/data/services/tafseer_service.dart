// lib/features/tafseer/data/services/tafseer_service.dart

// ============================================================
// QIBRA AI — TAFSEER IBN KATHIR SERVICE
// Version: 1.0.0
// Description: Loads Tafseer Ibn Kathir Urdu from local JSON.
//              6236 ayahs across 114 surahs.
// ============================================================

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

// ============================================================
// MODEL
// ============================================================

class TafseerAyah {
  final int surahNumber;
  final int ayahNumber;
  final String text;

  const TafseerAyah({
    required this.surahNumber,
    required this.ayahNumber,
    required this.text,
  });

  factory TafseerAyah.fromJson(Map<String, dynamic> json) {
    return TafseerAyah(
      surahNumber: (json['surah'] as num?)?.toInt() ?? 0,
      ayahNumber: (json['ayah'] as num?)?.toInt() ?? 0,
      text: json['text']?.toString() ?? '',
    );
  }

  bool get hasText => text.isNotEmpty;

  /// Short preview (first 100 chars)
  String get preview {
    if (text.length <= 100) return text;
    return '${text.substring(0, 100)}...';
  }
}

// ============================================================
// SERVICE
// ============================================================

class TafseerService {
  TafseerService();

  // Cache: surah number → list of ayah tafseers
  final Map<int, List<TafseerAyah>> _cache = {};

  static const String _basePath = 'assets/data/tafseer/ibn_kathir_urdu';

  /// Get all tafseer ayahs for a specific surah
  Future<List<TafseerAyah>> getSurahTafseer(int surahNumber) async {
    // Check cache first
    if (_cache.containsKey(surahNumber)) {
      return _cache[surahNumber]!;
    }

    try {
      final path = '$_basePath/$surahNumber.json';
            final jsonString = await rootBundle.loadString(path);
      final decoded = jsonDecode(jsonString);

      // Handle both formats: array OR {"ayahs": [...]}
      List<dynamic> ayahsList;
      if (decoded is List) {
        ayahsList = decoded;
      } else if (decoded is Map<String, dynamic>) {
        ayahsList = decoded['ayahs'] as List<dynamic>? ?? [];
      } else {
        ayahsList = [];
      }

      final ayahs = ayahsList
          .map((item) => TafseerAyah.fromJson(item as Map<String, dynamic>))
          .toList();

      _cache[surahNumber] = ayahs;

      debugPrint(
        '[TAFSEER] Loaded Surah $surahNumber: ${ayahs.length} ayahs',
      );

      return ayahs;
    } catch (e) {
      debugPrint('[TAFSEER] Failed to load Surah $surahNumber: $e');
      return [];
    }
  }

  /// Get tafseer for specific ayah
  Future<TafseerAyah?> getAyahTafseer(
    int surahNumber,
    int ayahNumber,
  ) async {
    final surahTafseer = await getSurahTafseer(surahNumber);
    try {
      return surahTafseer.firstWhere(
        (t) => t.ayahNumber == ayahNumber,
      );
    } catch (_) {
      return null;
    }
  }

  /// Clear cache (free memory)
  void clearCache() {
    _cache.clear();
    debugPrint('[TAFSEER] Cache cleared');
  }

  /// Check if surah is cached
  bool isSurahCached(int surahNumber) {
    return _cache.containsKey(surahNumber);
  }

  /// Get cache statistics
  Map<String, dynamic> get statistics {
    return {
      'cachedSurahs': _cache.length,
      'totalAyahs':
          _cache.values.fold<int>(0, (sum, list) => sum + list.length),
    };
  }
}
