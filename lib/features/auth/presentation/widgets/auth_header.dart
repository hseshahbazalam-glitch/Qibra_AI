import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:qibra_ai/core/design_system/qibra_colors.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';

class AuthHeader extends StatelessWidget {
  const AuthHeader({
    super.key,
    required this.onBackTap,
    this.stepNumber,
    this.totalSteps,
    this.stepLabel,
    this.stepGradient,
  });

  final VoidCallback onBackTap;
  final int? stepNumber;
  final int? totalSteps;
  final String? stepLabel;
  final LinearGradient? stepGradient;

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    return Row(
      mainAxisAlignment: _shouldShowStepBadge
          ? MainAxisAlignment.spaceBetween
          : MainAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: onBackTap,
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.textPrimary.withValues(alpha: 0.10),
                  border: Border.all(
                    color: colors.textPrimary.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: colors.textPrimary,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
        if (_shouldShowStepBadge)
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: colors.textPrimary.withValues(alpha: 0.10),
              borderRadius: AppRadius.pillRadius,
              border: Border.all(
                color: colors.textPrimary.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ShaderMask(
                  shaderCallback: (bounds) =>
                      (stepGradient ?? AppGradients.gold).createShader(bounds),
                  child: Text(
                    '$stepNumber',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  totalSteps == null ? '' : ' / $totalSteps',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                if (stepLabel != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    '· $stepLabel',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }

  bool get _shouldShowStepBadge =>
      stepNumber != null || totalSteps != null || stepLabel != null;
}
