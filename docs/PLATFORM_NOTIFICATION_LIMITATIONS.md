# Platform notification limitations

## Android

- `POST_NOTIFICATIONS` required (13+).
- `RECEIVE_BOOT_COMPLETED` + plugin boot receiver — **unverified** restore.
- `WAKE_LOCK` present for the plugin; does not make alarms exact.
- `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM` **not** used. Scheduler is `inexactAllowWhileIdle`.
- OEM battery savers can drop alarms. User may need vendor settings. **No UI redesign in this phase.**
- Adhan file `azan_makkah.mp3` is bundled; **license UNKNOWN**.

## iOS

- No `UIBackgroundModes` for fetch/processing.
- Local notifications only; the OS may defer delivery.
- No unrestricted background execution. Do not pretend otherwise.

## This environment

Flutter SDK **NOT RUN**. No emulator/device. No reboot test. No iOS simulator.
