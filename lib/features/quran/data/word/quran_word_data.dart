// lib/features/quran/data/word/quran_word_data.dart
// ============================================================
// QIBRA AI — WORD LAYER (Pass Q3): PURE DATA + VALIDATION
// ============================================================
// Word-level Arabic spans (with English glosses) and per-ayah word
// timing cues, loaded from the datasets under assets/data/quran/
// (see scripts/build_word_data.py for provenance + rebuild).
//
// THE HONESTY CORE — the alignment validator: every ayah's shipped
// spans are checked against the app's OWN canonical Uthmani text via
// the fold-join identity (QuranAyahSearch.normalize over the rejoined
// spans). A mismatch NEVER renders words with possibly-wrong mapping:
// the ayah degrades to whole-ayah behavior (tap = existing options
// sheet, play = ayah start). Validation results are memoized per ayah
// key — one cheap string pass per ayah per app run.
//
// Word timings are per-reciter (cue windows were measured against the
// exact everyayah per-ayah files the app streams). A qari without a
// timings dataset has NO word-exact seek — callers must surface the
// honest "playing from ayah start" notice, never fake a sync.
// ============================================================

import '../search/quran_ayah_search.dart';

/// One rendered word + its gloss (empty gloss = honestly unavailable).
class WordSpan {
  const WordSpan({required this.word, required this.gloss});
  final String word;
  final String gloss;
}

/// Word layer of one ayah. [basmalaLead] = how many leading spans are
/// the reused 1:1 basmala words for a sura-head ayah (1:1 itself and
/// surah 9 never carry a lead; timing indices address the SAME span
/// space, so the file is index-truth).
class AyahWords {
  const AyahWords({required this.basmalaLead, required this.spans});

  final int basmalaLead;
  final List<WordSpan> spans;
}

/// One word-timing cue: [span] indexes the ayah's rendered word spans
/// (basmala lead included); start/end are ms into the ayah's audio file.
class WordCue {
  const WordCue({
    required this.span,
    required this.startMs,
    required this.endMs,
  });

  final int span;
  final int startMs;
  final int endMs;
}

/// The whole bundled word corpus (glosses + per-qari cues), pure —
/// decodes already-loaded JSON so tests run without the asset bundle.
class QuranWordCorpus {
  QuranWordCorpus._({
    required Map<String, AyahWords> byKey,
    required Map<String, Map<String, List<WordCue>>> timingsByQari,
  })  : _byKey = byKey,
        _timings = timingsByQari;

  final Map<String, AyahWords> _byKey;
  final Map<String, Map<String, List<WordCue>>> _timings;
  final Map<String, bool> _alignMemo = {};

  static const String glossAsset = 'assets/data/quran/word_gloss_en.json';
  static String timingsAsset(String qariId) =>
      'assets/data/quran/word_timings_$qariId.json';

  /// Parse decoded JSON into the corpus. Shape mirrors the builder's
  /// output; unknown extra keys are ignored (forward-compatible).
  factory QuranWordCorpus.fromJson({
    required Map<String, dynamic> glossJson,
    Map<String, Map<String, dynamic>> timingsByQari = const {},
  }) {
    final byKey = <String, AyahWords>{};
    final ayahs = glossJson['ayahs'];
    if (ayahs is Map) {
      ayahs.forEach((key, entry) {
        if (key is! String || entry is! Map) return;
        final spansRaw = entry['w'];
        if (spansRaw is! List || spansRaw.isEmpty) return;
        final spans = <WordSpan>[];
        for (final s in spansRaw) {
          if (s is List && s.length >= 2 && s[0] is String) {
            spans.add(WordSpan(word: s[0] as String, gloss: '${s[1]}'));
          }
        }
        if (spans.length != spansRaw.length) return; // malformed — absent
        final p = entry['p'];
        byKey[key] = AyahWords(
          basmalaLead: p is int ? p : 0,
          spans: List<WordSpan>.unmodifiable(spans),
        );
      });
    }
    final timings = <String, Map<String, List<WordCue>>>{};
    timingsByQari.forEach((qari, doc) {
      final map = <String, List<WordCue>>{};
      final a = doc['ayahs'];
      if (a is Map) {
        a.forEach((key, cues) {
          if (key is! String || cues is! List) return;
          final list = <WordCue>[];
          for (final c in cues) {
            if (c is List &&
                c.length >= 3 &&
                c[0] is int &&
                c[1] is int &&
                c[2] is int) {
              list.add(WordCue(
                  span: c[0] as int, startMs: c[1] as int, endMs: c[2] as int));
            }
          }
          if (list.isNotEmpty) {
            map[key] = List<WordCue>.unmodifiable(list);
          }
        });
      }
      timings[qari] = Map<String, List<WordCue>>.unmodifiable(map);
    });
    return QuranWordCorpus._(byKey: byKey, timingsByQari: timings);
  }

