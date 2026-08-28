// Accessibility constants. Do not clamp MediaQuery textScaler.

import 'package:flutter/material.dart';

abstract final class AppA11y {
  static const double minTapTarget = 48.0;

  static Widget ensureTapTarget({
    required Widget child,
    double minSize = minTapTarget,
  }) {
    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: minSize, minHeight: minSize),
      child: child,
    );
  }

  static String announceUnknown() => 'Unknown';
}
