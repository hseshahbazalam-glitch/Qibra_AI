// Contrast helpers — WCAG-ish checks against Family A tokens.
// Gold fill #C6A15B is not used as body text. Gold TEXT is #6B542B.

import 'dart:math' as math;

import 'package:flutter/material.dart';

abstract final class Contrast {
  static const Color goldText = Color(0xFF6B542B);
  static const Color ivory = Color(0xFFFEFDF9);
  static const Color ivoryCanvas = Color(0xFFF5F3EC);
  static const Color forest = Color(0xFF123F36);
  static const Color ink = Color(0xFF19312C);
  static const Color muted = Color(0xFF4A5A54);
  static const Color danger = Color(0xFFB42318);

  static double relativeLuminance(Color color) {
    double channel(double c) {
      final v = c;
      return v <= 0.04045 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    }

    final r = channel(color.r);
    final g = channel(color.g);
    final b = channel(color.b);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  static double ratio(Color a, Color b) {
    final l1 = relativeLuminance(a);
    final l2 = relativeLuminance(b);
    final lighter = math.max(l1, l2);
    final darker = math.min(l1, l2);
    return (lighter + 0.05) / (darker + 0.05);
  }

  static bool meetsAa(Color foreground, Color background, {bool largeText = false}) {
    return ratio(foreground, background) >= (largeText ? 3.0 : 4.5);
  }

  /// Body text on ivory must use ink or forest, never champagne gold fill.
  static Color readableOnIvory({required bool emphasis}) {
    return emphasis ? forest : ink;
  }
}
