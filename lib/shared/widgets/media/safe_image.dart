// lib/shared/widgets/media/safe_image.dart
// ===========================================================
// QIBRA AI — FAIL-SAFE IMAGE WIDGET
// Wraps Image.asset with a custom vector-painted fallback so
// the app NEVER crashes or shows white blanks if an asset
// is missing.  Two custom painters are provided:
//   • _MosqueVectorPainter  → used for mosque/prayer imagery
//   • _QuranVectorPainter   → used for Quran/religious imagery
//
// Automatic fallback detection by path keyword:
//   'quran', 'mushaf', 'cover'  → Quran vector
//   'mosque', 'kaaba', 'hero'   → Mosque vector
//   Otherwise                   → Decorative Islamic pattern vector
// ===========================================================

import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../../core/design_system/qibra_colors.dart';

/// Possible fallback variants for [SafeImage].
enum SafeImageFallback { quran, mosque, pattern, logo }

/// Fail-safe replacement for [Image.asset].
///
/// * If the asset loads successfully it is shown normally (with
///   optional [fit], [width], [height], [borderRadius]).
/// * If the asset is missing or fails to decode, a vector-painted
///   placeholder is rendered instead so no white/blank box ever
///   appears and no exception bubbles up.
class SafeImage extends StatelessWidget {
  final String assetPath;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final BorderRadius? borderRadius;
  final Color? fallbackTint;
  final SafeImageFallback? fallback;
  /// Decode-size hint (pixels). Set for large art so memory matches
  /// display size (P0 perf pass).
  final int? cacheWidth;
  final AlignmentGeometry alignment;

  const SafeImage({
    super.key,
    required this.assetPath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallbackTint,
    this.fallback,
    this.cacheWidth,
    this.alignment = Alignment.center,
  });

  SafeImageFallback _inferFallback() {
    final p = assetPath.toLowerCase();
    if (p.contains('quran') || p.contains('mushaf') || p.contains('cover')) {
      return SafeImageFallback.quran;
    }
    if (p.contains('mosque') ||
        p.contains('kaaba') ||
        p.contains('hero') ||
        p.contains('compass') ||
        p.contains('splash')) {
      return SafeImageFallback.mosque;
    }
    if (p.contains('logo')) return SafeImageFallback.logo;
    if (p.contains('pattern') || p.contains('onboarding')) {
      return SafeImageFallback.pattern;
    }
    return SafeImageFallback.mosque;
  }

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    final variant = fallback ?? _inferFallback();
    final placeholder = _VectorFallback(
      variant: variant,
      width: width,
      height: height,
      tint: fallbackTint,
    );

    Widget image = Image.asset(
      assetPath,
      width: width,
      height: height,
      fit: fit,
      cacheWidth: cacheWidth,
      alignment: alignment,
      errorBuilder: (context, error, stackTrace) {
        debugPrint('[SafeImage] Asset missing/failed: $assetPath — $error');
        return placeholder;
      },
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (frame == null) {
          // While loading first frame, show placeholder to avoid white flash.
          return AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: frame == null ? placeholder : child,
          );
        }
        return child;
      },
    );

    if (borderRadius != null) {
      image = ClipRRect(borderRadius: borderRadius!, child: image);
    }
    return image;
  }
}

// ===========================================================
// INTERNAL: Vector painted placeholder
// ===========================================================

class _VectorFallback extends StatelessWidget {
  final SafeImageFallback variant;
  final double? width;
  final double? height;
  final Color? tint;

  const _VectorFallback({
    required this.variant,
    this.width,
    this.height,
    this.tint,
  });

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    final CustomPainter painter;
    switch (variant) {
      case SafeImageFallback.quran:
        painter = _QuranVectorPainter(accent: tint ?? colors.primary);
      case SafeImageFallback.mosque:
        painter = _MosqueVectorPainter(accent: tint ?? colors.accent);
      case SafeImageFallback.logo:
        painter = _LogoVectorPainter(accent: tint ?? colors.accent);
      case SafeImageFallback.pattern:
        painter = _PatternVectorPainter(accent: tint ?? colors.primary);
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.surface,
            colors.surfaceElevated,
          ],
        ),
      ),
      child: CustomPaint(painter: painter),
    );
  }
}

// ===========================================================
// MOSQUE VECTOR PAINTER
// Draws a stylised mosque silhouette with dome + minarets
// in the brand gold colour over a subtle gradient background.
// ===========================================================

class _MosqueVectorPainter extends CustomPainter {
  final Color accent;
  _MosqueVectorPainter({required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final colors = QibraColors.light;
    final w = size.width;
    final h = size.height;
    if (w == 0 || h == 0) return;

    // Back gradient
    final bgRect = Rect.fromLTWH(0, 0, w, h);
    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          colors.background,
          colors.background,
        ],
      ).createShader(bgRect);
    canvas.drawRect(bgRect, bgPaint);

