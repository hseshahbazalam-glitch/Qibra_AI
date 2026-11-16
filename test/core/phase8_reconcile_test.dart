import 'package:flutter_test/flutter_test.dart';
import 'package:qibra_ai/core/notifications/notification_reconcile.dart';

void main() {
  const engine = NotificationReconcile();
  final times = {
    'Fajr': DateTime(2026, 8, 28, 5),
    'Sunrise': DateTime(2026, 8, 28, 6, 20),
    'Dhuhr': DateTime(2026, 8, 28, 12, 10),
    'Asr': DateTime(2026, 8, 28, 15, 40),
    'Maghrib': DateTime(2026, 8, 28, 18, 50),
    'Isha': DateTime(2026, 8, 28, 20, 10),
  };

  List<ScheduledPrayerAlert> desired({
    Map<String, DateTime>? t,
    DateTime? now,
    NotificationPolicy policy = const NotificationPolicy(preMinutes: 10),
    String timezone = 'Asia/Karachi',
    String locationKey = 'Karachi',
    NotificationPermissionStatus permission =
        NotificationPermissionStatus.granted,
  }) {
    return engine.desired(
      times: t ?? times,
      now: now ?? DateTime(2026, 8, 28, 4),
      policy: policy,
      timezone: timezone,
      locationKey: locationKey,
      permission: permission,
    );
  }

  test('ids are deterministic and reconcile is idempotent', () {
    expect(engine.requestsExactAlarm, isFalse);
    final a = desired();
    final b = desired();
    expect(a.map((e) => e.id).toList(), b.map((e) => e.id).toList());
    expect(a.map((e) => e.id).toSet().length, a.length);
    final plan1 = engine.plan(desired: a, existingIds: const []);
    final plan2 = engine.plan(desired: a, existingIds: plan1.resultingIds);
    final plan3 = engine.plan(desired: a, existingIds: plan2.resultingIds);
    expect(plan2.create, isEmpty);
    expect(plan3.create, isEmpty);
    expect(plan1.resultingIds, plan3.resultingIds);
  });

  test('denied permission, disabled policy, unknown timezone, empty times', () {
    expect(
      desired(permission: NotificationPermissionStatus.denied),
      isEmpty,
    );
    expect(
      desired(permission: NotificationPermissionStatus.deniedForever),
      isEmpty,
    );
    expect(
      desired(policy: const NotificationPolicy(prayerAlertsEnabled: false)),
      isEmpty,
    );
    expect(desired(timezone: 'UNKNOWN'), isEmpty);
    expect(desired(t: const {}), isEmpty);
  });

  test('location and settings fingerprints cancel stale ids', () {
    final here = desired();
    final there = desired(timezone: 'Asia/Riyadh', locationKey: 'Makkah');
    final loc = engine.plan(
      desired: there,
      existingIds: here.map((e) => e.id),
    );
    expect(loc.keepIds, isEmpty);
    expect(loc.cancelIds, isNotEmpty);

    final settings = desired(
      policy: const NotificationPolicy(preMinutes: 0),
    );
    final setPlan = engine.plan(
      desired: settings,
      existingIds: here.map((e) => e.id),
    );
    expect(setPlan.keepIds, isEmpty);
  });

  test('DST hhmm change produces a different id', () {
    final winter = NotificationReconcile.alertId(
      prayer: 'Dhuhr',
      localDate: '2026-01-15',
      timezone: 'America/New_York',
      locationKey: 'New York',
      settingsKey: 's',
      hhmm: '12:10',
    );
    final summer = NotificationReconcile.alertId(
      prayer: 'Dhuhr',
      localDate: '2026-07-15',
      timezone: 'America/New_York',
      locationKey: 'New York',
      settingsKey: 's',
      hhmm: '13:10',
    );
    expect(winter, isNot(summer));
  });

  test('midnight rollover drops yesterday', () {
    final leftover = desired();
    final todayTimes = {
      for (final e in times.entries) e.key: e.value.add(const Duration(days: 1)),
    };
    final today = desired(t: todayTimes, now: DateTime(2026, 8, 29, 0, 5));
    final plan = engine.plan(
      desired: today,
      existingIds: leftover.map((e) => e.id),
    );
    expect(plan.keepIds, isEmpty);
  });

  test('sunrise is opt-in; pre-alerts use a distinct kind', () {
    final without = desired(
      policy: const NotificationPolicy(preMinutes: 0),
    );
    final withExtras = desired(
      policy: const NotificationPolicy(preMinutes: 10, includeSunrise: true),
    );
    expect(withExtras.length, greaterThan(without.length));
    expect(withExtras.any((a) => a.kind == NotificationKind.pre), isTrue);
    expect(withExtras.any((a) => a.name == 'Sunrise'), isTrue);
    expect(without.any((a) => a.name == 'Sunrise'), isFalse);
  });

  test('legacy filter still drops past alerts', () {
    final kept = engine.reconcile(
      desired: [
        ScheduledPrayerAlert(
          id: 1,
          name: 'Fajr',
          when: DateTime(2026, 8, 28, 3),
        ),
        ScheduledPrayerAlert(
          id: 2,
          name: 'Dhuhr',
          when: DateTime(2026, 8, 28, 12),
        ),
      ],
      now: DateTime(2026, 8, 28, 4),
    );
    expect(kept.map((e) => e.name), ['Dhuhr']);
  });
}
