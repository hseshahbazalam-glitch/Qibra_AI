// lib/core/observability/qibra_log.dart

import 'package:flutter/foundation.dart';


// PASS X2 (bisect-hardened): the seam is ALSO the foundation import for every
// file that uses it, so swapping `debugPrint` for [QibraLog.log] can never
// strand a `package:meta` / `dart:ui` type (`@immutable`, `@protected`,
// `kDebugMode`, `compute`, `listEquals`, `ValueChanged`, `Size`…) that the
// foundation import used to carry — that class of fault is what made the first
// two X2 pushes red. Keeping the direct `foundation.dart` import next to this
// one is at worst `unnecessary_import` (an INFO, sanctioned by the CI gate), so
// the files that genuinely use foundation symbols — `error_shield.dart`
// (`FlutterError`, `kDebugMode`), `tafsir_bundle.dart` (`kDebugMode`),
// `hadith_database_service.dart` (`kReleaseMode`, `visibleForTesting`),
// `quran_audio_provider.dart` / `quran_download_provider.dart` (`@immutable`) —
// KEEP it, because the repo's own battery (G12) treats a foundation usage with
// no foundation import as a hard finding.
export 'package:flutter/foundation.dart';

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
///
/// The thunk returns `Object?` rather than `String` because that is what
/// `debugPrint` took: widening the parameter keeps every converted site valid
/// (`String Function()` is assignable to `Object? Function()`), and `debugPrint`
/// does its own toString — so no call site needed rewriting to `'$x'`.
abstract final class QibraLog {
  /// Print [message] in debug builds. In release, nothing is evaluated.
  static void log(Object? Function() message) {
    if (kDebugMode) debugPrint(message());
  }
}
