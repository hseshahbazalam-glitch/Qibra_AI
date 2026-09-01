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
const Map<String, String> _arabicFold = {
  'أ': 'ا',
  'إ': 'ا',
  'آ': 'ا',
  'ٱ': 'ا',
  'ى': 'ي',
  'ئ': 'ي',
  'ؤ': 'و',
  'ة': 'ه',
  'ک': 'ك',
};

// Tashkeel, maddah signs, small stop marks and tatweel removed wholesale.
final RegExp _arabicInert = RegExp(
  '[\u0610-\u061A\u064B-\u065F\u0670\u06D6-\u06ED\u0640]',
);

/// Normalizes a single character: folds a known variant, or drops an inert
/// diacritic (returns empty string for drops).
String _foldChar(int rune) {
  final ch = String.fromCharCode(rune);
  if (_arabicInert.hasMatch(ch)) return '';
  return _arabicFold[ch] ?? ch;
}

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
  static FoldedText fold(String source) {
    final foldedBuf = StringBuffer();
    final starts = <int>[];
    void append(String ch, int i) {
      // Collapse runs of whitespace: skip if buffer empty or last char
      // already a space.
      if (ch == ' ') {
        if (foldedBuf.isEmpty) return;
        final last = foldedBuf.toString().codeUnitAt(foldedBuf.length - 1);
        if (last == 0x20 || last == 0x09 || last == 0x0A) return;
      }
      foldedBuf.write(ch);
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
  static String foldQuery(String query) {
    final buf = StringBuffer();
    void append(String ch) {
      if (ch == ' ' && (buf.isEmpty ||
          buf.toString().codeUnitAt(buf.length - 1) == 0x20)) {
        return;
      }
      buf.write(ch);
    }

    for (int i = 0; i < query.length; i++) {
      final rune = query.codeUnitAt(i);
      if (rune == 0x20 || rune == 0x09 || rune == 0x0A || rune == 0x0D) {
        append(' ');
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
