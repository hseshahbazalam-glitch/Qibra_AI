# Phase 8 audit — Notification & background reliability

**Date:** 2026-08-30  
**Branch:** `arena/01a049e4-qibra-ai`  
**Actual HEAD at audit start:** `0b1bb52`  
**Requested Phase 7 `89201e4`:** not in this checkout. No reset.

**Verdict: NOT APPROVED.** Local `flutter_local_notifications` exists. Exact-alarm and reboot-proof delivery are **not** device-tested. Flutter SDK **NOT RUN**. Android/iOS devices **NOT RUN**.

This file was written **before** Phase 8 wiring. Do not restyle Settings/Home. Do not rewrite prayer math. Phase 6 licenses stay UNKNOWN / REQUIRES_PERMISSION / DO_NOT_DISTRIBUTE.

---

## 1. Current notification architecture

`NotificationService` (`lib/core/services/notification_service.dart`) is a singleton wrapping `flutter_local_notifications`. Channels: azan, pre-prayer, islamic, tahajjud. Initialized from `main.dart` (failure is swallowed). `azanSchedulerProvider` in `prayer_provider.dart` calls `schedulePrayerNotifications` when daily times exist.

`NotificationReconcile` only filters `when.isAfter(now)`. **Not** idempotent vs an existing set.

## 2. Current scheduling mechanism

`zonedSchedule` + `AndroidScheduleMode.inexactAllowWhileIdle`. Fixed IDs 1001–1005 / 2001–2005. Cancel-all-prayer then re-add. Uses `tz.local` (device zone), not necessarily the prayer IANA from Phase 7.

## 3. Platform limitations

No WorkManager / android_alarm_manager / background_fetch in `pubspec.yaml`. iOS `Info.plist` has **no** `UIBackgroundModes`. OEM battery killers can drop inexact alarms. **Not reboot-proof.**

## 4. Permission handling

`requestPermission()` returns Android bool; iOS result ignored. No denied-forever / not-determined / unsupported mapping. App continues if init fails.

## 5–8. Timezone / DST / midnight / reboot

Timezone: `tz.local` in scheduler vs location IANA in prayer calc — **risk**. DST untested on device. Midnight wrap exists in Phase 7 next-prayer, not in notification IDs (IDs are constant so yesterday’s cancel depends on `time.isBefore(now)`). Reboot: `ScheduledNotificationBootReceiver` + `RECEIVE_BOOT_COMPLETED` present; **NOT RUN** on hardware. Do not claim restore works.

## 9. App-update behavior

`MY_PACKAGE_REPLACED` on boot receiver. Untested.

## 10–12. Battery / exact alarm / iOS

`SCHEDULE_EXACT_ALARM` is in the manifest but the scheduler is **inexact**. Extra permission. Previous contract: do **not** use `USE_EXACT_ALARM`. iOS: no background fetch; OS may defer local notifications.

## 13–16. Duplicate / stale / recalc / location

Cancel-then-schedule can race. Fixed IDs prevent two Fajrs *if* cancel succeeds. Location change reschedules only if `dailyPrayerTimesProvider` rebuilds. GPS must not go to Qibra API (Phase 7).

## 17. What this environment can test

Python unit tests for ID stability, reconcile idempotency, DST/midnight/location/settings fingerprints, permission mapping, disabled notifications, calc-failure → empty schedule. Flutter tests **NOT RUN** (no SDK). No emulator/device.

## 18. Production blockers

No device reboot test. Inexact alarms. `tz.local` vs IANA. Adhan `azan_makkah.mp3` has **no in-repo license** → UNKNOWN, not VERIFIED. `SCHEDULE_EXACT_ALARM` unused. Health `notifications_local_only: true`.

## Planned edits (after this audit)

Deterministic IDs + idempotent reconcile; persist last slots **without** lat/lng; permission enum; drop unused `SCHEDULE_EXACT_ALARM`; keep inexact; honest docs. No UI redesign. No live adhan claim.
