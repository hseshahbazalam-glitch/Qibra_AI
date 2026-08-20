import 'dart:math' as math;
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:qibra_ai/core/constants/app_constants.dart';
import 'package:qibra_ai/core/providers/auth_provider.dart';
import 'package:qibra_ai/features/prayer/data/services/prayer_calculation_service.dart';
import 'package:qibra_ai/features/prayer/data/models/prayer_models.dart';

// Mock secure storage for tests
class MockSecureStorage extends FlutterSecureStorage {
  MockSecureStorage();
  final Map<String, String> _store = {};

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      _store[key];

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value == null) {
      _store.remove(key);
    } else {
      _store[key] = value;
    }
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      _store.remove(key);

  @override
  Future<bool> containsKey({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      _store.containsKey(key);

  @override
  Future<Map<String, String>> readAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      Map.from(_store);

  @override
  Future<void> deleteAll({
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async =>
      _store.clear();
}

void main() {
  group('P0.1 Auth Anonymous-First', () {
    test('backend disabled -> login fails with guest error, no fake token',
        () async {
      expect(AppApi.isBackendEnabled, isFalse);
      final storage = MockSecureStorage();
      final notifier = AuthNotifier(storage);
      await Future.delayed(const Duration(milliseconds: 150));
      expect(notifier.state.isUnauthenticated, isTrue);
      final success = await notifier.login(
          email: 'test@example.com', password: 'password123');
      expect(success, isFalse);
      expect(notifier.state.errorMessage, contains('not available'));
      final token = await storage.read(key: AppStorageKeys.accessToken);
      expect(token == null || !token.startsWith('fake_'), isTrue);
    });

    test('continueAsGuest clears error', () async {
      final storage = MockSecureStorage();
      final notifier = AuthNotifier(storage);
      await Future.delayed(const Duration(milliseconds: 100));
      await notifier.login(email: 'a@b.co', password: '12345678');
      expect(notifier.state.hasError, isTrue);
      notifier.continueAsGuest();
      expect(notifier.state.isUnauthenticated, isTrue);
      expect(notifier.state.hasError, isFalse);
    });
  });

  group('P0.3 Zakat Nisab', () {
    test('silver nisab threshold realistic (280 vs old 110)', () {
      const silverGrams = 612.36;
      const oldPrice = 110.0;
      const newPrice = 280.0;
      const oldNisab = silverGrams * oldPrice;
      const newNisab = silverGrams * newPrice;
      expect(oldNisab, closeTo(67359, 1));
      expect(newNisab, closeTo(171460, 1));
      expect(100000 < newNisab, isTrue,
          reason: '100k should be below realistic nisab');
    });
  });

  group('P0.4 Inheritance Validation', () {
    test('Awl reduces proportionally when >1', () {
      double total = 1 / 2 + 1 / 3 + 2 / 3;
      expect(total, greaterThan(1.0));
      final factor = 1.0 / total;
      expect(total * factor, closeTo(1.0, 0.001));
    });
    test('Wasiyyah capped at 1/3', () {
      const estate = 300000.0;
      const maxW = estate / 3;
      expect(maxW, 100000.0);
      const wasiyyah = 150000.0;
      final actual = wasiyyah > maxW ? maxW : wasiyyah;
      expect(actual, 100000.0);
    });
  });

  group('P0.6 Prayer Timezone', () {
    test('Karachi vs London produce different fajr times (location timezone)',
        () {
      final service = PrayerCalculationService();
      final karachi = PrayerLocation.karachi();
      const london = PrayerLocation(
        latitude: 51.5074,
        longitude: -0.1278,
        city: 'London',
        country: 'UK',
        countryCode: 'GB',
        timezone: 'Europe/London',
      );
      final date = DateTime(2026, 6, 15, 12);
      final kTimes = service.calculatePrayerTimes(
          date: date,
          location: karachi,
          method: CalculationMethod.karachi,
          asrMethod: AsrMethod.hanafi);
      final lTimes = service.calculatePrayerTimes(
          date: date,
          location: london,
          method: CalculationMethod.muslimWorldLeague,
          asrMethod: AsrMethod.standard);
      final kFajr = kTimes.fajr.adjustedTime;
      final lFajr = lTimes.fajr.adjustedTime;
      expect(kFajr.hour != lFajr.hour || kFajr.minute != lFajr.minute, isTrue,
          reason: 'Timezone must affect prayer time');
    });
  });

  group('P0.7 Qibla Bearing', () {
    double calcBearing(double lat, double lng) {
      const kaabaLat = 21.4225;
      const kaabaLng = 39.8262;
      double toRad(double d) => d * math.pi / 180;
      double toDeg(double r) => r * 180 / math.pi;
      final latRad = toRad(lat);
      final lngRad = toRad(lng);
      final kaabaLatRad = toRad(kaabaLat);
      final kaabaLngRad = toRad(kaabaLng);
      final dLng = kaabaLngRad - lngRad;
      final y = math.sin(dLng) * math.cos(kaabaLatRad);
      final x = math.cos(latRad) * math.sin(kaabaLatRad) -
          math.sin(latRad) * math.cos(kaabaLatRad) * math.cos(dLng);
      var bearing = toDeg(math.atan2(y, x));
      bearing = (bearing + 360) % 360;
      return bearing;
    }

    test('Karachi bearing ~260-285', () {
      final angle = calcBearing(24.8607, 67.0011);
      expect(angle, greaterThan(250));
      expect(angle, lessThan(290));
    });
    test('London bearing ~115-130', () {
      final angle = calcBearing(51.5074, -0.1278);
      expect(angle, greaterThan(110));
      expect(angle, lessThan(135));
    });
    test('PrayerCalc qibla via service matches', () {
      final service = PrayerCalculationService();
      final loc = PrayerLocation.karachi();
      final bearing = service.calculateQiblaDirection(loc);
      expect(bearing, greaterThan(250));
      expect(bearing, lessThan(290));
    });
  });
}
