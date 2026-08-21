// lib/core/design_system/app_typography.dart
// ============================================================
// QIBRA AI — PREMIUM TYPOGRAPHY SYSTEM (Arabic & English Getters)
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract final class AppFontFamily {
  static const String primary = 'Poppins';
  static const String arabic = 'Amiri';
  static const String mono = 'monospace';
}

abstract final class AppFontWeight {
  static const FontWeight thin = FontWeight.w100;
  static const FontWeight extraLight = FontWeight.w200;
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semiBold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static const FontWeight extraBold = FontWeight.w800;
  static const FontWeight black = FontWeight.w900;
}

abstract final class AppFontSize {
  static const double displayLarge = 57.0;
  static const double displayMedium = 45.0;
  static const double displaySmall = 36.0;
  static const double headlineLarge = 32.0;
  static const double headlineMedium = 28.0;
  static const double headlineSmall = 24.0;
  static const double titleLarge = 22.0;
  static const double titleMedium = 18.0;
  static const double titleSmall = 16.0;
  static const double bodyLarge = 16.0;
  static const double bodyMedium = 14.0;
  static const double bodySmall = 12.0;
  static const double labelLarge = 14.0;
  static const double labelMedium = 12.0;
  static const double labelSmall = 11.0;
  static const double labelXSmall = 10.0;
  static const double arabicSmall = 18.0;
  static const double arabicMedium = 22.0;
  static const double arabicLarge = 28.0;
  static const double arabicDisplay = 36.0;
  static const double arabicHero = 48.0;
}

abstract final class AppLineHeight {
  static const double tight = 1.0;
  static const double snug = 1.2;
  static const double compact = 1.3;
  static const double normal = 1.4;
  static const double relaxed = 1.5;
  static const double loose = 1.6;
  static const double extraLoose = 1.8;
  static const double double_ = 2.0;
  static const double arabicNormal = 1.8;
  static const double arabicRelaxed = 2.2;
  static const double arabicLoose = 2.5;
}

abstract final class AppLetterSpacing {
  static const double tighter = -0.5;
  static const double tight = -0.25;
  static const double normal = 0.0;
  static const double wide = 0.15;
  static const double wider = 0.5;
  static const double widest = 1.0;
  static const double ultraWide = 2.0;
  static const double max = 4.0;
}

