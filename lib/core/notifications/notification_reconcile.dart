// Local-only notification reconcile. Exact alarms are not requested.

class ScheduledPrayerAlert {
  const ScheduledPrayerAlert({
    required this.id,
    required this.name,
    required this.when,
  });

  final int id;
  final String name;
  final DateTime when;
}

class NotificationReconcile {
  const NotificationReconcile();

  List<ScheduledPrayerAlert> reconcile({
    required List<ScheduledPrayerAlert> desired,
    required DateTime now,
  }) {
    return desired.where((a) => a.when.isAfter(now)).toList()
      ..sort((a, b) => a.when.compareTo(b.when));
  }

  /// Exact alarm permission is never requested. Inexact scheduling is enough.
  bool get requestsExactAlarm => false;
}
