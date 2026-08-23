// lib/features/bookmarks/presentation/bookmarks_hub_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/qibra_colors.dart';
import '../../../shared/widgets/qibra_ui.dart';
import '../../duas/presentation/dua_detail_screen.dart';
import '../../duas/providers/dua_provider.dart';
import '../../hadith/providers/hadith_provider.dart';
import '../../quran/data/models/quran_models.dart';
import '../../quran/presentation/surah_reader_screen.dart';
import '../../quran/providers/quran_provider.dart';

enum BookmarkSortOption {
  newestFirst('Newest'),
  oldestFirst('Oldest'),
  surahOrder('Surah order'),
  withNotes('With notes');

  const BookmarkSortOption(this.label);
  final String label;
}

class BookmarksHubScreen extends ConsumerStatefulWidget {
  const BookmarksHubScreen({super.key});

  @override
  ConsumerState<BookmarksHubScreen> createState() => _BookmarksHubScreenState();
}

class _BookmarksHubScreenState extends ConsumerState<BookmarksHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    final quran = ref.watch(bookmarksProvider);
    final hadith = ref.watch(hadithBookmarksProvider);
    final duas = ref.watch(favoriteDuasProvider);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.background,
        title: const Text('Bookmarks'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.more);
            }
          },
        ),
        actions: [
          if (_tabs.index == 0 && quran.isNotEmpty)
            IconButton(
              tooltip: 'Clear Quran bookmarks',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: _confirmClearQuran,
            ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: 'Quran (${quran.length})'),
            Tab(text: 'Hadith (${hadith.length})'),
            Tab(text: 'Duas (${duas.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: const [
          _QuranBookmarksTab(),
          _HadithBookmarksTab(),
          _DuaBookmarksTab(),
        ],
      ),
    );
  }

  void _confirmClearQuran() {
    final colors = QibraColors.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.card,
        title: Text(
          'Clear Quran bookmarks?',
          style: AppTextStyles.titleSmall.copyWith(color: colors.textPrimary),
        ),
        content: Text(
          'This removes saved ayahs from this device. Hadith and dua saves stay.',
          style: AppTextStyles.bodySmall.copyWith(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(bookmarksProvider.notifier).clearAll();
              Navigator.pop(dialogContext);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}

class _QuranBookmarksTab extends ConsumerStatefulWidget {
  const _QuranBookmarksTab();

  @override
  ConsumerState<_QuranBookmarksTab> createState() => _QuranBookmarksTabState();
}

class _QuranBookmarksTabState extends ConsumerState<_QuranBookmarksTab> {
  final TextEditingController _search = TextEditingController();
  BookmarkSortOption _sort = BookmarkSortOption.newestFirst;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<BookmarkModel> _visible(List<BookmarkModel> bookmarks) {
    var items = List<BookmarkModel>.from(bookmarks);
    final query = _search.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      items = items.where((bookmark) {
        return bookmark.surahName.toLowerCase().contains(query) ||
            bookmark.ayahText.contains(query) ||
            '${bookmark.surahNumber}:${bookmark.ayahNumber}'.contains(query) ||
            (bookmark.note?.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    switch (_sort) {
      case BookmarkSortOption.newestFirst:
        items.sort((a, b) => b.bookmarkedAt.compareTo(a.bookmarkedAt));
      case BookmarkSortOption.oldestFirst:
        items.sort((a, b) => a.bookmarkedAt.compareTo(b.bookmarkedAt));
      case BookmarkSortOption.surahOrder:
        items.sort((a, b) {
          final surah = a.surahNumber.compareTo(b.surahNumber);
          return surah != 0 ? surah : a.ayahNumber.compareTo(b.ayahNumber);
        });
      case BookmarkSortOption.withNotes:
        items = items
            .where((bookmark) => bookmark.note?.trim().isNotEmpty == true)
            .toList()
          ..sort((a, b) => b.bookmarkedAt.compareTo(a.bookmarkedAt));
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    final items = ref.watch(bookmarksProvider);
    if (items.isEmpty) {
      return const QibraEmptyState(
        icon: Icons.bookmark_border_rounded,
        title: 'No Quran bookmarks',
        message: 'Save an ayah while reading to see it here.',
      );
    }

    final visible = _visible(items);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  style: AppTextStyles.bodySmall
                      .copyWith(color: colors.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search ayah, surah, or note',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () {
                              _search.clear();
                              setState(() {});
                            },
                          ),
                    isDense: true,
                    filled: true,
                    fillColor: colors.card,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: colors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: colors.border),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<BookmarkSortOption>(
                tooltip: 'Sort',
                initialValue: _sort,
                onSelected: (value) => setState(() => _sort = value),
                itemBuilder: (context) => [
                  for (final option in BookmarkSortOption.values)
                    PopupMenuItem(
                      value: option,
                      child: Text(option.label),
                    ),
                ],
                child: Icon(Icons.sort_rounded, color: colors.primary),
              ),
            ],
          ),
        ),
        if (visible.isEmpty)
          const Expanded(
            child: QibraEmptyState(
              icon: Icons.search_off_rounded,
              title: 'No matches',
              message: 'Try a different search or sort.',
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              itemCount: visible.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final item = visible[index];
                final hasNote = item.note?.trim().isNotEmpty == true;
                return QibraCard(
                  onTap: () => _openAyah(item),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${item.surahName} ${item.surahNumber}:${item.ayahNumber}',
                              style: AppTextStyles.labelLarge
                                  .copyWith(color: colors.primary),
                            ),
                          ),
                          Text(
                            item.formattedTime,
                            style: AppTextStyles.labelSmall
                                .copyWith(color: colors.textTertiary),
                          ),
                          PopupMenuButton<String>(
                            onSelected: (value) {
                              switch (value) {
                                case 'copy':
                                  _copy(item);
                                case 'note':
                                  _editNote(item);
                                case 'delete':
                                  _delete(item);
                              }
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(
                                  value: 'copy', child: Text('Copy')),
                              PopupMenuItem(
                                  value: 'note', child: Text('Note')),
                              PopupMenuItem(
                                  value: 'delete', child: Text('Delete')),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        item.ayahText,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        style: AppArabicStyles.quranSmall.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      if (hasNote) ...[
                        const SizedBox(height: 8),
                        Text(
                          item.note!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: colors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  void _openAyah(BookmarkModel bookmark) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SurahReaderScreen(
          surahNumber: bookmark.surahNumber,
          initialAyah: bookmark.ayahNumber,
        ),
      ),
    );
  }

  void _copy(BookmarkModel bookmark) {
    final note = bookmark.note?.trim().isNotEmpty == true
        ? '\n\nNote: ${bookmark.note}'
        : '';
    Clipboard.setData(
      ClipboardData(
        text:
            '${bookmark.ayahText}\n\n— ${bookmark.surahName} (${bookmark.surahNumber}:${bookmark.ayahNumber})$note',
      ),
    );
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied')),
    );
  }

  void _delete(BookmarkModel bookmark) {
    ref.read(bookmarksProvider.notifier).removeBookmark(
          bookmark.surahNumber,
          bookmark.ayahNumber,
        );
  }

  void _editNote(BookmarkModel bookmark) {
    final colors = QibraColors.of(context);
    final controller = TextEditingController(text: bookmark.note ?? '');
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.card,
        title: Text(
          'Note',
          style: AppTextStyles.titleSmall.copyWith(color: colors.textPrimary),
        ),
        content: TextField(
          controller: controller,
          maxLines: 4,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Personal note',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(bookmarksProvider.notifier).updateNote(
                    bookmark.surahNumber,
                    bookmark.ayahNumber,
                    controller.text.trim().isEmpty
                        ? null
                        : controller.text.trim(),
                  );
              Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}

class _HadithBookmarksTab extends ConsumerWidget {
  const _HadithBookmarksTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = QibraColors.of(context);
    final items = ref.watch(hadithBookmarksProvider);
    if (items.isEmpty) {
      return const QibraEmptyState(
        icon: Icons.bookmark_border_rounded,
        title: 'No Hadith bookmarks',
        message: 'Bookmark a hadith to keep it here.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        return QibraCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${item.bookName} #${item.hadithNumber}',
                      style: AppTextStyles.labelLarge.copyWith(
                        color: colors.primary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.textPreview,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline, color: colors.textTertiary),
                onPressed: () {
                  ref
                      .read(hadithBookmarksProvider.notifier)
                      .removeBookmark(item.hadithId);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DuaBookmarksTab extends ConsumerWidget {
  const _DuaBookmarksTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = QibraColors.of(context);
    final items = ref.watch(favoriteDuasProvider);
    if (items.isEmpty) {
      return const QibraEmptyState(
        icon: Icons.favorite_border_rounded,
        title: 'No saved duas',
        message: 'Mark a dua as favorite to see it here.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        return QibraCard(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DuaDetailScreen(duaId: item.id),
              ),
            );
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.titleEnglish,
                style: AppTextStyles.titleSmall.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.arabic,
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppArabicStyles.quranSmall.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
