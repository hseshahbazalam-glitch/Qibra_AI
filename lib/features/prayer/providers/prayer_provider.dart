// lib/features/prayer/providers/prayer_provider.dart

// ============================================================
// QIBRA AI — PRAYER PROVIDER (v1.2 — No Geocoding Dependency)
// ============================================================

import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/prayer_models.dart';
import '../data/services/prayer_calculation_service.dart';

// ============================================================
// SECTION 1 — SERVICE PROVIDER
// ============================================================

final prayerCalculationServiceProvider = Provider<PrayerCalculationService>(
  (ref) => PrayerCalculationService(),
);

// ============================================================
// SECTION 2 — SHARED PREFERENCES PROVIDER
// ============================================================

final sharedPreferencesProvider =
    FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

// ============================================================
// SECTION 3 — LOCATION STATE
// ============================================================

enum LocationStatus { initial, loading, success, denied, disabled, error }

class LocationState {
  const LocationState({
    this.status = LocationStatus.initial,
    this.location,
    this.error,
  });

  final LocationStatus status;
  final PrayerLocation? location;
  final String? error;

  bool get isLoading => status == LocationStatus.loading;
  bool get hasLocation => location != null;
  bool get hasError =>
      status == LocationStatus.error ||
      status == LocationStatus.denied ||
      status == LocationStatus.disabled;

  LocationState copyWith({
    LocationStatus? status,
    PrayerLocation? location,
    String? error,
    bool clearError = false,
  }) {
    return LocationState(
      status: status ?? this.status,
      location: location ?? this.location,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

// ============================================================
// SECTION 4 — LOCATION NOTIFIER
// ============================================================

class LocationNotifier extends StateNotifier<LocationState> {
  LocationNotifier(this._ref) : super(const LocationState()) {
    _loadCachedLocation();
  }

  // ignore: unused_field
  final Ref _ref;
  static const String _cacheKey = 'prayer_location_cache';

  Future<void> _loadCachedLocation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_cacheKey);
      if (cached != null) {
        final json = jsonDecode(cached) as Map<String, dynamic>;
        final location = PrayerLocation(
          latitude: (json['lat'] as num).toDouble(),
          longitude: (json['lng'] as num).toDouble(),
          city: json['city'] as String,
          country: json['country'] as String,
          countryCode: json['countryCode'] as String?,
          timezone: json['timezone'] as String?,
          isManuallySet: json['manual'] as bool? ?? false,
        );
        state = state.copyWith(
          status: LocationStatus.success,
          location: location,
        );
      }
    } catch (e) {
      debugPrint('[LOCATION] Cache load error: $e');
    }
  }

  Future<void> _cacheLocation(PrayerLocation location) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = jsonEncode({
        'lat': location.latitude,
        'lng': location.longitude,
        'city': location.city,
        'country': location.country,
        'countryCode': location.countryCode,
        'timezone': location.timezone,
        'manual': location.isManuallySet,
      });
      await prefs.setString(_cacheKey, json);
    } catch (e) {
      debugPrint('[LOCATION] Cache save error: $e');
    }
  }

  /// Fetch current location from GPS
  Future<void> fetchCurrentLocation() async {
    state = state.copyWith(
      status: LocationStatus.loading,
      clearError: true,
    );

    try {
      // Check if location service is enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(
          status: LocationStatus.disabled,
          error: 'Please turn on GPS/Location services',
        );
        return;
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          state = state.copyWith(
            status: LocationStatus.denied,
            error: 'Location permission denied',
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        state = state.copyWith(
          status: LocationStatus.denied,
          error:
              'Location permission permanently denied. Enable from settings.',
        );
        return;
      }

      // Get current position
      debugPrint('[LOCATION] Getting current position...');
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 20),
      );

      debugPrint(
        '[LOCATION] Position: ${position.latitude}, ${position.longitude}',
      );

      // Use coordinates as city name — geocoding removed
      // Will be improved in future with a free geocoding API
      const cityName = 'My Location';
      const countryName = 'Auto-detected';

      final location = PrayerLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        city: cityName,
        country: countryName,
        countryCode: null,
        isManuallySet: false,
      );

      state = state.copyWith(
        status: LocationStatus.success,
        location: location,
      );

      await _cacheLocation(location);
    } catch (e) {
      debugPrint('[LOCATION] Error: $e');
      state = state.copyWith(
        status: LocationStatus.error,
        error: 'Failed to get location. Check GPS and internet.',
      );
    }
  }

  /// Set location manually
  Future<void> setManualLocation(PrayerLocation location) async {
    final withFlag = location.copyWith(isManuallySet: true);
    state = state.copyWith(
      status: LocationStatus.success,
      location: withFlag,
    );
    await _cacheLocation(withFlag);
  }

  /// Reset to default (Makkah)
  Future<void> resetToDefault() async {
    final makkah = PrayerLocation.makkah();
    state = state.copyWith(
      status: LocationStatus.success,
      location: makkah,
    );
    await _cacheLocation(makkah);
  }
}

