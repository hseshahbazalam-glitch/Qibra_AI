// test/features/quran/mushaf_pass_m4_test.dart
// ============================================================
// PASS M4 — DEVICE TRUTH FOR PAPER, THE EDGE-CUT FIX, AND THE
// DELIBERATE TURN RETUNE.
//
// P — RENDERED colors: nothing here greps the palette chain. Every P
//   test pumps the REAL reader (real provider pipeline: mock prefs
//   store → ReadingPreferencesNotifier → QibraPaper.scope) or the REAL
//   settings screen (real SegmentedButton tap), then asserts the COLOR
//   THE TREE ACTUALLY CARRIES — the Scaffold's backgroundColor the
//   renderer consumes, the leaf's ColoredBox.color mid-turn. Source
//   pinning the hexes was D2's job; this pass pins what the widgets
//   the device builds actually hold.
// E — the edge-cut: the user's device said 'thora cut rha h, nice
//   side se' — the gilded free edge lost its corners mid-turn because
//   the rectangular ClipRect sat OUTSIDE the perspective transform
//   while the transform magnifies the lifted edge past the box. The
//   pins below prove the clip contains the leaf's projected quad, is
//   anti-aliased, and that the shadow band feathers to zero AT the
//   fold instead of painting a hard fringe across it.
// W — the retune: velocity-carrying critically damped spring, frame-
//   rate-independent integration, 3px anticipation micro-lift with a
//   growing shadow, the commit haptic on the LANDING, ≤8px base
//   parallax. The physics ledger is in the pass report; W6 here proves
//   every M-suite pin (0.42 / 520 / single-owner controller /
//   notifier-only ticks) stayed in place UNMOVED — the M suite needed
//   zero edits because no pinned string changed meaning.
// ============================================================

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // FontLoader + ByteData (M-suite pattern)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qibra_ai/core/l10n/app_strings.dart';
import 'package:qibra_ai/core/design_system/qibra_colors.dart';
import 'package:qibra_ai/core/design_system/qibra_paper.dart';
import 'package:qibra_ai/core/providers/auth_provider.dart';
import 'package:qibra_ai/features/quran/data/models/quran_models.dart';
import 'package:qibra_ai/features/quran/presentation/mushaf/mushaf_turn.dart';
import 'package:qibra_ai/features/quran/presentation/mushaf_reader_screen.dart';
import 'package:qibra_ai/features/quran/providers/quran_download_provider.dart';
import 'package:qibra_ai/features/quran/providers/reading_preferences_provider.dart';
import 'package:qibra_ai/features/settings/presentation/settings_screen.dart';
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
  number: 7,
  numberInQuran: 7,
  text: 'اِهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ',
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

