
import 'package:flutter_test/flutter_test.dart';
import 'package:qibra_ai/core/content/edition_resolver.dart';

void main() {
  test('edition resolver honest miss for Hindi', () {
    expect(EditionResolver.isBundled('en'), isTrue);
    expect(EditionResolver.isBundled('hi'), isFalse);
    expect(EditionResolver.miss('hi')!.reason.contains('not bundled'), isTrue);
  });

}
