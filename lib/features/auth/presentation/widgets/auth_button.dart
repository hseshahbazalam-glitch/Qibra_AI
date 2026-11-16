import 'package:flutter/material.dart';
import 'package:qibra_ai/core/design_system/qibra_colors.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';

class AuthButton extends StatelessWidget {
  const AuthButton({
    super.key,
    required this.label,
    required this.onTap,
    this.isLoading = false,
    this.height = 56,
    this.borderColor,
    this.backgroundColor,
    this.leadingIcon,
    this.trailingIcon,
    this.textColor,
    this.enabled = true,
  });

  final String label;
  final VoidCallback? onTap;
  final bool isLoading;
  final double height;
  final Color? borderColor;
  final Color? backgroundColor;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final Color? textColor;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    final button = GestureDetector(
      onTap: enabled && !isLoading ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: height,
        decoration: BoxDecoration(
          color: backgroundColor ?? colors.primary,
          borderRadius: AppRadius.buttonRadiusLg,
          border: borderColor != null
              ? Border.all(
                  color: borderColor!,
                  width: 1.5,
                )
              : null,
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black87),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (leadingIcon != null) ...[
                      Icon(
                        leadingIcon,
                        color: textColor ?? colors.onPrimary,
                        size: 20,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Text(
                      label,
                      style: AppTextStyles.buttonLarge.copyWith(
                        color: textColor ?? colors.onPrimary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                    if (trailingIcon != null) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Icon(
                        trailingIcon,
                        color: textColor ?? colors.onPrimary,
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

    return accessibleButton;
  }
}
