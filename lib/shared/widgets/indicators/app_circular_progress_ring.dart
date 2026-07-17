// lib/shared/widgets/indicators/app_circular_progress_ring.dart
// ============================================================
// QIBRA AI — CIRCULAR PROGRESS RING WIDGET (v1.0)
// Phase: 8 — Premium UI Redesign
// Description: Reusable circular progress ring with:
//   - Smooth gradient stroke (emerald, gold, custom)
//   - Center content (text, icon, custom widget)
//   - Optional subtitle below center
//   - Animated value changes
//   - Configurable size, stroke width, glow
//   - Multiple styles: countdown, progress, activity
// Usage: Prayer countdown, Ramadan progress, Reading progress
// ============================================================

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:qibra_ai/core/design_system/app_colors.dart';

// ============================================================
// SECTION 1 — RING STYLE ENUM
// ============================================================

/// Different visual styles for the progress ring
enum RingStyle {
  /// Solid single color stroke
  solid,

  /// Gradient stroke (start color → end color)
  gradient,

  /// Rainbow multi-color gradient
  rainbow,
}

/// Progress direction
enum RingDirection {
  /// Clockwise (default) — 12 o'clock → 3 → 6 → 9
  clockwise,

  /// Counter-clockwise — 12 o'clock → 9 → 6 → 3
  counterClockwise,
}

// ============================================================
// SECTION 2 — CIRCULAR PROGRESS RING WIDGET
// ============================================================

/// Premium circular progress ring with gradient and glow
///
/// Example usage:
/// ```dart
/// AppCircularProgressRing(
///   progress: 0.75,  // 0.0 to 1.0
///   size: 120,
///   centerText: '01:32:04',
///   subtitleText: 'remaining',
/// )
/// ```
class AppCircularProgressRing extends StatefulWidget {
  /// Progress value (0.0 to 1.0)
  final double progress;

  /// Ring size (width & height) — default 120
  final double size;

  /// Stroke width — default 8
  final double strokeWidth;

  /// Center text (like countdown)
  final String? centerText;

  /// Subtitle text below center
  final String? subtitleText;

  /// Custom center widget (overrides centerText)
  final Widget? centerWidget;

  /// Ring style
  final RingStyle style;

  /// Progress direction
  final RingDirection direction;

  /// Starting angle in degrees (0 = top, 90 = right)
  final double startAngleDegrees;

  /// Primary color (for solid or gradient start)
  final Color? primaryColor;

  /// Secondary color (for gradient end)
  final Color? secondaryColor;

  /// Background ring color
  final Color? backgroundColor;

  /// Show glow effect around ring
  final bool showGlow;

  /// Glow color (default: primaryColor)
  final Color? glowColor;

  /// Animate value changes
  final bool animate;

  /// Animation duration
  final Duration animationDuration;

  /// Center text style
  final TextStyle? centerTextStyle;

  /// Subtitle text style
  final TextStyle? subtitleTextStyle;

  /// Rounded stroke caps (default true — smoother look)
  final bool roundedCaps;

  const AppCircularProgressRing({
    super.key,
    required this.progress,
    this.size = 120,
    this.strokeWidth = 8,
    this.centerText,
    this.subtitleText,
    this.centerWidget,
    this.style = RingStyle.gradient,
    this.direction = RingDirection.clockwise,
    this.startAngleDegrees = 270, // Top (12 o'clock)
    this.primaryColor,
    this.secondaryColor,
    this.backgroundColor,
    this.showGlow = true,
    this.glowColor,
    this.animate = true,
    this.animationDuration = const Duration(milliseconds: 800),
    this.centerTextStyle,
    this.subtitleTextStyle,
    this.roundedCaps = true,
  }) : assert(progress >= 0.0 && progress <= 1.0,
            'Progress must be between 0.0 and 1.0');

  @override
  State<AppCircularProgressRing> createState() =>
      _AppCircularProgressRingState();
}

// ============================================================
// SECTION 3 — STATE CLASS
// ============================================================

