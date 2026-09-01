// lib/shared/widgets/qibra_night_sky.dart
// ============================================================
// QIBRA AI — NIGHT SKY BACKDROP
// Vector-painted midnight sky (stars, crescent moon, mosque
// silhouette) for hero panels. No raster assets, no looping
// animation — reduced-motion safe and cheap to repaint.
// ============================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/design_system/qibra_colors.dart';
import '../../core/design_system/qibra_navy.dart';

class QibraNightSkyBackdrop extends StatelessWidget {
  const QibraNightSkyBackdrop({
    super.key,
    required this.child,
    this.borderRadius = 24,
    this.padding = const EdgeInsets.all(20),
    this.showSky = true,
    this.onTap,
    this.semanticsLabel,
  });

  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final bool showSky;
  final VoidCallback? onTap;
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradient = isDark
        ? QibraNavy.heroNight
        : LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colors.cardMuted, colors.card, colors.background],
            stops: const [0.0, 0.55, 1.0],
          );
    final silhouette = isDark
        ? QibraNavy.nightInk
        : Colors.black.withValues(alpha: 0.08);

    Widget panel = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(borderRadius),
          border: Border.all(color: colors.border),
        ),
        child: Stack(
          children: [
            if (showSky)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _NightSkyPainter(
                      silhouette: silhouette,
                      star: colors.textSecondary,
                      moon: colors.accent,
                      isDark: isDark,
                    ),
                  ),
                ),
              ),
            Padding(padding: padding, child: child),
          ],
        ),
      ),
    );

    if (onTap != null) {
      panel = Semantics(
        button: true,
        label: semanticsLabel,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(borderRadius),
            child: panel,
          ),
        ),
      );
    }
    return panel;
  }
}

class _NightSkyPainter extends CustomPainter {
  _NightSkyPainter({
    required this.silhouette,
    required this.star,
    required this.moon,
    required this.isDark,
  });

  final Color silhouette;
  final Color star;
  final Color moon;
  final bool isDark;

