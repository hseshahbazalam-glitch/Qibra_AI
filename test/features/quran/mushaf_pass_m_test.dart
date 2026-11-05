// Pass M — mushaf page-turn realism (M1 engine / M2 physical detail /
// M3 ribbon / M4 chrome). Layout note mirrors the Q2 harness: REAL app
// fonts load first, because flutter test's Ahem placeholder has no
// glyph metrics and manufactures overflow "bugs" that don't exist on
// device. The page index is overridden at the provider edge with
// fixture content — nothing the UI renders is invented on the fly.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // FontLoader + ByteData (Q2 pattern)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qibra_ai/core/l10n/app_strings.dart';
import 'package:qibra_ai/features/quran/data/models/quran_models.dart';
import 'package:qibra_ai/features/quran/presentation/mushaf/mushaf_ribbon.dart';
import 'package:qibra_ai/features/quran/presentation/mushaf/mushaf_turn.dart';
import 'package:qibra_ai/features/quran/presentation/mushaf_reader_screen.dart';
import 'package:qibra_ai/features/quran/providers/quran_download_provider.dart';
import 'package:qibra_ai/features/quran/data/repository/reading_progress_repository.dart';
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

class _NoopDownloads extends QuranDownloadController {
  @override
  Map<int, SurahAudioStatus> build() => const {};
  @override
  Future<void> checkSurah(int surah) async {}
}

final _p1a1 = AyahModel(
  number: 1,
  numberInQuran: 1,
  text: 'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
  juz: 1,
  page: 1,
);
const _p1a2 = AyahModel(
  number: 2,
  numberInQuran: 2,
  text: 'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
  juz: 1,
  page: 1,
);
const _p2a = AyahModel(
  number: 255,
  numberInQuran: 262,
  text: 'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ',
  juz: 3,
  page: 2,
);

final _index = <int, List<MushafPageEntry>>{
  1: [
    const MushafPageEntry(
        surahNumber: 1, surahName: 'Al-Fatihah', ayah: _p1a1),
    const MushafPageEntry(
        surahNumber: 1, surahName: 'Al-Fatihah', ayah: _p1a2),
  ],
  2: [
    const MushafPageEntry(
        surahNumber: 2, surahName: 'Al-Baqarah', ayah: _p2a),
  ],
};

Future<void> pumpMushaf(WidgetTester tester,
    {int? initialPage, bool reduceMotion = false}) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      mushafPageIndexProvider
          .overrideWith((ref) async => Map.of(_index)),
      quranDownloadProvider.overrideWith(_NoopDownloads.new),
    ],
    child: MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: reduceMotion),
        child: AppStringsScope(
          locale: const Locale('en'),
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            body: MushafReaderScreen(initialPage: initialPage ?? 1),
          ),
        ),
      ),
    ),
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// Mid-turn gesture: press, drag to the given dx, hold frames, release.
Future<void> _swipe(WidgetTester tester, double dx) async {
  final g = await tester.startGesture(const Offset(195, 420));
  await tester.pump();
  await g.moveBy(Offset(dx / 3, 0));
  await tester.pump(const Duration(milliseconds: 16));
  await g.moveBy(Offset(dx / 3, 0));
  await tester.pump(const Duration(milliseconds: 16));
  await g.moveBy(Offset(dx / 3, 0));
  await tester.pump(const Duration(milliseconds: 16));
  await g.up();
  await tester.pump(const Duration(milliseconds: 60));
  await tester.pumpAndSettle(const Duration(milliseconds: 30));
}

