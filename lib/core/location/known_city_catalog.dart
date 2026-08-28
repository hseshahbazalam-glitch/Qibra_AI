// Known-city catalog. GPS must not invent city names.

class KnownCity {
  const KnownCity({
    required this.name,
    required this.country,
    required this.countryCode,
    required this.latitude,
    required this.longitude,
    required this.timezone,
    this.radiusKm = 25,
  });

  final String name;
  final String country;
  final String countryCode;
  final double latitude;
  final double longitude;
  final String timezone;
  final double radiusKm;
}

abstract final class KnownCityCatalog {
  static const List<KnownCity> cities = [
    KnownCity(name: 'Makkah', country: 'Saudi Arabia', countryCode: 'SA', latitude: 21.3891, longitude: 39.8579, timezone: 'Asia/Riyadh'),
    KnownCity(name: 'Madinah', country: 'Saudi Arabia', countryCode: 'SA', latitude: 24.5247, longitude: 39.5692, timezone: 'Asia/Riyadh'),
    KnownCity(name: 'Riyadh', country: 'Saudi Arabia', countryCode: 'SA', latitude: 24.7136, longitude: 46.6753, timezone: 'Asia/Riyadh'),
    KnownCity(name: 'Jeddah', country: 'Saudi Arabia', countryCode: 'SA', latitude: 21.4858, longitude: 39.1925, timezone: 'Asia/Riyadh'),
    KnownCity(name: 'Karachi', country: 'Pakistan', countryCode: 'PK', latitude: 24.8607, longitude: 67.0011, timezone: 'Asia/Karachi'),
    KnownCity(name: 'Lahore', country: 'Pakistan', countryCode: 'PK', latitude: 31.5204, longitude: 74.3587, timezone: 'Asia/Karachi'),
    KnownCity(name: 'Islamabad', country: 'Pakistan', countryCode: 'PK', latitude: 33.6844, longitude: 73.0479, timezone: 'Asia/Karachi'),
    KnownCity(name: 'Peshawar', country: 'Pakistan', countryCode: 'PK', latitude: 34.0151, longitude: 71.5249, timezone: 'Asia/Karachi'),
    KnownCity(name: 'Delhi', country: 'India', countryCode: 'IN', latitude: 28.6139, longitude: 77.2090, timezone: 'Asia/Kolkata'),
    KnownCity(name: 'Mumbai', country: 'India', countryCode: 'IN', latitude: 19.0760, longitude: 72.8777, timezone: 'Asia/Kolkata'),
    KnownCity(name: 'Dhaka', country: 'Bangladesh', countryCode: 'BD', latitude: 23.8103, longitude: 90.4125, timezone: 'Asia/Dhaka'),
    KnownCity(name: 'Dubai', country: 'United Arab Emirates', countryCode: 'AE', latitude: 25.2048, longitude: 55.2708, timezone: 'Asia/Dubai'),
    KnownCity(name: 'Abu Dhabi', country: 'United Arab Emirates', countryCode: 'AE', latitude: 24.4539, longitude: 54.3773, timezone: 'Asia/Dubai'),
    KnownCity(name: 'Istanbul', country: 'Turkey', countryCode: 'TR', latitude: 41.0082, longitude: 28.9784, timezone: 'Europe/Istanbul'),
    KnownCity(name: 'Ankara', country: 'Turkey', countryCode: 'TR', latitude: 39.9334, longitude: 32.8597, timezone: 'Europe/Istanbul'),
    KnownCity(name: 'Cairo', country: 'Egypt', countryCode: 'EG', latitude: 30.0444, longitude: 31.2357, timezone: 'Africa/Cairo'),
    KnownCity(name: 'Jakarta', country: 'Indonesia', countryCode: 'ID', latitude: -6.2088, longitude: 106.8456, timezone: 'Asia/Jakarta'),
    KnownCity(name: 'Kuala Lumpur', country: 'Malaysia', countryCode: 'MY', latitude: 3.1390, longitude: 101.6869, timezone: 'Asia/Kuala_Lumpur'),
    KnownCity(name: 'London', country: 'United Kingdom', countryCode: 'GB', latitude: 51.5074, longitude: -0.1278, timezone: 'Europe/London'),
    KnownCity(name: 'New York', country: 'United States', countryCode: 'US', latitude: 40.7128, longitude: -74.0060, timezone: 'America/New_York'),
  ];

  static KnownCity? nearest(double lat, double lng, {double maxKm = 40}) {
    KnownCity? best;
    var bestKm = maxKm;
    for (final city in cities) {
      final d = _haversineKm(lat, lng, city.latitude, city.longitude);
      final limit = city.radiusKm < maxKm ? city.radiusKm : maxKm;
      if (d <= limit && d < bestKm) {
        best = city;
        bestKm = d;
      }
    }
    return best;
  }

  static double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371.0;
    final dLat = _rad(lat2 - lat1);
    final dLon = _rad(lon2 - lon1);
    final a = _sin2(dLat / 2) +
        _cos(_rad(lat1)) * _cos(_rad(lat2)) * _sin2(dLon / 2);
    return r * 2 * _atan2(_sqrt(a), _sqrt(1 - a));
  }

  static double _rad(double d) => d * 3.141592653589793 / 180;
  static double _sin2(double x) {
    final s = _sin(x);
    return s * s;
  }

  static double _sin(double x) {
    // Enough precision for city matching.
    var t = x;
    while (t > 3.141592653589793) {
      t -= 6.283185307179586;
    }
    while (t < -3.141592653589793) {
      t += 6.283185307179586;
    }
    final t2 = t * t;
    return t * (1 - t2 / 6 + t2 * t2 / 120);
  }

  static double _cos(double x) {
    final s = _sin(x + 1.5707963267948966);
    return s;
  }

  static double _sqrt(double x) {
    if (x <= 0) return 0;
    var g = x;
    for (var i = 0; i < 12; i++) {
      g = 0.5 * (g + x / g);
    }
    return g;
  }

  static double _atan2(double y, double x) {
    if (x > 0) return _atan(y / x);
    if (x < 0 && y >= 0) return _atan(y / x) + 3.141592653589793;
    if (x < 0 && y < 0) return _atan(y / x) - 3.141592653589793;
    if (x == 0 && y > 0) return 1.5707963267948966;
    if (x == 0 && y < 0) return -1.5707963267948966;
    return 0;
  }

  static double _atan(double z) {
    final az = z.abs();
    final a = az > 1 ? 1 / az : az;
    final a2 = a * a;
    var r = a * (1 - a2 / 3 + a2 * a2 / 5 - a2 * a2 * a2 / 7);
    if (az > 1) r = 1.5707963267948966 - r;
    return z < 0 ? -r : r;
  }
}
