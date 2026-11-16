// lib/core/utils/countdown_format.dart
// ============================================================
// QIBRA AI — SHARED COUNTDOWN GRAMMAR (Stage A, rule G7)
// ONE human countdown format for the whole app: "Xh Ym" at an
// hour+, "Xm Ys" under an hour, "Ns" under a minute, "Now" when
// elapsed. Home hero, Prayer ring and every future countdown
// must render through this so formats can never drift.
// ============================================================

/// Formats a remaining duration with the app-wide countdown grammar.
String formatCountdownCompact(Duration d) {
  if (d.isNegative) return 'Now';
  if (d.inHours >= 1) {
    return '${d.inHours}h ${d.inMinutes.remainder(60)}m';
  }
  if (d.inMinutes >= 1) {
    return '${d.inMinutes}m ${d.inSeconds.remainder(60)}s';
  }
  return '${d.inSeconds}s';
}
