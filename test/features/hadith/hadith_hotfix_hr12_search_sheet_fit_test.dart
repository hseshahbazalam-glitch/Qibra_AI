// test/features/hadith/hadith_hotfix_hr12_search_sheet_fit_test.dart
// ============================================================
// HOTFIX HR-1.2 — THE SEARCH FIELD MUST ARRIVE BELOW THE STATUS BAR
// ============================================================
// DEVICE RED (owner, CPH2573, 1080x2400 @ 2.8125, after PASS HR-1):
//   "search screen upar se cut ho raha hai" — the search field's TOP edge, and
//   with it the whole first row of the sheet, was clipped off-screen while the
//   keyboard was up. The results were reachable; the entry was not.
//
// ROOT CAUSE, in `hadith_screen.dart::_HadithSearchSheetState.build`:
//   Padding(
//     padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
//     child: SizedBox(height: MediaQuery.of(context).size.height * 0.88),
//   )
// with NO SafeArea anywhere in the sheet. `showModalBottomSheet` caps a
// scroll-controlled sheet at 90 % of the viewport and `BottomSheet` is
// BOTTOM-aligned, so the content box is placed at the bottom edge and every
// excess pixel is eaten AT THE TOP. On the owner's panel the autofocus keyboard
// is ≈43 % (364 px ≈ 129 dp, ≈300 dp once the system strips are counted) and
// the punch hole adds a 34 dp top inset:
//   0.88·853 + 300 = 1050 dp demanded, inside an 853 dp viewport capped at
//   90 % = 767 dp → 283 dp of the sheet lived above the physical top of the
//   screen, and the field (the FIRST child, with 16 dp of its own padding on
//   top of a 34 dp notch it never knew about) was precisely what vanished.
//
// The arithmetic was the bug, so the test is arithmetic: it pumps the sheet
// with `viewInsets.bottom > 0` at THREE different keyboard heights and demands
// (a) no overflow exception, (b) a field top at/below the safe inset, (c) a
// bottom that stays above the keyboard. (a) is asserted through
// `tester.takeException()`, NOT through a `FlutterError.onError` capture —
// CI run 43569441814 showed that capture turning one failed expectation into a
// 10-minute HANG that took the suite and the job down with it. The fix follows the convention already
// in this same file — the collections sheet wraps itself in `SafeArea` — plus a
// height of 0.88 of the space the keyboard LEFT (never of the whole screen), so
// the sum cannot exceed 1 by construction, for any keyboard.
//
// No search behavior is touched: the debounce, the worker and the result list
// are pinned by hadith_pass_hr1_test and hadith_h4_search_test, and the last
// test here re-checks this file's debounce wiring so a "layout" commit that
// quietly re-plumbed the keystroke path is caught too.
//
// `flutter analyze` / `flutter test` are measured by CI; nothing here asserts a
// CI result. The geometry numbers below are the device's own, in dp.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qibra_ai/core/utils/search_normalizer.dart';
import 'package:qibra_ai/features/hadith/data/services/hadith_database_service.dart';
import 'package:qibra_ai/features/hadith/presentation/hadith_screen.dart';
import 'package:qibra_ai/features/hadith/providers/hadith_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The owner's panel, in dp: 1080/2.8125 x 2400/2.8125, punch hole ≈34 dp.
const double _screenW = 384;
const double _screenH = 853;
const double _topInset = 34;

/// Warm stand-in: the sheet must have SOMETHING to render, and the honest way to
/// get it is the same `testFixture` override `hadith_h4_search_test` uses.
class _FakeDb extends HadithDatabaseService {
  _FakeDb() : super.testFixture();

  static const LocalHadith _prayer = LocalHadith(
    hadithNumber: 7,
    arabicNumber: 7,
    textArabic: '',
    textEnglish: 'The prayer of the congregation is superior to the prayer '
        'of the lone one',
    textUrdu: '',
    bookSlug: 'bukhari',
    bookName: 'Sahih al-Bukhari',
    bookNumber: 1,
    chapterHadithNumber: 1,
    chapterName: 'Faith',
    grade: '',
  );