final locationProvider =
    StateNotifierProvider<LocationNotifier, LocationState>((ref) {
  return LocationNotifier(ref);
});

// ============================================================
// SECTION 5 — SETTINGS NOTIFIER
// ============================================================

class PrayerSettingsNotifier extends StateNotifier<PrayerSettings> {
  PrayerSettingsNotifier(this._ref) : super(const PrayerSettings()) {
    _loadSettings();
  }

  final Ref _ref;
  static const String _key = 'prayer_settings';

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_key);
      if (cached == null) return;

      final json = jsonDecode(cached) as Map<String, dynamic>;

      final adjustments = <PrayerType, int>{};
      final adjJson = json['adjustments'] as Map<String, dynamic>? ?? {};
      for (final entry in adjJson.entries) {
        try {
          final type = PrayerType.values.firstWhere((p) => p.name == entry.key);
          adjustments[type] = entry.value as int;
        } catch (_) {}
      }

      state = PrayerSettings(
        calculationMethod: CalculationMethod.values.firstWhere(
          (m) => m.name == json['method'],
          orElse: () => CalculationMethod.muslimWorldLeague,
        ),
        asrMethod: AsrMethod.values.firstWhere(
          (m) => m.name == json['asr'],
          orElse: () => AsrMethod.standard,
        ),
        highLatitudeMethod: HighLatitudeMethod.values.firstWhere(
          (m) => m.name == json['highLat'],
          orElse: () => HighLatitudeMethod.none,
        ),
        adjustments: adjustments,
        enableNotifications: json['notifications'] as bool? ?? true,
        enableAdhan: json['adhan'] as bool? ?? true,
        enablePreReminder: json['preReminder'] as bool? ?? true,
        preReminderMinutes: json['preMin'] as int? ?? 15,
        enableSilentMode: json['silentMode'] as bool? ?? false,
        silentModeDuration: json['silentDuration'] as int? ?? 10,
        adhanSound: json['adhanSound'] as String? ?? 'default',
        iqamahMinutes: json['iqamah'] as int? ?? 15,
        showSunrise: json['showSunrise'] as bool? ?? true,
        use24HourFormat: json['24hr'] as bool? ?? false,
      );
    } catch (e) {
      debugPrint('[SETTINGS] Load error: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final adjJson = <String, int>{};
      state.adjustments.forEach((type, minutes) {
        adjJson[type.name] = minutes;
      });

      final json = jsonEncode({
        'method': state.calculationMethod.name,
        'asr': state.asrMethod.name,
        'highLat': state.highLatitudeMethod.name,
        'adjustments': adjJson,
        'notifications': state.enableNotifications,
        'adhan': state.enableAdhan,
        'preReminder': state.enablePreReminder,
        'preMin': state.preReminderMinutes,
        'silentMode': state.enableSilentMode,
        'silentDuration': state.silentModeDuration,
        'adhanSound': state.adhanSound,
        'iqamah': state.iqamahMinutes,
        'showSunrise': state.showSunrise,
        '24hr': state.use24HourFormat,
      });

      await prefs.setString(_key, json);
    } catch (e) {
      debugPrint('[SETTINGS] Save error: $e');
    }
  }

  Future<void> updateSettings(PrayerSettings newSettings) async {
    state = newSettings;
    await _saveSettings();
  }

  Future<void> setCalculationMethod(CalculationMethod method) async {
    state = state.copyWith(calculationMethod: method);
    await _saveSettings();
  }

  Future<void> setAsrMethod(AsrMethod method) async {
    state = state.copyWith(asrMethod: method);
    await _saveSettings();
  }

  Future<void> setAdjustment(PrayerType type, int minutes) async {
    final adjustments = Map<PrayerType, int>.from(state.adjustments);
    if (minutes == 0) {
      adjustments.remove(type);
    } else {
      adjustments[type] = minutes;
    }
    state = state.copyWith(adjustments: adjustments);
    await _saveSettings();
  }

  Future<void> toggleNotifications(bool enabled) async {
    state = state.copyWith(enableNotifications: enabled);
    await _saveSettings();
  }

  Future<void> toggleAdhan(bool enabled) async {
    state = state.copyWith(enableAdhan: enabled);
    await _saveSettings();
  }

  Future<void> togglePreReminder(bool enabled) async {
    state = state.copyWith(enablePreReminder: enabled);
    await _saveSettings();
  }

  Future<void> setPreReminderMinutes(int minutes) async {
    state = state.copyWith(preReminderMinutes: minutes);
    await _saveSettings();
  }

  Future<void> toggleSilentMode(bool enabled) async {
    state = state.copyWith(enableSilentMode: enabled);
    await _saveSettings();
  }

  Future<void> set24HourFormat(bool enabled) async {
    state = state.copyWith(use24HourFormat: enabled);
    await _saveSettings();
  }

  Future<void> toggleSunrise(bool enabled) async {
    state = state.copyWith(showSunrise: enabled);
    await _saveSettings();
  }

  /// Auto-configure based on country
  Future<void> autoConfigureForCountry(String? countryCode) async {
    final service = _ref.read(prayerCalculationServiceProvider);
    final method = service.detectMethodByCountry(countryCode);
    final asr = service.detectAsrMethodByCountry(countryCode);

    state = state.copyWith(
      calculationMethod: method,
      asrMethod: asr,
    );
    await _saveSettings();
  }
}

