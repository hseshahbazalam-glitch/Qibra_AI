// lib/features/prayer/data/services/mosque_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/mosque_model.dart';

class MosqueService {
  MosqueService._();
  static final MosqueService instance = MosqueService._();

  static const _mockMosques = [
    Mosque(
      id: 'm1',
      name: 'Masjid Al-Falah',
      arabicName: 'مسجد الفلاح',
      address: 'Main Road, Near Central Park',
      latitude: 12.9716,
      longitude: 77.5946,
      distanceKm: 0.4,
      rating: 4.9,
      hasWuduArea: true,
      hasParking: true,
      hasWomenSection: true,
      isWheelchairAccessible: true,
      fajrJamaat: '05:15 AM',
      dhuhrJamaat: '01:15 PM',
      asrJamaat: '04:30 PM',
      maghribJamaat: '06:55 PM',
      ishaJamaat: '08:15 PM',
      jummahJamaat: '01:30 PM',
    ),
    Mosque(
      id: 'm2',
      name: 'Jamia Masjid',
      arabicName: 'الجامع الكبير',
      address: 'City Center, Market Square',
      latitude: 12.9730,
      longitude: 77.5980,
      distanceKm: 0.8,
      rating: 4.8,
      hasWuduArea: true,
      hasParking: true,
      hasWomenSection: false,
      isWheelchairAccessible: true,
      fajrJamaat: '05:20 AM',
      dhuhrJamaat: '01:30 PM',
      asrJamaat: '04:30 PM',
      maghribJamaat: '06:55 PM',
      ishaJamaat: '08:30 PM',
      jummahJamaat: '01:45 PM',
    ),
    Mosque(
      id: 'm3',
      name: 'Masjid Bilal',
      arabicName: 'مسجد بلال',
      address: 'Old Airport Road, 2nd Cross',
      latitude: 12.9650,
      longitude: 77.5900,
      distanceKm: 1.2,
      rating: 4.7,
      hasWuduArea: true,
      hasParking: false,
      hasWomenSection: true,
      isWheelchairAccessible: false,
      fajrJamaat: '05:15 AM',
      dhuhrJamaat: '01:15 PM',
      asrJamaat: '04:15 PM',
      maghribJamaat: '06:52 PM',
      ishaJamaat: '08:15 PM',
      jummahJamaat: '01:30 PM',
    ),
  ];

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

      final url = Uri.parse('https://overpass-api.de/api/interpreter?data=${Uri.encodeComponent(overpassQuery)}');
      final response = await http.get(url).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final elements = data['elements'] as List<dynamic>? ?? [];

        if (elements.isNotEmpty) {
          final liveList = <Mosque>[];
          for (final el in elements) {
            final tags = el['tags'] as Map<String, dynamic>? ?? {};
            final name = tags['name'] ?? tags['name:en'] ?? 'Masjid';
            final arabicName = tags['name:ar'] ?? '';
            final street = tags['addr:street'] ?? 'Nearby Area';
            final lat = (el['lat'] ?? el['center']?['lat'] ?? latitude) as double;
            final lon = (el['lon'] ?? el['center']?['lon'] ?? longitude) as double;
            final dist = Mosque.calculateDistance(latitude, longitude, lat, lon);

            liveList.add(
              Mosque(
                id: el['id'].toString(),
                name: name.toString(),
                arabicName: arabicName.toString(),
                address: street.toString(),
                latitude: lat,
                longitude: lon,
                distanceKm: dist,
                hasWuduArea: tags['wudu'] == 'yes' || true,
                hasParking: tags['parking'] != 'no',
                hasWomenSection: tags['female'] == 'yes' || true,
                isWheelchairAccessible: tags['wheelchair'] != 'no',
              ),
            );
          }
          liveList.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
          return liveList;
        }
      }
    } catch (e) {
      debugPrint('[MOSQUE_SERVICE] Overpass fallback: $e');
    }

    return _mockMosques
        .map((m) => m.copyWithDistance(latitude, longitude))
        .toList()
      ..sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
  }
}
