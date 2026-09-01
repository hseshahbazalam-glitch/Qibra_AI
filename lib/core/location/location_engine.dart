// Location permission + fix model. GPS must not invent city names.
// Precise coordinates are not sent to the Qibra API.

enum LocationFixSource { device, manual, cached }

enum LocationFixStatus {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
  timeout,
  unavailable,
  cached,
}

class LocationFix {
  const LocationFix({
    required this.latitude,
    required this.longitude,
    required this.source,
    required this.status,
    this.city,
    this.country,
    this.countryCode,
    this.timezone,
    this.accuracy,
    this.timestamp,
  });

  final double latitude;
  final double longitude;
  final LocationFixSource source;
  final LocationFixStatus status;
  final String? city;
  final String? country;
  final String? countryCode;
  final String? timezone;
  final double? accuracy;
  final DateTime? timestamp;

  bool get hasNamedCity =>
      city != null && city!.isNotEmpty && city != 'UNKNOWN';

  Map<String, dynamic> toJson() => {
        'latitude': latitude,
        'longitude': longitude,
        'city': city,
        'country': country,
        'countryCode': countryCode,
        'timezone': timezone,
        'accuracy': accuracy,
        'timestamp': timestamp?.toIso8601String(),
        'source': source.name,
        'status': status.name,
      };

  factory LocationFix.fromJson(Map<String, dynamic> json) {
    return LocationFix(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      city: json['city'] as String?,
      country: json['country'] as String?,
      countryCode: json['countryCode'] as String?,
      timezone: json['timezone'] as String?,
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? ''),
      source: LocationFixSource.values.firstWhere(
        (v) => v.name == json['source'],
        orElse: () => LocationFixSource.cached,
      ),
      status: LocationFixStatus.values.firstWhere(
        (v) => v.name == json['status'],
        orElse: () => LocationFixStatus.cached,
      ),
    );
  }
}

abstract final class LocationEngine {
  /// Map geolocator-style permission strings. Unknown stays unavailable.
  static LocationFixStatus fromPermission({
    required bool serviceEnabled,
    required String permission,
    bool timedOut = false,
  }) {
    if (timedOut) return LocationFixStatus.timeout;
    if (!serviceEnabled) return LocationFixStatus.serviceDisabled;
    switch (permission) {
      case 'deniedForever':
      case 'deniedForeverPermission':
        return LocationFixStatus.deniedForever;
      case 'denied':
        return LocationFixStatus.denied;
      case 'whileInUse':
      case 'always':
      case 'granted':
        return LocationFixStatus.granted;
      default:
        return LocationFixStatus.unavailable;
    }
  }
}
