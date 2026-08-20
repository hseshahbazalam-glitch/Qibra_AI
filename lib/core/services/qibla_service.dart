// lib/features/qibla/data/services/qibla_service.dart

// ============================================================
// QIBRA AI — QIBLA SERVICE (v2.0 - Enhanced)
// GPS-based Qibla direction calculator with location name
// ============================================================

import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qibra_ai/core/services/qibla_calculator.dart';

// ============================================================
// QIBLA RESULT MODEL (Enhanced)
// ============================================================

class QiblaResult {
  final double qiblaAngle; // True north bearing
  final double latitude;
  final double longitude;
  final double distanceToMakkah;
  final String locationName;
  final String? city;
  final String? country;
  final double? altitude;
  final double? accuracy;
  final bool isFromCache;
  final DateTime? updatedAt;
  // P0.7: Magnetic declination (true vs magnetic north difference, degrees)
  // Positive = magnetic north east of true north
  final double magneticDeclination;
  final String declinationNote;

  const QiblaResult({
    required this.qiblaAngle,
    required this.latitude,
    required this.longitude,
    required this.distanceToMakkah,
    this.locationName = '',
    this.city,
    this.country,
    this.altitude,
    this.accuracy,
    this.isFromCache = false,
    this.updatedAt,
    this.magneticDeclination = 0.0,
    this.declinationNote = '',
  });

  String get formattedCoordinates {
    final latDir = latitude >= 0 ? 'N' : 'S';
    final lngDir = longitude >= 0 ? 'E' : 'W';
    return '${latitude.abs().toStringAsFixed(4)}°$latDir, ${longitude.abs().toStringAsFixed(4)}°$lngDir';
  }

  String get shortCoordinates {
    return '${latitude.toStringAsFixed(2)}, ${longitude.toStringAsFixed(2)}';
  }

  String get accuracyText {
    if (accuracy == null) return 'Unknown';
    if (accuracy! < 5) return 'Excellent';
    if (accuracy! < 15) return 'Good';
    if (accuracy! < 30) return 'Fair';
    return 'Poor';
  }
}

// ============================================================
// QIBLA SERVICE
// ============================================================

class QiblaService {
  QiblaService._();

  // SharedPreferences keys
  static const _kLastLat = 'qibla_last_lat';
  static const _kLastLng = 'qibla_last_lng';
  static const _kLastAngle = 'qibla_last_angle';
  static const _kLastDistance = 'qibla_last_distance';
  static const _kLastCity = 'qibla_last_city';
  static const _kLastCountry = 'qibla_last_country';
  static const _kLastAltitude = 'qibla_last_altitude';
  static const _kLastAccuracy = 'qibla_last_accuracy';
  static const _kLastUpdated = 'qibla_last_updated';

  // ============================================================
  // GET QIBLA DIRECTION
  // ============================================================

