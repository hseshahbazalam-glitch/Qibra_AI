import 'dart:math' as math;

import '../constants/app_constants.dart';

/// Shared Qibla geometry utilities.
///
/// This is the single calculation path used by both Prayer and Qibla features.
/// Bearings are true-north initial great-circle bearings; distance is Haversine
/// distance in kilometres.
class QiblaCalculator {
  QiblaCalculator._();

  static const double earthRadiusKm = 6371.0;

  /// Returns the true-north bearing (0 <= bearing < 360) from [latitude] and
  /// [longitude] to the Kaaba.
  static double directionFrom(double latitude, double longitude) {
    const kaabaLat = AppIslamicConstants.kaabatullahLatitude;
    const kaabaLng = AppIslamicConstants.kaabatullahLongitude;

    final lat1 = _toRadians(latitude);
    final lat2 = _toRadians(kaabaLat);
    final deltaLongitude = _toRadians(kaabaLng - longitude);

    final y = math.sin(deltaLongitude) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(deltaLongitude);

    return (_toDegrees(math.atan2(y, x)) + 360) % 360;
  }

  /// Returns the Haversine great-circle distance in kilometres from a point
  /// to the Kaaba.
  static double distanceToKaabaFrom(double latitude, double longitude) {
    const kaabaLat = AppIslamicConstants.kaabatullahLatitude;
    const kaabaLng = AppIslamicConstants.kaabatullahLongitude;

    final lat1 = _toRadians(latitude);
    final lat2 = _toRadians(kaabaLat);
    final deltaLatitude = _toRadians(kaabaLat - latitude);
    final deltaLongitude = _toRadians(kaabaLng - longitude);

    final a = math.sin(deltaLatitude / 2) * math.sin(deltaLatitude / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(deltaLongitude / 2) *
            math.sin(deltaLongitude / 2);

    final angularDistance = 2 *
        math.atan2(
          math.sqrt(a),
          math.sqrt(1 - a),
        );

    return earthRadiusKm * angularDistance;
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180;

  static double _toDegrees(double radians) => radians * 180 / math.pi;
}
