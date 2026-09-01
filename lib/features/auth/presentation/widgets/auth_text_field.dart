import 'package:flutter/material.dart';
import 'package:qibra_ai/core/design_system/qibra_colors.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.hint,
    required this.validator,
    this.isFocused = false,
    this.enabled = true,
    this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.onSubmitted,
    this.obscureText = false,
    this.suffixIcon,
    this.onSuffixPressed,
    this.style,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final String hint;
  final String? Function(String?) validator;
  final bool isFocused;
  final bool enabled;
  final IconData? prefixIcon;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;
  final bool obscureText;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixPressed;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    return TextFormField(
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        validator: validator,
        enabled: enabled,
        onFieldSubmitted: onSubmitted,
        obscureText: obscureText,
        style: style ??
            AppTextStyles.bodyMedium.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: colors.textTertiary,
          ),
          labelStyle: AppTextStyles.bodyMedium.copyWith(
            color: isFocused ? colors.primary : colors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: prefixIcon == null
              ? null
              : Icon(
                  prefixIcon,
                  color:
                      isFocused ? colors.primary : colors.textSecondary,
                  size: 22,
                ),
          suffixIcon: suffixIcon == null
              ? null
              : IconButton(
                  icon: Icon(
                    suffixIcon,
                    color: colors.textSecondary,
                    size: 20,
                  ),
                  onPressed: onSuffixPressed,
                ),
          filled: true,
          fillColor: colors.cardMuted,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          border: OutlineInputBorder(
            borderRadius: AppRadius.cardRadius,
            borderSide: BorderSide(
              color: colors.border,
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.cardRadius,
            borderSide: BorderSide(
              color: colors.border,
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.cardRadius,
            borderSide: BorderSide(
              color: colors.primary,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: AppRadius.cardRadius,
            borderSide: BorderSide(
              color: colors.error,
              width: 1,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: AppRadius.cardRadius,
            borderSide: BorderSide(
              color: colors.error,
              width: 2,
            ),
          ),
          errorStyle: AppTextStyles.labelSmall.copyWith(
            color: colors.error,
            fontWeight: FontWeight.w600,
          ),
        ),
    );
  }
}
