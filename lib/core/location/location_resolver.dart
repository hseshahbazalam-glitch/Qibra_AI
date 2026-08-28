// Resolves GPS coordinates against the known-city catalog.
// Does not invent city names. UNKNOWN stays UNKNOWN.

import 'known_city_catalog.dart';

class ResolvedLocation {
  const ResolvedLocation({
    required this.latitude,
    required this.longitude,
    this.city,
    this.country,
    this.countryCode,
    this.timezone,
  });

  final double latitude;
  final double longitude;
  final String? city;
  final String? country;
  final String? countryCode;
  final String? timezone;

  bool get hasNamedCity => city != null && city!.isNotEmpty && city != 'UNKNOWN';

  String get displayName {
    if (hasNamedCity) {
      if (country != null && country!.isNotEmpty && country != 'UNKNOWN') {
        return '$city, $country';
      }
      return city!;
    }
    return 'UNKNOWN';
  }
}

abstract final class LocationResolver {
  static ResolvedLocation fromCoordinates(double lat, double lng) {
    final city = KnownCityCatalog.nearest(lat, lng);
    if (city == null) {
      return ResolvedLocation(
        latitude: lat,
        longitude: lng,
        city: 'UNKNOWN',
        country: 'UNKNOWN',
      );
    }
    return ResolvedLocation(
      latitude: lat,
      longitude: lng,
      city: city.name,
      country: city.country,
      countryCode: city.countryCode,
      timezone: city.timezone,
    );
  }
}