    // Subtle radial glow behind dome
    final glowPaint = Paint()
      ..color = accent.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 30);
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.55),
      w * 0.35,
      glowPaint,
    );

    final baseY = h * 0.82;
    final silhouette = Paint()
      ..color = colors.backgroundSecondary
      ..style = PaintingStyle.fill;

    // Ground
    canvas.drawRect(Rect.fromLTWH(0, baseY, w, h - baseY), silhouette);

    // Main dome
    final domeCenter = Offset(w * 0.5, baseY - h * 0.15);
    final domeRect = Rect.fromCenter(
      center: domeCenter,
      width: w * 0.40,
      height: h * 0.32,
    );
    canvas.drawArc(domeRect, math.pi, math.pi, true, silhouette);

    // Dome band
    final bandPaint = Paint()..color = accent.withValues(alpha: 0.55);
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(w * 0.5, baseY - h * 0.02),
        width: w * 0.44,
        height: h * 0.025,
      ),
      bandPaint,
    );

    // Spire (crescent atop dome)
    final spirePaint = Paint()
      ..color = accent
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(w * 0.5, domeCenter.dy - h * 0.16),
      Offset(w * 0.5, domeCenter.dy - h * 0.28),
      spirePaint,
    );
    // crescent
    final crescentRect = Rect.fromCenter(
      center: Offset(w * 0.5, domeCenter.dy - h * 0.30),
      width: w * 0.06,
      height: h * 0.06,
    );
    canvas.drawArc(crescentRect, -math.pi * 0.7, math.pi * 1.4, false,
        spirePaint..strokeWidth = 1.8);

    // Minarets
    void minaret(double x) {
      canvas.drawRect(
        Rect.fromLTWH(x - w * 0.02, baseY - h * 0.38, w * 0.04, h * 0.38),
        silhouette,
      );
      // cone
      final cone = Path()
        ..moveTo(x - w * 0.035, baseY - h * 0.38)
        ..lineTo(x, baseY - h * 0.48)
        ..lineTo(x + w * 0.035, baseY - h * 0.38)
        ..close();
      canvas.drawPath(cone, silhouette);
      // balcony
      canvas.drawRect(
        Rect.fromCenter(
          center: Offset(x, baseY - h * 0.22),
          width: w * 0.06,
          height: h * 0.015,
        ),
        bandPaint,
      );
    }

    minaret(w * 0.18);
    minaret(w * 0.82);

    // Small side domes
    void sideDome(double x) {
      final r = Rect.fromCenter(
        center: Offset(x, baseY - h * 0.05),
        width: w * 0.14,
        height: h * 0.12,
      );
      canvas.drawArc(r, math.pi, math.pi, true, silhouette);
    }

    sideDome(w * 0.28);
    sideDome(w * 0.72);

    // Arches on base
    final archPaint = Paint()
      ..color = colors.backgroundSecondary
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 5; i++) {
      final cx = w * (0.2 + i * 0.15);
      final archRect = Rect.fromCenter(
        center: Offset(cx, baseY - h * 0.05),
        width: w * 0.08,
        height: h * 0.10,
      );
      canvas.drawArc(archRect, math.pi, math.pi, true, archPaint);
    }

    // Star sparkles
    final starPaint = Paint()..color = accent.withValues(alpha: 0.7);
    final rnd = math.Random(42);
    for (int i = 0; i < 18; i++) {
      final sx = rnd.nextDouble() * w;
      final sy = rnd.nextDouble() * h * 0.45;
      canvas.drawCircle(Offset(sx, sy), 1.0, starPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MosqueVectorPainter oldDelegate) =>
      oldDelegate.accent != accent;
}

// ===========================================================
// QURAN VECTOR PAINTER
// Draws a stylised Qur'an book cover with gold borders and
// emerald corner ornaments.
// ===========================================================

