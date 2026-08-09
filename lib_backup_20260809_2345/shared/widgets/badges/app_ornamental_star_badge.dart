// lib/shared/widgets/badges/app_ornamental_star_badge.dart
// ============================================================
// QIBRA AI — ORNAMENTAL STAR BADGE WIDGET (v1.0)
// Phase: 8 — Premium UI Redesign
// Description: 8-point Islamic star badge with:
//   - Custom painted star shape (Rub el Hizb inspired)
//   - Gold border + emerald fill (or custom colors)
//   - Centered number/text
//   - Ambient glow effect
//   - Multiple sizes (small, medium, large, custom)
//   - Color variants (emerald, gold, purple, custom)
// Usage: Surah numbers, Juz numbers, Ayah numbers, ranks
// Reference: Recently Read section in Quran screen
// ============================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:qibra_ai/core/design_system/app_colors.dart';

// ============================================================
// SECTION 1 — ENUMS
// ============================================================

/// Badge size presets
enum BadgeSize {
  small, // 40px — for compact lists
  medium, // 56px — default (reference image match)
  large, // 72px — for hero displays
  xlarge, // 96px — for feature showcase
}

/// Badge color themes
enum BadgeColorTheme {
  /// Emerald green fill + gold border (reference default)
  emerald,

  /// Gold fill + emerald border
  gold,

  /// Purple fill + gold border (for special items)
  purple,

  /// Dark surface + gold border (subtle)
  dark,

  /// Custom colors (use customFillColor + customBorderColor)
  custom,
}

// ============================================================
// SECTION 2 — ORNAMENTAL STAR BADGE WIDGET
// ============================================================

/// Premium 8-point Islamic star badge
///
/// Example usage:
/// ```dart
/// AppOrnamentalStarBadge(
///   number: 1,
///   size: BadgeSize.medium,
///   theme: BadgeColorTheme.emerald,
/// )
/// ```
class AppOrnamentalStarBadge extends StatelessWidget {
  /// Number to display (e.g., 1, 2, 3, 114)
  final int? number;

  /// Custom text (overrides number if provided)
  final String? customText;

  /// Badge size preset
  final BadgeSize size;

  /// Custom size (overrides preset)
  final double? customSize;

  /// Color theme
  final BadgeColorTheme theme;

  /// Custom fill color (used when theme = custom)
  final Color? customFillColor;

  /// Custom border color (used when theme = custom)
  final Color? customBorderColor;

  /// Custom text color (overrides theme default)
  final Color? customTextColor;

  /// Show ambient glow effect
  final bool showGlow;

  /// Custom glow color (default: fill color)
  final Color? glowColor;

  /// Border width
  final double borderWidth;

  /// Optional tap handler
  final VoidCallback? onTap;

  /// Text style override
  final TextStyle? textStyle;

  const AppOrnamentalStarBadge({
    super.key,
    this.number,
    this.customText,
    this.size = BadgeSize.medium,
    this.customSize,
    this.theme = BadgeColorTheme.emerald,
    this.customFillColor,
    this.customBorderColor,
    this.customTextColor,
    this.showGlow = true,
    this.glowColor,
    this.borderWidth = 2.0,
    this.onTap,
    this.textStyle,
  }) : assert(number != null || customText != null,
            'Either number or customText must be provided');

  // ============================================================
  // BUILD METHOD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final double effectiveSize = customSize ?? _getSizeFromPreset(size);
    final _BadgeColors colors = _getColorsFromTheme(theme);
    final String displayText = customText ?? number.toString();

