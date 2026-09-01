// lib/features/tools/screens/nikah_guide_inline.dart
// Renders the Nikah guide inside ToolsHubScreen — the LEAN PASS retired
// the standalone NikahGuideScreen and its route; the data lives in
// logic/nikah_guide_data.dart.
import 'package:flutter/material.dart';

import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/qibra_colors.dart';
import '../../../shared/widgets/qibra_ui.dart';
import '../logic/nikah_guide_data.dart';

class NikahGuideInlineCard extends StatelessWidget {
  const NikahGuideInlineCard({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    return QibraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.favorite_border_rounded,
                  color: colors.accent, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Nikah guide — Marriage in Islam',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final f in nikahQuickFacts)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: colors.primarySoft,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: colors.border),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(f.icon, size: 13, color: colors.accent),
                      const SizedBox(width: 5),
                      Text(
                        '${f.label} · ${f.note}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          for (final s in nikahGuideSections)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              childrenPadding: const EdgeInsets.only(bottom: 4),
              iconColor: colors.accent,
              collapsedIconColor: colors.textTertiary,
              leading: Icon(s.icon, color: colors.accent, size: 20),
              title: Text(
                s.title,
                style: AppTextStyles.titleSmall.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              subtitle: Text(
                s.subtitle,
                style: AppTextStyles.bodySmall.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              children: [
                for (final it in s.items)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 2, 4, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Icon(it.icon, size: 15, color: colors.primary),
                            const SizedBox(width: 7),
                            Expanded(
                              child: Text(
                                it.title,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (it.body.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 5, left: 22),
                            child: Text(
                              it.body,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: colors.textSecondary,
                                height: 1.5,
                              ),
                            ),
                          ),
                        if (it.arabic.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8, left: 22),
                            child: Text(
                              it.arabic,
                              textAlign: TextAlign.right,
                              textDirection: TextDirection.rtl,
                              style: AppArabicStyles.quranSmall.copyWith(
                                color: colors.textPrimary,
                              ),
                            ),
                          ),
                        if (it.transliteration.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, left: 22),
                            child: Text(
                              it.transliteration,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: colors.textTertiary,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
