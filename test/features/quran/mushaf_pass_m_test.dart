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
import 'package:flutter_test/flutter_test.dart' hide test, testWidgets;
import 'package:flutter_test/flutter_test.dart' as ft show test, testWidgets;
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

const _p1a1 = AyahModel(
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


// M6SHADOW3 (transient, one round): file-local wrappers with the SDK's
// EXACT test/testWidgets signatures (read from flutter 3.44.6 sources:
// test() takes Object + dynamic skip + retry/testOn/tags/onPlatform;
// testWidgets() takes String + bool? skip). Bodies are caught and the
// name rides the ::error:: annotation channel. Removed with the fix.
final _m6bad = <String>[];

void testWidgets(
  String d,
  WidgetTesterCallback cb, {
  bool? skip,
  Timeout? timeout,
}) {
  ft.testWidgets(d, (t) async {
    try {
      await cb(t);
    } catch (e) {
      _m6bad.add('mushaf_pass_m :: $d :: ${e.toString().split('\n').first}');
      rethrow;
    }
  }, skip: skip, timeout: timeout);
}

void test(
  Object d,
  dynamic Function() body, {
  String? testOn,
  Timeout? timeout,
  dynamic skip,
  dynamic tags,
  Map<String, dynamic>? onPlatform,
  int? retry,
}) {
  ft.test(d, () async {
    try {
      await body();
    } catch (e) {
      _m6bad.add('mushaf_pass_m :: $d :: ${e.toString().split('\n').first}');
      rethrow;
    }
  },
      testOn: testOn,
      timeout: timeout,
      skip: skip,
      tags: tags,
      onPlatform: onPlatform,
      retry: retry);
}

void main() {
  tearDownAll(() {
    for (final x in _m6bad) {
      print('::error::M6BAD ${x.length > 230 ? x.substring(0, 230) : x}');
    }
    print('::error::M6BADEND mushaf_pass_m_test.dart ${_m6bad.length}');
  });

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
      // The move that WINS the arena fires onDragStart only — a second
      // move is what delivers the first onDragUpdate, and the overlay
      // latches its direction on update (by design: start measures,
      // update decides). One extra step and the leaf is live.
      await g.moveBy(const Offset(2, 0));
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

      // Force a FRESH State for the reduced-motion visit (same widget
      // type + pumpWidget would silently reuse the old overlay state,
      // carrying _hintUsed over and killing the very behaviour tested).
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
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
  // ── M2 jank contract — build scoping (pass M2) ───────────────
  group('M2 jank contract', () {
    test('scoped rebuild + cache shapes live in the sources', () {
      final turn = File(
              'lib/features/quran/presentation/mushaf/mushaf_turn.dart')
          .readAsStringSync();
      final rdr =
          File('lib/features/quran/presentation/mushaf_reader_screen.dart')
              .readAsStringSync();
      expect(turn, contains('ValueNotifier<double> _turnT'));
      expect(turn, contains('AnimatedBuilder('));
      expect(turn, isNot(contains('setState(() => _t')),
          reason: 'drag/settle ticks must not setState the whole overlay');
      expect(turn, contains('Widget? _leafContent'));
      expect(turn, contains('_latchLeafContent'));
      expect(turn, contains('pageAtStatic'),
          reason: 'the F3 motion twin is part of the contract');
      expect(turn, contains('Transform.translate('));
      expect(turn, isNot(contains('48 * (1 - 0.6 * t)')),
          reason: 'the old per-tick re-sized Positioned band is gone');
      // Physics pins UNTOUCHED — no silent retune (discipline):
      expect(turn, contains('static const double commitFraction = 0.42;'));
      expect(turn, contains('static const double commitVelocity = 520;'));
      expect(rdr, contains('_pageCache'));
      expect(rdr, contains('putIfAbsent'));
      expect(rdr, contains('pageAtStatic:'));
      expect(rdr, contains('selectable: false'));
      expect(rdr, contains('_warmPageCache'));
      expect(rdr, contains('identical(_cacheIndex, index)'),
          reason: 'dep-identity invalidation keeps play-follow honest');
      // F3 scope rule: the SETTLED render still owns SelectableText.
      expect(rdr, contains('SelectableText.rich('));
      expect(RegExp(r'PageView\.builder\(').allMatches(rdr).length, 1);
    });

    testWidgets('a drag builds each page EXACTLY ONCE per turn',
        (tester) async {
      int builds = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MushafTurnOverlay(
            currentPage: 1,
            pageCount: 604,
            pageAt: (page) {
              builds++;
              return SelectableText('live $page',
                  textDirection: TextDirection.ltr);
            },
            pageAtStatic: (page) {
              builds++;
              return Text('motion $page', textDirection: TextDirection.ltr);
            },
            onCommitPage: (_) {},
            child: const Center(
                key: ValueKey('stub-child'), child: Text('settled')),
          ),
        ),
      ));
      final g = await tester.startGesture(const Offset(200, 300));
      for (var i = 0; i < 8; i++) {
        await g.moveBy(const Offset(24, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(builds, 2,
          reason: 'leaf + base latch once at the direction lock; the '
              'seven further ticks build nothing');
      // F3: the leaf in motion shows the NON-selectable twin — the
      // selection layer never competes in the arena mid-turn.
      final leaf = find.byKey(const ValueKey('mushaf-turn-leaf'));
      expect(leaf, findsOneWidget);
      expect(
          find.descendant(of: leaf, matching: find.byType(SelectableText)),
          findsNothing);
      expect(find.text('motion 1'), findsOneWidget,
          reason: 'forward leaf renders the current page statically');
      await g.up();
      await tester.pump(const Duration(milliseconds: 60));
      await tester.pumpAndSettle(const Duration(milliseconds: 40));
      expect(builds, 2,
          reason: 'commit and settle add zero builds — the pager owns '
              'the settled render from here');
      expect(find.byKey(const ValueKey('mushaf-turn-leaf')), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  // ── M3 lifeline — settle controller, device-caught (pass M3) ──
  // Device log (CPH2573, debug): the SECOND turn in one overlay
  // lifetime threw "SingleTickerProviderStateMixin but multiple
  // tickers were created" (per-call AnimationController), and every
  // later touch spammed stop-after-dispose — because the throw landed
  // BETWEEN _settle.dispose() and the _settle re-assignment, leaving a
  // disposed controller in the field. CI-551 missed it: every prior
  // test settled at most ONE turn per mounted overlay, and the mixin
  // only bites on the second ticker creation. These tests pin the
  // single-owner contract so it can never regress silently.
  group('M3 turn lifeline', () {
    testWidgets('R1: two committed turns in one overlay lifetime — zero throws',
        (tester) async {
      var commits = 0;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MushafTurnOverlay(
            currentPage: 1,
            pageCount: 604,
            pageAt: (page) =>
                Text('page $page', textDirection: TextDirection.ltr),
            onCommitPage: (_) => commits++,
            child: const Center(
                key: ValueKey('stub-child'), child: Text('settled')),
          ),
        ),
      ));
      // Turn #1 — the cycle the buggy build survived. 600px so the
      // DELIVERED 400px (first move only wins the arena) clears the
      // 0.42 position threshold at the default 800-wide test surface
      // — TestGesture.up() carries zero velocity by default.
      await _swipe(tester, 600);
      await tester.pumpAndSettle(const Duration(milliseconds: 40));
      expect(commits, 1);
      // Turn #2 — the device killer: re-settling must REUSE the one
      // controller, never construct a second ticker.
      await _swipe(tester, 600);
      await tester.pumpAndSettle(const Duration(milliseconds: 40));
      expect(commits, 2,
          reason: 'the second turn commits exactly like the first');
      expect(find.text('settled'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('R2: unmount mid-settle — zero exceptions', (tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: MushafTurnOverlay(
            currentPage: 1,
            pageCount: 604,
            pageAt: (page) =>
                Text('page $page', textDirection: TextDirection.ltr),
            onCommitPage: (_) {},
            child: const Center(child: Text('settled')),
          ),
        ),
      ));
      final g = await tester.startGesture(const Offset(195, 420));
      await g.moveBy(const Offset(150, 0));
      await tester.pump();
      await g.moveBy(const Offset(2, 0));
      await tester.pump();
      await g.up();
      await tester.pump(const Duration(milliseconds: 30)); // settle live
      // Back-navigation / hot route-change DURING the settle animation.
      await tester.pumpWidget(const MaterialApp(
          home: Center(key: ValueKey('gone'), child: Text('elsewhere'))));
      await tester.pump(const Duration(milliseconds: 30));
      await tester.pumpAndSettle(const Duration(milliseconds: 40));
      expect(find.text('elsewhere'), findsOneWidget);
      expect(tester.takeException(), isNull,
          reason: 'teardown mid-settle must throw nothing (F3 audit)');
    });

    test('R3: single-owner controller — source pins', () {
      final turn = File(
              'lib/features/quran/presentation/mushaf/mushaf_turn.dart')
          .readAsStringSync();
      // F1: ONE controller for the State's whole life, created in
      // initState — a non-nullable late final field makes the nullable
      // dance (the cascade's root) structurally impossible.
      expect(turn, contains('late final AnimationController _settle'));
      expect(RegExp(r'AnimationController\(').allMatches(turn).length, 1,
          reason: 'exactly one creation site — initState (F1)');
      expect(RegExp(r'_settle\?*\.dispose\(\)').allMatches(turn).length, 1,
          reason: 'exactly one dispose site — State.dispose (F1/F3)');
      // F2: the settle wiring is TWO permanent listeners attached once;
      // _animateTo attaches nothing per call anymore.
      expect(turn, contains('..addListener(_onSettleTick)'));
      expect(turn, contains('..addStatusListener(_onSettleStatus)'));
      expect(turn, isNot(contains('..addListener(() {')),
          reason: 'no per-call listener attach (F2)');
      // F4: the mixin stays SingleTicker — and after F1 the contract is
      // TRUE (one ticker ever), which is why no TickerProviderStateMixin
      // escalation is needed.
      expect(turn, contains('with SingleTickerProviderStateMixin'));
      // R4: physics lifelines verbatim (nothing retuned here either):
      expect(turn, contains('static const double commitFraction = 0.42;'));
      expect(turn, contains('static const double commitVelocity = 520;'));
    });
  });

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
      // SIX 12px steps: the accepting move becomes onDragStart, so only
      // the moves AFTER it are updates — 4 would deliver 24px (< the
      // 26px arm threshold); 6 delivers 48px of real drag.
      for (var i = 0; i < 6; i++) {
        await g.moveBy(const Offset(0, 12));
        await tester.pump(const Duration(milliseconds: 12));
      }
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
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      // Route page WINS on open (restore skips when initialPage != 1 —
      // the pre-M contract, pinned by Q2's own jump-math test). That is
      // what makes this the honest ribbon-TAP test: page 3 is not the
      // saved page, so ONLY the ribbon can move the reader now. And the
      // ribbon must still know the saved page — mirroring it before the
      // early return is exactly the Pass M integration line under test.
      await pumpMushaf(tester, initialPage: 3);
      await tester.pumpAndSettle();
      expect(find.text('3 / 604'), findsOneWidget,
          reason: 'the explicit route page holds against the store');
      // Tap the silk column itself (left margin band, mid-height).
      await tester.tapAt(const Offset(30, 47));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('2 / 604'), findsOneWidget,
          reason: 'ribbon tap jumped 3 -> the saved page 2');
      expect(tester.takeException(), isNull);
      final f = MushafRibbon.progressFraction(2, 604);
      expect(f, greaterThan(0.0));
      expect(f, lessThan(0.01));
    });

    testWidgets('ribbon hint text is localized and the a11y label exists',
        (tester) async {
      final en = AppStrings.forCode('en');
      final ar = AppStrings.forCode('ar');
      final ur = AppStrings.forCode('ur');
      final arabic = RegExp(r'[؀-ۿ]');
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
      // pumpWidget on the same widget TYPE reuses State — initState (and
      // the PageController seed) would never re-run. Unmount first.
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
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
      // Comments may say 'PageView' (they explain the contract); a
      // SECOND pager CONSTRUCTION is what must never appear.
      expect(turn, isNot(contains('PageView(')));
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
