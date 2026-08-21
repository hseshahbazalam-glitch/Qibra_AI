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

            String? _cleanTime(Object? v) {
              if (v == null) return null;
              final s = v.toString().trim();
              if (s.isEmpty) return null;
              // OSM prayer_times often like "05:15"; normalize to "hh:mm AM/PM".
              final m = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(s);
              if (m == null) return s;
              var h = int.parse(m.group(1)!);
              final min = m.group(2)!;
              final period = h < 12 ? 'AM' : 'PM';
              if (h == 0) h = 12;
              if (h > 12) h -= 12;
              return '${h.toString().padLeft(2, '0')}:$min $period';
            }

            liveList.add(
              Mosque(
                id: el['id'].toString(),
                name: name.toString(),
                arabicName: arabicName.toString(),
                address: street.toString(),
                latitude: lat,
                longitude: lon,
                distanceKm: dist,
                rating:
                    double.tryParse(tags['rating']?.toString() ?? '') ?? 4.7,
                // OSM doesn't always tag wudu/female explicitly. Default true
                // only when tag is absent; an explicit 'no' tag is respected.
                hasWuduArea: (tags['wudu'] as String? ?? 'yes') != 'no',
                hasParking: (tags['parking'] as String? ?? 'yes') != 'no',
                hasWomenSection: (tags['female'] as String? ?? 'yes') != 'no',
                isWheelchairAccessible:
                    (tags['wheelchair'] as String? ?? 'yes') != 'no',
                // Jama'at timetable from OSM prayer_times tags when present.
                fajrJamaat: _cleanTime(tags['prayer:fajr'] ?? tags['fajr']),
                dhuhrJamaat:
                    _cleanTime(tags['prayer:dhuhr'] ?? tags['dhuhr']),
                asrJamaat: _cleanTime(tags['prayer:asr'] ?? tags['asr']),
                maghribJamaat:
                    _cleanTime(tags['prayer:maghrib'] ?? tags['maghrib']),
                ishaJamaat: _cleanTime(tags['prayer:isha'] ?? tags['isha']),
                jummahJamaat: _cleanTime(
                    tags['prayer:jummah'] ?? tags['jummah'] ?? tags['jumma']),
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
