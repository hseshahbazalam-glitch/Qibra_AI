# Notification reliability

**Honest status:** implemented in source, covered by unit tests for IDs/reconcile. **Not device-tested. Not reboot-proof. Not production-ready.**

## Idempotency

Running reconcile 1× or 10× with the same desired set yields the same resulting IDs. Create is empty on the second pass.

## What should reschedule

When `dailyPrayerTimesProvider` rebuilds:

| Trigger | Effect |
| --- | --- |
| Settings change | New `settingsKey` → cancel old, create new |
| Location / IANA change | New location/timezone in ID → cancel old |
| Date rollover | Yesterday’s `localDate` not in desired → cancel |
| DST | `hhmm` in the ID changes when wall time changes |
| Permission denied | Desired empty → cancel remaining prayer IDs |
| Calc failure / empty times | Desired empty |
| Offline | Still local; no Qibra API |

Startup: `NotificationService.initialize` does not invent times. Repair happens when prayer times exist.

## Reboot / OEM

Android `ScheduledNotificationBootReceiver` is declared. **NOT RUN** on a device. Do not claim it works.

Battery/OEM (Xiaomi, Huawei, Oppo, …) can delay or drop inexact alarms. No unrestricted background service. No WorkManager in this phase.

## What this environment cannot prove

Flutter SDK **NOT RUN**. No emulator. No iOS simulator. No reboot. No OEM battery test.
