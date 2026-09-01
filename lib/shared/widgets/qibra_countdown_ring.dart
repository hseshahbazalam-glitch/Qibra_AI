// lib/shared/widgets/qibra_countdown_ring.dart
// ============================================================
// QIBRA AI — PREMIUM COUNTDOWN RING
// Arc countdown used by Home hero and (stage 2) Prayer hero.
// Pure CustomPaint — no infinite animations, reduced-motion safe.
// Meaning is never conveyed by color alone: the ring always
// carries a text label and the parent supplies semantic labels.
// ============================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/design_system/qibra_colors.dart';
import '../../core/design_system/qibra_navy.dart';

class QibraCountdownRing extends StatelessWidget {
  const QibraCountdownRing({
    super.key,
    required this.progress,
    required this.child,
    this.size = 96,
    this.strokeWidth = 7,
    this.glow = true,
  });

  /// 0.0 → 1.0 elapsed fraction of the current prayer interval.
  final double progress;
  final Widget child;
  final double size;
  final double strokeWidth;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    final track = colors.border;
    final active = colors.primary;
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: glow
              ? [
                  BoxShadow(
                    color: active.withValues(alpha: 0.22),
                    blurRadius: 18,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: CustomPaint(
          painter: _CountdownRingPainter(
            progress: progress,
            strokeWidth: strokeWidth,
            trackColor: track,
            activeColor: active,
            deepColor: isNavy(colors)
                ? QibraNavy.emeraldDeep
                : colors.primarySoft,
          ),
          child: Center(
            child: Padding(
              padding: EdgeInsets.all(strokeWidth + 4),
              child: FittedBox(fit: BoxFit.scaleDown, child: child),
            ),
          ),
        ),
      ),
    );
  }

  static bool isNavy(QibraColors colors) =>
      colors.background == QibraNavy.canvas;
}

class _CountdownRingPainter extends CustomPainter {
  _CountdownRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.trackColor,
    required this.activeColor,
    required this.deepColor,
  });

  final double progress;
  final double strokeWidth;
  final Color trackColor;
  final Color activeColor;
  final Color deepColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = trackColor;
    canvas.drawCircle(center, radius, track);

    final t = progress.clamp(0.0, 1.0);
    if (t <= 0) return;

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + 2 * math.pi,
        colors: [deepColor, activeColor, activeColor, deepColor],
        stops: const [0.0, 0.35, 0.9, 1.0],
        tileMode: TileMode.clamp,
        transform: GradientRotation(-math.pi / 2),
      ).createShader(rect);
    // Draw the elapsed fraction from the top, clockwise.
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * t, false, arc);

    // Leading dot for the current position.
    final angle = -math.pi / 2 + 2 * math.pi * t;
    final dot = Offset(
      center.dx + radius * math.cos(angle),
      center.dy + radius * math.sin(angle),
    );
    canvas.drawCircle(
      dot,
      strokeWidth * 0.8,
      Paint()
        ..color = activeColor.withValues(alpha: 0.55)
        ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 3),
    );
    canvas.drawCircle(dot, strokeWidth * 0.42, Paint()..color = activeColor);
  }

  @override
  bool shouldRepaint(covariant _CountdownRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.activeColor != activeColor;
  }
}
