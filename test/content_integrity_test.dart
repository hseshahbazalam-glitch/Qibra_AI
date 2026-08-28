
import 'package:flutter_test/flutter_test.dart';
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
}
