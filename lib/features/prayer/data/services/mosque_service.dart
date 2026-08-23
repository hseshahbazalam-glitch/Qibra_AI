// lib/features/prayer/data/services/mosque_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/mosque_model.dart';

/// Nearby mosques from OpenStreetMap Overpass.
/// Missing OSM tags stay empty / false — never invent jamaat, ratings, or amenities.
class MosqueService {
  MosqueService._();
  static final MosqueService instance = MosqueService._();

  Future<List<Mosque>> getNearbyMosques({
    required double latitude,
    required double longitude,
    double radiusMeters = 5000,
  }) async {
    try {
      final overpassQuery = '''
[out:json][timeout:10];
(
  node["amenity"="place_of_worship"]["religion"="muslim"](around:$radiusMeters,$latitude,$longitude);
  way["amenity"="place_of_worship"]["religion"="muslim"](around:$radiusMeters,$latitude,$longitude);
);
out center;
''';

      final url = Uri.parse(
        'https://overpass-api.de/api/interpreter?data=${Uri.encodeComponent(overpassQuery)}',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        debugPrint('[MOSQUE_SERVICE] Overpass HTTP ${response.statusCode}');
        return const [];
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final elements = data['elements'] as List<dynamic>? ?? [];
      final liveList = <Mosque>[];

      for (final el in elements) {
        if (el is! Map<String, dynamic>) continue;
        final tags = (el['tags'] as Map<String, dynamic>?) ?? const {};
        final lat = _asDouble(el['lat'] ?? (el['center'] is Map ? el['center']['lat'] : null));
        final lon = _asDouble(el['lon'] ?? (el['center'] is Map ? el['center']['lon'] : null));
        if (lat == null || lon == null) continue;

        liveList.add(
          Mosque(
            id: el['id']?.toString() ?? '${lat}_$lon',
            name: _name(tags),
            arabicName: tags['name:ar']?.toString() ?? '',
            address: _address(tags),
            latitude: lat,
            longitude: lon,
            distanceKm: Mosque.calculateDistance(latitude, longitude, lat, lon),
            rating: _rating(tags['rating']),
            hasWuduArea: _osmYes(tags['wudu']),
            hasParking: _osmYes(tags['parking']),
            hasWomenSection: _osmYes(tags['female']),
            isWheelchairAccessible: _osmYes(tags['wheelchair']),
            fajrJamaat: _cleanTime(tags['prayer:fajr'] ?? tags['fajr']),
            dhuhrJamaat: _cleanTime(tags['prayer:dhuhr'] ?? tags['dhuhr']),
            asrJamaat: _cleanTime(tags['prayer:asr'] ?? tags['asr']),
            maghribJamaat: _cleanTime(tags['prayer:maghrib'] ?? tags['maghrib']),
            ishaJamaat: _cleanTime(tags['prayer:isha'] ?? tags['isha']),
            jummahJamaat: _cleanTime(
              tags['prayer:jummah'] ?? tags['jummah'] ?? tags['jumma'],
            ),
            phone: tags['phone']?.toString() ?? tags['contact:phone']?.toString(),
          ),
        );
      }

      liveList.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
      return liveList;
    } catch (e) {
      debugPrint('[MOSQUE_SERVICE] Overpass error: $e');
      return const [];
    }
  }

  static double? _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static String _name(Map<String, dynamic> tags) {
    final raw = tags['name'] ?? tags['name:en'] ?? tags['name:ar'];
    final name = raw?.toString().trim() ?? '';
    return name.isEmpty ? 'Unnamed mosque' : name;
  }

  static String _address(Map<String, dynamic> tags) {
    final parts = <String>[
      if (tags['addr:housenumber'] != null) tags['addr:housenumber'].toString(),
      if (tags['addr:street'] != null) tags['addr:street'].toString(),
      if (tags['addr:suburb'] != null) tags['addr:suburb'].toString(),
      if (tags['addr:neighbourhood'] != null)
        tags['addr:neighbourhood'].toString(),
      if (tags['addr:city'] != null) tags['addr:city'].toString(),
    ]
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    return parts.join(', ');
  }

  static double _rating(Object? value) {
    if (value == null) return 0;
    return double.tryParse(value.toString()) ?? 0;
  }

  static bool _osmYes(Object? value) {
    if (value == null) return false;
    final tag = value.toString().trim().toLowerCase();
    return tag == 'yes' || tag == 'true' || tag == 'limited' || tag == 'designated';
  }

  static String? _cleanTime(Object? value) {
    if (value == null) return null;
    final raw = value.toString().trim();
    if (raw.isEmpty) return null;
    final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(raw);
    if (match == null) return raw;
    var hour = int.parse(match.group(1)!);
    final minute = match.group(2)!;
    final period = hour < 12 ? 'AM' : 'PM';
    if (hour == 0) hour = 12;
    if (hour > 12) hour -= 12;
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }
}