final prayerSettingsProvider =
    StateNotifierProvider<PrayerSettingsNotifier, PrayerSettings>((ref) {
  return PrayerSettingsNotifier(ref);
});

// ============================================================
// SECTION 6 — DAILY PRAYER TIMES PROVIDER
// ============================================================

final dailyPrayerTimesProvider = Provider<DailyPrayerTimes?>((ref) {
  final locationState = ref.watch(locationProvider);
  final settings = ref.watch(prayerSettingsProvider);
  final service = ref.watch(prayerCalculationServiceProvider);

  if (locationState.location == null) return null;

  try {
    return service.calculatePrayerTimes(
      date: DateTime.now(),
      location: locationState.location!,
      method: settings.calculationMethod,
      asrMethod: settings.asrMethod,
      highLatitudeMethod: settings.highLatitudeMethod,
      adjustments: settings.adjustments,
    );
  } catch (e) {
    debugPrint('[PRAYER] Calculation error: $e');
    return null;
  }
});

// ============================================================
// SECTION 7 — MONTHLY PRAYER TIMES
// ============================================================

final monthlyPrayerTimesProvider =
    Provider.family<List<DailyPrayerTimes>, DateTime>((ref, month) {
  final locationState = ref.watch(locationProvider);
  final settings = ref.watch(prayerSettingsProvider);
  final service = ref.watch(prayerCalculationServiceProvider);

  if (locationState.location == null) return [];

  try {
    return service.calculateMonthlyPrayerTimes(
      month: month,
      location: locationState.location!,
      method: settings.calculationMethod,
      asrMethod: settings.asrMethod,
      highLatitudeMethod: settings.highLatitudeMethod,
      adjustments: settings.adjustments,
    );
  } catch (e) {
    return [];
  }
});

// ============================================================
// SECTION 8 — LIVE COUNTDOWN TICKER
// ============================================================

final currentTimeProvider = StreamProvider<DateTime>((ref) {
  return Stream.periodic(
    const Duration(seconds: 1),
    (_) => DateTime.now(),
  );
});

// ============================================================
// SECTION 9 — NEXT PRAYER & COUNTDOWN
// ============================================================

class NextPrayerInfo {
  const NextPrayerInfo({
    required this.prayer,
    required this.countdown,
    required this.progress,
  });

  final PrayerTime prayer;
  final Duration countdown;
  final double progress;

