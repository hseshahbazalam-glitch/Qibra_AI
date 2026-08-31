// Dark-first identity (product-owner approved).
// Old QibraColors stays compiling for migration.

import 'package:flutter/material.dart';

@immutable
class QibraColorsNext extends ThemeExtension<QibraColorsNext> {
  const QibraColorsNext({
    required this.bgCanvas,
    required this.bgSurface,
    required this.bgCard,
    required this.bgCardElevated,
    required this.borderSubtle,
    required this.emeraldPrimary,
    required this.emeraldDeep,
    required this.goldIslamic,
    required this.goldSoft,
    required this.violetAi,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.error,
  });

  final Color bgCanvas;
  final Color bgSurface;
  final Color bgCard;
  final Color bgCardElevated;
  final Color borderSubtle;
  final Color emeraldPrimary;
  final Color emeraldDeep;
  final Color goldIslamic;
  final Color goldSoft;
  final Color violetAi;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color error;

  static const QibraColorsNext dark = QibraColorsNext(
    bgCanvas: Color(0xFF071512),
    bgSurface: Color(0xFF0B1D19),
    bgCard: Color(0xFF102721),
    bgCardElevated: Color(0xFF14332A),
    borderSubtle: Color(0xFF244139),
    emeraldPrimary: Color(0xFF2ED39A),
    emeraldDeep: Color(0xFF0F8F68),
    goldIslamic: Color(0xFFD7AD5A),
    goldSoft: Color(0xFFF0D58A),
    violetAi: Color(0xFF9B6CFF),
    textPrimary: Color(0xFFF4F7F4),
    textSecondary: Color(0xFFA9B8B2),
    textMuted: Color(0xFF71817B),
    error: Color(0xFFE5484D),
  );

  static QibraColorsNext of(BuildContext context) {
    return Theme.of(context).extension<QibraColorsNext>() ??
        QibraColorsNext.dark;
  }

  @override
  QibraColorsNext copyWith({
    Color? bgCanvas,
    Color? bgSurface,
    Color? bgCard,
    Color? bgCardElevated,
    Color? borderSubtle,
    Color? emeraldPrimary,
    Color? emeraldDeep,
    Color? goldIslamic,
    Color? goldSoft,
    Color? violetAi,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
    Color? error,
  }) {
    return QibraColorsNext(
      bgCanvas: bgCanvas ?? this.bgCanvas,
      bgSurface: bgSurface ?? this.bgSurface,
      bgCard: bgCard ?? this.bgCard,
      bgCardElevated: bgCardElevated ?? this.bgCardElevated,
      borderSubtle: borderSubtle ?? this.borderSubtle,
      emeraldPrimary: emeraldPrimary ?? this.emeraldPrimary,
      emeraldDeep: emeraldDeep ?? this.emeraldDeep,
      goldIslamic: goldIslamic ?? this.goldIslamic,
      goldSoft: goldSoft ?? this.goldSoft,
      violetAi: violetAi ?? this.violetAi,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textMuted: textMuted ?? this.textMuted,
      error: error ?? this.error,
    );
  }

  @override
  QibraColorsNext lerp(ThemeExtension<QibraColorsNext>? other, double t) {
    if (other is! QibraColorsNext) return this;
    return QibraColorsNext(
      bgCanvas: Color.lerp(bgCanvas, other.bgCanvas, t)!,
      bgSurface: Color.lerp(bgSurface, other.bgSurface, t)!,
      bgCard: Color.lerp(bgCard, other.bgCard, t)!,
      bgCardElevated: Color.lerp(bgCardElevated, other.bgCardElevated, t)!,
      borderSubtle: Color.lerp(borderSubtle, other.borderSubtle, t)!,
      emeraldPrimary: Color.lerp(emeraldPrimary, other.emeraldPrimary, t)!,
      emeraldDeep: Color.lerp(emeraldDeep, other.emeraldDeep, t)!,
      goldIslamic: Color.lerp(goldIslamic, other.goldIslamic, t)!,
      goldSoft: Color.lerp(goldSoft, other.goldSoft, t)!,
      violetAi: Color.lerp(violetAi, other.violetAi, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
      error: Color.lerp(error, other.error, t)!,
    );
  }
}
