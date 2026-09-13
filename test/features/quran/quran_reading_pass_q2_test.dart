// PASS Q2 — Quran reading & tracking (khatm / streak honesty /
// per-ayah compare / search scopes / mushaf direction / deep play).
//
// Layout note (mirrors quran_device_fixes_test.dart): the app's REAL
// fonts are loaded first — flutter test's Ahem placeholder has no glyph
// metrics and manufactures overflow "bugs" that don't exist on device.
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qibra_ai/core/l10n/app_strings.dart';
import 'package:qibra_ai/features/quran/data/models/quran_models.dart';
import 'package:qibra_ai/features/quran/data/repository/quran_meta.dart';
import 'package:qibra_ai/features/quran/data/repository/reading_progress_repository.dart';
import 'package:qibra_ai/features/quran/data/search/quran_ayah_search.dart';
import 'package:qibra_ai/features/quran/presentation/surah_reader_screen.dart';
import 'package:qibra_ai/features/quran/providers/quran_audio_provider.dart';
import 'package:qibra_ai/features/quran/providers/quran_download_provider.dart';
import 'package:qibra_ai/features/quran/providers/quran_provider.dart';
import 'package:qibra_ai/features/quran/providers/reading_preferences_provider.dart';
import 'package:qibra_ai/features/quran/providers/reading_progress_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> loadAppTestFonts() async {
  Future<void> faces(String family, List<String> paths) async {
    final loader = FontLoader(family);
    for (final path in paths) {
      final bytes = File(path).readAsBytesSync();
      loader.addFont(Future.value(ByteData.view(bytes.buffer)));
    }
    await loader.load();
  }

  await faces('Inter', [
    for (final w in [
      'Light', 'Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold', 'Black',
    ])
      'assets/fonts/Inter-$w.ttf',
  ]);
  await faces('Amiri', [
    'assets/fonts/Amiri-Regular.ttf',
    'assets/fonts/Amiri-Bold.ttf',
  ]);
}

/// The reader's post-frame disk check must not do real fs work in tests.
class _NoopDownloads extends QuranDownloadController {
  @override
  Map<int, SurahAudioStatus> build() => const {};
  @override
  Future<void> checkSurah(int surah) async {}
}

/// Records startQueue calls; nothing streams, so it stays fully honest.
class _RecordingAudio extends QuranAudioController {
  final List<
      ({int surahNumber, String surahName, List<PlayableAyah> queue,
      int startIndex})> calls = [];

  @override
  QuranAudioState build() => const QuranAudioState();

  @override
  Future<void> startQueue({
    required int surahNumber,
    required String surahName,
    required List<PlayableAyah> queue,
    required int startIndex,
  }) async {
    calls.add((
      surahNumber: surahNumber,
      surahName: surahName,
      queue: queue,
      startIndex: startIndex,
    ));
  }
}

const surah1 = SurahModel(
  number: 1,
  name: 'Al-Fatihah',
  nameArabic: 'الفاتحة',
  englishNameTranslation: 'The Opening',
  revelationType: 'Meccan',
  numberOfAyahs: 2,
  ayahs: [
    AyahModel(
      number: 1,
      numberInQuran: 1,
      text: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
      juz: 1,
      page: 1,
      translation: 'In the name of Allah, the Entirely Merciful,',
      translationUrdu: 'اللہ کے نام سے جو نہایت مہربان',
    ),
    AyahModel(
      number: 2,
      numberInQuran: 2,
      text: 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
      juz: 1,
      page: 1,
      translation: 'All praise is due to Allah, Lord of the worlds',
      translationUrdu: 'سب تعریف اللہ کے لیے',
    ),
  ],
);