abstract final class AppTextStyles {
  static TextStyle get displayLarge => GoogleFonts.poppins(
      fontSize: AppFontSize.displayLarge,
      fontWeight: AppFontWeight.black,
      color: AppColors.textPrimary,
      height: AppLineHeight.snug,
      letterSpacing: AppLetterSpacing.tighter);
  static TextStyle get displayMedium => GoogleFonts.poppins(
      fontSize: AppFontSize.displayMedium,
      fontWeight: AppFontWeight.extraBold,
      color: AppColors.textPrimary,
      height: AppLineHeight.snug,
      letterSpacing: AppLetterSpacing.tighter);
  static TextStyle get displaySmall => GoogleFonts.poppins(
      fontSize: AppFontSize.displaySmall,
      fontWeight: AppFontWeight.bold,
      color: AppColors.textPrimary,
      height: AppLineHeight.compact,
      letterSpacing: AppLetterSpacing.tight);
  static TextStyle get headlineLarge => GoogleFonts.poppins(
      fontSize: AppFontSize.headlineLarge,
      fontWeight: AppFontWeight.bold,
      color: AppColors.textPrimary,
      height: AppLineHeight.compact,
      letterSpacing: AppLetterSpacing.tight);
  static TextStyle get headlineMedium => GoogleFonts.poppins(
      fontSize: AppFontSize.headlineMedium,
      fontWeight: AppFontWeight.bold,
      color: AppColors.textPrimary,
      height: AppLineHeight.compact,
      letterSpacing: AppLetterSpacing.normal);
  static TextStyle get headlineSmall => GoogleFonts.poppins(
      fontSize: AppFontSize.headlineSmall,
      fontWeight: AppFontWeight.semiBold,
      color: AppColors.textPrimary,
      height: AppLineHeight.compact,
      letterSpacing: AppLetterSpacing.normal);
  static TextStyle get titleLarge => GoogleFonts.poppins(
      fontSize: AppFontSize.titleLarge,
      fontWeight: AppFontWeight.semiBold,
      color: AppColors.textPrimary,
      height: AppLineHeight.normal,
      letterSpacing: AppLetterSpacing.normal);
  static TextStyle get titleMedium => GoogleFonts.poppins(
      fontSize: AppFontSize.titleMedium,
      fontWeight: AppFontWeight.semiBold,
      color: AppColors.textPrimary,
      height: AppLineHeight.normal,
      letterSpacing: AppLetterSpacing.wide);
  static TextStyle get titleSmall => GoogleFonts.poppins(
      fontSize: AppFontSize.titleSmall,
      fontWeight: AppFontWeight.medium,
      color: AppColors.textPrimary,
      height: AppLineHeight.normal,
      letterSpacing: AppLetterSpacing.wide);
  static TextStyle get bodyLarge => GoogleFonts.poppins(
      fontSize: AppFontSize.bodyLarge,
      fontWeight: AppFontWeight.regular,
      color: AppColors.textPrimary,
      height: AppLineHeight.relaxed,
      letterSpacing: AppLetterSpacing.normal);
  static TextStyle get bodyMedium => GoogleFonts.poppins(
      fontSize: AppFontSize.bodyMedium,
      fontWeight: AppFontWeight.regular,
      color: AppColors.textPrimary,
      height: AppLineHeight.relaxed,
      letterSpacing: AppLetterSpacing.normal);
  static TextStyle get bodySmall => GoogleFonts.poppins(
      fontSize: AppFontSize.bodySmall,
      fontWeight: AppFontWeight.regular,
      color: AppColors.textSecondary,
      height: AppLineHeight.normal,
      letterSpacing: AppLetterSpacing.normal);
  static TextStyle get labelLarge => GoogleFonts.poppins(
      fontSize: AppFontSize.labelLarge,
      fontWeight: AppFontWeight.semiBold,
      color: AppColors.textPrimary,
      height: AppLineHeight.tight,
      letterSpacing: AppLetterSpacing.wide);
  static TextStyle get labelMedium => GoogleFonts.poppins(
      fontSize: AppFontSize.labelMedium,
      fontWeight: AppFontWeight.medium,
      color: AppColors.textPrimary,
      height: AppLineHeight.tight,
      letterSpacing: AppLetterSpacing.wide);
  static TextStyle get labelSmall => GoogleFonts.poppins(
      fontSize: AppFontSize.labelSmall,
      fontWeight: AppFontWeight.medium,
      color: AppColors.textSecondary,
      height: AppLineHeight.tight,
      letterSpacing: AppLetterSpacing.wider);
  static TextStyle get labelXSmall => GoogleFonts.poppins(
      fontSize: AppFontSize.labelXSmall,
      fontWeight: AppFontWeight.regular,
      color: AppColors.textTertiary,
      height: AppLineHeight.tight,
      letterSpacing: AppLetterSpacing.widest);
  static TextStyle get buttonLarge => GoogleFonts.poppins(
      fontSize: AppFontSize.labelLarge,
      fontWeight: AppFontWeight.semiBold,
      color: AppColors.white,
      height: AppLineHeight.tight,
      letterSpacing: AppLetterSpacing.wide);
  static TextStyle get buttonMedium => GoogleFonts.poppins(
      fontSize: AppFontSize.labelMedium,
      fontWeight: AppFontWeight.semiBold,
      color: AppColors.white,
      height: AppLineHeight.tight,
      letterSpacing: AppLetterSpacing.wide);
  static TextStyle get buttonSmall => GoogleFonts.poppins(
      fontSize: AppFontSize.labelSmall,
      fontWeight: AppFontWeight.medium,
      color: AppColors.white,
      height: AppLineHeight.tight,
      letterSpacing: AppLetterSpacing.wide);
  static TextStyle get inputText => GoogleFonts.poppins(
      fontSize: AppFontSize.bodyLarge,
      fontWeight: AppFontWeight.regular,
      color: AppColors.textPrimary,
      height: AppLineHeight.normal,
      letterSpacing: AppLetterSpacing.normal);
  static TextStyle get inputHint => GoogleFonts.poppins(
      fontSize: AppFontSize.bodyLarge,
      fontWeight: AppFontWeight.regular,
      color: AppColors.textDisabled,
      height: AppLineHeight.normal,
      letterSpacing: AppLetterSpacing.normal);
  static TextStyle get inputLabel => GoogleFonts.poppins(
      fontSize: AppFontSize.labelMedium,
      fontWeight: AppFontWeight.medium,
      color: AppColors.textSecondary,
      height: AppLineHeight.tight,
      letterSpacing: AppLetterSpacing.wide);
  static TextStyle get inputError => GoogleFonts.poppins(
      fontSize: AppFontSize.bodySmall,
      fontWeight: AppFontWeight.regular,
      color: AppColors.error,
      height: AppLineHeight.tight,
      letterSpacing: AppLetterSpacing.normal);

