// lib/core/design_system/qibra_colors_next.dart
// ============================================================
// QIBRA AI — Semantic theme-extension tokens (MIDNIGHT NAVY).
// Product-owner override: navy identity is the global brand.
// Values are derived from [QibraNavy] so tokens never drift.
// Dark is the primary identity; the light theme maps Family A
// palette onto the same semantic fields for migration.
// ============================================================

import 'package:flutter/material.dart';

import 'qibra_navy.dart';

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
    this.info = QibraNavy.blue,
    this.infoCyan = QibraNavy.cyan,
    this.warning = QibraNavy.orange,
    this.success = QibraNavy.emerald,
    this.heroVioletDeep = QibraNavy.violetDeep,
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

  /// Errors / destructive actions only.
  final Color error;

  /// Informational states, search, hadith contexts.
  final Color info;
  final Color infoCyan;

  /// Warnings / streak reminders (never decoration).
  final Color warning;

  /// Completion / positive states.
  final Color success;

  /// Deeper violet stop for AI surfaces.
  final Color heroVioletDeep;

  /// The approved midnight-navy identity.
  static const QibraColorsNext dark = QibraColorsNext(
    bgCanvas: QibraNavy.canvas,
    bgSurface: QibraNavy.surface,
    bgCard: QibraNavy.card,
    bgCardElevated: QibraNavy.cardElevated,
    borderSubtle: QibraNavy.hairline,
    emeraldPrimary: QibraNavy.emerald,
    emeraldDeep: QibraNavy.emeraldDeep,
    goldIslamic: QibraNavy.gold,
    goldSoft: QibraNavy.goldBright,
    violetAi: QibraNavy.violet,
    textPrimary: QibraNavy.textPrimary,
    textSecondary: QibraNavy.textSecondary,
    textMuted: QibraNavy.textMuted,
    error: QibraNavy.red,
    info: QibraNavy.blue,
    infoCyan: QibraNavy.cyan,
    warning: QibraNavy.orange,
    success: QibraNavy.emerald,
    heroVioletDeep: QibraNavy.violetDeep,
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
    Color? info,
    Color? infoCyan,
    Color? warning,
    Color? success,
    Color? heroVioletDeep,
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
      info: info ?? this.info,
      infoCyan: infoCyan ?? this.infoCyan,
      warning: warning ?? this.warning,
      success: success ?? this.success,
      heroVioletDeep: heroVioletDeep ?? this.heroVioletDeep,
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
      info: Color.lerp(info, other.info, t)!,
      infoCyan: Color.lerp(infoCyan, other.infoCyan, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      success: Color.lerp(success, other.success, t)!,
      heroVioletDeep:
          Color.lerp(heroVioletDeep, other.heroVioletDeep, t)!,
    );
  }
}
