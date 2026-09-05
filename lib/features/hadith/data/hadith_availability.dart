// lib/features/hadith/data/hadith_availability.dart
// ============================================================
// QIBRA AI — HADITH TRANSLATION AVAILABILITY MATRIX (Phase B, 2026-09-05)
// ============================================================
// ONE source of truth for: which languages the app offers, what each is
// called natively, which books each language actually covers, and which
// asset file carries it. The Settings language selector and the
// HadithLanguageNotifier's supported set are BOTH derived from this map —
// nothing downstream may hardcode a language list.
//
// Pinned against the real bundled JSON files by
// test/hadith_multilang_test.dart (matrix ⇔ data on disk). If a file is
// added/removed here and on disk, that test fails by construction.
//
// French honesty note: the dataset (fawazahmed0/hadith-api) ships no
// fra-tirmidhi edition, so French covers SIX of seven books. The chosen
// mechanism is per-hadith fallback rather than a selector lock: in
// Tirmidhi every French text is simply absent, and each card shows the
// existing "Verified translation unavailable for this language." line —
// the same fallback that already serves the 67 empty tirmidhi/urdu texts.
// The selector itself discloses the coverage count.

/// The seven bundled collections, in app order.
const List<String> kHadithBookSlugs = [
  'bukhari',
  'muslim',
  'abudawud',
  'nasai',
  'tirmidhi',
  'ibnmajah',
  'malik',
];

class HadithAvailability {
  const HadithAvailability._();

  /// UI codes in selector order: ISO-639-1 (state codes — the app's
  /// language-code convention; the dataset's 3-letter edition prefixes
  /// ben/tur/ind/fra live only in the extraction tooling).
  static const List<String> languageCodes = ['en', 'ar', 'ur', 'bn', 'tr', 'id', 'fr'];

  /// Native names — what a reader of that language expects to see.
  static const Map<String, String> labelFor = {
    'en': 'English',
    'ar': 'العربية',
    'ur': 'اردو',
    'bn': 'বাংলা',
    'tr': 'Türkçe',
    'id': 'Bahasa Indonesia',
    'fr': 'Français',
  };

  /// Which books each language covers. 'fr' is six of seven by data
  /// absence (see header). Every entry is the full list for the rest.
  static const Map<String, List<String>> booksForLanguage = {
    'en': kHadithBookSlugs,
    'ar': kHadithBookSlugs,
    'ur': kHadithBookSlugs,
    'bn': kHadithBookSlugs,
    'tr': kHadithBookSlugs,
    'id': kHadithBookSlugs,
    'fr': ['bukhari', 'muslim', 'abudawud', 'nasai', 'ibnmajah', 'malik'],
  };

  /// Asset file stem per non-English language inside each book directory
  /// (english.json is the structural base the loader starts from).
  static const Map<String, String> fileForLanguage = {
    'ar': 'arabic',
    'ur': 'urdu',
    'bn': 'bengali',
    'tr': 'turkish',
    'id': 'indonesian',
    'fr': 'french',
  };

  /// Phase B additions loaded by pair-key join (arabic/urdu keep their
  /// historical hadithnumber-only join in the loader — untouched).
  static const Map<String, String> newLanguageFiles = {
    'bn': 'bengali',
    'tr': 'turkish',
    'id': 'indonesian',
    'fr': 'french',
  };

  static int bookCount(String languageCode) =>
      booksForLanguage[languageCode]?.length ?? 0;

  static int get fullCoverageCount => kHadithBookSlugs.length;

  static bool hasBook(String languageCode, String bookSlug) =>
      booksForLanguage[languageCode]?.contains(bookSlug) ?? false;

  static String label(String languageCode) =>
      labelFor[languageCode] ?? languageCode;

  /// Selector rows, derived (never hardcoded): (code, native label,
  /// optional coverage note for languages below full book coverage).
  static List<({String code, String label, String? note})> selectorOptions() {
    return [
      for (final code in languageCodes)
        (
          code: code,
          label: label(code),
          note: bookCount(code) < fullCoverageCount
              ? '${bookCount(code)} of $fullCoverageCount collections'
              : null,
        ),
    ];
  }
}
