import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart' hide test, testWidgets;
import 'package:flutter_test/flutter_test.dart' as ft show test, testWidgets;
import 'package:qibra_ai/core/content/edition_resolver.dart';
import 'package:qibra_ai/core/l10n/app_locales.dart';
import 'package:qibra_ai/core/l10n/app_strings.dart';
import 'package:qibra_ai/features/hadith/data/models/hadith_models.dart';
import 'package:qibra_ai/features/hadith/providers/hadith_provider.dart';


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
      _m6bad.add('core_phase_continue_wiring_test :: $d :: ${e.toString().split('\n').first}');
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
      _m6bad.add('core_phase_continue_wiring_test :: $d :: ${e.toString().split('\n').first}');
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
      narrator: const HadithNarrator(name: ''),
      reference: 'Bukhari 1',
    );
    expect(hadithTextForLanguage(hadith, 'en'), 'english');
    expect(hadithTextForLanguage(hadith, 'ur'), 'urdu');
    expect(hadithTextForLanguage(hadith, 'ar'), 'arabic');
    expect(hadithTextForLanguage(hadith, 'hi'), isNull);
  });
}
