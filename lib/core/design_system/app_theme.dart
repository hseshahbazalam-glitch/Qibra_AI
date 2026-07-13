// lib/core/design_system/app_theme.dart

// ============================================================
// QIBRA AI — PREMIUM THEME SYSTEM
// Version: 1.0.0
// Description: Complete ThemeData for QIBRA AI.
//              Dark Emerald + Royal Gold Islamic theme.
//              Every Material widget is themed here.
//              Usage: MaterialApp(theme: AppTheme.dark)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_design_system.dart';
import 'app_typography.dart';

// ============================================================
// AppTheme — Main Theme Class
// ============================================================
// Yeh class poori app ka theme hold karti hai.
// Abhi sirf dark theme hai.
// Future mein light theme bhi add kar sakte hain.
// ============================================================

abstract final class AppTheme {
  // ══════════════════════════════════════════
  // DARK THEME — Primary QIBRA AI Theme
  // ══════════════════════════════════════════

  /// QIBRA AI Dark Theme
  /// MaterialApp mein use karo:
  ///   MaterialApp(theme: AppTheme.dark)
  static ThemeData get dark => ThemeData(
        // ── FOUNDATION ──────────────────────────────────────

        // useMaterial3: true → Material Design 3 enable karta hai
        // Modern rounded corners, better color system
        useMaterial3: true,

        // brightness: dark → poori app dark mode mein
        brightness: Brightness.dark,

        // ── COLOR SCHEME ─────────────────────────────────────
        // ColorScheme = Material 3 ka color system
        // Har widget automatically yahan se colors leta hai
        colorScheme: _colorScheme,

        // ── SCAFFOLD ────────────────────────────────────────
        // Scaffold = har screen ka base widget
        // Background color set karo
        scaffoldBackgroundColor: AppColors.background,

        // ── TEXT THEME ───────────────────────────────────────
        // Step 3 mein banaya hua TextTheme
        textTheme: AppTextTheme.textTheme,

        // ── ICON THEME ───────────────────────────────────────
        iconTheme: _iconTheme,
        primaryIconTheme: _primaryIconTheme,

        // ── APP BAR ─────────────────────────────────────────
        appBarTheme: _appBarTheme,

        // ── BOTTOM NAVIGATION BAR ───────────────────────────
        bottomNavigationBarTheme: _bottomNavTheme,

        // ── NAVIGATION BAR (Material 3) ──────────────────────
        navigationBarTheme: _navigationBarTheme,

        // ── CARD ────────────────────────────────────────────
        cardTheme: _cardTheme,

        // ── ELEVATED BUTTON ──────────────────────────────────
        elevatedButtonTheme: _elevatedButtonTheme,

        // ── OUTLINED BUTTON ──────────────────────────────────
        outlinedButtonTheme: _outlinedButtonTheme,

        // ── TEXT BUTTON ─────────────────────────────────────
        textButtonTheme: _textButtonTheme,

        // ── FLOATING ACTION BUTTON ───────────────────────────
        floatingActionButtonTheme: _fabTheme,

        // ── INPUT DECORATION (TextField) ─────────────────────
        inputDecorationTheme: _inputDecorationTheme,

        // ── DIALOG ──────────────────────────────────────────
        dialogTheme: _dialogTheme,

        // ── BOTTOM SHEET ─────────────────────────────────────
        bottomSheetTheme: _bottomSheetTheme,

        // ── SNACK BAR ────────────────────────────────────────
        snackBarTheme: _snackBarTheme,

        // ── CHIP ────────────────────────────────────────────
        chipTheme: _chipTheme,

        // ── DIVIDER ─────────────────────────────────────────
        dividerTheme: _dividerTheme,

        // ── LIST TILE ────────────────────────────────────────
        listTileTheme: _listTileTheme,

        // ── SWITCH ──────────────────────────────────────────
        switchTheme: _switchTheme,

        // ── CHECKBOX ────────────────────────────────────────
        checkboxTheme: _checkboxTheme,

        // ── RADIO ────────────────────────────────────────────
        radioTheme: _radioTheme,

        // ── SLIDER ──────────────────────────────────────────
        sliderTheme: _sliderTheme,

        // ── PROGRESS INDICATOR ───────────────────────────────
        progressIndicatorTheme: _progressIndicatorTheme,

        // ── TAB BAR ─────────────────────────────────────────
        tabBarTheme: _tabBarTheme,

        // ── TOOLTIP ─────────────────────────────────────────
        tooltipTheme: _tooltipTheme,

        // ── POPUP MENU ───────────────────────────────────────
        popupMenuTheme: _popupMenuTheme,

        // ── DRAWER ──────────────────────────────────────────
        drawerTheme: _drawerTheme,

        // ── BADGE ────────────────────────────────────────────
        badgeTheme: _badgeTheme,

        // ── SEARCH BAR ───────────────────────────────────────
        searchBarTheme: _searchBarTheme,
      );