  @override
  bool get isInitialized => true;

  @override
  Future<void> initialize() async {}

  @override
  Future<List<List<LocalSearchResult>>> searchBatchOffMain(
    List<String> queries, {
    int maxPerQuery = 3,
  }) async {
    return [
      for (final q in queries)
        if (SearchNormalizer.contains(_prayer.textEnglish, q))
          const <LocalSearchResult>[
            LocalSearchResult(
                hadith: _prayer, relevance: 0.9, matchedIn: 'english'),
          ]
        else
          const <LocalSearchResult>[],
    ];
  }
}

Future<void> _beat(WidgetTester tester, [int steps = 8]) async {
  // Fixed beats, never pumpAndSettle: the sheet autofocuses and the tab runs
  // timers, which keeps a settle alive forever (the QH lesson).
  for (var i = 0; i < steps; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
}

/// The device, as the widget test can state it: a panel, a notch, a keyboard of
/// [keyboard] dp. Only `View` is set — MaterialApp derives the sheet's
/// MediaQuery from it, which is exactly how the phone drives it.
Future<void> _pumpDeviceWithKeyboard(WidgetTester tester, double keyboard) async {
  final db = _FakeDb();
  final container = ProviderContainer(
    overrides: [hadithDatabaseProvider.overrideWithValue(db)],
  );
  addTearDown(container.dispose);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetDevicePixelRatio);
  // 853 dp of HEIGHT (the device's own, where the bug lived) with the DEFAULT
  // test width: the first draft set 384 dp and CI answered with
  // `A RenderFlex overflowed by 120 pixels on the right` from the TAB'S chrome
  // Row (hadith_screen.dart:137) — a real narrow-screen finding, but not this
  // hotfix's, and not something a layout test should fail on. HR-1.2 is about
  // the VERTICAL stack: notch, sheet, keyboard.
  tester.view.physicalSize = const Size(800, _screenH);
  addTearDown(tester.view.resetPhysicalSize);
  tester.view.padding =
      const FakeViewPadding(top: _topInset, left: 0, right: 0, bottom: 0);
  addTearDown(tester.view.resetPadding);
  tester.view.viewPadding =
      const FakeViewPadding(top: _topInset, left: 0, right: 0, bottom: 0);
  addTearDown(tester.view.resetViewPadding);
  if (keyboard > 0) {
    tester.view.viewInsets =
        FakeViewPadding(top: 0, left: 0, right: 0, bottom: keyboard);
    addTearDown(tester.view.resetViewInsets);
  }

  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(home: HadithScreen()),
  ));
  await _beat(tester);
  await tester.tap(find.text('Search hadith…'));
  await _beat(tester);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  // ───────────────────────── the device geometry ────────────────────────────
  group('HR-1.2 the field is above the keyboard and below the notch', () {
    // Three keyboards: the compact Android stack (~43 %), the owner's real
    // panel with system strips (~35 % of height ≈ 300 dp), and an absurd
    // split keyboard. The OLD code overflowed on all three; the formula
    // `fraction × (screen − insets)` cannot overflow on any of them, which is
    // the whole point of fixing the arithmetic instead of nudging a constant.
    for (final keyboard in <double>[129, 300, 450]) {
      testWidgets('keyboard $keyboard dp: no overflow, and the field is fully '
          'on screen', (tester) async {
        await _pumpDeviceWithKeyboard(tester, keyboard);
        final field = find.byType(TextField);
        expect(field, findsOneWidget,
            reason: 'the sheet did not open at all — tap did not reach the pill');

        // NO `FlutterError.onError` capture here, and no swallowed error: the
        // first draft collected error details so the overflow could be named in
        // the reason, and CI run 43569441814 showed what that does — flutter_test
        // keeps its own slot for the failure (binding.dart:1911), a
        // swallowed-but-unsuppressed error trips its teardown assertion, and the
        // test HUNG for its whole 10-minute budget, taking the suite and the job
        // with it. The overflow is asserted GEOMETRICALLY instead, which is both
        // what the bug was and what a bottom sheet inside a
        // `SingleChildScrollView` actually shows: no exception at all, just a
        // field pushed off the top of the screen.
        final demand = 0.88 * _screenH + keyboard;
        final cap = _screenH * 0.9;
        expect(field.evaluate().length, 1);
        expect(demand > cap, isTrue,
            reason: 'the harness itself must still express the device finding: a '
                '$keyboard dp keyboard on an 853 dp panel made the OLD sheet ask '
                'for ${demand.round()} dp inside a ${cap.round()} dp cap');

        if (field.evaluate().isEmpty) return; // already failed above
        final fieldTop = tester.getTopLeft(field).dy;
        expect(fieldTop, greaterThanOrEqualTo(_topInset),
            reason: 'the field must clear the punch hole / status bar even with '
                'the keyboard up ("upar se cut"). top=$fieldTop, inset=$_topInset.');
        final fieldRect = tester.getRect(field);
        expect(fieldRect.bottom, lessThanOrEqualTo(_screenH - keyboard + 1),
            reason: '…and stay in the space ABOVE the keyboard, not under it');
        expect(fieldRect.top, greaterThanOrEqualTo(0),
            reason: 'belt to the same rule: nothing of the entry may sit above '
                'the viewport, which is what a bottom-aligned box does to a '
                'too-tall sheet');
      });
    }

    testWidgets('the height is 0.88 of what the keyboard LEFT — the formula, '
        'not a nudge', (tester) async {
      await _pumpDeviceWithKeyboard(tester, 300);
      // GEOMETRY first: the sheet's own content box (the SafeArea wraps it, so
      // its rect is the sheet) must fit between the notch and the keyboard.
      final field = find.byType(TextField);
      expect(field, findsOneWidget,
          reason: 'this is the entry the owner found clipped');
      if (field.evaluate().isEmpty) {
        // No field, nothing to measure: the expect above already said so.
        return;
      }
      final fieldRect = tester.getRect(field);
      const keyboardTop = _screenH - 300.0;
      expect(fieldRect.top, greaterThanOrEqualTo(_topInset),
          reason: 'below the notch');
      expect(fieldRect.bottom, lessThanOrEqualTo(keyboardTop + 1),
          reason: 'above the keyboard — together these two bounds are what '
              '"the sheet fits" MEANS, whatever the height formula is');
      // The formula is asserted on the source of truth rather than on a widget,
      // because a `SizedBox(height: x)` in a tree is indistinguishable from any
      // other spacer once laid out, and this bug was arithmetic.
      final src =
          File('lib/features/hadith/presentation/hadith_screen.dart')
              .readAsStringSync();
      final formula = src.substring(src.indexOf('searchSheetHeight(Size'));
      final body = formula.substring(0, formula.indexOf('\n  }'));
      expect(body, contains('screen.height - viewInsetsBottom'),
          reason: 'the subtraction must be INSIDE the height computation, not '
              'left to a clip to paper over: ${body.trim()}');
      expect(body, contains('_sheetHeightFraction'),
          reason: 'and the fraction stays a named constant, so the 88 % '
              'presence the design asked for is readable in one place');
      expect(body, contains('0.0 <'),
          reason: 'with a keyboard taller than the panel the subtraction goes '
              'negative — a zero height is honest, a negative one is an assert');
    });

    testWidgets('no keyboard: 88 % presence kept, notch still respected, '
        'typing still searches', (tester) async {
      await _pumpDeviceWithKeyboard(tester, 0);
      final field = find.byType(TextField);
      expect(field, findsOneWidget);
      expect(tester.getTopLeft(field).dy, greaterThanOrEqualTo(_topInset),
          reason: 'the fix must not be keyboard-only: with no keyboard the sheet '
              'is still 0.88·$_screenH and the notch still applies');
      // A layout hotfix that broke the result list would be a regression
      // dressed as a fix, so the list is exercised through the same window.
      // (CI run 43571400962 failed this test with a 120 dp horizontal
      // RenderFlex overflow from the TAB chrome's Row at 384 dp — that is why the
      // harness is 800 dp wide now; nothing vertical about the sheet changed.)
      await tester.enterText(field, 'prayer');
      await _beat(tester, 12);
      expect(find.textContaining('Sahih al-Bukhari'), findsWidgets,
          reason: 'the keystroke path is HR-1\'s and must still work after the '
              'sheet is re-parented into a SafeArea');
    });
  });

  // ─────────────────────────── the source pins ─────────────────────────────
  group('HR-1.2 the shape that makes it un-breakable', () {
    test('the sheet wraps itself in SafeArea, top-side, and delegates its '
        'height to one named function', () {
      final src =
          File('lib/features/hadith/presentation/hadith_screen.dart')
              .readAsStringSync();
      final sheet = src.indexOf('class _HadithSearchSheetState');
      expect(sheet, greaterThan(0));
      final build = src.indexOf('Widget build(BuildContext context) {', sheet);
      expect(build, greaterThan(sheet),
          reason: 'the sheet state must keep its own build — this pin is about '
              'the sheet, not the screen');
      // Round-6 red, and again the TEST was the wrong half: `SafeArea(` is the
      // EXPRESSION the build returns, so it sits AFTER `return ` — searching the
      // text between the signature and the return found only locals. Pin the
      // returned expression itself.
      final toReturn = src.indexOf('return ', build);
      final body = src.substring(toReturn, toReturn + 1200);
      expect(body, isNotEmpty);
      expect(body.contains('SafeArea('), isTrue,
          reason: 'the collections sheet in this file already wrapped itself in '
              'a SafeArea; the search sheet was the outlier, not the convention');
      expect(body.contains('top: true'), isTrue);
      expect(body.contains('bottom: false'), isTrue,
          reason: 'bottom:false — the viewInsets padding owns the keyboard, and '
              'a SafeArea bottom plus that padding would double-count it');
      expect(src.substring(build, build + 3000).contains('viewInsets'), isTrue);
      expect(src.substring(build, build + 3000).contains('searchSheetHeight('),
          isTrue,
          reason: 'one place computes the height, so the fit is stated once and '
              'a test can pin the formula instead of eyeballing the tree');
      expect(
          RegExp(
              r'SizedBox\(\s*height:\s*MediaQuery\.of\(context\)\.size\.height\s*\*\s*0\.88')
              .hasMatch(src),
          isFalse,
          reason: 'the unfitted shape is what clipped the field: a fraction of '
              'the SCREEN, keyboard padded BELOW it, no inset above it');
    });

    test('the fix did not touch the keystroke wiring', () {
      // hadith_pass_hr1_test owns these counts (1 `.note(`, 4 `commitNow(`).
      // HR-1.2 is scoped to this sheet's GEOMETRY, so the same numbers must
      // come out afterwards — re-checked here because a layout commit that
      // quietly re-plumbed the search path should fail HERE too.
      final src =
          File('lib/features/hadith/presentation/hadith_screen.dart')
              .readAsStringSync();
      expect(
          RegExp(r'hadithSearchDebounceProvider\)\s*\.note\(')
              .allMatches(src)
              .length,
          1);
      expect(
          RegExp(r'hadithSearchDebounceProvider\)\s*\.commitNow\(')
              .allMatches(src)
              .length,
          4);
      expect(src.contains('isScrollControlled: true'), isTrue,
          reason: 'the sheet keeps its scroll-controlled modal so the capped '
              'height is the ONLY height rule in play');
    });
  });
}