class _AppCircularProgressRingState extends State<AppCircularProgressRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;
  double _oldProgress = 0.0;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: widget.progress,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Animate on initial build
    if (widget.animate) {
      _animationController.forward();
    } else {
      _animationController.value = 1.0;
    }

    _oldProgress = widget.progress;
  }

  @override
  void didUpdateWidget(covariant AppCircularProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);

    // ── Animate when progress value changes ─────────────────
    if (widget.progress != _oldProgress) {
      _progressAnimation = Tween<double>(
        begin: _oldProgress,
        end: widget.progress,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Curves.easeOutCubic,
        ),
      );

      _animationController.forward(from: 0.0);
      _oldProgress = widget.progress;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ============================================================
  // SECTION 4 — BUILD METHOD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final Color effectivePrimary = widget.primaryColor ?? AppColors.primary;
    final Color effectiveSecondary =
        widget.secondaryColor ?? _lightenColor(effectivePrimary, 0.20);
    final Color effectiveBackground =
        widget.backgroundColor ?? AppColors.white.withValues(alpha: 0.15);
    final Color effectiveGlow = widget.glowColor ?? effectivePrimary;

    return RepaintBoundary(
      // ⚡ RepaintBoundary: Isolates paint, prevents parent rebuilds
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── LAYER 1: Glow effect (optional) ──────────────
            if (widget.showGlow) _buildGlowLayer(effectiveGlow),

            // ── LAYER 2: Progress ring (animated) ────────────
            _buildProgressRing(
              primary: effectivePrimary,
              secondary: effectiveSecondary,
              background: effectiveBackground,
            ),

            // ── LAYER 3: Center content ──────────────────────
            _buildCenterContent(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SECTION 5 — LAYER BUILDERS
  // ============================================================

  /// LAYER 1: Ambient glow effect around ring
  Widget _buildGlowLayer(Color glowColor) {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, _) {
        // Glow intensity based on progress (more progress = stronger glow)
        final double glowIntensity = 0.15 + (_progressAnimation.value * 0.15);

        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: glowColor.withValues(alpha: glowIntensity),
                blurRadius: 20,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: glowColor.withValues(alpha: glowIntensity * 0.5),
                blurRadius: 40,
                spreadRadius: 4,
              ),
            ],
          ),
        );
      },
    );
  }

  /// LAYER 2: Custom-painted progress ring
  Widget _buildProgressRing({
    required Color primary,
    required Color secondary,
    required Color background,
  }) {
    return AnimatedBuilder(
      animation: _progressAnimation,
      builder: (context, _) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _RingPainter(
            progress: _progressAnimation.value,
            strokeWidth: widget.strokeWidth,
            primaryColor: primary,
            secondaryColor: secondary,
            backgroundColor: background,
            style: widget.style,
            direction: widget.direction,
            startAngleDegrees: widget.startAngleDegrees,
            roundedCaps: widget.roundedCaps,
          ),
        );
      },
    );
  }

  /// LAYER 3: Center content (text or custom widget)
  Widget _buildCenterContent() {
    // If custom center widget provided, use it
    if (widget.centerWidget != null) {
      return widget.centerWidget!;
    }

    // Otherwise build text content
    if (widget.centerText == null && widget.subtitleText == null) {
      return const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Center text (main)
        if (widget.centerText != null)
          Text(
            widget.centerText!,
            style: widget.centerTextStyle ??
                TextStyle(
                  fontSize: widget.size * 0.15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.white,
                  fontFamily: 'monospace',
                  height: 1.0,
                  letterSpacing: -0.5,
                ),
            textAlign: TextAlign.center,
          ),

        // Subtitle text (below main)
        if (widget.subtitleText != null) ...[
          const SizedBox(height: 2),
          Text(
            widget.subtitleText!,
            style: widget.subtitleTextStyle ??
                TextStyle(
                  fontSize: widget.size * 0.08,
                  fontWeight: FontWeight.w500,
                  color: AppColors.white.withValues(alpha: 0.70),
                  height: 1.0,
                  letterSpacing: 0.5,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }

  // ============================================================
  // SECTION 6 — HELPERS
  // ============================================================

  /// Lighten a color by given amount (0.0 - 1.0)
  Color _lightenColor(Color color, double amount) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final lightened = hsl.withLightness(
      (hsl.lightness + amount).clamp(0.0, 1.0),
    );
    return lightened.toColor();
  }
}

// ============================================================
// SECTION 7 — CUSTOM PAINTER (draws the ring)
// ============================================================

class _RingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color primaryColor;
  final Color secondaryColor;
  final Color backgroundColor;
  final RingStyle style;
  final RingDirection direction;
  final double startAngleDegrees;
  final bool roundedCaps;

  _RingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundColor,
    required this.style,
    required this.direction,
    required this.startAngleDegrees,
    required this.roundedCaps,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = Offset(size.width / 2, size.height / 2);
    final double radius = (size.width - strokeWidth) / 2;

    // ── BACKGROUND RING (full circle, faded) ─────────────
    final Paint backgroundPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = roundedCaps ? StrokeCap.round : StrokeCap.butt;

    canvas.drawCircle(center, radius, backgroundPaint);

    // ── ACTIVE PROGRESS RING (gradient) ─────────────────
    if (progress <= 0.0) return;

    final Rect ringRect = Rect.fromCircle(center: center, radius: radius);

    // Convert degrees to radians
    final double startAngleRadians = _degreesToRadians(startAngleDegrees);

    // Progress angle (clockwise or counter-clockwise)
    double sweepAngle = 2 * math.pi * progress;
    if (direction == RingDirection.counterClockwise) {
      sweepAngle = -sweepAngle;
    }

    // Create paint with style
    final Paint progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = roundedCaps ? StrokeCap.round : StrokeCap.butt;

    // Apply color/gradient based on style
    switch (style) {
      case RingStyle.solid:
        progressPaint.color = primaryColor;
        break;

      case RingStyle.gradient:
        progressPaint.shader = SweepGradient(
          startAngle: startAngleRadians,
          endAngle: startAngleRadians + sweepAngle,
          colors: [primaryColor, secondaryColor, primaryColor],
          stops: const [0.0, 0.5, 1.0],
          tileMode: TileMode.clamp,
        ).createShader(ringRect);
        break;

      case RingStyle.rainbow:
        progressPaint.shader = SweepGradient(
          startAngle: startAngleRadians,
          endAngle: startAngleRadians + (2 * math.pi),
          colors: [
            primaryColor,
            secondaryColor,
            AppColors.accent,
            primaryColor,
          ],
          stops: const [0.0, 0.33, 0.66, 1.0],
          tileMode: TileMode.clamp,
        ).createShader(ringRect);
        break;
    }

    // Draw the arc
    canvas.drawArc(
      ringRect,
      startAngleRadians,
      sweepAngle,
      false,
      progressPaint,
    );

    // ── END DOT (small glow at the end of progress) ─────
    if (progress > 0.05 && progress < 1.0) {
      final double endAngle = startAngleRadians + sweepAngle;
      final double dotX = center.dx + radius * math.cos(endAngle);
      final double dotY = center.dy + radius * math.sin(endAngle);

      // Outer glow
      final Paint dotGlowPaint = Paint()
        ..color = primaryColor.withValues(alpha: 0.40)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(Offset(dotX, dotY), strokeWidth * 0.8, dotGlowPaint);

      // Inner dot (bright)
      final Paint dotPaint = Paint()
        ..color = AppColors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(dotX, dotY), strokeWidth * 0.35, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.secondaryColor != secondaryColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }

  /// Convert degrees to radians
  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }
}