  // ══════════════════════════════════════════
  // COLOR SCHEME
  // ══════════════════════════════════════════
  // Material 3 ColorScheme — har widget automatically
  // yahan se apna color pick karta hai.
  // primary = main brand color (Emerald)
  // secondary = accent color (Gold)
  // surface = card/sheet backgrounds
  // error = error state color
  // ══════════════════════════════════════════

  static ColorScheme get _colorScheme => const ColorScheme(
        brightness: Brightness.dark,

        // Primary — Emerald (buttons, active states, FAB)
        primary: AppColors.primary,
        onPrimary: AppColors.textOnEmerald,
        primaryContainer: AppEmerald.s800,
        onPrimaryContainer: AppEmerald.s100,

        // Secondary — Gold (secondary buttons, chips)
        secondary: AppColors.accent,
        onSecondary: AppColors.textOnGold,
        secondaryContainer: AppGold.s800,
        onSecondaryContainer: AppGold.s100,

        // Tertiary — Teal accent
        tertiary: Color(0xFF4DB6AC),
        onTertiary: AppColors.black,
        tertiaryContainer: Color(0xFF00363B),
        onTertiaryContainer: Color(0xFFB2DFDB),

        // Error
        error: AppColors.error,
        onError: AppColors.white,
        errorContainer: AppSemanticColors.errorDark,
        onErrorContainer: AppSemanticColors.errorLight,

        // Surface (cards, sheets, dialogs)
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        surfaceContainerHighest: AppColors.surfaceHigh,
        onSurfaceVariant: AppColors.textSecondary,

        // Outline (borders, dividers)
        outline: AppColors.borderStandard,
        outlineVariant: AppColors.borderSubtle,

        // Background (scaffold)
        // Note: In M3, surface is used as background
        // surfaceTint handles the elevation tinting

        // Shadow
        shadow: AppColors.black,

        // Scrim (behind modals)
        scrim: AppColors.black,

        // Inverse
        inverseSurface: AppNeutral.s100,
        onInverseSurface: AppNeutral.s900,
        inversePrimary: AppEmerald.s700,

        // Surface tint (elevation overlay color in M3)
        // Emerald tint for elevated surfaces
        surfaceTint: AppColors.primary,
      );

  // ══════════════════════════════════════════
  // ICON THEME
  // ══════════════════════════════════════════

  static IconThemeData get _iconTheme => const IconThemeData(
        color: AppColors.iconSecondary,
        size: AppIconSizes.lg, // 24px standard
        opticalSize: 24,
        weight: 400,
      );

  static IconThemeData get _primaryIconTheme => const IconThemeData(
        color: AppColors.iconPrimary,
        size: AppIconSizes.lg,
        opticalSize: 24,
        weight: 400,
      );

  // ══════════════════════════════════════════
  // APP BAR THEME
  // ══════════════════════════════════════════
  // AppBar = screen ke upar wala header bar
  // QIBRA AI mein transparent/dark app bar
  // ══════════════════════════════════════════

