// lib/shared/widgets/buttons/app_button.dart

// ============================================================
// QIBRA AI — REUSABLE BUTTON COMPONENTS
// Version: 1.1.0
// Fix: Added missing import for AppUIConstants
//      Added const keywords throughout
//      Fixed all analyzer warnings
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qibra_ai/core/constants/app_constants.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_colors.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';

// ============================================================
// SECTION 1: BUTTON SIZE ENUM
// ============================================================

enum AppButtonSize {
  /// Small — 36px height
  small,

  /// Medium — 48px height
  medium,

  /// Large — 56px height
  large,
}

// ============================================================
// SECTION 2: BUTTON SIZE CONFIG
// ============================================================

class _ButtonSizeConfig {
  final double height;
  final double fontSize;
  final EdgeInsets padding;
  final double iconSize;
  final double borderRadius;

  const _ButtonSizeConfig({
    required this.height,
    required this.fontSize,
    required this.padding,
    required this.iconSize,
    required this.borderRadius,
  });

  static _ButtonSizeConfig fromSize(AppButtonSize size) {
    switch (size) {
      case AppButtonSize.small:
        return const _ButtonSizeConfig(
          height: 36,
          fontSize: 13,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          iconSize: AppIconSizes.sm,
          borderRadius: AppRadius.md,
        );
      case AppButtonSize.medium:
        return const _ButtonSizeConfig(
          height: 48,
          fontSize: 14,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.sm,
          ),
          iconSize: AppIconSizes.md,
          borderRadius: AppRadius.lg,
        );
      case AppButtonSize.large:
        return const _ButtonSizeConfig(
          height: 56,
          fontSize: 16,
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.xl2,
            vertical: AppSpacing.md,
          ),
          iconSize: AppIconSizes.lg,
          borderRadius: AppRadius.lg,
        );
    }
  }
}

// ============================================================
// SECTION 3: APP PRIMARY BUTTON
// ============================================================

class AppPrimaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonSize size;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final bool fullWidth;

  const AppPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.size = AppButtonSize.large,
    this.prefixIcon,
    this.suffixIcon,
    this.fullWidth = true,
  });

  @override
  State<AppPrimaryButton> createState() => _AppPrimaryButtonState();
}

class _AppPrimaryButtonState extends State<AppPrimaryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
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

  void _onTapDown(TapDownDetails details) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onPressed == null || widget.isLoading;
    final config = _ButtonSizeConfig.fromSize(widget.size);

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: isDisabled
          ? null
          : () {
              HapticFeedback.lightImpact();
              widget.onPressed?.call();
            },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          height: config.height,
          width: widget.fullWidth ? double.infinity : null,
          decoration: BoxDecoration(
            gradient: isDisabled
                ? LinearGradient(
                    colors: [
                      AppColors.primary.withValues(alpha: 0.40),
                      AppColors.primaryDark.withValues(alpha: 0.40),
                    ],
                  )
                : AppGradients.emerald,
            borderRadius: BorderRadius.circular(config.borderRadius),
            boxShadow: isDisabled ? null : AppShadows.emeraldGlow,
          ),
          child: Padding(
            padding: config.padding,
            child: _buildContent(config, isDisabled),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(_ButtonSizeConfig config, bool isDisabled) {
    if (widget.isLoading) {
      return Center(
        child: SizedBox(
          width: config.iconSize,
          height: config.iconSize,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColors.white.withValues(alpha: 0.80),
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.prefixIcon != null) ...[
          Icon(
            widget.prefixIcon,
            color: isDisabled
                ? AppColors.white.withValues(alpha: 0.50)
                : AppColors.white,
            size: config.iconSize,
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        Text(
          widget.label,
          style: AppTextStyles.buttonLarge.copyWith(
            fontSize: config.fontSize,
            color: isDisabled
                ? AppColors.white.withValues(alpha: 0.50)
                : AppColors.white,
          ),
        ),
        if (widget.suffixIcon != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Icon(
            widget.suffixIcon,
            color: isDisabled
                ? AppColors.white.withValues(alpha: 0.50)
                : AppColors.white,
            size: config.iconSize,
          ),
        ],
      ],
    );
  }
}

// ============================================================
// SECTION 4: APP SECONDARY BUTTON
// ============================================================

class AppSecondaryButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonSize size;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final bool fullWidth;

  const AppSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.size = AppButtonSize.large,
    this.prefixIcon,
    this.suffixIcon,
    this.fullWidth = true,
  });

  @override
  State<AppSecondaryButton> createState() => _AppSecondaryButtonState();
}