class _QuranVectorPainter extends CustomPainter {
  final Color accent;
  _QuranVectorPainter({required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final colors = QibraColors.light;
    final w = size.width;
    final h = size.height;
    if (w == 0 || h == 0) return;

    final bg = Paint()..color = colors.backgroundSecondary;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bg);

    // Pages
    final pageRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.10, h * 0.18, w * 0.80, h * 0.66),
      Radius.circular(w * 0.03),
    );
    final pagePaint = Paint()..color = colors.backgroundSecondary;
    canvas.drawRRect(pageRect, pagePaint);

    // Spine
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.51),
        width: w * 0.02,
        height: h * 0.70,
      ),
      Paint()..color = colors.background,
    );

    // Gold border
    final borderPaint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawRRect(pageRect, borderPaint);

    // Inner border
    final inner = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.15, h * 0.23, w * 0.70, h * 0.56),
      Radius.circular(w * 0.02),
    );
    canvas.drawRRect(
      inner,
      Paint()
        ..color = accent.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Center ornament (octagon)
    final cx = w * 0.5;
    final cy = h * 0.51;
    final octSize = w * 0.14;
    _drawOctagon(canvas, Offset(cx, cy), octSize,
        Paint()..color = colors.primary.withValues(alpha: 0.55));
    _drawOctagon(canvas, Offset(cx, cy), octSize * 0.6,
        Paint()..color = accent.withValues(alpha: 0.85));

    // Arabic-style calligraphy line (Bismillah stroke placeholder)
    final bisPaint = Paint()
      ..color = accent
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final bisPath = Path()
      ..moveTo(cx - w * 0.18, cy - h * 0.10)
      ..quadraticBezierTo(cx, cy - h * 0.14, cx + w * 0.18, cy - h * 0.10)
      ..moveTo(cx - w * 0.12, cy + h * 0.10)
      ..quadraticBezierTo(cx, cy + h * 0.06, cx + w * 0.12, cy + h * 0.10);
    canvas.drawPath(bisPath, bisPaint);

    // Corner ornaments (emerald)
    _drawCornerOrnament(canvas, Offset(w * 0.15, h * 0.23), -1, -1);
    _drawCornerOrnament(canvas, Offset(w * 0.85, h * 0.23), 1, -1);
    _drawCornerOrnament(canvas, Offset(w * 0.15, h * 0.79), -1, 1);
    _drawCornerOrnament(canvas, Offset(w * 0.85, h * 0.79), 1, 1);
  }

  void _drawOctagon(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final a = (math.pi / 8) + i * (math.pi / 4);
      final x = center.dx + size * math.cos(a);
      final y = center.dy + size * math.sin(a);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawCornerOrnament(
      Canvas canvas, Offset anchor, double dirX, double dirY) {
    final colors = QibraColors.light;
    final p = Paint()
      ..color = colors.primary.withValues(alpha: 0.85)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    final len = 18.0;
    canvas.drawLine(anchor,
        Offset(anchor.dx + dirX * len, anchor.dy), p);
    canvas.drawLine(anchor,
        Offset(anchor.dx, anchor.dy + dirY * len), p);
    canvas.drawCircle(anchor, 2.5,
        Paint()..color = colors.primary);
  }

  @override
  bool shouldRepaint(covariant _QuranVectorPainter oldDelegate) =>
      oldDelegate.accent != accent;
}

// ===========================================================
// LOGO VECTOR PAINTER
// ===========================================================

class _LogoVectorPainter extends CustomPainter {
  final Color accent;
  _LogoVectorPainter({required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final colors = QibraColors.light;
    final w = size.width;
    final h = size.height;
    if (w == 0 || h == 0) return;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = colors.background,
    );
    // Kaaba cube
    final cube = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(w / 2, h / 2 + h * 0.05),
        width: w * 0.55,
        height: h * 0.45,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(
      cube,
      Paint()..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          colors.textPrimary,
          colors.backgroundSecondary,
        ],
      ).createShader(cube.outerRect),
    );
    // Gold band (hijr ismail / kiswa band)
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(w / 2, h / 2 - h * 0.05),
        width: w * 0.55,
        height: h * 0.07,
      ),
      Paint()..color = accent,
    );
    // Crescent above
    final crescentPaint = Paint()
      ..color = accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(w / 2, h * 0.22),
        width: w * 0.22,
        height: h * 0.20,
      ),
      -math.pi * 0.8,
      math.pi * 1.4,
      false,
      crescentPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _LogoVectorPainter oldDelegate) =>
      oldDelegate.accent != accent;
}

// ===========================================================
// PATTERN VECTOR PAINTER
// Draws a repeating Islamic star pattern.
// ===========================================================

class _PatternVectorPainter extends CustomPainter {
  final Color accent;
  _PatternVectorPainter({required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    final colors = QibraColors.light;
    final w = size.width;
    final h = size.height;
    if (w == 0 || h == 0) return;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = colors.backgroundSecondary,
    );
    final p = Paint()
      ..color = accent.withValues(alpha: 0.18)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    const step = 36.0;
    for (double x = 0; x < w + step; x += step) {
      for (double y = 0; y < h + step; y += step) {
        _draw8Star(canvas, Offset(x, y), step * 0.4, p);
      }
    }
  }

  void _draw8Star(Canvas canvas, Offset c, double r, Paint p) {
    final path = Path();
    for (int i = 0; i < 16; i++) {
      final a = i * math.pi / 8 - math.pi / 2;
      final rad = i.isEven ? r : r * 0.45;
      final x = c.dx + rad * math.cos(a);
      final y = c.dy + rad * math.sin(a);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(covariant _PatternVectorPainter oldDelegate) =>
      oldDelegate.accent != accent;
}
