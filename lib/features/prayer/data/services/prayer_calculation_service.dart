// lib/features/prayer/data/services/prayer_calculation_service.dart

// ============================================================
// QIBRA AI — PRAYER CALCULATION SERVICE (v1.0)
// Phase: 9 — Astronomical Prayer Time Calculation
// ============================================================
// Based on:
//   - Praying Times Calculation - Ahmed Ouzzine
//   - Astronomical Algorithms - Jean Meeus
//   - IslamicFinder & PrayTimes.org formulas
// ============================================================

import 'dart:math' as math;

import '../models/prayer_models.dart';

class PrayerCalculationService {
  PrayerCalculationService();

  // ============================================================
  // MAIN CALCULATION METHOD
  // ============================================================

  /// Calculate all prayer times for a given date and location
  DailyPrayerTimes calculatePrayerTimes({
    required DateTime date,
    required PrayerLocation location,
    required CalculationMethod method,
    required AsrMethod asrMethod,
    HighLatitudeMethod highLatitudeMethod = HighLatitudeMethod.none,
    Map<PrayerType, int> adjustments = const {},
  }) {
    // Convert to noon of that day for consistency
    final calcDate = DateTime(date.year, date.month, date.day, 12);

    // Get timezone offset in hours
    final timezoneOffset = calcDate.timeZoneOffset.inHours.toDouble();

    // Calculate Julian date
    final julianDate = _calculateJulianDate(
      calcDate.year,
      calcDate.month,
      calcDate.day,
    );

    // Calculate each prayer time (returns hours since midnight)
    final fajrHour = _calculateFajr(
      julianDate,
      location.latitude,
      location.longitude,
      timezoneOffset,
      method.fajrAngle,
    );

    final sunriseHour = _calculateSunrise(
      julianDate,
      location.latitude,
      location.longitude,
      timezoneOffset,
    );

    final dhuhrHour = _calculateDhuhr(
      julianDate,
      location.longitude,
      timezoneOffset,
    );

    final asrHour = _calculateAsr(
      julianDate,
      location.latitude,
      location.longitude,
      timezoneOffset,
      asrMethod.shadowFactor,
    );

    final maghribHour = _calculateMaghrib(
      julianDate,
      location.latitude,
      location.longitude,
      timezoneOffset,
    );

    final ishaHour = _calculateIsha(
      julianDate,
      location.latitude,
      location.longitude,
      timezoneOffset,
      method,
      maghribHour,
    );

    // Convert hours to DateTime objects
    final prayers = [
      _createPrayerTime(
        PrayerType.fajr,
        calcDate,
        fajrHour,
        adjustments[PrayerType.fajr] ?? 0,
      ),
      _createPrayerTime(
        PrayerType.sunrise,
        calcDate,
        sunriseHour,
        adjustments[PrayerType.sunrise] ?? 0,
      ),
      _createPrayerTime(
        PrayerType.dhuhr,
        calcDate,
        dhuhrHour,
        adjustments[PrayerType.dhuhr] ?? 0,
      ),
      _createPrayerTime(
        PrayerType.asr,
        calcDate,
        asrHour,
        adjustments[PrayerType.asr] ?? 0,
      ),
      _createPrayerTime(
        PrayerType.maghrib,
        calcDate,
        maghribHour,
        adjustments[PrayerType.maghrib] ?? 0,
      ),
      _createPrayerTime(
        PrayerType.isha,
        calcDate,
        ishaHour,
        adjustments[PrayerType.isha] ?? 0,
      ),
    ];

    return DailyPrayerTimes(
      date: calcDate,
      prayers: prayers,
      location: location,
      method: method,
      asrMethod: asrMethod,
    );
  }

  /// Calculate prayer times for multiple days (for calendar view)
  List<DailyPrayerTimes> calculateMonthlyPrayerTimes({
    required DateTime month,
    required PrayerLocation location,
    required CalculationMethod method,
    required AsrMethod asrMethod,
    HighLatitudeMethod highLatitudeMethod = HighLatitudeMethod.none,
    Map<PrayerType, int> adjustments = const {},
  }) {
    final results = <DailyPrayerTimes>[];
    final firstDay = DateTime(month.year, month.month, 1);
    final lastDay = DateTime(month.year, month.month + 1, 0);
    final totalDays = lastDay.day;

    for (int day = 1; day <= totalDays; day++) {
      final date = DateTime(firstDay.year, firstDay.month, day);
      results.add(calculatePrayerTimes(
        date: date,
        location: location,
        method: method,
        asrMethod: asrMethod,
        highLatitudeMethod: highLatitudeMethod,
        adjustments: adjustments,
      ));
    }

    return results;
  }

  // ============================================================
  // JULIAN DATE CONVERSION
  // ============================================================

