// lib/features/home/presentation/widgets/hadith_card.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qibra_ai/core/constants/app_constants.dart';
import 'package:qibra_ai/core/design_system/qibra_colors.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';
import 'package:qibra_ai/features/hadith/providers/hadith_provider.dart';

class HomeHadithCard extends ConsumerWidget {
  const HomeHadithCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = QibraColors.of(context);
    final dailyHadith = ref.watch(dailyHadithProvider);
    final accent = colors.accent;
    final hadith = dailyHadith.valueOrNull;
    final collection = (hadith?.reference != null && hadith!.reference.isNotEmpty)
        ? hadith.reference
        : '—';
    final hadithBody = hadith?.textEnglish ??
        'Hadith text is unavailable in the bundled collection.';
    final hadithArabic = hadith?.textArabic ?? '';

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.go(AppRoutes.hadith);
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: AppRadius.cardRadiusLarge,
          border: Border.all(color: accent.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.format_quote_rounded, color: accent, size: 14),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    'HADITH OF THE DAY',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: colors.goldText,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (hadithArabic.isNotEmpty) ...[
              Text(
                hadithArabic,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 15,
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
                textDirection: TextDirection.rtl,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
            ],
            Text(
              hadithBody,
              style: AppTextStyles.bodySmall.copyWith(
                color: colors.textSecondary,
                fontSize: 10,
                height: 1.3,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    collection,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 9,
                    ),
                  ),
                ),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.arrow_forward_rounded,
                      color: accent, size: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
