// lib/core/notifications/dua_reminder_policy.dart
// ============================================================
// QIBRA AI — DUA REMINDER POLICY (P1 · Item 1)
// ============================================================
// Pure, device-free logic behind the per-dua daily reminder:
//   * category/title-derived default time (morning → app Fajr-ish
//     07:00, evening → app Maghrib-ish 17:30, sleep → 22:00),
//   * next-occurrence computation with day rollover,
//   * notification-surface truncation,
//   * the SharedPreferences entry encoding used by NotificationService.
// No plugins, no I/O — unit-testable on the VM. Scheduling itself
// reuses the proven daily custom-time mechanism already in
// NotificationService (zonedSchedule + DateTimeComponents.time),
// the same one behind the Tahajjud and adhkar reminders.

/// A wall-clock reminder time with no date component.
class DuaReminderTime {
  final int hour;
  final int minute;

  const DuaReminderTime(this.hour, this.minute)
      : assert(hour >= 0 && hour <= 23),
        assert(minute >= 0 && minute <= 59);

  /// Next wall-clock occurrence strictly after [now] (today, else +1d).
  DateTime nextOccurrence(DateTime now) {
    var t = DateTime(now.year, now.month, now.day, hour, minute);
    if (!t.isAfter(now)) {
      t = t.add(const Duration(days: 1));
    }
    return t;
  }

  /// Display label such as '07:00 AM' — 12-hour, zero-padded.
  String get label {
    final ampm = hour < 12 ? 'AM' : 'PM';
    final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '${h.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')} $ampm';
  }

  @override
  bool operator ==(Object other) =>
      other is DuaReminderTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() => '$hour|$minute';
}

class DuaReminderPolicy {
  const DuaReminderPolicy._();

  /// Prefs key holding the list of enabled reminders, one per line entry.
  static const String storageKey = 'qibra_dua_reminders_v1';

  /// Max characters kept for the notification title (truncated with '…').
  static const int maxTitleChars = 48;

  /// Max characters kept for the notification body preview.
  static const int maxBodyChars = 90;

  /// Default time derived from the dua's own category id + English title.
  /// Mirrors the app's existing adhkar times so the two systems agree:
  /// morning 07:00, evening 17:30 (both user-changeable on the detail card).
  static DuaReminderTime defaultFor({
    required String category,
    required String titleEnglish,
  }) {
    final title = titleEnglish.toLowerCase();
    if (title.contains('evening')) return const DuaReminderTime(17, 30);
    if (title.contains('morning')) return const DuaReminderTime(7, 0);
    if (category == 'sleep' || title.contains('sleep') || title.contains('night')) {
      return const DuaReminderTime(22, 0);
    }
    if (category == 'morning_evening') return const DuaReminderTime(7, 0);
    return const DuaReminderTime(8, 0);
  }

  /// Single-line, capped title for the notification surface.
  static String truncateTitle(String text) {
    final flat = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (flat.length <= maxTitleChars) return flat;
    return '${flat.substring(0, maxTitleChars - 1).trimRight()}…';
  }

  /// Single-line preview body from the dua's own text (never a stub).
  static String truncateBody(String text) {
    final flat = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (flat.length <= maxBodyChars) return flat;
    return '${flat.substring(0, maxBodyChars - 1).trimRight()}…';
  }

  // ─── prefs encoding: '<duaId>|<hour>|<minute>' ───────────────

  static String encodeEntry(String duaId, int hour, int minute) =>
      '$duaId|$hour|$minute';

  /// Parses an entry; returns null for malformed lines (fail-safe:
  /// bad data is skipped, never guessed).
  static ({String duaId, DuaReminderTime time})? parseEntry(String raw) {
    final parts = raw.split('|');
    if (parts.length != 3) return null;
    final id = parts[0].trim();
    final h = int.tryParse(parts[1]);
    final m = int.tryParse(parts[2]);
    if (id.isEmpty || h == null || m == null) return null;
    if (h < 0 || h > 23 || m < 0 || m > 59) return null;
    return (duaId: id, time: DuaReminderTime(h, m));
  }
}