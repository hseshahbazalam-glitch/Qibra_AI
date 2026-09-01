import 'package:flutter_test/flutter_test.dart';
import 'package:qibra_ai/core/hijri/hijri_civil.dart';
import 'package:qibra_ai/core/location/location_engine.dart';
import 'package:qibra_ai/core/location/location_resolver.dart';
import 'package:qibra_ai/features/prayer/data/services/next_prayer_engine.dart';
import 'package:qibra_ai/features/prayer/data/services/prayer_schedule_cache.dart';
import 'package:qibra_ai/features/prayer/data/services/prayer_source.dart';

void main() {
  test('location fix json roundtrip and unknown city', () {
    const fix = LocationFix(
      latitude: 10,
      longitude: 20,
      source: LocationFixSource.device,
      status: LocationFixStatus.granted,
      city: 'UNKNOWN',
    );
    expect(fix.hasNamedCity, isFalse);
    expect(LocationFix.fromJson(fix.toJson()).source, LocationFixSource.device);
  });

  test('permission mapping', () {
    expect(
      LocationEngine.fromPermission(serviceEnabled: false, permission: 'granted'),
      LocationFixStatus.serviceDisabled,
    );
    expect(
      LocationEngine.fromPermission(serviceEnabled: true, permission: 'deniedForever'),
      LocationFixStatus.deniedForever,
    );
    expect(
      LocationEngine.fromPermission(
        serviceEnabled: true,
        permission: 'granted',
        timedOut: true,
      ),
      LocationFixStatus.timeout,
    );
  });

  test('gps does not invent a city far from catalog', () {
    final resolved = LocationResolver.fromCoordinates(1.0, 1.0);
    expect(resolved.city, 'UNKNOWN');
  });

  test('cache key changes with location date timezone settings provider', () {
    final a = PrayerScheduleCache.keyFor(
      latitude: 24.8607,
      longitude: 67.0011,
      date: DateTime(2026, 8, 28),
      timezone: 'Asia/Karachi',
      method: 'MWL',
      asr: 'standard',
      provider: 'local',
    );
    final b = PrayerScheduleCache.keyFor(
      latitude: 24.8607,
      longitude: 67.0011,
      date: DateTime(2026, 8, 29),
      timezone: 'Asia/Karachi',
      method: 'MWL',
      asr: 'standard',
      provider: 'local',
    );
    expect(a == b, isFalse);
  });

  test('aladhan parser rejects invalid payload', () {
    const parser = AladhanParser();
    expect(parser.parseTimings({'data': 'x'}), isEmpty);
    expect(parser.isLiveNetwork, isFalse);
    final parsed = parser.parseTimings({
      'data': {
        'timings': {'Fajr': '05:01 (PKT)', 'Dhuhr': '12:10'}
      }
    });
    expect(parsed['Fajr'], '05:01');
  });

  test('current prayer skips sunrise; after isha next is tomorrow fajr', () {
    final today = [
      NamedPrayerInstant(name: 'Fajr', time: DateTime(2026, 8, 28, 5)),
      NamedPrayerInstant(name: 'Sunrise', time: DateTime(2026, 8, 28, 6, 20)),
      NamedPrayerInstant(name: 'Isha', time: DateTime(2026, 8, 28, 20)),
    ];
    final current = NextPrayerEngine.current(
      now: DateTime(2026, 8, 28, 6, 30),
      today: today,
    );
    expect(current?.name, 'Fajr');
    final next = NextPrayerEngine.next(
      now: DateTime(2026, 8, 28, 23),
      today: today,
      tomorrowFajr: NamedPrayerInstant(
        name: 'Fajr',
        time: DateTime(2026, 8, 29, 5, 1),
      ),
    );
    expect(next?.isTomorrow, isTrue);
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
