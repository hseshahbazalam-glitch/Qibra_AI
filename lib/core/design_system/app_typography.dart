// lib/core/design_system/app_typography.dart
// ============================================================
// QIBRA AI — PREMIUM TYPOGRAPHY SYSTEM (Arabic & English Getters)
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract final class AppFontFamily {
  static const String primary = 'Inter';
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
  static TextStyle get displayLarge => GoogleFonts.inter(
      fontSize: AppFontSize.displayLarge,
      fontWeight: AppFontWeight.black,
      height: AppLineHeight.snug,
      letterSpacing: AppLetterSpacing.tighter);
  static TextStyle get displayMedium => GoogleFonts.inter(
      fontSize: AppFontSize.displayMedium,
      fontWeight: AppFontWeight.extraBold,
      height: AppLineHeight.snug,
      letterSpacing: AppLetterSpacing.tighter);
  static TextStyle get displaySmall => GoogleFonts.inter(
      fontSize: AppFontSize.displaySmall,
      fontWeight: AppFontWeight.bold,
      height: AppLineHeight.compact,
      letterSpacing: AppLetterSpacing.tight);
  static TextStyle get headlineLarge => GoogleFonts.inter(
      fontSize: AppFontSize.headlineLarge,
      fontWeight: AppFontWeight.bold,
      height: AppLineHeight.compact,
      letterSpacing: AppLetterSpacing.tight);
  static TextStyle get headlineMedium => GoogleFonts.inter(
      fontSize: AppFontSize.headlineMedium,
      fontWeight: AppFontWeight.bold,
      height: AppLineHeight.compact,
      letterSpacing: AppLetterSpacing.normal);
  static TextStyle get headlineSmall => GoogleFonts.inter(
      fontSize: AppFontSize.headlineSmall,
      fontWeight: AppFontWeight.semiBold,
      height: AppLineHeight.compact,
      letterSpacing: AppLetterSpacing.normal);
  static TextStyle get titleLarge => GoogleFonts.inter(
      fontSize: AppFontSize.titleLarge,
      fontWeight: AppFontWeight.semiBold,
      height: AppLineHeight.normal,
      letterSpacing: AppLetterSpacing.normal);
  static TextStyle get titleMedium => GoogleFonts.inter(
      fontSize: AppFontSize.titleMedium,
      fontWeight: AppFontWeight.semiBold,
      height: AppLineHeight.normal,
      letterSpacing: AppLetterSpacing.wide);
  static TextStyle get titleSmall => GoogleFonts.inter(
      fontSize: AppFontSize.titleSmall,
      fontWeight: AppFontWeight.medium,
      height: AppLineHeight.normal,
      letterSpacing: AppLetterSpacing.wide);
  static TextStyle get bodyLarge => GoogleFonts.inter(
      fontSize: AppFontSize.bodyLarge,
      fontWeight: AppFontWeight.regular,
      height: AppLineHeight.relaxed,
      letterSpacing: AppLetterSpacing.normal);
  static TextStyle get bodyMedium => GoogleFonts.inter(
      fontSize: AppFontSize.bodyMedium,
      fontWeight: AppFontWeight.regular,
      height: AppLineHeight.relaxed,
      letterSpacing: AppLetterSpacing.normal);
  static TextStyle get bodySmall => GoogleFonts.inter(
      fontSize: AppFontSize.bodySmall,
      fontWeight: AppFontWeight.regular,
      height: AppLineHeight.normal,
      letterSpacing: AppLetterSpacing.normal);
  static TextStyle get labelLarge => GoogleFonts.inter(
      fontSize: AppFontSize.labelLarge,
      fontWeight: AppFontWeight.semiBold,
      height: AppLineHeight.tight,
      letterSpacing: AppLetterSpacing.wide);
  static TextStyle get labelMedium => GoogleFonts.inter(
      fontSize: AppFontSize.labelMedium,
      fontWeight: AppFontWeight.medium,
      height: AppLineHeight.tight,
      letterSpacing: AppLetterSpacing.wide);
  static TextStyle get labelSmall => GoogleFonts.inter(
      fontSize: AppFontSize.labelSmall,
      fontWeight: AppFontWeight.medium,
      height: AppLineHeight.tight,
      letterSpacing: AppLetterSpacing.wider);
  static TextStyle get labelXSmall => GoogleFonts.inter(
      fontSize: AppFontSize.labelXSmall,
      fontWeight: AppFontWeight.regular,
      height: AppLineHeight.tight,
      letterSpacing: AppLetterSpacing.widest);
  static TextStyle get buttonLarge => GoogleFonts.inter(
      fontSize: AppFontSize.labelLarge,
      fontWeight: AppFontWeight.semiBold,
      height: AppLineHeight.tight,
      letterSpacing: AppLetterSpacing.wide);
  static TextStyle get buttonMedium => GoogleFonts.inter(
      fontSize: AppFontSize.labelMedium,
      fontWeight: AppFontWeight.semiBold,
      height: AppLineHeight.tight,
      letterSpacing: AppLetterSpacing.wide);
  static TextStyle get buttonSmall => GoogleFonts.inter(
      fontSize: AppFontSize.labelSmall,
      fontWeight: AppFontWeight.medium,
      height: AppLineHeight.tight,
      letterSpacing: AppLetterSpacing.wide);
  static TextStyle get inputText => GoogleFonts.inter(
      fontSize: AppFontSize.bodyLarge,
      fontWeight: AppFontWeight.regular,
      height: AppLineHeight.normal,
      letterSpacing: AppLetterSpacing.normal);
  static TextStyle get inputHint => GoogleFonts.inter(
      fontSize: AppFontSize.bodyLarge,
      fontWeight: AppFontWeight.regular,
      height: AppLineHeight.normal,
      letterSpacing: AppLetterSpacing.normal);
  static TextStyle get inputLabel => GoogleFonts.inter(
      fontSize: AppFontSize.labelMedium,
      fontWeight: AppFontWeight.medium,
      height: AppLineHeight.tight,
      letterSpacing: AppLetterSpacing.wide);
  static TextStyle get inputError => GoogleFonts.inter(
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

  static TextStyle get cardTitle => GoogleFonts.inter(
      fontSize: AppFontSize.titleMedium,
      fontWeight: AppFontWeight.semiBold,
      height: AppLineHeight.compact,
      letterSpacing: AppLetterSpacing.normal);
  static TextStyle get cardSubtitle => GoogleFonts.inter(
      fontSize: AppFontSize.bodySmall,
      fontWeight: AppFontWeight.regular,
      height: AppLineHeight.relaxed,
      letterSpacing: AppLetterSpacing.normal);
  static TextStyle get badge => GoogleFonts.inter(
      fontSize: AppFontSize.labelXSmall,
      fontWeight: AppFontWeight.bold,
      height: AppLineHeight.tight,
      letterSpacing: AppLetterSpacing.normal);
  static TextStyle get chip => GoogleFonts.inter(
      fontSize: AppFontSize.labelMedium,
      fontWeight: AppFontWeight.medium,
      height: AppLineHeight.tight,
      letterSpacing: AppLetterSpacing.normal);
}

abstract final class AppArabicStyles {
  static TextStyle get quranSmall => GoogleFonts.amiri(
      fontSize: AppFontSize.arabicSmall,
      fontWeight: AppFontWeight.regular,
      height: AppLineHeight.arabicNormal);
  static TextStyle get quranMedium => GoogleFonts.amiri(
      fontSize: AppFontSize.arabicMedium,
      fontWeight: AppFontWeight.regular,
      height: AppLineHeight.arabicRelaxed);
  static TextStyle get quranLarge => GoogleFonts.amiri(
      fontSize: AppFontSize.arabicLarge,
      fontWeight: AppFontWeight.regular,
      height: AppLineHeight.arabicLoose);
  static TextStyle get quranBold => GoogleFonts.amiri(
      fontSize: AppFontSize.arabicMedium,
      fontWeight: AppFontWeight.bold,
      height: AppLineHeight.arabicRelaxed);
  static TextStyle get surahName => GoogleFonts.amiri(
      fontSize: AppFontSize.arabicDisplay,
      fontWeight: AppFontWeight.bold,
      height: AppLineHeight.arabicNormal);
  static TextStyle get bismillah => GoogleFonts.amiri(
      fontSize: AppFontSize.arabicDisplay,
      fontWeight: AppFontWeight.bold,
      height: AppLineHeight.arabicRelaxed);
  static TextStyle get bismillahHero => GoogleFonts.amiri(
      fontSize: AppFontSize.arabicHero,
      fontWeight: AppFontWeight.bold,
      height: AppLineHeight.arabicRelaxed);
  static TextStyle get hadithArabic => GoogleFonts.amiri(
      fontSize: AppFontSize.arabicMedium,
      fontWeight: AppFontWeight.regular,
      height: AppLineHeight.arabicRelaxed);
  static TextStyle get duaArabic => GoogleFonts.amiri(
      fontSize: AppFontSize.arabicLarge,
      fontWeight: AppFontWeight.regular,
      height: AppLineHeight.arabicLoose);
  static TextStyle get ayahNumber => GoogleFonts.inter(
      fontSize: AppFontSize.labelSmall,
      fontWeight: AppFontWeight.semiBold,
      height: AppLineHeight.tight);
  static TextStyle get translation => GoogleFonts.inter(
      fontSize: AppFontSize.bodyMedium,
      fontWeight: AppFontWeight.regular,
      height: AppLineHeight.loose,
      letterSpacing: AppLetterSpacing.normal);
  static TextStyle get transliteration => GoogleFonts.inter(
      fontSize: AppFontSize.bodySmall,
      fontWeight: AppFontWeight.light,
      height: AppLineHeight.relaxed,
      letterSpacing: AppLetterSpacing.wide,
      fontStyle: FontStyle.italic);
}

extension TextStyleExtension on TextStyle {
  TextStyle get white => copyWith(color: AppColors.textPrimary);
  TextStyle get secondary => copyWith(color: AppColors.textSecondary);
  TextStyle get tertiary => copyWith(color: AppColors.textTertiary);
  TextStyle get gold => copyWith(color: const Color(0xFF6B542B));
  TextStyle get goldBright => copyWith(color: const Color(0xFF6B542B));
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
