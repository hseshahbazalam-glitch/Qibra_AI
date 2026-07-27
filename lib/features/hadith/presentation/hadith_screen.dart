// lib/features/hadith/presentation/hadith_screen.dart

// ============================================================
// QIBRA AI — HADITH SCREEN (v2.1 - Fixed with Correct Fields)
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

class HadithScreen extends ConsumerStatefulWidget {
  const HadithScreen({super.key});

  @override
  ConsumerState<HadithScreen> createState() => _HadithScreenState();
}

class _HadithScreenState extends ConsumerState<HadithScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

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
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildHeader(),
            _buildSearchBar(),
            if (_isSearching)
              _buildSearchResults()
            else ...[
              _buildDailyHadithSection(),
              _buildBooksSectionHeader(),
              _buildBooksList(),
            ],
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: Row(
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
                  Text('Hadith', style: AppTextStyles.headlineSmall),
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
                      icon: Icon(
                        count > 0
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        color: count > 0
                            ? AppColors.primary
                            : AppColors.iconSecondary,
                      ),
                      onPressed: _showBookmarks,
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
      ),
    );
  }

  // ============================================================
  // SEARCH BAR
  // ============================================================

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
            border: Border.all(
              color: _isSearching ? AppColors.primary : AppColors.borderSubtle,
              width: _isSearching ? 1.5 : 1,
            ),
          ),
          child: TextField(
            controller: _searchController,
            style: AppTextStyles.bodyMedium,
            onChanged: (value) {
              setState(() {
                _isSearching = value.trim().isNotEmpty;
              });
              ref.read(hadithSearchQueryProvider.notifier).state = value;
            },
            decoration: InputDecoration(
              hintText: 'Search 34,000+ hadiths...',
              hintStyle: AppTextStyles.bodyMedium.secondary,
              prefixIcon: const Icon(
                Icons.search,
                color: AppColors.iconSecondary,
              ),
              suffixIcon: _isSearching
                  ? IconButton(
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.iconSecondary,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _isSearching = false);
                        ref.read(hadithSearchQueryProvider.notifier).state = '';
                        HapticFeedback.lightImpact();
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                vertical: AppSpacing.md,
                horizontal: AppSpacing.md,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SEARCH RESULTS
  // ============================================================

  Widget _buildSearchResults() {
    return Consumer(
      builder: (context, ref, _) {
        final query = _searchController.text;

        if (query.trim().isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox());
        }

        final booksAsync = ref.watch(hadithBooksProvider);

        return booksAsync.when(
          data: (books) {
            return SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  const SizedBox(height: 8),
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
                        'SEARCH RESULTS',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Tap any book below to search inside it',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ...books.map((book) => Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _HadithBookCard(
                          book: book,
                          searchQuery: query,
                          onTap: () => _openBook(book),
                        ),
                      )),
                ]),
              ),
            );
          },
          loading: () => const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xl2),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
          ),
          error: (_, __) => const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.xl),
                child: Text('Error loading'),
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // DAILY HADITH
  // ============================================================

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

  // ============================================================
  // BOOKS SECTION
  // ============================================================

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
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
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
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
          ),
          error: (_, __) => SliverToBoxAdapter(
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

  // ============================================================
  // ACTIONS
  // ============================================================

  void _openBook(HadithBook book) {
    HapticFeedback.selectionClick();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => HadithBookScreen(book: book),
      ),
    );
  }

  void _showBookmarks() {
    HapticFeedback.mediumImpact();
    final bookmarks = ref.read(hadithBookmarksProvider);

    if (bookmarks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.bookmark_border, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text('No bookmarks yet. Save hadiths to see them here!'),
            ],
          ),
          duration: Duration(seconds: 2),
          backgroundColor: AppColors.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A2438),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.bookmark_rounded,
                        color: AppColors.primary, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'My Bookmarks',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${bookmarks.length} saved',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white12, height: 1),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  padding: const EdgeInsets.all(16),
                  itemCount: bookmarks.length,
                  itemBuilder: (context, index) {
                    final bookmark = bookmarks[index];
                    return _BookmarkTile(
                      bookmark: bookmark,
                      onRemove: () {
                        ref
                            .read(hadithBookmarksProvider.notifier)
                            .removeBookmark(bookmark.id);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
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
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                    Icon(hadith.grade.icon,
                        color: hadith.grade.color, size: 12),
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
                  isBookmarked
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: isBookmarked
                      ? AppColors.primary
                      : AppColors.iconSecondary,
                ),
                onPressed: () {
                  HapticFeedback.selectionClick();
                  ref
                      .read(hadithBookmarksProvider.notifier)
                      .toggleBookmark(hadith);
                },
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined),
                color: AppColors.iconSecondary,
                onPressed: () => _shareHadith(context, hadith),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (hadith.textArabic.isNotEmpty) ...[
            Text(
              hadith.textArabic,
              style: AppTextStyles.headlineSmall.copyWith(
                fontFamily: 'Amiri',
                height: 1.8,
                color: AppColors.textPrimary,
              ),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          Text(
            '"${hadith.textEnglish}"',
            style: AppTextStyles.bodyMedium.copyWith(
              fontStyle: FontStyle.italic,
              height: 1.6,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.book_outlined,
                    color: AppColors.primary, size: 14),
                const SizedBox(width: 4),
                Text(
                  hadith.displayReference,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _shareHadith(BuildContext context, HadithModel hadith) {
    final text = '''📖 Hadith

${hadith.textArabic}

"${hadith.textEnglish}"

📚 ${hadith.displayReference} - ${hadith.grade.label}

Shared via Qibra AI''';

    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.mediumImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text('📋 Hadith copied - paste to share'),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }
}

// ============================================================
// DAILY HADITH SKELETON
// ============================================================

class _DailyHadithSkeleton extends StatelessWidget {
  const _DailyHadithSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: const Center(
        child: Padding(
          padding: EdgeInsets.all(AppSpacing.xl),
          child: CircularProgressIndicator(color: AppColors.primary),
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
  final String? searchQuery;

  const _HadithBookCard({
    required this.book,
    required this.onTap,
    this.searchQuery,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: searchQuery != null
                  ? AppColors.primary.withValues(alpha: 0.5)
                  : AppColors.borderSubtle,
              width: searchQuery != null ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: AppGradients.emerald,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.library_books,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.name,
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      book.nameArabic,
                      style: const TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 14,
                        color: AppColors.textSecondary,
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${book.totalHadiths} hadiths',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                searchQuery != null
                    ? Icons.search_rounded
                    : Icons.arrow_forward_ios_rounded,
                color: AppColors.iconSecondary,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// BOOKMARK TILE
// ============================================================

class _BookmarkTile extends StatelessWidget {
  final HadithBookmark bookmark;
  final VoidCallback onRemove;

  const _BookmarkTile({required this.bookmark, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '#${bookmark.hadithNumber}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.red,
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            bookmark.textPreview,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
              height: 1.5,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.book_outlined,
                color: AppColors.primary,
                size: 12,
              ),
              const SizedBox(width: 4),
              Text(
                bookmark.bookName,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                bookmark.formattedDate,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
