// lib/shared/widgets/cards/app_card.dart

// ============================================================
// QIBRA AI — REUSABLE CARD COMPONENTS
// Version: 1.0.0
// Description: All card types for QIBRA AI.
//              Standard, Gradient, Feature, Info,
//              Prayer, List, and Shimmer cards.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_colors.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';

// ============================================================
// SECTION 1: APP CARD (Standard Dark Card)
// ============================================================
// Sabse basic card — dark surface, subtle border
// Use: General content containers
// ============================================================

class AppCard extends StatefulWidget {
  /// Card ke andar content
  final Widget child;

  /// Press hone par kya karna hai (optional)
  final VoidCallback? onTap;

  /// Custom padding (default: standard card padding)
  final EdgeInsets? padding;

  /// Custom background color
  final Color? color;

  /// Border dikhana hai ya nahi
  final bool showBorder;

  /// Custom border color
  final Color? borderColor;

  /// Elevated version (thoda lighter background)
  final bool elevated;

  /// Shadow dikhana hai ya nahi
  final bool showShadow;

  /// Custom border radius
  final BorderRadius? borderRadius;

  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.color,
    this.showBorder = true,
    this.borderColor,
    this.elevated = false,
    this.showShadow = true,
    this.borderRadius,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Tappable hai ya nahi
    final bool isTappable = widget.onTap != null;

    // Background color decide karo
    final Color bgColor = widget.color ??
        (widget.elevated ? AppColors.surfaceElevated : AppColors.surface);

    Widget card = AnimatedContainer(
      duration: AppDurations.fast,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: widget.borderRadius ?? AppRadius.cardRadius,
        border: widget.showBorder
            ? Border.all(
                color: widget.borderColor ?? AppColors.borderSubtle,
                width: 1.0,
              )
            : null,
        boxShadow: widget.showShadow ? AppShadows.darkCard : null,
      ),
      child: ClipRRect(
        // ClipRRect = content ko rounded corners ke andar clip karo
        borderRadius: widget.borderRadius ?? AppRadius.cardRadius,
        child: Padding(
          padding: widget.padding ?? AppSpacing.cardPadding,
          child: widget.child,
        ),
      ),
    );

    // Tappable version
    if (isTappable) {
      return GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTap?.call();
        },
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: card,
        ),
      );
    }

    return card;
  }
}

// ============================================================
// SECTION 2: APP GRADIENT CARD
// ============================================================
// Gradient background card — premium feel
// Use: Featured content, hero sections
// ============================================================

class AppGradientCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;

  /// Custom gradient (default: emerald)
  final Gradient? gradient;

  /// Gold gradient use karna hai?
  final bool isGold;

  /// Custom border radius
  final BorderRadius? borderRadius;

  /// Shadow type
  final bool useGoldGlow;

  const AppGradientCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.gradient,
    this.isGold = false,
    this.borderRadius,
    this.useGoldGlow = false,
  });

  @override
  State<AppGradientCard> createState() => _AppGradientCardState();
}

class _AppGradientCardState extends State<AppGradientCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isTappable = widget.onTap != null;

    // Gradient decide karo
    final Gradient gradient = widget.gradient ??
        (widget.isGold ? AppGradients.goldCard : AppGradients.emeraldCard);

    // Shadow decide karo
    final List<BoxShadow> shadow = widget.isGold || widget.useGoldGlow
        ? AppShadows.goldGlow
        : AppShadows.emeraldGlow;

    Widget card = Container(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: widget.borderRadius ?? AppRadius.cardRadiusLarge,
        boxShadow: shadow,
      ),
      child: ClipRRect(
        borderRadius: widget.borderRadius ?? AppRadius.cardRadiusLarge,
        child: Padding(
          padding: widget.padding ?? AppSpacing.cardPadding,
          child: widget.child,
        ),
      ),
    );

    if (isTappable) {
      return GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) => _controller.reverse(),
        onTapCancel: () => _controller.reverse(),
        onTap: () {
          HapticFeedback.selectionClick();
          widget.onTap?.call();
        },
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: card,
        ),
      );
    }

    return card;
  }
}