    Widget badge = SizedBox(
      width: effectiveSize,
      height: effectiveSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Layer 1: Ambient glow (optional)
          if (showGlow) _buildGlowLayer(effectiveSize, colors),

          // Layer 2: Star shape (custom painted)
          CustomPaint(
            size: Size(effectiveSize, effectiveSize),
            painter: _StarPainter(
              fillColor: colors.fill,
              borderColor: colors.border,
              borderWidth: borderWidth,
            ),
          ),

          // Layer 3: Centered text/number
          _buildCenterText(displayText, effectiveSize, colors),
        ],
      ),
    );

    // Wrap with tap handler if provided
    if (onTap != null) {
      badge = GestureDetector(
        onTap: onTap,
        child: badge,
      );
    }

    return badge;
  }

  // ============================================================
  // SECTION 3 — LAYER BUILDERS
  // ============================================================

  /// LAYER 1: Ambient glow around badge
  Widget _buildGlowLayer(double size, _BadgeColors colors) {
    final Color effectiveGlow = glowColor ?? colors.fill;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: effectiveGlow.withValues(alpha: 0.30),
            blurRadius: 12,
            spreadRadius: 0,
          ),
          BoxShadow(
            color: effectiveGlow.withValues(alpha: 0.15),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
    );
  }

  /// LAYER 3: Centered number/text
  Widget _buildCenterText(String text, double size, _BadgeColors colors) {
    return Text(
      text,
      style: textStyle ??
          TextStyle(
            fontSize: _getFontSize(size, text.length),
            fontWeight: FontWeight.w900,
            color: customTextColor ?? colors.text,
            height: 1.0,
            letterSpacing: -0.5,
          ),
      textAlign: TextAlign.center,
    );
  }

  // ============================================================
  // SECTION 4 — HELPERS
  // ============================================================

  /// Get size in pixels from preset
  double _getSizeFromPreset(BadgeSize preset) {
    switch (preset) {
      case BadgeSize.small:
        return 40;
      case BadgeSize.medium:
        return 56;
      case BadgeSize.large:
        return 72;
      case BadgeSize.xlarge:
        return 96;
    }
  }

  /// Get font size based on badge size + text length
  double _getFontSize(double badgeSize, int textLength) {
    // Base font size = 40% of badge size
    double baseFontSize = badgeSize * 0.40;

    // Reduce font size for longer numbers (3-digit like "114")
    if (textLength >= 3) {
      baseFontSize *= 0.75;
    } else if (textLength == 2) {
      baseFontSize *= 0.90;
    }

    return baseFontSize;
  }

  /// Get colors from theme preset
  _BadgeColors _getColorsFromTheme(BadgeColorTheme theme) {
    switch (theme) {
      case BadgeColorTheme.emerald:
        return const _BadgeColors(
          fill: AppColors.primary,
          border: AppColors.accent,
          text: AppColors.white,
        );

      case BadgeColorTheme.gold:
        return const _BadgeColors(
          fill: AppColors.accent,
          border: AppColors.primary,
          text: AppColors.background,
        );

      case BadgeColorTheme.purple:
        return const _BadgeColors(
          fill: Color(0xFF6B21A8),
          border: AppColors.accent,
          text: AppColors.white,
        );

      case BadgeColorTheme.dark:
        return const _BadgeColors(
          fill: AppColors.surface,
          border: AppColors.accent,
          text: AppColors.accent,
        );

      case BadgeColorTheme.custom:
        return _BadgeColors(
          fill: customFillColor ?? AppColors.primary,
          border: customBorderColor ?? AppColors.accent,
          text: customTextColor ?? AppColors.white,
        );
    }
  }
}

// ============================================================
// SECTION 5 — HELPER COLOR CLASS
// ============================================================

class _BadgeColors {
  final Color fill;
  final Color border;
  final Color text;

  const _BadgeColors({
    required this.fill,
    required this.border,
    required this.text,
  });
}

// ============================================================
// SECTION 6 — CUSTOM PAINTER (8-Point Islamic Star)
// ============================================================

/// Draws an 8-point Islamic star (Rub el Hizb inspired)
class _StarPainter extends CustomPainter {
  final Color fillColor;
  final Color borderColor;
  final double borderWidth;

