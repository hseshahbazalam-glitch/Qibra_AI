// lib/features/quran/data/search/quran_ayah_search.dart
// ============================================================
// QIBRA AI — QURAN SEARCH SCOPES + ARABIC NORMALIZER (Pass Q2)
// ============================================================
// Pure, unit-tested matching for the Quran search scope toggle
// (Translations | Arabic | All). The Arabic folding is deliberately
// SELF-CONTAINED here (feature-local mirror of the core
// search-normalizer's rules, tested hard): diacritics/tashkeel/maddah/
// small-stop marks and tatweel removed; alef family unified
// (أ إ آ ٱ → ا); ta marbuta → heh (ة → ه); alef maqsura and yaa
// carriers unified (ى ئ → ي, ؤ → و); Persian kaf → Arabic kaf. Latin
// text is lowercased; whitespace runs collapse to single spaces.
//
// Scoping rule (honest): a scope restricts WHICH field is searched —
// 'arabic' never borrows a translation hit, 'translations' never
// borrows an Arabic one, 'all' is the historical either-field match.
// No matches = the empty list; the UI shows the real empty state.

/// Which fields an ayah search consults.
enum QuranSearchScope { translations, arabic, all }

abstract final class QuranAyahSearch {
  /// Ranges removed wholesale (inert marks): Quran annotation signs,
  /// tashkeel, maddah above, small stop marks, tatweel.
  static final RegExp _inert =
      RegExp('[\\u0610-\\u061A\\u064B-\\u065F\\u0670\\u06D6-\\u06ED\\u0640]');

  /// Orthographic fold table — conservative, meaning-preserving.
  static const Map<String, String> _fold = {
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

  /// The pure normalizer: fold + strip inert marks + lowercase + collapse
  /// whitespace. Exported for direct unit-testing of the equivalence
  /// table ("ٱلْحَمْدُ" == "الحمد", "موسي" == "موسى").
  static String normalize(String src) {
    final buf = StringBuffer();
    for (int i = 0; i < src.length; i++) {
      final r = src.codeUnitAt(i);
      final ch = String.fromCharCode(r);
      if (r == 0x20 || r == 0x09 || r == 0x0A || r == 0x0D) {
        // Collapse whitespace runs; drop leading space.
        if (buf.isEmpty) continue;
        final last = buf.toString().codeUnitAt(buf.length - 1);
        if (last == 0x20) continue;
        buf.write(' ');
        continue;
      }
      if (_inert.hasMatch(ch)) continue; // diacritics/tatweel: removed
      final f = _fold[ch];
      if (f != null) {
        buf.write(f);
        continue;
      }
      // Latin casing folded; everything else passes through.
      buf.write(r < 0x80 ? ch.toLowerCase() : ch);
    }
    var out = buf.toString();
    if (out.endsWith(' ')) out = out.substring(0, out.length - 1);
    return out;
  }

  /// Core of the scoping rule — pure so repository/UI and tests share
  /// ONE definition. Returns the historical matchType (0 = Arabic text,
  /// 1 = translation) or null for no match. An empty/whitespace query
  /// matches NOTHING (documented: the UI clears results for empty
  /// queries; never match-all).
  static int? matchType({
    required QuranSearchScope scope,
    required String query,
    required String arabicText,
    String? translation,
  }) {
    final q = normalize(query);
    if (q.isEmpty) return null;
    if (scope != QuranSearchScope.translations &&
        normalize(arabicText).contains(q)) {
      return 0; // Arabic first (the historical priority, kept verbatim)
    }
    if (scope != QuranSearchScope.arabic &&
        translation != null &&
        normalize(translation).contains(q)) {
      return 1;
    }
    return null;
  }

  /// Boolean view of [matchType] (used by UI/tests that don't care
  /// which field matched).
  static bool matches({
    required QuranSearchScope scope,
    required String query,
    required String arabicText,
    String? translation,
  }) =>
      matchType(
        scope: scope,
        query: query,
        arabicText: arabicText,
        translation: translation,
      ) != null;
}
