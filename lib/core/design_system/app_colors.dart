// lib/core/design_system/app_colors.dart
//
// QIBRA AI — Unified colour system
// Warm Ivory + Deep Forest Green + Sage + Champagne Gold
// Token names are preserved so existing AppColors.* call sites keep compiling.

import 'package:flutter/material.dart';

// ============================================================
// FOREST / SAGE PALETTE
// ============================================================

abstract final class AppEmerald {
  static const Color s50 = Color(0xFFEEF1EA);
  static const Color s100 = Color(0xFFDCE6DF);
  static const Color s200 = Color(0xFFB7CDC4);
  static const Color s300 = Color(0xFF7BA396);
  static const Color s400 = Color(0xFF2F6B5D);
  static const Color s500 = Color(0xFF123F36);
  static const Color s600 = Color(0xFF0E332C);
  static const Color s700 = Color(0xFF0A2822);
  static const Color s800 = Color(0xFF071C18);
  static const Color s900 = Color(0xFF041210);

  static const Color primary = s500;
  static const Color light = s200;
  static const Color dark = s700;
  static const Color deepest = s900;

  static Color get tint10 => s500.withValues(alpha: 0.10);
  static Color get tint20 => s500.withValues(alpha: 0.20);
  static Color get tint30 => s500.withValues(alpha: 0.30);
  static Color get tint50 => s500.withValues(alpha: 0.50);
}

// ============================================================
// CHAMPAGNE GOLD PALETTE
// ============================================================

abstract final class AppGold {
  static const Color s50 = Color(0xFFF8F1E3);
  static const Color s100 = Color(0xFFF0E4C8);
  static const Color s200 = Color(0xFFE4D0A0);
  static const Color s300 = Color(0xFFD4B87A);
  static const Color s400 = Color(0xFFCDB06A);
  static const Color s500 = Color(0xFFC6A15B);
  static const Color royal = Color(0xFFC6A15B);
  static const Color s600 = Color(0xFFA88748);
  static const Color s700 = Color(0xFF8A6D38);
  static const Color s800 = Color(0xFF6B542B);
  static const Color s900 = Color(0xFF4A3A1D);

  static const Color primary = s500;
  static const Color bright = s400;
  static const Color dark = s700;

  static Color get tint10 => s500.withValues(alpha: 0.10);
  static Color get tint20 => s500.withValues(alpha: 0.20);
  static Color get tint30 => s500.withValues(alpha: 0.30);
  static Color get tint50 => s500.withValues(alpha: 0.50);
}

// ============================================================
// WARM NEUTRALS
// ============================================================

abstract final class AppNeutral {
  static const Color s0 = Color(0xFFFEFDF9);
  static const Color s50 = Color(0xFFF5F3EC);
  static const Color s100 = Color(0xFFEEF1EA);
  static const Color s200 = Color(0xFFE4E0D5);
  static const Color s300 = Color(0xFFD4CFC3);
  static const Color s400 = Color(0xFFA3ADA9);
  static const Color s500 = Color(0xFF71807A);
  static const Color s600 = Color(0xFF4A5A54);
  static const Color s700 = Color(0xFF2C3B36);
  static const Color s800 = Color(0xFF19312C);
  static const Color s900 = Color(0xFF121C19);
  static const Color s1000 = Color(0xFF000000);
}

// ============================================================
// SEMANTIC
// ============================================================

abstract final class AppSemanticColors {
  static const Color successLight = Color(0xFFDCE6DF);
  static const Color success = Color(0xFF2F6B5D);
  static const Color successDark = Color(0xFF123F36);

  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color error = Color(0xFFB42318);
  static const Color errorDark = Color(0xFF7F1D1D);

  static const Color warningLight = Color(0xFFF8F1E3);
  static const Color warning = Color(0xFFC6A15B);
  static const Color warningDark = Color(0xFF8A6D38);

  static const Color infoLight = Color(0xFFEEF1EA);
  static const Color info = Color(0xFF2F6B5D);
  static const Color infoDark = Color(0xFF123F36);
}

