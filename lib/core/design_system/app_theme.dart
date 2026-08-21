// lib/core/design_system/app_theme.dart
// ============================================================
// QIBRA AI — PREMIUM THEME SYSTEM (100% Error-Free & Validated)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_design_system.dart';
import 'app_typography.dart';

abstract final class AppTheme {
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: _colorScheme,
        scaffoldBackgroundColor: AppColors.background,
        textTheme: AppTextTheme.textTheme,
        iconTheme: _iconTheme,
        primaryIconTheme: _primaryIconTheme,
        appBarTheme: _appBarTheme,
        bottomNavigationBarTheme: _bottomNavTheme,
        navigationBarTheme: _navigationBarTheme,
        cardTheme: _cardTheme,
        elevatedButtonTheme: _elevatedButtonTheme,
        outlinedButtonTheme: _outlinedButtonTheme,
        textButtonTheme: _textButtonTheme,
        floatingActionButtonTheme: _fabTheme,
        inputDecorationTheme: _inputDecorationTheme,
        dialogTheme: _dialogTheme,
        bottomSheetTheme: _bottomSheetTheme,
        snackBarTheme: _snackBarTheme,
        chipTheme: _chipTheme,
        dividerTheme: _dividerTheme,
        listTileTheme: _listTileTheme,
        switchTheme: _switchTheme,
        checkboxTheme: _checkboxTheme,
        radioTheme: _radioTheme,
        sliderTheme: _sliderTheme,
        progressIndicatorTheme: _progressIndicatorTheme,
        tabBarTheme: _tabBarTheme,
        tooltipTheme: _tooltipTheme,
        popupMenuTheme: _popupMenuTheme,
        drawerTheme: _drawerTheme,
        badgeTheme: _badgeTheme,
        searchBarTheme: _searchBarTheme,
      );

  static ColorScheme get _colorScheme => const ColorScheme(
        brightness: Brightness.dark,
        primary: AppColors.primary,
        onPrimary: AppColors.textOnEmerald,
        primaryContainer: AppEmerald.s800,
        onPrimaryContainer: AppEmerald.s100,
        secondary: AppColors.accent,
        onSecondary: AppColors.textOnGold,
        secondaryContainer: AppGold.s800,
        onSecondaryContainer: AppGold.s100,
        tertiary: Color(0xFF4DB6AC),
        onTertiary: AppColors.black,
        tertiaryContainer: Color(0xFF00363B),
        onTertiaryContainer: Color(0xFFB2DFDB),
        error: AppColors.error,
        onError: AppColors.white,
        errorContainer: AppSemanticColors.errorDark,
        onErrorContainer: AppSemanticColors.errorLight,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.surfaceHigh,
        onSurfaceVariant: AppColors.textSecondary,
        outline: AppColors.borderStandard,
        outlineVariant: AppColors.borderSubtle,
        shadow: AppColors.black,
        scrim: AppColors.black,
        inverseSurface: AppNeutral.s100,
        onInverseSurface: AppNeutral.s900,
        inversePrimary: AppEmerald.s700,
        surfaceTint: AppColors.primary,
      );

  static IconThemeData get _iconTheme => const IconThemeData(
        color: AppColors.iconSecondary,
        size: AppIconSizes.lg,
        opticalSize: 24,
        weight: 400,
      );

  static IconThemeData get _primaryIconTheme => const IconThemeData(
        color: AppColors.iconPrimary,
        size: AppIconSizes.lg,
        opticalSize: 24,
        weight: 400,
      );

  static AppBarTheme get _appBarTheme => AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: AppElevation.none,
        scrolledUnderElevation: AppElevation.xs,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        centerTitle: true,
        titleTextStyle: AppTextStyles.titleLarge,
        iconTheme: const IconThemeData(
            color: AppColors.iconPrimary, size: AppIconSizes.lg),
        actionsIconTheme: const IconThemeData(
            color: AppColors.iconPrimary, size: AppIconSizes.lg),
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
          statusBarBrightness: Brightness.dark,
          systemNavigationBarColor: AppColors.background,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      );

  static BottomNavigationBarThemeData get _bottomNavTheme =>
      const BottomNavigationBarThemeData(
        backgroundColor: AppColors.navBackground,
        elevation: AppElevation.lg,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.navInactive,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
      );

  static NavigationBarThemeData get _navigationBarTheme =>
      NavigationBarThemeData(
        backgroundColor: AppColors.navBackground,
        indicatorColor: AppColors.primary.withValues(alpha: 0.20),
        surfaceTintColor: Colors.transparent,
        elevation: AppElevation.lg,
        height: AppSpacing.bottomNavHeight,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
                color: AppColors.primary, size: AppIconSizes.lg);
          }
          return const IconThemeData(
              color: AppColors.navInactive, size: AppIconSizes.lg);
        }),
      );

  static CardThemeData get _cardTheme => CardThemeData(
        color: AppColors.surface,
        elevation: AppElevation.sm,
        shadowColor: AppColors.black.withValues(alpha: 0.40),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardRadius,
          side: const BorderSide(color: AppColors.borderSubtle, width: 1.0),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      );

  static ElevatedButtonThemeData get _elevatedButtonTheme =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textOnEmerald,
          elevation: AppElevation.sm,
          textStyle: AppTextStyles.buttonLarge,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl2, vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonRadiusLg),
          minimumSize: const Size(double.infinity, 52),
        ),
      );

  static OutlinedButtonThemeData get _outlinedButtonTheme =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          side: const BorderSide(color: AppColors.primary, width: 1.5),
          textStyle: AppTextStyles.buttonLarge,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl2, vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonRadiusLg),
          minimumSize: const Size(double.infinity, 52),
        ),
      );

  static TextButtonThemeData get _textButtonTheme => TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: AppTextStyles.buttonMedium,
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
        ),
      );

  static FloatingActionButtonThemeData get _fabTheme =>
      FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnEmerald,
        elevation: AppElevation.md,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.cardRadiusLarge),
      );

  static InputDecorationTheme get _inputDecorationTheme => InputDecorationTheme(
        filled: true,
        fillColor: AppColors.inputBackground,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        hintStyle: AppTextStyles.inputHint,
        labelStyle: AppTextStyles.inputLabel,
        border: OutlineInputBorder(
            borderRadius: AppRadius.cardRadius,
            borderSide:
                const BorderSide(color: AppColors.borderStandard, width: 1.0)),
        enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.cardRadius,
            borderSide:
                const BorderSide(color: AppColors.borderStandard, width: 1.0)),
        focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.cardRadius,
            borderSide:
                const BorderSide(color: AppColors.borderFocus, width: 2.0)),
        errorBorder: OutlineInputBorder(
            borderRadius: AppRadius.cardRadius,
            borderSide:
                const BorderSide(color: AppColors.borderError, width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: AppRadius.cardRadius,
            borderSide:
                const BorderSide(color: AppColors.borderError, width: 2.0)),
      );

  static DialogThemeData get _dialogTheme => DialogThemeData(
        backgroundColor: AppColors.surfaceSheet,
        surfaceTintColor: Colors.transparent,
        elevation: AppElevation.xl2,
        shadowColor: AppColors.black.withValues(alpha: 0.50),
        shape: RoundedRectangleBorder(
            borderRadius: AppRadius.cardRadiusLarge,
            side: const BorderSide(color: AppColors.borderSubtle, width: 1.0)),
        titleTextStyle: AppTextStyles.titleLarge,
        contentTextStyle: AppTextStyles.bodyMedium,
      );

  static BottomSheetThemeData get _bottomSheetTheme =>
      const BottomSheetThemeData(
        backgroundColor: AppColors.surfaceSheet,
        surfaceTintColor: Colors.transparent,
        elevation: AppElevation.xl2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppRadius.xl3),
            topRight: Radius.circular(AppRadius.xl3),
          ),
        ),
      );

  static SnackBarThemeData get _snackBarTheme => SnackBarThemeData(
        backgroundColor: AppColors.surfaceHigh,
        contentTextStyle: AppTextStyles.bodyMedium,
        shape: RoundedRectangleBorder(
            borderRadius: AppRadius.cardRadius,
            side: const BorderSide(color: AppColors.borderSubtle, width: 1.0)),
        behavior: SnackBarBehavior.floating,
      );

  static ChipThemeData get _chipTheme => ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary.withValues(alpha: 0.20),
        labelStyle: AppTextStyles.labelMedium,
        shape: RoundedRectangleBorder(
            borderRadius: AppRadius.buttonRadius,
            side:
                const BorderSide(color: AppColors.borderStandard, width: 1.0)),
      );

  static DividerThemeData get _dividerTheme => const DividerThemeData(
        color: AppColors.divider,
        thickness: 1.0,
        space: 1.0,
      );

  static ListTileThemeData get _listTileTheme => ListTileThemeData(
        tileColor: Colors.transparent,
        textColor: AppColors.textPrimary,
        selectedColor: AppColors.primary,
        iconColor: AppColors.iconSecondary,
        titleTextStyle: AppTextStyles.titleMedium,
        subtitleTextStyle: AppTextStyles.bodySmall.secondary,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.cardRadius),
      );

  static SwitchThemeData get _switchTheme => SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.iconSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected))
            return AppColors.primary.withValues(alpha: 0.35);
          return AppColors.surfaceHigh;
        }),
      );

  static CheckboxThemeData get _checkboxTheme => CheckboxThemeData(
        checkColor: WidgetStateProperty.all(AppColors.white),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return Colors.transparent;
        }),
        side: const BorderSide(color: AppColors.borderStandard, width: 1.5),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm)),
      );

  static RadioThemeData get _radioTheme => RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.primary;
          return AppColors.borderStandard;
        }),
      );

  static SliderThemeData get _sliderTheme => SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.surfaceHigh,
        thumbColor: AppColors.primary,
        overlayColor: AppColors.primary.withValues(alpha: 0.12),
        valueIndicatorColor: AppColors.surfaceHigh,
        valueIndicatorTextStyle: AppTextStyles.labelSmall,
        trackHeight: 4.0,
        thumbShape: const RoundSliderThumbShape(
            enabledThumbRadius: 8.0, elevation: 2.0),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20.0),
      );

  static ProgressIndicatorThemeData get _progressIndicatorTheme =>
      const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.surfaceHigh,
        circularTrackColor: AppColors.surfaceHigh,
        linearMinHeight: 4.0,
      );

  static TabBarThemeData get _tabBarTheme => TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.navInactive,
        labelStyle: AppTextStyles.labelLarge,
        unselectedLabelStyle: AppTextStyles.labelLarge.secondary,
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: AppColors.divider,
        dividerHeight: 1.0,
      );

  static TooltipThemeData get _tooltipTheme => TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.surfaceHighest,
          borderRadius: AppRadius.buttonRadius,
          border: Border.all(color: AppColors.borderSubtle, width: 1.0),
        ),
        textStyle: AppTextStyles.labelSmall,
      );

  static PopupMenuThemeData get _popupMenuTheme => PopupMenuThemeData(
        color: AppColors.surfaceHigh,
        surfaceTintColor: Colors.transparent,
        elevation: AppElevation.lg,
        shape: RoundedRectangleBorder(
            borderRadius: AppRadius.cardRadius,
            side: const BorderSide(color: AppColors.borderSubtle, width: 1.0)),
        textStyle: AppTextStyles.bodyMedium,
      );

  static DrawerThemeData get _drawerTheme => DrawerThemeData(
        backgroundColor: AppColors.surfaceSheet,
        surfaceTintColor: Colors.transparent,
        elevation: AppElevation.xl2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(AppRadius.xl3),
            bottomRight: Radius.circular(AppRadius.xl3),
          ),
        ),
        width: 300,
      );

  static BadgeThemeData get _badgeTheme => BadgeThemeData(
        backgroundColor: AppColors.error,
        textColor: AppColors.white,
        smallSize: 8.0,
        largeSize: 18.0,
        textStyle: AppTextStyles.badge,
      );

  static SearchBarThemeData get _searchBarTheme => SearchBarThemeData(
        backgroundColor: WidgetStateProperty.all(AppColors.inputBackground),
        surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
        shadowColor: WidgetStateProperty.all(Colors.transparent),
        elevation: WidgetStateProperty.all(AppElevation.none),
        shape: WidgetStateProperty.all(RoundedRectangleBorder(
            borderRadius: AppRadius.cardRadius,
            side:
                const BorderSide(color: AppColors.borderStandard, width: 1.0))),
        textStyle: WidgetStateProperty.all(AppTextStyles.inputText),
        hintStyle: WidgetStateProperty.all(AppTextStyles.inputHint),
      );
}

abstract final class AppSystemUI {
  static void setDarkTheme() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.background,
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