  static AppBarTheme get _appBarTheme => AppBarTheme(
        // Background color — same as scaffold (seamless look)
        backgroundColor: AppColors.background,

        // Elevation — 0 means no shadow (flat, modern)
        elevation: AppElevation.none,

        // Scroll elevation — jab scroll karo tab bhi flat
        scrolledUnderElevation: AppElevation.xs,

        // Surface tint — M3 elevation tinting disable karo
        surfaceTintColor: Colors.transparent,

        // Shadow color
        shadowColor: Colors.transparent,

        // Center title — iOS style centered title
        centerTitle: true,

        // Title text style
        titleTextStyle: AppTextStyles.titleLarge,

        // Icon theme for back button, menu icon
        iconTheme: const IconThemeData(
          color: AppColors.iconPrimary,
          size: AppIconSizes.lg,
        ),

        // Actions icon theme (top right icons)
        actionsIconTheme: const IconThemeData(
          color: AppColors.iconPrimary,
          size: AppIconSizes.lg,
        ),

        // Status bar style — light icons on dark background
        // SystemUiOverlayStyle controls status bar appearance
        systemOverlayStyle: const SystemUiOverlayStyle(
          // Status bar background (Android)
          statusBarColor: Colors.transparent,
          // Status bar icons — light (white) on dark bg
          statusBarIconBrightness: Brightness.light,
          // iOS status bar text — light
          statusBarBrightness: Brightness.dark,
          // Navigation bar (Android bottom system bar)
          systemNavigationBarColor: AppColors.background,
          systemNavigationBarIconBrightness: Brightness.light,
        ),
      );

  // ══════════════════════════════════════════
  // BOTTOM NAVIGATION BAR THEME
  // ══════════════════════════════════════════

  static BottomNavigationBarThemeData get _bottomNavTheme =>
      BottomNavigationBarThemeData(
        // Background
        backgroundColor: AppColors.navBackground,

        // Elevation — slight shadow above content
        elevation: AppElevation.lg,

        // Active item color (selected tab)
        selectedItemColor: AppColors.primary,

        // Inactive item color (unselected tabs)
        unselectedItemColor: AppColors.navInactive,

        // Selected icon size
        selectedIconTheme: const IconThemeData(
          color: AppColors.primary,
          size: AppIconSizes.lg,
        ),

        // Unselected icon size
        unselectedIconTheme: const IconThemeData(
          color: AppColors.navInactive,
          size: AppIconSizes.lg,
        ),

        // Selected label style
        selectedLabelStyle: AppTextStyles.navLabelActive,

        // Unselected label style
        unselectedLabelStyle: AppTextStyles.navLabelInactive,

        // Show labels for all items
        showSelectedLabels: true,
        showUnselectedLabels: true,

        // Type — fixed (all items same width)
        type: BottomNavigationBarType.fixed,
      );

  // ══════════════════════════════════════════
  // NAVIGATION BAR THEME (Material 3)
  // ══════════════════════════════════════════