// ============================================================
// SURFACES (Light — primary identity)
// ============================================================

abstract final class AppSurface {
  static const Color background = Color(0xFFF5F3EC);
  static const Color backgroundPrimary = Color(0xFFF5F3EC);
  static const Color backgroundSecondary = Color(0xFFEEF1EA);
  static const Color backgroundTertiary = Color(0xFFE8EBE3);

  static const Color card = Color(0xFFFEFDF9);
  static const Color cardElevated = Color(0xFFFEFDF9);
  static const Color cardHigh = Color(0xFFF8F6EF);
  static const Color cardHighest = Color(0xFFF3F0E6);

  static const Color sheet = Color(0xFFFEFDF9);
  static const Color modal = Color(0xFFFEFDF9);

  static const Color inputBackground = Color(0xFFFEFDF9);
  static const Color inputFocused = Color(0xFFFEFDF9);

  static const Color bottomNav = Color(0xFFFEFDF9);
  static const Color appBar = Color(0xFFF5F3EC);

  static const Color divider = Color(0xFFE4E0D5);
  static const Color dividerStrong = Color(0xFFD4CFC3);
}

// ============================================================
// TEXT
// ============================================================

abstract final class AppTextColors {
  static const Color primary = Color(0xFF19312C);
  static const Color body = Color(0xFF19312C);
  static const Color secondary = Color(0xFF71807A);
  static const Color tertiary = Color(0xFF8A9691);
  static const Color disabled = Color(0xFFA3ADA9);
  static const Color hint = Color(0xFFA3ADA9);

  static const Color emerald = Color(0xFF123F36);
  static const Color gold = Color(0xFFC6A15B);
  static const Color goldRoyal = Color(0xFFC6A15B);
  static const Color goldBright = Color(0xFFC6A15B);

  static const Color error = Color(0xFFB42318);
  static const Color success = Color(0xFF2F6B5D);
  static const Color warning = Color(0xFFC6A15B);
  static const Color info = Color(0xFF2F6B5D);

  static const Color inverse = Color(0xFFFEFDF9);
  static const Color onGold = Color(0xFF19312C);
  static const Color onEmerald = Color(0xFFFEFDF9);
}

abstract final class AppIconColors {
  static const Color primary = Color(0xFF19312C);
  static const Color secondary = Color(0xFF71807A);
  static const Color emerald = Color(0xFF123F36);
  static const Color gold = Color(0xFFC6A15B);
  static const Color disabled = Color(0xFFA3ADA9);
  static const Color error = Color(0xFFB42318);
  static const Color warning = Color(0xFFC6A15B);
}

abstract final class AppBorderColors {
  static const Color subtle = Color(0xFFE4E0D5);
  static const Color standard = Color(0xFFE4E0D5);
  static const Color strong = Color(0xFFD4CFC3);
  static const Color emerald = Color(0xFF123F36);
  static Color get emeraldSubtle =>
      const Color(0xFF123F36).withValues(alpha: 0.22);
  static const Color gold = Color(0xFFC6A15B);
  static const Color royalGold = Color(0xFFC6A15B);
  static Color get goldSubtle =>
      const Color(0xFFC6A15B).withValues(alpha: 0.28);
  static const Color error = Color(0xFFB42318);
  static const Color focus = Color(0xFF123F36);
  static const Color transparent = Colors.transparent;
}

// ============================================================
// MAIN AppColors
// ============================================================

abstract final class AppColors {
  static const Color primary = AppEmerald.s500;
  static const Color primaryLight = AppEmerald.s400;
  static const Color primaryDark = AppEmerald.s600;

  static const Color accent = AppGold.s500;
  static const Color accentLight = AppGold.s300;
  static const Color accentDark = AppGold.s700;
  static const Color accentBright = AppGold.s400;

  static const Color background = AppSurface.backgroundPrimary;
  static const Color backgroundSecondary = AppSurface.backgroundSecondary;
  static const Color backgroundTertiary = AppSurface.backgroundTertiary;

