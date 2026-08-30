import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qibra_ai/core/content/edition_resolver.dart';
import 'package:qibra_ai/core/l10n/app_locales.dart';
import 'package:qibra_ai/core/l10n/app_strings.dart';
import 'package:qibra_ai/features/hadith/data/models/hadith_models.dart';
import 'package:qibra_ai/features/hadith/providers/hadith_provider.dart';

void main() {
  test('Hindi Quran edition is an honest miss', () {
    final miss = EditionResolver.miss('hi');
    expect(miss, isNotNull);
    expect(miss!.reason.toLowerCase().contains('not bundled'), isTrue);
    expect(EditionResolver.isBundled('en'), isTrue);
    expect(EditionResolver.isBundled('ur'), isTrue);
  });

  test('app locale RTL is independent of content catalogs', () {
    expect(AppLocales.isRtl(AppLocales.ar), isTrue);
    expect(AppLocales.isRtl(AppLocales.ur), isTrue);
    expect(AppLocales.isRtl(AppLocales.en), isFalse);
    expect(AppLocales.resolve(const Locale('hi')).languageCode, 'en');
  });

  test('hand-written AppStrings cover ar/ur without gen-l10n', () {
    expect(AppStrings.forCode('ar').settings, isNotEmpty);
    expect(AppStrings.forCode('ur').language, isNotEmpty);
    expect(AppStrings.forCode('en').tafsirUnavailable.contains('not bundled'),
        isTrue);
  });

  test('hadith language helper does not invent Hindi', () {
    const hadith = HadithModel(
      id: 't1',
      hadithNumber: 1,
      bookSlug: 'bukhari',
      bookName: 'Sahih al-Bukhari',
      chapterNumber: 1,
      chapterName: 'x',
      textArabic: 'arabic',
      textEnglish: 'english',
      textUrdu: 'urdu',
      grade: HadithGrade.sahih,
      narrator: HadithNarrator(name: ''),
      reference: 'Bukhari 1',
    );
    expect(hadithTextForLanguage(hadith, 'en'), 'english');
    expect(hadithTextForLanguage(hadith, 'ur'), 'urdu');
    expect(hadithTextForLanguage(hadith, 'ar'), 'arabic');
    expect(hadithTextForLanguage(hadith, 'hi'), isNull);
  });
}
