// Next-prayer engine with midnight wrap: after Isha, next is tomorrow Fajr.

class NamedPrayerInstant {
  const NamedPrayerInstant({required this.name, required this.time});
  final String name;
  final DateTime time;
}

class NextPrayerResult {
  const NextPrayerResult({
    required this.name,
    required this.time,
    required this.countdown,
    this.isTomorrow = false,
  });

  final String name;
  final DateTime time;
  final Duration countdown;
  final bool isTomorrow;
}

abstract final class NextPrayerEngine {
  static const obligatory = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

  static NextPrayerResult? next({
    required DateTime now,
    required List<NamedPrayerInstant> today,
    NamedPrayerInstant? tomorrowFajr,
  }) {
    final ordered = [...today]
      ..sort((a, b) => a.time.compareTo(b.time));
    for (final p in ordered) {
      if (!obligatory.contains(p.name)) continue;
      if (p.time.isAfter(now)) {
        return NextPrayerResult(
          name: p.name,
          time: p.time,
          countdown: p.time.difference(now),
        );
      }
    }
    if (tomorrowFajr != null) {
      var fajr = tomorrowFajr.time;
      if (!fajr.isAfter(now)) {
        fajr = fajr.add(const Duration(days: 1));
      }
      return NextPrayerResult(
        name: tomorrowFajr.name,
        time: fajr,
        countdown: fajr.difference(now),
        isTomorrow: true,
      );
    }
    return null;
  }
}