  double _calculateJulianDate(int year, int month, int day) {
    if (month <= 2) {
      year -= 1;
      month += 12;
    }
    final a = (year / 100).floor();
    final b = 2 - a + (a / 4).floor();
    return (365.25 * (year + 4716)).floor() +
        (30.6001 * (month + 1)).floor() +
        day +
        b -
        1524.5;
  }

  // ============================================================
  // SUN POSITION CALCULATIONS
  // ============================================================

  /// Get sun declination and equation of time
  /// Returns [declination, equationOfTime] both in degrees/minutes
  List<double> _sunPosition(double julianDate) {
    final d = julianDate - 2451545.0;
    final g = _fixAngle(357.529 + 0.98560028 * d);
    final q = _fixAngle(280.459 + 0.98564736 * d);
    final l = _fixAngle(q + 1.915 * _sin(g) + 0.020 * _sin(2 * g));

    final e = 23.439 - 0.00000036 * d;
    final ra = _arctan2(_cos(e) * _sin(l), _cos(l)) / 15;

    final decl = _arcsin(_sin(e) * _sin(l));
    final eqt = q / 15 - _fixHour(ra);

    return [decl, eqt];
  }

  // ============================================================
  // PRAYER TIME CALCULATIONS
  // ============================================================

  double _calculateFajr(
    double julianDate,
    double latitude,
    double longitude,
    double timezone,
    double angle,
  ) {
    final dhuhr = _calculateDhuhr(julianDate, longitude, timezone);
    final time = _sunAngleTime(
      julianDate,
      latitude,
      angle,
      dhuhr,
      isCcw: true,
    );
    return time;
  }

  double _calculateSunrise(
    double julianDate,
    double latitude,
    double longitude,
    double timezone,
  ) {
    final dhuhr = _calculateDhuhr(julianDate, longitude, timezone);
    return _sunAngleTime(
      julianDate,
      latitude,
      0.833, // Standard sunrise angle
      dhuhr,
      isCcw: true,
    );
  }

  double _calculateDhuhr(
    double julianDate,
    double longitude,
    double timezone,
  ) {
    final sunPos = _sunPosition(julianDate);
    final eqt = sunPos[1];
    return 12 - eqt - longitude / 15 + timezone;
  }

  double _calculateAsr(
    double julianDate,
    double latitude,
    double longitude,
    double timezone,
    int shadowFactor,
  ) {
    final dhuhr = _calculateDhuhr(julianDate, longitude, timezone);
    final sunPos = _sunPosition(julianDate);
    final declination = sunPos[0];

    final angle = -_arccot(shadowFactor + _tan((latitude - declination).abs()));

    return _sunAngleTime(
      julianDate,
      latitude,
      angle,
      dhuhr,
      isCcw: false,
    );
  }

  double _calculateMaghrib(
    double julianDate,
    double latitude,
    double longitude,
    double timezone,
  ) {
    final dhuhr = _calculateDhuhr(julianDate, longitude, timezone);
    return _sunAngleTime(
      julianDate,
      latitude,
      0.833, // Standard sunset angle
      dhuhr,
      isCcw: false,
    );
  }

  double _calculateIsha(
    double julianDate,
    double latitude,
    double longitude,
    double timezone,
    CalculationMethod method,
    double maghribHour,
  ) {
    // If method uses interval (minutes after Maghrib)
    if (method.useIshaInterval) {
      return maghribHour + (method.ishaIntervalMinutes / 60.0);
    }

    // Angle-based calculation
    final dhuhr = _calculateDhuhr(julianDate, longitude, timezone);
    return _sunAngleTime(
      julianDate,
      latitude,
      method.ishaAngle,
      dhuhr,
      isCcw: false,
    );
  }

  // ============================================================
  // SUN ANGLE TIME (CORE FORMULA)
  // ============================================================

  double _sunAngleTime(
    double julianDate,
    double latitude,
    double angle,
    double dhuhr, {
    required bool isCcw,
  }) {
    final sunPos = _sunPosition(julianDate);
    final declination = sunPos[0];

    final numerator = -_sin(angle) - _sin(latitude) * _sin(declination);
    final denominator = _cos(latitude) * _cos(declination);

    if (denominator == 0) return dhuhr;

    final ratio = numerator / denominator;

    // Check for polar day/night
    if (ratio < -1 || ratio > 1) {
      // Handle polar regions - return approximation
      return dhuhr + (isCcw ? -6 : 6);
    }

    final t = _arccos(ratio) / 15;
    return dhuhr + (isCcw ? -t : t);
  }

  // ============================================================
  // HELPER: CONVERT HOUR TO DATETIME
  // ============================================================