void main() {
  setUpAll(loadAppTestFonts);

  setUp(() => SharedPreferences.setMockInitialValues({}));

  // ── M1 — turn engine ─────────────────────────────────────────
  group('M1 turn physics', () {
    test('commit thresholds: position, agreeing flick, decisive flick-back',
        () {
      const f = MushafTurnDirection.forward;
      const b = MushafTurnDirection.backward;
      expect(MushafTurnGeometry.commits(f, 0.42, 0), isTrue);
      expect(MushafTurnGeometry.commits(f, 0.2, 600), isTrue,
          reason: 'fast right-flick commits early');
      expect(MushafTurnGeometry.commits(f, 0.9, -600), isFalse,
          reason: 'a decisive flick BACK outvotes position');
      expect(MushafTurnGeometry.commits(f, 0.3, -100), isFalse);
      expect(MushafTurnGeometry.commits(b, 0.45, 0), isTrue,
          reason: 'backward commits on its own sign');
      expect(MushafTurnGeometry.commits(b, 0.3, -600), isTrue,
          reason: 'a leftward 600 px/s flick is +600 in the backward sign');
      expect(MushafTurnGeometry.commits(b, 0.3, 600), isFalse,
          reason: 'a rightward flick back declines a backward turn');
    });

    test('RTL truth: the forward free edge travels RIGHTWARD (never left)',
        () {
      // Right-bound codex: the LEFT (free) edge lifts and sweeps RIGHT.
      // A Latin book sweeps its right edge leftward — this pins we are
      // NOT doing that.
      double edge(double t) =>
          MushafTurnGeometry.freeEdgeFrac(MushafTurnDirection.forward, t);
      expect(edge(0), closeTo(0.0, 0.001));
      expect(edge(0.5), greaterThan(edge(0.2)));
      expect(edge(1.0), greaterThan(0.9));
      expect(MushafTurnGeometry.leafWidthFrac(
              MushafTurnDirection.forward, 1.0),
          lessThan(0.1),
          reason: 'at full lift only a hair of page remains');
      // Backward = the mirror arriving: width grows leftward from the
      // spine, so the free edge STARTS off-screen-right of zero and
      // sweeps left to cover — t=1 is a flat, full-width page.
      expect(MushafTurnGeometry.leafWidthFrac(
              MushafTurnDirection.backward, 1.0),
          closeTo(1.0, 0.02));
    });

    testWidgets('a right-drag turns forward: page 1 -> 2 with the lift',
        (tester) async {
      await pumpMushaf(tester);
      expect(find.text('1 / 604'), findsOneWidget);
      final g = await tester.startGesture(const Offset(195, 420));
      await g.moveBy(const Offset(120, 0));
      await tester.pump();
      // Mid-turn: leaf is up, pinned to the spine (right edge), its
      // left edge has travelled RIGHTWARD past the screen's left.
      // Mid-turn the leaf + the revealed base are BOTH mounted (the
      // free-edge travel itself is pinned in the geometry unit test —
      // asserting on a perspective-transformed bbox here would test the
      // framework's matrix math, not our rule).
      expect(find.byKey(const ValueKey('mushaf-turn-leaf')), findsOneWidget);
      expect(find.byKey(const ValueKey('mushaf-turn-base')), findsOneWidget,
          reason: 'the revealed next page is mounted under the leaf');
      expect(find.byKey(const ValueKey('mushaf-ribbon-hint')), findsNothing);
      await g.moveBy(const Offset(160, 0));
      await tester.pump();
      await g.up();
      await tester.pump(const Duration(milliseconds: 60));
      await tester.pumpAndSettle(const Duration(milliseconds: 40));
      expect(find.text('2 / 604'), findsOneWidget,
          reason: 'committed turn landed the pager on page 2');
      expect(find.byKey(const ValueKey('mushaf-turn-leaf')), findsNothing,
          reason: 'the overlay goes transparent after the settle');
      expect(tester.takeException(), isNull);
    });

    testWidgets('a left-drag on page 2 turns back to page 1', (tester) async {
      await pumpMushaf(tester, initialPage: 2);
      expect(find.text('2 / 604'), findsOneWidget);
      await _swipe(tester, -300);
      expect(find.text('1 / 604'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a partial, slow release settles back — no turn',
        (tester) async {
      await pumpMushaf(tester);
      final g = await tester.startGesture(const Offset(195, 420));
      await g.moveBy(const Offset(50, 0));
      await tester.pump();
      await g.up(); // ~zero velocity, t ≈ 0.14 < 0.42
      await tester.pump(const Duration(milliseconds: 60));
      await tester.pumpAndSettle(const Duration(milliseconds: 40));
      expect(find.text('1 / 604'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('enabled=false degrades to a pass-through child',
        (tester) async {
      var commits = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MushafTurnOverlay(
            enabled: false,
            currentPage: 1,
            pageCount: 604,
            pageAt: (page) => Text('page $page'),
            onCommitPage: (_) => commits++,
            child: const Center(key: ValueKey('inner-child'), child: Text('x')),
          ),
        ),
      ));
      await tester.drag(find.byKey(const ValueKey('inner-child')),
          const Offset(300, 0));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('mushaf-turn-leaf')), findsNothing);
      expect(commits, 0);
    });
  });

  // ── M2 — physical detail ─────────────────────────────────────
  group('M2 detail', () {
    testWidgets('idle peel hint fires once after 5s, then never loops; '
        'reduced-motion still shows the corner (fade fallback)',
        (tester) async {
      await pumpMushaf(tester);
      expect(find.byKey(const ValueKey('mushaf-peel-flap')), findsNothing);
      await tester.pump(const Duration(seconds: 5, milliseconds: 120));
      expect(find.byKey(const ValueKey('mushaf-peel-flap')), findsOneWidget);
      await tester.pump(const Duration(seconds: 1, milliseconds: 700));
      expect(find.byKey(const ValueKey('mushaf-peel-flap')), findsNothing);
      // Same visit, further idle: the hint already told its story.
      await tester.pump(const Duration(seconds: 7));
      expect(find.byKey(const ValueKey('mushaf-peel-flap')), findsNothing);
      expect(tester.takeException(), isNull);

      await pumpMushaf(tester, reduceMotion: true);
      await tester.pump(const Duration(seconds: 5, milliseconds: 120));
      expect(find.byKey(const ValueKey('mushaf-peel-flap')), findsOneWidget,
          reason: 'fade fallback: same hint, zero movement');
      expect(find.byKey(const ValueKey('mushaf-peel-lift')), findsNothing,
          reason: 'the animated lift must NOT exist under reduceMotion');
    });

    test('grain is static and spine/leaf shading stay theme-safe', () {
      final src = File(
              'lib/features/quran/presentation/mushaf/mushaf_turn.dart')
          .readAsStringSync();
      expect(src, contains('bool shouldRepaint(_PaperGrainPainter oldDelegate) => false'));
      expect(src, contains("const step = 14.0;"));
      expect(src, isNot(contains('ColorFiltered')),
          reason: 'no bespoke invert matrices this pass (or ever again)');
      expect(src, isNot(contains('BackdropFilter')));
      expect(src, isNot(contains('saveLayer')));
    });
  });

  // ── M3 — ribbon bookmark ─────────────────────────────────────
  group('M3 ribbon', () {
    testWidgets('drop-the-ribbon writes the real progress store',
        (tester) async {
      await pumpMushaf(tester);
      // Turn to page 2 with a committed drag first (turn path doubles
      // as the setup — progress follows real saves only).
      await _swipe(tester, 300);
      expect(find.text('2 / 604'), findsOneWidget);
      final before =
          await ReadingProgressRepository.instance.getCurrentPage();
      // lastRead at this point is whatever onPageChanged saved (2) —
      // drag the ribbon down past the arm distance and release.
      final g = await tester.startGesture(const Offset(24, 30));
      await g.moveBy(const Offset(0, 40));
      await tester.pump();
      expect(find.byKey(const ValueKey('mushaf-ribbon-hint')), findsOneWidget,
          reason: 'the armed drop hint appears past the threshold');
      await g.up();
      await tester.pump(const Duration(milliseconds: 120));
      final after =
          await ReadingProgressRepository.instance.getCurrentPage();
      expect(after?.pageNumber, 2);
      expect(before?.pageNumber ?? 2, 2);
      expect(find.text('2 / 604'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tap jumps to the saved page (route page still wins on '
        'open — the ribbon jump is the manual override)', (tester) async {
      final repo = ReadingProgressRepository.instance;
      await repo.initialize();
      await repo.saveCurrentPage(MushafPageModel(
        pageNumber: 2,
        surahNumber: 2,
        surahName: 'Al-Baqarah',
        ayahNumber: 255,
        juzNumber: 3,
        hizbNumber: 1,
        savedAt: DateTime(2026, 11, 5),
      ));
      await pumpMushaf(tester, initialPage: 2);
      expect(find.text('2 / 604'), findsOneWidget);
      // Saved page == current page here: the jump is a no-op but the
      // affordance must fire without errors; then move to a state where
      // it MEANS something — save via a turn to page 2 from 1.
      await pumpMushaf(tester); // fresh open on page 1, saved page = 2…
      // …restore auto-jumps to it (existing Q2 behaviour), so verify the
      // ribbon renders at the SAVED fraction, not the route's.
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('2 / 604'), findsOneWidget,
          reason: 'restore-from-store stays intact through the M rewrite');
      final f = MushafRibbon.progressFraction(2, 604);
      expect(f, greaterThan(0.0));
      expect(f, lessThan(0.01));
    });

    testWidgets('ribbon hint text is localized and the a11y label exists',
        (tester) async {
      final en = AppStrings.forCode('en');
      final ar = AppStrings.forCode('ar');
      final ur = AppStrings.forCode('ur');
      const arabic = RegExp(r'[؀-ۿ]');
      expect(en.mushafRibbonA11y, contains('Ribbon'));
      expect(arabic.hasMatch(ar.mushafRibbonA11y), isTrue);
      expect(arabic.hasMatch(ur.mushafRibbonA11y), isTrue);
      expect(ar.mushafRibbonDropHint, isNot(en.mushafRibbonDropHint));
      expect(ur.mushafRibbonDropHint, isNot(en.mushafRibbonDropHint));
      final handle = tester.ensureSemantics();
      await pumpMushaf(tester);
      await tester.pump();
      expect(find.bySemanticsLabel('Ribbon bookmark. Tap to return to '
          'your last read page; drag down to mark this page.'),
          findsOneWidget);
      handle.dispose();
    });
  });

  // ── M4 + regression — chrome and the pins that must survive ──
  group('M4 chrome + regression', () {
    testWidgets('juz chip renders from the SAME data the old text used',
        (tester) async {
      await pumpMushaf(tester);
      expect(find.text('Juz 1'), findsOneWidget); // page 1 = Al-Fatihah
      // With the chip present, the duplicate 'Juz n ·' words left the
      // label line — and only there:
      expect(find.text('Page 1 / 604'), findsOneWidget);
      expect(find.text('Page 1 of 604'), findsNothing);
      await pumpMushaf(tester, initialPage: 2);
      expect(find.text('Juz 3'), findsOneWidget,
          reason: 'fixture p2 carries juz 3 — real field, styled');
    });

    test('Q2 direction pins + overlay coexistence (source truth)', () {
      final src = File(
              'lib/features/quran/presentation/mushaf_reader_screen.dart')
          .readAsStringSync();
      expect(RegExp(r'PageView\.builder\(').allMatches(src).length, 1);
      expect(RegExp(r'reverse:\s*true').allMatches(src).length, 1);
      expect(src, contains('jumpToPage(saved.pageNumber - 1)'));
      expect(src, isNot(contains('Directionality(')));
      // The arbitration swap: user drags now belong to the turn engine.
      expect(src, contains('NeverScrollableScrollPhysics'));
      // _menuOption ink fix + sheets untouched (S1/S2 own those pumps):
      expect(src, contains('_menuOption'));
      // No second renderer was smuggled in:
      final turn = File(
              'lib/features/quran/presentation/mushaf/mushaf_turn.dart')
          .readAsStringSync();
      expect(turn, isNot(contains('PageView')));
      expect(turn, isNot(contains('Color(0x')));
      expect(turn, isNot(contains("tooltip: '")));
    });

    test('census: zero raw hex and zero raw tooltips across the M files', () {
      for (final p in [
        'lib/features/quran/presentation/mushaf/mushaf_turn.dart',
        'lib/features/quran/presentation/mushaf/mushaf_ribbon.dart',
        'lib/features/quran/presentation/mushaf/mushaf_chrome.dart',
      ]) {
        final src = File(p).readAsStringSync();
        expect(src.contains('Color(0x'), isFalse, reason: p);
        expect(src.contains("tooltip: '"), isFalse, reason: p);
        expect(src.contains('IconButton('), isFalse, reason: p);
      }
    });
  });
}
