// lib/features/hadith/presentation/hadith_screen.dart

// ============================================================
// QIBRA AI — HADITH SCREEN
// Version: 1.0.0
// Description: Main hadith screen with daily hadith,
//              books list, search, and bookmarks.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qibra_ai/core/design_system/app_colors.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';

import '../data/models/hadith_models.dart';
import '../providers/hadith_provider.dart';
import 'hadith_book_screen.dart';

// ============================================================
// MAIN SCREEN
// ============================================================

class HadithScreen extends ConsumerStatefulWidget {
  const HadithScreen({super.key});

  @override
  ConsumerState<HadithScreen> createState() => _HadithScreenState();
}

class _HadithScreenState extends ConsumerState<HadithScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            _buildHeader(),
            _buildSearchBar(),
            _buildDailyHadithSection(),
            _buildBooksSectionHeader(),
            _buildBooksList(),
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
    );
  }

  // ─── HEADER ──────────────────────────────────────────────

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: AppGradients.gold,
                    shape: BoxShape.circle,
                    boxShadow: AppShadows.goldGlow,
                  ),
                  child: const Icon(
                    Icons.library_books,
                    color: AppColors.background,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hadith',
                        style: AppTextStyles.headlineSmall,
                      ),
                      Text(
                        'Words of Prophet ﷺ',
                        style: AppTextStyles.bodySmall.secondary,
                      ),
                    ],
                  ),
                ),
                Consumer(
                  builder: (context, ref, _) {
                    final count = ref.watch(bookmarkCountProvider);
                    return Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.bookmark_border),
                          color: AppColors.iconSecondary,
                          onPressed: () {
                            _showBookmarks();
                          },
                        ),
                        if (count > 0)
                          Positioned(
                            right: 6,
                            top: 6,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                '$count',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.background,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── SEARCH BAR ──────────────────────────────────────────

  Widget _buildSearchBar() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: TextField(
            controller: _searchController,
            style: AppTextStyles.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Search hadith...',
              hintStyle: AppTextStyles.bodyMedium.secondary,
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.iconSecondary,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                vertical: AppSpacing.md,
                horizontal: AppSpacing.md,
              ),
            ),
            onSubmitted: (query) {
              if (query.trim().isNotEmpty) {
                _showSearchResults(query);
              }
            },
          ),
        ),
      ),
    );
  }

  // ─── DAILY HADITH SECTION ────────────────────────────────

  Widget _buildDailyHadithSection() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'DAILY HADITH',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Consumer(
              builder: (context, ref, _) {
                final dailyAsync = ref.watch(dailyHadithProvider);
                return dailyAsync.when(
                  data: (hadith) {
                    if (hadith == null) return const _DailyHadithSkeleton();
                    return _DailyHadithCard(hadith: hadith);
                  },
                  loading: () => const _DailyHadithSkeleton(),
                  error: (_, __) => const _DailyHadithSkeleton(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ─── BOOKS SECTION HEADER ────────────────────────────────

  Widget _buildBooksSectionHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'HADITH COLLECTIONS',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── BOOKS LIST ──────────────────────────────────────────

  Widget _buildBooksList() {
    return Consumer(
      builder: (context, ref, _) {
        final booksAsync = ref.watch(hadithBooksProvider);

        return booksAsync.when(
          data: (books) {
            if (books.isEmpty) {
              return const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: Text('No books available'),
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
                    child: _HadithBookCard(
                      book: books[index],
                      onTap: () => _openBook(books[index]),
                    ),
                  ),
                  childCount: books.length,
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
                child: Text(
                  'Error loading books',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── ACTIONS ─────────────────────────────────────────────

  void _openBook(HadithBook book) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HadithBookScreen(book: book),
      ),
    );
  }

  void _showBookmarks() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bookmarks coming soon!'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showSearchResults(String query) {
    ref.read(hadithSearchQueryProvider.notifier).state = query;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Searching: "$query"'),
        duration: const Duration(seconds: 1),
      ),
    );
  }
}

// ============================================================
// DAILY HADITH CARD
// ============================================================

class _DailyHadithCard extends ConsumerWidget {
  final HadithModel hadith;

  const _DailyHadithCard({required this.hadith});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBookmarked = ref.watch(isHadithBookmarkedProvider(hadith.id));

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reference + Grade + Bookmark
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: hadith.grade.color.withValues(alpha: 0.2),
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
                ),
                onPressed: () {
                  ref
                      .read(hadithBookmarksProvider.notifier)
                      .toggleBookmark(hadith);
                },
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined),
                color: AppColors.iconSecondary,
                onPressed: () => _shareHadith(context),
              ),
            ],
          ),

          // Arabic text
          if (hadith.hasArabic) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              hadith.textArabic,
              style: AppArabicStyles.hadithArabic.copyWith(
                height: 2,
              ),
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              height: 1,
              color: AppColors.borderSubtle,
            ),
            const SizedBox(height: AppSpacing.md),
          ],

          // English text
          if (hadith.hasEnglish)
            Text(
              hadith.textEnglish,
              style: AppTextStyles.bodyMedium.copyWith(
                height: 1.6,
              ),
            ),

          const SizedBox(height: AppSpacing.md),

          // Reference
          Row(
            children: [
              const Icon(
                Icons.book_outlined,
                color: AppColors.primary,
                size: 16,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  hadith.displayReference,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

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
                const SizedBox(width: AppSpacing.xs),
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

  void _shareHadith(BuildContext context) {
    final shareText =
        '${hadith.textEnglish}\n\n— ${hadith.displayReference}\nNarrator: ${hadith.narrator.name}';
    Clipboard.setData(ClipboardData(text: shareText));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Hadith copied to clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }
}

// ============================================================
// DAILY HADITH SKELETON (Loading)
// ============================================================

class _DailyHadithSkeleton extends StatelessWidget {
  const _DailyHadithSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.primary,
        ),
      ),
    );
  }
}

// ============================================================
// HADITH BOOK CARD
// ============================================================

class _HadithBookCard extends StatelessWidget {
  final HadithBook book;
  final VoidCallback onTap;

  const _HadithBookCard({
    required this.book,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          children: [
            // Book icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: book.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.menu_book_rounded,
                color: book.color,
                size: 28,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.name,
                    style: AppTextStyles.titleMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (book.nameArabic.isNotEmpty)
                    Text(
                      book.nameArabic,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: book.color,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.article_outlined,
                        color: AppColors.iconSecondary,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${book.totalHadiths} hadiths',
                        style: AppTextStyles.labelSmall.secondary,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      const Icon(
                        Icons.folder_outlined,
                        color: AppColors.iconSecondary,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${book.totalChapters} chapters',
                        style: AppTextStyles.labelSmall.secondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppColors.iconSecondary,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