  // --- Arabic Style Aliases for Duas and Qibla ---
  static TextStyle get arabicSmall => AppArabicStyles.quranSmall;
  static TextStyle get arabicMedium => AppArabicStyles.quranMedium;
  static TextStyle get arabicLarge => AppArabicStyles.quranLarge;
  static TextStyle get arabicDisplay => AppArabicStyles.surahName;

  static TextStyle get cardTitle => GoogleFonts.poppins(
      fontSize: AppFontSize.titleMedium,
      fontWeight: AppFontWeight.semiBold,
      color: AppColors.textPrimary,
      height: AppLineHeight.compact,
      letterSpacing: AppLetterSpacing.normal);
  static TextStyle get cardSubtitle => GoogleFonts.poppins(
      fontSize: AppFontSize.bodySmall,
      fontWeight: AppFontWeight.regular,
      color: AppColors.textSecondary,
      height: AppLineHeight.relaxed,
      letterSpacing: AppLetterSpacing.normal);
  static TextStyle get badge => GoogleFonts.poppins(
      fontSize: AppFontSize.labelXSmall,
      fontWeight: AppFontWeight.bold,
      color: AppColors.white,
      height: AppLineHeight.tight,
      letterSpacing: AppLetterSpacing.normal);
  static TextStyle get chip => GoogleFonts.poppins(
      fontSize: AppFontSize.labelMedium,
      fontWeight: AppFontWeight.medium,
      color: AppColors.textSecondary,
      height: AppLineHeight.tight,
      letterSpacing: AppLetterSpacing.normal);
}

abstract final class AppArabicStyles {
  static TextStyle get quranSmall => GoogleFonts.amiri(
      fontSize: AppFontSize.arabicSmall,
      fontWeight: AppFontWeight.regular,
      color: AppColors.textPrimary,
      height: AppLineHeight.arabicNormal);
  static TextStyle get quranMedium => GoogleFonts.amiri(
      fontSize: AppFontSize.arabicMedium,
      fontWeight: AppFontWeight.regular,
      color: AppColors.textPrimary,
      height: AppLineHeight.arabicRelaxed);
  static TextStyle get quranLarge => GoogleFonts.amiri(
      fontSize: AppFontSize.arabicLarge,
      fontWeight: AppFontWeight.regular,
      color: AppColors.textPrimary,
      height: AppLineHeight.arabicLoose);
  static TextStyle get quranBold => GoogleFonts.amiri(
      fontSize: AppFontSize.arabicMedium,
      fontWeight: AppFontWeight.bold,
      color: AppColors.textPrimary,
      height: AppLineHeight.arabicRelaxed);
  static TextStyle get surahName => GoogleFonts.amiri(
      fontSize: AppFontSize.arabicDisplay,
      fontWeight: AppFontWeight.bold,
      color: AppColors.accent,
      height: AppLineHeight.arabicNormal);
  static TextStyle get bismillah => GoogleFonts.amiri(
      fontSize: AppFontSize.arabicDisplay,
      fontWeight: AppFontWeight.bold,
      color: AppColors.accent,
      height: AppLineHeight.arabicRelaxed);
  static TextStyle get bismillahHero => GoogleFonts.amiri(
      fontSize: AppFontSize.arabicHero,
      fontWeight: AppFontWeight.bold,
      color: AppColors.accent,
      height: AppLineHeight.arabicRelaxed);
  static TextStyle get hadithArabic => GoogleFonts.amiri(
      fontSize: AppFontSize.arabicMedium,
      fontWeight: AppFontWeight.regular,
      color: AppColors.textPrimary,
      height: AppLineHeight.arabicRelaxed);
  static TextStyle get duaArabic => GoogleFonts.amiri(
      fontSize: AppFontSize.arabicLarge,
      fontWeight: AppFontWeight.regular,
      color: AppColors.textEmerald,
      height: AppLineHeight.arabicLoose);
  static TextStyle get ayahNumber => GoogleFonts.poppins(
      fontSize: AppFontSize.labelSmall,
      fontWeight: AppFontWeight.semiBold,
      color: AppColors.accent,
      height: AppLineHeight.tight);
  static TextStyle get translation => GoogleFonts.poppins(
      fontSize: AppFontSize.bodyMedium,
      fontWeight: AppFontWeight.regular,
      color: AppColors.textSecondary,
      height: AppLineHeight.loose,
      letterSpacing: AppLetterSpacing.normal);
  static TextStyle get transliteration => GoogleFonts.poppins(
      fontSize: AppFontSize.bodySmall,
      fontWeight: AppFontWeight.light,
      color: AppColors.textTertiary,
      height: AppLineHeight.relaxed,
      letterSpacing: AppLetterSpacing.wide,
      fontStyle: FontStyle.italic);
}

