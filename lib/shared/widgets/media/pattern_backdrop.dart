// lib/shared/widgets/media/pattern_backdrop.dart
// ============================================================
// QIBRA AI — PATTERN BACKDROP (perf pass item 3, owner 2026-09-05)
// ============================================================
// ARTIFACT NOTE (the "dead-pixel-like glitches"): this widget used to
// wrap a full-screen 768x768 repeating tile in a widget-level fade
// (clamp 0.04..0.06). On Impeller/Vulkan that is a per-frame saveLayer
// over the whole surface — the classic source of smeared/partial-tile
// artifacts on low-end devices AND a boot-jank contributor.
//
// The wash is now PRE-BAKED into the tile pixels themselves
// (assets/images/hero/pattern_tile_faded.png, generated deterministically
// by scripts/make_faded_tile.py: 256px box-averaged tile with alpha 13 —
// mathematically the identical composite of 0.05 over any background).
// The widget therefore contains NO fade wrapper, NO ColorFiltered, and
// no saveLayer path at all: a plain tiled Image.asset with cacheWidth
// pinned to the baked size. The old `opacity` parameter is GONE — every
// caller used the default, and reintroducing a runtime multiplier would
// re-add the compositor layer this whole pass exists to remove.
// ============================================================

import 'package:flutter/material.dart';

import '../../../core/design_system/app_design_system.dart';

/// Repeating geometric tile at a baked 5% wash. Hero/sheet backgrounds
/// only. Composites flat: no saveLayer, per frame or ever.
class PatternBackdrop extends StatelessWidget {
  const PatternBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: Image.asset(
              AppAssets.patternTileFaded,
              repeat: ImageRepeat.repeat,
              fit: BoxFit.none,
              // Decode budget == the baked tile size: zero rescale work,
              // ~2x logical for typical densities (256px unit).
              cacheWidth: 256,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