  static NavigationBarThemeData get _navigationBarTheme =>
      NavigationBarThemeData(
        backgroundColor: AppColors.navBackground,
        indicatorColor: AppColors.primary.withValues(alpha: 0.20),
        surfaceTintColor: Colors.transparent,
        elevation: AppElevation.lg,
        height: AppSpacing.bottomNavHeight,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          // Active state
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(
              color: AppColors.primary,
              size: AppIconSizes.lg,
            );
          }
          // Inactive state
          return const IconThemeData(
            color: AppColors.navInactive,
            size: AppIconSizes.lg,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTextStyles.navLabelActive;
          }
          return AppTextStyles.navLabelInactive;
        }),
      );

  // ══════════════════════════════════════════
  // CARD THEME
  // ══════════════════════════════════════════
  // Card widget ka default style
  // ══════════════════════════════════════════

  static CardThemeData get _cardTheme => CardThemeData(
        // Card background color
        color: AppColors.surface,

        // No surface tint (disable M3 elevation tinting)
        surfaceTintColor: Colors.transparent,

        // Elevation — subtle shadow
        elevation: AppElevation.sm,

        // Shadow color
        shadowColor: AppColors.black.withValues(alpha: 0.40),

        // Border radius — standard card radius
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardRadius,
          side: const BorderSide(color: AppColors.borderSubtle, width: 1.0),
        ),

        // Internal padding (none — developer controls)
        margin: EdgeInsets.zero,

        // Clip behavior — content stays inside rounded corners
        clipBehavior: Clip.antiAlias,
      );

  // ══════════════════════════════════════════
  // ELEVATED BUTTON THEME
  // ══════════════════════════════════════════
  // Primary action buttons — Emerald background
  // ══════════════════════════════════════════

  static ElevatedButtonThemeData get _elevatedButtonTheme =>
      ElevatedButtonThemeData(
        style: ButtonStyle(
          // Background color
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.primary.withValues(alpha: 0.30);
            }
            if (states.contains(WidgetState.pressed)) {
              return AppColors.primaryDark;
            }
            if (states.contains(WidgetState.hovered)) {
              return AppColors.primaryLight;
            }
            return AppColors.primary;
          }),

          // Foreground (text + icon) color
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.textOnEmerald.withValues(alpha: 0.50);
            }
            return AppColors.textOnEmerald;
          }),

          // Overlay (ripple) color
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return AppColors.white.withValues(alpha: 0.10);
            }
            if (states.contains(WidgetState.hovered)) {
              return AppColors.white.withValues(alpha: 0.05);
            }
            return Colors.transparent;
          }),

          // Elevation
          elevation: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return AppElevation.xs;
            }
            return AppElevation.sm;
          }),

          // Shadow color
          shadowColor: WidgetStateProperty.all(
            AppColors.primary.withValues(alpha: 0.40),
          ),

          // Shape — rounded button
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: AppRadius.buttonRadiusLg),
          ),

          // Minimum size
          minimumSize: WidgetStateProperty.all(const Size(double.infinity, 52)),

          // Maximum size
          maximumSize: WidgetStateProperty.all(const Size(double.infinity, 60)),

          // Padding
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl2,
              vertical: AppSpacing.md,
            ),
          ),

          // Text style
          textStyle: WidgetStateProperty.all(AppTextStyles.buttonLarge),

          // Surface tint
          surfaceTintColor: WidgetStateProperty.all(Colors.transparent),

          // Animation duration
          animationDuration: AppDurations.fast,
        ),
      );

  // ══════════════════════════════════════════
  // OUTLINED BUTTON THEME
  // ══════════════════════════════════════════
  // Secondary action buttons — transparent with border
  // ══════════════════════════════════════════

  static OutlinedButtonThemeData get _outlinedButtonTheme =>
      OutlinedButtonThemeData(
        style: ButtonStyle(
          // Background — transparent
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return AppColors.primary.withValues(alpha: 0.10);
            }
            if (states.contains(WidgetState.hovered)) {
              return AppColors.primary.withValues(alpha: 0.05);
            }
            return Colors.transparent;
          }),

          // Foreground — Emerald text
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.primary.withValues(alpha: 0.40);
            }
            return AppColors.primary;
          }),

          // Overlay
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return AppColors.primary.withValues(alpha: 0.10);
            }
            return Colors.transparent;
          }),

          // Border
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return BorderSide(
                color: AppColors.primary.withValues(alpha: 0.30),
                width: 1.5,
              );
            }
            if (states.contains(WidgetState.pressed)) {
              return const BorderSide(color: AppColors.primaryDark, width: 1.5);
            }
            return const BorderSide(color: AppColors.primary, width: 1.5);
          }),

          // Shape
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: AppRadius.buttonRadiusLg),
          ),

          // Minimum size
          minimumSize: WidgetStateProperty.all(const Size(double.infinity, 52)),

          // Padding
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(
              horizontal: AppSpacing.xl2,
              vertical: AppSpacing.md,
            ),
          ),

          // Text style
          textStyle: WidgetStateProperty.all(AppTextStyles.buttonLarge),

          // Elevation — none for outlined
          elevation: WidgetStateProperty.all(AppElevation.none),
        ),
      );

  // ══════════════════════════════════════════
  // TEXT BUTTON THEME
  // ══════════════════════════════════════════
  // Tertiary actions — no background, no border
  // ══════════════════════════════════════════

  static TextButtonThemeData get _textButtonTheme => TextButtonThemeData(
        style: ButtonStyle(
          // Foreground — Emerald
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.primary.withValues(alpha: 0.40);
            }
            return AppColors.primary;
          }),

          // Overlay
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return AppColors.primary.withValues(alpha: 0.12);
            }
            if (states.contains(WidgetState.hovered)) {
              return AppColors.primary.withValues(alpha: 0.06);
            }
            return Colors.transparent;
          }),

          // Shape
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: AppRadius.buttonRadius),
          ),

          // Text style
          textStyle: WidgetStateProperty.all(AppTextStyles.buttonMedium),

          // Padding
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
          ),

          // Elevation — none
          elevation: WidgetStateProperty.all(AppElevation.none),
        ),
      );

  // ══════════════════════════════════════════
  // FLOATING ACTION BUTTON THEME
  // ══════════════════════════════════════════

  static FloatingActionButtonThemeData get _fabTheme =>
      FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textOnEmerald,
        elevation: AppElevation.md,
        focusElevation: AppElevation.lg,
        hoverElevation: AppElevation.md,
        highlightElevation: AppElevation.xs,
        splashColor: AppColors.white.withValues(alpha: 0.15),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.cardRadiusLarge),
        extendedTextStyle: AppTextStyles.buttonMedium,
      );

  // ══════════════════════════════════════════
  // INPUT DECORATION THEME (TextField)
  // ══════════════════════════════════════════
  // Yeh sab TextFields ko style karta hai automatically
  // ══════════════════════════════════════════

  static InputDecorationTheme get _inputDecorationTheme => InputDecorationTheme(
        // Fill color (background)
        filled: true,
        fillColor: AppColors.inputBackground,

        // Content padding inside field
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),

        // Hint text style
        hintStyle: AppTextStyles.inputHint,

        // Label text style
        labelStyle: AppTextStyles.inputLabel,

        // Floating label style (label when field is focused)
        floatingLabelStyle: WidgetStateTextStyle.resolveWith((states) {
          if (states.contains(WidgetState.error)) {
            return AppTextStyles.inputLabel.error;
          }
          if (states.contains(WidgetState.focused)) {
            return AppTextStyles.inputLabel.emerald;
          }
          return AppTextStyles.inputLabel;
        }),

        // Helper text style
        helperStyle: AppTextStyles.labelSmall.secondary,

        // Error text style
        errorStyle: AppTextStyles.errorText,

        // Counter text style (character count)
        counterStyle: AppTextStyles.labelXSmall.tertiary,

        // Icon color
        iconColor: AppColors.iconSecondary,
        prefixIconColor: AppColors.iconSecondary,
        suffixIconColor: AppColors.iconSecondary,

        // Border — Default (unfocused, no error)
        border: OutlineInputBorder(
          borderRadius: AppRadius.cardRadius,
          borderSide:
              const BorderSide(color: AppColors.borderStandard, width: 1.0),
        ),

        // Enabled border (unfocused, not error)
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.cardRadius,
          borderSide:
              const BorderSide(color: AppColors.borderStandard, width: 1.0),
        ),

        // Focused border (user is typing)
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.cardRadius,
          borderSide:
              const BorderSide(color: AppColors.borderFocus, width: 2.0),
        ),

        // Error border
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.cardRadius,
          borderSide:
              const BorderSide(color: AppColors.borderError, width: 1.5),
        ),

        // Focused error border
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.cardRadius,
          borderSide:
              const BorderSide(color: AppColors.borderError, width: 2.0),
        ),

        // Disabled border
        disabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.cardRadius,
          borderSide: BorderSide(
            color: AppColors.borderSubtle.withValues(alpha: 0.50),
            width: 1.0,
          ),
        ),

        // Alignment
        alignLabelWithHint: true,

        // Floating label behavior
        floatingLabelBehavior: FloatingLabelBehavior.auto,
      );

  // ══════════════════════════════════════════
  // DIALOG THEME
  // ══════════════════════════════════════════

  static DialogThemeData get _dialogTheme => DialogThemeData(
        backgroundColor: AppColors.surfaceSheet,
        surfaceTintColor: Colors.transparent,
        elevation: AppElevation.xl2,
        shadowColor: AppColors.black.withValues(alpha: 0.50),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardRadiusLarge,
          side: const BorderSide(color: AppColors.borderSubtle, width: 1.0),
        ),
        titleTextStyle: AppTextStyles.titleLarge,
        contentTextStyle: AppTextStyles.bodyMedium,
        actionsPadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xs,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        clipBehavior: Clip.antiAlias,
      );

  // ══════════════════════════════════════════
  // BOTTOM SHEET THEME
  // ══════════════════════════════════════════

  static BottomSheetThemeData get _bottomSheetTheme => BottomSheetThemeData(
        backgroundColor: AppColors.surfaceSheet,
        surfaceTintColor: Colors.transparent,
        elevation: AppElevation.xl2,
        modalElevation: AppElevation.xl3,
        shadowColor: AppColors.black.withValues(alpha: 0.60),

        // Only top corners rounded
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppRadius.xl3),
            topRight: Radius.circular(AppRadius.xl3),
          ),
        ),

        // Drag handle color
        dragHandleColor: AppColors.borderStandard,
        dragHandleSize: const Size(40, 4),

        // Clip
        clipBehavior: Clip.antiAlias,
      );

  // ══════════════════════════════════════════
  // SNACK BAR THEME
  // ══════════════════════════════════════════

  static SnackBarThemeData get _snackBarTheme => SnackBarThemeData(
        backgroundColor: AppColors.surfaceHigh,
        contentTextStyle: AppTextStyles.bodyMedium,
        actionTextColor: AppColors.primary,
        disabledActionTextColor: AppColors.textDisabled,
        elevation: AppElevation.lg,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardRadius,
          side: const BorderSide(color: AppColors.borderSubtle, width: 1.0),
        ),
        behavior: SnackBarBehavior.floating,
        width: null, // Full width floating
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        showCloseIcon: false,
        closeIconColor: AppColors.iconSecondary,
      );

  // ══════════════════════════════════════════
  // CHIP THEME
  // ══════════════════════════════════════════

  static ChipThemeData get _chipTheme => ChipThemeData(
        backgroundColor: AppColors.surface,
        selectedColor: AppColors.primary.withValues(alpha: 0.20),
        disabledColor: AppColors.surface.withValues(alpha: 0.50),
        deleteIconColor: AppColors.iconSecondary,
        checkmarkColor: AppColors.primary,
        labelStyle: AppTextStyles.chip,
        secondaryLabelStyle: AppTextStyles.chip.emerald,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        labelPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.pillRadius,
          side: const BorderSide(color: AppColors.borderStandard, width: 1.0),
        ),
        elevation: AppElevation.none,
        pressElevation: AppElevation.xs,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        side: const BorderSide(color: AppColors.borderStandard, width: 1.0),
      );

  // ══════════════════════════════════════════
  // DIVIDER THEME
  // ══════════════════════════════════════════

  static DividerThemeData get _dividerTheme => const DividerThemeData(
        color: AppColors.divider,
        thickness: 1.0,
        space: 1.0,
        indent: 0,
        endIndent: 0,
      );

  // ══════════════════════════════════════════
  // LIST TILE THEME
  // ══════════════════════════════════════════

  static ListTileThemeData get _listTileTheme => ListTileThemeData(
        // Background
        tileColor: Colors.transparent,
        selectedTileColor: AppColors.primary.withValues(alpha: 0.10),

        // Text colors
        textColor: AppColors.textPrimary,
        selectedColor: AppColors.primary,
        iconColor: AppColors.iconSecondary,

        // Padding
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.xs,
        ),

        // Shape
        shape: RoundedRectangleBorder(borderRadius: AppRadius.cardRadius),

        // Dense — slightly compact
        dense: false,

        // Visual density
        visualDensity: VisualDensity.comfortable,

        // Title text style
        titleTextStyle: AppTextStyles.titleSmall,

        // Subtitle text style
        subtitleTextStyle: AppTextStyles.bodySmall,

        // Leading and trailing icon size
        leadingAndTrailingTextStyle: AppTextStyles.labelMedium,

        // Min leading width
        minLeadingWidth: AppIconSizes.xl,

        // Min vertical padding
        minVerticalPadding: AppSpacing.sm,

        // Horizontal title gap
        horizontalTitleGap: AppSpacing.md,
      );

  // ══════════════════════════════════════════
  // SWITCH THEME
  // ══════════════════════════════════════════

  static SwitchThemeData get _switchTheme => SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.white;
          }
          return AppColors.iconSecondary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.surfaceHigh;
        }),
        trackOutlineColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.transparent;
          }
          return AppColors.borderStandard;
        }),
        trackOutlineWidth: WidgetStateProperty.all(1.5),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary.withValues(alpha: 0.12);
          }
          return AppColors.iconSecondary.withValues(alpha: 0.12);
        }),
      );

  // ══════════════════════════════════════════
  // CHECKBOX THEME
  // ══════════════════════════════════════════

  static CheckboxThemeData get _checkboxTheme => CheckboxThemeData(
        checkColor: WidgetStateProperty.all(AppColors.white),
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return Colors.transparent;
        }),
        side: const BorderSide(color: AppColors.borderStandard, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return AppColors.primary.withValues(alpha: 0.12);
          }
          return Colors.transparent;
        }),
      );

  // ══════════════════════════════════════════
  // RADIO THEME
  // ══════════════════════════════════════════

  static RadioThemeData get _radioTheme => RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.borderStandard;
        }),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return AppColors.primary.withValues(alpha: 0.12);
          }
          return Colors.transparent;
        }),
      );

  // ══════════════════════════════════════════
  // SLIDER THEME
  // ══════════════════════════════════════════

  static SliderThemeData get _sliderTheme => SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.surfaceHigh,
        thumbColor: AppColors.primary,
        overlayColor: AppColors.primary.withValues(alpha: 0.12),
        valueIndicatorColor: AppColors.surfaceHigh,
        valueIndicatorTextStyle: AppTextStyles.labelSmall,
        trackHeight: 4.0,
        thumbShape: const RoundSliderThumbShape(
          enabledThumbRadius: 8.0,
          elevation: 2.0,
        ),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20.0),
      );

  // ══════════════════════════════════════════
  // PROGRESS INDICATOR THEME
  // ══════════════════════════════════════════

  static ProgressIndicatorThemeData get _progressIndicatorTheme =>
      const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.surfaceHigh,
        circularTrackColor: AppColors.surfaceHigh,
        linearMinHeight: 4.0,
        refreshBackgroundColor: AppColors.surfaceElevated,
      );

  // ══════════════════════════════════════════
  // TAB BAR THEME
  // ══════════════════════════════════════════

  static TabBarThemeData get _tabBarTheme => TabBarThemeData(
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.navInactive,
        labelStyle: AppTextStyles.labelLarge,
        unselectedLabelStyle: AppTextStyles.labelLarge.secondary,
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: AppColors.divider,
        dividerHeight: 1.0,
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return AppColors.primary.withValues(alpha: 0.10);
          }
          return Colors.transparent;
        }),
        tabAlignment: TabAlignment.fill,
        indicator: UnderlineTabIndicator(
          borderSide: const BorderSide(color: AppColors.primary, width: 2.0),
          borderRadius: BorderRadius.circular(AppRadius.xs),
        ),
      );

  // ══════════════════════════════════════════
  // TOOLTIP THEME
  // ══════════════════════════════════════════

  static TooltipThemeData get _tooltipTheme => TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.surfaceHighest,
          borderRadius: AppRadius.buttonRadius,
          border: Border.all(color: AppColors.borderSubtle, width: 1.0),
          boxShadow: AppShadows.medium,
        ),
        textStyle: AppTextStyles.labelSmall,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        verticalOffset: AppSpacing.lg,
        preferBelow: true,
        waitDuration: const Duration(milliseconds: 500),
        showDuration: const Duration(milliseconds: 2000),
      );

  // ══════════════════════════════════════════
  // POPUP MENU THEME
  // ══════════════════════════════════════════

  static PopupMenuThemeData get _popupMenuTheme => PopupMenuThemeData(
        color: AppColors.surfaceHigh,
        surfaceTintColor: Colors.transparent,
        elevation: AppElevation.lg,
        shadowColor: AppColors.black.withValues(alpha: 0.40),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardRadius,
          side: const BorderSide(color: AppColors.borderSubtle, width: 1.0),
        ),
        textStyle: AppTextStyles.bodyMedium,
        labelTextStyle: WidgetStateProperty.all(AppTextStyles.bodyMedium),
        position: PopupMenuPosition.under,
        enableFeedback: true,
      );

  // ══════════════════════════════════════════
  // DRAWER THEME
  // ══════════════════════════════════════════

  static DrawerThemeData get _drawerTheme => DrawerThemeData(
        backgroundColor: AppColors.surfaceSheet,
        surfaceTintColor: Colors.transparent,
        elevation: AppElevation.xl2,
        shadowColor: AppColors.black.withValues(alpha: 0.60),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(AppRadius.xl3),
            bottomRight: Radius.circular(AppRadius.xl3),
          ),
        ),
        width: 300,
      );

  // ══════════════════════════════════════════
  // BADGE THEME
  // ══════════════════════════════════════════

  static BadgeThemeData get _badgeTheme => BadgeThemeData(
        backgroundColor: AppColors.error,
        textColor: AppColors.white,
        smallSize: 8.0,
        largeSize: 18.0,
        textStyle: AppTextStyles.badge,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
        alignment: AlignmentDirectional.topEnd,
        offset: const Offset(4, -4),
      );

  // ══════════════════════════════════════════
  // SEARCH BAR THEME
  // ══════════════════════════════════════════

  static SearchBarThemeData get _searchBarTheme => SearchBarThemeData(
        backgroundColor: WidgetStateProperty.all(AppColors.inputBackground),
        surfaceTintColor: WidgetStateProperty.all(Colors.transparent),
        shadowColor: WidgetStateProperty.all(Colors.transparent),
        elevation: WidgetStateProperty.all(AppElevation.none),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: AppRadius.cardRadius,
            side: const BorderSide(color: AppColors.borderStandard, width: 1.0),
          ),
        ),
        textStyle: WidgetStateProperty.all(AppTextStyles.inputText),
        hintStyle: WidgetStateProperty.all(AppTextStyles.inputHint),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
        ),
        constraints: const BoxConstraints(minHeight: 52, maxHeight: 60),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.pressed)) {
            return AppColors.primary.withValues(alpha: 0.06);
          }
          return Colors.transparent;
        }),
      );
}

// ============================================================
// SECTION: SYSTEM UI CONFIGURATION
// ============================================================
// Status bar aur navigation bar appearance control karna
// ============================================================

abstract final class AppSystemUI {
  /// Dark theme ke liye system UI style set karo
  /// main() mein call karo ya screen initState mein
  static void setDarkTheme() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        // Status bar (top) — transparent
        statusBarColor: Colors.transparent,
        // Status bar icons — white (light icons on dark bg)
        statusBarIconBrightness: Brightness.light,
        // iOS status bar
        statusBarBrightness: Brightness.dark,
        // Bottom nav bar (Android system)
        systemNavigationBarColor: AppColors.background,
        systemNavigationBarIconBrightness: Brightness.light,
        systemNavigationBarDividerColor: Colors.transparent,
      ),
    );
  }

  /// Portrait only orientation lock karo
  static Future<void> setPortraitOnly() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  /// Portrait + Landscape dono allow karo
  static Future<void> setAllOrientations() async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }
}
