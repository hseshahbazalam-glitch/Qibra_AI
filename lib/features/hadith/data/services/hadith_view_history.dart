// lib/features/hadith/data/services/hadith_view_history.dart
// ============================================================
// QIBRA AI — HADITH VIEW HISTORY (P1 · Item 4)
// ============================================================
// "Recently Read" is a pure LRU list of '<bookSlug>#<hadithNumber>'
// references in SharedPreferences — the same persistence substrate as
// bookmarks and reading progress. That is ALL the app knows:
// no timestamps, no view counts, nothing fabricated. Cap: 50 entries.

import 'package:shared_preferences/shared_preferences.dart';

class HadithViewHistory {
  const HadithViewHistory._();

  static const String storageKey = 'qibra_hadith_history_v1';
  static const int cap = 50;

  static String ref(String bookSlug, int hadithNumber) =>
      '$bookSlug#$hadithNumber';

  /// Malformed entries parse to null and are skipped, never guessed.
  static ({String bookSlug, int hadithNumber})? parseRef(String raw) {
    final i = raw.lastIndexOf('#');
    if (i <= 0 || i == raw.length - 1) return null;
    final num = int.tryParse(raw.substring(i + 1));
    if (num == null || num <= 0) return null;
    return (bookSlug: raw.substring(0, i), hadithNumber: num);
  }

  /// Most-recent-first refs, newest at index 0.
  static Future<List<String>> entries() async {
    final prefs = await SharedPreferences.getInstance();
    return List<String>.unmodifiable(
      prefs.getStringList(storageKey) ?? const <String>[],
    );
  }

  /// Record one view: dedupe, move to front, trim to [cap].
  static Future<void> record(String bookSlug, int hadithNumber) async {
    if (bookSlug.isEmpty || hadithNumber <= 0) return;
    final entry = ref(bookSlug, hadithNumber);
    final list = List<String>.from(await entries())
      ..remove(entry)
      ..insert(0, entry);
    if (list.length > cap) list.removeRange(cap, list.length);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(storageKey, list);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
  }
}
