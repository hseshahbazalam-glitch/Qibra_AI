// IANA timezone engine. Unknown IANA stays unknown — no invented offsets.

import 'package:timezone/timezone.dart' as tz;

class TimezoneResolution {
  const TimezoneResolution({
    required this.iana,
    required this.offsetHours,
    required this.ok,
    this.note,
  });

  final String iana;
  final double offsetHours;
  final bool ok;
  final String? note;
}

abstract final class TimezoneEngine {
  static TimezoneResolution resolve(String? iana, DateTime date) {
    if (iana == null || iana.isEmpty) {
      return const TimezoneResolution(
        iana: 'UNKNOWN',
        offsetHours: 0,
        ok: false,
        note: 'No IANA timezone provided.',
      );
    }
    try {
      final loc = tz.getLocation(iana);
      final local = tz.TZDateTime(loc, date.year, date.month, date.day, 12);
      return TimezoneResolution(
        iana: iana,
        offsetHours: local.timeZoneOffset.inMinutes / 60.0,
        ok: true,
      );
    } catch (_) {
      return TimezoneResolution(
        iana: iana,
        offsetHours: 0,
        ok: false,
        note: 'IANA timezone "$iana" is unknown.',
      );
    }
  }

  static DateTime toLocal(String iana, DateTime utc) {
    final loc = tz.getLocation(iana);
    return tz.TZDateTime.from(utc, loc);
  }
}
