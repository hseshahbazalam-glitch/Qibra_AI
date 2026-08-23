// lib/core/design_system/app_theme.dart
// QIBRA AI — Light-first theme with a refined forest-night dark mode.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_design_system.dart';
import 'app_typography.dart';
import 'qibra_colors.dart';

abstract final class AppTheme {
  static ThemeData get light => _build(
        brightness: Brightness.light,
        palette: QibraColors.light,
        background: AppColors.background,
        surface: AppColors.surface,
        surfaceHigh: AppColors.surfaceHigh,
        surfaceHighest: AppColors.surfaceHighest,
        surfaceSheet: AppColors.surfaceSheet,
        primary: AppColors.primary,
        onPrimary: AppColors.textOnEmerald,
        accent: AppColors.accent,
        onAccent: AppColors.textOnGold,
        textPrimary: AppColors.textPrimary,
        textSecondary: AppColors.textSecondary,
        border: AppColors.borderSubtle,
        navBackground: AppColors.navBackground,
        navInactive: AppColors.navInactive,
        inputBackground: AppColors.inputBackground,
        statusIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
      );

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        palette: QibraColors.dark,
        background: AppColorsDark.background,
        surface: AppColorsDark.surface,
        surfaceHigh: AppColorsDark.surfaceHigh,
        surfaceHighest: AppColorsDark.surfaceElevated,
        surfaceSheet: AppColorsDark.surface,
        primary: AppColorsDark.primaryDeep,
        onPrimary: AppColorsDark.textPrimary,
        accent: AppColorsDark.accent,
        onAccent: const Color(0xFF19312C),
        textPrimary: AppColorsDark.textPrimary,
        textSecondary: AppColorsDark.textSecondary,
        border: AppColorsDark.border,
        navBackground: AppColorsDark.navBackground,
        navInactive: AppColorsDark.textTertiary,
        inputBackground: AppColorsDark.surfaceElevated,
        statusIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      );

  static ThemeData _build({
    required Brightness brightness,
    required QibraColors palette,
    required Color background,
    required Color surface,
    required Color surfaceHigh,
    required Color surfaceHighest,
    required Color surfaceSheet,
    required Color primary,
    required Color onPrimary,
    required Color accent,
    required Color onAccent,
    required Color textPrimary,
    required Color textSecondary,
    required Color border,
    required Color navBackground,
    required Color navInactive,
    required Color inputBackground,
    required Brightness statusIconBrightness,
    required Brightness statusBarBrightness,
  }) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      extensions: [palette],
      scaffoldBackgroundColor: background,
      textTheme: AppTextTheme.textTheme.apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: onPrimary,
        primaryContainer: isDark ? AppColorsDark.surfaceElevated : AppEmerald.s100,
        onPrimaryContainer: isDark ? AppColorsDark.textPrimary : AppEmerald.s800,
        secondary: accent,
        onSecondary: onAccent,
        secondaryContainer: isDark ? AppGold.s800 : AppGold.s100,
        onSecondaryContainer: isDark ? AppGold.s100 : AppGold.s800,
        tertiary: AppEmerald.s400,
        onTertiary: onPrimary,
        tertiaryContainer: AppEmerald.s100,
        onTertiaryContainer: AppEmerald.s800,
        error: AppColors.error,
        onError: AppColors.white,
        errorContainer: AppSemanticColors.errorLight,
        onErrorContainer: AppSemanticColors.errorDark,
        surface: surface,
        onSurface: textPrimary,
        surfaceContainerHighest: surfaceHigh,
        onSurfaceVariant: textSecondary,
        outline: border,
        outlineVariant: border,
        shadow: const Color(0xFF19312C),
        scrim: const Color(0xFF19312C),
        inverseSurface: isDark ? AppNeutral.s50 : AppNeutral.s800,
        onInverseSurface: isDark ? AppNeutral.s800 : AppNeutral.s50,
        inversePrimary: AppEmerald.s400,
        surfaceTint: Colors.transparent,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: AppTextStyles.titleLarge.copyWith(color: textPrimary),
        iconTheme: IconThemeData(color: textPrimary, size: AppIconSizes.lg),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: statusIconBrightness,
          statusBarBrightness: statusBarBrightness,
          systemNavigationBarColor: navBackground,
          systemNavigationBarIconBrightness: statusIconBrightness,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shadowColor: const Color(0xFF19312C).withValues(alpha: 0.06),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardRadiusLarge,
          side: BorderSide(color: border),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          textStyle: AppTextStyles.buttonLarge,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl2, vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonRadiusLg),
          minimumSize: const Size(64, 52),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary, width: 1.2),
          textStyle: AppTextStyles.buttonLarge,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl2, vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonRadiusLg),
          minimumSize: const Size(64, 52),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: AppTextStyles.buttonMedium,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: onPrimary,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.cardRadiusLarge),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputBackground,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        hintStyle: AppTextStyles.inputHint.copyWith(color: textSecondary),
        labelStyle: AppTextStyles.inputLabel.copyWith(color: textSecondary),
        border: OutlineInputBorder(
            borderRadius: AppRadius.cardRadius,
            borderSide: BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.cardRadius,
            borderSide: BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.cardRadius,
            borderSide: BorderSide(color: primary, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: AppRadius.cardRadius,
            borderSide: const BorderSide(color: AppColors.error)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceSheet,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardRadiusLarge,
          side: BorderSide(color: border),
        ),
        titleTextStyle: AppTextStyles.titleLarge.copyWith(color: textPrimary),
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: textSecondary),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surfaceSheet,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppRadius.xl3),
            topRight: Radius.circular(AppRadius.xl3),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppColorsDark.surfaceHigh : AppColors.primary,
        contentTextStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.cardRadius),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: primary.withValues(alpha: 0.12),
        labelStyle: AppTextStyles.labelMedium.copyWith(color: textPrimary),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.pillRadius,
          side: BorderSide(color: border),
        ),
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return textSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primary.withValues(alpha: 0.28);
          }
          return border;
        }),
      ),
      checkboxTheme: CheckboxThemeData(
        checkColor: WidgetStateProperty.all(onPrimary),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primary;
          return Colors.transparent;
        }),
        side: BorderSide(color: border, width: 1.5),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: border,
        circularTrackColor: border,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: navInactive,
        labelStyle: AppTextStyles.labelLarge,
        unselectedLabelStyle: AppTextStyles.labelLarge,
        indicatorColor: primary,
        dividerColor: border,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: navBackground,
        selectedItemColor: primary,
        unselectedItemColor: navInactive,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: navBackground,
        indicatorColor: primary.withValues(alpha: 0.12),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: AppSpacing.bottomNavHeight,
      ),
    );
  }
}

abstract final class AppSystemUI {
  static void setLightTheme() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: AppColors.navBackground,
        systemNavigationBarIconBrightness: Brightness.dark,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );
  }

  static void setDarkTheme() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppColorsDark.navBackground,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );
  }

  static Future<void> setPortraitOnly() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }
}
