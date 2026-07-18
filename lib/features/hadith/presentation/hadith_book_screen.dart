// lib/features/hadith/presentation/hadith_book_screen.dart

// ============================================================
// QIBRA AI — HADITH BOOK DETAIL SCREEN
// Version: 1.0.0
// Description: Shows all hadiths from a specific book.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qibra_ai/core/design_system/app_colors.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';

import '../data/models/hadith_models.dart';
import '../providers/hadith_provider.dart';

// ============================================================
// MAIN SCREEN
// ============================================================

class HadithBookScreen extends ConsumerWidget {
  final HadithBook book;

  const HadithBookScreen({super.key, required this.book});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = HadithsParams(bookSlug: book.slug);
    final hadithsAsync = ref.watch(hadithsProvider(params));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildAppBar(context),
            _buildBookHeader(),
            hadithsAsync.when(
              data: (hadiths) {
                if (hadiths.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.xl2),
                        child: Text('No hadiths available'),
                      ),
                    ),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _HadithCard(hadith: hadiths[index]),
                      ),
                      childCount: hadiths.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xl2),
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
              error: (error, _) => SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: AppColors.error,
                          size: 48,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          'Failed to load hadiths',
                          style: AppTextStyles.bodyLarge,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          error.toString(),
                          style: AppTextStyles.bodySmall.secondary,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  // ─── APP BAR ─────────────────────────────────────────────

  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: AppColors.background,
      pinned: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        color: AppColors.iconPrimary,
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        book.name,
        style: AppTextStyles.titleLarge.copyWith(
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  // ─── BOOK HEADER ─────────────────────────────────────────

  Widget _buildBookHeader() {
    return SliverToBoxAdapter(
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.lg),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              book.color.withValues(alpha: 0.2),
              book.color.withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: book.color.withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: book.color.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    Icons.menu_book_rounded,
                    color: book.color,
                    size: 32,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        book.name,
                        style: AppTextStyles.titleLarge.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (book.nameArabic.isNotEmpty)
                        Text(
                          book.nameArabic,
                          style: AppArabicStyles.hadithArabic.copyWith(
                            color: book.color,
                            fontSize: 18,
                          ),
                          textDirection: TextDirection.rtl,
                        ),
                    ],
                  ),
                ),
              ],
            ),
            if (book.description.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text(
                book.description,
                style: AppTextStyles.bodySmall.copyWith(
                  height: 1.5,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                _StatChip(
                  icon: Icons.article_outlined,
                  label: '${book.totalHadiths}',
                  sublabel: 'Hadiths',
                  color: book.color,
                ),
                const SizedBox(width: AppSpacing.sm),
                _StatChip(
                  icon: Icons.folder_outlined,
                  label: '${book.totalChapters}',
                  sublabel: 'Chapters',
                  color: book.color,
                ),
                if (book.author.isNotEmpty) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: _StatChip(
                      icon: Icons.person_outline,
                      label: book.author,
                      sublabel: 'Author',
                      color: book.color,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// STAT CHIP
// ============================================================

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              Text(
                sublabel,
                style: AppTextStyles.labelSmall.copyWith(
                  fontSize: 9,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// HADITH CARD
// ============================================================

class _HadithCard extends ConsumerWidget {
  final HadithModel hadith;

  const _HadithCard({required this.hadith});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBookmarked = ref.watch(isHadithBookmarkedProvider(hadith.id));

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Number + Grade + Bookmark
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '#${hadith.hadithNumber}',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: hadith.grade.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hadith.grade.icon,
                      color: hadith.grade.color,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      hadith.grade.label,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: hadith.grade.color,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(
                  isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                  color: isBookmarked
                      ? AppColors.primary
                      : AppColors.iconSecondary,
                  size: 20,
                ),
                onPressed: () {
                  ref
                      .read(hadithBookmarksProvider.notifier)
                      .toggleBookmark(hadith);
                },
              ),
              IconButton(
                icon: const Icon(
                  Icons.share_outlined,
                  size: 20,
                ),
                color: AppColors.iconSecondary,
                onPressed: () => _share(context),
              ),
            ],
          ),

          // Arabic
          if (hadith.hasArabic) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              hadith.textArabic,
              style: AppArabicStyles.hadithArabic,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
          ],

          // Divider
          if (hadith.hasArabic && hadith.hasEnglish) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              height: 1,
              color: AppColors.borderSubtle,
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // English
          if (hadith.hasEnglish)
            SelectableText(
              hadith.textEnglish,
              style: AppTextStyles.bodyMedium.copyWith(
                height: 1.6,
              ),
            ),

          // Chapter
          if (hadith.chapterName.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                const Icon(
                  Icons.folder_outlined,
                  color: AppColors.iconSecondary,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Chapter: ${hadith.chapterName}',
                    style: AppTextStyles.labelSmall.secondary,
                  ),
                ),
              ],
            ),
          ],

          // Narrator
          if (hadith.narrator.name.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.person_outline,
                  color: AppColors.iconSecondary,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Narrator: ${hadith.narrator.displayName}',
                    style: AppTextStyles.labelSmall.secondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  void _share(BuildContext context) {
    final shareText =
        '${hadith.textEnglish}\n\n— ${hadith.displayReference}\nGrade: ${hadith.grade.label}\nNarrator: ${hadith.narrator.name}';
    Clipboard.setData(ClipboardData(text: shareText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hadith copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}