class _AppSecondaryButtonState extends State<AppSecondaryButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
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

  void _onTapDown(TapDownDetails _) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails _) => _controller.reverse();
  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onPressed == null || widget.isLoading;
    final config = _ButtonSizeConfig.fromSize(widget.size);

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: isDisabled
          ? null
          : () {
              HapticFeedback.lightImpact();
              widget.onPressed?.call();
            },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          height: config.height,
          width: widget.fullWidth ? double.infinity : null,
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(config.borderRadius),
            border: Border.all(
              color: isDisabled
                  ? AppColors.primary.withValues(alpha: 0.30)
                  : AppColors.primary,
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: config.padding,
            child: _buildContent(config, isDisabled),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(_ButtonSizeConfig config, bool isDisabled) {
    if (widget.isLoading) {
      return Center(
        child: SizedBox(
          width: config.iconSize,
          height: config.iconSize,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColors.primary.withValues(alpha: 0.80),
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.prefixIcon != null) ...[
          Icon(
            widget.prefixIcon,
            color: isDisabled
                ? AppColors.primary.withValues(alpha: 0.40)
                : AppColors.primary,
            size: config.iconSize,
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        Text(
          widget.label,
          style: AppTextStyles.buttonLarge.copyWith(
            fontSize: config.fontSize,
            color: isDisabled
                ? AppColors.primary.withValues(alpha: 0.40)
                : AppColors.primary,
          ),
        ),
        if (widget.suffixIcon != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Icon(
            widget.suffixIcon,
            color: isDisabled
                ? AppColors.primary.withValues(alpha: 0.40)
                : AppColors.primary,
            size: config.iconSize,
          ),
        ],
      ],
    );
  }
}

// ============================================================
// SECTION 5: APP GOLD BUTTON
// ============================================================

class AppGoldButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final AppButtonSize size;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final bool fullWidth;

  const AppGoldButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.size = AppButtonSize.large,
    this.prefixIcon,
    this.suffixIcon,
    this.fullWidth = true,
  });

  @override
  State<AppGoldButton> createState() => _AppGoldButtonState();
}

