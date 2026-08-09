// lib/shared/widgets/cards/app_feature_illustration_card.dart
// ============================================================
// QIBRA AI — FEATURE ILLUSTRATION CARD (v1.0)
// Phase: 8 — Premium UI Redesign
// Description: 3D icon feature card with:
//   - Large icon or 3D illustration at top
//   - Feature name + description
//   - Optional badge (Premium, New, Coming Soon, Beta)
//   - Optional gradient border
//   - Press animation with haptic
//   - Multiple sizes + color themes
//   - Image asset OR icon fallback
// Usage: Home feature grid, Onboarding, Settings features
// Reference: Bottom feature grid in reference image
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qibra_ai/core/design_system/app_colors.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';

// ============================================================
// SECTION 1 — ENUMS
// ============================================================

/// Card size variants
enum FeatureCardSize {
  compact, // 130x130 — for tight grids
  standard, // 150x180 — default (reference match)
  expanded, // 180x220 — for showcase
}

/// Card color themes
enum FeatureCardTheme {
  emerald, // Green — main features
  gold, // Gold — premium/special
  purple, // Purple — AI/tech features
  blue, // Blue — informational
  amber, // Amber — warnings/tips
  dark, // Dark surface — subtle
}

/// Badge types for the card
enum FeatureBadgeType {
  none,
  premium, // Gold "PREMIUM"
  newBadge, // Red "NEW"
  comingSoon, // Orange "SOON"
  beta, // Purple "BETA"
  free, // Green "FREE"
}

// ============================================================
// SECTION 2 — FEATURE CARD WIDGET
// ============================================================

/// Premium 3D icon feature card
///
/// Example usage:
/// ```dart
/// AppFeatureIllustrationCard(
///   title: 'Prayer Times',
///   description: 'Accurate prayer times with beautiful countdown',
///   icon: Icons.access_time_filled_rounded,
///   theme: FeatureCardTheme.emerald,
///   onTap: () => print('Tapped'),
/// )
/// ```
class AppFeatureIllustrationCard extends StatefulWidget {
  /// Feature title (e.g., "Prayer Times")
  final String title;

  /// Description text (2-3 lines)
  final String description;

  /// Icon to display (if imagePath not provided)
  final IconData? icon;

  /// Image asset path (overrides icon if provided)
  final String? imagePath;

  /// Card size variant
  final FeatureCardSize size;

  /// Color theme
  final FeatureCardTheme theme;

  /// Optional badge
  final FeatureBadgeType badge;

  /// Custom badge text (overrides badge type default)
  final String? customBadgeText;

  /// Tap handler
  final VoidCallback? onTap;

  /// Long press handler
  final VoidCallback? onLongPress;

  /// Show gradient border effect
  final bool showGradientBorder;

  /// Show glow effect around icon
  final bool showIconGlow;

  /// Custom primary color (overrides theme)
  final Color? customPrimaryColor;

  /// Custom card background color
  final Color? customBackgroundColor;

  const AppFeatureIllustrationCard({
    super.key,
    required this.title,
    required this.description,
    this.icon,
    this.imagePath,
    this.size = FeatureCardSize.standard,
    this.theme = FeatureCardTheme.emerald,
    this.badge = FeatureBadgeType.none,
    this.customBadgeText,
    this.onTap,
    this.onLongPress,
    this.showGradientBorder = false,
    this.showIconGlow = true,
    this.customPrimaryColor,
    this.customBackgroundColor,
  }) : assert(icon != null || imagePath != null,
            'Either icon or imagePath must be provided');

  @override
  State<AppFeatureIllustrationCard> createState() =>
      _AppFeatureIllustrationCardState();
}

// ============================================================
// SECTION 3 — STATE CLASS (for press animation)
// ============================================================

