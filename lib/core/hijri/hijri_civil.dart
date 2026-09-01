// Civil/tabular Hijri helper. Not moon-sighting. Not authoritative for
// Ramadan or Eid. The `hijri` package (UI) is the same class of conversion.

class HijriCivil {
  const HijriCivil._();

  static const source = 'tabular/civil (hijri package on device)';
  static const authoritativeMoonSighting = false;

  /// Local civil calendar date for [utc] in [offset].
  /// IANA conversion lives in TimezoneEngine; this only applies a known offset.
  static DateTime civilDate({
    required DateTime utc,
    required Duration offset,
  }) {
    final local = utc.toUtc().add(offset);
    return DateTime(local.year, local.month, local.day);
  }
}
