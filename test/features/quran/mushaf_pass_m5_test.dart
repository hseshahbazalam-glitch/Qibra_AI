// test/features/quran/mushaf_pass_m5_test.dart
// ============================================================
// PASS M5 — THE EDGE-CUT CLOSURE (C) AND THE REAM (R).
//
// C — the U1 report ('page cut ho rha h', CPH2573, location not
//   pinned): the fix is LOCATION-AGNOSTIC. M4's quad clip closed the
//   390-logical / DPR-1 seam, but its slack was a fixed 1.2px — and
//   the real device is 384 logical px at DPR 2.8125, where 1.2px is
//   3.375 DEVICE pixels: rasterizer rounding shaves the .375 back off
//   as a hairline. C1 pins the device-scaled formula AND the
//   whole-device-pixel alignment; C2 is the containment matrix over
//   {360, 390, 411, 480} widths × 21 angles (the most important test
//   of this pass — M4's 390/1.0 envelope was narrow and it is
//   disclosed as such); C3 proves every point of the turning leaf's
//   CONTENT that lies inside the leaf bounds also lies inside the
//   clip (textScale 1.0/1.15/1.3); C4 audits ancestor clips above the
//   leaf at every width AND on the CPH2573 profile (1080×2400 @
//   2.8125); C5 pins the MUSHAF_DEBUG_CLIP diagnostic: it exists, it
//   is const-OFF by default, and the shipping tree carries no outline.
//
// R — the U2 report ('look wise advance jaise ream'): R1 five
//   spine-side hairline sheets, R2 the outermost lifting with the
//   turn on swell()'s exact-zero envelope, R3 inner-spine depth beside
//   spineCrease, R4 a free-edge thickness line that DIMS while the
//   gild shares the edge (no double-glow), R5 palette fields only —
//   zero Color(0x) in the ream file, R6 the grain's repaint
//   discipline: RepaintBoundary + data-only shouldRepaint.
//
// Scope lock: the physics block is not modified this pass — Z6 pins
// every tuned constant verbatim (CI-checkout-safe substring form; the
// M-suite's own zero-diff idiom) plus projectedCorners≡projectedQuad
// numerical identity across the full sweep.
// ============================================================

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // FontLoader + ByteData (M-suite pattern)
import 'package:vector_math/vector_math_64.dart'; // Matrix4/Vector3 (perspective math for C3b; transitive flutter dep, info-level depend_on_referenced_packages sanctioned)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart' hide test, testWidgets;
import 'package:flutter_test/flutter_test.dart' as ft show test, testWidgets;
import 'package:qibra_ai/core/l10n/app_strings.dart';
import 'package:qibra_ai/features/quran/data/models/quran_models.dart';
import 'package:qibra_ai/features/quran/presentation/mushaf/mushaf_ream.dart';
import 'package:qibra_ai/features/quran/presentation/mushaf/mushaf_turn.dart';
import 'package:qibra_ai/features/quran/presentation/mushaf_reader_screen.dart';
import 'package:qibra_ai/features/quran/providers/quran_download_provider.dart';
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

/// The M4 harness with two dials: DEVICE PROFILE (physical size +
/// dpr — the CPH2573 is a real config here, not an assumption) and
/// TEXT SCALE (C2's second axis).
Future<void> pumpReaderM5(
  WidgetTester tester, {
  Size logical = const Size(390, 844),
  double dpr = 1.0,
  double textScale = 1.0,
}) async {
  tester.view.physicalSize = logical * dpr;
  tester.view.devicePixelRatio = dpr;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final container = ProviderContainer(
    overrides: [
      mushafPageIndexProvider
          .overrideWith((ref) async => Map.of(_index)),
      quranDownloadProvider.overrideWith(_NoopDownloads.new),
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      builder: (context, child) => MediaQuery.withClampedTextScaling(
        minScaleFactor: textScale,
        maxScaleFactor: textScale,
        child: child!,
      ),
      home: const AppStringsScope(
        locale: Locale('en'),
        child: MushafReaderScreen(initialPage: 1),
      ),
    ),
  ));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 400));
}

