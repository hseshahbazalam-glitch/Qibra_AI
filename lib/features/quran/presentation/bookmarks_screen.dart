// lib/features/quran/presentation/bookmarks_screen.dart

// ============================================================
// QIBRA AI — BOOKMARKS SCREEN (v1.0)
// Phase: 8.5 — Bookmarks Management
// ============================================================

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_design_system.dart';
import '../../../core/design_system/app_typography.dart';
import '../data/models/quran_models.dart';
import '../providers/quran_provider.dart';
import 'surah_reader_screen.dart';

// ============================================================
// SECTION 1 — SORT ENUM
// ============================================================

enum BookmarkSortOption {
  newestFirst('Newest First', Icons.arrow_downward_rounded),
  oldestFirst('Oldest First', Icons.arrow_upward_rounded),
  surahOrder('Surah Order', Icons.format_list_numbered_rounded),
  withNotes('With Notes', Icons.edit_note_rounded);

  const BookmarkSortOption(this.label, this.icon);
  final String label;
  final IconData icon;
}

// ============================================================
// SECTION 2 — MAIN SCREEN
// ============================================================

class BookmarksScreen extends ConsumerStatefulWidget {
  const BookmarksScreen({super.key});

  @override
  ConsumerState<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends ConsumerState<BookmarksScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  String _searchQuery = '';
  BookmarkSortOption _sortOption = BookmarkSortOption.newestFirst;
  final bool _isSearchExpanded = false;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeOutCubic,
      ),
    );

    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(() => setState(() {}));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _animController.forward();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query != _searchQuery) {
      setState(() => _searchQuery = query);
    }
  }

  List<BookmarkModel> _applyFiltersAndSort(List<BookmarkModel> bookmarks) {
    // Filter by search
    var filtered = bookmarks;
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = bookmarks.where((b) {
        return b.surahName.toLowerCase().contains(query) ||
            b.ayahText.contains(query) ||
            b.surahNumber.toString().contains(query) ||
            b.ayahNumber.toString().contains(query) ||
            (b.note?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Sort
    switch (_sortOption) {
      case BookmarkSortOption.newestFirst:
        filtered.sort((a, b) => b.bookmarkedAt.compareTo(a.bookmarkedAt));
        break;
      case BookmarkSortOption.oldestFirst:
        filtered.sort((a, b) => a.bookmarkedAt.compareTo(b.bookmarkedAt));
        break;
      case BookmarkSortOption.surahOrder:
        filtered.sort((a, b) {
          final surahCompare = a.surahNumber.compareTo(b.surahNumber);
          if (surahCompare != 0) return surahCompare;
          return a.ayahNumber.compareTo(b.ayahNumber);
        });
        break;
      case BookmarkSortOption.withNotes:
        filtered = filtered
            .where((b) => b.note != null && b.note!.isNotEmpty)
            .toList();
        filtered.sort((a, b) => b.bookmarkedAt.compareTo(a.bookmarkedAt));
        break;
    }

    return filtered;
  }

  // ── Actions ──────────────────────────────────────────────

  void _openAyah(BookmarkModel bookmark) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SurahReaderScreen(
          surahNumber: bookmark.surahNumber,
          initialAyah: bookmark.ayahNumber,
        ),
      ),
    );
  }

  void _showBookmarkOptions(BookmarkModel bookmark) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _BookmarkOptionsSheet(
        bookmark: bookmark,
        onOpen: () {
          Navigator.of(context).pop();
          _openAyah(bookmark);
        },
        onEditNote: () {
          Navigator.of(context).pop();
          _showEditNoteDialog(bookmark);
        },
        onCopy: () {
          Navigator.of(context).pop();
          _copyBookmark(bookmark);
        },
        onDelete: () {
          Navigator.of(context).pop();
          _deleteBookmark(bookmark);
        },
      ),
    );
  }

  void _copyBookmark(BookmarkModel bookmark) {
    final text = '${bookmark.ayahText}\n\n'
        '— ${bookmark.surahName} '
        '(${bookmark.surahNumber}:${bookmark.ayahNumber})'
        '${bookmark.note != null ? '\n\nNote: ${bookmark.note}' : ''}';
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();

    _showSnackBar(
      icon: Icons.check_circle_rounded,
      message: 'Bookmark copied to clipboard!',
      color: AppColors.primary,
    );
  }

  void _deleteBookmark(BookmarkModel bookmark) {
    HapticFeedback.mediumImpact();
    ref.read(bookmarksProvider.notifier).removeBookmark(
          bookmark.surahNumber,
          bookmark.ayahNumber,
        );

    _showSnackBar(
      icon: Icons.delete_rounded,
      message: 'Bookmark removed',
      color: AppColors.error,
    );
  }

  void _showEditNoteDialog(BookmarkModel bookmark) {
    final controller = TextEditingController(text: bookmark.note ?? '');

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceSheet,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl2),
        ),
        title: Row(
          children: [
            const Icon(Icons.edit_note_rounded, color: AppColors.accent),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Edit Note',
              style: AppTextStyles.titleSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${bookmark.surahName} ${bookmark.surahNumber}:${bookmark.ayahNumber}',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: controller,
              autofocus: true,
              maxLines: 4,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
              cursorColor: AppColors.accent,
              decoration: InputDecoration(
                hintText: 'Write your reflection...',
                hintStyle: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
                filled: true,
                fillColor: AppColors.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: BorderSide(
                    color: AppColors.primary.withValues(alpha: 0.20),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  borderSide: BorderSide(
                    color: AppColors.accent.withValues(alpha: 0.50),
                  ),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(bookmarksProvider.notifier).updateNote(
                    bookmark.surahNumber,
                    bookmark.ayahNumber,
                    controller.text.trim().isEmpty
                        ? null
                        : controller.text.trim(),
                  );
              Navigator.of(dialogContext).pop();
              _showSnackBar(
                icon: Icons.check_rounded,
                message: 'Note saved!',
                color: AppColors.primary,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
            child: Text(
              'Save',
              style: AppTextStyles.labelMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmClearAll() {
    HapticFeedback.mediumImpact();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surfaceSheet,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl2),
        ),
        title: Row(
          children: [
            const Icon(Icons.warning_rounded, color: AppColors.error),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Clear All Bookmarks?',
              style: AppTextStyles.titleSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        content: Text(
          'This will permanently delete all your bookmarks. This action cannot be undone.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              ref.read(bookmarksProvider.notifier).clearAll();
              Navigator.of(dialogContext).pop();
              _showSnackBar(
                icon: Icons.delete_sweep_rounded,
                message: 'All bookmarks cleared',
                color: AppColors.error,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
            ),
            child: Text(
              'Clear All',
              style: AppTextStyles.labelMedium.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSortOptions() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SortOptionsSheet(
        currentOption: _sortOption,
        onSelect: (option) {
          setState(() => _sortOption = option);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showSnackBar({
    required IconData icon,
    required String message,
    required Color color,
  }) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        margin: const EdgeInsets.all(AppSpacing.lg),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final bookmarks = ref.watch(bookmarksProvider);
    final filtered = _applyFiltersAndSort(bookmarks);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.accent.withValues(alpha: 0.06),
              AppColors.background,
              AppColors.background,
            ],
            stops: const [0.0, 0.18, 1.0],
          ),
        ),
        child: SafeArea(
          child: bookmarks.isEmpty
              ? _buildEmptyState()
              : _buildBookmarksList(bookmarks, filtered),
        ),
      ),
    );
  }

  Widget _buildBookmarksList(
    List<BookmarkModel> allBookmarks,
    List<BookmarkModel> filtered,
  ) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Header
        SliverToBoxAdapter(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopBar(allBookmarks.length),
                    const SizedBox(height: AppSpacing.lg),
                    _buildStatsCard(allBookmarks),
                    const SizedBox(height: AppSpacing.lg),
                    _buildSearchBar(),
                    const SizedBox(height: AppSpacing.md),
                    _buildResultBar(
                      total: allBookmarks.length,
                      filtered: filtered.length,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ),
              ),
            ),
          ),
        ),

        // List or empty search state
        if (filtered.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildNoResults(),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.xl3 + AppSpacing.xl3,
            ),
            sliver: SliverList.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final bookmark = filtered[index];
                return _BookmarkCard(
                  bookmark: bookmark,
                  onTap: () => _openAyah(bookmark),
                  onLongPress: () => _showBookmarkOptions(bookmark),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildTopBar(int totalCount) {
    return Row(
      children: [
        _CircleButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).maybePop();
          },
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'MY COLLECTION',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Bookmarks',
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        _CircleButton(
          icon: Icons.sort_rounded,
          onTap: _showSortOptions,
        ),
        const SizedBox(width: AppSpacing.sm),
        if (totalCount > 0)
          _CircleButton(
            icon: Icons.delete_sweep_rounded,
            onTap: _confirmClearAll,
            color: AppColors.error,
          ),
      ],
    );
  }

  Widget _buildStatsCard(List<BookmarkModel> bookmarks) {
    final now = DateTime.now();
    final thisWeek = bookmarks.where((b) {
      return now.difference(b.bookmarkedAt).inDays <= 7;
    }).length;
    final withNotes =
        bookmarks.where((b) => b.note != null && b.note!.isNotEmpty).length;

    // Find favorite surah
    final surahCounts = <String, int>{};
    for (final b in bookmarks) {
      surahCounts[b.surahName] = (surahCounts[b.surahName] ?? 0) + 1;
    }
    String favSurah = 'None';
    int favCount = 0;
    surahCounts.forEach((surah, count) {
      if (count > favCount) {
        favSurah = surah;
        favCount = count;
      }
    });

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent.withValues(alpha: 0.20),
            AppColors.accent.withValues(alpha: 0.10),
            AppColors.primary.withValues(alpha: 0.14),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.22),
          width: 1.1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              _StatItem(
                icon: Icons.bookmark_rounded,
                value: bookmarks.length.toString(),
                label: 'Total',
                color: AppColors.accent,
              ),
              _StatDivider(),
              _StatItem(
                icon: Icons.calendar_today_rounded,
                value: thisWeek.toString(),
                label: 'This Week',
                color: AppColors.primary,
              ),
              _StatDivider(),
              _StatItem(
                icon: Icons.edit_note_rounded,
                value: withNotes.toString(),
                label: 'With Notes',
                color: const Color(0xFF7C4DFF),
              ),
            ],
          ),
          if (favCount > 0) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: AppColors.surface.withValues(alpha: 0.40),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 16,
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Favorite: ',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      favSurah,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    '$favCount ayahs',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final isFocused = _searchFocusNode.hasFocus;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xl2),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(AppRadius.xl2),
            border: Border.all(
              color: isFocused
                  ? AppColors.accent.withValues(alpha: 0.44)
                  : AppColors.primary.withValues(alpha: 0.16),
              width: 1.2,
            ),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            cursorColor: AppColors.accent,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md + 2,
              ),
              border: InputBorder.none,
              prefixIcon: Icon(
                Icons.search_rounded,
                color: AppColors.accent.withValues(alpha: 0.90),
                size: 22,
              ),
              hintText: 'Search bookmarks...',
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w500,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: () {
                        _searchController.clear();
                        _searchFocusNode.unfocus();
                      },
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultBar({required int total, required int filtered}) {
    final isFiltering = _searchQuery.isNotEmpty ||
        _sortOption != BookmarkSortOption.newestFirst;

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Row(
            children: [
              Icon(_sortOption.icon, size: 12, color: AppColors.accent),
              const SizedBox(width: 4),
              Text(
                _sortOption.label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Text(
          isFiltering ? '$filtered of $total bookmarks' : '$total bookmarks',
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopBar(0),
          const Spacer(),
          Center(
            child: Column(
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.accent.withValues(alpha: 0.20),
                        AppColors.accent.withValues(alpha: 0.05),
                      ],
                    ),
                  ),
                  child: Icon(
                    Icons.bookmark_border_rounded,
                    size: 60,
                    color: AppColors.accent.withValues(alpha: 0.80),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'No Bookmarks Yet',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Start bookmarking your favorite ayahs\nto build your personal collection',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                ElevatedButton.icon(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    Navigator.of(context).maybePop();
                  },
                  icon: const Icon(Icons.menu_book_rounded, size: 20),
                  label: Text(
                    'Explore Quran',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.md,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  Widget _buildNoResults() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceElevated,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                size: 40,
                color: AppColors.textTertiary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No matches found',
              style: AppTextStyles.titleSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Try different keywords',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SECTION 3 — BOOKMARK CARD
// ============================================================

class _BookmarkCard extends StatelessWidget {
  const _BookmarkCard({
    required this.bookmark,
    required this.onTap,
    required this.onLongPress,
  });

  final BookmarkModel bookmark;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final hasNote = bookmark.note != null && bookmark.note!.isNotEmpty;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        splashColor: AppColors.accent.withValues(alpha: 0.10),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated.withValues(alpha: 0.90),
            borderRadius: BorderRadius.circular(AppRadius.xl2),
            border: Border.all(
              color: hasNote
                  ? AppColors.accent.withValues(alpha: 0.30)
                  : AppColors.primary.withValues(alpha: 0.12),
              width: hasNote ? 1.2 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
              if (hasNote)
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.60),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppRadius.xl2),
                    topRight: Radius.circular(AppRadius.xl2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.accent.withValues(alpha: 0.90),
                            AppColors.accent.withValues(alpha: 0.60),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.bookmark_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bookmark.surahName,
                            style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            '${bookmark.surahNumber}:${bookmark.ayahNumber}  •  ${bookmark.formattedTime}',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textTertiary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (hasNote)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs + 2,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(AppRadius.full),
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.24),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.edit_note_rounded,
                              size: 12,
                              color: AppColors.accent,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              'Note',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w800,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(width: AppSpacing.xs),
                    const Icon(
                      Icons.chevron_right_rounded,
                      size: 20,
                      color: AppColors.textTertiary,
                    ),
                  ],
                ),
              ),

              // Arabic text
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Text(
                  bookmark.ayahText,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 20,
                    color: AppColors.textPrimary,
                    height: 2.0,
                  ),
                ),
              ),

              // Note preview
              if (hasNote)
                Container(
                  margin: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: const Border(
                      left: BorderSide(
                        color: AppColors.accent,
                        width: 3,
                      ),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.format_quote_rounded,
                        size: 14,
                        color: AppColors.accent.withValues(alpha: 0.70),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          bookmark.note!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                const SizedBox(height: AppSpacing.sm),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SECTION 4 — OPTIONS SHEET
// ============================================================

class _BookmarkOptionsSheet extends StatelessWidget {
  const _BookmarkOptionsSheet({
    required this.bookmark,
    required this.onOpen,
    required this.onEditNote,
    required this.onCopy,
    required this.onDelete,
  });

  final BookmarkModel bookmark;
  final VoidCallback onOpen;
  final VoidCallback onEditNote;
  final VoidCallback onCopy;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.xl2),
      decoration: BoxDecoration(
        color: AppColors.surfaceSheet,
        borderRadius: BorderRadius.circular(AppRadius.xl3),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textTertiary.withValues(alpha: 0.40),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Preview
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated.withValues(alpha: 0.70),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.14),
              ),
            ),
            child: Column(
              children: [
                Text(
                  '${bookmark.surahName} • ${bookmark.surahNumber}:${bookmark.ayahNumber}',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  bookmark.ayahText,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 18,
                    color: AppColors.textPrimary,
                    height: 1.8,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Options
          _OptionTile(
            icon: Icons.menu_book_rounded,
            iconColor: AppColors.primary,
            title: 'Open in Reader',
            subtitle: 'Jump to this ayah',
            onTap: onOpen,
          ),
          _OptionTile(
            icon: Icons.edit_note_rounded,
            iconColor: AppColors.accent,
            title: bookmark.note != null && bookmark.note!.isNotEmpty
                ? 'Edit Note'
                : 'Add Note',
            subtitle: 'Personal reflection',
            onTap: onEditNote,
          ),
          _OptionTile(
            icon: Icons.copy_rounded,
            iconColor: const Color(0xFF1E88E5),
            title: 'Copy',
            subtitle: 'Copy ayah and note',
            onTap: onCopy,
          ),
          _OptionTile(
            icon: Icons.delete_rounded,
            iconColor: AppColors.error,
            title: 'Remove Bookmark',
            subtitle: 'Delete from collection',
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: iconColor.withValues(alpha: 0.20),
                  ),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SECTION 5 — SORT SHEET
// ============================================================

class _SortOptionsSheet extends StatelessWidget {
  const _SortOptionsSheet({
    required this.currentOption,
    required this.onSelect,
  });

  final BookmarkSortOption currentOption;
  final ValueChanged<BookmarkSortOption> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.xl2),
      decoration: BoxDecoration(
        color: AppColors.surfaceSheet,
        borderRadius: BorderRadius.circular(AppRadius.xl3),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 42,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textTertiary.withValues(alpha: 0.40),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              const Icon(Icons.sort_rounded, color: AppColors.accent),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Sort Bookmarks',
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ...BookmarkSortOption.values.map((option) {
            final isSelected = option == currentOption;
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onSelect(option),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  child: Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.accent.withValues(alpha: 0.14)
                          : AppColors.surfaceElevated.withValues(alpha: 0.70),
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.accent.withValues(alpha: 0.40)
                            : AppColors.primary.withValues(alpha: 0.10),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.accent.withValues(alpha: 0.20)
                                : AppColors.surfaceHigh,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            option.icon,
                            color: isSelected
                                ? AppColors.accent
                                : AppColors.textTertiary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Text(
                            option.label,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isSelected
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontWeight: isSelected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.accent,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ============================================================
// SECTION 6 — SMALL WIDGETS
// ============================================================

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 44,
      color: AppColors.primary.withValues(alpha: 0.14),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: (color ?? AppColors.primary).withValues(alpha: 0.14),
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: color ?? AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// END OF FILE — bookmarks_screen.dart
// ============================================================