// ============================================================
// SECTION 8 — PRE-CONFIGURED VARIANTS (convenience widgets)
// ============================================================

/// Pre-configured countdown ring for prayer times
class AppPrayerCountdownRing extends StatelessWidget {
  final Duration timeRemaining;
  final Duration totalDuration;
  final double size;

  const AppPrayerCountdownRing({
    super.key,
    required this.timeRemaining,
    required this.totalDuration,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate progress (how much time has elapsed)
    final double elapsed = 1.0 -
        (timeRemaining.inSeconds / totalDuration.inSeconds).clamp(0.0, 1.0);

    // Format countdown as HH:MM:SS
    final String countdown = _formatDuration(timeRemaining);

    return AppCircularProgressRing(
      progress: elapsed,
      size: size,
      strokeWidth: 6,
      centerText: countdown,
      subtitleText: 'remaining',
      primaryColor: AppColors.white,
      secondaryColor: AppColors.accent,
      backgroundColor: AppColors.white.withValues(alpha: 0.20),
      showGlow: true,
      glowColor: AppColors.accent,
      style: RingStyle.gradient,
      centerTextStyle: TextStyle(
        fontSize: size * 0.13,
        fontWeight: FontWeight.w800,
        color: AppColors.white,
        fontFamily: 'monospace',
        height: 1.0,
        letterSpacing: -0.5,
      ),
      subtitleTextStyle: TextStyle(
        fontSize: size * 0.075,
        fontWeight: FontWeight.w500,
        color: AppColors.white.withValues(alpha: 0.75),
        height: 1.0,
        letterSpacing: 0.5,
      ),
    );
  }

  /// Format duration as HH:MM:SS
  String _formatDuration(Duration duration) {
    final int total = duration.inSeconds;
    final int hours = total ~/ 3600;
    final int minutes = (total % 3600) ~/ 60;
    final int seconds = total % 60;
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}

/// Pre-configured Ramadan progress ring
class AppRamadanProgressRing extends StatelessWidget {
  final int currentDay;
  final int totalDays;
  final double size;

  const AppRamadanProgressRing({
    super.key,
    required this.currentDay,
    this.totalDays = 30,
    this.size = 120,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = (currentDay / totalDays).clamp(0.0, 1.0);

    return AppCircularProgressRing(
      progress: progress,
      size: size,
      strokeWidth: 8,
      centerText: '$currentDay',
      subtitleText: 'of $totalDays',
      primaryColor: const Color(0xFFFFD700),
      secondaryColor: const Color(0xFFFFB84D),
      backgroundColor: AppColors.white.withValues(alpha: 0.15),
      showGlow: true,
      glowColor: const Color(0xFFFFD700),
      style: RingStyle.gradient,
    );
  }
}

/// Pre-configured reading progress ring
class AppReadingProgressRing extends StatelessWidget {
  final double progress; // 0.0 - 1.0
  final double size;

  const AppReadingProgressRing({
    super.key,
    required this.progress,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    final int percentage = (progress * 100).round();

    return AppCircularProgressRing(
      progress: progress,
      size: size,
      strokeWidth: 5,
      centerText: '$percentage%',
      primaryColor: AppColors.primary,
      secondaryColor: AppColors.accent,
      backgroundColor: AppColors.borderSubtle,
      showGlow: false,
      style: RingStyle.gradient,
      centerTextStyle: TextStyle(
        fontSize: size * 0.20,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        height: 1.0,
      ),
    );
  }
}

// ============================================================
// END OF FILE — app_circular_progress_ring.dart (v1.0)
// ============================================================
