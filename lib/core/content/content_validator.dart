// Validates bundled Quran structure without rewriting JSON.
// Expected: 114 surahs, 6236 ayahs.

class ContentValidationResult {
  const ContentValidationResult({
    required this.ok,
    required this.surahCount,
    required this.ayahCount,
    this.issues = const [],
  });

  final bool ok;
  final int surahCount;
  final int ayahCount;
  final List<String> issues;
}

abstract final class ContentValidator {
  static const int expectedSurahs = 114;
  static const int expectedAyahs = 6236;

  /// Canonical ayah counts per surah (1-indexed via list index 0 unused).
  static const List<int> ayahsPerSurah = [
    0,
    7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111, 43, 52, 99, 128,
    111, 110, 98, 135, 112, 78, 118, 64, 77, 227, 93, 88, 69, 60, 34, 30, 73,
    54, 45, 83, 182, 88, 75, 85, 54, 53, 89, 59, 37, 35, 38, 29, 18, 45, 60,
    49, 62, 55, 78, 96, 29, 22, 24, 13, 14, 11, 11, 18, 12, 12, 30, 52, 52,
    44, 28, 28, 20, 56, 40, 31, 50, 40, 46, 42, 29, 19, 36, 25, 22, 17, 19,
    26, 30, 20, 15, 21, 11, 8, 8, 19, 5, 8, 8, 11, 11, 8, 3, 9, 5, 4, 7, 3,
    6, 3, 5, 4, 5, 6,
  ];

  static ContentValidationResult validateCounts({
    required int surahCount,
    required int ayahCount,
    List<int>? perSurah,
  }) {
    final issues = <String>[];
    if (surahCount != expectedSurahs) {
      issues.add('Surah count $surahCount != $expectedSurahs');
    }
    if (ayahCount != expectedAyahs) {
      issues.add('Ayah count $ayahCount != $expectedAyahs');
    }
    if (perSurah != null) {
      if (perSurah.length != expectedSurahs) {
        issues.add('per-surah length ${perSurah.length} != $expectedSurahs');
      } else {
        for (var i = 0; i < expectedSurahs; i++) {
          if (perSurah[i] != ayahsPerSurah[i + 1]) {
            issues.add('Surah ${i + 1} has ${perSurah[i]}, expected ${ayahsPerSurah[i + 1]}');
          }
        }
      }
    }
    return ContentValidationResult(
      ok: issues.isEmpty,
      surahCount: surahCount,
      ayahCount: ayahCount,
      issues: issues,
    );
  }
}