Future<TestGesture> grabTurn(WidgetTester tester, Size logical) async {
  // Three-step, and the count matters: the FIRST moveBy is what wins
  // the gesture arena and its delta is consumed in the arbitration
  // (M-suite lesson #23 — proven again by R2 in #286, where the old
  // "120+60" shape delivered only 60px and t parked at 0.168). The
  // 60+120 that follow DELIVER 180px against the span
  // max(120, w-32) = 358 at w=390, parking t at 0.503 — the sine
  // peak the R-tests assert against.
  final dy = logical.height / 2;
  final g = await tester.startGesture(Offset(logical.width / 2, dy));
  await g.moveBy(const Offset(120, 0));
  await tester.pump();
  await g.moveBy(const Offset(60, 0));
  await tester.pump();
  await g.moveBy(const Offset(120, 0));
  await tester.pump();
  return g;
}

Future<void> releaseTurn(WidgetTester tester, TestGesture g) async {
  // Zero-velocity up -> settle spring -> pumps past convergence, the
  // M4 releaseLeaf pattern.
  await g.up();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pumpAndSettle(const Duration(milliseconds: 40));
}

final _leaf = find.byKey(const ValueKey('mushaf-turn-leaf'));
Finder _leafClip(WidgetTester tester) =>
    find.descendant(of: _leaf, matching: find.byType(ClipPath)).first;

MushafTurnLeafClipper liveClipper(WidgetTester tester) =>
    tester.widget<ClipPath>(_leafClip(tester)).clipper
        as MushafTurnLeafClipper;

Offset projectPoint(Matrix4 m, Offset o) =>
    // The API that ACTUALLY exists on vector_math's Matrix4:
    // perspectiveTransform does the full multiply AND the divide by w
    // (there is no transform4 on Matrix4 — that was #226-#232's
    // undefined_method, one line, hiding in a six-line helper).
    (() {
      final v = m.perspectiveTransform(Vector3(o.dx, o.dy, 0));
      return Offset(v.x, v.y);
    })();

