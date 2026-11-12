// lib/core/observability/error_shield.dart
// The global shield: one place that catches what nothing else did.
// install() is fully synchronous and cheap — hook assignment only, no
// awaits and no file IO (first persistence flush is deferred inside
// LocalErrorLog). In debug, FlutterError.presentError keeps the normal
// red-screen/console behavior; zoned errors additionally log so the console
// stays informative. Release stays silent — no user-facing error spam.
// PASS X2 (print diet) routed that one line through [QibraLog], which is
// silent AND unevaluated in release, like every other diagnostic in lib/.
// Deliberately NOT touched: [HADITH_DB] timing logs' TEXT, observability
// consent semantics, and notification-tap routing.

import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'package:qibra_ai/core/observability/error_log.dart';
import 'package:qibra_ai/core/observability/qibra_log.dart';

abstract final class ErrorShield {
  static bool _installed = false;

  static void install() {
    if (_installed) return; // idempotent: hot restarts / tests re-entry safe
    _installed = true;
    FlutterError.onError = (details) {
      LocalErrorLog.instance.record(details.exception, details.stack,
          context: 'flutter');
      FlutterError.presentError(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      LocalErrorLog.instance.record(error, stack, context: 'platform');
      return true; // recorded: consume it, no second crash dialog
    };
  }

  /// runZonedGuarded's handler for everything outside Flutter's own
  /// error plumbing (platform channels, timers, stray microtasks…).
  static void zoneHandler(Object error, StackTrace stack) {
    LocalErrorLog.instance.record(error, stack, context: 'zone');
    if (kDebugMode) {
      QibraLog.log(() => '⚠️ [ErrorShield] uncaught: $error');
    }
  }
}
