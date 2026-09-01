# Notification architecture

Local-only (`flutter_local_notifications`). The Qibra API does **not** send or store prayer alarms. GPS coordinates are **not** written into notification payloads, SharedPreferences, or observability.

| Piece | Role |
| --- | --- |
| `NotificationReconcile` | Deterministic FNV-1a IDs, desired set, idempotent plan |
| `NotificationPolicy` | Enabled / pre-minutes / sunrise opt-in fingerprint |
| `NotificationService` | Plugin wrapper, inexact `zonedSchedule`, persist last IDs |
| `azanSchedulerProvider` | Calls schedule when daily times exist |
| `backend/app/notifications/reconcile.py` | Same ID + plan rules for Python tests |

## ID fingerprint

`prayer|localDate|IANA|locationKey|settings|hhmm|kind`

- `locationKey` is a catalog city or `UNKNOWN` — **not** lat/lng.
- `settings` is `prayer=1|pre=10|sun=0`.
- `kind` is `prayer` or `pre`.

## Scheduling

- Android mode: `inexactAllowWhileIdle`.
- `requestsExactAlarm == false`.
- `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM` are **not** declared.
- Last IDs stored under `qibra_notif_ids_v1` (integers only).
- Legacy fixed IDs 1001–1005 / 2001–2005 are cancelled on the first reconcile.

## Permissions

Mapped to `granted` | `denied` | `deniedForever` | `notDetermined` | `unsupported`. Denied / denied-forever / unsupported → empty desired set.

## Adhan audio

`assets/audio/azan_makkah.mp3` and Android `res/raw/azan_makkah`. **License UNKNOWN** — not VERIFIED.
