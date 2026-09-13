// PASS Q2 — Quran reading & tracking. (Bisect stage A: pure halves.)
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:qibra_ai/features/quran/data/repository/quran_meta.dart';
import 'package:qibra_ai/features/quran/data/repository/reading_progress_repository.dart';
import 'package:qibra_ai/features/quran/data/search/quran_ayah_search.dart';

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

  group('QuranAyahSearch', () {
    test('normalizer: tashkeel/tatweel die, letters fold, latin folds', () {
      expect(QuranAyahSearch.normalize('بِسْمِ  اللَّهِ'), 'بسم الله');
      expect(QuranAyahSearch.normalize('ٱلْحَمْدُ'), 'الحمد');
      expect(QuranAyahSearch.normalize('مُوسَى'), equals('موسي'));
      expect(QuranAyahSearch.normalize('مُوسٰى'), equals('موسي'));
      expect(QuranAyahSearch.normalize('کتاب'), 'كتاب');
      expect(QuranAyahSearch.normalize('  The   Lord  '), 'the lord');
    });

    test('scopes filter FIELDS — never borrow hits across them', () {
      const arabic = 'وَضَجَّ النَّارَ';
      const english = 'the blazing fire';
      expect(
          QuranAyahSearch.matchType(
              scope: QuranSearchScope.translations,
              query: 'fire',
              arabicText: arabic,
              translation: english),
          1);
      expect(
          QuranAyahSearch.matchType(
              scope: QuranSearchScope.arabic,
              query: 'fire',
              arabicText: arabic,
              translation: english),
          isNull);
      expect(
          QuranAyahSearch.matchType(
              scope: QuranSearchScope.arabic,
              query: 'النار',
              arabicText: arabic,
              translation: english),
          0);
      expect(
          QuranAyahSearch.matchType(
              scope: QuranSearchScope.translations,
              query: 'النار',
              arabicText: arabic,
              translation: english),
          isNull);
      expect(
          QuranAyahSearch.matchType(
              scope: QuranSearchScope.all,
              query: 'fire',
              arabicText: arabic,
              translation: english),
          1);
    });

    test('empty/whitespace query matches NOTHING (never match-all)', () {
      for (final scope in QuranSearchScope.values) {
        expect(
            QuranAyahSearch.matchType(
                scope: scope,
                query: '   ',
                arabicText: 'الحمد',
                translation: 'praise'),
            isNull);
      }
    });

    test('bundled data honors the scopes (real translation file)', () {
      final decoded = jsonDecode(
              File('assets/data/quran/translation_en.json').readAsStringSync())
          as Map<String, dynamic>;
      final surahs =
          ((decoded['data'] as Map)['surahs'] as List).cast<Map>();
      final ayahs = (surahs.first['ayahs'] as List).cast<Map>();
      final firstAyahEn = ayahs.first['text'] as String;
      expect(firstAyahEn.length, greaterThan(12));
      const basmala = 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ';
      final probe = firstAyahEn.substring(3, 9).toLowerCase();
      expect(
          QuranAyahSearch.matchType(
              scope: QuranSearchScope.translations,
              query: probe,
              arabicText: basmala,
              translation: firstAyahEn),
          1);
      expect(
          QuranAyahSearch.matchType(
              scope: QuranSearchScope.arabic,
              query: 'الرَّحِيم',
              arabicText: basmala,
              translation: firstAyahEn),
          0);
      expect(
          QuranAyahSearch.matchType(
              scope: QuranSearchScope.arabic,
              query: probe,
              arabicText: basmala,
              translation: firstAyahEn),
          isNull);
    });
  });

  group('source guards (pinned behavior without device access)', () {
    test('mushaf: the pager reverses exactly once; jump math matches', () {
      final src =
          File('lib/features/quran/presentation/mushaf_reader_screen.dart')
              .readAsStringSync();
      final pagers = RegExp('PageView\\.builder\\(').allMatches(src).length;
      final reversals = RegExp('reverse:\\s*true').allMatches(src).length;
      expect(pagers, 1, reason: 'exactly one page pager');
      expect(reversals, 1,
          reason: 'reversed exactly once — left-edge swipe advances');
      expect(src, contains('jumpToPage(saved.pageNumber - 1)'));
      expect(src, isNot(contains('Directionality(')),
          reason: 'no double-reversal override anywhere in the screen');
    });

    test('search wiring: repo threads the scope; notifier owns it', () {
      final repoSrc =
          File('lib/features/quran/data/repository/quran_repository.dart')
              .readAsStringSync();
      expect(repoSrc,
          contains('QuranSearchScope scope = QuranSearchScope.all'));
      expect(repoSrc, contains('_searchInIsolate(query, scope)'));
      expect(
          RegExp('QuranAyahSearch\\.matchType\\(').allMatches(repoSrc).length,
          2);
      final provSrc =
          File('lib/features/quran/providers/quran_provider.dart')
              .readAsStringSync();
      expect(provSrc, contains('search(query, scope: _scope)'));
      expect(provSrc, contains('Future<void> setScope(QuranSearchScope'));
    });

    test('deep play: routes parse ?play=; entries offer it; sheet intact',
        () {
      final router = File('lib/core/router/app_router.dart').readAsStringSync();
      expect(
          RegExp('playParam == \'1\' \\|\\| playParam == \'true\'')
              .allMatches(router)
              .length,
          2);
      expect(router, contains('playOnOpen: play'));
      final searchSrc =
          File('lib/features/quran/presentation/quran_search_screen.dart')
              .readAsStringSync();
      expect(searchSrc, contains('onPlay: () => _openAyah(result, play: true)'));
      expect(searchSrc, contains('playOnOpen: play'));
      final hubSrc =
          File('lib/features/bookmarks/presentation/bookmarks_hub_screen.dart')
              .readAsStringSync();
      expect(hubSrc, contains('_openAyah(item, play: true)'));
      expect(hubSrc, contains('playOnOpen: play'));
      final sheet =
          File('lib/features/quran/presentation/ayah_options_sheet.dart')
              .readAsStringSync();
      expect(sheet, contains('playAyah'));
    });

    test('compare toggle + streak honesty are wired at their anchors', () {
      final reader =
          File('lib/features/quran/presentation/surah_reader_screen.dart')
              .readAsStringSync();
      expect(reader, contains('if (prefs.translationCompare && '
          'activeTab == \'Translation\') ...['));
      expect(reader, contains('this.playOnOpen = false'));
      expect(reader, contains('_didAutoPlay = true;'));
      final home = File('lib/features/quran/presentation/quran_screen.dart')
          .readAsStringSync();
      expect(home, contains('Icons.hourglass_bottom_rounded'));
      expect(home, contains('AppStrings.of(context).noStreakYet'));
      expect(home, contains('progress.khatm.coverageFraction'));
      expect(home, contains('AppStrings.of(context).khatmHonestCaption'));
      final prefs =
          File('lib/features/quran/providers/reading_preferences_provider.dart')
              .readAsStringSync();
      expect(prefs, contains('_translation_compare'));
      expect(prefs, contains('setTranslationCompare'));
    });

    test('all Q2 strings carry three locales and the parsed shape', () {
      final src = File('lib/core/l10n/app_strings.dart').readAsStringSync();
      for (final name in [
        'khatmCoverage',
        'khatmSummary',
        'khatmHonestCaption',
        'noStreakYet',
        'compareTranslations',
        'compareTranslationsHint',
        'bundledTranslationsForAyah',
        'searchScope',
        'scopeTranslations',
        'scopeArabic',
        'scopeAll',
        'playFromHere',
      ]) {
        expect(src, contains(name), reason: 'missing getter: $name');
      }
      expect(src, contains('String get scopeAll => _t('));
    });
  });
}
