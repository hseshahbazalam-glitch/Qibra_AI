// lib/core/widgets/glassmorphic_card.dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:qibra_ai/core/design_system/app_colors.dart';

class GlassmorphicCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final Gradient? borderGradient;
  final Gradient? gradient;

  const GlassmorphicCard({
    super.key,
    required this.child,
    this.borderRadius = 24.0,
    this.padding,
    this.borderGradient,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Stack(
        children: [
          // The blurred background
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: const BoxDecoration(
                color:
                    Colors.transparent, // Important: The filter needs a child
              ),
            ),
          ),
          // The gradient and color overlay
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              color: AppColors.surface,
              gradient: gradient,
              border: Border.all(
                width: 1.5,
                color: const Color.fromRGBO(255, 255, 255, 0.15),
              ),
            ),
          ),
          // The border gradient (if any)
          if (borderGradient != null)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                border: GradientBoxBorder(
                  // Custom border class
                  gradient: borderGradient!,
                  width: 1.5,
                ),
              ),
            ),
          // The actual content of the card
          Padding(
            padding: padding ?? const EdgeInsets.all(16.0),
            child: child,
          ),
        ],
      ),
    );
  }
}

// We need to add this helper class for gradient borders since Flutter's
// default Border doesn't support gradients.
class GradientBoxBorder extends BoxBorder {
  const GradientBoxBorder({
    required this.gradient,
    this.width = 1.0,
  });

  final Gradient gradient;
  final double width;

  @override
  BorderSide get bottom => BorderSide.none;

  @override
  BorderSide get top => BorderSide.none;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.all(width);

  @override
  bool get isUniform => true;

  @override
  void paint(
    Canvas canvas,
    Rect rect, {
    TextDirection? textDirection,
    BoxShape shape = BoxShape.rectangle,
    BorderRadius? borderRadius,
  }) {
    if (borderRadius != null) {
      _paintRRect(canvas, rect, borderRadius);
      return;
    }
    _paintRect(canvas, rect);
  }

  void _paintRect(Canvas canvas, Rect rect) {
    canvas.drawRect(rect, _getPaint(rect));
  }

  void _paintRRect(Canvas canvas, Rect rect, BorderRadius borderRadius) {
    final rrect = borderRadius.toRRect(rect);
    canvas.drawRRect(rrect, _getPaint(rect));
  }

  @override
  ShapeBorder scale(double t) {
    return GradientBoxBorder(
      gradient: gradient.scale(t),
      width: width * t,
    );
  }

  Paint _getPaint(Rect rect) {
    return Paint()
      ..strokeWidth = width
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke;
  }
}
