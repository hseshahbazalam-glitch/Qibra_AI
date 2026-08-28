// lib/features/home/presentation/widgets/error_empty_states.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qibra_ai/core/design_system/qibra_colors.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';

class HomeErrorState extends StatelessWidget {
  final VoidCallback onRetry;
  const HomeErrorState({super.key, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl3),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: colors.error.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: colors.error.withValues(alpha: 0.25), width: 2),
                ),
                child: Icon(Icons.wifi_off_rounded,
                    color: colors.error, size: 40),
              ),
              const SizedBox(height: AppSpacing.xl2),
              Text(
                'Something went wrong',
                style: AppTextStyles.titleLarge
                    .copyWith(fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Please check your connection and try again.',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: colors.textSecondary, height: 1.6),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl3),
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  onRetry();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  decoration: BoxDecoration(
                    gradient: AppGradients.emerald,
                    borderRadius: AppRadius.buttonRadius,
                    boxShadow: AppShadows.emeraldGlow,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.refresh_rounded,
                          color: colors.onPrimary, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Try Again',
                        style: AppTextStyles.labelLarge.copyWith(
                            color: colors.onPrimary,
                            fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomeEmptyState extends StatelessWidget {
  final VoidCallback onGetStarted;
  const HomeEmptyState({super.key, required this.onGetStarted});

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    return SafeArea(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl3),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors.primary.withValues(alpha: 0.15),
                      colors.accent.withValues(alpha: 0.10),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: colors.primary.withValues(alpha: 0.20),
                      width: 2),
                ),
                child: Icon(Icons.mosque_rounded,
                    color: colors.primary, size: 60),
              ),
              const SizedBox(height: AppSpacing.xl2),
              Text(
                'Welcome to QIBRA AI',
                style: AppTextStyles.titleLarge
                    .copyWith(fontWeight: FontWeight.w800),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Your Islamic companion is ready.',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: colors.textSecondary, height: 1.6),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl3),
              GestureDetector(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  onGetStarted();
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  decoration: BoxDecoration(
                    gradient: AppGradients.emerald,
                    borderRadius: AppRadius.buttonRadius,
                    boxShadow: AppShadows.emeraldGlow,
                  ),
                  child: Text(
                    'Get Started',
                    style: AppTextStyles.labelLarge.copyWith(
                        color: colors.onPrimary, fontWeight: FontWeight.w700),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