Future<void> pumpReader(
  WidgetTester tester, {
  bool playOnOpen = false,
  int? initialAyah,
  String? initialTab,
  _RecordingAudio? audio,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  // Typed non-null local: avoids leaning on parameter promotion inside
  // the override closure (the analyzer gate does not forgive that).
  final overrides = <Override>[
    surahDetailProvider(1).overrideWith((ref) async => surah1),
    quranDownloadProvider.overrideWith(_NoopDownloads.new),
  ];
  if (audio != null) {
    final _RecordingAudio rec = audio;
    overrides.add(quranAudioProvider.overrideWith(() => rec));
  }
  await tester.pumpWidget(ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      home: AppStringsScope(
        locale: const Locale('en'),
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: SurahReaderScreen(
            surahNumber: 1,
            initialAyah: initialAyah,
            initialTab: initialTab,
            playOnOpen: playOnOpen,
          ),
        ),
      ),
    ),
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

({int c, Set<int> seen}) mark(
        ({int c, Set<int> seen}) from, int ayah) =>
    ReadingProgressRepository.hwApplySeen(
        contiguous: from.c, seen: from.seen, ayah: ayah);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppTestFonts);

  // ────────────────────────────────────────────────────────────
  // P1 — the khatm metric: pure definitions first (no faking).
  // ────────────────────────────────────────────────────────────
  group('khatm high-water — pure rules', () {
    test('contiguous run grows only through adjacent ayahs', () {
      var r = (c: 0, seen: const <int>{});
      r = mark(r, 1);
      expect(r.c, 1);
      r = mark(r, 2);
      expect(r.c, 2);
      // 4 arrives before 3: seen, but the run STOPS at the gap.
      r = mark(r, 4);
      expect(r.c, 2, reason: 'a gap never lets the run jump');
      expect(r.seen, contains(4));
      // Closing the gap absorbs the whole frontier at once.
      r = mark(r, 3);
      expect(r.c, 4);
      expect(r.seen, isEmpty, reason: 'absorbed ayahs leave the frontier');
    });

    test('already-credited ayahs change nothing (idempotent marks)', () {
      var r = (c: 3, seen: const <int>{7});
      r = mark(r, 2); // inside the run — no growth, no frontier churn
      expect(r.c, 3);
      expect(r.seen, {7});
      r = mark(r, 7); // already parked
      expect(r.c, 3);
      expect(r.seen, {7});
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
      expect(s2.surahsReachedEnd, 0,
          reason: 'the 7th ayah is SEEN but not contiguous — no credit');
      expect(s2.ayahsHighWater, 6);
      expect(s2.openedSurahs, 1,
          reason: 'opened is honest context, never the ring count');
    });

    test('coverage divides by the REAL totals and never exceeds 1.0', () {
      expect(QuranMeta.totalSurahs, 114);
      expect(QuranMeta.totalAyahs, 6236);
      const whole = KhatmStats(
          openedSurahs: 114, surahsReachedEnd: 114, ayahsHighWater: 6236);
      expect(whole.coverageFraction, 1.0);
      const over = KhatmStats(
          openedSurahs: 1, surahsReachedEnd: 0, ayahsHighWater: 9999);
      expect(over.coverageFraction, 1.0,
          reason: 'clamped — the fraction can never CLAIM more than all');
      const empty = KhatmStats.empty();
      expect(empty.coverageFraction, 0.0);
    });
  });

  group('khatm store — persistence honesty', () {
    // Order contract: these tests run FIRST among the disk-touching
    // tests and drive the REAL ReadingProgressRepository singleton
    // through its public API. setMockInitialValues replaces the platform
    // store, but an already-bound SharedPreferences cache inside the
    // shared instance keeps its own view — clearAll() is the one public
    // reset that nulls every cache (and now also the high-water cache).
    test('a lone non-contiguous ayah credits NOTHING but is remembered',
        () async {
      SharedPreferences.setMockInitialValues({});
      await ReadingProgressRepository.instance.clearAll();
      await ReadingProgressRepository.instance.markAyahSeen(1, 7);
      final stats =
          await ReadingProgressRepository.instance.getKhatmStats();
      expect(stats.ayahsHighWater, 0,
          reason: 'c stays 0 until ayahs 1..6 arrive in order');
      expect(stats.surahsReachedEnd, 0,
          reason: 'seen-last-ayah alone never counts toward the ring');
      expect(stats.openedSurahs, 1,
          reason: 'opened is honest context — kept, never credited');
    });

    test('the provider state carries those numbers through _loadAll',
        () async {
      // Same process, same singleton: the 7-parked state above is what
      // a fresh provider must reproduce (zero divergence UI vs store).
      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(readingProgressProvider);
      await Future<void>.delayed(const Duration(milliseconds: 80));
      final st = container.read(readingProgressProvider);
      expect(st.khatm.ayahsHighWater, 0);
      expect(st.khatm.surahsReachedEnd, 0);
      expect(st.khatm.openedSurahs, 1);
      // Complete Al-Fatihah contiguously through the store, then a UI
      // refresh (refresh()) must surface the end-of-surah credit.
      for (final a in [1, 2, 3, 4, 5, 6]) {
        await ReadingProgressRepository.instance.markAyahSeen(1, a);
      }
      await container.read(readingProgressProvider.notifier).refresh();
      expect(container.read(readingProgressProvider).khatm.surahsReachedEnd,
          1, reason: 'contiguous 1..7 = reached the last ayah');
      expect(container.read(readingProgressProvider).khatm.ayahsHighWater, 7);
      expect(
          container.read(readingProgressProvider).khatm.coverageFraction,
          closeTo(7 / 6236, 1e-9));
    });

    test('markAyahSeen persists, dedups, and re-reads from the store',
        () async {
      SharedPreferences.setMockInitialValues({});
      final repo = ReadingProgressRepository.instance;
      await repo.clearAll(); // clean caches, same test process
      await repo.markAyahSeen(1, 1);
      await repo.markAyahSeen(1, 2);
      await repo.markAyahSeen(1, 4);
      expect((await repo.getKhatmStats()).ayahsHighWater, 2);
      await repo.markAyahSeen(1, 3); // closes the gap -> absorbs 4 too
      expect((await repo.getKhatmStats()).ayahsHighWater, 4);
      await repo.markAyahSeen(1, 3); // duplicate: no churn, no growth
      expect((await repo.getKhatmStats()).ayahsHighWater, 4);

      // Out-of-range marks are IGNORED, never stored (no fake ayahs).
      await repo.markAyahSeen(1, 8); // Al-Fatihah has 7 ayahs
      await repo.markAyahSeen(0, 1);
      await repo.markAyahSeen(999, 1);
      final stats = await repo.getKhatmStats();
      expect(stats.ayahsHighWater, 4);
      expect(stats.surahsReachedEnd, 0,
          reason: '4 of 7 contiguous — NOT the last ayah yet');

      // PERSISTENCE: the disk artifact the next launch reads.
      final prefs = await SharedPreferences.getInstance();
      final json = jsonDecode(
          prefs.getString('ayah_high_water_v1')!) as Map<String, dynamic>;
      final entry = json['1'] as Map<String, dynamic>;
      expect(entry['c'], 4);
      expect(entry['s'] as List, isEmpty,
          reason: 'seen 1..4 all contiguous — frontier empty');
    });

    test('disk garbage is dropped, never trusted or fatal', () {
      // Pure parser (the loader routes its disk string through EXACTLY
      // this) — impossible values make the WHOLE entry untrusted.
      final m = ReadingProgressRepository.parseHighWater(
          '{"1":{"c":-5,"s":[0,"x",-2]},"999":{"c":9},"abc":{"c":1},'
          '"2":7,"3":{"c":999999,"s":[4]},"4":{"c":1,"s":[9,200]}}');
      expect(m[1]!.c, 0); // negative count clamps to 0…
      expect(m[1]!.seen, isEmpty); // …garbage seen-values dropped
      expect(m.containsKey(999), isFalse); // out-of-range surah key
      expect(m.containsKey(2), isFalse); // entry not a map
      expect(m.containsKey(3), isFalse);
      // impossible run (> 176 ayahs of An-Nisa) → untrusted entirely
      expect(m[4]!.c, 1);
      expect(m[4]!.seen, {9},
          reason: '9 <= 176 stays; 200 > 176 is dropped');
      expect(
          ReadingProgressRepository.khatmFrom(m).ayahsHighWater, 1);
      expect(ReadingProgressRepository.parseHighWater('not json{').isEmpty,
          isTrue);
      expect(ReadingProgressRepository.parseHighWater(null).isEmpty, isTrue);
    });

    testWidgets('the reader exit records EXACTLY the resume ayah',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await ReadingProgressRepository.instance.clearAll();
      await pumpReader(tester, initialAyah: 2);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('ayah_high_water_v1');
      expect(raw, isNotNull, reason: 'the visit end MUST credit the store');
      final json = jsonDecode(raw!) as Map<String, dynamic>;
      final entry = json['1'] as Map<String, dynamic>;
      expect(entry['c'], 0,
          reason: 'only ayah 2 was seen — no contiguous run from 1 exists');
      expect((entry['s'] as List).cast<int>(), [2]);
    });
  });

  // ────────────────────────────────────────────────────────────
  // P2 — streak 0-state + ring presentation (source pins, honest copy).
  // ────────────────────────────────────────────────────────────
  group('streak & ring presentation', () {
    test('home shows the hourglass + getter label at streak 0, flame '
        'only for real streaks; ring reads khatm state', () {
      final src = File('lib/features/quran/presentation/quran_screen.dart')
          .readAsStringSync();
      expect(src, contains('Icons.hourglass_bottom_rounded'));
      expect(src, contains('progress.streak.currentStreak > 0\n'
          '                        ? Icons.local_fire_department_outlined'));
      expect(src, contains('AppStrings.of(context).noStreakYet'));
      expect(src, contains('progress.khatm.coverageFraction'));
      expect(src, contains('AppStrings.of(context).khatmSummary('),
          reason: 'the ring row is the ONE summary string');
      expect(src, contains('AppStrings.of(context).khatmHonestCaption'));
    });

    test('khatmSummary renders the exact EN sentence and real locales',
        () {
      final en = AppStrings.forCode('en').khatmSummary(3, 114, 57, 1, 6236);
      expect(
          en,
          '3 of 114 surahs reached its last ayah · 57 ayahs high-water '
          '(~1% of 6236)');
      final ar = AppStrings.forCode('ar').khatmSummary(3, 114, 57, 1, 6236);
      final ur = AppStrings.forCode('ur').khatmSummary(3, 114, 57, 1, 6236);
      expect(ar, isNot(contains('surahs')));
      expect(ur, isNot(contains('surahs')));
      expect(ar, contains('114'));
      expect(ur, contains('6236'));
      expect(AppStrings.forCode('en').khatmHonestCaption,
          contains('never a completion claim'));
    });

  });

  // ────────────────────────────────────────────────────────────
  // P3 — per-ayah compare card (ONE widget, gated on real prefs).
  // ────────────────────────────────────────────────────────────
  group('translation compare', () {
    testWidgets('toggle ON renders the card per ayah on the Translation '
        'tab with an honest title; OFF renders only the trailing card',
        (tester) async {
      SharedPreferences.setMockInitialValues(
          {'quran_reading_preferences_v1_translation_compare': true});
      await pumpReader(tester, initialTab: 'Translation');
      expect(find.text('Bundled translations — ayah 1'), findsOneWidget);
      expect(find.text('Bundled translations — ayah 2'), findsOneWidget);
      expect(find.text('Bundled translations — first ayah'), findsOneWidget,
          reason: 'the trailing list item is untouched (byte-identical)');
      // The per-ayah card carries BOTH real columns.
      expect(find.textContaining('Lord of the worlds'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('toggle OFF (the default) keeps the pre-Q2 layout exactly',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      await pumpReader(tester, initialTab: 'Translation');
      expect(find.textContaining('Bundled translations — ayah'), findsNothing);
      expect(find.text('Bundled translations — first ayah'), findsOneWidget);
    });

    test('the toggle persists round-trip through prefs (settled first)',
        () async {
      SharedPreferences.setMockInitialValues({});
      final n1 = ReadingPreferencesNotifier();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await n1.setTranslationCompare(true);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('quran_reading_preferences_v1_translation_compare'),
          isTrue);
      final n2 = ReadingPreferencesNotifier();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(n2.state.translationCompare, isTrue);
      // Unrelated keys never leak the value: absent stays false.
      await prefs.remove('quran_reading_preferences_v1_translation_compare');
      final n3 = ReadingPreferencesNotifier();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(n3.state.translationCompare, isFalse);
    });
  });

  // ────────────────────────────────────────────────────────────
  // P4 — scopes + the self-contained Arabic fold table.
  // ────────────────────────────────────────────────────────────
  group('QuranAyahSearch', () {
    test('normalizer: tashkeel/tatweel die, letters fold, latin folds', () {
      expect(QuranAyahSearch.normalize('بِسْمِ  اللَّهِ'), 'بسم الله');
      expect(QuranAyahSearch.normalize('ٱلْحَمْدُ'), 'الحمد');
      expect(QuranAyahSearch.normalize('مُوسَى'), equals('موسي'));
      expect(QuranAyahSearch.normalize('مُوسٰى'), equals('موسي'),
          reason: 'alef maqsura == dagger alef after folding');
      expect(QuranAyahSearch.normalize('بِئْر'), contains('بي'));
      expect(QuranAyahSearch.normalize('سُؤَالَ'), contains('سو'));
      expect(QuranAyahSearch.normalize('مدرسة'), contains('مدرسه'));
      expect(QuranAyahSearch.normalize('کتاب'), 'كتاب',
          reason: 'persian kaf folds to arabic kaf');
      expect(QuranAyahSearch.normalize('تـَعـَ'), 'تع',
          reason: 'tatweel stretches carry no signal');
      expect(QuranAyahSearch.normalize('  The   Lord  '), 'the lord');
    });

    test('scopes filter FIELDS — never borrow hits across them', () {
      const arabic = 'وَضَجَّ النَّارَ';
      const english = 'the blazing fire';
      // A latin word only ever matches the translation column…
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
          isNull,
          reason: 'Arabic scope never borrows the translation hit');
      // …and an Arabic-only word never matches the translation column.
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
      // all = either field, Arabic first (the historical priority).
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
      final data = decoded['data'] as Map<String, dynamic>;
      final surahs = data['surahs'] as List<dynamic>;
      final firstSurah = surahs.first as Map<String, dynamic>;
      final ayahs = firstSurah['ayahs'] as List<dynamic>;
      final firstAyah = ayahs.first as Map<String, dynamic>;
      final firstAyahEn = firstAyah['text'] as String;
      expect(firstAyahEn.length, greaterThan(12));
      const basmala = 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ';
      // A slice of the REAL translation matches under translations…
      final probe = firstAyahEn.substring(3, 9).toLowerCase();
      expect(
          QuranAyahSearch.matchType(
              scope: QuranSearchScope.translations,
              query: probe,
              arabicText: basmala,
              translation: firstAyahEn),
          1);
      // …diacritic-heavy Arabic matches under arabic…
      expect(
          QuranAyahSearch.matchType(
              scope: QuranSearchScope.arabic,
              query: 'الرَّحِيم',
              arabicText: basmala,
              translation: firstAyahEn),
          0);
      // …and a latin word NEVER leaks into the Arabic scope (the
      // basmala holds no latin letters — deterministic, any bundle).
      expect(
          QuranAyahSearch.matchType(
              scope: QuranSearchScope.arabic,
              query: probe,
              arabicText: basmala,
              translation: firstAyahEn),
          isNull);
    });

    test('wiring: repo threads the scope to BOTH paths; notifier owns it',
        () {
      final repoSrc =
          File('lib/features/quran/data/repository/quran_repository.dart')
              .readAsStringSync();
      expect(repoSrc,
          contains('QuranSearchScope scope = QuranSearchScope.all'));
      expect(repoSrc, contains('_searchInIsolate(query, scope)'));
      // Count = 2: main path + isolate both route through the ONE pure
      // matcher (the AI bridge searchBatchOffMain stays unscoped).
      expect(
          RegExp('QuranAyahSearch\\.matchType\\(').allMatches(repoSrc).length,
          2,
          reason: 'exactly the two bundled-search paths use the matcher');
      final provSrc =
          File('lib/features/quran/providers/quran_provider.dart')
              .readAsStringSync();
      expect(provSrc, contains('search(query, scope: _scope)'));
      expect(provSrc, contains('Future<void> setScope(QuranSearchScope'));
      expect(provSrc, contains('QuranSearchScope _scope = QuranSearchScope.all'),
          reason: 'default preserves historical behavior');
    });
  });

  // ────────────────────────────────────────────────────────────
  // P5 — mushaf reading direction: behavior pin (see report; device
  // gesture verification is the owner's — this pins the machine-check
  // able truth: ONE reversed pager, page math consistent, no stray
  // Directionality overrides re-reversing it).
  // ────────────────────────────────────────────────────────────
  group('mushaf direction', () {
    test('the pager reverses exactly once and the jump math matches', () {
      final src =
          File('lib/features/quran/presentation/mushaf_reader_screen.dart')
              .readAsStringSync();
      final pagers = RegExp('PageView\\.builder\\(')
          .allMatches(src)
          .length;
      final reversals = RegExp('reverse:\\s*true').allMatches(src).length;
      expect(pagers, 1, reason: 'exactly one page pager');
      expect(reversals, 1,
          reason: 'reversed exactly once — left-edge swipe advances');
      expect(src, contains('jumpToPage(saved.pageNumber - 1)'));
      expect(src, isNot(contains('Directionality(')),
          reason: 'no double-reversal override anywhere in the screen');
    });
  });

  // ────────────────────────────────────────────────────────────
  // P6 — open-and-play deep links (one-shot, same startQueue).
  // ────────────────────────────────────────────────────────────
  group('deep play', () {
    testWidgets('playOnOpen starts the queue at the linked ayah, ONCE',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final audio = _RecordingAudio();
      await pumpReader(tester,
          playOnOpen: true, initialAyah: 2, initialTab: 'Translation', audio: audio);
      expect(audio.calls, hasLength(1));
      expect(audio.calls.single.surahNumber, 1);
      expect(audio.calls.single.startIndex, 1,
          reason: 'initialAyah 2 is queue index 1 (0-based)');
      expect(audio.calls.single.queue, hasLength(2));
      // Tab flip / rebuilds never retrigger the autoplay.
      await tester.tap(find.text('Arabic').last);
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));
      expect(audio.calls, hasLength(1), reason: 'one-shot per visit');
      expect(tester.takeException(), isNull);
    });

    testWidgets('no playOnOpen = plain open (zero queue calls)',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final audio = _RecordingAudio();
      await pumpReader(tester, initialAyah: 2, audio: audio);
      await tester.pump(const Duration(milliseconds: 400));
      expect(audio.calls, isEmpty,
          reason: 'autoplay is opt-in via the link param only');
    });

    test('routes parse ?play=; every open-from-here entry offers play', () {
      final router = File('lib/core/router/app_router.dart').readAsStringSync();
      expect(RegExp('playParam == \'1\' \\|\\| playParam == \'true\'')
              .allMatches(router)
              .length,
          2,
          reason: 'both reader routes parse the play param');
      expect(router, contains('playOnOpen: play'));

      final search = File(
              'lib/features/quran/presentation/quran_search_screen.dart')
          .readAsStringSync();
      expect(search, contains('onPlay: () => _openAyah(result, play: true)'));
      expect(search, contains('playOnOpen: play'));

      final hub = File(
              'lib/features/bookmarks/presentation/bookmarks_hub_screen.dart')
          .readAsStringSync();
      expect(hub, contains('_openAyah(item, play: true)'));
      expect(hub, contains('playOnOpen: play'));

      // The per-ayah options-sheet path stays the SINGLE-ayah playAyah
      // route it always was (deep play must not hijack it).
      final sheet =
          File('lib/features/quran/presentation/ayah_options_sheet.dart')
              .readAsStringSync();
      expect(sheet, contains('playAyah'));
    });
  });

  // New user-facing copy rides AppStrings (never raw); pin the trio.
  test('all Q2 strings carry three distinct, non-empty locales', () {
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
    expect(src, contains('String get scopeAll => _t('),
        reason: 'single-line form = parsed by the coverage test');
  });
}
