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
// test/features/hadith/hadith_multilang_test.dart (matrix ⇔ data on disk). If a file is
// added/removed here and on disk, that test fails by construction.
//
// PASS X5 (bundle diet, 2026-11-12): the four Phase B editions (bengali,
// turkish, indonesian, french) are UNBUNDLED — 27 JSON files, 119.7 MB of
// `assets/data/hadith/` (the shipped bundle carried 48 files where the boot
// path reads 21). They are removed from THIS map, which is the single source
// of truth: the Settings selector, the book quick-settings sheet and
// [HadithLanguageNotifier]'s supported set all derive from here, so the
// selector now offers exactly the three editions whose files ship, and a
// stale `bn`/`tr`/`id`/`fr` value in SharedPreferences falls back to English
// (`_load` already filters through `supported`) instead of opening a screen
// with no file behind it. The pair-key FOLD SEAM stays wired on purpose —
// [newLanguageFiles] is empty, so `warmLanguage` answers false for every
// code, `_loadBook`'s wanted-batch stays the base trio, and a future
// re-bundle is a data drop plus one map row, not a refactor.

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
  static const List<String> languageCodes = ['en', 'ar', 'ur'];

  /// Native names — what a reader of that language expects to see.
  static const Map<String, String> labelFor = {
    'en': 'English',
    'ar': 'العربية',
    'ur': 'اردو',
  };

  /// Which books each language covers — every bundled edition is 7/7.
  static const Map<String, List<String>> booksForLanguage = {
    'en': kHadithBookSlugs,
    'ar': kHadithBookSlugs,
    'ur': kHadithBookSlugs,
  };

  /// Asset file stem per non-English language inside each book directory
  /// (english.json is the structural base the loader starts from).
  static const Map<String, String> fileForLanguage = {
    'ar': 'arabic',
    'ur': 'urdu',
  };

  /// The pair-key joined editions (Phase B mechanism) that ship in this
  /// bundle. EMPTY since X5: the four files were unbundled, and this map is
  /// what [warmLanguage] consults — so every warm request is a no-op and the
  /// boot batch is exactly `english + fileForLanguage.values` per book.
  /// Re-bundling a language = put its JSON back + add one row here (the
  /// loader, the coverage math and the selector all follow automatically).
  static const Map<String, String> newLanguageFiles = {};

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

  // ─── Pass H1: parity-disclosure math (ADDITIVE — the pinned matrix
  // maps and selectorOptions() above are untouched by construction;
  // hadith_pass_h1_test byte-pins them) ─────────────────────────────

  /// Display names for disclosure sentences. Same strings the loader's
  /// private table uses; kept here so the pure note math never reaches
  /// into the singleton (and UI widgets never hand-write a book name
  /// next to a percentage).
  static const Map<String, String> bookDisplayNames = {
    'bukhari': 'Sahih al-Bukhari',
    'muslim': 'Sahih Muslim',
    'nasai': "Sunan an-Nasa'i",
    'abudawud': 'Sunan Abi Dawud',
    'tirmidhi': 'Jami` at-Tirmidhi',
    'ibnmajah': 'Sunan Ibn Majah',
    'malik': 'Muwatta Malik',
  };

  /// Percent of [total] rows that actually carry text, ROUNDED to the
  /// nearest whole number (a floored 10% would understate 10.9% just
  /// as a rounded-up 12% would overstate — honest math is symmetric).
  static int coveragePercent(int nonEmpty, int total) =>
      total <= 0 ? 0 : (100 * nonEmpty + total ~/ 2) ~/ total;

  /// Language/book pairs that need a depth note: an absent edition is
  /// always disclosed (percent 0, [absent] true); a present one when
  /// its text coverage is below [noteThresholdPercent]. Pairs the
  /// caller cannot count (null entry — e.g. corpus not loaded yet) are
  /// never guessed: they simply produce no row.
  static List<({String language, String book, int percent, bool absent})>
      thinCoverage(
    Map<String, Map<String, ({int nonEmpty, int total})>> countsByBook, {
    int noteThresholdPercent = 90,
  }) {
    final rows =
        <({String language, String book, int percent, bool absent})>[];
    for (final code in languageCodes) {
      for (final book in kHadithBookSlugs) {
        if (!hasBook(code, book)) {
          rows.add(
              (language: code, book: book, percent: 0, absent: true));
          continue;
        }
        final c = countsByBook[book]?[code];
        if (c == null) continue;
        final pct = coveragePercent(c.nonEmpty, c.total);
        if (pct < noteThresholdPercent) {
          rows.add((
            language: code,
            book: book,
            percent: pct,
            absent: false
          ));
        }
      }
    }
    rows.sort((a, b) => a.percent != b.percent
        ? a.percent.compareTo(b.percent)
        : a.language.compareTo(b.language));
    return rows;
  }
}
