// Local-only notification reconcile. Exact alarms are not requested.
// IDs are deterministic. Reconcile is idempotent. No GPS in payloads.

import 'dart:convert';

enum NotificationPermissionStatus {
  granted,
  denied,
  deniedForever,
  notDetermined,
  unsupported,
}

enum NotificationKind { prayer, pre }

class NotificationPolicy {
  const NotificationPolicy({
    this.prayerAlertsEnabled = true,
    this.preMinutes = 0,
    this.includeSunrise = false,
  });

  final bool prayerAlertsEnabled;
  final int preMinutes;
  final bool includeSunrise;

  String get fingerprint =>
      'prayer=${prayerAlertsEnabled ? 1 : 0}|pre=$preMinutes|sun=${includeSunrise ? 1 : 0}';
}

class ScheduledPrayerAlert {
  const ScheduledPrayerAlert({
    required this.id,
    required this.name,
    required this.when,
    this.kind = NotificationKind.prayer,
    this.timezone = 'UNKNOWN',
  });

  final int id;
  final String name;
  final DateTime when;
  final NotificationKind kind;
  final String timezone;
}

class ReconcilePlan {
  const ReconcilePlan({
    required this.create,
    required this.cancelIds,
    required this.keepIds,
  });

  final List<ScheduledPrayerAlert> create;
  final Set<int> cancelIds;
  final Set<int> keepIds;

  List<int> get resultingIds {
    final ids = {...keepIds, ...create.map((a) => a.id)};
    return ids.toList()..sort();
  }
}

class NotificationReconcile {
  const NotificationReconcile();

  /// Exact alarm permission is never requested. Inexact scheduling is enough.
  bool get requestsExactAlarm => false;

  static const obligatory = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

  static int stableId(String input) {
    var hash = 2166136261;
    for (final b in utf8.encode(input)) {
      hash ^= b;
      hash = (hash * 16777619) & 0xFFFFFFFF;
    }
    final v = hash & 0x7FFFFFFF;
    return v == 0 ? 1 : v;
  }

  /// Location key is a catalog city or rounded coords — never raw GPS in payload.
  static int alertId({
    required String prayer,
    required String localDate,
    required String timezone,
    required String locationKey,
    required String settingsKey,
    required String hhmm,
    NotificationKind kind = NotificationKind.prayer,
  }) {
    return stableId(
      '$prayer|$localDate|$timezone|$locationKey|$settingsKey|$hhmm|${kind.name}',
    );
  }

  static String hhmm(DateTime when) =>
      '${when.hour.toString().padLeft(2, '0')}:${when.minute.toString().padLeft(2, '0')}';

  static String localDate(DateTime when) =>
      '${when.year.toString().padLeft(4, '0')}-${when.month.toString().padLeft(2, '0')}-${when.day.toString().padLeft(2, '0')}';

  List<ScheduledPrayerAlert> desired({
    required Map<String, DateTime> times,
    required DateTime now,
    required NotificationPolicy policy,
    required String timezone,
    required String locationKey,
    NotificationPermissionStatus permission = NotificationPermissionStatus.granted,
  }) {
    if (!policy.prayerAlertsEnabled) return const [];
    if (permission == NotificationPermissionStatus.denied ||
        permission == NotificationPermissionStatus.deniedForever ||
        permission == NotificationPermissionStatus.unsupported) {
      return const [];
    }
    if (timezone.isEmpty || timezone == 'UNKNOWN') return const [];

    final names = [
      ...obligatory,
      if (policy.includeSunrise) 'Sunrise',
    ];
    final out = <ScheduledPrayerAlert>[];
    final settingsKey = policy.fingerprint;
    for (final name in names) {
      final when = times[name];
      if (when == null) continue;
      if (!when.isAfter(now)) continue;
      out.add(
        ScheduledPrayerAlert(
          id: alertId(
            prayer: name,
            localDate: localDate(when),
            timezone: timezone,
            locationKey: locationKey,
            settingsKey: settingsKey,
            hhmm: hhmm(when),
          ),
          name: name,
          when: when,
          timezone: timezone,
        ),
      );
      if (policy.preMinutes > 0) {
        final pre = when.subtract(Duration(minutes: policy.preMinutes));
        if (pre.isAfter(now)) {
          out.add(
            ScheduledPrayerAlert(
              id: alertId(
                prayer: name,
                localDate: localDate(when),
                timezone: timezone,
                locationKey: locationKey,
                settingsKey: settingsKey,
                hhmm: hhmm(when),
                kind: NotificationKind.pre,
              ),
              name: name,
              when: pre,
              kind: NotificationKind.pre,
              timezone: timezone,
            ),
          );
        }
      }
    }
    out.sort((a, b) => a.when.compareTo(b.when));
    return out;
  }

  ReconcilePlan plan({
    required List<ScheduledPrayerAlert> desired,
    required Iterable<int> existingIds,
  }) {
    final want = {for (final a in desired) a.id};
    final have = existingIds.toSet();
    final cancel = have.difference(want);
    final keep = have.intersection(want);
    final create = desired.where((a) => !have.contains(a.id)).toList();
    return ReconcilePlan(create: create, cancelIds: cancel, keepIds: keep);
  }

  /// Convenience used by tests: filter future alerts (legacy API).
  List<ScheduledPrayerAlert> reconcile({
    required List<ScheduledPrayerAlert> desired,
    required DateTime now,
  }) {
    return desired.where((a) => a.when.isAfter(now)).toList()
      ..sort((a, b) => a.when.compareTo(b.when));
  }

  static NotificationPermissionStatus parsePermission(String raw) {
    switch (raw) {
      case 'granted':
        return NotificationPermissionStatus.granted;
      case 'denied':
        return NotificationPermissionStatus.denied;
      case 'deniedForever':
      case 'permanentlyDenied':
      case 'restricted':
        return NotificationPermissionStatus.deniedForever;
      case 'notDetermined':
        return NotificationPermissionStatus.notDetermined;
      default:
        return NotificationPermissionStatus.unsupported;
    }
  }
}
