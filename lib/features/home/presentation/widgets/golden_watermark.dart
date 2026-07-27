// lib/features/home/presentation/widgets/golden_watermark.dart

import 'package:flutter/material.dart';
import 'package:qibra_ai/core/design_system/app_colors.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';

class GoldenArabicWatermark extends StatelessWidget {
  const GoldenArabicWatermark({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        AppColors.accent.withValues(alpha: 0.30),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Icon(
                  Icons.star_rounded,
                  color: AppColors.accent.withValues(alpha: 0.60),
                  size: 16,
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accent.withValues(alpha: 0.30),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [
                Color(0xFFFFD700),
                Color(0xFFB8960C),
              ],
            ).createShader(bounds),
            child: const Text(
              'جَزَاكَ اللَّه',
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 32,
                color: Colors.white,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'May Allah reward you',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.accent.withValues(alpha: 0.70),
              fontStyle: FontStyle.italic,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'QIBRA AI',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w800,
              letterSpacing: 3.0,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