// ============================================================
// SECTION 3: APP FEATURE CARD
// ============================================================
// Islamic feature cards — Quran, Prayer, Hadith, AI etc
// Use: Home screen feature grid
// ============================================================

class AppFeatureCard extends StatefulWidget {
  /// Feature ka naam
  final String title;

  /// Feature ki description
  final String? subtitle;

  /// Feature icon
  final IconData icon;

  /// Icon background color
  final Color? iconColor;

  /// Card background gradient
  final Gradient? gradient;

  /// Press handler
  final VoidCallback? onTap;

  /// Gold variant (premium feature)
  final bool isGold;

  /// Badge text (e.g., "New", "Pro")
  final String? badge;

  /// Custom width (default: expands)
  final double? width;

  /// Custom height
  final double? height;

  const AppFeatureCard({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.iconColor,
    this.gradient,
    this.onTap,
    this.isGold = false,
    this.badge,
    this.width,
    this.height,
  });

  @override
  State<AppFeatureCard> createState() => _AppFeatureCardState();
}

class _AppFeatureCardState extends State<AppFeatureCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Icon color decide karo
    final Color iconClr = widget.iconColor ??
        (widget.isGold ? AppColors.accent : AppColors.primary);

    // Card gradient decide karo
    final Gradient cardGradient = widget.gradient ?? AppGradients.premiumCard;

    // Glow shadow decide karo
    final List<BoxShadow> shadow =
        widget.isGold ? AppShadows.goldGlow : AppShadows.darkCard;

    return GestureDetector(
      onTapDown: (_) {
        if (widget.onTap != null) _controller.forward();
      },
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              widget.onTap?.call();
            },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            gradient: cardGradient,
            borderRadius: AppRadius.featureCardRadius,
            boxShadow: shadow,
            border: Border.all(
              color: widget.isGold
                  ? AppColors.borderGold.withValues(alpha: 0.30)
                  : AppColors.borderSubtle,
              width: 1.0,
            ),
          ),
          child: ClipRRect(
            borderRadius: AppRadius.featureCardRadius,
            child: Stack(
              children: [
                // Islamic pattern overlay (subtle)
                Positioned(
                  right: -20,
                  top: -20,
                  child: Icon(
                    widget.icon,
                    size: 80,
                    color: iconClr.withValues(alpha: 0.06),
                  ),
                ),

                // Main content
                Padding(
                  padding: AppSpacing.cardPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top row: Icon + Badge
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Icon container
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: iconClr.withValues(alpha: 0.15),
                              borderRadius: AppRadius.buttonRadius,
                              border: Border.all(
                                color: iconClr.withValues(alpha: 0.30),
                                width: 1,
                              ),
                            ),
                            child: Icon(
                              widget.icon,
                              color: iconClr,
                              size: AppIconSizes.md,
                            ),
                          ),

                          // Badge
                          if (widget.badge != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: widget.isGold
                                    ? AppColors.accent.withValues(alpha: 0.20)
                                    : AppColors.primary.withValues(alpha: 0.20),
                                borderRadius: AppRadius.pillRadius,
                                border: Border.all(
                                  color: widget.isGold
                                      ? AppColors.accent.withValues(alpha: 0.50)
                                      : AppColors.primary
                                          .withValues(alpha: 0.50),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                widget.badge!,
                                style: AppTextStyles.badge.copyWith(
                                  color: widget.isGold
                                      ? AppColors.accent
                                      : AppColors.primary,
                                ),
                              ),
                            ),
                        ],
                      ),

                      // Title + Subtitle
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: AppTextStyles.cardTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.subtitle != null) ...[
                            const SizedBox(height: AppSpacing.xs2),
                            Text(
                              widget.subtitle!,
                              style: AppTextStyles.cardSubtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SECTION 4: APP INFO CARD
// ============================================================
// Stats/info display card
// Use: Dashboard stats, counts, percentages
// ============================================================

class AppInfoCard extends StatelessWidget {
  /// Card title (top label)
  final String title;

  /// Main value (big number/text)
  final String value;

  /// Optional subtitle below value
  final String? subtitle;

  /// Leading icon
  final IconData? icon;

  /// Value color (default: primary white)
  final Color? valueColor;

  /// Icon color
  final Color? iconColor;

  /// Press handler
  final VoidCallback? onTap;

  /// Compact mode (smaller padding)
  final bool compact;

  const AppInfoCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.valueColor,
    this.iconColor,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: compact ? AppSpacing.cardPaddingCompact : AppSpacing.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Title row with optional icon
          Row(
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  color: iconColor ?? AppColors.iconSecondary,
                  size: AppIconSizes.sm,
                ),
                const SizedBox(width: AppSpacing.xs),
              ],
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyles.labelSmall.secondary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),

          // Main value
          Text(
            value,
            style: AppTextStyles.headlineSmall.copyWith(
              color: valueColor ?? AppColors.textPrimary,
              fontWeight: AppFontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          // Optional subtitle
          if (subtitle != null) ...[
            const SizedBox(height: AppSpacing.xs2),
            Text(
              subtitle!,
              style: AppTextStyles.bodySmall.secondary,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// SECTION 5: APP PRAYER CARD
// ============================================================
// Prayer time display card
// Use: Prayer times screen, home dashboard
// ============================================================

class AppPrayerCard extends StatelessWidget {
  /// Prayer name (e.g., "Fajr")
  final String prayerName;

  /// Prayer name in Arabic (e.g., "الفجر")
  final String prayerNameArabic;

  /// Prayer time (e.g., "05:30 AM")
  final String prayerTime;

  /// Is this the current/next prayer?
  final bool isActive;

  /// Is notification enabled for this prayer?
  final bool notificationEnabled;

  /// Notification toggle callback
  final VoidCallback? onNotificationToggle;

  const AppPrayerCard({
    super.key,
    required this.prayerName,
    required this.prayerNameArabic,
    required this.prayerTime,
    this.isActive = false,
    this.notificationEnabled = true,
    this.onNotificationToggle,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppDurations.normal,
      decoration: BoxDecoration(
        // Active prayer mein gradient, inactive mein solid
        gradient: isActive ? AppGradients.emeraldCard : null,
        color: isActive ? null : AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.50)
              : AppColors.borderSubtle,
          width: isActive ? 1.5 : 1.0,
        ),
        boxShadow: isActive ? AppShadows.emeraldGlow : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            // Active indicator dot
            AnimatedContainer(
              duration: AppDurations.normal,
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.white.withValues(alpha: 0.80)
                    : AppColors.borderStandard,
                borderRadius: AppRadius.pillRadius,
              ),
            ),

            const SizedBox(width: AppSpacing.md),

            // Prayer name column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    prayerName,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: isActive ? AppColors.white : AppColors.textPrimary,
                      fontWeight: isActive
                          ? AppFontWeight.semiBold
                          : AppFontWeight.medium,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs2),
                  Text(
                    prayerNameArabic,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isActive
                          ? AppColors.white.withValues(alpha: 0.70)
                          : AppColors.textSecondary,
                      fontFamily: AppFontFamily.arabic,
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),

            // Prayer time
            Text(
              prayerTime,
              style: AppTextStyles.prayerTime.copyWith(
                fontSize: 22,
                color: isActive ? AppColors.white : AppColors.textPrimary,
              ),
            ),

            const SizedBox(width: AppSpacing.md),

            // Notification bell icon
            GestureDetector(
              onTap: onNotificationToggle,
              child: Icon(
                notificationEnabled
                    ? Icons.notifications_active_outlined
                    : Icons.notifications_off_outlined,
                color: isActive
                    ? AppColors.white.withValues(alpha: 0.80)
                    : notificationEnabled
                        ? AppColors.primary
                        : AppColors.iconSecondary,
                size: AppIconSizes.md,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SECTION 6: APP LIST CARD
// ============================================================
// List item card — leading icon/image + title + subtitle + trailing
// Use: Hadith list, Surah list, Settings items
// ============================================================

class AppListCard extends StatelessWidget {
  /// Leading widget (icon, image, number)
  final Widget? leading;

  /// Title text
  final String title;

  /// Optional subtitle
  final String? subtitle;

  /// Trailing widget (arrow, switch, badge)
  final Widget? trailing;

  /// Press handler
  final VoidCallback? onTap;

  /// Show divider at bottom?
  final bool showDivider;

  /// Custom padding
  final EdgeInsets? padding;

  /// Background color
  final Color? color;

  const AppListCard({
    super.key,
    required this.title,
    this.leading,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showDivider = false,
    this.padding,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            // InkWell = ripple effect ke saath tappable
            onTap: onTap == null
                ? null
                : () {
                    HapticFeedback.selectionClick();
                    onTap?.call();
                  },
            borderRadius: AppRadius.cardRadius,
            splashColor: AppColors.primary.withValues(alpha: 0.08),
            highlightColor: AppColors.primary.withValues(alpha: 0.04),
            child: Container(
              padding: padding ??
                  const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
              decoration: BoxDecoration(
                color: color ?? AppColors.surface,
                borderRadius: AppRadius.cardRadius,
              ),
              child: Row(
                children: [
                  // Leading
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(width: AppSpacing.md),
                  ],

                  // Title + Subtitle
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: AppTextStyles.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: AppSpacing.xs2),
                          Text(
                            subtitle!,
                            style: AppTextStyles.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),

                  // Trailing
                  if (trailing != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    trailing!,
                  ] else if (onTap != null) ...[
                    const SizedBox(width: AppSpacing.sm),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: AppColors.iconSecondary,
                      size: AppIconSizes.xs,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),

        // Divider
        if (showDivider)
          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
            ),
            child: Divider(
              height: 1,
              color: AppColors.divider,
            ),
          ),
      ],
    );
  }
}

// ============================================================
// SECTION 7: APP QURAN CARD
// ============================================================
// Surah display card
// Use: Quran screen surah list
// ============================================================

class AppQuranCard extends StatelessWidget {
  /// Surah number
  final int surahNumber;

  /// Surah name in English
  final String surahName;

  /// Surah name in Arabic
  final String surahNameArabic;

  /// Total ayahs count
  final int ayahCount;

  /// Revelation type (Makki/Madani)
  final String revelationType;

  /// Press handler
  final VoidCallback? onTap;

  /// Is bookmarked?
  final bool isBookmarked;

  /// Bookmark toggle
  final VoidCallback? onBookmark;

  const AppQuranCard({
    super.key,
    required this.surahNumber,
    required this.surahName,
    required this.surahNameArabic,
    required this.ayahCount,
    required this.revelationType,
    this.onTap,
    this.isBookmarked = false,
    this.onBookmark,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          // Surah number badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: AppRadius.buttonRadius,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                '$surahNumber',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: AppFontWeight.bold,
                ),
              ),
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          // Surah info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  surahName,
                  style: AppTextStyles.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs2),
                Row(
                  children: [
                    Text(
                      '$ayahCount Ayahs',
                      style: AppTextStyles.labelSmall.secondary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Container(
                      width: 3,
                      height: 3,
                      decoration: const BoxDecoration(
                        color: AppColors.borderStandard,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      revelationType,
                      style: AppTextStyles.labelSmall.secondary,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Arabic name + bookmark
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                surahNameArabic,
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.accent,
                  fontFamily: AppFontFamily.arabic,
                ),
                textDirection: TextDirection.rtl,
              ),
              const SizedBox(height: AppSpacing.xs),
              GestureDetector(
                onTap: onBookmark,
                child: Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color:
                      isBookmarked ? AppColors.accent : AppColors.iconSecondary,
                  size: AppIconSizes.sm,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SECTION 8: APP SHIMMER CARD (Loading Skeleton)
// ============================================================
// Skeleton loading effect
// Use: Jab data load ho raha ho tab dikhao
// ============================================================

class AppShimmerCard extends StatefulWidget {
  /// Shimmer card ki width
  final double? width;

  /// Shimmer card ki height
  final double height;

  /// Custom border radius
  final BorderRadius? borderRadius;

  const AppShimmerCard({
    super.key,
    this.width,
    this.height = 80,
    this.borderRadius,
  });

  @override
  State<AppShimmerCard> createState() => _AppShimmerCardState();
}

class _AppShimmerCardState extends State<AppShimmerCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();

    // Shimmer animation — repeat hoti rahegi
    _shimmerController = AnimationController(
      vsync: this,
      duration: AppDurations.shimmer,
    )..repeat(); // repeat() = automatically loop karo

    _shimmerAnimation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(
      CurvedAnimation(
        parent: _shimmerController,
        curve: Curves.linear,
      ),
    );
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, child) {
        return Container(
          width: widget.width ?? double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius ?? AppRadius.cardRadius,
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                AppColors.shimmerBase,
                AppColors.shimmerHighlight,
                AppColors.shimmerBase,
              ],
              // stops control karte hain shimmer position
              stops: [
                (_shimmerAnimation.value - 1).clamp(0.0, 1.0),
                _shimmerAnimation.value.clamp(0.0, 1.0),
                (_shimmerAnimation.value + 1).clamp(0.0, 1.0),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
// SECTION 9: APP SHIMMER LIST (Multiple shimmer rows)
// ============================================================
// Multiple shimmer cards stacked
// Use: List loading state
// ============================================================

class AppShimmerList extends StatelessWidget {
  /// Kitne shimmer items dikhane hain
  final int itemCount;

  /// Har item ki height
  final double itemHeight;

  /// Items ke beech gap
  final double gap;

  const AppShimmerList({
    super.key,
    this.itemCount = 5,
    this.itemHeight = 80,
    this.gap = AppSpacing.sm,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        itemCount,
        (index) => Padding(
          padding: EdgeInsets.only(
            bottom: index < itemCount - 1 ? gap : 0,
          ),
          child: AppShimmerCard(height: itemHeight),
        ),
      ),
    );
  }
}

// ============================================================
// SECTION 10: APP HADITH CARD
// ============================================================
// Hadith display card
// Use: Hadith screen, Daily hadith widget
// ============================================================

class AppHadithCard extends StatelessWidget {
  /// Hadith Arabic text
  final String arabicText;

  /// Hadith English translation
  final String translation;

  /// Hadith narrator/source
  final String narrator;

  /// Collection name (e.g., Sahih al-Bukhari)
  final String collection;

  /// Hadith number
  final String? hadithNumber;

  /// Share callback
  final VoidCallback? onShare;

  /// Bookmark callback
  final VoidCallback? onBookmark;

  /// Is bookmarked?
  final bool isBookmarked;

  const AppHadithCard({
    super.key,
    required this.arabicText,
    required this.translation,
    required this.narrator,
    required this.collection,
    this.hadithNumber,
    this.onShare,
    this.onBookmark,
    this.isBookmarked = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: AppSpacing.cardPaddingLarge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Collection + Number
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      collection,
                      style: AppTextStyles.labelMedium
                          .copyWith(color: AppColors.accent),
                    ),
                    if (hadithNumber != null)
                      Text(
                        'Hadith #$hadithNumber',
                        style: AppTextStyles.labelSmall.secondary,
                      ),
                  ],
                ),
              ),

              // Action buttons
              Row(
                children: [
                  if (onShare != null)
                    GestureDetector(
                      onTap: onShare,
                      child: const Icon(
                        Icons.share_outlined,
                        color: AppColors.iconSecondary,
                        size: AppIconSizes.md,
                      ),
                    ),
                  const SizedBox(width: AppSpacing.md),
                  if (onBookmark != null)
                    GestureDetector(
                      onTap: onBookmark,
                      child: Icon(
                        isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                        color: isBookmarked
                            ? AppColors.accent
                            : AppColors.iconSecondary,
                        size: AppIconSizes.md,
                      ),
                    ),
                ],
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Decorative top line
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: AppGradients.gold,
              borderRadius: AppRadius.pillRadius,
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Arabic text
          Text(
            arabicText,
            style: AppArabicStyles.hadithArabic,
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
          ),

          const SizedBox(height: AppSpacing.lg),

          // Divider
          const Divider(color: AppColors.divider),

          const SizedBox(height: AppSpacing.md),

          // English translation
          Text(
            translation,
            style: AppTextStyles.bodyMedium.copyWith(
              height: AppLineHeight.loose,
              color: AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Narrator
          Row(
            children: [
              Container(
                width: 3,
                height: 14,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: AppRadius.pillRadius,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  narrator,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textTertiary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