  _StarPainter({
    required this.fillColor,
    required this.borderColor,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double outerRadius = (size.width / 2) - borderWidth;
    final double innerRadius = outerRadius * 0.72; // Inner point depth

    // ── Build 8-point star path ─────────────────────────
    final Path starPath = _buildStarPath(center, outerRadius, innerRadius);

    // ── LAYER 1: Fill ────────────────────────────────────
    final Paint fillPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          _lightenColor(fillColor, 0.15),
          fillColor,
          _darkenColor(fillColor, 0.10),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(
        Rect.fromCircle(center: center, radius: outerRadius),
      )
      ..style = PaintingStyle.fill;

    canvas.drawPath(starPath, fillPaint);

    // ── LAYER 2: Border ──────────────────────────────────
    final Paint borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(starPath, borderPaint);

    // ── LAYER 3: Subtle inner highlight ─────────────────
    final Paint highlightPaint = Paint()
      ..color = AppColors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Inner star (slightly smaller)
    final Path innerStar = _buildStarPath(
      center,
      outerRadius * 0.85,
      innerRadius * 0.85,
    );
    canvas.drawPath(innerStar, highlightPaint);
  }

  /// Build 8-point star path
  Path _buildStarPath(Offset center, double outerRadius, double innerRadius) {
    final Path path = Path();
    const int points = 8; // 8-point star
    const double angleStep = math.pi / points; // 22.5° step

    for (int i = 0; i < points * 2; i++) {
      final double radius = i.isEven ? outerRadius : innerRadius;
      // -pi/2 = start from top (12 o'clock)
      final double angle = (i * angleStep) - (math.pi / 2);
      final double x = center.dx + radius * math.cos(angle);
      final double y = center.dy + radius * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    path.close();
    return path;
  }

  /// Lighten a color
  Color _lightenColor(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness + amount).clamp(0.0, 1.0))
        .toColor();
  }

  /// Darken a color
  Color _darkenColor(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }

  @override
  bool shouldRepaint(covariant _StarPainter oldDelegate) {
    return oldDelegate.fillColor != fillColor ||
        oldDelegate.borderColor != borderColor ||
        oldDelegate.borderWidth != borderWidth;
  }
}

// ============================================================
// SECTION 7 — PRE-CONFIGURED VARIANTS
// ============================================================

/// Pre-configured Surah number badge (reference image match)
class AppSurahNumberBadge extends StatelessWidget {
  final int surahNumber;
  final double size;
  final VoidCallback? onTap;

  const AppSurahNumberBadge({
    super.key,
    required this.surahNumber,
    this.size = 56,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppOrnamentalStarBadge(
      number: surahNumber,
      customSize: size,
      theme: BadgeColorTheme.emerald,
      showGlow: true,
      onTap: onTap,
    );
  }
}

/// Pre-configured Juz number badge
class AppJuzNumberBadge extends StatelessWidget {
  final int juzNumber;
  final double size;
  final VoidCallback? onTap;

  const AppJuzNumberBadge({
    super.key,
    required this.juzNumber,
    this.size = 48,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppOrnamentalStarBadge(
      number: juzNumber,
      customSize: size,
      theme: BadgeColorTheme.gold,
      showGlow: true,
      onTap: onTap,
    );
  }
}

/// Pre-configured Ayah number badge (smaller, inline)
class AppAyahNumberBadge extends StatelessWidget {
  final int ayahNumber;

  const AppAyahNumberBadge({
    super.key,
    required this.ayahNumber,
  });

  @override
  Widget build(BuildContext context) {
    return AppOrnamentalStarBadge(
      number: ayahNumber,
      size: BadgeSize.small,
      theme: BadgeColorTheme.dark,
      showGlow: false,
      borderWidth: 1.5,
    );
  }
}

// ============================================================
// END OF FILE — app_ornamental_star_badge.dart (v1.0)
// ============================================================
