// lib/features/home/presentation/widgets/hadith_card.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:qibra_ai/core/constants/app_constants.dart';
import 'package:qibra_ai/core/design_system/app_colors.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';

class HomeHadithCard extends StatelessWidget {
  const HomeHadithCard({super.key});

  @override
  Widget build(BuildContext context) {
    const String narrator = 'Abu Hurairah (RA)';
    const String collection = 'Sahih al-Bukhari · 6477';
    const String hadithBody =
        'The Prophet \uFDFA said: "Whoever believes in Allah and the Last Day should speak a good word or remain silent."';
    const String hadithArabic =
        '\u0645\u064E\u0646\u0652 \u0643\u064E\u0627\u0646\u064E \u064A\u0624\u0652\u0645\u0650\u0646\u064F \u0628\u0650\u0627\u0644\u0644\u0651\u064E\u0647\u0650 \u0648\u064E\u0627\u0644\u0652\u064A\u064E\u0648\u0652\u0645\u0650 \u0627\u0644\u0622\u062E\u0650\u0631\u0650 \u0641\u064E\u0644\u0652\u064A\u064E\u0642\u064F\u0644\u0652 \u062E\u064E\u064A\u0652\u0631\u064B\u0627 \u0623\u064E\u0648\u0652 \u0644\u0650\u064A\u064E\u0635\u0652\u0645\u064F\u062A\u0652';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          context.go(AppRoutes.hadith);
        },
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.cardRadiusLarge,
            border: Border.all(
              color: const Color(0xFFB45309).withValues(alpha: 0.20),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 3,
                          height: 14,
                          decoration: BoxDecoration(
                            color: const Color(0xFFB45309),
                            borderRadius: AppRadius.pillRadius,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'HADITH',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: const Color(0xFFB45309),
                            letterSpacing: 2.0,
                            fontWeight: FontWeight.w700,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      collection,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: const Color(0xFFB45309),
                        fontWeight: FontWeight.w700,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                const Text(
                  hadithArabic,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 18,
                    color: AppColors.textPrimary,
                    height: 2.0,
                    fontWeight: FontWeight.w600,
                  ),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  hadithBody,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.7,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      narrator,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'Read more',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: const Color(0xFFB45309),
                            fontWeight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 3),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Color(0xFFB45309),
                          size: 10,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
