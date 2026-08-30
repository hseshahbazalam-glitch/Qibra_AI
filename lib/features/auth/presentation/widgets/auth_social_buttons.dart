import 'dart:ui';

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
            color: const Color(0xFF2F6B5D),
            icon: 'G',
            isEnabled: !isLoading && googleAvailable,
            onTap: isLoading || !googleAvailable ? null : onGoogleTap,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _AuthSocialButton(
            label: appleAvailable ? 'Apple' : 'Apple (soon)',
            color: const Color(0xFF19312C),
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
    required this.color,
    this.icon,
    this.iconData,
    this.onTap,
    required this.isEnabled,
  });

  final String label;
  final Color color;
  final String? icon;
  final IconData? iconData;
  final VoidCallback? onTap;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: isEnabled,
      label: isEnabled ? '$label sign in' : '$label is unavailable',
      child: Opacity(
        opacity: isEnabled ? 1 : 0.45,
        child: GestureDetector(
          onTap: onTap,
          child: ClipRRect(
            borderRadius: AppRadius.buttonRadiusLg,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      QibraColors.light.textPrimary.withValues(alpha: 0.08),
                      QibraColors.light.textPrimary.withValues(alpha: 0.03),
                    ],
                  ),
                  borderRadius: AppRadius.buttonRadiusLg,
                  border: Border.all(
                    color: const Color(0xFF19312C).withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null)
                      Container(
                        width: 22,
                        height: 22,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF19312C),
                        ),
                        child: Center(
                          child: Text(
                            icon!,
                            style: TextStyle(
                              color: color,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      )
                    else if (iconData != null)
                      Icon(
                        iconData,
                        color: color,
                        size: 24,
                      ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      label,
                      style: AppTextStyles.buttonMedium.copyWith(
                        color: const Color(0xFF19312C),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
