// ignore_for_file: unused_import, unused_local_variable, unused_element
// ignore_for_file: unused_import, unused_local_variable, unused_element
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
import 'package:flutter_test/flutter_test.dart';
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
  // Same two-step the M suite proved the arena needs: 120 wins the
  // gesture arena, the rest delivers travel (against the span
  // max(120, w-32), 180px parks t near the sine peak).
  final dy = logical.height / 2;
  final g = await tester.startGesture(Offset(logical.width / 2, dy));
  await g.moveBy(const Offset(120, 0));
  await tester.pump();
  await g.moveBy(const Offset(60, 0));
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppTestFonts);
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // ── C1 — the formula and its device closure ───────────────────
  // C1 group content, unwrapped, test 2 only
    test('alignment: slack lands on WHOLE device pixels, rounded UP',
        () {
      const matrix = {
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
  testWidgets('anchor', (tester) async {});

  // ── C3 — CONTENT containment, widget level, per textScale ────


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


  // ── C5 — the debug clip diagnostic ships SILENT ───────────────


  // ── R — the ream ──────────────────────────────────────────────







  // ── Z6 — physics zero-diff (scope lock, substring form) ─────

}
