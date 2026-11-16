// lib/core/utils/search_normalizer.dart

// ============================================================
// QIBRA AI — SEARCH NORMALIZER
// Stage 3 — shared text normalization for Quran & Hadith search.
//
// Purpose: users type Arabic with or without tashkeel/hamza forms,
// and search UIs previously compared raw lowercase strings — so
// "الرحمن" would not match "ٱلرَّحْمَٰن". This normalizer folds both
// sides before comparison while keeping an index map back to the
// ORIGINAL string so highlights stay truthful.
//
// Pure Dart, zero dependencies: unit-tested in phase19.
// ============================================================

/// Folding table applied after diacritics removal. Maps orthographic
/// variants onto a single canonical letter (standard Arabic search
/// folding — conservative, no meaning changes).
///
/// KEYED BY UTF-16 UNIT, not by `String`, and every key is one BMP code unit
/// (the keys and their values are pinned against the pre-HR-1.3 rule by the
/// differential test in
/// test/features/hadith/hadith_hotfix_hr13_fold_cache_test.dart):
/// the fold loop runs per code unit, and building a `String` in order to hash a
/// 9-entry table is a large share of what a fold costs. HOTFIX HR-1.3 measured
/// the per-char version at 128.5 ns/char on a CI runner, x 15.4 M english chars
/// of shipped corpus = 1,979 ms for ONE pre-pass over one field — and the
/// pre-pass is now paid at every boot, so its constant is a shipping number.
const Map<int, String> _arabicFoldByRune = {
  0x0623: '\u0627', // أ -> ا
  0x0625: '\u0627', // إ -> ا
  0x0622: '\u0627', // آ -> ا
  0x0671: '\u0627', // ٱ -> ا
  0x0649: '\u064a', // ى -> ي
  0x0626: '\u064a', // ئ -> ي
  0x0624: '\u0648', // ؤ -> و
  0x0629: '\u0647', // ة -> ه
  0x06a9: '\u0643', // ک -> ك
};

// Tashkeel, maddah signs, small stop marks and tatweel removed wholesale.
// Written as the ranges the old `RegExp('[\u0610-\u061A\u064B-\u065F'
// '\u0670\u06D6-\u06ED\u0640]')` matched, in the same order: a range test
// on the code unit is the same predicate, without the regex engine per
// character (see the note on [_arabicFoldByRune]).
bool _isInertRune(int rune) =>
    (rune >= 0x0610 && rune <= 0x061A) ||
    (rune >= 0x064B && rune <= 0x065F) ||
    rune == 0x0670 ||
    (rune >= 0x06D6 && rune <= 0x06ED) ||
    rune == 0x0640;

/// Normalizes a single character: folds a known variant, or drops an inert
/// diacritic (returns empty string for drops).
String _foldChar(int rune) {
  if (_isInertRune(rune)) return '';
  return _arabicFoldByRune[rune] ?? String.fromCharCode(rune);
}

/// The ASCII case of the fold, decided without a map, a `String.fromCharCode`
/// or a `toLowerCase()` call: an ASCII letter folds to its lowercase and every
/// other ASCII unit folds to itself (the table above has no ASCII keys and the
/// inert ranges are all >= 0x0610). That is most of the western half of the
/// corpus — 15.4 M of the shipped 52.3 M searched chars — and it is the reason
/// the settle-time pre-pass is a boot cost instead of a boot freeze.
bool _isAsciiUpper(int rune) => rune >= 0x41 && rune <= 0x5A;

/// Result of folding a source string: the folded text plus a per-position
/// map back into the ORIGINAL string (folded position i was produced by
/// original position originalStart[i]).
class FoldedText {
  FoldedText._(this.source, this.folded, this.originalStart);

  /// The untouched source string.
  final String source;

  /// Case-folded + normalized text, safe to `indexOf` into.
  final String folded;

  /// originalStart[i] = index in [source] whose fold begins at folded i.
  final List<int> originalStart;

  /// Maps an end index in [folded] (exclusive) to an end index in [source]
  /// (exclusive). Returns source.length when the fold ends at the very end.
  int foldedEndToSource(int foldedEnd) {
    if (foldedEnd >= folded.length) return source.length;
    return originalStart[foldedEnd];
  }
}