  static String _key(int s, int a) => '$s:$a';

  int get ayahsWithWords => _byKey.length;
  int get totalCuedAyahs => _timings.values.fold(
      0, (sum, m) => sum + m.length);

  /// The ayah's word layer ONLY IF it aligns to [canonicalText] (memoized
  /// fold-join identity, see header). Null → whole-ayah mode.
  AyahWords? wordsFor(int surah, int ayah, String canonicalText) {
    final entry = _byKey[_key(surah, ayah)];
    if (entry == null) return null;
    final k = _key(surah, ayah);
    final ok = _alignMemo[k] ??=
        normalizeUnits(unitize(canonicalText).join(' ')) ==
            normalizeUnits(entry.spans.map((w) => w.word).join(' '));
    if (!ok) return null;
    return entry;
  }

  /// Timings for one ayah under [qariId] — null when this qari has no
  /// dataset or this ayah has no cue coverage (caller then shows the
  /// honest ayah-start notice).
  List<WordCue>? cuesFor(String qariId, int surah, int ayah) =>
      _timings[qariId]?[_key(surah, ayah)];

  bool hasTimingsFor(String qariId) => _timings.containsKey(qariId);

  /// The seek target (ms) for word [span]: the cue's start clamped to
  /// non-negative, or null (whole-ayah start). Pure + testable.
  static int? seekStartMs(List<WordCue>? cues, int span) {
    if (cues == null) return null;
    for (final c in cues) {
      if (c.span == span) {
        return c.startMs < 0 ? 0 : c.startMs;
      }
    }
    return null;
  }

  /// Which span (if any) is sounding at [posMs] inside the ayah — the
  /// word-highlight window helper (used only when the playing qari has
  /// cues; the reader's gold ayah highlight itself stays ayah-level).
  static int? spanAtMs(List<WordCue>? cues, int posMs) {
    if (cues == null) return null;
    for (final c in cues) {
      if (posMs >= c.startMs && posMs < c.endMs) return c.span;
    }
    return null;
  }

  // ─── pure helpers mirrored 1:1 from the builder ───────────────────

  /// Whitespace word-units: marker-only runs (Uthmani pause signs that
  /// stand as their own whitespace token) attach to the PREVIOUS unit —
  /// faithful to the ayah text modulo the single whitespace that stood
  /// before such a mark, and word counts then match the dataset's
  /// streams (the validator compares under the space-free fold).
  static List<String> unitize(String text) {
    final out = <String>[];
    var lead = '';
    for (final raw in text.split(RegExp(r'\s+'))) {
      if (raw.isEmpty) continue;
      if (normalizeUnits(raw).isEmpty) {
        if (out.isNotEmpty) {
          out[out.length - 1] = '${out[out.length - 1]}$raw';
        } else {
          lead = '$lead$raw';
        }
        continue;
      }
      out.add('$lead$raw');
      lead = '';
    }
    return out;
  }

  /// [QuranAyahSearch.normalize] with whitespace and the ZWNBSP
  /// (U+FEFF) fully removed — the alignment identity both the builder
  /// and this validator agree on (spaces only separate; they never
  /// carry meaning for equality). ZWNBSP must go too: Dart's RegExp \s
  /// follows ECMAScript, which counts U+FEFF as whitespace (Python's
  /// re does not) — so a leading ZWNJ in the app's own 1:1 is consumed
  /// as a SEPARATOR by [unitize] while it stays glued to the dataset's
  /// span word. Treating it as the inert mark it is — on both sides —
  /// is what keeps the fold honest (CI run 35179679229 caught exactly
  /// this asymmetry at 1:1).
  static String normalizeUnits(String s) =>
      QuranAyahSearch.normalize(s).replaceAll(' ', '').replaceAll('\uFEFF', '');

  /// Occurrences of a word FORM across the corpus, LIVE over the app's
  /// own bundled texts with the search fold (never a shipped number —
  /// the spec's honesty rule; the builder prints the same count and
  /// tests pin it against real data).
  static int countOccurrences(String word, Iterable<String> ayahTexts) {
    final target = normalizeUnits(word);
    if (target.isEmpty) return 0;
    var n = 0;
    for (final text in ayahTexts) {
      for (final t in text.split(RegExp(r'\s+'))) {
        if (t.isEmpty) continue;
        if (normalizeUnits(t) == target) n++;
      }
    }
    return n;
  }
}
