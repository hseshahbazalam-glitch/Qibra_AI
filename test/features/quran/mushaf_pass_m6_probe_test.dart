// test/features/quran/mushaf_pass_m6_probe_test.dart
// ============================================================
// PASS M6 — PART B PROBE ROUND (transient by design).
//
// The device report: 'neeche se cut ho rha h' + 'goto (page-jump)
// wajh se', post-M5 on the CPH2573. Three suspects were named by
// the brief (B1 IME-resize, B2 jump-render, B3 chrome-overlap);
// this round runs containment-level probes against the BASE lib so
// the annotations name the real culprit with numbers — red-on-base
// is the evidence, the fix commit comes after. Folded into
// mushaf_pass_m6_test.dart and deleted at the pass close (ledger).
// ============================================================

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // FontLoader + ByteData (M-suite pattern)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart' hide test, testWidgets;
import 'package:flutter_test/flutter_test.dart' as ft show test, testWidgets;
import 'package:qibra_ai/core/l10n/app_strings.dart';
import 'package:qibra_ai/features/quran/data/models/quran_models.dart';
import 'package:qibra_ai/features/quran/presentation/mushaf_reader_screen.dart';
import 'package:qibra_ai/features/quran/providers/quran_download_provider.dart';

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

class _NoopDownloads extends QuranDownloadController {
  @override
  Map<int, SurahAudioStatus> build() => const {};

  @override
  Future<void> checkSurah(int surah) async {}
}

const _p1a1 = AyahModel(
  number: 1,
  numberInQuran: 1,
  text: 'بِسْمِ اللّٰهِ الرَّحْمٰنِ الرَّحِيمِ',
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
  text: 'اللّٰهُ لَآ اِلٰهَ اِلَّا هُوَ الْحَيُّ الْقَيُّومُ',
  juz: 3,
  page: 2,
  sajdah: true, // B3: the footer variant rides the same bottom edge
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

Future<void> pumpReaderM6(
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
      mushafPageIndexProvider.overrideWith((ref) async => Map.of(_index)),
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

/// Bottom edges of every rendered text line, in GLOBAL space (the
/// pageView's slot rect is global too — no matrix math, no
/// Rect.transform version trap — that was the analyze red: modern
/// Flutter's Rect.transform wants Matrix4, and .storage stopped
/// being acceptable).
double _deepestTextBottom(WidgetTester tester) {
  final texts = find.byType(RichText);
  final count = texts.evaluate().length;
  double maxB = 0;
  for (var i = 0; i < count; i++) {
    final b = tester.getRect(texts.at(i)).bottom;
    if (b > maxB) maxB = b;
  }
  return maxB;
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
      _m6bad.add('mushaf_pass_m6_probe :: $d :: ${e.toString().split('\n').first}');
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
      _m6bad.add('mushaf_pass_m6_probe :: $d :: ${e.toString().split('\n').first}');
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
    print('::error::M6BADEND mushaf_pass_m6_probe_test.dart ${_m6bad.length}');
  });

  setUpAll(loadAppTestFonts);

  // ── B1 — IME resize must NOT reach the page slot ───────────────
  testWidgets('B1: the reader page slot is IME-invariant',
      (tester) async {
    await pumpReaderM6(tester);
    final slot = tester.getSize(find.byType(PageView));
    // A 336dp keyboard on the CPH2573 (1080x2400 @ 2.8125, IME
    // ~35% of the panel) — the exact storm the device log named.
    tester.view.viewInsets =
        FakeViewPadding(top: 0, left: 0, right: 0, bottom: 336);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final during = tester.getSize(find.byType(PageView));
    tester.view.resetViewInsets();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final after = tester.getSize(find.byType(PageView));
    debugPrint('::error::B1MEASURE before=$slot during=$during '
        'after=$after');
    expect(
      during,
      slot,
      reason: 'B1 CONFIRMED: the goto keyboard resized the reader '
          'body ${slot.height} -> ${during.height} — the page (and '
          'anything latched to it) relayouts mid-jump; the fix is '
          'resizeToAvoidBottomInset:false on the reader Scaffold '
          '(the AlertDialog lifts itself over viewInsets — Dialog '
          'handles that internally).',
    );
    expect(after, slot,
        reason: 'after the keyboard closed the slot did not return '
            'to the mounted size — a PERSISTENT bottom cut');
  });

  // ── B3 — chrome height vs the page's bottom reserve ───────────
  testWidgets('B3: the settled bottom chrome fits the 148px page '
      'reserve', (tester) async {
    await pumpReaderM6(tester);
    // The bottom bar is the SECOND AnimatedPositioned in the Stack
    // (top bar first); its box spans the whole chrome block.
    final bar = find.byType(AnimatedPositioned).at(1);
    final barRect = tester.getRect(bar);
    final barH = barRect.height;
    debugPrint('::error::B3MEASURE barH=$barH '
        'reserve=$kMushafChromeBottomReserve');
    expect(barH,
        lessThanOrEqualTo(kMushafChromeBottomReserve - 8.0),
        reason: 'the bottom chrome is ${barH}px tall but the page '
            'reserve is $kMushafChromeBottomReserve — under 8px of '
            'air is a cut waiting for the next textScale step '
            '(#289 base-red evidence: 175 vs 148)');
  });

  // ── B2 — first-frame containment right after the goto jump ────
  testWidgets('B2: the jumped-to page contains its text on the '
      'FIRST frame after GO', (tester) async {
    await pumpReaderM6(tester);
    await tester.tap(find.text('1 / 604'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '2');
    await tester.pump();
    await tester.tap(find.byType(FilledButton));
    await tester.pump(); // exactly the first post-jump frame
    final slotRect = tester.getRect(find.byType(PageView));
    final maxB = _deepestTextBottom(tester);
    debugPrint('::error::B2MEASURE slotBottom=${slotRect.bottom} '
        'deepestText=$maxB');
    expect(maxB, greaterThan(0.0), reason: 'probe wiring: page text '
        'must be live for this measurement');
    expect(maxB, lessThanOrEqualTo(slotRect.bottom + 0.5),
        reason: 'B2 CONFIRMED: ${maxB - slotRect.bottom}px of text '
            'past the page slot on the first frame after the jump '
            '(cache-miss render at the wrong size)');
    expect(find.text('2 / 604'), findsWidgets,
        reason: 'sanity: the jump landed on page 2');
    await tester.pumpAndSettle();
  });
}
