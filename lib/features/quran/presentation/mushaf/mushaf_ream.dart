// QIBRA — Pass M5 (R part): the ream.
//
// The U2 report ("look wise advance jaise ream") asked for the page
// block to read like a REAM of paper, not a single card. This painter
// draws the four physical tells of a bound block, and only those:
//
//   R1  spine-side (screen-right, where the mushaf's binding edge
//       lives for this app's pinned RTL pager) — five 1px hairline
//       sheet edges at 1.6px rhythm, alternating tones. Static at
//       rest: zero turn, zero movement.
//   R2  at turn commit the outermost sheet is the one that LIFTS —
//       its alpha rides (1 - swell(t)). swell() is exact-zero at both
//       ends (M4 guard), so at rest and at landing the block is
//       complete, bit for bit.
//   R3  a soft inner-spine gradient (2–4%) beside the existing
//       spineCrease ramp — depth, never a vignette.
//   R4  the LEFT free edge gets a 1.5px sheet-thickness highlight
//       that DIMS while the gild band rides the same edge —
//       double-glow is the failure mode this coordinate against.
//
// Discipline (all pinned by test/features/quran/mushaf_pass_m5_test):
//   R5  no hardcoded hex colour literals anywhere — the tones arrive as the
//       palette's own fields (card / cardMuted / border), so paper and
//       navy both resolve without a single new literal;
//   R6  the M2 grain pattern is copied exactly: const-shaped painter,
//       shouldRepaint compares the DATA only, and the widget tree
//       wraps it in a RepaintBoundary so its turn frames never dirty
//       the settled page.
//

import 'dart:math' as math;

import 'package:flutter/material.dart';

/// One painter for the whole page-block edge story (no new shader files,
/// no saveLayer — the R part runs entirely on drawRect + one
/// LinearGradient shader, per the scope lock).
class MushafReamPainter extends CustomPainter {
  MushafReamPainter({
    required this.turn,
    required this.sheetA,
    required this.sheetB,
    required this.crease,
    required this.depth,
  });

  /// swell(t) of the live turn — exact 0.0 at rest (the M4 guard).
  final double turn;

  /// The alternating sheet tones: palette `card` / `cardMuted`.
  final Color sheetA;
  final Color sheetB;

  /// Palette hairline (paper: border hairline, navy: its own border).
  final Color crease;

  /// R3 depth alpha, 0.02–0.04, fed by the spineCrease ramp.
  final double depth;

  /// R1: 4–6 hairline sheets — five, with the outermost liftable.
  static const int sheets = 5;

  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height;
    final w = size.width;
    if (h <= 0 || w <= 0) return;
    final t = turn.clamp(0.0, 1.0);
    final fill = Paint()..style = PaintingStyle.fill;

    // R1/R2 — spine-side block. Inner sheets solid; the outermost
    // fades out while the leaf is mid-turn (the sheet that lifts).
    for (var i = 0; i < sheets; i++) {
      final x = w - 1.0 - i * 1.6;
      var a = i.isEven ? 0.9 : 0.55;
      if (i == sheets - 1) a *= 1.0 - t;
      // R5: tones are the palette fields; alpha is the only math.
      fill.color =
          (i.isEven ? sheetA : sheetB).withValues(alpha: a.clamp(0.0, 1.0));
      canvas.drawRect(Rect.fromLTRB(x - 1.0, h * 0.04, x, h * 0.96), fill);
      if (i == 0) {
        // The binding edge itself — one hairline of the crease tone.
        fill.color = crease.withValues(alpha: 0.60);
        canvas.drawRect(Rect.fromLTRB(w - 1.0, 0.0, w, h), fill);
      }
    }

    // R3 — inner-spine depth band, riding the spineCrease ramp.
    final band = Rect.fromLTWH(w - 16.0 - sheets * 1.6, 0.0, 16.0, h);
    fill.shader = LinearGradient(
      begin: Alignment.centerRight,
      end: Alignment.centerLeft,
      colors: [
        Colors.black.withValues(alpha: depth.clamp(0.0, 0.04)),
        Colors.black.withValues(alpha: 0.0),
      ],
    ).createShader(band);
    canvas.drawRect(band, fill);
    fill.shader = null;

    // R4 — free-edge sheet thickness: the 1.5px light line, dimmed
    // exactly while the gild band shares this edge (anti double-glow),
    // plus a half-line of shadow beneath it for the block's depth.
    fill.color =
        Colors.white.withValues(alpha: math.max(0.0, 0.18 - 0.08 * t));
    canvas.drawRect(Rect.fromLTRB(0.0, h * 0.02, 1.5, h * 0.98), fill);
    fill.color = sheetB.withValues(alpha: 0.35);
    canvas.drawRect(Rect.fromLTRB(1.5, h * 0.02, 2.25, h * 0.98), fill);
  }

  @override
  bool shouldRepaint(MushafReamPainter oldDelegate) =>
      oldDelegate.turn != turn ||
      oldDelegate.depth != depth ||
      oldDelegate.sheetA != sheetA ||
      oldDelegate.sheetB != sheetB ||
      oldDelegate.crease != crease;
}