  static const Color surface = AppSurface.card;
  static const Color surfaceElevated = AppSurface.cardElevated;
  static const Color surfaceHigh = AppSurface.cardHigh;
  static const Color surfaceHighest = AppSurface.cardHighest;
  static const Color surfaceSheet = AppSurface.sheet;
  static const Color surfaceModal = AppSurface.modal;

  static const Color textPrimary = AppTextColors.primary;
  static const Color textBody = AppTextColors.body;
  static const Color textSecondary = AppTextColors.secondary;
  static const Color textTertiary = AppTextColors.tertiary;
  static const Color textDisabled = AppTextColors.disabled;
  static const Color textHint = AppTextColors.hint;
  static const Color textEmerald = AppTextColors.emerald;
  static const Color textGold = AppTextColors.gold;
  static const Color textOnGold = AppTextColors.onGold;
  static const Color textOnEmerald = AppTextColors.onEmerald;

  static const Color iconPrimary = AppIconColors.primary;
  static const Color iconSecondary = AppIconColors.secondary;
  static const Color iconEmerald = AppIconColors.emerald;
  static const Color iconGold = AppIconColors.gold;

  static const Color borderSubtle = AppBorderColors.subtle;
  static const Color borderStandard = AppBorderColors.standard;
  static const Color borderStrong = AppBorderColors.strong;
  static const Color borderEmerald = AppBorderColors.emerald;
  static const Color borderGold = AppBorderColors.gold;
  static const Color borderError = AppBorderColors.error;
  static const Color borderFocus = AppBorderColors.focus;

  static const Color success = AppSemanticColors.success;
  static const Color successLight = AppSemanticColors.successLight;
  static const Color successDark = AppSemanticColors.successDark;
  static const Color error = AppSemanticColors.error;
  static const Color errorLight = AppSemanticColors.errorLight;
  static const Color errorDark = AppSemanticColors.errorDark;
  static const Color warning = AppSemanticColors.warning;
  static const Color warningLight = AppSemanticColors.warningLight;
  static const Color warningDark = AppSemanticColors.warningDark;
  static const Color info = AppSemanticColors.info;
  static const Color infoLight = AppSemanticColors.infoLight;
  static const Color infoDark = AppSemanticColors.infoDark;

  static const Color navBackground = AppSurface.bottomNav;
  static const Color navActive = AppEmerald.s500;
  static const Color navInactive = AppNeutral.s500;

  static const Color inputBackground = AppSurface.inputBackground;
  static const Color inputFocused = AppSurface.inputFocused;

  static const Color divider = AppSurface.divider;
  static const Color dividerStrong = AppSurface.dividerStrong;

  static const Color transparent = Colors.transparent;
  static const Color white = Color(0xFFFEFDF9);
  static const Color black = Color(0xFF19312C);

  static Color get overlay => const Color(0xFF19312C).withValues(alpha: 0.40);
  static Color get scrim => const Color(0xFF19312C).withValues(alpha: 0.45);

  static const Color shimmerBase = Color(0xFFEEF1EA);
  static const Color shimmerHighlight = Color(0xFFFEFDF9);
}

// ============================================================
// DARK VARIANT (forest night — not neon)
// ============================================================

abstract final class AppColorsDark {
  static const Color background = Color(0xFF121916);
  static const Color backgroundSecondary = Color(0xFF171F1B);
  static const Color surface = Color(0xFF1C2621);
  static const Color surfaceElevated = Color(0xFF222E28);
  static const Color surfaceHigh = Color(0xFF28352E);
  static const Color primary = Color(0xFF8FB8A8);
  static const Color primaryDeep = Color(0xFF2F6B5D);
  static const Color accent = Color(0xFFC6A15B);
  static const Color textPrimary = Color(0xFFF5F3EC);
  static const Color textSecondary = Color(0xFF9AA8A2);
  static const Color textTertiary = Color(0xFF7A8882);
  static const Color border = Color(0xFF2A332E);
  static const Color navBackground = Color(0xFF171F1B);
}
