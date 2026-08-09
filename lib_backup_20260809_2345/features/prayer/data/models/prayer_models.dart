// lib/features/prayer/data/models/prayer_models.dart

// ============================================================
// QIBRA AI — PRAYER MODELS (v1.0)
// Phase: 9 — Advanced Prayer System
// ============================================================

import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

// ============================================================
// SECTION 1 — PRAYER TYPE ENUM
// ============================================================

enum PrayerType {
  fajr('Fajr', 'الفجر', 'Dawn', 'assets/icons/prayer.svg', Color(0xFF3F51B5)),
  sunrise('Sunrise', 'الشروق', 'Sunrise', 'assets/icons/prayer.svg',
      Color(0xFFFFA726)),
  dhuhr('Dhuhr', 'الظهر', 'Noon', 'assets/icons/prayer.svg', Color(0xFFFDD835)),
  asr('Asr', 'العصر', 'Afternoon', 'assets/icons/prayer.svg',
      Color(0xFFFF7043)),
  maghrib('Maghrib', 'المغرب', 'Sunset', 'assets/icons/prayer.svg',
      Color(0xFFE53935)),
  isha('Isha', 'العشاء', 'Night', 'assets/icons/prayer.svg', Color(0xFF1A237E));

  const PrayerType(
    this.name,
    this.arabicName,
    this.description,
    this.iconPath,
    this.color,
  );

  final String name;
  final String arabicName;
  final String description;
  final String iconPath;
  final Color color;

  IconData get icon {
    return switch (this) {
      PrayerType.fajr => Icons.brightness_4_rounded,
      PrayerType.sunrise => Icons.wb_sunny_rounded,
      PrayerType.dhuhr => Icons.wb_sunny_outlined,
      PrayerType.asr => Icons.wb_twilight_rounded,
      PrayerType.maghrib => Icons.brightness_3_rounded,
      PrayerType.isha => Icons.dark_mode_rounded,
    };
  }

  /// Only 5 obligatory prayers (excludes Sunrise)
  bool get isObligatory => this != PrayerType.sunrise;

  /// List of only obligatory prayers
  static List<PrayerType> get obligatoryPrayers =>
      values.where((p) => p.isObligatory).toList();
}

// ============================================================
// SECTION 2 — CALCULATION METHOD
// ============================================================

enum CalculationMethod {
  muslimWorldLeague(
    'Muslim World League',
    'MWL',
    'Standard for most of the world',
    18.0, // Fajr angle
    17.0, // Isha angle
  ),
  islamicSociety(
    'Islamic Society of North America',
    'ISNA',
    'North America standard',
    15.0,
    15.0,
  ),
  egyptian(
    'Egyptian General Authority',
    'Egypt',
    'Africa, Syria, Iraq, Lebanon, Malaysia',
    19.5,
    17.5,
  ),
  ummAlQura(
    'Umm Al-Qura University, Makkah',
    'Makkah',
    'Arabian Peninsula',
    18.5,
    -1, // 90 minutes after Maghrib
  ),
  karachi(
    'University of Islamic Sciences, Karachi',
    'Karachi',
    'Pakistan, Bangladesh, India, Afghanistan',
    18.0,
    18.0,
  ),
  tehran(
    'Institute of Geophysics, Tehran',
    'Tehran',
    'Iran, Some Shia communities',
    17.7,
    14.0,
  ),
  jafari(
    'Shia Ithna Ashari, Leva',
    'Jafari',
    'Shia communities',
    16.0,
    14.0,
  ),
  singapore(
    'Majlis Ugama Islam Singapura',
    'Singapore',
    'Singapore, Malaysia, Indonesia',
    20.0,
    18.0,
  ),
  gulf(
    'Gulf Region',
    'Gulf',
    'UAE, Kuwait, Bahrain, Qatar, Oman',
    19.5,
    -1,
  );

  const CalculationMethod(
    this.fullName,
    this.shortName,
    this.description,
    this.fajrAngle,
    this.ishaAngle,
  );

  final String fullName;
  final String shortName;
  final String description;
  final double fajrAngle;
  final double ishaAngle;

  /// If ishaAngle is -1, Isha is calculated as X minutes after Maghrib
  bool get useIshaInterval => ishaAngle == -1;