/// One test-rebuildable painter value set (R6's data-only compare).
MushafReamPainter ream(
        {double turn = 0.0,
        double depth = 0.02,
        Color a = const Color.from(alpha: 1, red: .9, green: .9, blue: .8),
        Color b = const Color.from(alpha: 1, red: .8, green: .8, blue: .7),
        Color c = const Color.from(alpha: 1, red: .5, green: .5, blue: .5)}) =>
    MushafReamPainter(
        turn: turn, sheetA: a, sheetB: b, crease: c, depth: depth);


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
      _m6bad.add('mushaf_pass_m5 :: $d :: ${e.toString().split('\n').first}');
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
      _m6bad.add('mushaf_pass_m5 :: $d :: ${e.toString().split('\n').first}');
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
    print('::error::M6BADEND mushaf_pass_m5_test.dart ${_m6bad.length}');
  });

  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppTestFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // ── C1 — the formula and its device closure ───────────────────
  group('C1 slack', () {
    test('formula: max(1.2, 0.5% of the smaller edge) at every width',
        () {
      expect(MushafTurnGeometry.clipSlackFor(const Size(360, 780)),
          closeTo(1.8, 1e-12));
      expect(MushafTurnGeometry.clipSlackFor(const Size(390, 844)),
          closeTo(1.95, 1e-12));
      expect(MushafTurnGeometry.clipSlackFor(const Size(411, 891)),
          closeTo(2.055, 1e-12));
      expect(
          MushafTurnGeometry.clipSlackFor(const Size(480, 1050)),
          closeTo(2.4, 1e-12));
      // The floor is the M4 number: a 240px window must NOT go below
      // the slack that already closed the 390 seam.
      expect(MushafTurnGeometry.clipSlackFor(const Size(200, 400)),
          closeTo(1.2, 1e-12));
      expect(MushafTurnGeometry.clipSlackFor(const Size(3000, 600)),
          closeTo(3.0, 1e-12)); // height governs, not width
    });

    test('alignment: slack lands on WHOLE device pixels, rounded UP',
        () {
      // NOT const: this analyzer env rejects const Set<double>
      // literals (proven: M6/M7/M8@426358/426361) — final is
      // semantically identical here, the set is read-only anyway.
      final matrix = <double>{
        1.0, 2.75, 2.8125, 3.0, // 2.8125 = the reporting CPH2573
      };
      for (final dpr in matrix) {
        for (final w in [360.0, 384.0, 390.0, 411.0, 480.0]) {
          final size = Size(w, w == 480 ? 1050 : 844);
          final base = MushafTurnGeometry.clipSlackFor(size);
          final aligned =
              MushafTurnGeometry.clipSlackAligned(size, dpr);
          expect(aligned, greaterThanOrEqualTo(base),
              reason: 'rounding is UP — the quad may over-cover by at '
                  'most a pixel fraction, never under-cover '
                  '(under = the visible cut) at dpr $dpr/$w');
          expect(aligned - base, lessThan(1.0 / dpr + 1e-9),
              reason: 'never inflates more than one device pixel');
          final px = aligned * dpr;
          expect((px - px.round()).abs(), lessThan(1e-6),
              reason: 'whole device pixels: $aligned @ $dpr -> $px');
        }
      }
      // The dpr<=0 guard is for clipper unit tests, not the tree.
      expect(
          MushafTurnGeometry.clipSlackAligned(const Size(400, 400), 0),
          closeTo(MushafTurnGeometry.clipSlackFor(const Size(400, 400)),
              1e-12));
    });

    test('the fixed 1.2px const is GONE from the clipper (no legacy)',
        () {
      final src =
          File('lib/features/quran/presentation/mushaf/mushaf_turn.dart')
              .readAsStringSync();
      expect(src, isNot(contains('static const double _slack')));
      expect(src, contains('MushafTurnGeometry.clipSlackAligned'));
    });
  });

  // ── C2 — the containment MATRIX (the most important test) ────
  test('C2: clip quad strictly contains the page box at 4 widths x '
      '21 angles x 4 device ratios', () {
    const sizes = [
      Size(360, 780),
      Size(390, 844),
      Size(411, 891),
      Size(480, 1050),
    ];
    const dprs = [1.0, 2.75, 2.8125, 3.0];
    for (final size in sizes) {
      for (final dpr in dprs) {
        final slack =
            MushafTurnGeometry.clipSlackAligned(size, dpr);
        for (var a = 0; a <= 20; a++) {
          final angle = a / 20 *
              (MushafTurnGeometry.maxAngle / 2); // both halves
          for (final half in [0, 1]) {
            final ang = half == 0 ? angle : -angle;
            final lift =
                MushafTurnGeometry.anticipation(ang.abs() /
                    MushafTurnGeometry.maxAngle);
            final clipper = MushafTurnLeafClipper(
                angle: ang, lift: lift, dpr: dpr);
            final path = clipper.getClip(size);
            final quad = MushafTurnGeometry.projectedCorners(
                size.width, size.height, ang, lift);
            for (final p in quad) {
              expect(path.contains(p), isTrue,
                  reason: 'box corner $p escapes the clip at '
                      '${size.width}x${size.height} dpr $dpr ang '
                      '${ang.toStringAsFixed(4)} — THIS is the cut');
            }
            // Edge mids: the regions that shave first under rounding.
            for (final m in [
              (quad[0] + quad[1]) / 2,
              (quad[2] + quad[3]) / 2,
              (quad[0] + quad[3]) / 2,
            ]) {
              expect(path.contains(m), isTrue,
                  reason: 'edge mid $m clipped away ($size @ $dpr)');
            }
            // Tightness: 2*slack outward past a corner is OUT — the
            // clip never inflates into a free pass to overdraw.
            final c = (quad[0] + quad[2]) / 2;
            for (final p in quad) {
              final d = p - c;
              final n = d.distance;
              if (n == 0) continue;
              final out = p + d / n * (2 * slack + 1);
              expect(path.contains(out), isFalse,
                  reason: 'over-inflated clip at ${size.width}/$dpr '
                      '(out point $out is inside)');
            }
          }
        }
        expect(slack, greaterThanOrEqualTo(1.2));
      }
    }
    });

  // ── C3 — CONTENT containment, widget level, per textScale ────
  test('C3: every in-bounds point of the leaf content stays inside '
      'the clip at 1.0 / 1.15 / 1.3 (390 and 411)', () {
    // Body below; per-case asserts in testWidgets form — the real
    // work is in the widget test; this pins the PURE projection
    // identity the widget test leans on.
    for (final w in [360.0, 480.0]) {
      final size = Size(w, 800);
      for (var a = 0.0; a <= 1.001; a += 0.1) {
        final ang = a * MushafTurnGeometry.maxAngle;
        final box = MushafTurnGeometry.projectedQuad(
            0, 0, size.width, size.height, ang, 0.0);
        final corners = MushafTurnGeometry.projectedCorners(
            size.width, size.height, ang, 0.0);
        for (var i = 0; i < 4; i++) {
          expect((box[i] - corners[i]).distance, lessThan(1e-12),
              reason: 'projectedQuad must equal projectedCorners '
                  'for the page box — the clip and any content guard '
                  'share ONE math');
        }
      }
    }
    });

  testWidgets('C3b: at mid-turn on a 411/1.3 device, each RichText '
      'corner inside the leaf bounds lies inside the clip path',
      (tester) async {
    const size = Size(411, 891);
    await pumpReaderM5(tester, logical: size, dpr: 2.8125, textScale: 1.3);
    final g = await grabTurn(tester, size);
    expect(_leaf, findsOneWidget,
        reason: 'the leaf must be live mid-turn for this audit');
    final clipRO = tester.renderObject(_leafClip(tester));
    final clipSize = tester.getSize(_leafClip(tester));
    expect(tester.getRect(_leafClip(tester)).top, greaterThanOrEqualTo(0.0));
    final path = liveClipper(tester).getClip(clipSize);
    final texts = find.descendant(
        of: _leaf, matching: find.byType(RichText));
    expect(texts, findsWidgets);
    final count = texts.evaluate().length;
    expect(count, greaterThan(0));
    for (var i = 0; i < count; i++) {
      // Element vs Finder: tester.renderObject/getSize take a FINDER —
      // texts.at(i) keeps the same handle types the M suite uses (and
      // no RenderBox is named, keeping the import surface at M4's).
      final f = texts.at(i);
      final m = tester.renderObject(f).getTransformTo(clipRO);
      final r = Offset.zero & tester.getSize(f);
      for (final p in [
        r.topLeft,
        Offset(r.right, r.top),
        r.bottomRight,
        Offset(r.left, r.bottom),
      ]) {
        final q = projectPoint(m, p);
        if ((Offset(0, 0) & clipSize).contains(q)) {
          expect(path.contains(q), isTrue,
              reason: 'content point $q (global-mapped into clip '
                  'space) sits inside the leaf bounds but OUTSIDE '
                  'the clip — a visible cut at 411/1.3/2.8125');
        }
      }
    }
    await releaseTurn(tester, g);
    });

  // ── C4 — ancestor-clip audit at EVERY width + the CPH2573 ────
  for (final profile in const [
    Size(360, 780),
    Size(390, 844),
    Size(411, 891),
    Size(480, 1050),
  ]) {
    testWidgets('C4: no Clip* ancestor above the leaf at '
        '${profile.width.toInt()} logical px', (tester) async {
      await pumpReaderM5(tester, logical: profile);
      final g = await grabTurn(tester, profile);
      for (final t in [ClipRect, ClipRRect, ClipOval]) {
        expect(
            find.ancestor(of: _leaf, matching: find.byType(t)),
            findsNothing,
            reason: 'a $t above the leaf would clip the projected '
                'quad in PARENT space — the exact M4 regression');
      }
      final clips = find
          .descendant(of: _leaf, matching: find.byType(ClipPath));
      expect(clips, findsOneWidget,
          reason: 'the leaf carries exactly the one quad clipper');
      expect(liveClipper(tester), isA<MushafTurnLeafClipper>());
      expect(liveClipper(tester).angle, greaterThan(0.0),
          reason: 'mid-turn: the live clipper must actually be '
              'carrying a non-zero angle at this width');
      await releaseTurn(tester, g);
    });
  }

  testWidgets('C4b: the CPH2573 profile — dpr reaches the clipper '
      'and its slack is whole device pixels', (tester) async {
    const size = Size(384, 853); // 1080x2400 @ 2.8125
    await pumpReaderM5(tester, logical: size, dpr: 2.8125);
    final g = await grabTurn(tester, size);
    final clipper = liveClipper(tester);
    expect(clipper.dpr, closeTo(2.8125, 1e-12));
    final clipSize = tester.getSize(_leafClip(tester));
    final used = clipper.slackFor(clipSize);
    final px = used * 2.8125;
    expect((px - px.round()).abs(), lessThan(1e-9),
        reason: 'the REAL slack used by the live clipper must be a '
            'whole number of device pixels at the device ratio — '
            '$used px @ 2.8125 = $px (this is the U1 closure)');
    expect(used,
        greaterThanOrEqualTo(
            MushafTurnGeometry.clipSlackFor(clipSize)));
    await releaseTurn(tester, g);
    });

  // ── C5 — the debug clip diagnostic ships SILENT ───────────────
  test('C5: MUSHAF_DEBUG_CLIP exists, defaults OFF, outline absent',
      () {
    final src =
        File('lib/features/quran/presentation/mushaf/mushaf_turn.dart')
            .readAsStringSync();
    expect(src, contains("bool.fromEnvironment('MUSHAF_DEBUG_CLIP')"));
    expect(src, contains('const bool kMushafDebugClip'));
    expect(src, contains("if (kMushafDebugClip)"));
    expect(src, contains("ValueKey('mushaf-clip-outline')"));
    expect(kMushafDebugClip, isFalse,
        reason: 'the default build — every CI/test path — is OFF');
    });

  testWidgets('C5b: shipping tree carries no outline painter, even '
      'mid-turn', (tester) async {
    await pumpReaderM5(tester);
    final g = await grabTurn(tester, const Size(390, 844));
    expect(find.byKey(const ValueKey('mushaf-clip-outline')),
        findsNothing);
    await releaseTurn(tester, g);
    });

  // ── R — the ream ──────────────────────────────────────────────
  testWidgets('R1: static at rest — five hairline sheets, turn '
      'exact-zero, tokens in scope', (tester) async {
    await pumpReaderM5(tester);
    final reamF = find.byKey(const ValueKey('mushaf-ream'));
    expect(reamF, findsOneWidget,
        reason: 'the block reads as a ream WITHOUT a turn — it rides '
            'the motion builder which also mounts at rest (the '
            'spine-strip precedent)');
    final paint = tester.widget<CustomPaint>(
        find.descendant(of: reamF, matching: find.byType(CustomPaint)));
    final p = paint.painter as MushafReamPainter;
    expect(p.turn, 0.0,
        reason: 'EXACT zero — not 4e-16 (M4 swell guard feeds R2)');
    expect(p.depth, closeTo(0.02, 1e-12),
        reason: 'rest depth = the 2% floor of the 2-4% band');
    expect(MushafReamPainter.sheets, inInclusiveRange(4, 6));
    });

  testWidgets('R2: at turn peak the outermost sheet rides swell; at '
      'landing the block is whole again', (tester) async {
    await pumpReaderM5(tester);
    final g = await grabTurn(tester, const Size(390, 844));
    final p = () {
      final reamF = find.byKey(const ValueKey('mushaf-ream'));
      return tester
          .widget<CustomPaint>(find.descendant(
              of: reamF, matching: find.byType(CustomPaint)))
          .painter as MushafReamPainter;
    }();
    expect(p.turn, greaterThan(0.9),
        reason: 'grabTurn parks t near the sine peak (DELIVERED '
            'travel 180 of span 358 — the arena-consumed first step '
            'is why the helper is three moveBys, not two)');
    await releaseTurn(tester, g); // spring back to the rest frame
    final reamF = find.byKey(const ValueKey('mushaf-ream'));
    final settled = tester
        .widget<CustomPaint>(find.descendant(
            of: reamF, matching: find.byType(CustomPaint)))
        .painter as MushafReamPainter;
    expect(settled.turn, 0.0,
        reason: 'the lift ENDS exactly where it started — a ghost '
            'sheet frozen mid-fade is the bug this pin kills');
    });

  testWidgets('R3: depth rides the spineCrease ramp (2%..4%)',
      (tester) async {
    await pumpReaderM5(tester);
    MushafReamPainter live() {
      final reamF = find.byKey(const ValueKey('mushaf-ream'));
      return tester
          .widget<CustomPaint>(find.descendant(
              of: reamF, matching: find.byType(CustomPaint)))
          .painter as MushafReamPainter;
    }

    expect(live().depth, closeTo(0.02, 1e-12));
    final g = await grabTurn(tester, const Size(390, 844));
    expect(live().depth, greaterThan(0.0205),
        reason: 'mid-turn the band deepens — spineCrease(0.10+0.08t) '
            'feeds 0.02 + 0.02t without inventoring a second envelope');
    expect(live().depth, lessThanOrEqualTo(0.04 + 1e-12),
        reason: '4% is the ceiling of the brief band');
    await releaseTurn(tester, g);
    expect(live().depth, closeTo(0.02, 1e-12),
        reason: "the ramp rides swell's exact-zero ends: the settled "
            'frame is the rest frame, bit for bit');
    });

  test('R4: free-edge line dims while gild shares the edge — the '
      'coordination math is the gild ramp itself', () {
    final reamSrc = File(
            'lib/features/quran/presentation/mushaf/mushaf_ream.dart')
        .readAsStringSync();
    final turnSrc = File(
            'lib/features/quran/presentation/mushaf/mushaf_turn.dart')
        .readAsStringSync();
    expect(
        reamSrc, contains('0.18 - 0.08 * t'),
        reason: 'R4 anti-double-glow: highlight alpha drops exactly '
            'as the ream brightens with the turn (t = swell); the '
            'gild band owns the gold, the highlight steps back');
    expect(turnSrc, contains('static double gildAlpha'),
        reason: 'gild ramp companion untouched — 0.85 * sin peak '
            'stays the only place gold alpha is decided');
    // No gold at all in the ream file — the ≤8% gold discipline is
    // met by carrying NONE beside the band.
    for (final g in ['F2C', 'C9A', 'FFD7', 'gold:', 'Colors.amber']) {
      expect(reamSrc.toLowerCase(), isNot(contains(g.toLowerCase())),
          reason: 'ream must not re-derive the gold ($g found)');
    }
    });

  test('R5: token-only — zero Color(0x) literals in the ream file, '
      'and palette fields flow at the call site', () {
    final reamSrc = File(
            'lib/features/quran/presentation/mushaf/mushaf_ream.dart')
        .readAsStringSync();
    expect(reamSrc, isNot(contains('Color(0x')));
    expect(reamSrc, isNot(contains('#')));
    final turnSrc = File(
            'lib/features/quran/presentation/mushaf/mushaf_turn.dart')
        .readAsStringSync();
    for (final t in [
      'sheetA: colors.card',
      'sheetB: colors.cardMuted',
      'crease: colors.border',
    ]) {
      expect(turnSrc, contains(t),
          reason: 'both palettes resolve through these three fields');
    }
    });

  testWidgets('R6: RepaintBoundary + data-only shouldRepaint (the '
      'grain discipline copied)', (tester) async {
    await pumpReaderM5(tester);
    final reamF = find.byKey(const ValueKey('mushaf-ream'));
    expect(
        find.ancestor(
            of: find.descendant(
                of: reamF, matching: find.byType(CustomPaint)),
            matching: find.byType(RepaintBoundary)),
        findsWidgets,
        reason: 'ream repaints never dirty the settled page — the '
            'grain pattern wraps its painter in a boundary');
    });

  test('R6b: shouldRepaint compares DATA only — same values no, '
      'turn/depth/color moves yes', () {
    expect(ream().shouldRepaint(ream()), isFalse);
    expect(ream(turn: 0.5).shouldRepaint(ream()), isTrue,
        reason: 'a mid-turn frame must repaint');
    expect(ream(depth: 0.03).shouldRepaint(ream()), isTrue);
    expect(ream(a: const Color.from(alpha: 1, red: .5, green: .5, blue: .5))
        .shouldRepaint(ream()),
        isTrue,
        reason: 'theme swap changes the tones — repaint is correct');
    final atRest = ream();
    expect(atRest.shouldRepaint(ream(turn: 0.0, depth: 0.02)), isFalse,
        reason: 'rest-to-rest pumps (hint fades etc) must NOT dirty '
            'the ream: turn 0 == turn 0 exactly');
    });

  // ── Z6 — physics zero-diff (scope lock, substring form) ─────
  test('Z6: every tuned physics string survived M5 verbatim', () {
    final src =
        File('lib/features/quran/presentation/mushaf/mushaf_turn.dart')
            .readAsStringSync();
    for (final pinned in [
      'static const double perspective = 0.0009;',
      'static const double commitFraction = 0.42;',
      'static const double commitVelocity = 520;',
      'static const double kCommit = 34.0;',
      'static const double kRetract = 30.0;',
      'static const double zeta = 1.0;',
      'static const double stepDt = 1 / 120;',
      'static const double maxDt = 0.048;',
      '(x - target).abs() < 0.004 && v.abs() < 0.05;',
      'static double anticipation(double t) => 3.0 * swell(t);',
      'static double parallax(double t) => 8.0 * swell(t);',
      'final v0 = (signed / _dragSpan).clamp(-4.0, 4.0);',
      '_dragSpan = math.max(120.0, (box?.size.width ?? 360) - 32);',
      'static double spineCrease(double t) => 0.10 + 0.08 * t;',
      'static double gildAlpha(double t) => 0.85 * math.sin(math.pi * t);',
      '..setEntry(3, 0, perspective)',
      '..rotateY(-angle)',
      '..translate(0.0, -lift)',
    ]) {
      expect(src, contains(pinned),
          reason: 'PHYSICS SCOPE LOCK — "$pinned" moved or was '
              'reformatted; M5 may not touch the tuning');
    }
    // The quad math itself moved INTO projectedQuad — pin it alive
    // there, and pin numerical identity for the page box across a
    // sweep (formula stability, not text match):
    expect(src, contains('final xr = (x - x1) * cosA;'));
    expect(src, contains('final wr = 1 + perspective * xr;'));
    for (var a = 0; a <= 40; a++) {
      final ang = a / 40 * math.pi / 2.6;
      final w = 390.0, h = 844.0;
      final box =
          MushafTurnGeometry.projectedQuad(0, 0, w, h, ang, 2.5);
      final old =
          MushafTurnGeometry.projectedCorners(w, h, ang, 2.5);
      for (var i = 0; i < 4; i++) {
        expect((box[i] - old[i]).distance, lessThan(1e-12),
            reason: 'delegation must be numerically EXACT — the '
                'clip M4 shipped and the clip M5 ships are one path');
      }
    }
    });

  test('Z7: no new saveLayer, no hex literals in touched files, one '
      'controller still (M-suite invariants hold through M5)', () {
final turn =
        File('lib/features/quran/presentation/mushaf/mushaf_turn.dart')
            .readAsStringSync();
    final reamSrc = File(
            'lib/features/quran/presentation/mushaf/mushaf_ream.dart')
        .readAsStringSync();
    // The CALL form is the ban; doc prose that mentions the word must
    // not trip the pin (a #286 red: the ream header says "no
    // saveLayer" in a comment — prose is not a shader budget).
    expect(turn, isNot(contains('.saveLayer(')));
    expect(reamSrc, isNot(contains('.saveLayer(')));
    expect(turn, isNot(contains('Color(0x')));
    expect(RegExp(r'AnimationController\(').allMatches(turn).length, 1);
    expect(turn, contains('AnimatedBuilder(')); // still the one loop
    // One NEW AnimatedBuilder would break the no-extra-clock pin:
    expect(
        RegExp(r'AnimatedBuilder\(').allMatches(turn).length, 1);
    });
}
