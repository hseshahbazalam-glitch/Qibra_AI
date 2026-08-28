// Prayer source policy: local calculation is primary.
// Aladhan parser exists only as an optional adapter and is not live unless
// already wired. This module does not call the network.

enum PrayerSourceKind { local, aladhanParser, unknown }

class PrayerSource {
  const PrayerSource({
    required this.kind,
    this.note,
  });

  final PrayerSourceKind kind;
  final String? note;

  static const local = PrayerSource(
    kind: PrayerSourceKind.local,
    note: 'Astronomical calculation on device.',
  );

  static const aladhanParserOnly = PrayerSource(
    kind: PrayerSourceKind.aladhanParser,
    note: 'Parser for Aladhan JSON exists but is not a live network source.',
  );
}

class AladhanParser {
  const AladhanParser();

  Map<String, String> parseTimings(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final timings = data['timings'] as Map<String, dynamic>? ?? {};
    final out = <String, String>{};
    for (final key in ['Fajr', 'Sunrise', 'Dhuhr', 'Asr', 'Maghrib', 'Isha']) {
      final raw = timings[key]?.toString();
      if (raw == null || raw.isEmpty) continue;
      out[key] = raw.split(' ').first;
    }
    return out;
  }
}
