// lib/shared/widgets/cards/app_hero_image_card.dart
// ============================================================
// QIBRA AI — HERO IMAGE CARD WIDGET (v1.0)
// Phase: 8 — Premium UI Redesign
// Description: Reusable hero image card with:
//   - Background image (asset) with gradient fallback
//   - Dark gradient overlay for text readability
//   - Rounded corners with premium shadows
//   - Optional tap handler with haptic feedback
//   - Configurable height, overlay opacity, gradient colors
//   - Loading states + error handling
// Usage: Home greeting, Ramadan widget, Daily verse, Al-Fatihah hero
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qibra_ai/core/design_system/app_colors.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';

// ============================================================
// SECTION 1 — OVERLAY STYLE ENUM
// ============================================================

/// Different overlay styles for different use cases
enum HeroOverlayStyle {
  /// Dark gradient from bottom (default) - for text at bottom
  bottomDark,

  /// Dark gradient from top - for text at top
  topDark,

  /// Full dark overlay - maximum text contrast
  fullDark,

  /// Emerald tint - for Islamic themed cards
  emeraldTint,

  /// Gold tint - for Ramadan/special occasions
  goldTint,

  /// No overlay - pure image
  none,
}

// ============================================================
// SECTION 2 — HERO IMAGE CARD WIDGET
// ============================================================

/// Premium hero image card with gradient overlay
///
/// Example usage:
/// ```dart
/// AppHeroImageCard(
///   imagePath: 'assets/images/hero/mosque_night.png',
///   height: 200,
///   overlayStyle: HeroOverlayStyle.bottomDark,
///   onTap: () => print('Tapped'),
///   child: Padding(
///     padding: EdgeInsets.all(20),
///     child: Text('Assalamu Alaikum'),
///   ),
/// )
/// ```
class AppHeroImageCard extends StatelessWidget {
  /// Asset image path (e.g., 'assets/images/hero/mosque_night.png')
  final String? imagePath;

  /// Card height — default 200
  final double height;

  /// Card width — default full width
  final double? width;

  /// Content on top of image
  final Widget? child;

  /// Tap handler with haptic feedback
  final VoidCallback? onTap;

  /// Border radius — default cardRadiusLarge (24)
  final BorderRadius? borderRadius;

  /// Overlay style for text readability
  final HeroOverlayStyle overlayStyle;

  /// Custom overlay opacity (0.0 - 1.0) - overrides style default
  final double? overlayOpacity;

  /// Fallback gradient colors when image is null or fails to load
  final List<Color>? fallbackGradient;

  /// Image alignment
  final Alignment imageAlignment;

  /// Image fit
  final BoxFit imageFit;

  /// Custom shadow — default emeraldGlow
  final List<BoxShadow>? boxShadow;

  /// Padding for child content
  final EdgeInsetsGeometry? childPadding;

  /// Show subtle border
  final bool showBorder;

  const AppHeroImageCard({
    super.key,
    this.imagePath,
    this.height = 200,
    this.width,
    this.child,
    this.onTap,
    this.borderRadius,
    this.overlayStyle = HeroOverlayStyle.bottomDark,
    this.overlayOpacity,
    this.fallbackGradient,
    this.imageAlignment = Alignment.center,
    this.imageFit = BoxFit.cover,
    this.boxShadow,
    this.childPadding,
    this.showBorder = false,
  });

  // ── DEFAULT FALLBACK GRADIENT (mosque night vibe) ─────────
  static const List<Color> _defaultFallbackGradient = [
    Color(0xFF0A2540), // Deep navy
    Color(0xFF00A86B), // Emerald
    Color(0xFF003D26), // Dark emerald
  ];

  // ============================================================
  // BUILD METHOD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final BorderRadius effectiveRadius =
        borderRadius ?? AppRadius.cardRadiusLarge;
    final List<Color> effectiveFallback =
        fallbackGradient ?? _defaultFallbackGradient;

