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

import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

import '../../../../core/constants/app_constants.dart';
import '../models/prayer_models.dart';

class PrayerCalculationService {
  static bool _tzInitialized = false;

  PrayerCalculationService() {
    _ensureTzInitialized();
  }

  void _ensureTzInitialized() {
    if (_tzInitialized) return;
    try {
      tz_data.initializeTimeZones();
      _tzInitialized = true;
    } catch (_) {}
  }

  // ============================================================
  // MAIN CALCULATION METHOD
  // ============================================================

  /// Calculate all prayer times for a given date and location
  /// P0.6 FIX: Uses location timezone, not device timezone.
  /// Priority: 1) location.timezone IANA -> offset via mapping, 2) longitude estimate, 3) device fallback.
  DailyPrayerTimes calculatePrayerTimes({
    required DateTime date,
    required PrayerLocation location,
    required CalculationMethod method,
    required AsrMethod asrMethod,
    HighLatitudeMethod highLatitudeMethod = HighLatitudeMethod.none,
    Map<PrayerType, int> adjustments = const {},
    double? explicitTimezoneOffset,
  }) {
    // Convert to noon of that day for consistency
    final calcDate = DateTime(date.year, date.month, date.day, 12);

    // P0.6: Resolve timezone correctly
    final timezoneOffset =
        explicitTimezoneOffset ?? _resolveTimezoneOffset(location, calcDate);

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

    final ishaHourRaw = _calculateIsha(
      julianDate,
      location.latitude,
      location.longitude,
      timezoneOffset,
      method,
      maghribHour,
    );

    // Phase 3: High-latitude correction — replace NaN (polar day/night) with method-specific adjustment
    double fajrHourCorrected = fajrHour;
    double ishaHourCorrected = ishaHourRaw;
    if (fajrHour.isNaN || ishaHourRaw.isNaN) {
      // Determine night duration; handle NaN sunrise/maghrib (polar) with fallback 8h
      final safeSunrise = sunriseHour.isNaN ? 6.0 : sunriseHour;
      final safeMaghrib = maghribHour.isNaN ? 18.0 : maghribHour;
      final night = _calculateNightDuration(safeSunrise, safeMaghrib);
      final methodToUse = highLatitudeMethod == HighLatitudeMethod.none
          ? HighLatitudeMethod
              .angleBased // emergency fallback when high-lat but method none
          : highLatitudeMethod;
      if (fajrHour.isNaN) {
        fajrHourCorrected = _highLatAdjustment(
            safeSunrise, night, method.fajrAngle, methodToUse, true);
      }
      if (ishaHourRaw.isNaN) {
        // For UmmAlQura etc. where isha is interval, ishaHourRaw already valid; only angle-based may be NaN
        ishaHourCorrected = _highLatAdjustment(
            safeMaghrib,
            night,
            method.useIshaInterval ? 18.0 : method.ishaAngle,
            methodToUse,
            false);
      }
    }

    // Use corrected values
    final ishaHour = ishaHourCorrected;
    // Also need to handle fajrHourCorrected
    final fajrHourFinal = fajrHourCorrected;

    // Convert hours to DateTime objects
    final prayers = [
      _createPrayerTime(
        PrayerType.fajr,
        calcDate,
        fajrHourFinal,
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
  // SUN ANGLE TIME (CORE FORMULA) — PHASE 3 HIGH-LAT FIX
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

    if (denominator == 0) return double.nan;

    final ratio = numerator / denominator;

    // Polar day/night: sun never reaches angle → NaN for high-lat handler
    if (ratio < -1 || ratio > 1) {
      return double.nan;
    }

    final t = _arccos(ratio) / 15;
    return dhuhr + (isCcw ? -t : t);
  }

  // Phase 3: High-latitude night duration and adjustment
  double _calculateNightDuration(double sunriseHour, double maghribHour) {
    // Night = from maghrib to next sunrise: (24 - maghrib) + sunrise
    if (sunriseHour.isNaN || maghribHour.isNaN) return 8.0; // fallback 8h night
    var night = (24.0 - maghribHour) + sunriseHour;
    if (night < 0) night += 24;
    if (night > 16) night = 8; // clamp unrealistic polar night
    if (night < 2) night = 8;
    return night;
  }

  double _highLatAdjustment(
    double baseHour, // sunrise for Fajr, maghrib for Isha
    double nightDuration,
    double angle,
    HighLatitudeMethod method,
    bool isFajr,
  ) {
    double portion;
    switch (method) {
      case HighLatitudeMethod.angleBased:
        // Portion = angle/60 * night (standard)
        portion = (angle / 60.0) * nightDuration;
        break;
      case HighLatitudeMethod.seventh:
        portion = nightDuration / 7.0;
        break;
      case HighLatitudeMethod.midnight:
        portion = nightDuration / 2.0;
        break;
      case HighLatitudeMethod.none:
        return baseHour + (isFajr ? -6 : 6);
    }
    // Clamp portion to reasonable 0.5..3h for angleBased
    portion = portion.clamp(0.5, 3.5);
    return baseHour + (isFajr ? -portion : portion);
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
    // Phase 3: Handle NaN (polar) — fallback to noon with note
    if (hour.isNaN || hour.isInfinite) {
      hour =
          12.0; // noon fallback; high-lat correction should have handled Fajr/Isha, this is for sunrise/maghrib polar case
    }
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
  // PHASE 2 — EXACT TIMEZONE RESOLUTION (IANA via timezone package)
  // ============================================================

  /// Resolve timezone offset for location using IANA database.
  /// Priority: 1) location.timezone IANA via tz.getLocation + TZDateTime,
  ///           2) countryCode fallback for when timezone string is null (covers most users),
  ///           3) longitude emergency fallback explicitly documented.
  double _resolveTimezoneOffset(PrayerLocation location, DateTime date) {
    _ensureTzInitialized();

    // 1. IANA timezone — proper TZDateTime offset (handles DST and 5:45, 9:30 correctly)
    if (location.timezone != null && location.timezone!.isNotEmpty) {
      final offset = _ianaOffsetViaTz(location.timezone!, date);
      if (offset != null) return offset;
    }

    // 2. CountryCode fallback when timezone string is null (common when from geolocator without reverse geocode)
    // This avoids emergency longitude for major Islamic regions.
    if (location.countryCode != null) {
      final ccOffset = _countryCodeTimezoneOffset(location.countryCode!);
      // Only use countryCode if we have no IANA; longitude emergency will handle US/AU subzones better
      if (ccOffset != null) {
        // For US/CA/AU where subzones vary widely, prefer longitude if timezone missing
        if (['US', 'CA', 'AU'].contains(location.countryCode!.toUpperCase())) {
          // Fall through to longitude emergency for these
        } else {
          return ccOffset;
        }
      }
    }

    // 3. Emergency fallback: longitude estimation — explicitly documented as emergency
    // Used only when no IANA and no countryCode mapping (rare). Error up to 0.5-1h.
    final lngEstimate = (location.longitude / 15.0);
    final rounded = (lngEstimate * 4).round() /
        4.0; // quarter-hour increments to support Kathmandu 5:45 etc. via lng
    return rounded.clamp(-12.0, 14.0);
  }

  /// Real IANA offset via timezone package (handles Kathmandu 5:45, Adelaide 9:30, DST correctly)
  double? _ianaOffsetViaTz(String iana, DateTime date) {
    try {
      final loc = tz.getLocation(iana);
      // Use noon of date to capture DST correctly
      final tzDateTime =
          tz.TZDateTime(loc, date.year, date.month, date.day, 12);
      return tzDateTime.timeZoneOffset.inMinutes / 60.0;
    } catch (_) {
      // Try case-insensitive fallback
      try {
        final all = tz.timeZoneDatabase.locations;
        for (final key in all.keys) {
          if (key.toLowerCase() == iana.toLowerCase()) {
            final loc = tz.getLocation(key);
            final tzDateTime =
                tz.TZDateTime(loc, date.year, date.month, date.day, 12);
            return tzDateTime.timeZoneOffset.inMinutes / 60.0;
          }
        }
      } catch (_) {}
      return null;
    }
  }

  double? _countryCodeTimezoneOffset(String cc) {
    const ccMap = {
      'PK': 5.0,
      'IN': 5.5,
      'BD': 6.0,
      'NP': 5.75,
      'MM': 6.5,
      'TH': 7.0,
      'SG': 8.0,
      'MY': 8.0,
      'ID': 7.0,
      'AE': 4.0,
      'OM': 4.0,
      'SA': 3.0,
      'KW': 3.0,
      'BH': 3.0,
      'QA': 3.0,
      'IR': 3.5, // Tehan DST 4.5 handled by IANA; this is fallback
      'TR': 3.0,
      'EG': 2.0,
      'GB': 0.0,
      'UK': 0.0,
      'US': -5.0,
      'CA': -5.0,
      'AU': 10.0,
      'NZ': 12.0,
    };
    return ccMap[cc.toUpperCase()];
  }

  // ============================================================
  // QIBLA DIRECTION CALCULATION
  // ============================================================

  /// Calculate Qibla direction from given location
  /// Returns bearing in degrees (0-360) from North
  /// Centralized to AppIslamicConstants.kaabatullah (21.3891,39.8579)
  double calculateQiblaDirection(PrayerLocation location) {
    const kaabaLat = AppIslamicConstants.kaabatullahLatitude;
    const kaabaLng = AppIslamicConstants.kaabatullahLongitude;

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
  /// Centralized to AppIslamicConstants
  double calculateDistanceToKaaba(PrayerLocation location) {
    const kaabaLat = AppIslamicConstants.kaabatullahLatitude;
    const kaabaLng = AppIslamicConstants.kaabatullahLongitude;
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
