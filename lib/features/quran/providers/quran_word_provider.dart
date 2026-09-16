// lib/features/quran/providers/quran_word_provider.dart
// ============================================================
// QIBRA AI — WORD LAYER PROVIDERS (Pass Q3)
// ============================================================
// Single FutureProvider: gloss spans + every available qari's word
// timings, parsed into the pure QuranWordCorpus. ANY failure resolves
// to null — the reader then renders exactly as before this pass (the
// word layer is additive by design; a missing/corrupt asset can only
// remove the extra affordances, never break the reader).
//
// Timings assets exist only for the qaris whose cue data was verified
// at build time (see scripts/build_word_data.py); a missing qari file
// is the documented honest-unavailable state — per-ayah word play
// then starts at the ayah beginning and the UI says so (never faked).
// ============================================================

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/audio/tilawat.dart';
import '../data/repository/quran_repository.dart';
import '../data/word/quran_word_data.dart';

/// The word corpus, or null when nothing verified could be loaded.
final quranWordCorpusProvider =
    FutureProvider<QuranWordCorpus?>((ref) async {
  try {
    final gloss = jsonDecode(
      await rootBundle.loadString(QuranWordCorpus.glossAsset),
    ) as Map<String, dynamic>;
    final timings = <String, Map<String, dynamic>>{};
    for (final qari in Tilawat.qaris) {
      try {
        final decoded = jsonDecode(await rootBundle
            .loadString(QuranWordCorpus.timingsAsset(qari.id)));
        if (decoded is Map<String, dynamic>) timings[qari.id] = decoded;
      } catch (_) {
        // Honest-unavailable qari: no timings file bundled for it.
        continue;
      }
    }
    return QuranWordCorpus.fromJson(
      glossJson: gloss,
      timingsByQari: timings,
    );
  } catch (_) {
    return null;
  }
});

/// How often [word] (a raw Arabic word form as displayed) occurs in
/// the app's own bundled Uthmani corpus — computed LIVE with the
/// search fold (no shipped counters; QuranAyahSearch is the single
/// definition of Arabic equivalence, not forked here). The repository
/// is the app's single Quran cache; initialize() is idempotent.
final quranWordOccurrencesProvider =
    FutureProvider.family<int, String>((ref, word) async {
  final repo = QuranRepository();
  await repo.initialize();
  return QuranWordCorpus.countOccurrences(word, repo.allAyahTextsSync());
});
