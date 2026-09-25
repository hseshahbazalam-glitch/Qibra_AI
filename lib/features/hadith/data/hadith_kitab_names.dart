// lib/features/hadith/data/hadith_kitab_names.dart

// ============================================================
// QIBRA AI — KITAB (BOOK) NAME ACCESSOR (Pass H1)
// ============================================================
// The one pure surface for "what is this book number called".
//
// Census truth (H1 Part 0, 2026-09-25): the join target upstream —
// fawazahmed0/hadith-api, branch `1` — was fetched and read in full for
// this question. Its metadata sections dict is ENGLISH-ONLY for every
// edition (the ara-* and urd-* files repeat the very same strings), so
// native-language kitab names simply do not exist at the source. None
// were invented. The names the app already renders come from each
// bundled edition's own metadata.sections — the loader joins them by
// (collection, book_number) and this accessor is the single honest
// window onto that map, including the "no name" case:
//
//   referenced pairs across all 7 collections: 401
//   unnamed: 3 — the '0' sentinel groups (bukhari, nasai, malik)
//   → UI shows the i18n fallback label 'Book {n}', never a blank.
//
// The sidecar assets/data/hadith/kitab_names.json mirrors this census;
// test/features/hadith/hadith_pass_h1_test.dart pins ledger ⇄ shipped
// data, so a spike of unnamed books fails CI instead of shipping
// dangling chips.

/// Pure join over a book's already-loaded sections map. Deliberately
/// stateless: the DB service owns the maps, callers own the strings.
abstract final class HadithKitabNames {
  const HadithKitabNames._();

  /// The section name for [bookNumber] inside [sections], or null when
  /// the corpus carries none. Blank-only values count as none — a name
  /// that renders nothing is not a name. Callers supply the fallback
  /// label; nothing here invents one.
  static String? name(Map<String, String> sections, int bookNumber) {
    final raw = sections['$bookNumber'];
    if (raw == null) return null;
    final trimmed = raw.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Every `collection/number` pair that [refsByCollection] references
  /// but [sectionsByCollection] cannot name. Used by the H1 validator
  /// test against the shipped ledger (a drift here means data loss,
  /// which must be loud).
  static Set<String> unnamedRefs(
    Map<String, Map<String, String>> sectionsByCollection,
    Map<String, Set<int>> refsByCollection,
  ) {
    final out = <String>{};
    for (final entry in refsByCollection.entries) {
      final sections = sectionsByCollection[entry.key] ?? const {};
      for (final n in entry.value) {
        if (name(sections, n) == null) out.add('${entry.key}/$n');
      }
    }
    return out;
  }
}