  String get formattedCountdown {
    if (countdown.isNegative) return '00:00:00';
    final h = countdown.inHours.toString().padLeft(2, '0');
    final m = countdown.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = countdown.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String get compactCountdown {
    if (countdown.isNegative) return 'Now';
    if (countdown.inHours >= 1) {
      final h = countdown.inHours;
      final m = countdown.inMinutes.remainder(60);
      return '${h}h ${m}m';
    }
    if (countdown.inMinutes >= 1) {
      final m = countdown.inMinutes;
      final s = countdown.inSeconds.remainder(60);
      return '${m}m ${s}s';
    }
    return '${countdown.inSeconds}s';
  }
}

final nextPrayerProvider = Provider<NextPrayerInfo?>((ref) {
  final times = ref.watch(dailyPrayerTimesProvider);
  final currentTimeAsync = ref.watch(currentTimeProvider);

  if (times == null) return null;

  final now = currentTimeAsync.value ?? DateTime.now();

  PrayerTime? nextPrayer = times.getNextPrayer(now);

  if (nextPrayer == null) {
    final tomorrow = now.add(const Duration(days: 1));
    final tomorrowTimes =
        ref.read(prayerCalculationServiceProvider).calculatePrayerTimes(
              date: tomorrow,
              location: times.location,
              method: times.method,
              asrMethod: times.asrMethod,
              adjustments: ref.read(prayerSettingsProvider).adjustments,
            );
    nextPrayer = tomorrowTimes.fajr;
  }

  PrayerTime? previousPrayer;
  for (final prayer in times.prayers) {
    if (!prayer.type.isObligatory) continue;
    if (prayer.adjustedTime.isBefore(now) && prayer.type != nextPrayer.type) {
      previousPrayer = prayer;
    }
  }

  final countdown = nextPrayer.adjustedTime.difference(now);

  double progress = 0.0;
  if (previousPrayer != null) {
    final totalDuration =
        nextPrayer.adjustedTime.difference(previousPrayer.adjustedTime);
    final elapsed = now.difference(previousPrayer.adjustedTime);
    if (totalDuration.inSeconds > 0) {
      progress = elapsed.inSeconds / totalDuration.inSeconds;
      progress = progress.clamp(0.0, 1.0);
    }
  }

  return NextPrayerInfo(
    prayer: nextPrayer,
    countdown: countdown,
    progress: progress,
  );
});

// ============================================================
// SECTION 10 — CURRENT PRAYER
// ============================================================

final currentPrayerProvider = Provider<PrayerTime?>((ref) {
  final times = ref.watch(dailyPrayerTimesProvider);
  final currentTimeAsync = ref.watch(currentTimeProvider);

  if (times == null) return null;
  final now = currentTimeAsync.value ?? DateTime.now();
  return times.getCurrentPrayer(now);
});

// ============================================================
// SECTION 11 — PRAYER TRACKING (Records)
// ============================================================

class PrayerRecordsNotifier extends StateNotifier<List<PrayerRecord>> {
  PrayerRecordsNotifier() : super([]) {
    _loadRecords();
  }

  static const String _key = 'prayer_records';

  Future<void> _loadRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_key);
      if (cached == null) return;

      final list = jsonDecode(cached) as List;
      state = list.map((json) {
        final map = json as Map<String, dynamic>;
        return PrayerRecord(
          date: DateTime.parse(map['date'] as String),
          type: PrayerType.values.firstWhere((p) => p.name == map['type']),
          status:
              PrayerStatus.values.firstWhere((s) => s.name == map['status']),
          prayedAt: map['prayedAt'] != null
              ? DateTime.parse(map['prayedAt'] as String)
              : null,
          notes: map['notes'] as String?,
        );
      }).toList();
    } catch (e) {
      debugPrint('[RECORDS] Load error: $e');
    }
  }

  Future<void> _saveRecords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = state
          .map((record) => {
                'date': record.date.toIso8601String(),
                'type': record.type.name,
                'status': record.status.name,
                'prayedAt': record.prayedAt?.toIso8601String(),
                'notes': record.notes,
              })
          .toList();
      await prefs.setString(_key, jsonEncode(list));
    } catch (e) {
      debugPrint('[RECORDS] Save error: $e');
    }
  }

  Future<void> markPrayer({
    required DateTime date,
    required PrayerType type,
    required PrayerStatus status,
    String? notes,
  }) async {
    final dateOnly = DateTime(date.year, date.month, date.day);

    final updated = state
        .where((r) => !(r.date.year == dateOnly.year &&
            r.date.month == dateOnly.month &&
            r.date.day == dateOnly.day &&
            r.type == type))
        .toList();

    updated.add(PrayerRecord(
      date: dateOnly,
      type: type,
      status: status,
      prayedAt: status != PrayerStatus.pending ? DateTime.now() : null,
      notes: notes,
    ));

    state = updated;
    await _saveRecords();
  }

  PrayerRecord? getRecord(DateTime date, PrayerType type) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    try {
      return state.firstWhere((r) =>
          r.date.year == dateOnly.year &&
          r.date.month == dateOnly.month &&
          r.date.day == dateOnly.day &&
          r.type == type);
    } catch (_) {
      return null;
    }
  }

  List<PrayerRecord> getRecordsForDate(DateTime date) {
    final dateOnly = DateTime(date.year, date.month, date.day);
    return state.where((r) {
      return r.date.year == dateOnly.year &&
          r.date.month == dateOnly.month &&
          r.date.day == dateOnly.day;
    }).toList();
  }

  List<PrayerRecord> getRecordsInRange(DateTime start, DateTime end) {
    return state.where((r) {
      return !r.date.isBefore(start) && !r.date.isAfter(end);
    }).toList();
  }

  Future<void> clearAll() async {
    state = [];
    await _saveRecords();
  }
}

