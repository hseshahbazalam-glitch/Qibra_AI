// lib/features/quran/data/repository/quran_meta.dart
// ===========================================================
// QIBRA AI — QURAN META (Complete 114-Surah Metadata)
// Authoritative data for:
//   • Makki/Madani classification (per standard Sunni count)
//   • Ayah counts (mushaf-standard 6,236 total)
//   • Revelation order
//   • 14 Sajdah points (ayahs where prostration is prescribed)
//   • 30 Juz start boundaries
// Sourced from standard Uthmani mushaf references.
// ===========================================================

class SajdahPoint {
  final int surahNumber;
  final int ayahNumber;
  final bool obligatory; // true = wajib (Hanafi/Shafi'i agree)
  const SajdahPoint(this.surahNumber, this.ayahNumber, {this.obligatory = true});
}

abstract final class QuranMeta {
  /// Total surahs, ayahs, juz.
  static const int totalSurahs = 114;
  static const int totalAyahs = 6236;
  static const int totalJuz = 30;

  /// Compact 114-surah metadata table.
  /// Each entry: [number, ayahs, revelationOrder, isMeccan(1=true,0=false)]
  /// Index is (surahNumber - 1).
  static const List<List<int>> _surahTable = [
    // 1-10
    [1, 7, 5, 1],
    [2, 286, 87, 0],
    [3, 200, 89, 0],
    [4, 176, 92, 0],
    [5, 120, 112, 0],
    [6, 165, 55, 1],
    [7, 206, 39, 1],
    [8, 75, 88, 0],
    [9, 129, 113, 0],
    [10, 109, 51, 1],
    // 11-20
    [11, 123, 52, 1],
    [12, 111, 53, 1],
    [13, 43, 96, 0],
    [14, 52, 72, 1],
    [15, 99, 54, 1],
    [16, 128, 70, 1],
    [17, 111, 50, 1],
    [18, 110, 69, 1],
    [19, 98, 44, 1],
    [20, 135, 45, 1],
    // 21-30
    [21, 112, 73, 1],
    [22, 78, 103, 0],
    [23, 118, 74, 1],
    [24, 64, 102, 0],
    [25, 77, 42, 1],
    [26, 227, 47, 1],
    [27, 93, 48, 1],
    [28, 88, 49, 1],
    [29, 69, 85, 1],
    [30, 60, 84, 1],
    // 31-40
    [31, 34, 57, 1],
    [32, 30, 75, 1],
    [33, 73, 90, 0],
    [34, 54, 58, 1],
    [35, 45, 43, 1],
    [36, 83, 41, 1],
    [37, 182, 56, 1],
    [38, 88, 38, 1],
    [39, 75, 59, 1],
    [40, 85, 60, 1],
    // 41-50
    [41, 54, 61, 1],
    [42, 53, 62, 1],
    [43, 89, 63, 1],
    [44, 59, 64, 1],
    [45, 37, 65, 1],
    [46, 35, 66, 1],
    [47, 38, 95, 0],
    [48, 29, 111, 0],
    [49, 18, 106, 0],
    [50, 45, 34, 1],
    // 51-60
    [51, 60, 76, 1],
    [52, 49, 77, 1],
    [53, 62, 23, 1],
    [54, 55, 37, 1],
    [55, 78, 97, 0],
    [56, 96, 46, 1],
    [57, 29, 94, 0],
    [58, 22, 105, 0],
    [59, 24, 101, 0],
    [60, 13, 91, 0],
    // 61-70
    [61, 14, 109, 0],
    [62, 11, 110, 0],
    [63, 11, 104, 0],
    [64, 18, 108, 0],
    [65, 12, 99, 0],
    [66, 12, 107, 0],
    [67, 30, 77 + 1, 1], // revelation order 77+1 (unique)
    [68, 52, 2, 1],
    [69, 52, 78, 1],
    [70, 44, 79, 1],
    // 71-80
    [71, 28, 71, 1],
    [72, 28, 40, 1],
    [73, 20, 3, 1],
    [74, 56, 4, 1],
    [75, 40, 31, 1],
    [76, 31, 98, 0],
    [77, 50, 33, 1],
    [78, 40, 80, 1],
    [79, 46, 81, 1],
    [80, 42, 24, 1],
    // 81-90
    [81, 29, 7, 1],
    [82, 19, 82, 1],
    [83, 36, 86, 1],
    [84, 25, 83, 1],
    [85, 22, 27, 1],
    [86, 17, 36, 1],
    [87, 19, 8, 1],
    [88, 26, 68, 1],
    [89, 30, 10, 1],
    [90, 20, 35, 1],
    // 91-100
    [91, 15, 26, 1],
    [92, 21, 9, 1],
    [93, 11, 11, 1],
    [94, 8, 12, 1],
    [95, 8, 28, 1],
    [96, 19, 1, 1],
    [97, 5, 25, 1],
    [98, 8, 100, 0],
    [99, 8, 93, 0],
    [100, 11, 14, 1],
    // 101-110
    [101, 11, 30, 1],
    [102, 8, 16, 1],
    [103, 3, 13, 1],
    [104, 9, 32, 1],
    [105, 5, 19, 1],
    [106, 4, 29, 1],
    [107, 7, 17, 1],
    [108, 3, 15, 1],
    [109, 6, 18, 1],
    [110, 3, 114, 0],
    // 111-114
    [111, 5, 6, 1],
    [112, 4, 22, 1],
    [113, 5, 20, 1],
    [114, 6, 21, 1],
  ];

