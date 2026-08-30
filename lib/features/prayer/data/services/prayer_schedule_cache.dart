import 'dart:convert';

import '../../../../core/cache/cache_store.dart';

class PrayerScheduleCache {
  PrayerScheduleCache._();
  static final PrayerScheduleCache instance = PrayerScheduleCache._();

  static const ttl = Duration(hours: 24);

  static String keyFor({
    required double latitude,
    required double longitude,
    required DateTime date,
    required String timezone,
    required String method,
    required String asr,
    required String provider,
  }) {
    final day =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final lat = latitude.toStringAsFixed(4);
    final lng = longitude.toStringAsFixed(4);
    return 'prayer|$lat|$lng|$day|$timezone|$method|$asr|$provider';
  }

  Future<void> save({
    required String cacheKey,
    required Map<String, String> times,
  }) {
    return CacheStore.instance.write(
      cacheKey,
      jsonEncode({'times': times, 'key': cacheKey}),
      ttl: ttl,
    );
  }

  Future<Map<String, String>?> load(String cacheKey) async {
    final entry = await CacheStore.instance.read(cacheKey);
    if (entry == null) return null;
    try {
      final map = jsonDecode(entry.value) as Map<String, dynamic>;
      if (map['key'] != cacheKey) return null;
      final times = map['times'];
      if (times is! Map) return null;
      return times.map((k, v) => MapEntry(k.toString(), v.toString()));
    } catch (_) {
      return null;
    }
  }
}