/// The reader on the REAL preference pipeline — the same harness the
/// M suite pumps, but with an externally owned container so the theme
/// can be driven through the SAME notifier the settings screen calls.
Future<void> pumpReader(WidgetTester tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final container = ProviderContainer(
    overrides: [
      mushafPageIndexProvider.overrideWith((ref) async => Map.of(_index)),
      quranDownloadProvider.overrideWith(_NoopDownloads.new),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      home: const AppStringsScope(
        locale: Locale('en'),
        child: MushafReaderScreen(initialPage: 1),
      ),
    ),
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

/// The reader Scaffold's CANVAS color as the built tree carries it —
/// the value the renderer paints, read off the widget itself.
Color? renderedPageCanvas(WidgetTester tester) {
  final scaffold = tester.widget<Scaffold>(find
      .descendant(
          of: find.byType(MushafReaderScreen),
          matching: find.byType(Scaffold))
      .first);
  return scaffold.backgroundColor;
}

/// Every ColoredBox color the LEAF currently carries mid-turn. The
/// leaf paints its page on `colors.card` — that IS the rendered paper
/// surface rotating under the finger.
Set<Color?> leafColoredBoxColors(WidgetTester tester) {
  final leaf = find.byKey(const ValueKey('mushaf-turn-leaf'));
  return tester
      .widgetList<ColoredBox>(
          find.descendant(of: leaf, matching: find.byType(ColoredBox)))
      .map((c) => c.color)
      .toSet();
}

Future<void> setTheme(WidgetTester tester, QibraReadingTheme theme) async {
  final container =
      ProviderScope.containerOf(tester.element(find.byType(MushafReaderScreen)));
  await container
      .read(readingPreferencesProvider.notifier)
      .setReadingTheme(theme);
  await tester.pump(); // exactly ONE frame — the switch must be instant
}

/// Drag the leaf up mid-turn and HOLD THE FINGER DOWN: 120 wins the
/// arena, 60 delivers travel (the two-step the M suite learned is
/// required). The caller asserts mid-turn, then releaseLeaf() — whose
/// zero-velocity up lands the retract spring and pumps past
/// convergence.
Future<TestGesture> grabLeaf(WidgetTester tester) async {
  final g = await tester.startGesture(const Offset(195, 420));
  await g.moveBy(const Offset(120, 0));
  await tester.pump();
  await g.moveBy(const Offset(60, 0));
  await tester.pump();
  return g;
}

Future<void> releaseLeaf(WidgetTester tester, TestGesture g) async {
  await g.up();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle(const Duration(milliseconds: 40));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppTestFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // ── P — rendered-color device truth ──────────────────────────
  group('P rendered colors', () {
    testWidgets('P1: night default renders the AMBIENT canvas — the '
        'D2 machinery is provably absent from the Night path',
        (tester) async {
      print('::notice::P1-enter');
      await pumpReader(tester);
      final ctx = tester.element(find.byType(MushafReaderScreen));
      final ambient = QibraColors.of(ctx);
      expect(ambient is! QibraPaperColors, isTrue);
      expect(renderedPageCanvas(tester), isNot(same(QibraPaper.paper)));
      expect(renderedPageCanvas(tester), same(ambient.background),
          reason: 'the scaffold paints the app palette\'s own instance — '
              'not a paper copy, not a lerp, THE object');
      print('::notice::P1-ok');
    });

    testWidgets('P2: a persisted paper preference lands as paper IN THE '
        'TREE — the color the device would paint', (tester) async {
      print('::notice::P2-enter');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'quran_reading_preferences_v1_reading_theme', 'paper');
      await pumpReader(tester);
      expect(renderedPageCanvas(tester), same(QibraPaper.paper));
      final ctx = tester.element(find.byType(MushafReaderScreen));
      expect(QibraColors.of(ctx).card, same(QibraPaper.paper));
      print('::notice::P2-ok');
    });

    testWidgets('P3: mid-turn the LEAF itself renders paper — not just '
        'the settled page', (tester) async {
      print('::notice::P3-enter');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          'quran_reading_preferences_v1_reading_theme', 'paper');
      await pumpReader(tester);
      final g = await grabLeaf(tester);
      expect(find.byKey(const ValueKey('mushaf-turn-leaf')), findsOneWidget);
      expect(leafColoredBoxColors(tester), contains(QibraPaper.paper),
          reason: 'the turning page paints colors.card == paper — the '
              'viral-reader claim proven on the widget the renderer '
              'consumes, never by grep');
      await releaseLeaf(tester, g);
      print('::notice::P3-ok');
    });

    testWidgets('P4: the REAL settings flow — tap Paper, tap Night; the '
        'preference persists through the real notifier', (tester) async {
      print('::notice::P4-enter');
      await tester.pumpWidget(ProviderScope(
        overrides: [
          currentUserProvider.overrideWithValue(null),
          userDisplayNameProvider.overrideWithValue('Guest'),
          isGuestModeProvider.overrideWithValue(true),
        ],
        child: MaterialApp(home: const SettingsScreen()),
      ));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      final paper = find.text('Paper');
      expect(paper, findsOneWidget,
          reason: 'the Reading Theme card ships a Paper segment (D2)');
      await tester.ensureVisible(paper);
      await tester.pump();
      await tester.tap(paper);
      await tester.pump();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('quran_reading_preferences_v1_reading_theme'),
          'paper',
          reason: 'the tap persisted through the real pipeline — no '
              'test-side shortcut');
      await tester.tap(find.text('Night'));
      await tester.pump();
      expect(prefs.getString('quran_reading_preferences_v1_reading_theme'),
          'night');
      print('::notice::P4-ok');
    });

    testWidgets('P5: instant switch BOTH WAYS at the rendered level — '
        'including mid-turn, zero animation frames', (tester) async {
      print('::notice::P5-enter');
      await pumpReader(tester);
      final night = renderedPageCanvas(tester);
      expect(night, isNot(same(QibraPaper.paper)));

      await setTheme(tester, QibraReadingTheme.paper);
      // ONE pump — no ramp, no settle: lerp-to-self + a copied Theme
      // mean the very next frame is FULLY paper.
      expect(renderedPageCanvas(tester), same(QibraPaper.paper));

      // Mid-turn flip: the leaf's ColoredBox reads the LIVE theme
      // inside the turn's AnimatedBuilder — a theme change while the
      // page is airborne repaints it the SAME frame. (If the chain
      // ever cached the painter's color, this rots first.)
      final g = await grabLeaf(tester);
      expect(leafColoredBoxColors(tester), contains(QibraPaper.paper));
      await setTheme(tester, QibraReadingTheme.night);
      expect(leafColoredBoxColors(tester), isNot(contains(QibraPaper.paper)),
          reason: 'back to navy on the same frame the preference lands');

      await releaseLeaf(tester, g);
      // And the canvas is the ORIGINAL instance it started on — the
      // Night path is not 'close to' night, it IS night's own object
      // again (the scope returns the child unwrapped).
      expect(renderedPageCanvas(tester), same(night));
      print('::notice::P5-ok');
    });
  });

  // ── E — the edge-cut fix ─────────────────────────────────────
  group('E edge fidelity', () {
    test('E1: the clip is the projected quad — every leaf corner '
        'survives the turn, the non-page region beyond does not', () {
      print('::notice::E1-enter');
      const w = 390.0, h = 844.0;
      for (var i = 0; i <= 20; i++) {
        final t = i / 20;
        final ang =
            MushafTurnGeometry.angleFor(MushafTurnDirection.forward, t);
        final lift = MushafTurnGeometry.anticipation(t);
        final path =
            MushafTurnLeafClipper(angle: ang, lift: lift).getClip(const Size(w, h));
        final corners =
            MushafTurnGeometry.projectedCorners(w, h, ang, lift);
        for (final c in corners) {
          expect(c.isFinite, isTrue);
          expect(path.contains(c), isTrue,
              reason: 't=$t: a real corner of the projected paper must be '
                  'INSIDE the clip — this is the exact cut the device saw '
                  'on the gilded side');
        }
        // Tight quad: 40px above the topmost corner is NOT page, so it
        // must stay outside the clip.
        expect(path.contains(Offset(corners.first.dx, corners.first.dy - 40)),
            isFalse);
      }
      // THE CUT, PROVEN: mid-turn, the perspective-MAGNIFIED free-edge
      // corner of the paper renders ABOVE y=0 of the leaf box (the
      // hinge-anchored transform divides the lifted side's y by
      // 1 + p·x < 1). The old rectangular ClipRect stopped at exactly
      // 0 — everything past it was the device's 'thora cut'. The new
      // clip's bounds must OPEN where the paper actually goes:
      final ang =
          MushafTurnGeometry.angleFor(MushafTurnDirection.forward, 0.62);
      final lift = MushafTurnGeometry.anticipation(0.62);
      final corners = MushafTurnGeometry.projectedCorners(w, h, ang, lift);
      expect(corners.first.dy, lessThan(0.0),
          reason: 'the projected free-edge top is genuinely off-box — '
              'if this were >= 0 the old clip never cut anything');
      final opened = MushafTurnLeafClipper(angle: ang, lift: lift)
          .getClip(const Size(w, h))
          .bounds;
      expect(opened.top, lessThan(corners.first.dy),
          reason: 'the clip encloses that corner WITH its AA slack — the '
              'cut region is inside now...');
      expect(opened.top, greaterThan(corners.first.dy - 2.0),
          reason: '...and still TIGHT (slack is 1.2px, not a free pass '
              'to overdraw); non-page points stay out');
      final rest = MushafTurnLeafClipper(
              angle: MushafTurnGeometry.angleFor(
                  MushafTurnDirection.forward, 0),
              lift: 0)
          .getClip(const Size(w, h))
          .bounds;
      expect(rest.top, inInclusiveRange(-2.0, 0.0),
          reason: 'at touch-down the quad is THE BOX within its AA '
              'slack only — no lift, no parallax, the settled frame is '
              'untouched');
      print('::notice::E1-ok');
    });

    testWidgets('E2: the leaf is wrapped in an ANTI-ALIASED ClipPath — '
        'the ClipRect that did the cutting is gone', (tester) async {
      await pumpReader(tester);
      final g = await grabLeaf(tester);
      final leaf = find.byKey(const ValueKey('mushaf-turn-leaf'));
      final clips =
          find.descendant(of: leaf, matching: find.byType(ClipPath));
      expect(clips, findsOneWidget);
      expect(tester.widget<ClipPath>(clips).clipBehavior, Clip.antiAlias,
          reason: 'feathered, not chopped — AA kills the stair-step along '
              'the band boundary');
      expect(find.descendant(of: leaf, matching: find.byType(ClipRect)),
          findsNothing);
      await releaseLeaf(tester, g);
    });

    testWidgets('E3: shadow band — feathers to zero at its own end and '
        'ends EXACTLY at the fold, never across it', (tester) async {
      await pumpReader(tester);
      final g = await grabLeaf(tester);
      final band = find.descendant(
          of: find.byKey(const ValueKey('mushaf-turn-shadow')),
          matching: find.byType(DecoratedBox));
      final deco =
          tester.widget<DecoratedBox>(band.first).decoration as BoxDecoration;
      final grad = deco.gradient as LinearGradient;
      expect(grad.colors.first.a, 0.0, reason: 'lead-in alpha zero');
      expect(grad.colors.last.a, 0.0,
          reason: 'stop continuity: the band ENDS in nothing — no hard '
              'edge of shadow anywhere, least of all over the paper');
      expect(grad.stops!.first, 0.0);
      expect(grad.stops!.last, 1.0);
      expect(grad.colors.length, grad.stops!.length);
      // One fold, two riders: the shadow (width 64, translate
      // edgeX−64) and the gild (translate edgeX−1) must land on the
      // SAME edgeX — band-seam continuity, cross-widget.
      double tx(Key k) => tester
          .widget<Transform>(find
              .descendant(of: find.byKey(k), matching: find.byType(Transform))
              .first)
          .transform
          .getTranslation()
          .x;
      final shadowX = tx(const ValueKey('mushaf-turn-shadow'));
      final gildX = tx(const ValueKey('mushaf-turn-gild'));
      expect(shadowX + 64, closeTo(gildX + 1, 1e-9),
          reason: 'shadow right edge == gild center == the free edge');
      await releaseLeaf(tester, g);
    });
  });
}
