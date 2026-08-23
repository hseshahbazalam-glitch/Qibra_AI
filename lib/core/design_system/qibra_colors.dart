// lib/core/design_system/qibra_colors.dart
// Theme-aware palette so light/dark both stay on-brand.

import 'package:flutter/material.dart';
import 'app_colors.dart';

@immutable
class QibraColors extends ThemeExtension<QibraColors> {
  const QibraColors({
    required this.background,
    required this.backgroundSecondary,
    required this.card,
    required this.cardMuted,
    required this.primary,
    required this.primarySoft,
    required this.secondary,
    required this.accent,
    required this.goldFill,
    required this.goldText,
    required this.forest,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.border,
    required this.navBackground,
    required this.onPrimary,
  });

  final Color background;
  final Color backgroundSecondary;
  final Color card;
  final Color cardMuted;
  final Color primary;
  final Color primarySoft;
  final Color secondary;
  final Color accent;
  final Color goldFill;
  final Color goldText;
  final Color forest;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color border;
  final Color navBackground;
  final Color onPrimary;

  static const QibraColors light = QibraColors(
    background: Color(0xFFF5F3EC),
    backgroundSecondary: Color(0xFFEEF1EA),
    card: Color(0xFFFEFDF9),
    cardMuted: Color(0xFFF8F6EF),
    primary: Color(0xFF123F36),
    primarySoft: Color(0xFF2F6B5D),
    secondary: Color(0xFF2F6B5D),
    accent: Color(0xFFC6A15B),
    goldFill: Color(0xFFC6A15B),
    goldText: Color(0xFF6B542B),
    forest: Color(0xFF123F36),
    textPrimary: Color(0xFF19312C),
    textSecondary: Color(0xFF71807A),
    textTertiary: Color(0xFF8A9691),
    border: Color(0xFFE4E0D5),
    navBackground: Color(0xFFFEFDF9),
    onPrimary: Color(0xFFFEFDF9),
  );

  static const QibraColors dark = QibraColors(
    // Midnight reading surfaces: intentionally not navy or pure black.
    background: Color(0xFF0B1210),
    backgroundSecondary: Color(0xFF15201C),
    card: Color(0xFF15201C),
    cardMuted: Color(0xFF222E28),
    primary: Color(0xFF8FB8A8),
    primarySoft: Color(0xFF2F6B5D),
    secondary: Color(0xFF8FB8A8),
    accent: Color(0xFFC6A15B),
    goldFill: Color(0xFFC6A15B),
    goldText: Color(0xFF6B542B),
    forest: Color(0xFF123F36),
    textPrimary: Color(0xFFF5F3EC),
    textSecondary: Color(0xFF9AA8A2),
    textTertiary: Color(0xFF7A8882),
    border: Color(0xFF2A332E),
    navBackground: Color(0xFF171F1B),
    onPrimary: Color(0xFF121916),
  );

  static QibraColors of(BuildContext context) {
    return Theme.of(context).extension<QibraColors>() ?? QibraColors.light;
  }

  bool get isDark => background == dark.background;

  @override
  QibraColors copyWith({
    Color? background,
    Color? backgroundSecondary,
    Color? card,
    Color? cardMuted,
    Color? primary,
    Color? primarySoft,
    Color? secondary,
    Color? accent,
    Color? goldFill,
    Color? goldText,
    Color? forest,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? border,
    Color? navBackground,
    Color? onPrimary,
  }) {
    return QibraColors(
      background: background ?? this.background,
      backgroundSecondary: backgroundSecondary ?? this.backgroundSecondary,
      card: card ?? this.card,
      cardMuted: cardMuted ?? this.cardMuted,
      primary: primary ?? this.primary,
      primarySoft: primarySoft ?? this.primarySoft,
      secondary: secondary ?? this.secondary,
      accent: accent ?? this.accent,
      goldFill: goldFill ?? this.goldFill,
      goldText: goldText ?? this.goldText,
      forest: forest ?? this.forest,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      border: border ?? this.border,
      navBackground: navBackground ?? this.navBackground,
      onPrimary: onPrimary ?? this.onPrimary,
    );
  }

  @override
  QibraColors lerp(ThemeExtension<QibraColors>? other, double t) {
    if (other is! QibraColors) return this;
    return QibraColors(
      background: Color.lerp(background, other.background, t)!,
      backgroundSecondary:
          Color.lerp(backgroundSecondary, other.backgroundSecondary, t)!,
      card: Color.lerp(card, other.card, t)!,
      cardMuted: Color.lerp(cardMuted, other.cardMuted, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primarySoft: Color.lerp(primarySoft, other.primarySoft, t)!,
      secondary: Color.lerp(secondary, other.secondary, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      border: Color.lerp(border, other.border, t)!,
      navBackground: Color.lerp(navBackground, other.navBackground, t)!,
      onPrimary: Color.lerp(onPrimary, other.onPrimary, t)!,
    );
  }
}

/// Convenience so existing AppColors tokens still resolve in const contexts.
abstract final class QibraTokens {
  static const Color ivory = AppColors.background;
  static const Color card = AppColors.surface;
  static const Color forest = AppColors.primary;
  static const Color sage = AppColors.primaryLight;
  static const Color gold = AppColors.accent;
  static const Color goldFill = Color(0xFFC6A15B);
  static const Color goldText = Color(0xFF6B542B);
}