  /// Minutes after Maghrib for Isha (when using interval method)
  int get ishaIntervalMinutes {
    return switch (this) {
      CalculationMethod.ummAlQura => 90,
      CalculationMethod.gulf => 90,
      _ => 0,
    };
  }
}

// ============================================================
// SECTION 3 — ASR JURISTIC METHOD
// ============================================================

enum AsrMethod {
  standard(
    'Standard (Shafi\'i, Maliki, Hanbali)',
    'Standard',
    'Most common — shadow = object height',
    1,
  ),
  hanafi(
    'Hanafi',
    'Hanafi',
    'Shadow = 2x object height',
    2,
  );

  const AsrMethod(
    this.fullName,
    this.shortName,
    this.description,
    this.shadowFactor,
  );

  final String fullName;
  final String shortName;
  final String description;
  final int shadowFactor;
}

// ============================================================
// SECTION 4 — HIGH LATITUDE ADJUSTMENT
// ============================================================

enum HighLatitudeMethod {
  none('No Adjustment', 'Use calculated times as is'),
  angleBased('Angle-Based', 'Best for high latitudes'),
  midnight('Middle of Night', 'Fajr/Isha at midnight'),
  seventh('One-Seventh', 'Divide night into 7 parts');

  const HighLatitudeMethod(this.label, this.description);
  final String label;
  final String description;
}

// ============================================================
// SECTION 5 — PRAYER TIME MODEL
// ============================================================

class PrayerTime extends Equatable {
  const PrayerTime({
    required this.type,
    required this.time,
    this.adjustment = 0,
  });

  final PrayerType type;
  final DateTime time;
  final int adjustment; // minutes

  DateTime get adjustedTime => time.add(Duration(minutes: adjustment));

  String get formattedTime {
    final h = adjustedTime.hour;
    final m = adjustedTime.minute;
    final hour12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    final period = h < 12 ? 'AM' : 'PM';
    return '${hour12.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')} $period';
  }

  String get formattedTime24 {
    final h = adjustedTime.hour.toString().padLeft(2, '0');
    final m = adjustedTime.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Duration timeUntil(DateTime from) {
    return adjustedTime.difference(from);
  }

  bool isPast(DateTime now) => adjustedTime.isBefore(now);
  bool isCurrent(DateTime now, DateTime nextPrayerTime) {
    return !isPast(now) == false && now.isBefore(nextPrayerTime);
  }

  PrayerTime copyWith({
    PrayerType? type,
    DateTime? time,
    int? adjustment,
  }) {
    return PrayerTime(
      type: type ?? this.type,
      time: time ?? this.time,
      adjustment: adjustment ?? this.adjustment,
    );
  }

  @override
  List<Object?> get props => [type, time, adjustment];
}

// ============================================================
// SECTION 6 — DAILY PRAYER TIMES
// ============================================================

class DailyPrayerTimes extends Equatable {
  const DailyPrayerTimes({
    required this.date,
    required this.prayers,
    required this.location,
    required this.method,
    required this.asrMethod,
  });

  final DateTime date;
  final List<PrayerTime> prayers;
  final PrayerLocation location;
  final CalculationMethod method;
  final AsrMethod asrMethod;

  PrayerTime? getPrayer(PrayerType type) {
    try {
      return prayers.firstWhere((p) => p.type == type);
    } catch (_) {
      return null;
    }
  }

  PrayerTime get fajr => getPrayer(PrayerType.fajr)!;
  PrayerTime get sunrise => getPrayer(PrayerType.sunrise)!;
  PrayerTime get dhuhr => getPrayer(PrayerType.dhuhr)!;
  PrayerTime get asr => getPrayer(PrayerType.asr)!;
  PrayerTime get maghrib => getPrayer(PrayerType.maghrib)!;
  PrayerTime get isha => getPrayer(PrayerType.isha)!;

  /// Get the next prayer after given time
  PrayerTime? getNextPrayer(DateTime now) {
    for (final prayer in prayers) {
      if (!prayer.type.isObligatory) continue;
      if (prayer.adjustedTime.isAfter(now)) {
        return prayer;
      }
    }
    return null; // All prayers passed today
  }

