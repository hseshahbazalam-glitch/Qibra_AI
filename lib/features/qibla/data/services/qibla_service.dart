// lib/features/qibla/data/services/qibla_service.dart

// ============================================================
// QIBRA AI — QIBLA SERVICE
// GPS-based Qibla direction calculator
// ============================================================

import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ============================================================
// QIBLA RESULT MODEL
// ============================================================

class QiblaResult {
  final double qiblaAngle; // Degrees from North
  final double latitude;
  final double longitude;
  final double distanceToMakkah; // in km
  final String locationName;
  final bool isFromCache;

  const QiblaResult({
    required this.qiblaAngle,
    required this.latitude,
    required this.longitude,
    required this.distanceToMakkah,
    this.locationName = '',
    this.isFromCache = false,
  });
}

// ============================================================
// QIBLA SERVICE
// ============================================================

class QiblaService {
  QiblaService._();

  // Makkah coordinates
  static const double _makkahLat = 21.4225;
  static const double _makkahLng = 39.8262;

  // SharedPreferences keys
  static const _kLastLat = 'qibla_last_lat';
  static const _kLastLng = 'qibla_last_lng';
  static const _kLastAngle = 'qibla_last_angle';
  static const _kLastDistance = 'qibla_last_distance';

  // ============================================================
  // GET QIBLA DIRECTION
  // ============================================================

  static Future<QiblaResult> getQiblaDirection() async {
    try {
      // Check location permission
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

      // Check if location service enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return await _getFromCache();
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      // Calculate Qibla
      final angle = _calculateQiblaAngle(
        position.latitude,
        position.longitude,
      );

      final distance = _calculateDistance(
        position.latitude,
        position.longitude,
        _makkahLat,
        _makkahLng,
      );

      // Save to cache
      await _saveToCache(
        position.latitude,
        position.longitude,
        angle,
        distance,
      );

      return QiblaResult(
        qiblaAngle: angle,
        latitude: position.latitude,
        longitude: position.longitude,
        distanceToMakkah: distance,
        isFromCache: false,
      );
    } catch (e) {
      return await _getFromCache();
    }
  }

  // ============================================================
  // CALCULATE QIBLA ANGLE
  // Using spherical trigonometry
  // ============================================================

  static double _calculateQiblaAngle(double lat, double lng) {
    final double latRad = _toRad(lat);
    final double lngRad = _toRad(lng);
    final double makkahLatRad = _toRad(_makkahLat);
    final double makkahLngRad = _toRad(_makkahLng);

    final double dLng = makkahLngRad - lngRad;

    final double y = math.sin(dLng) * math.cos(makkahLatRad);
    final double x = math.cos(latRad) * math.sin(makkahLatRad) -
        math.sin(latRad) * math.cos(makkahLatRad) * math.cos(dLng);

    double bearing = math.atan2(y, x);
    bearing = _toDeg(bearing);
    bearing = (bearing + 360) % 360;

    return bearing;
  }

  // ============================================================
  // CALCULATE DISTANCE TO MAKKAH (Haversine formula)
  // ============================================================

  static double _calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const double earthRadius = 6371; // km

    final double dLat = _toRad(lat2 - lat1);
    final double dLng = _toRad(lng2 - lng1);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRad(lat1)) *
            math.cos(_toRad(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  // ============================================================
  // CACHE METHODS
  // ============================================================

  static Future<void> _saveToCache(
    double lat,
    double lng,
    double angle,
    double distance,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_kLastLat, lat);
      await prefs.setDouble(_kLastLng, lng);
      await prefs.setDouble(_kLastAngle, angle);
      await prefs.setDouble(_kLastDistance, distance);
    } catch (_) {}
  }

  static Future<QiblaResult> _getFromCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble(_kLastLat);
      final lng = prefs.getDouble(_kLastLng);
      final angle = prefs.getDouble(_kLastAngle);
      final distance = prefs.getDouble(_kLastDistance);

      if (lat != null && lng != null && angle != null && distance != null) {
        return QiblaResult(
          qiblaAngle: angle,
          latitude: lat,
          longitude: lng,
          distanceToMakkah: distance,
          isFromCache: true,
        );
      }
    } catch (_) {}

    // Default — Karachi ke liye
    return const QiblaResult(
      qiblaAngle: 292.0,
      latitude: 24.8607,
      longitude: 67.0011,
      distanceToMakkah: 4524,
      locationName: 'Default (Karachi)',
      isFromCache: true,
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  static double _toRad(double deg) => deg * math.pi / 180;
  static double _toDeg(double rad) => rad * 180 / math.pi;

  // Format distance - proper km display
  // Format distance — proper km display
  static String formatDistance(double km) {
    final rounded = km.round();
    // Add commas for thousands
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