  static Future<QiblaResult> getQiblaDirection() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return await _getFromCache();
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return await _getFromCache();
      }

      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return await _getFromCache();
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      final angle = QiblaCalculator.directionFrom(
        position.latitude,
        position.longitude,
      );

      final distance = QiblaCalculator.distanceToKaabaFrom(
        position.latitude,
        position.longitude,
      );

      // P0.7: Estimate magnetic declination for true-vs-magnetic correction
      final declination = _estimateMagneticDeclination(
        position.latitude,
        position.longitude,
      );
      final declNote =
          _declinationNote(declination, position.latitude, position.longitude);

      // Get city name from coordinates (offline lookup)
      final locationInfo =
          _getLocationInfo(position.latitude, position.longitude);

      // Save to cache
      await _saveToCache(
        lat: position.latitude,
        lng: position.longitude,
        angle: angle,
        distance: distance,
        city: locationInfo['city'],
        country: locationInfo['country'],
        altitude: position.altitude,
        accuracy: position.accuracy,
      );

      return QiblaResult(
        qiblaAngle: angle,
        latitude: position.latitude,
        longitude: position.longitude,
        distanceToMakkah: distance,
        city: locationInfo['city'],
        country: locationInfo['country'],
        altitude: position.altitude,
        accuracy: position.accuracy,
        isFromCache: false,
        updatedAt: DateTime.now(),
        magneticDeclination: declination,
        declinationNote: declNote,
      );
    } catch (e) {
      return await _getFromCache();
    }
  }

  // ============================================================
  // OFFLINE LOCATION LOOKUP
  // Detects major regions without internet
  // ============================================================

  static Map<String, String> _getLocationInfo(double lat, double lng) {
    // Major regions detection (offline)

    // Pakistan
    if (lat >= 23.6 && lat <= 37.1 && lng >= 60.9 && lng <= 77.9) {
      String city = 'Pakistan';
      if (lat >= 24.7 && lat <= 25.1 && lng >= 66.9 && lng <= 67.3) {
        city = 'Karachi';
      } else if (lat >= 33.5 && lat <= 33.8 && lng >= 72.9 && lng <= 73.3) {
        city = 'Islamabad';
      }
      else if (lat >= 31.4 && lat <= 31.7 && lng >= 74.2 && lng <= 74.5) {
        city = 'Lahore';
      }
      else if (lat >= 34.0 && lat <= 34.2 && lng >= 71.4 && lng <= 71.7) {
        city = 'Peshawar';
      }
      return {'city': city, 'country': 'Pakistan'};
    }

    // India
    if (lat >= 8.0 && lat <= 37.0 && lng >= 68.0 && lng <= 97.5) {
      String city = 'India';
      if (lat >= 28.4 && lat <= 28.9 && lng >= 76.8 && lng <= 77.4) {
        city = 'Delhi';
      } else if (lat >= 18.9 && lat <= 19.3 && lng >= 72.8 && lng <= 73.0) {
        city = 'Mumbai';
      }
      else if (lat >= 12.9 && lat <= 13.1 && lng >= 77.4 && lng <= 77.8) {
        city = 'Bangalore';
      }
      else if (lat >= 13.0 && lat <= 13.2 && lng >= 80.1 && lng <= 80.3) {
        city = 'Chennai';
      }
      else if (lat >= 22.4 && lat <= 22.7 && lng >= 88.2 && lng <= 88.5) {
        city = 'Kolkata';
      }
      return {'city': city, 'country': 'India'};
    }

    // Saudi Arabia
    if (lat >= 16.0 && lat <= 32.2 && lng >= 34.5 && lng <= 55.7) {
      String city = 'Saudi Arabia';
      if (lat >= 21.3 && lat <= 21.5 && lng >= 39.7 && lng <= 39.9) {
        city = 'Makkah';
      } else if (lat >= 24.4 && lat <= 24.6 && lng >= 39.5 && lng <= 39.7) {
        city = 'Madinah';
      }
      else if (lat >= 24.6 && lat <= 24.8 && lng >= 46.6 && lng <= 46.8) {
        city = 'Riyadh';
      }
      else if (lat >= 21.4 && lat <= 21.6 && lng >= 39.1 && lng <= 39.3) {
        city = 'Jeddah';
      }
      return {'city': city, 'country': 'Saudi Arabia'};
    }

    // UAE
    if (lat >= 22.6 && lat <= 26.1 && lng >= 51.5 && lng <= 56.4) {
      String city = 'UAE';
      if (lat >= 25.0 && lat <= 25.4 && lng >= 55.1 && lng <= 55.4) {
        city = 'Dubai';
      } else if (lat >= 24.3 && lat <= 24.6 && lng >= 54.3 && lng <= 54.6) {
        city = 'Abu Dhabi';
      }
      return {'city': city, 'country': 'UAE'};
    }

    // Bangladesh
    if (lat >= 20.5 && lat <= 26.7 && lng >= 88.0 && lng <= 92.7) {
      String city = 'Bangladesh';
      if (lat >= 23.7 && lat <= 23.9 && lng >= 90.3 && lng <= 90.5) {
        city = 'Dhaka';
      }
      return {'city': city, 'country': 'Bangladesh'};
    }

    // Turkey
    if (lat >= 35.8 && lat <= 42.1 && lng >= 25.7 && lng <= 44.8) {
      String city = 'Turkey';
      if (lat >= 40.9 && lat <= 41.2 && lng >= 28.7 && lng <= 29.3) {
        city = 'Istanbul';
      } else if (lat >= 39.8 && lat <= 40.0 && lng >= 32.7 && lng <= 32.9) {
        city = 'Ankara';
      }
      return {'city': city, 'country': 'Turkey'};
    }

    // Indonesia
    if (lat >= -11.0 && lat <= 6.5 && lng >= 94.5 && lng <= 141.5) {
      String city = 'Indonesia';
      if (lat >= -6.4 && lat <= -6.1 && lng >= 106.6 && lng <= 106.9) {
        city = 'Jakarta';
      }
      return {'city': city, 'country': 'Indonesia'};
    }

    // Malaysia
    if (lat >= 0.8 && lat <= 7.4 && lng >= 99.5 && lng <= 119.3) {
      String city = 'Malaysia';
      if (lat >= 3.0 && lat <= 3.3 && lng >= 101.6 && lng <= 101.8) {
        city = 'Kuala Lumpur';
      }
      return {'city': city, 'country': 'Malaysia'};
    }

    // Egypt
    if (lat >= 22.0 && lat <= 31.7 && lng >= 24.7 && lng <= 36.9) {
      String city = 'Egypt';
      if (lat >= 30.0 && lat <= 30.2 && lng >= 31.2 && lng <= 31.4) {
        city = 'Cairo';
      }
      return {'city': city, 'country': 'Egypt'};
    }

    // Default
    return {'city': 'Unknown', 'country': 'Unknown'};
  }

  // ============================================================
  // CACHE METHODS
  // ============================================================

  static Future<void> _saveToCache({
    required double lat,
    required double lng,
    required double angle,
    required double distance,
    String? city,
    String? country,
    double? altitude,
    double? accuracy,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_kLastLat, lat);
      await prefs.setDouble(_kLastLng, lng);
      await prefs.setDouble(_kLastAngle, angle);
      await prefs.setDouble(_kLastDistance, distance);
      if (city != null) await prefs.setString(_kLastCity, city);
      if (country != null) await prefs.setString(_kLastCountry, country);
      if (altitude != null) await prefs.setDouble(_kLastAltitude, altitude);
      if (accuracy != null) await prefs.setDouble(_kLastAccuracy, accuracy);
      await prefs.setString(_kLastUpdated, DateTime.now().toIso8601String());
    } catch (_) {}
  }

  static Future<QiblaResult> _getFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble(_kLastLat);
      final lng = prefs.getDouble(_kLastLng);
      final angle = prefs.getDouble(_kLastAngle);
      final distance = prefs.getDouble(_kLastDistance);
      final city = prefs.getString(_kLastCity);
      final country = prefs.getString(_kLastCountry);
      final altitude = prefs.getDouble(_kLastAltitude);
      final accuracy = prefs.getDouble(_kLastAccuracy);
      final updatedStr = prefs.getString(_kLastUpdated);
      DateTime? updatedAt;
      if (updatedStr != null) {
        try {
          updatedAt = DateTime.parse(updatedStr);
        } catch (_) {}
      }

      if (lat != null && lng != null && angle != null && distance != null) {
        return QiblaResult(
          qiblaAngle: angle,
          latitude: lat,
          longitude: lng,
          distanceToMakkah: distance,
          city: city,
          country: country,
          altitude: altitude,
          accuracy: accuracy,
          isFromCache: true,
          updatedAt: updatedAt,
        );
      }
    } catch (_) {}

    // SAHI — Dynamic calculate karo:
    const double defaultLat = 24.8607;
    const double defaultLng = 67.0011;

    return QiblaResult(
      qiblaAngle: QiblaCalculator.directionFrom(defaultLat, defaultLng),
      latitude: defaultLat,
      longitude: defaultLng,
      distanceToMakkah:
          QiblaCalculator.distanceToKaabaFrom(defaultLat, defaultLng),
      locationName: 'Default (Karachi)',
      city: 'Karachi',
      country: 'Pakistan',
      isFromCache: true,
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  // P0.7: Approximate magnetic declination (WMM simplified)
  // Real WMM requires heavy model; we use lookup for major Islamic regions
  // and longitude-based heuristic elsewhere. Error ±3° outside table — documented.
  static double _estimateMagneticDeclination(double lat, double lng) {
    // Lookup for major regions (approx 2026 declination)
    if (lat >= 23.6 && lat <= 37.1 && lng >= 60.9 && lng <= 77.9) {
      // Pakistan: +1 to +2°
      return 1.5;
    }
    if (lat >= 8.0 && lat <= 37.0 && lng >= 68.0 && lng <= 97.5) {
      // India: -1 to +2° (varies west->east)
      if (lng < 75) return 0.5;
      if (lng < 85) return -0.5;
      return -1.0;
    }
    if (lat >= 16.0 && lat <= 32.2 && lng >= 34.5 && lng <= 55.7) {
      // Saudi: +2 to +4°
      return 3.0;
    }
    if (lat >= 22.6 && lat <= 26.1 && lng >= 51.5 && lng <= 56.4) {
      return 1.0; // UAE
    }
    if (lat >= 20.5 && lat <= 26.7 && lng >= 88.0 && lng <= 92.7) {
      return 0.0; // BD
    }
    if (lat >= 35.8 && lat <= 42.1 && lng >= 25.7 && lng <= 44.8) {
      return 5.0; // Turkey
    }
    if (lat >= -11.0 && lat <= 6.5 && lng >= 94.5 && lng <= 141.5) {
      return 0.5; // Indo
    }
    if (lat >= 0.8 && lat <= 7.4 && lng >= 99.5 && lng <= 119.3) {
      return 0.0; // My
    }
    if (lat >= 22.0 && lat <= 31.7 && lng >= 24.7 && lng <= 36.9) {
      return 3.5; // Egypt
    }
    // Europe
    if (lat >= 35 && lat <= 72 && lng >= -25 && lng <= 40) {
      // UK +5 to -5, Central Europe 2-5
      if (lng < 0) return -2.0; // UK west
      if (lng < 10) return 2.0;
      return 4.0;
    }
    // North America
    if (lat >= 25 && lat <= 49 && lng >= -125 && lng <= -66) {
      // US: -10 (west) to +10 (east)
      if (lng < -100) return 10.0;
      if (lng < -80) return -5.0;
      return -10.0;
    }
    // Default longitude heuristic: decl ~ (lng - 0) * 0.1 clamped
    final est = (lng / 10.0).clamp(-15.0, 15.0);
    return est;
  }

  static String _declinationNote(double decl, double lat, double lng) {
    if (decl.abs() < 2) {
      return 'Magnetic declination small (${decl.toStringAsFixed(1)}°) — magnetic ≈ true north. Compass should be accurate when calibrated.';
    }
    if (decl.abs() < 5) {
      return 'Magnetic declination ${decl.toStringAsFixed(1)}° — add ${decl > 0 ? '+' : ''}${decl.toStringAsFixed(1)}° to magnetic heading for true north. Calibrate compass in figure-8.';
    }
    return 'Magnetic declination ${decl.toStringAsFixed(1)}° — significant. Use true north correction and calibrate compass. For precise prayer, verify with local mosque.';
  }

  static String formatDistance(double km) {
    final rounded = km.round();
    final str = rounded.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < str.length; i++) {
      if (i > 0 && (str.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(str[i]);
    }
    return '${buffer.toString()} km';
  }
}