  /// Get the currently active prayer window
  PrayerTime? getCurrentPrayer(DateTime now) {
    final obligatory = prayers.where((p) => p.type.isObligatory).toList();
    for (int i = 0; i < obligatory.length; i++) {
      final prayer = obligatory[i];
      final next = i < obligatory.length - 1 ? obligatory[i + 1] : null;

      if (prayer.adjustedTime.isBefore(now) &&
          (next == null || next.adjustedTime.isAfter(now))) {
        return prayer;
      }
    }
    return null;
  }

  @override
  List<Object?> get props => [date, prayers, location, method, asrMethod];
}

// ============================================================
// SECTION 7 — LOCATION MODEL
// ============================================================

class PrayerLocation extends Equatable {
  const PrayerLocation({
    required this.latitude,
    required this.longitude,
    required this.city,
    required this.country,
    this.countryCode,
    this.timezone,
    this.elevation = 0,
    this.isManuallySet = false,
  });

  final double latitude;
  final double longitude;
  final String city;
  final String country;
  final String? countryCode;
  final String? timezone;
  final double elevation;
  final bool isManuallySet;

  String get displayName => '$city, $country';

  bool get isHighLatitude => latitude.abs() > 48.5;

  factory PrayerLocation.makkah() {
    return const PrayerLocation(
      latitude: 21.4225,
      longitude: 39.8262,
      city: 'Makkah',
      country: 'Saudi Arabia',
      countryCode: 'SA',
      timezone: 'Asia/Riyadh',
    );
  }

  factory PrayerLocation.karachi() {
    return const PrayerLocation(
      latitude: 24.8607,
      longitude: 67.0011,
      city: 'Karachi',
      country: 'Pakistan',
      countryCode: 'PK',
      timezone: 'Asia/Karachi',
    );
  }

  PrayerLocation copyWith({
    double? latitude,
    double? longitude,
    String? city,
    String? country,
    String? countryCode,
    String? timezone,
    double? elevation,
    bool? isManuallySet,
  }) {
    return PrayerLocation(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      city: city ?? this.city,
      country: country ?? this.country,
      countryCode: countryCode ?? this.countryCode,
      timezone: timezone ?? this.timezone,
      elevation: elevation ?? this.elevation,
      isManuallySet: isManuallySet ?? this.isManuallySet,
    );
  }

  @override
  List<Object?> get props => [
        latitude,
        longitude,
        city,
        country,
        countryCode,
        timezone,
        elevation,
        isManuallySet,
      ];
}

// ============================================================
// SECTION 8 — PRAYER STATUS (Tracking)
// ============================================================

enum PrayerStatus {
  pending('Pending', Icons.schedule_rounded, Color(0xFF9E9E9E)),
  prayed('Prayed', Icons.check_circle_rounded, Color(0xFF4CAF50)),
  prayedInMosque('In Mosque', Icons.mosque_rounded, Color(0xFF00A86B)),
  missed('Missed', Icons.cancel_rounded, Color(0xFFEF5350)),
  makeup('Made Up', Icons.autorenew_rounded, Color(0xFFFFA726));

  const PrayerStatus(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color color;
}

class PrayerRecord extends Equatable {
  const PrayerRecord({
    required this.date,
    required this.type,
    required this.status,
    this.prayedAt,
    this.notes,
  });

  final DateTime date;
  final PrayerType type;
  final PrayerStatus status;
  final DateTime? prayedAt;
  final String? notes;

  String get key {
    final d =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return '${d}_${type.name}';
  }

  PrayerRecord copyWith({
    DateTime? date,
    PrayerType? type,
    PrayerStatus? status,
    DateTime? prayedAt,
    String? notes,
  }) {
    return PrayerRecord(
      date: date ?? this.date,
      type: type ?? this.type,
      status: status ?? this.status,
      prayedAt: prayedAt ?? this.prayedAt,
      notes: notes ?? this.notes,
    );
  }

  @override
  List<Object?> get props => [date, type, status, prayedAt, notes];
}

// ============================================================
// SECTION 9 — PRAYER SETTINGS
// ============================================================

class PrayerSettings extends Equatable {
  const PrayerSettings({
    this.calculationMethod = CalculationMethod.muslimWorldLeague,
    this.asrMethod = AsrMethod.standard,
    this.highLatitudeMethod = HighLatitudeMethod.none,
    this.adjustments = const {},
    this.enableNotifications = true,
    this.enableAdhan = true,
    this.enablePreReminder = true,
    this.preReminderMinutes = 15,
    this.enableSilentMode = false,
    this.silentModeDuration = 10,
    this.adhanSound = 'default',
    this.iqamahMinutes = 15,
    this.showSunrise = true,
    this.use24HourFormat = false,
  });

