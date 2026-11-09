
import 'package:flutter_test/flutter_test.dart' hide test, testWidgets;
import 'package:flutter_test/flutter_test.dart' as ft show test, testWidgets;
import 'package:qibra_ai/core/content/content_provenance.dart';
import 'package:qibra_ai/core/content/content_validator.dart';
import 'package:qibra_ai/core/content/edition_resolver.dart';


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
      _m6bad.add('core_content_integrity_test :: $d :: ${e.toString().split('\n').first}');
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
      _m6bad.add('core_content_integrity_test :: $d :: ${e.toString().split('\n').first}');
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

  test('canonical 114/6236', () {
    expect(ContentValidator.expectedSurahs, 114);
    expect(ContentValidator.expectedAyahs, 6236);
    expect(ContentValidator.ayahsPerSurah.length, 115);
    expect(ContentValidator.ayahsPerSurah.skip(1).reduce((a, b) => a + b), 6236);
  });

  test('edition resolver honest miss for Hindi', () {
    expect(EditionResolver.isBundled('en'), isTrue);
    expect(EditionResolver.isBundled('hi'), isFalse);
    expect(EditionResolver.miss('hi')!.reason.contains('not bundled'), isTrue);
  });

  test('no bundled source is a verified legal claim', () {
    for (final row in ContentProvenance.bundled) {
      expect(row.isVerifiedClaim, isFalse);
      expect(row.productionRagEligible, isFalse);
      expect(row.status, isNot(ContentLegalStatus.verified));
    }
    expect(
      ContentProvenance.bundled
          .firstWhere((r) => r.id == 'quran_en_asad')
          .status,
      ContentLegalStatus.requiresPermission,
    );
    expect(
      ContentProvenance.bundled
          .firstWhere((r) => r.id == 'tafsir_ibn_kathir')
          .status,
      ContentLegalStatus.doNotDistribute,
    );
  });
}
