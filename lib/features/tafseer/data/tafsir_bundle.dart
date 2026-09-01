// lib/features/tafseer/data/tafsir_bundle.dart
// Tafsir dataset sidecar: Tafsir Ibn Kathir (abridged), English.
// The text is bundled VERBATIM from a published dataset (upstream repo
// + commit pinned in assets/data/content_manifest.json and in the asset
// metadata itself). It is never generated at build time and never
// AI-composed under a scholar's name. Ayah -> passage ranges are
// precomputed in the asset and are contiguous, non-overlapping and
// total-cover per surah (guarded by test/content_pass_test.dart).

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class TafsirPassage {
  const TafsirPassage({
    required this.surah,
    required this.start,
    required this.end,
    required this.text,
  });

  final int surah;
  final int start;
  final int end;
  final String text;
}

class TafsirBundle {
  TafsirBundle._(this.credit, this._bySurah);

  /// Visible source credit shown next to every passage.
  final String credit;
  final Map<int, List<TafsirPassage>> _bySurah;

  int get surahCount => _bySurah.length;
  int get passageCount =>
      _bySurah.values.fold(0, (sum, list) => sum + list.length);

  TafsirPassage? passageFor(int surah, int ayah) {
    final list = _bySurah[surah];
    if (list == null) return null;
    for (final p in list) {
      if (ayah >= p.start && ayah <= p.end) return p;
    }
    return null;
  }

  static Future<TafsirBundle?> load() async {
    try {
      final raw = await rootBundle
          .loadString('assets/data/tafsir/ibn_kathir_en.json');
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final meta = json['metadata'] as Map<String, dynamic>;
      final surahs = json['surahs'] as Map<String, dynamic>;
      final bySurah = <int, List<TafsirPassage>>{};
      surahs.forEach((key, value) {
        final s = int.parse(key);
        bySurah[s] = [
          for (final e in (value as List<dynamic>))
            TafsirPassage(
              surah: s,
              start: (e['s'] as num).toInt(),
              end: (e['e'] as num).toInt(),
              text: e['t'] as String,
            ),
        ];
      });
      return TafsirBundle._(meta['credit'] as String, bySurah);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('tafsir bundle unavailable: $e');
      }
      return null;
    }
  }
}

final tafsirBundleProvider =
    FutureProvider.autoDispose<TafsirBundle?>((ref) => TafsirBundle.load());