  final CalculationMethod calculationMethod;
  final AsrMethod asrMethod;
  final HighLatitudeMethod highLatitudeMethod;
  final Map<PrayerType, int> adjustments;
  final bool enableNotifications;
  final bool enableAdhan;
  final bool enablePreReminder;
  final int preReminderMinutes;
  final bool enableSilentMode;
  final int silentModeDuration;
  final String adhanSound;
  final int iqamahMinutes;
  final bool showSunrise;
  final bool use24HourFormat;

  int getAdjustment(PrayerType type) => adjustments[type] ?? 0;

  PrayerSettings copyWith({
    CalculationMethod? calculationMethod,
    AsrMethod? asrMethod,
    HighLatitudeMethod? highLatitudeMethod,
    Map<PrayerType, int>? adjustments,
    bool? enableNotifications,
    bool? enableAdhan,
    bool? enablePreReminder,
    int? preReminderMinutes,
    bool? enableSilentMode,
    int? silentModeDuration,
    String? adhanSound,
    int? iqamahMinutes,
    bool? showSunrise,
    bool? use24HourFormat,
  }) {
    return PrayerSettings(
      calculationMethod: calculationMethod ?? this.calculationMethod,
      asrMethod: asrMethod ?? this.asrMethod,
      highLatitudeMethod: highLatitudeMethod ?? this.highLatitudeMethod,
      adjustments: adjustments ?? this.adjustments,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      enableAdhan: enableAdhan ?? this.enableAdhan,
      enablePreReminder: enablePreReminder ?? this.enablePreReminder,
      preReminderMinutes: preReminderMinutes ?? this.preReminderMinutes,
      enableSilentMode: enableSilentMode ?? this.enableSilentMode,
      silentModeDuration: silentModeDuration ?? this.silentModeDuration,
      adhanSound: adhanSound ?? this.adhanSound,
      iqamahMinutes: iqamahMinutes ?? this.iqamahMinutes,
      showSunrise: showSunrise ?? this.showSunrise,
      use24HourFormat: use24HourFormat ?? this.use24HourFormat,
    );
  }

  @override
  List<Object?> get props => [
        calculationMethod,
        asrMethod,
        highLatitudeMethod,
        adjustments,
        enableNotifications,
        enableAdhan,
        enablePreReminder,
        preReminderMinutes,
        enableSilentMode,
        silentModeDuration,
        adhanSound,
        iqamahMinutes,
        showSunrise,
        use24HourFormat,
      ];
}

// ============================================================
// SECTION 10 — PRAYER STATISTICS
// ============================================================

class PrayerStatistics extends Equatable {
  const PrayerStatistics({
    required this.totalPrayers,
    required this.prayedCount,
    required this.missedCount,
    required this.inMosqueCount,
    required this.currentStreak,
    required this.longestStreak,
    required this.byType,
  });

  final int totalPrayers;
  final int prayedCount;
  final int missedCount;
  final int inMosqueCount;
  final int currentStreak;
  final int longestStreak;
  final Map<PrayerType, int> byType;

  double get consistencyPercentage {
    if (totalPrayers == 0) return 0;
    return (prayedCount / totalPrayers) * 100;
  }

  double get mosquePercentage {
    if (prayedCount == 0) return 0;
    return (inMosqueCount / prayedCount) * 100;
  }

  String get consistencyLabel {
    final p = consistencyPercentage;
    if (p >= 90) return 'Excellent 🌟';
    if (p >= 75) return 'Very Good 💚';
    if (p >= 60) return 'Good 👍';
    if (p >= 40) return 'Fair 📈';
    return 'Needs Improvement 🤲';
  }

  factory PrayerStatistics.empty() {
    return const PrayerStatistics(
      totalPrayers: 0,
      prayedCount: 0,
      missedCount: 0,
      inMosqueCount: 0,
      currentStreak: 0,
      longestStreak: 0,
      byType: {},
    );
  }

  @override
  List<Object?> get props => [
        totalPrayers,
        prayedCount,
        missedCount,
        inMosqueCount,
        currentStreak,
        longestStreak,
        byType,
      ];
}

// ============================================================
// END OF FILE — prayer_models.dart
// ============================================================
