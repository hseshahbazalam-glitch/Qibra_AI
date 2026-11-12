part of 'hijri.dart';

// Civil/tabular Hijri helper. Not moon-sighting. Not authoritative for
// Ramadan or Eid. The `hijri` package (UI) is the same class of conversion.

class HijriCivil {
  const HijriCivil._();

  static const source = 'tabular/civil (hijri package on device)';
  static const authoritativeMoonSighting = false;

  /// Local civil calendar date for [utc] in [offset].
  ///
  /// This only applies a KNOWN offset — the IANA conversion that used to be
  /// documented here as living in `TimezoneEngine` is not part of this class
  /// (and PASS X3 deleted that unwired engine: the app calls
  /// `initializeTimeZones()` + `tz.TZDateTime` directly).
  static DateTime civilDate({
    required DateTime utc,
    required Duration offset,
  }) {
    final local = utc.toUtc().add(offset);
    return DateTime(local.year, local.month, local.day);
  }
}