class _AppGoldButtonState extends State<AppGoldButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
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

  void _onTapDown(TapDownDetails _) {
    if (widget.onPressed != null && !widget.isLoading) {
      _controller.forward();
    }
  }

  void _onTapUp(TapUpDetails _) => _controller.reverse();
  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = widget.onPressed == null || widget.isLoading;
    final config = _ButtonSizeConfig.fromSize(widget.size);

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: isDisabled
          ? null
          : () {
              HapticFeedback.lightImpact();
              widget.onPressed?.call();
            },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          height: config.height,
          width: widget.fullWidth ? double.infinity : null,
          decoration: BoxDecoration(
            gradient: isDisabled
                ? LinearGradient(
                    colors: [
                      AppColors.accent.withValues(alpha: 0.40),
                      AppColors.accentDark.withValues(alpha: 0.40),
                    ],
                  )
                : AppGradients.gold,
            borderRadius: BorderRadius.circular(config.borderRadius),
            boxShadow: isDisabled ? null : AppShadows.goldGlow,
          ),
          child: Padding(
            padding: config.padding,
            child: _buildContent(config, isDisabled),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(_ButtonSizeConfig config, bool isDisabled) {
    if (widget.isLoading) {
      return Center(
        child: SizedBox(
          width: config.iconSize,
          height: config.iconSize,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColors.textOnGold.withValues(alpha: 0.80),
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: widget.fullWidth ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.prefixIcon != null) ...[
          Icon(
            widget.prefixIcon,
            color: isDisabled
                ? AppColors.textOnGold.withValues(alpha: 0.50)
                : AppColors.textOnGold,
            size: config.iconSize,
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        Text(
          widget.label,
          style: AppTextStyles.buttonLarge.copyWith(
            fontSize: config.fontSize,
            color: isDisabled
                ? AppColors.textOnGold.withValues(alpha: 0.50)
                : AppColors.textOnGold,
          ),
        ),
        if (widget.suffixIcon != null) ...[
          const SizedBox(width: AppSpacing.sm),
          Icon(
            widget.suffixIcon,
            color: isDisabled
                ? AppColors.textOnGold.withValues(alpha: 0.50)
                : AppColors.textOnGold,
            size: config.iconSize,
          ),
        ],
      ],
    );
  }
}

// ============================================================
// SECTION 6: APP TEXT BUTTON
// ============================================================

class AppTextBtn extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonSize size;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final bool isGold;

  const AppTextBtn({
    super.key,
    required this.label,
    this.onPressed,
    this.size = AppButtonSize.medium,
    this.prefixIcon,
    this.suffixIcon,
    this.isGold = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDisabled = onPressed == null;
    final config = _ButtonSizeConfig.fromSize(size);

    final Color textColor = isDisabled
        ? AppColors.textTertiary
        : isGold
            ? AppColors.accent
            : AppColors.primary;

    return GestureDetector(
      onTap: isDisabled
          ? null
          : () {
              HapticFeedback.selectionClick();
              onPressed?.call();
            },
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (prefixIcon != null) ...[
              Icon(prefixIcon, color: textColor, size: config.iconSize),
              const SizedBox(width: AppSpacing.xs),
            ],
            Text(
              label,
              style: AppTextStyles.buttonMedium.copyWith(
                fontSize: config.fontSize,
                color: textColor,
              ),
            ),
            if (suffixIcon != null) ...[
              const SizedBox(width: AppSpacing.xs),
              Icon(suffixIcon, color: textColor, size: config.iconSize),
            ],
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SECTION 7: APP ICON BUTTON
// ============================================================

class AppIconBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double? size;
  final Color? iconColor;
  final Color? backgroundColor;
  final int? badgeCount;
  final bool isOutlined;
  final bool isFilled;

  const AppIconBtn({
    super.key,
    required this.icon,
    this.onPressed,
    this.size,
    this.iconColor,
    this.backgroundColor,
    this.badgeCount,
    this.isOutlined = false,
    this.isFilled = false,
  });

  @override
  State<AppIconBtn> createState() => _AppIconBtnState();
}

class _AppIconBtnState extends State<AppIconBtn>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.88,
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
    final double btnSize = widget.size ?? AppUIConstants.tapTargetSize;
    final bool isDisabled = widget.onPressed == null;

    Color bgColor;
    if (widget.backgroundColor != null) {
      bgColor = widget.backgroundColor!;
    } else if (widget.isFilled) {
      bgColor = AppColors.primary;
    } else if (widget.isOutlined) {
      bgColor = Colors.transparent;
    } else {
      bgColor = AppColors.surfaceElevated;
    }

    Color iconClr;
    if (widget.iconColor != null) {
      iconClr = widget.iconColor!;
    } else if (widget.isFilled) {
      iconClr = AppColors.white;
    } else {
      iconClr = isDisabled
          ? AppColors.iconSecondary.withValues(alpha: 0.40)
          : AppColors.iconPrimary;
    }

    return GestureDetector(
      onTapDown: (_) {
        if (!isDisabled) _controller.forward();
      },
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: isDisabled
          ? null
          : () {
              HapticFeedback.lightImpact();
              widget.onPressed?.call();
            },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: btnSize,
              height: btnSize,
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
                border: widget.isOutlined
                    ? Border.all(
                        color: AppColors.borderStandard,
                        width: 1.5,
                      )
                    : null,
                boxShadow: widget.isFilled ? AppShadows.emeraldGlow : null,
              ),
              child: Icon(
                widget.icon,
                color: iconClr,
                size: btnSize * 0.45,
              ),
            ),
            if (widget.badgeCount != null && widget.badgeCount! > 0)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: AppColors.error,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    widget.badgeCount! > 99 ? '99+' : '${widget.badgeCount}',
                    style: AppTextStyles.badge.copyWith(fontSize: 9),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SECTION 8: APP SOCIAL BUTTON
// ============================================================

enum SocialButtonType { google, apple }

class AppSocialButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final SocialButtonType type;

  const AppSocialButton({
    super.key,
    required this.label,
    required this.type,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  State<AppSocialButton> createState() => _AppSocialButtonState();
}

class _AppSocialButtonState extends State<AppSocialButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
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
    final bool isDisabled = widget.onPressed == null || widget.isLoading;

    return GestureDetector(
      onTapDown: (_) {
        if (!isDisabled) _controller.forward();
      },
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: isDisabled
          ? null
          : () {
              HapticFeedback.lightImpact();
              widget.onPressed?.call();
            },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: AppDurations.fast,
          height: 52,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDisabled
                ? AppColors.surfaceElevated.withValues(alpha: 0.50)
                : AppColors.surfaceElevated,
            borderRadius: AppRadius.cardRadius,
            border: Border.all(
              color: AppColors.borderStandard,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
            ),
            child: _buildContent(isDisabled),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(bool isDisabled) {
    if (widget.isLoading) {
      return const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSocialIcon(),
        const SizedBox(width: AppSpacing.md),
        Text(
          widget.label,
          style: AppTextStyles.buttonMedium.copyWith(
            color: isDisabled ? AppColors.textTertiary : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildSocialIcon() {
    switch (widget.type) {
      case SocialButtonType.google:
        return Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
          ),
          child: const Center(
            child: Text(
              'G',
              style: TextStyle(
                color: Color(0xFF4285F4),
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      case SocialButtonType.apple:
        return const Icon(
          Icons.apple,
          color: AppColors.white,
          size: 22,
        );
    }
  }
}

// ============================================================
// SECTION 9: APP LOADING BUTTON
// ============================================================

class AppLoadingButton extends StatefulWidget {
  final String label;
  final String? loadingLabel;
  final Future<void> Function()? onPressed;
  final AppButtonSize size;
  final bool isGold;
  final bool fullWidth;
  final IconData? prefixIcon;

  const AppLoadingButton({
    super.key,
    required this.label,
    this.loadingLabel,
    this.onPressed,
    this.size = AppButtonSize.large,
    this.isGold = false,
    this.fullWidth = true,
    this.prefixIcon,
  });

  @override
  State<AppLoadingButton> createState() => _AppLoadingButtonState();
}

class _AppLoadingButtonState extends State<AppLoadingButton> {
  bool _isLoading = false;

  Future<void> _handlePress() async {
    if (_isLoading || widget.onPressed == null) return;
    setState(() => _isLoading = true);
    try {
      await widget.onPressed!();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isGold) {
      return AppGoldButton(
        label:
            _isLoading ? (widget.loadingLabel ?? widget.label) : widget.label,
        onPressed: _isLoading ? null : _handlePress,
        isLoading: _isLoading,
        size: widget.size,
        fullWidth: widget.fullWidth,
        prefixIcon: widget.prefixIcon,
      );
    }

    return AppPrimaryButton(
      label: _isLoading ? (widget.loadingLabel ?? widget.label) : widget.label,
      onPressed: _isLoading ? null : _handlePress,
      isLoading: _isLoading,
      size: widget.size,
      fullWidth: widget.fullWidth,
      prefixIcon: widget.prefixIcon,
    );
  }
}