    // ── OUTER CONTAINER (shadow + shape) ────────────────────
    Widget cardContainer = Container(
      height: height,
      width: width ?? double.infinity,
      decoration: BoxDecoration(
        borderRadius: effectiveRadius,
        boxShadow: boxShadow ?? _defaultShadow(),
      ),
      child: ClipRRect(
        borderRadius: effectiveRadius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Layer 1: Background (image or gradient fallback)
            _buildBackgroundLayer(effectiveFallback),

            // Layer 2: Overlay (for text readability)
            _buildOverlayLayer(),

            // Layer 3: Optional subtle border
            if (showBorder) _buildBorderLayer(effectiveRadius),

            // Layer 4: Child content (on top)
            if (child != null)
              Padding(
                padding: childPadding ?? const EdgeInsets.all(AppSpacing.xl2),
                child: child!,
              ),
          ],
        ),
      ),
    );

    // ── WRAP WITH TAP HANDLER (if provided) ─────────────────
    if (onTap != null) {
      return GestureDetector(
        onTapDown: (_) => HapticFeedback.lightImpact(),
        onTap: onTap,
        child: cardContainer,
      );
    }

    return cardContainer;
  }

  // ============================================================
  // SECTION 3 — LAYER BUILDERS
  // ============================================================

  /// LAYER 1: Background image with gradient fallback
  Widget _buildBackgroundLayer(List<Color> fallback) {
    // Agar imagePath null hai ya empty hai → gradient use karo
    if (imagePath == null || imagePath!.isEmpty) {
      return _buildGradientFallback(fallback);
    }

    // Image with error handling
    return Image.asset(
      imagePath!,
      fit: imageFit,
      alignment: imageAlignment,
      errorBuilder: (context, error, stackTrace) {
        // Agar image load nahi hui → gradient fallback dikha do
        return _buildGradientFallback(fallback);
      },
      // Optional: loading builder for network images (not used for assets)
      // frameBuilder for smoother appearance
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          child: child,
        );
      },
    );
  }

  /// Gradient fallback when image is unavailable
  Widget _buildGradientFallback(List<Color> colors) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
          stops: colors.length == 2 ? const [0.0, 1.0] : null,
        ),
      ),
      child: Stack(
        children: [
          // Subtle decorative circles (like reference image)
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            left: -40,
            bottom: -40,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.08),
              ),
            ),
          ),
          // Subtle mosque icon (decorative)
          Positioned(
            right: 20,
            top: 20,
            child: Icon(
              Icons.mosque_rounded,
              size: 60,
              color: AppColors.white.withValues(alpha: 0.10),
            ),
          ),
          // Crescent moon icon
          Positioned(
            right: 30,
            top: 30,
            child: Icon(
              Icons.nightlight_round,
              size: 24,
              color: AppColors.accent.withValues(alpha: 0.40),
            ),
          ),
        ],
      ),
    );
  }

  /// LAYER 2: Gradient overlay for text readability
  Widget _buildOverlayLayer() {
    if (overlayStyle == HeroOverlayStyle.none) {
      return const SizedBox.shrink();
    }

    final _OverlayConfig config = _getOverlayConfig();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: config.begin,
          end: config.end,
          colors: config.colors,
          stops: config.stops,
        ),
      ),
    );
  }

  /// LAYER 3: Optional subtle border
  Widget _buildBorderLayer(BorderRadius radius) {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(
            color: AppColors.white.withValues(alpha: 0.10),
            width: 1,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SECTION 4 — OVERLAY CONFIGURATION
  // ============================================================

  /// Get overlay config based on style
  _OverlayConfig _getOverlayConfig() {
    final double opacity = overlayOpacity ?? _defaultOpacity();

    switch (overlayStyle) {
      case HeroOverlayStyle.bottomDark:
        return _OverlayConfig(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: opacity * 0.5),
            Colors.black.withValues(alpha: opacity),
          ],
          stops: const [0.0, 0.6, 1.0],
        );

      case HeroOverlayStyle.topDark:
        return _OverlayConfig(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Colors.transparent,
            Colors.black.withValues(alpha: opacity * 0.5),
            Colors.black.withValues(alpha: opacity),
          ],
          stops: const [0.0, 0.6, 1.0],
        );

      case HeroOverlayStyle.fullDark:
        return _OverlayConfig(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withValues(alpha: opacity * 0.7),
            Colors.black.withValues(alpha: opacity),
          ],
          stops: const [0.0, 1.0],
        );

      case HeroOverlayStyle.emeraldTint:
        return _OverlayConfig(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            AppColors.primary.withValues(alpha: opacity * 0.3),
            AppColors.primary.withValues(alpha: opacity * 0.7),
          ],
          stops: const [0.0, 0.5, 1.0],
        );

      case HeroOverlayStyle.goldTint:
        return _OverlayConfig(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.transparent,
            AppColors.accent.withValues(alpha: opacity * 0.2),
            AppColors.accent.withValues(alpha: opacity * 0.5),
          ],
          stops: const [0.0, 0.5, 1.0],
        );
      case HeroOverlayStyle.none:
        return const _OverlayConfig(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.transparent, Colors.transparent],
          stops: [0.0, 1.0],
        );
    }
  }

  /// Default opacity based on overlay style
  double _defaultOpacity() {
    switch (overlayStyle) {
      case HeroOverlayStyle.bottomDark:
      case HeroOverlayStyle.topDark:
        return 0.75;
      case HeroOverlayStyle.fullDark:
        return 0.65;
      case HeroOverlayStyle.emeraldTint:
      case HeroOverlayStyle.goldTint:
        return 0.8;
      case HeroOverlayStyle.none:
        return 0.0;
    }
  }

  /// Default shadow based on overlay style
  List<BoxShadow> _defaultShadow() {
    switch (overlayStyle) {
      case HeroOverlayStyle.emeraldTint:
        return [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.30),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ];

      case HeroOverlayStyle.goldTint:
        return [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.30),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ];

      default:
        return [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            spreadRadius: 0,
            offset: const Offset(0, 6),
          ),
        ];
    }
  }
}

