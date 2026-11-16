import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qibra_ai/core/a11y/app_a11y.dart';
import 'package:qibra_ai/core/design_system/contrast.dart';
import 'package:qibra_ai/core/l10n/app_locales.dart';
import 'package:qibra_ai/core/l10n/app_strings.dart';

void main() {
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
