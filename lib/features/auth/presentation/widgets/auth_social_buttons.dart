import 'package:flutter/material.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';
import 'package:qibra_ai/core/design_system/qibra_colors.dart';

class AuthSocialButtons extends StatelessWidget {
  const AuthSocialButtons({
    super.key,
    required this.onGoogleTap,
    required this.onAppleTap,
    this.isLoading = false,
    this.googleAvailable = true,
    this.appleAvailable = true,
  });

  final VoidCallback? onGoogleTap;
  final VoidCallback? onAppleTap;
  final bool isLoading;
  final bool googleAvailable;
  final bool appleAvailable;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _AuthSocialButton(
            label: googleAvailable ? 'Google' : 'Google (soon)',
            icon: 'G',
            isEnabled: !isLoading && googleAvailable,
            onTap: isLoading || !googleAvailable ? null : onGoogleTap,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _AuthSocialButton(
            label: appleAvailable ? 'Apple' : 'Apple (soon)',
            iconData: Icons.apple,
            isEnabled: !isLoading && appleAvailable,
            onTap: isLoading || !appleAvailable ? null : onAppleTap,
          ),
        ),
      ],
    );
  }
}

class _AuthSocialButton extends StatelessWidget {
  const _AuthSocialButton({
    required this.label,
    this.icon,
    this.iconData,
    this.onTap,
    required this.isEnabled,
  });

  final String label;
  final String? icon;
  final IconData? iconData;
  final VoidCallback? onTap;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    return Semantics(
      button: true,
      enabled: isEnabled,
      label: isEnabled ? '$label sign in' : '$label is unavailable',
      child: Opacity(
        opacity: isEnabled ? 1 : 0.45,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: AppRadius.buttonRadiusLg,
              border: Border.all(color: colors.border, width: 1),
            ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null)
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.cardMuted,
                        ),
                        child: Center(
                          child: Text(
                            icon!,
                            style: TextStyle(
                              color: colors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      )
                    else if (iconData != null)
                      Icon(
                        iconData,
                        color: colors.textSecondary,
                        size: 24,
                      ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      label,
                      style: AppTextStyles.buttonMedium.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
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
