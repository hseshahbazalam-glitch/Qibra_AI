// lib/core/observability/qibra_log.dart

import 'package:flutter/foundation.dart';

/// PASS X2 (2026-09-02, print diet) — the ONE logging seam in `lib/`.
///
/// Before this, 120 `debugPrint` call sites sat across 21 files (122 grep hits,
/// two of them comment prose), and every one of them evaluated its message in
/// RELEASE too: `debugPrint` is not stripped
/// for AOT (it writes to the system log), and the interpolation happens BEFORE
/// the call — `'$found/${registeredAssets.length}'`, `list.join(', ')`,
/// `e.toString()` — in the worst cases once per frame (audio providers,
/// reading-progress saves while scrolling). A sluggish device paid string
/// building plus a logcat write for output no release user can ever read.
///
/// The message here is a THUNK, and that is the point: in release [kDebugMode]
/// is a compile-time false, so the branch is dead code and the closure is never
/// called — no interpolation, no join, no toString, no print. Debug builds keep
/// every line verbatim, because the device-log gates in this repository are read
/// from exactly those lines (the `[HADITH_DB]` boot timings among them).
abstract final class QibraLog {
  /// Print [message] in debug builds. In release, nothing is evaluated.
  static void log(String Function() message) {
    if (kDebugMode) debugPrint(message());
  }
}