  // Deterministic star field — normalized positions, no RNG at paint time.
  static const List<List<double>> _stars = [
    [0.04, 0.10, 1.0, 0.55],
    [0.11, 0.30, 0.7, 0.40],
    [0.18, 0.06, 1.2, 0.65],
    [0.24, 0.22, 0.6, 0.35],
    [0.30, 0.09, 0.9, 0.50],
    [0.36, 0.27, 0.7, 0.30],
    [0.42, 0.05, 1.1, 0.60],
    [0.47, 0.18, 0.6, 0.40],
    [0.55, 0.08, 0.9, 0.55],
    [0.61, 0.24, 0.7, 0.35],
    [0.66, 0.05, 1.2, 0.65],
    [0.73, 0.16, 0.6, 0.35],
    [0.80, 0.07, 1.0, 0.55],
    [0.86, 0.22, 0.7, 0.40],
    [0.93, 0.11, 1.1, 0.60],
    [0.97, 0.28, 0.6, 0.30],
    [0.08, 0.44, 0.7, 0.30],
    [0.90, 0.42, 0.8, 0.35],
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Aurora glow behind the skyline — extremely subtle.
    final glowRect = Rect.fromCircle(
      center: Offset(w * 0.5, h * 0.86),
      radius: w * 0.75,
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, 0.72),
          radius: 0.9,
          colors: [
            QibraNavy.emeraldDeep.withValues(alpha: isDark ? 0.10 : 0.05),
            Colors.transparent,
          ],
        ).createShader(glowRect),
    );

    // Stars.
    final starPaint = Paint();
    for (final s in _stars) {
      final x = s[0] * w;
      final y = s[1] * h;
      final r = s[2] * 1.1;
      final a = s[3];
      starPaint.color = star.withValues(alpha: a * (isDark ? 0.9 : 0.4));
      canvas.drawCircle(Offset(x, y), r, starPaint);
      if (s[2] >= 1.1) {
        // Cross-sparkle on the brightest stars.
        starPaint.color = star.withValues(alpha: a * 0.28);
        starPaint.strokeWidth = 0.8;
        canvas.drawLine(
            Offset(x - r * 3, y), Offset(x + r * 3, y), starPaint);
        canvas.drawLine(
            Offset(x, y - r * 3), Offset(x, y + r * 3), starPaint);
      }
    }

    // Crescent moon (gold), top-right.
    final moonR = math.min(w, h) * 0.13;
    final moonC = Offset(w * 0.83, h * 0.22);
    canvas.drawCircle(
      moonC,
      moonR * 2.2,
      Paint()
        ..shader = RadialGradient(
          colors: [
            moon.withValues(alpha: isDark ? 0.20 : 0.10),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: moonC, radius: moonR * 2.2)),
    );
    final disc = Path()
      ..addOval(Rect.fromCircle(center: moonC, radius: moonR));
    final bite = Path()
      ..addOval(Rect.fromCircle(
        center: moonC.translate(moonR * 0.42, -moonR * 0.12),
        radius: moonR * 0.88,
      ));
    final crescent = Path.combine(PathOperation.difference, disc, bite);
    // Slightly dimmed in dark so foreground chips/labels keep contrast
    // when they overlap the moon zone (Stage A collision fix).
    canvas.drawPath(
      crescent,
      Paint()..color = moon.withValues(alpha: isDark ? 0.78 : 1.0),
    );

    // Mosque silhouette — skyline anchored to the bottom edge.
    final baseY = h * 0.92;
    final domeR = w * 0.11;
    final domeCx = w * 0.42;
    final skyline = Path()
      ..moveTo(0, h)
      ..lineTo(0, baseY)
      ..lineTo(domeCx - domeR * 1.5, baseY);

    // Left minaret.
    final mnx = domeCx - domeR * 1.9;
    skyline
      ..lineTo(mnx, baseY)
      ..lineTo(mnx, h * 0.50)
      ..lineTo(mnx - 2.5, h * 0.50)
      ..lineTo(mnx + 2.5, h * 0.44)
      ..lineTo(mnx + 7.5, h * 0.50)
      ..lineTo(mnx + 5, h * 0.50)
      ..lineTo(mnx + 5, baseY);

    // Dome + finial.
    final domeBase = baseY - h * 0.03;
    skyline
      ..lineTo(domeCx - domeR, domeBase)
      ..cubicTo(
        domeCx - domeR, domeBase - domeR * 1.05,
        domeCx + domeR, domeBase - domeR * 1.05,
        domeCx + domeR, domeBase,
      );
    // Finial.
    final finial = Paint()
      ..color = silhouette
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(domeCx, domeBase - domeR * 0.78),
      Offset(domeCx, domeBase - domeR * 1.12),
      finial,
    );
    canvas.drawCircle(
      Offset(domeCx, domeBase - domeR * 1.2),
      2.1,
      Paint()..color = moon.withValues(alpha: isDark ? 0.9 : 0.5),
    );

    // Right wing + right minaret.
    final rx = domeCx + domeR * 1.55;
    final r2x = domeCx + domeR * 2.6;
    skyline
      ..lineTo(rx, domeBase)
      ..lineTo(rx, baseY)
      ..lineTo(r2x - 3, baseY)
      ..lineTo(r2x - 3, h * 0.55)
      ..lineTo(r2x + 1, h * 0.50)
      ..lineTo(r2x + 5, h * 0.55)
      ..lineTo(r2x + 5, baseY)
      ..lineTo(w, baseY)
      ..lineTo(w, h)
      ..close();

    canvas.drawPath(skyline, Paint()..color = silhouette);

    // (Stage A: the row of "window lights" read as dead pagination dots
    // in both heroes and was removed by owner decision.)
  }

  @override
  bool shouldRepaint(covariant _NightSkyPainter oldDelegate) {
    return oldDelegate.silhouette != silhouette ||
        oldDelegate.star != star ||
        oldDelegate.moon != moon ||
        oldDelegate.isDark != isDark;
  }
}