class _AppFeatureIllustrationCardState extends State<AppFeatureIllustrationCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(
        parent: _pressController,
        curve: Curves.easeOut,
      ),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    HapticFeedback.selectionClick();
    _pressController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _pressController.reverse();
  }

  void _handleTapCancel() {
    _pressController.reverse();
  }

  // ============================================================
  // BUILD METHOD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final _CardTheme colors = _getThemeColors(widget.theme);
    final Color effectivePrimary = widget.customPrimaryColor ?? colors.primary;
    final Color effectiveBackground =
        widget.customBackgroundColor ?? colors.background;
    final _CardDimensions dims = _getDimensions(widget.size);

    Widget card = AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        );
      },
      child: Container(
        width: dims.width,
        height: dims.height,
        decoration: BoxDecoration(
          color: effectiveBackground,
          borderRadius: AppRadius.cardRadiusLarge,
          border: widget.showGradientBorder
              ? null
              : Border.all(
                  color: effectivePrimary.withValues(alpha: 0.15),
                  width: 1,
                ),
          boxShadow: [
            BoxShadow(
              color: effectivePrimary.withValues(alpha: 0.08),
              blurRadius: 16,
              spreadRadius: 0,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // ── LAYER 1: Optional gradient border ──────────
            if (widget.showGradientBorder)
              _buildGradientBorderLayer(effectivePrimary),

            // ── LAYER 2: Main content ──────────────────────
            _buildContent(dims, effectivePrimary, colors),

            // ── LAYER 3: Optional badge (top-right) ────────
            if (widget.badge != FeatureBadgeType.none)
              Positioned(
                top: 10,
                right: 10,
                child: _buildBadge(),
              ),
          ],
        ),
      ),
    );

    // Wrap with tap handler
    if (widget.onTap != null || widget.onLongPress != null) {
      card = GestureDetector(
        onTap: widget.onTap,
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onLongPress: () {
          HapticFeedback.mediumImpact();
          widget.onLongPress?.call();
        },
        child: card,
      );
    }

    return card;
  }

  // ============================================================
  // SECTION 4 — SUB-COMPONENTS
  // ============================================================

  /// LAYER 1: Gradient border (premium look)
  Widget _buildGradientBorderLayer(Color primary) {
    return Positioned.fill(
      child: Container(
        padding: const EdgeInsets.all(1.5),
        decoration: BoxDecoration(
          borderRadius: AppRadius.cardRadiusLarge,
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primary.withValues(alpha: 0.50),
              AppColors.accent.withValues(alpha: 0.30),
              primary.withValues(alpha: 0.50),
            ],
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            color: widget.customBackgroundColor ?? AppColors.surface,
            borderRadius: BorderRadius.circular(23),
          ),
        ),
      ),
    );
  }

  /// LAYER 2: Main content (icon + title + description)
  Widget _buildContent(
    _CardDimensions dims,
    Color primary,
    _CardTheme colors,
  ) {
    return Padding(
      padding: EdgeInsets.all(dims.padding),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Icon / Image section ────────────────────────
          _buildIconSection(dims, primary),

          SizedBox(height: dims.iconTextGap),

          // ── Title ──────────────────────────────────────
          Text(
            widget.title,
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              fontSize: dims.titleSize,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),

          SizedBox(height: dims.titleDescGap),

          // ── Description ────────────────────────────────
          Flexible(
            child: Text(
              widget.description,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: dims.descriptionSize,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
              maxLines: dims.descriptionMaxLines,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  /// Icon section (image or icon with glow)
  Widget _buildIconSection(_CardDimensions dims, Color primary) {
    return SizedBox(
      width: dims.iconContainerSize,
      height: dims.iconContainerSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Glow effect (optional)
          if (widget.showIconGlow)
            Container(
              width: dims.iconContainerSize * 0.8,
              height: dims.iconContainerSize * 0.8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primary.withValues(alpha: 0.25),
                    blurRadius: 20,
                    spreadRadius: 0,
                  ),
                ],
              ),
            ),

          // Icon container background
          Container(
            width: dims.iconContainerSize,
            height: dims.iconContainerSize,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  primary.withValues(alpha: 0.15),
                  primary.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: AppRadius.cardRadius,
              border: Border.all(
                color: primary.withValues(alpha: 0.20),
                width: 1,
              ),
            ),
          ),

          // Actual icon or image
          _buildIconOrImage(dims, primary),
        ],
      ),
    );
  }

  /// Icon or image widget
  Widget _buildIconOrImage(_CardDimensions dims, Color primary) {
    // If image path provided, use it (with error fallback to icon)
    if (widget.imagePath != null && widget.imagePath!.isNotEmpty) {
      return Image.asset(
        widget.imagePath!,
        width: dims.iconContainerSize * 0.65,
        height: dims.iconContainerSize * 0.65,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          // Fallback to icon if image fails
          return Icon(
            widget.icon ?? Icons.star_rounded,
            color: primary,
            size: dims.iconSize,
          );
        },
      );
    }

    // Use icon
    return Icon(
      widget.icon,
      color: primary,
      size: dims.iconSize,
    );
  }

  /// LAYER 3: Badge (Premium/New/Coming Soon)
  Widget _buildBadge() {
    final _BadgeConfig badgeConfig = _getBadgeConfig(widget.badge);
    final String text = widget.customBadgeText ?? badgeConfig.text;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeConfig.color,
        borderRadius: AppRadius.pillRadius,
        boxShadow: [
          BoxShadow(
            color: badgeConfig.color.withValues(alpha: 0.40),
            blurRadius: 6,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Text(
        text,
        style: AppTextStyles.labelSmall.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w800,
          fontSize: 8,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  // ============================================================
  // SECTION 5 — HELPERS
  // ============================================================

  /// Get theme colors
  _CardTheme _getThemeColors(FeatureCardTheme theme) {
    switch (theme) {
      case FeatureCardTheme.emerald:
        return const _CardTheme(
          primary: AppColors.primary,
          background: AppColors.surface,
        );

      case FeatureCardTheme.gold:
        return const _CardTheme(
          primary: AppColors.accent,
          background: AppColors.surface,
        );

      case FeatureCardTheme.purple:
        return const _CardTheme(
          primary: Color(0xFF7C3AED),
          background: AppColors.surface,
        );

      case FeatureCardTheme.blue:
        return const _CardTheme(
          primary: Color(0xFF0891B2),
          background: AppColors.surface,
        );

      case FeatureCardTheme.amber:
        return const _CardTheme(
          primary: Color(0xFFF59E0B),
          background: AppColors.surface,
        );

      case FeatureCardTheme.dark:
        return const _CardTheme(
          primary: AppColors.textSecondary,
          background: AppColors.surfaceElevated,
        );
    }
  }

  /// Get badge config
  _BadgeConfig _getBadgeConfig(FeatureBadgeType type) {
    switch (type) {
      case FeatureBadgeType.premium:
        return const _BadgeConfig(text: 'PREMIUM', color: AppColors.accent);
      case FeatureBadgeType.newBadge:
        return const _BadgeConfig(text: 'NEW', color: AppColors.error);
      case FeatureBadgeType.comingSoon:
        return const _BadgeConfig(text: 'SOON', color: Color(0xFFF59E0B));
      case FeatureBadgeType.beta:
        return const _BadgeConfig(text: 'BETA', color: Color(0xFF7C3AED));
      case FeatureBadgeType.free:
        return const _BadgeConfig(text: 'FREE', color: AppColors.primary);
      case FeatureBadgeType.none:
        return const _BadgeConfig(text: '', color: Colors.transparent);
    }
  }

  /// Get dimensions based on size
  _CardDimensions _getDimensions(FeatureCardSize size) {
    switch (size) {
      case FeatureCardSize.compact:
        return const _CardDimensions(
          width: 130,
          height: 150,
          padding: AppSpacing.sm,
          iconContainerSize: 44,
          iconSize: 24,
          iconTextGap: AppSpacing.sm,
          titleDescGap: 3,
          titleSize: 12,
          descriptionSize: 9,
          descriptionMaxLines: 2,
        );

      case FeatureCardSize.standard:
        return const _CardDimensions(
          width: 150,
          height: 180,
          padding: AppSpacing.md,
          iconContainerSize: 56,
          iconSize: 30,
          iconTextGap: AppSpacing.md,
          titleDescGap: 4,
          titleSize: 14,
          descriptionSize: 10,
          descriptionMaxLines: 3,
        );

      case FeatureCardSize.expanded:
        return const _CardDimensions(
          width: 180,
          height: 220,
          padding: AppSpacing.lg,
          iconContainerSize: 72,
          iconSize: 38,
          iconTextGap: AppSpacing.lg,
          titleDescGap: 6,
          titleSize: 16,
          descriptionSize: 11,
          descriptionMaxLines: 3,
        );
    }
  }
}

// ============================================================
// SECTION 6 — HELPER CLASSES
// ============================================================

class _CardTheme {
  final Color primary;
  final Color background;

  const _CardTheme({
    required this.primary,
    required this.background,
  });
}

class _BadgeConfig {
  final String text;
  final Color color;

  const _BadgeConfig({
    required this.text,
    required this.color,
  });
}

class _CardDimensions {
  final double width;
  final double height;
  final double padding;
  final double iconContainerSize;
  final double iconSize;
  final double iconTextGap;
  final double titleDescGap;
  final double titleSize;
  final double descriptionSize;
  final int descriptionMaxLines;

  const _CardDimensions({
    required this.width,
    required this.height,
    required this.padding,
    required this.iconContainerSize,
    required this.iconSize,
    required this.iconTextGap,
    required this.titleDescGap,
    required this.titleSize,
    required this.descriptionSize,
    required this.descriptionMaxLines,
  });
}

// ============================================================
// SECTION 7 — FEATURE GRID HELPER (horizontal scroll)
// ============================================================

/// Data model for a feature item
class FeatureItem {
  final String title;
  final String description;
  final IconData? icon;
  final String? imagePath;
  final FeatureCardTheme theme;
  final FeatureBadgeType badge;
  final VoidCallback? onTap;

  const FeatureItem({
    required this.title,
    required this.description,
    this.icon,
    this.imagePath,
    this.theme = FeatureCardTheme.emerald,
    this.badge = FeatureBadgeType.none,
    this.onTap,
  });
}

/// Horizontal scrollable feature list (like reference bottom)
///
/// Example usage:
/// ```dart
/// AppFeatureIllustrationList(
///   features: [
///     FeatureItem(title: 'Prayer Times', description: '...', icon: Icons.access_time),
///     FeatureItem(title: 'Quran', description: '...', icon: Icons.menu_book),
///   ],
/// )
/// ```
class AppFeatureIllustrationList extends StatelessWidget {
  final List<FeatureItem> features;
  final FeatureCardSize cardSize;
  final double horizontalPadding;
  final double cardSpacing;

  const AppFeatureIllustrationList({
    super.key,
    required this.features,
    this.cardSize = FeatureCardSize.standard,
    this.horizontalPadding = AppSpacing.lg,
    this.cardSpacing = AppSpacing.md,
  });

  @override
  Widget build(BuildContext context) {
    final double listHeight = _getListHeight(cardSize);

    return SizedBox(
      height: listHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        physics: const BouncingScrollPhysics(),
        itemCount: features.length,
        separatorBuilder: (_, __) => SizedBox(width: cardSpacing),
        itemBuilder: (context, index) {
          final FeatureItem feature = features[index];
          return AppFeatureIllustrationCard(
            title: feature.title,
            description: feature.description,
            icon: feature.icon,
            imagePath: feature.imagePath,
            theme: feature.theme,
            badge: feature.badge,
            size: cardSize,
            onTap: feature.onTap,
          );
        },
      ),
    );
  }

  double _getListHeight(FeatureCardSize size) {
    switch (size) {
      case FeatureCardSize.compact:
        return 160;
      case FeatureCardSize.standard:
        return 190;
      case FeatureCardSize.expanded:
        return 230;
    }
  }
}

// ============================================================
// END OF FILE — app_feature_illustration_card.dart (v1.0)
// ============================================================
