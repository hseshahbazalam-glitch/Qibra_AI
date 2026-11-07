// test/features/quran/edition_pass_e_test.dart
//
// ============================================================
// PASS E — EDITION TRUTH (Urdu picker says what it loads)
// ============================================================
// The picker used to offer Urdu editions while the loader only ever
// fed Jalandhry to the reader — choosing Tahir-ul-Qadri READ
// Jalandhry silently. These tests pin the fix from every angle: the
// catalog's pure rules (parse, blanks-are-absent, LRU), the resolver's
// picker truth, the prefs identity, the reader's live render (default
// unchanged, selected edition shown, honest unavailable where the
// upstream file is blank, keep-old while loading), the compare column,
// the E4 tab-label truth, and a census source-guard for every E1 site.
//
// Harness note (mirrors quran_reading_pass_q2_test.dart): the app's
// REAL fonts load first — the Ahem placeholder manufactures overflow
// "bugs" that don't exist on device.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qibra_ai/core/content/edition_resolver.dart';
import 'package:qibra_ai/core/l10n/app_strings.dart';
import 'package:qibra_ai/features/quran/data/models/quran_models.dart';
import 'package:qibra_ai/features/quran/data/repository/urdu_edition_catalog.dart';
import 'package:qibra_ai/features/quran/presentation/surah_reader_screen.dart';
import 'package:qibra_ai/features/quran/providers/quran_download_provider.dart';
import 'package:qibra_ai/features/quran/providers/quran_provider.dart';
import 'package:qibra_ai/features/quran/providers/reading_preferences_provider.dart';
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
    ])'assets/fonts/Inter-$w.ttf',
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

/// Two-ayah Al-Fatihah fixture (same shape as the Q2 harness, with a
/// roman face on ayah 1 so the E4 tab has something true to show and
/// none on ayah 2 to prove the honest fallback line).
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
      translationRoman: 'Roman-Bismillah-Line',
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

const enAyah1 = 'In the name of Allah, the Entirely Merciful,';
const enAyah2 = 'All praise is due to Allah, Lord of the worlds';
const faceAyah1 = 'اللہ کے نام سے جو نہایت مہربان';
const faceAyah2 = 'سب تعریف اللہ کے لیے';

/// The real bundled Tahir-ul-Qadri map, parsed once (this file is the
/// content-truth oracle — pins read from it, never from memory).
Map<String, String>? _tqCache;
Map<String, String> tqReal() => _tqCache ??= UrduEditionCatalog
    .parseUrduShape(jsonDecode(File(
            'assets/data/quran/translation_ur_tahirulqadri.json')
        .readAsStringSync()));

Map<String, String> urduFile(String name) => UrduEditionCatalog
    .parseUrduShape(
        jsonDecode(File('assets/data/quran/$name').readAsStringSync()));