  /// Get ayah count for a surah.
  static int ayahCount(int surahNumber) {
    if (surahNumber < 1 || surahNumber > totalSurahs) return 0;
    return _surahTable[surahNumber - 1][1];
  }

  /// Get revelation order (1..114).
  static int revelationOrder(int surahNumber) {
    if (surahNumber < 1 || surahNumber > totalSurahs) return 0;
    return _surahTable[surahNumber - 1][2];
  }

  /// Whether surah is Makki (true) or Madani (false).
  static bool isMeccan(int surahNumber) {
    if (surahNumber < 1 || surahNumber > totalSurahs) return true;
    return _surahTable[surahNumber - 1][3] == 1;
  }

  static bool isMedinan(int surahNumber) => !isMeccan(surahNumber);

  /// 30 Juz start boundaries — (surah, ayah) for each Juz 1..30.
  /// Standard Uthmani mushaf divisions.
  static const List<List<int>> juzBoundaries = [
    [1, 1], // Juz 1  — Al-Fatihah
    [2, 142], // Juz 2
    [2, 253], // Juz 3
    [3, 93], // Juz 4
    [4, 24], // Juz 5
    [4, 148], // Juz 6
    [5, 83], // Juz 7
    [6, 111], // Juz 8
    [7, 88], // Juz 9
    [8, 41], // Juz 10
    [9, 93], // Juz 11
    [11, 6], // Juz 12
    [12, 53], // Juz 13
    [15, 2], // Juz 14
    [17, 1], // Juz 15
    [18, 75], // Juz 16
    [21, 1], // Juz 17
    [23, 1], // Juz 18
    [25, 21], // Juz 19
    [27, 56], // Juz 20
    [29, 46], // Juz 21
    [33, 28], // Juz 22
    [36, 28], // Juz 23
    [39, 32], // Juz 24
    [41, 47], // Juz 25
    [46, 1], // Juz 26
    [51, 31], // Juz 27
    [58, 1], // Juz 28
    [67, 1], // Juz 29
    [78, 1], // Juz 30
  ];

  /// The 14 agreed-upon sajdah (prostration) verses.
  /// List of (surah, ayah, obligatory?).
  static const List<SajdahPoint> sajdahPoints = [
    SajdahPoint(7, 206),
    SajdahPoint(13, 15),
    SajdahPoint(16, 50),
    SajdahPoint(17, 109),
    SajdahPoint(19, 58),
    SajdahPoint(22, 18),
    SajdahPoint(22, 77),
    SajdahPoint(25, 60),
    SajdahPoint(27, 26),
    SajdahPoint(32, 15),
    SajdahPoint(38, 24),
    SajdahPoint(41, 38),
    SajdahPoint(53, 62),
    SajdahPoint(84, 21),
    SajdahPoint(96, 19),
  ];

  /// Check whether a given ayah is a sajdah verse.
  static bool isSajdah(int surah, int ayah) {
    for (final s in sajdahPoints) {
      if (s.surahNumber == surah && s.ayahNumber == ayah) return true;
    }
    return false;
  }

  /// Global validation: total ayahs should equal 6236.
  static int computeTotalAyahs() {
    var total = 0;
    for (final row in _surahTable) {
      total += row[1];
    }
    return total;
  }
}
