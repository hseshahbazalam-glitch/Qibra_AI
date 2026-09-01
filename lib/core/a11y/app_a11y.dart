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

class AppSemanticIconButton extends StatelessWidget {
  const AppSemanticIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AppA11y.ensureTapTarget(
      child: IconButton(
        tooltip: tooltip,
        icon: Icon(icon),
        onPressed: onPressed,
      ),
    );
  }
}
