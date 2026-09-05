// lib/features/hadith/presentation/hadith_related_section.dart
// ============================================================
// QIBRA AI — "MORE FROM THIS CHAPTER" SECTION (P1 · Item 5)
// ============================================================
// Honest relatedness: real same-chapter siblings from the bundled
// corpus (same collection + same chapter number), capped at 10,
// excluding the hadith being viewed. This is NOT AI similarity —
// the label says exactly what it is. When chapter metadata is
// missing (chapter number 0 / unknown) the section renders nothing:
// UNKNOWN stays unknown, no invented grouping.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/qibra_colors.dart';
import '../data/models/hadith_models.dart';
import '../data/services/hadith_database_service.dart';
import '../providers/hadith_provider.dart';

/// Pure selection used by the UI (unit-tested): same-chapter hadiths,
/// excluding the current one, capped — order preserved from the corpus.
List<LocalHadith> selectMoreFromChapter({
  required List<LocalHadith> chapterHadiths,
  required int currentHadithNumber,
  int cap = 10,
}) {
  if (cap <= 0) return const <LocalHadith>[];
  final out = <LocalHadith>[];
  for (final h in chapterHadiths) {
    if (h.hadithNumber == currentHadithNumber) continue;
    out.add(h);
    if (out.length >= cap) break;
  }
  return out;
}

class HadithMoreFromChapter extends ConsumerWidget {
  const HadithMoreFromChapter({
    super.key,
    required this.hadith,
    required this.onOpen,
  });

  final HadithModel hadith;

  /// Opens a sibling in the same surface the section lives in — the
  /// caller decides (book screen sheet vs home sheet).
  final void Function(BuildContext context, HadithModel target) onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = QibraColors.of(context);
    // Phase B: sibling previews follow the reading language (falls back
    // to English only when this hadith has no key-matched text there).
    final language = ref.watch(hadithLanguageProvider);
    if (hadith.chapterNumber <= 0 || hadith.bookSlug.isEmpty) {
      return const SizedBox.shrink();
    }
    final db = HadithDatabaseService();
    if (!db.isInitialized) return const SizedBox.shrink();
    final related = selectMoreFromChapter(
      chapterHadiths: db.getChapterHadiths(hadith.bookSlug, hadith.chapterNumber),
      currentHadithNumber: hadith.hadithNumber,
    );
    if (related.isEmpty) return const SizedBox.shrink();

    final chapterLabel = hadith.chapterName.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 20),
        Divider(color: colors.border, height: 1),
        const SizedBox(height: 14),
        Text(
          'More from this chapter',
          style: AppTextStyles.labelMedium.copyWith(
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          chapterLabel.isEmpty
              ? 'Same chapter of ${hadith.bookName} — by position, not AI'
              : '${hadith.bookName} · $chapterLabel — by position, not AI',
          style: AppTextStyles.labelSmall.copyWith(
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        for (final local in related)
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => onOpen(context, localToHadithModel(local)),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 4, vertical: 9),
                child: Row(
                  children: [
                    Text(
                      '#${local.hadithNumber}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        (localHadithTextForLanguage(local, language) ??
                                local.textEnglish)
                            .trim()
                            .replaceAll(RegExp(r'\s+'), ' '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        size: 18, color: colors.textTertiary),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
