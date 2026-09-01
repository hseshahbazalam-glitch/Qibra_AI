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

  /// Returns parsed HH:MM strings. Invalid payloads yield {}.
  /// Imsak/Sunset are optional and never invented.
  Map<String, String> parseTimings(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    final timings = data['timings'];
    if (timings is! Map) return {};
    final out = <String, String>{};
    for (final key in [
      'Imsak',
      'Fajr',
      'Sunrise',
      'Dhuhr',
      'Asr',
      'Sunset',
      'Maghrib',
      'Isha',
    ]) {
      final raw = timings[key]?.toString() ?? '';
      final hhmm = raw.split(' ').first.trim();
      if (!RegExp(r'^\d{1,2}:\d{2}').hasMatch(hhmm)) continue;
      out[key] = hhmm;
    }
    return out;
  }

  bool get isLiveNetwork => false;
}
