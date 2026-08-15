import 'package:flutter/material.dart';
import 'package:qibra_ai/core/design_system/app_colors.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';

class AuthButton extends StatelessWidget {
  const AuthButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isLoading = false,
    this.height = 56,
    this.gradient,
    this.borderColor,
    this.backgroundColor,
    this.leadingIcon,
    this.trailingIcon,
    this.textColor = Colors.white,
    this.pulseAnimation,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final double height;
  final LinearGradient? gradient;
  final Color? borderColor;
  final Color? backgroundColor;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final Color textColor;
  final Animation<double>? pulseAnimation;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      onTap: enabled && !isLoading ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: height,
        decoration: BoxDecoration(
          gradient: gradient ?? AppGradients.emerald,
          color: backgroundColor,
          borderRadius: AppRadius.buttonRadiusLg,
          border: borderColor != null
              ? Border.all(
                  color: borderColor!,
                  width: 1.5,
                )
              : null,
          boxShadow: !isLoading
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.50),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (leadingIcon != null) ...[
                      Icon(
                        leadingIcon,
                        color: textColor,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Text(
                      label,
                      style: AppTextStyles.buttonLarge.copyWith(
                        color: textColor,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                    if (trailingIcon != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Icon(
                        trailingIcon,
                        color: textColor,
                        size: 22,
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );

    final visiblyDisabled = !enabled && !isLoading;
    final accessibleButton = Semantics(
      button: true,
      enabled: enabled && !isLoading,
      child: Opacity(
        opacity: visiblyDisabled ? 0.45 : 1,
        child: button,
      ),
    );

    if (pulseAnimation == null) {
      return accessibleButton;
    }

    return AnimatedBuilder(
      animation: pulseAnimation!,
      builder: (context, child) {
        return Transform.scale(
          scale: isLoading ? 1.0 : pulseAnimation!.value * 0.02 + 0.98,
          child: child,
        );
      },
      child: accessibleButton,
    );
  }
}