Future<void> pumpE(
  WidgetTester tester, {
  String? initialTab,
  Map<String, Object>? mockPrefs, // setMockInitialValues wants Object, not
  // Object? — the mock store rejects nullable-valued maps at compile time.
  Override? editionOverride,
}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  SharedPreferences.setMockInitialValues({
    if (mockPrefs != null) ...mockPrefs,
  });
  // Typed locals: no leaning on parameter promotion inside closures.
  final Override? ed = editionOverride;
  final overrides = <Override>[
    surahDetailProvider(1).overrideWith((ref) async => surah1),
    quranDownloadProvider.overrideWith(_NoopDownloads.new),
    if (ed != null) ed,
  ];
  await tester.pumpWidget(ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      home: AppStringsScope(
        locale: const Locale('en'),
        child: Scaffold(
          resizeToAvoidBottomInset: false,
          body: SurahReaderScreen(
            surahNumber: 1,
            initialTab: initialTab,
          ),
        ),
      ),
    ),
  ));
  // Q2's exact settle ritual — deliberate pump frames, NEVER
  // pumpAndSettle: the reader carries a live pulse (audio-bar/download
  // status surfaces) that keeps scheduling frames forever under fake
  // async, so settle spins to its timeout. Four deliberate pumps flush
  // every microtask hop here (prefs load -> provider -> card rebuild);
  // Q2's green suite renders full cards under this same ritual.
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
  await tester.pump(const Duration(milliseconds: 400));
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppTestFonts);

  setUp(UrduEditionCatalog.instance.debugReset);
  tearDown(UrduEditionCatalog.instance.debugReset);

  // ────────────────────────────────────────────────────────────
  // E2 — the catalog's pure rules (no widget, no rootBundle yet).
  // ────────────────────────────────────────────────────────────
  group('E2 catalog — pure rules', () {
    test('parse indexes by chapter:verse; blanks become ABSENT', () {
      final map = UrduEditionCatalog.parseUrduShape({
        'quran': [
          {'chapter': 1, 'verse': 1, 'text': 'one'},
          {'chapter': 1, 'verse': 2, 'text': '   '},
          {'chapter': 1, 'verse': 3, 'text': null},
          {'chapter': 2, 'verse': 1, 'text': 'two-one'},
          'junk row',
        ],
      });
      expect(map, {'1:1': 'one', '2:1': 'two-one'});
      // A file without the quran list parses to empty, never throws.
      expect(UrduEditionCatalog.parseUrduShape({'data': 'other'}), isEmpty);
    });

    test('the real Tahir-ul-Qadri file: census, gap, and the 112:1 truth',
        () {
      final tq = tqReal();
      expect(tq.length, 6236 - 217);
      expect(tq.containsKey('7:1'), isFalse);
      expect(tq.containsKey('100:11'), isFalse);
      expect(tq['112:1'],
          '(اے نبئ مکرّم!) آپ فرما دیجئے: وہ اللہ ہے جو یکتا ہے');
      expect(tq['112:2'], isNotNull);
    });

    test('LRU: two resident max, head evicts, a peek renews the age', () {
      final c = UrduEditionCatalog.instance;
      c.debugInject('ur_junagarhi', {'1:1': 'J'});
      c.debugInject('ur_maududi', {'1:1': 'M'});
      expect(c.loadedIds, ['ur_junagarhi', 'ur_maududi']);
      expect(c.peek('ur_junagarhi')?['1:1'], 'J'); // touch -> MRU
      c.debugInject('ur_tahirulqadri', {'1:1': 'T'}); // third -> head drops
      expect(c.loadedIds, ['ur_junagarhi', 'ur_tahirulqadri']);
      expect(c.peek('ur_maududi'), isNull);
    });

    test('ensure answers null for model-served faces and non-Urdu ids',
        () async {
      final c = UrduEditionCatalog.instance;
      expect(await c.ensure('en'), isNull);
      expect(await c.ensure('ur'), isNull); // canonical -> Jalandhry face
      expect(await c.ensure('ur_jalandhry'), isNull);
      expect(await c.ensure('ur_maududi_roman'), isNull);
      expect(await c.ensure('not-an-edition'), isNull);
    });

    test('selectedText: edition first, face only while loading, absent is '
        'absent', () {
      final ayah = surah1.ayahs.first; // number 1
      String? resolve(String id, Map<String, String>? texts) =>
          UrduEditionCatalog.selectedText(
            ayah: ayah,
            prefs: ReadingPreferences(translationId: id),
            surahNumber: 1,
            editionTexts: texts,
          );
      expect(resolve('en', null), enAyah1);
      expect(resolve('ur_usmani', {'1:1': 'US'}), 'US');
      // Loaded map WITHOUT the entry (a TQ gap) must NOT silently fall
      // back to the Jalandhry face — absent resolves to the honest
      // unavailable line upstream.
      expect(resolve('ur_usmani', {}), isNull);
      expect(resolve('ur_usmani', {'1:2': 'x'}), isNull);
      // Not loaded yet: keep the model's default face (keep-old-until-
      // ready), roman edition riding its own resident face.
      expect(resolve('ur_usmani', null), faceAyah1);
      expect(resolve('ur_maududi_roman', null), 'Roman-Bismillah-Line');
      expect(resolve('ur', null), faceAyah1); // legacy alias
    });
  });

  // ────────────────────────────────────────────────────────────
  // E3 — picker list + persisted identity.
  // ────────────────────────────────────────────────────────────
  group('E3 — picker truth', () {
    test('the offer list IS the loadable set: seven unique, no dupes', () {
      final entries = EditionResolver.pickerEntries();
      expect(entries.map((e) => e.id).toList(), [
        'en',
        'ur_jalandhry',
        'ur_junagarhi',
        'ur_maududi',
        'ur_maududi_roman',
        'ur_tahirulqadri',
        'ur_usmani',
      ]);
      expect(entries.map((e) => e.label).toSet().length, 7);
      expect(
        entries
            .firstWhere((e) => e.id == 'ur_tahirulqadri')
            .disclosesGap,
        isTrue,
      );
      expect(EditionResolver.canonical('ur'), 'ur_jalandhry');
      expect(EditionResolver.canonical('EN'), 'en');
    });

    test('setTranslation persists the canonical id; junk is refused',
        () async {
      SharedPreferences.setMockInitialValues({});
      final n1 = ReadingPreferencesNotifier();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      await n1.setTranslation('ur');
      expect(n1.state.translationId, 'ur_jalandhry');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('quran_reading_preferences_v1_translation'),
          'ur_jalandhry');
      await n1.setTranslation('ur_tahirulqadri');
      await n1.setTranslation('definitely-not-bundled');
      expect(n1.state.translationId, 'ur_tahirulqadri');
      final n2 = ReadingPreferencesNotifier();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(n2.state.translationId, 'ur_tahirulqadri');
    });
  });

  // ────────────────────────────────────────────────────────────
  // E3 — the reader renders what was chosen.
  // ────────────────────────────────────────────────────────────
  group('E3 — reader render truth', () {
    testWidgets('default (no prefs at all) keeps the pre-E English line '
        'byte-identical', (tester) async {
      await pumpE(tester, initialTab: 'Translation');
      // Render truth with the legacy demo: the pre-E 'Bundled
      // translations — first ayah' card renders once per trailing slot —
      // TWO slots for a no-bismillah list, Q2's own test pins that count
      // (quran_reading_pass_q2_test.dart:446) — and each reads the model
      // fields directly, prefs-blind. They contribute enAyah1 + faceAyah1
      // copies; only how many of them landed inside the build window
      // varies with card height, so the demo-adjacent texts are asserted
      // as bounds while every per-ayah signal stays exact. faceAyah2 /
      // enAyah2 can ONLY come from the cards — those stay findsOneWidget
      // / findsNothing.
      expect(find.text(enAyah1), findsAtLeastNWidgets(2));
      expect(find.text(enAyah1).evaluate().length, lessThanOrEqualTo(3));
      expect(find.text(enAyah2), findsOneWidget);
      expect(find.text(faceAyah1).evaluate().length, lessThanOrEqualTo(2));
      expect(find.text(faceAyah2), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the legacy ur alias serves Jalandhry — the same content '
        'it always did, now under one canonical id', (tester) async {
      await pumpE(
        tester,
        initialTab: 'Translation',
        mockPrefs: {'quran_reading_preferences_v1_translation': 'ur'},
      );
      // The alias serves the Jalandhry face through the same selected-
      // text path as any ur* id — card #2's line is the exact proof.
      // faceAyah1 rides the two demo cards too (their fixed model-face
      // copies, 1-2 built), so it's bounded rather than counted.
      expect(find.text(faceAyah1), findsAtLeastNWidgets(2));
      expect(find.text(faceAyah1).evaluate().length, lessThanOrEqualTo(3));
      expect(find.text(faceAyah2), findsOneWidget);
      expect(find.text(enAyah1).evaluate().length, lessThanOrEqualTo(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Tahir-ul-Qadri selected -> the reader shows REAL TQ text '
        'from the bundled file — no Jalandhry bleed', (tester) async {
      final tq = tqReal();
      await pumpE(
        tester,
        initialTab: 'Translation',
        mockPrefs: {
          'quran_reading_preferences_v1_translation': 'ur_tahirulqadri',
        },
        editionOverride: editionTextProvider('ur_tahirulqadri')
            .overrideWith((ref) async => tq),
      );
      // No Jalandhry or English in the PER-AYAH lines — the bleed this
      // test owns. The trailing legacy demo cards keep rendering their
      // model-field faces (fixed source, prefs-blind; 1-2 of the Q2-
      // pinned pair land in the build window), so enAyah1/faceAyah1 are
      // bounded at their demo-only ceiling; faceAyah2/enAyah2 can come
      // from no card but the first-ayah demo — those stay zero.
      expect(find.text(tq['1:1']!), findsOneWidget);
      expect(find.text(tq['1:2']!), findsOneWidget);
      expect(find.text(faceAyah1).evaluate().length, lessThanOrEqualTo(2));
      expect(find.text(faceAyah2), findsNothing);
      expect(find.text(enAyah1).evaluate().length, lessThanOrEqualTo(2));
      expect(find.text(enAyah2), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a gap ayah in a loaded edition shows the honest '
        'unavailable line, never the previous edition', (tester) async {
      final truncated = Map<String, String>.of(tqReal())..remove('1:2');
      await pumpE(
        tester,
        initialTab: 'Translation',
        mockPrefs: {
          'quran_reading_preferences_v1_translation': 'ur_tahirulqadri',
        },
        editionOverride: editionTextProvider('ur_tahirulqadri')
            .overrideWith((ref) async => truncated),
      );
      expect(find.text(tqReal()['1:1']!), findsOneWidget);
      expect(find.text(AppStrings.forCode('en').translationUnavailable),
          findsOneWidget);
      expect(find.text(faceAyah2), findsNothing); // NO silent fallback
      expect(tester.takeException(), isNull);
    });

    testWidgets('while a lazy edition loads, the frame keeps the old '
        'face — never blank, never a promise it cannot yet keep',
        (tester) async {
      final gate = Completer<Map<String, String>?>();
      addTearDown(() {
        if (!gate.isCompleted) gate.complete(null);
      });
      await pumpE(
        tester,
        initialTab: 'Translation',
        mockPrefs: {
          'quran_reading_preferences_v1_translation': 'ur_junagarhi',
        },
        editionOverride:
            editionTextProvider('ur_junagarhi').overrideWith((ref) => gate.future),
      );
      // While the edition is in flight the cards keep the old face —
      // never a blank line. faceAyah1 also rides the demo cards, hence
      // the bound; faceAyah2 can only come from card #2 keeping its
      // face, which is the exact in-flight signal.
      expect(find.text(faceAyah1), findsAtLeastNWidgets(2));
      expect(find.text(faceAyah2), findsOneWidget);
      expect(find.text(AppStrings.forCode('en').translationUnavailable),
          findsNothing);
      expect(tester.takeException(), isNull);
      gate.complete({'1:1': 'junagarhi-one', '1:2': 'junagarhi-two'});
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 64));
      // Ready flips the SAME frame forward: both card lines are now the
      // edition — and Junagarhi text can never come from the legacy
      // demo, so findsOneWidget here IS the per-card proof. The old
      // face lingers only inside the demo cards' fixed budget.
      expect(find.text('junagarhi-one'), findsOneWidget);
      expect(find.text('junagarhi-two'), findsOneWidget);
      expect(find.text(faceAyah1).evaluate().length, lessThanOrEqualTo(2));
    });

    testWidgets('compare mode pairs EN with the SELECTED edition — the '
        'column names itself only when it shows what it claims',
        (tester) async {
      await pumpE(
        tester,
        initialTab: 'Translation',
        mockPrefs: {
          'quran_reading_preferences_v1_translation': 'ur_usmani',
          'quran_reading_preferences_v1_translation_compare': true,
        },
        editionOverride: editionTextProvider('ur_usmani').overrideWith(
            (ref) async => {'1:1': 'usmani-one', '1:2': 'usmani-two'}),
      );
      // Per-ayah cards carry the named edition column.
      expect(find.text('Urdu (Usmani)'), findsNWidgets(2));
      expect(find.text('usmani-one'), findsNWidgets(2)); // row + column
      expect(find.text('usmani-two'), findsNWidgets(2));
      // (The trailing shared card keeps its fixed EN + Jalandhry demo
      // untouched — Q2's own tests own that code path; at this viewport
      // it is outside the BUILT range while the per-ayah cards exist,
      // per Q2's harness comment, so it is not asserted here.)
      // No bleed of the un-named face into the SELECTED slots: the
      // only place Jalandhry's 1:2 could appear is a compare column,
      // and there it must NOT be.
      expect(find.text(faceAyah2), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  // ────────────────────────────────────────────────────────────
  // E4 — label truth: the roman tab says ROMAN URDU.
  // ────────────────────────────────────────────────────────────
  group('E4 — label truth', () {
    testWidgets('the tab is named for its content and the honest '
        'fallback speaks the same truth', (tester) async {
      await pumpE(
        tester,
        initialTab: 'Roman Urdu',
        mockPrefs: {'quran_reading_preferences_v1_show_transliteration': true},
      );
      expect(find.text('Roman Urdu'), findsWidgets); // the tab label
      expect(find.text('Transliteration'), findsNothing); // the old lie
      expect(find.text('Roman-Bismillah-Line'), findsOneWidget);
      expect(find.text(AppStrings.forCode('en').romanUrduUnavailable),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    test('the toggle label follows the content in all three locales', () {
      expect(AppStrings.forCode('en').showTransliteration, 'Show Roman Urdu');
      final ar = AppStrings.forCode('ar').showTransliteration;
      final ur = AppStrings.forCode('ur').showTransliteration;
      expect(ar, isNot(contains('transliteration')));
      expect(ur, isNot(contains('transliteration')));
      expect(ar.isNotEmpty && ur.isNotEmpty, isTrue);
    });
  });

  // ────────────────────────────────────────────────────────────
  // E1 census guard — every consumer the table names goes through
  // the edition seam. Source pins, because a widget test cannot
  // pump the whole home tab / options sheet for one string.
  // ────────────────────────────────────────────────────────────
  group('E1 census — source guards', () {
    String src(String path) => File(path).readAsStringSync();

    test('reader, share, copy and settings all carry the seam', () {
      final reader = src(
          'lib/features/quran/presentation/surah_reader_screen.dart');
      expect(reader, contains("activeTab == 'Roman Urdu'"));
      expect(reader, isNot(contains("'Transliteration is not bundled")));
      expect(reader, contains('editionTextProvider(editionId)'));
      expect(reader, contains('UrduEditionCatalog.selectedText'));
      final screen = src('lib/features/quran/presentation/quran_screen.dart');
      expect(screen, contains('UrduEditionCatalog.selectedText'));
      final sheet =
          src('lib/features/quran/presentation/ayah_options_sheet.dart');
      expect(sheet, contains('UrduEditionCatalog.selectedText'));
      final settings =
          src('lib/features/settings/presentation/settings_screen.dart');
      expect(settings, contains('EditionResolver.pickerEntries()'));
      // tafseer keeps its generic-but-true 'اردو' card (content IS
      // Jalandhry; naming editions there is a later polish — Pass E
      // scope: no new raw label added there, disclosed in the census).
      final tafseer =
          src('lib/features/tafseer/presentation/tafseer_screen.dart');
      expect(tafseer, contains("label: 'اردو'"));
      final wsheet =
          src('lib/features/quran/presentation/word_explain_sheet.dart');
      expect(wsheet, contains('required this.romanUrdu'));
      expect(wsheet, isNot(contains('this.transliteration')));
      expect(wsheet, isNot(contains('String? transliteration')));
    });

    test('the catalog never keeps more than two Urdu maps', () {
      final code = src(
          'lib/features/quran/data/repository/urdu_edition_catalog.dart');
      expect(code, contains('maxCachedEditions = 2'));
      expect(code, contains('_evictOverflow'));
    });
  });

  // ────────────────────────────────────────────────────────────
  // Content truth over every bundled file — the picker's whole
  // promise in one table test (v7-audit strings, re-verified).
  // ────────────────────────────────────────────────────────────
  test('E5 — every offered edition renders its OWN 112:1', () {
    expect(urduFile('translation_ur_jalandhry.json')['112:1'],
        'کہو کہ وہ (ذات پاک جس کا نام) الله (ہے) ایک ہے');
    expect(urduFile('translation_ur_junagarhi.json')['112:1'],
        'آپ کہہ دیجئے کہ وه اللہ تعالیٰ ایک (ہی) ہے');
    expect(urduFile('translation_ur_maududi.json')['112:1'],
        'کہو، وہ اللہ ہے، یکتا');
    expect(urduFile('translation_ur_maududi_roman.json')['112:1'],
        'Kaho woh Allah hai, Yakta'); // a TRANSLATION — the E4 rename
    expect(urduFile('translation_ur_usmani.json')['112:1'],
        'کہہ دو : بات یہ ہے کہ اللہ ہر لحاظ سے ایک ہے۔');
    expect(tqReal()['112:1'],
        '(اے نبئ مکرّم!) آپ فرما دیجئے: وہ اللہ ہے جو یکتا ہے');
    // English rides the OTHER shape — its loader is unchanged, pin it.
    final en = jsonDecode(
        File('assets/data/quran/translation_en.json').readAsStringSync())
        as Map<String, dynamic>;
    final surahs =
        (en['data'] as Map<String, dynamic>)['surahs'] as List<dynamic>;
    final s112 = surahs
        .cast<Map<String, dynamic>>()
        .firstWhere((s) => s['number'] == 112);
    expect(
      ((s112['ayahs'] as List<dynamic>).first
              as Map<String, dynamic>)['text'] as String,
      startsWith('SAY: "He is the One God'),
    );
  });

  testWidgets('end-to-end: the loader really reads a bundled asset file',
      (tester) async {
    // WHY testWidgets and not a plain test(): the loader's disk branch
    // was CI-proven to RUN to completion under the harness (the run log
    // printed read HIT 1393273b before the tripwire fired) — the bytes
    // are read, parsed, stored inline with zero awaits — yet a plain
    // test()'s await of the already-complete future is never resumed:
    // the file's binding guards that zone's microtask delivery
    // forever (no pump exists to drain it). testWidgets owns a clock
    // that DOES flush — exactly how the t8 render test rides this same
    // ensure() green. So: start the REAL load (no overrides), pump once
    // so the fake clock ticks past any bookkeeping hop, then await the
    // (by then already-complete) load future and assert through the
    // catalog's own synchronous eyes — cache and order included.
    final catalog = UrduEditionCatalog.instance;
    final fly = catalog.ensure('ur_junagarhi');
    await tester.pump(const Duration(seconds: 1));
    final map = await fly;
    expect(map, isNotNull);
    expect(map!['112:1'], 'آپ کہہ دیجئے کہ وه اللہ تعالیٰ ایک (ہی) ہے');
    expect(catalog.loadedIds, contains('ur_junagarhi'));
  });
}