extension TextStyleExtension on TextStyle {
  TextStyle get white => copyWith(color: AppColors.textPrimary);
  TextStyle get secondary => copyWith(color: AppColors.textSecondary);
  TextStyle get tertiary => copyWith(color: AppColors.textTertiary);
  TextStyle get gold => copyWith(color: AppColors.accent);
  TextStyle get goldBright => copyWith(color: AppColors.accentBright);
  TextStyle get emerald => copyWith(color: AppColors.primary);
  TextStyle get error => copyWith(color: AppColors.error);
  TextStyle get success => copyWith(color: AppColors.success);
  TextStyle get warning => copyWith(color: AppColors.warning);
  TextStyle get disabled => copyWith(color: AppColors.textDisabled);
  TextStyle get thin => copyWith(fontWeight: AppFontWeight.thin);
  TextStyle get light => copyWith(fontWeight: AppFontWeight.light);
  TextStyle get regular => copyWith(fontWeight: AppFontWeight.regular);
  TextStyle get medium => copyWith(fontWeight: AppFontWeight.medium);
  TextStyle get semiBold => copyWith(fontWeight: AppFontWeight.semiBold);
  TextStyle get bold => copyWith(fontWeight: AppFontWeight.bold);
  TextStyle get extraBold => copyWith(fontWeight: AppFontWeight.extraBold);
  TextStyle get black => copyWith(fontWeight: AppFontWeight.black);
  TextStyle get italic => copyWith(fontStyle: FontStyle.italic);
  TextStyle get underline => copyWith(decoration: TextDecoration.underline);
  TextStyle get lineThrough => copyWith(decoration: TextDecoration.lineThrough);
  TextStyle get larger => copyWith(fontSize: (fontSize ?? 14) + 2);
  TextStyle get smaller => copyWith(fontSize: (fontSize ?? 14) - 2);
  TextStyle get muted => copyWith(color: color?.withValues(alpha: 0.70));
  TextStyle get faded => copyWith(color: color?.withValues(alpha: 0.50));
}

abstract final class AppTextTheme {
  static TextTheme get textTheme => TextTheme(
        displayLarge: AppTextStyles.displayLarge,
        displayMedium: AppTextStyles.displayMedium,
        displaySmall: AppTextStyles.displaySmall,
        headlineLarge: AppTextStyles.headlineLarge,
        headlineMedium: AppTextStyles.headlineMedium,
        headlineSmall: AppTextStyles.headlineSmall,
        titleLarge: AppTextStyles.titleLarge,
        titleMedium: AppTextStyles.titleMedium,
        titleSmall: AppTextStyles.titleSmall,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.labelLarge,
        labelMedium: AppTextStyles.labelMedium,
        labelSmall: AppTextStyles.labelSmall,
      );
}