  PrayerTime _createPrayerTime(
    PrayerType type,
    DateTime date,
    double hour,
    int adjustment,
  ) {
    // Handle hour overflow/underflow
    while (hour < 0) {
      hour += 24;
    }
    while (hour >= 24) {
      hour -= 24;
    }

    final hours = hour.floor();
    final minutes = ((hour - hours) * 60).round();

    // Handle minute overflow
    var finalHours = hours;
    var finalMinutes = minutes;

    if (finalMinutes >= 60) {
      finalHours += 1;
      finalMinutes -= 60;
    }

    if (finalHours >= 24) {
      finalHours -= 24;
    }

    final time = DateTime(
      date.year,
      date.month,
      date.day,
      finalHours,
      finalMinutes,
    );

    return PrayerTime(
      type: type,
      time: time,
      adjustment: adjustment,
    );
  }

  // ============================================================
  // MATHEMATICAL HELPERS (Degree-based trig)
  // ============================================================

  double _sin(double degrees) => math.sin(_degreesToRadians(degrees));
  double _cos(double degrees) => math.cos(_degreesToRadians(degrees));
  double _tan(double degrees) => math.tan(_degreesToRadians(degrees));

  double _arcsin(double x) => _radiansToDegrees(math.asin(x));
  double _arccos(double x) => _radiansToDegrees(math.acos(x));
  double _arctan2(double y, double x) => _radiansToDegrees(math.atan2(y, x));

  double _arccot(double x) => _radiansToDegrees(math.atan2(1, x));

  double _degreesToRadians(double degrees) => degrees * math.pi / 180;
  double _radiansToDegrees(double radians) => radians * 180 / math.pi;

  double _fixAngle(double angle) {
    angle = angle - 360 * (angle / 360).floor();
    return angle < 0 ? angle + 360 : angle;
  }

  double _fixHour(double hour) {
    hour = hour - 24 * (hour / 24).floor();
    return hour < 0 ? hour + 24 : hour;
  }

  // ============================================================
  // QIBLA DIRECTION CALCULATION
  // ============================================================

  /// Calculate Qibla direction from given location
  /// Returns bearing in degrees (0-360) from North
  double calculateQiblaDirection(PrayerLocation location) {
    const kaabaLat = 21.4225; // Kaaba latitude
    const kaabaLng = 39.8262; // Kaaba longitude

    final lat1 = _degreesToRadians(location.latitude);
    final lat2 = _degreesToRadians(kaabaLat);
    final dLng = _degreesToRadians(kaabaLng - location.longitude);

    final y = math.sin(dLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);

    final bearing = _radiansToDegrees(math.atan2(y, x));
    return (bearing + 360) % 360;
  }

  /// Calculate distance to Kaaba in kilometers
  double calculateDistanceToKaaba(PrayerLocation location) {
    const kaabaLat = 21.4225;
    const kaabaLng = 39.8262;
    const earthRadius = 6371.0; // km

    final lat1 = _degreesToRadians(location.latitude);
    final lat2 = _degreesToRadians(kaabaLat);
    final dLat = _degreesToRadians(kaabaLat - location.latitude);
    final dLng = _degreesToRadians(kaabaLng - location.longitude);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));

    return earthRadius * c;
  }

  // ============================================================
  // AUTO-DETECT CALCULATION METHOD BY LOCATION
  // ============================================================

  /// Auto-detect the best calculation method based on country
  CalculationMethod detectMethodByCountry(String? countryCode) {
    if (countryCode == null) return CalculationMethod.muslimWorldLeague;

    final code = countryCode.toUpperCase();

    // Pakistan, India, Bangladesh
    if (['PK', 'IN', 'BD', 'AF'].contains(code)) {
      return CalculationMethod.karachi;
    }

    // Saudi Arabia
    if (code == 'SA') {
      return CalculationMethod.ummAlQura;
    }

    // Gulf countries
    if (['AE', 'KW', 'BH', 'QA', 'OM'].contains(code)) {
      return CalculationMethod.gulf;
    }

    // North America
    if (['US', 'CA', 'MX'].contains(code)) {
      return CalculationMethod.islamicSociety;
    }

    // Egypt, Africa, Middle East
    if (['EG', 'SY', 'IQ', 'LB', 'JO', 'PS', 'YE'].contains(code)) {
      return CalculationMethod.egyptian;
    }

    // Iran
    if (code == 'IR') {
      return CalculationMethod.tehran;
    }

    // Singapore, Malaysia, Indonesia
    if (['SG', 'MY', 'ID', 'BN'].contains(code)) {
      return CalculationMethod.singapore;
    }

    // Default: Muslim World League (Europe, Africa, most)
    return CalculationMethod.muslimWorldLeague;
  }

  /// Auto-detect Asr method based on country
  AsrMethod detectAsrMethodByCountry(String? countryCode) {
    if (countryCode == null) return AsrMethod.standard;

    // Hanafi countries
    final hanafiCountries = ['PK', 'IN', 'BD', 'AF', 'TR', 'UZ'];
    if (hanafiCountries.contains(countryCode.toUpperCase())) {
      return AsrMethod.hanafi;
    }

    return AsrMethod.standard;
  }
}
