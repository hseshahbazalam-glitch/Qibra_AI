import 'package:flutter_test/flutter_test.dart';
import 'package:qibra_ai/core/hijri/hijri.dart';
import 'package:qibra_ai/core/location/location_resolver.dart';

void main() {
  test('gps does not invent a city far from catalog', () {
    final resolved = LocationResolver.fromCoordinates(1.0, 1.0);
    expect(resolved.city, 'UNKNOWN');
  });

  test('hijri civil is not moon-sighting', () {
    expect(HijriCivil.authoritativeMoonSighting, isFalse);
    final date = HijriCivil.civilDate(
      utc: DateTime.utc(2026, 8, 30, 22),
      offset: const Duration(hours: 5, minutes: 30),
    );
    expect(date.day, 31);
  });
}
