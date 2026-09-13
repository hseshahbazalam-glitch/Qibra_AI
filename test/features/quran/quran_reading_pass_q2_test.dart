// PASS Q2 — Quran reading & tracking. (Bisect stage A: pure halves.)

import 'package:flutter_test/flutter_test.dart';
import 'package:qibra_ai/features/quran/data/repository/quran_meta.dart';
import 'package:qibra_ai/features/quran/data/repository/reading_progress_repository.dart';

({int c, Set<int> seen}) mark(
        ({int c, Set<int> seen}) from, int ayah) =>
    ReadingProgressRepository.hwApplySeen(
        contiguous: from.c, seen: from.seen, ayah: ayah);

void main() {
  group('khatm high-water — pure rules', () {
    test('contiguous run grows only through adjacent ayahs', () {
      var r = (c: 0, seen: const <int>{});
      r = mark(r, 1);
      expect(r.c, 1);
      r = mark(r, 2);
      expect(r.c, 2);
      r = mark(r, 4);
      expect(r.c, 2, reason: 'a gap never lets the run jump');
      expect(r.seen, contains(4));
      r = mark(r, 3);
      expect(r.c, 4);
      expect(r.seen, isEmpty, reason: 'absorbed ayahs leave the frontier');
    });

    test('a surah counts toward the ring ONLY when the run reaches its '
        'last ayah', () {
      final fatihahFull = {1: (c: QuranMeta.ayahCount(1), seen: const <int>{})};
      final justShort = {1: (c: 6, seen: const <int>{7})};
      final s1 = ReadingProgressRepository.khatmFrom(fatihahFull);
      expect(s1.surahsReachedEnd, 1);
      expect(s1.ayahsHighWater, 7);
      expect(s1.openedSurahs, 1);
      final s2 = ReadingProgressRepository.khatmFrom(justShort);
      expect(s2.surahsReachedEnd, 0);
      expect(s2.ayahsHighWater, 6);
      expect(s2.openedSurahs, 1);
    });

    test('coverage divides by the REAL totals and never exceeds 1.0', () {
      expect(QuranMeta.totalSurahs, 114);
      expect(QuranMeta.totalAyahs, 6236);
      const whole = KhatmStats(
          openedSurahs: 114, surahsReachedEnd: 114, ayahsHighWater: 6236);
      expect(whole.coverageFraction, 1.0);
      const over = KhatmStats(
          openedSurahs: 1, surahsReachedEnd: 0, ayahsHighWater: 9999);
      expect(over.coverageFraction, 1.0);
      const empty = KhatmStats.empty();
      expect(empty.coverageFraction, 0.0);
    });

    test('disk garbage is dropped, never trusted or fatal', () {
      final m = ReadingProgressRepository.parseHighWater(
          '{"1":{"c":-5,"s":[0,"x",-2]},"999":{"c":9},"abc":{"c":1},'
          '"2":7,"3":{"c":999999,"s":[4]},"4":{"c":1,"s":[9,200]}}');
      expect(m[1]!.c, 0);
      expect(m[1]!.seen, isEmpty);
      expect(m.containsKey(999), isFalse);
      expect(m.containsKey(2), isFalse);
      expect(m.containsKey(3), isFalse);
      expect(m[4]!.c, 1);
      expect(m[4]!.seen, {9});
      expect(ReadingProgressRepository.khatmFrom(m).ayahsHighWater, 1);
      expect(ReadingProgressRepository.parseHighWater('not json{').isEmpty,
          isTrue);
      expect(ReadingProgressRepository.parseHighWater(null).isEmpty, isTrue);
    });
  });

}