// ============================================================
// SECTION 5 — OVERLAY CONFIG HELPER CLASS
// ============================================================

class _OverlayConfig {
  final Alignment begin;
  final Alignment end;
  final List<Color> colors;
  final List<double>? stops;

  const _OverlayConfig({
    required this.begin,
    required this.end,
    required this.colors,
    this.stops,
  });
}

// ============================================================
// SECTION 6 — PREMIUM VARIANTS (Optional convenience widgets)
// ============================================================

/// Pre-configured mosque night hero card (for home greeting)
class AppMosqueHeroCard extends StatelessWidget {
  final Widget? child;
  final double height;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? childPadding;

  const AppMosqueHeroCard({
    super.key,
    this.child,
    this.height = 200,
    this.onTap,
    this.childPadding,
  });

  @override
  Widget build(BuildContext context) {
    return AppHeroImageCard(
      imagePath: 'assets/images/hero/mosque_night.png',
      height: height,
      onTap: onTap,
      childPadding: childPadding,
      overlayStyle: HeroOverlayStyle.bottomDark,
      overlayOpacity: 0.65,
      fallbackGradient: const [
        Color(0xFF0A2540), // Deep navy
        Color(0xFF1A3A5C), // Mid navy
        Color(0xFF00A86B), // Emerald bottom
      ],
      child: child,
    );
  }
}

/// Pre-configured Ramadan hero card
class AppRamadanHeroCard extends StatelessWidget {
  final Widget? child;
  final double height;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? childPadding;

  const AppRamadanHeroCard({
    super.key,
    this.child,
    this.height = 200,
    this.onTap,
    this.childPadding,
  });

  @override
  Widget build(BuildContext context) {
    return AppHeroImageCard(
      imagePath: 'assets/images/hero/ramadan_lanterns.png',
      height: height,
      onTap: onTap,
      childPadding: childPadding,
      overlayStyle: HeroOverlayStyle.bottomDark,
      overlayOpacity: 0.60,
      fallbackGradient: const [
        Color(0xFF6B21A8), // Purple
        Color(0xFF4C1D95), // Deep purple
        Color(0xFF1E1B4B), // Indigo
      ],
      child: child,
    );
  }
}

/// Pre-configured daily verse hero card
class AppVerseHeroCard extends StatelessWidget {
  final Widget? child;
  final double height;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? childPadding;

  const AppVerseHeroCard({
    super.key,
    this.child,
    this.height = 180,
    this.onTap,
    this.childPadding,
  });

  @override
  Widget build(BuildContext context) {
    return AppHeroImageCard(
      imagePath: 'assets/images/hero/daily_verse_bg.png',
      height: height,
      onTap: onTap,
      childPadding: childPadding,
      overlayStyle: HeroOverlayStyle.fullDark,
      overlayOpacity: 0.55,
      fallbackGradient: const [
        Color(0xFF1E1B4B), // Deep indigo
        Color(0xFF312E81), // Indigo
        Color(0xFF3730A3), // Purple
      ],
      child: child,
    );
  }
}

// ============================================================
// END OF FILE — app_hero_image_card.dart (v1.0)
// ============================================================
