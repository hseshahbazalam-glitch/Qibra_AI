
import 'package:flutter_test/flutter_test.dart';
import 'package:qibra_ai/core/content/content_provenance.dart';
import 'package:qibra_ai/core/content/content_validator.dart';
import 'package:qibra_ai/core/content/edition_resolver.dart';

void main() {
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
