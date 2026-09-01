import 'package:flutter/material.dart';

import '../../../core/design_system/app_design_system.dart';

/// Repeating geometric tile at 4–6% opacity. Hero/sheet backgrounds only.
class PatternBackdrop extends StatelessWidget {
  const PatternBackdrop({
    super.key,
    required this.child,
    this.opacity = 0.05,
  });

  final Widget child;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: Opacity(
              opacity: opacity.clamp(0.04, 0.06),
              child: Image.asset(
                AppAssets.patternTile,
                repeat: ImageRepeat.repeat,
                fit: BoxFit.none,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