/// Arabic + Latin search normalizer.
abstract final class SearchNormalizer {
  /// Fold [source] for matching (lowercase, Arabic normalization).
  /// Whitespace is collapsed to single spaces *while building* so the
  /// folded→original index map never shifts.
  ///
  /// HOTFIX HR-1.3 — the collapse test reads a tracked `lastUnit` instead of
  /// `foldedBuf.toString().codeUnitAt(len - 1)`. Asking a StringBuffer for its
  /// own contents MATERIALIZES IT: one fresh copy of the whole partially-built
  /// string, per whitespace character, and real hadith text has a space every
  /// 5-6 characters. So a fold cost (length x spaces) rather than length — a
  /// 1,400-char row paid ~240 copies averaging 700 chars, x 4 fields x 36,390
  /// rows x every keystroke. That is the device's "the scan never finishes"
  /// (owner log: six `scan request N, budget 90s`, zero `answered`), and the
  /// output is bit-identical: the guard asks the same question, in a variable.
  static FoldedText fold(String source) {
    final foldedBuf = StringBuffer();
    final starts = <int>[];
    // -1 = nothing written yet. Every `append` writes a non-empty [ch], so the
    // buffer's last unit is always exactly the last unit of the last [ch].
    var lastUnit = -1;
    void append(String ch, int i) {
      // Collapse runs of whitespace: skip if buffer empty or last char
      // already a space.
      if (ch == ' ') {
        if (lastUnit == -1) return;
        if (lastUnit == 0x20 || lastUnit == 0x09 || lastUnit == 0x0A) return;
      }
      foldedBuf.write(ch);
      lastUnit = ch.codeUnitAt(ch.length - 1);
      starts.add(i);
    }

    for (int i = 0; i < source.length; i++) {
      final rune = source.codeUnitAt(i);
      if (rune == 0x09 || rune == 0x0A || rune == 0x0D) {
        append(' ', i);
        continue;
      }
      if (rune == 0x20) {
        append(' ', i);
        continue;
      }
      if (rune < 0x0080) {
        // See [_isAsciiUpper]: the ASCII answer is arithmetic, not a lookup.
        final unit = _isAsciiUpper(rune) ? rune + 32 : rune;
        foldedBuf.writeCharCode(unit);
        lastUnit = unit;
        starts.add(i);
        continue;
      }
      final f = _foldChar(rune);
      if (f.isEmpty) continue;
      append(f.toLowerCase(), i);
    }
    // Trailing space: drop it and its mapping (no leading spaces can exist
    // because append() skips whitespace on an empty buffer).
    var folded = foldedBuf.toString();
    if (folded.endsWith(' ')) {
      folded = folded.substring(0, folded.length - 1);
      starts.removeLast();
    }
    return FoldedText._(source, folded, starts);
  }

  /// Fold a query the same way (no index map needed).
  ///
  /// This is [foldText] under the name the search bars use — one
  /// implementation on purpose: a query folded by a different rule than the
  /// corpus would silently drop hits, and `fold` above is not reusable for the
  /// corpus-side of HR-1.3 because building its index map per row is the cost
  /// being removed.
  static String foldQuery(String query) => foldText(query);

  /// [fold]'s folded string, WITHOUT the per-character index map back into the
  /// source. For a corpus-wide pre-pass (HOTFIX HR-1.3: the hadith worker
  /// folds every row ONCE at hand-off and matches with `indexOf` afterwards),
  /// where the map is 4 bytes per character of retained or thrown-away memory
  /// for a position nobody will highlight.
  ///
  /// Bit-identical to `fold(source).folded` — same append, same collapse, same
  /// trailing-space drop, pinned by
  /// test/features/hadith/hadith_hotfix_hr13_fold_cache_test.dart.
  static String foldText(String source) {
    final buf = StringBuffer();
    // See the note on [fold]: the last written unit is tracked, never
    // re-materialised out of the buffer.
    var lastUnit = -1;
    void append(String ch) {
      if (ch == ' ' && (lastUnit == -1 || lastUnit == 0x20)) return;
      buf.write(ch);
      lastUnit = ch.codeUnitAt(ch.length - 1);
    }

    for (int i = 0; i < source.length; i++) {
      final rune = source.codeUnitAt(i);
      if (rune == 0x20 || rune == 0x09 || rune == 0x0A || rune == 0x0D) {
        append(' ');
        continue;
      }
      if (rune < 0x0080) {
        // Same ASCII answer as `fold`, same reason (see [_isAsciiUpper]).
        final unit = _isAsciiUpper(rune) ? rune + 32 : rune;
        buf.writeCharCode(unit);
        lastUnit = unit;
        continue;
      }
      final f = _foldChar(rune);
      if (f.isNotEmpty) append(f.toLowerCase());
    }
    var q = buf.toString();
    if (q.endsWith(' ')) q = q.substring(0, q.length - 1);
    return q;
  }

  /// First match of [query] in [text] after normalization. Returns spans in
  /// ORIGINAL-text coordinates so UI highlights point at real characters.
  static ({int start, int end})? firstMatch(String text, String query) {
    final f = fold(text);
    final q = foldQuery(query);
    if (q.isEmpty) return null;
    final idx = f.folded.indexOf(q);
    if (idx == -1) return null;
    return (start: f.originalStart[idx], end: f.foldedEndToSource(idx + q.length));
  }

  /// All non-overlapping matches of [query] in [text] (original coords).
  static List<({int start, int end})> allMatches(String text, String query) {
    final f = fold(text);
    final q = foldQuery(query);
    final out = <({int start, int end})>[];
    if (q.isEmpty) return out;
    var idx = f.folded.indexOf(q);
    while (idx != -1) {
      out.add((
        start: f.originalStart[idx],
        end: f.foldedEndToSource(idx + q.length),
      ));
      idx = f.folded.indexOf(q, idx + q.length);
    }
    return out;
  }

  /// Plain contains check using the same folding.
  static bool contains(String text, String query) =>
      firstMatch(text, query) != null;
}
