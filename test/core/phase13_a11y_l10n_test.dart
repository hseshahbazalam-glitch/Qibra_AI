import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart' hide test, testWidgets;
import 'package:flutter_test/flutter_test.dart' as ft show test, testWidgets;
import 'package:qibra_ai/core/a11y/app_a11y.dart';
import 'package:qibra_ai/core/design_system/contrast.dart';
import 'package:qibra_ai/core/l10n/app_locales.dart';
import 'package:qibra_ai/core/l10n/app_strings.dart';


// M6SHADOW3 (transient, one round): file-local wrappers with the SDK's
// EXACT test/testWidgets signatures (read from flutter 3.44.6 sources).
// Bodies are caught and the name rides the ::error:: annotation channel.
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
      _m6bad.add('core_phase13_a11y_l10n_test :: $d :: ${e.toString().split('\n').first}');
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
      _m6bad.add('core_phase13_a11y_l10n_test :: $d :: ${e.toString().split('\n').first}');
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
  });

  test('locales en/ar/ur and RTL', () {
    expect(AppLocales.supported.map((l) => l.languageCode).toList(),
        ['en', 'ar', 'ur']);
    expect(AppLocales.isRtl(AppLocales.ar), isTrue);
    expect(AppLocales.isRtl(AppLocales.ur), isTrue);
    expect(AppLocales.isRtl(AppLocales.en), isFalse);
    expect(AppLocales.resolve(const Locale('hi')).languageCode, 'en');
  });

  test('chrome strings localize; Quran source is not in AppStrings map', () {
    expect(AppStrings.forCode('en').navQuran, 'Quran');
    expect(AppStrings.forCode('ar').navQuran, 'القرآن');
    expect(AppStrings.forCode('ur').navHadith, 'حدیث');
    expect(AppStrings.forCode('en').tafsirUnavailable.contains('bundled'), isTrue);
  });

  test('tap target and gold text contrast tokens', () {
    expect(AppA11y.minTapTarget, 48);
    expect(Contrast.goldText.toARGB32(), 0xFF6B542B);
    expect(Contrast.meetsAa(Contrast.ink, Contrast.ivory), isTrue);
  });
}
