// lib/features/prayer/data/models/mosque_model.dart
import 'dart:math' as math;

class Mosque {
  final String id;
  final String name;
  final String arabicName;
  final String address;
  final double latitude;
  final double longitude;
  final double distanceKm;
  final double rating;
  final int totalReviews;
  final bool hasWuduArea;
  final bool hasParking;
  final bool hasWomenSection;
  final bool isWheelchairAccessible;
  final String? fajrJamaat;
  final String? dhuhrJamaat;
  final String? asrJamaat;
  final String? maghribJamaat;
  final String? ishaJamaat;
  final String? jummahJamaat;
  final String? phone;

  const Mosque({
    required this.id,
    required this.name,
    this.arabicName = '',
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.distanceKm,
    this.rating = 4.8,
    this.totalReviews = 120,
    this.hasWuduArea = true,
    this.hasParking = true,
    this.hasWomenSection = true,
    this.isWheelchairAccessible = true,
    this.fajrJamaat = '05:15 AM',
    this.dhuhrJamaat = '01:15 PM',
    this.asrJamaat = '04:15 PM',
    this.maghribJamaat = '06:55 PM',
    this.ishaJamaat = '08:15 PM',
    this.jummahJamaat = '01:30 PM',
    this.phone,
  });

  String get formattedDistance {
    if (distanceKm < 1.0) {
      final meters = (distanceKm * 1000).round();
      return '$meters m away';
    }
    return '${distanceKm.toStringAsFixed(1)} km away';
  }

  Mosque copyWithDistance(double userLat, double userLng) {
    final dist = calculateDistance(userLat, userLng, latitude, longitude);
    return Mosque(
      id: id,
      name: name,
      arabicName: arabicName,
      address: address,
      latitude: latitude,
      longitude: longitude,
      distanceKm: dist,
      rating: rating,
      totalReviews: totalReviews,
      hasWuduArea: hasWuduArea,
      hasParking: hasParking,
      hasWomenSection: hasWomenSection,
      isWheelchairAccessible: isWheelchairAccessible,
      fajrJamaat: fajrJamaat,
      dhuhrJamaat: dhuhrJamaat,
      asrJamaat: asrJamaat,
      maghribJamaat: maghribJamaat,
      ishaJamaat: ishaJamaat,
      jummahJamaat: jummahJamaat,
      phone: phone,
    );
  }

  static double calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double earthRadiusKm = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _toRadians(double degree) => degree * math.pi / 180;
}