final prayerRecordsProvider =
    StateNotifierProvider<PrayerRecordsNotifier, List<PrayerRecord>>((ref) {
  return PrayerRecordsNotifier();
});

// ============================================================
// SECTION 12 — PRAYER STATISTICS
// ============================================================

final prayerStatisticsProvider = Provider<PrayerStatistics>((ref) {
  final records = ref.watch(prayerRecordsProvider);

  if (records.isEmpty) return PrayerStatistics.empty();

  int prayed = 0;
  int missed = 0;
  int inMosque = 0;
  final byType = <PrayerType, int>{};

  for (final record in records) {
    switch (record.status) {
      case PrayerStatus.prayed:
      case PrayerStatus.makeup:
        prayed++;
        byType[record.type] = (byType[record.type] ?? 0) + 1;
        break;
      case PrayerStatus.prayedInMosque:
        prayed++;
        inMosque++;
        byType[record.type] = (byType[record.type] ?? 0) + 1;
        break;
      case PrayerStatus.missed:
        missed++;
        break;
      case PrayerStatus.pending:
        break;
    }
  }

  int currentStreak = 0;
  int longestStreak = 0;
  int tempStreak = 0;

  final dateGroups = <String, List<PrayerRecord>>{};
  for (final r in records) {
    final key = '${r.date.year}-${r.date.month}-${r.date.day}';
    dateGroups.putIfAbsent(key, () => []).add(r);
  }

  final sortedDates = dateGroups.keys.toList()..sort();

  DateTime? lastDate;
  for (final key in sortedDates.reversed) {
    final dayRecords = dateGroups[key]!;
    final prayedInDay = dayRecords
        .where((r) =>
            r.status == PrayerStatus.prayed ||
            r.status == PrayerStatus.prayedInMosque ||
            r.status == PrayerStatus.makeup)
        .length;

    if (prayedInDay >= 5) {
      tempStreak++;
      longestStreak = tempStreak > longestStreak ? tempStreak : longestStreak;

      if (lastDate == null) {
        currentStreak = tempStreak;
        lastDate = dayRecords.first.date;
      }
    } else {
      tempStreak = 0;
      if (lastDate == null) currentStreak = 0;
    }
  }

  return PrayerStatistics(
    totalPrayers: records.length,
    prayedCount: prayed,
    missedCount: missed,
    inMosqueCount: inMosque,
    currentStreak: currentStreak,
    longestStreak: longestStreak,
    byType: byType,
  );
});

// ============================================================
// SECTION 13 — QIBLA DIRECTION
// ============================================================

final qiblaDirectionProvider = Provider<double?>((ref) {
  final locationState = ref.watch(locationProvider);
  final service = ref.watch(prayerCalculationServiceProvider);

  if (locationState.location == null) return null;
  return service.calculateQiblaDirection(locationState.location!);
});

final distanceToKaabaProvider = Provider<double?>((ref) {
  final locationState = ref.watch(locationProvider);
  final service = ref.watch(prayerCalculationServiceProvider);

  if (locationState.location == null) return null;
  return service.calculateDistanceToKaaba(locationState.location!);
});
