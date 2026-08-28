import 'dart:convert';

import '../../../../core/cache/cache_store.dart';

class PrayerScheduleCache {
  PrayerScheduleCache._();
  static final PrayerScheduleCache instance = PrayerScheduleCache._();

  static const _key = 'prayer_schedule_v1';

  Future<void> save({
    required DateTime date,
    required Map<String, String> times,
    required String locationLabel,
  }) {
    return CacheStore.instance.write(
      _key,
      jsonEncode({
        'date': DateTime(date.year, date.month, date.day).toIso8601String(),
        'times': times,
        'location': locationLabel,
      }),
      ttl: const Duration(hours: 24),
    );
  }

  Future<Map<String, dynamic>?> loadFor(DateTime date) async {
    final entry = await CacheStore.instance.read(_key);
    if (entry == null) return null;
    try {
      final map = jsonDecode(entry.value) as Map<String, dynamic>;
      final stored = DateTime.tryParse(map['date'] as String? ?? '');
      if (stored == null) return null;
      if (stored.year != date.year ||
          stored.month != date.month ||
          stored.day != date.day) {
        return null;
      }
      return map;
    } catch (_) {
      return null;
    }
  }
}
