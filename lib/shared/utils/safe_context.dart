// lib/shared/utils/safe_context.dart
// ===========================================================
// QIBRA AI — SAFE CONTEXT HELPERS
// Wrap Navigator / ScaffoldMessenger / GoRouter usages that
// may fire after an asynchronous gap so we NEVER call
// setState/navigation on an unmounted widget.
// ===========================================================

import 'package:flutter/material.dart';

/// Mixin for [State] classes that adds a mounted-aware guard.
mixin MountedStateAware<T extends StatefulWidget> on State<T> {
  /// Returns `true` only if this [State] is still mounted.
  bool get isMounted => mounted;

  /// Run [action] only if the widget is still mounted.
  void ifMounted(VoidCallback action) {
    if (mounted) action();
  }

  /// Returns the current [ScaffoldMessengerState] if mounted, else `null`.
  ScaffoldMessengerState? safeScaffold() {
    if (!mounted) return null;
    return ScaffoldMessenger.of(context);
  }

  /// Shows a [SnackBar] only if the widget is still mounted.
  void safeShowSnackBar(SnackBar snackBar) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  /// Returns the current [NavigatorState] if mounted, else `null`.
  NavigatorState? safeNavigator() {
    if (!mounted) return null;
    return Navigator.of(context);
  }
}
