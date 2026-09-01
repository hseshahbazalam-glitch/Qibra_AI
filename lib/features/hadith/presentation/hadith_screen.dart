// lib/features/hadith/presentation/hadith_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/design_system/app_design_system.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/qibra_colors.dart';
import '../../../core/design_system/qibra_navy.dart';
import '../../../shared/widgets/media/pattern_backdrop.dart';
import '../../../shared/widgets/media/safe_image.dart';
import '../../../shared/widgets/qibra_status.dart';
import '../../../shared/widgets/qibra_ui.dart';
import '../data/models/hadith_models.dart';
import '../data/services/hadith_database_service.dart';
import '../providers/hadith_provider.dart';
import 'hadith_book_screen.dart';

class HadithScreen extends ConsumerStatefulWidget {
  const HadithScreen({super.key});

  @override
  ConsumerState<HadithScreen> createState() => _HadithScreenState();
}

class _HadithScreenState extends ConsumerState<HadithScreen> {
  String _filterSlug = '';

  static const _collections = [
    {'name': 'Sahih al-Bukhari', 'slug': 'bukhari', 'author': 'Imam al-Bukhari'},
    {'name': 'Sahih Muslim', 'slug': 'muslim', 'author': 'Imam Muslim'},
    {'name': 'Sunan an-Nasa\'i', 'slug': 'nasai', 'author': 'Imam an-Nasa\'i'},
    {'name': 'Sunan Abu Dawud', 'slug': 'abudawud', 'author': 'Imam Abu Dawud'},
    {'name': 'Jami at-Tirmidhi', 'slug': 'tirmidhi', 'author': 'Imam al-Tirmidhi'},
    {'name': 'Sunan Ibn Majah', 'slug': 'ibnmajah', 'author': 'Imam Ibn Majah'},
    {'name': 'Muwatta Malik', 'slug': 'malik', 'author': 'Imam Malik'},
  ];

  /// Subtle per-collection accents (same navy system — not a rainbow).
  static Color collectionAccent(String slug, Color fallback) {
    switch (slug) {
      case 'bukhari':
        return QibraNavy.violet;
      case 'muslim':
        return QibraNavy.blue;
      case 'tirmidhi':
        return QibraNavy.emerald;
      case 'abudawud':
        return QibraNavy.gold;
      case 'nasai':
        return QibraNavy.cyan;
      case 'ibnmajah':
        return QibraNavy.violetDeep;
      case 'malik':
        return QibraNavy.orange;
      default:
        return fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    final daily = ref.watch(dailyHadithProvider);
    final featured = ref.watch(
      featuredHadithsProvider(_filterSlug.isEmpty ? null : _filterSlug),
    );
    final books = ref.watch(hadithBooksProvider);

    return QibraPage(
      title: 'Hadith',
      subtitle: 'The sayings of the Prophet ﷺ',
      actions: [
        QibraIconButton(
          icon: Icons.search_rounded,
          tooltip: 'Search',
          onTap: () => _showSearchSheet(context),
        ),
        QibraIconButton(
          icon: Icons.bookmark_border_rounded,
          tooltip: 'Bookmarks',
          onTap: () => context.go(AppRoutes.bookmarks),
        ),
      ],
      child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            daily.when(
              data: (hadith) => _TodaysHadithCard(
                hadith: hadith,
                onRead: () {
                  if (hadith != null) _showDetail(context, hadith);
                },
                onBookmark: () {
                  if (hadith == null) return;
                  ref.read(hadithBookmarksProvider.notifier).toggleBookmark(hadith);
                },
                onShare: () {
                  if (hadith == null) return;
                  _copyHadith(context, hadith);
                },
              ),
              loading: () => QibraStatus.skeleton(height: 140),
              error: (_, __) => const QibraEmptyState(
                icon: Icons.menu_book_outlined,
                title: 'Today\'s hadith is unavailable',
              ),
            ),
            const SizedBox(height: 24),
            QibraSectionHeader(
              title: 'Collections',
              actionLabel: 'All',
              onAction: () => _showCollectionsSheet(context),
            ),
            books.when(
              data: (bookList) {
                final source = bookList.isEmpty
                    ? _collections
                        .map(
                          (c) => HadithBook(
                            id: c['slug']!,
                            slug: c['slug']!,
                            name: c['name']!,
                            nameArabic: '',
                            author: c['author']!,
                            authorArabic: '',
                            totalHadiths: 0,
                            totalChapters: 0,
                            description: '',
                            color: colors.primary,
                          ),
                        )
                        .toList()
                    : bookList;
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: source.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 1.55,
                  ),
                  itemBuilder: (context, index) {
                    final book = source[index];
                    final author = book.author.isEmpty ? '—' : book.author;
                    final accent = collectionAccent(book.slug, colors.primary);
                    return QibraCard(
                      padding: const EdgeInsets.all(14),
                      onTap: () => _openBook(context, book.slug),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: accent,
                                ),
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  book.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.titleSmall.copyWith(
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            book.totalHadiths > 0
                                ? '${book.totalHadiths} hadiths'
                                : author,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: colors.goldText,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
              loading: () => QibraStatus.skeleton(height: 160),
              error: (_, __) => QibraStatus.error(
                title: 'Collections unavailable',
                message: 'Cached books will appear when they finish loading.',
              ),
            ),
            const SizedBox(height: 20),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  QibraChip(
                    label: 'All',
                    selected: _filterSlug.isEmpty,
                    onTap: () => setState(() => _filterSlug = ''),
                  ),
                  for (final collection in _collections)
                    QibraChip(
                      label: collection['name']!.split(' ').last,
                      selected: _filterSlug == collection['slug'],
                      onTap: () =>
                          setState(() => _filterSlug = collection['slug']!),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            featured.when(
              data: (hadiths) {
                if (hadiths.isEmpty) {
                  return const QibraEmptyState(
                    icon: Icons.library_books_outlined,
                    title: 'No hadiths to show',
                    message: 'Open a collection to start reading.',
                  );
                }
                return Column(
                  children: [
                    for (final hadith in hadiths)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _HadithTile(
                          hadith: hadith,
                          onTap: () => _showDetail(context, hadith),
                        ),
                      ),
                  ],
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (_, __) => const QibraEmptyState(
                icon: Icons.library_books_outlined,
                title: 'Could not load hadiths',
              ),
            ),
          ],
        ),
    );
  }

  void _openBook(BuildContext context, String slug) {
    final db = HadithDatabaseService();
    final info = db.getBookInfo(slug);
    final config = _collections.firstWhere(
      (c) => c['slug'] == slug,
      orElse: () => {'name': 'Hadith Collection', 'author': '—'},
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HadithBookScreen(
          book: HadithBook(
            id: slug,
            slug: slug,
            name: info?.name ?? config['name']!,
            nameArabic: '',
            author: (config['author'] == null || config['author']!.isEmpty)
                ? '—'
                : config['author']!,
            authorArabic: '',
            totalHadiths: info?.totalHadiths ?? 0,
            totalChapters: info?.sections.length ?? 0,
            description: '',
            color: QibraColors.of(context).primary,
          ),
        ),
      ),
    );
  }

  void _copyHadith(BuildContext context, HadithModel hadith) {
    final text =
        '${hadith.textArabic}\n\n${hadith.textEnglish}\n\n— ${hadith.displayReference}';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Hadith copied')),
    );
  }

  void _showDetail(BuildContext context, HadithModel hadith) {
    final colors = QibraColors.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Consumer(
          builder: (context, ref, _) {
            final bookmarked =
                ref.watch(isHadithBookmarkedProvider(hadith.id));
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.82,
              minChildSize: 0.5,
              maxChildSize: 0.95,
              builder: (_, controller) {
                return ListView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            hadith.displayReference,
                            style: AppTextStyles.titleSmall.copyWith(
                              color: colors.primary,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: bookmarked ? 'Remove bookmark' : 'Bookmark',
                          icon: Icon(
                            bookmarked
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            color: colors.primary,
                          ),
                          onPressed: () {
                            ref
                                .read(hadithBookmarksProvider.notifier)
                                .toggleBookmark(hadith);
                          },
                        ),
                        IconButton(
                          tooltip: 'Copy',
                          icon: Icon(Icons.copy_outlined, color: colors.primary),
                          onPressed: () => _copyHadith(context, hadith),
                        ),
                      ],
                    ),
                    if (hadith.grade != HadithGrade.unknown)
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Chip(
                          label: Text(hadith.grade.label),
                          backgroundColor:
                              colors.primary.withValues(alpha: 0.08),
                          side: BorderSide(color: colors.border),
                        ),
                      ),
                    if (hadith.chapterName.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        hadith.chapterName,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                    if (hadith.hasArabic) ...[
                      const SizedBox(height: 16),
                      Text(
                        hadith.textArabic,
                        textAlign: TextAlign.right,
                        style: AppArabicStyles.hadithArabic.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                    if (hadith.hasUrdu) ...[
                      const SizedBox(height: 16),
                      Text(
                        hadith.textUrdu,
                        textAlign: TextAlign.right,
                        textDirection: TextDirection.rtl,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ],
                    if (hadith.hasEnglish) ...[
                      const SizedBox(height: 16),
                      Text(
                        hadith.textEnglish,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: () {
                        Navigator.pop(sheetContext);
                        _openBook(context, hadith.bookSlug);
                      },
                      child: Text('Open ${hadith.bookName}'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _showSearchSheet(BuildContext context) {
    final colors = QibraColors.of(context);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: SizedBox(
            height: MediaQuery.of(sheetContext).size.height * 0.88,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Search hadiths',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                    onChanged: (value) {
                      ref.read(hadithSearchQueryProvider.notifier).state =
                          value;
                    },
                  ),
                ),
                Expanded(
                  child: Consumer(
                    builder: (context, ref, _) {
                      final query = ref.watch(hadithSearchQueryProvider);
                      final results = ref.watch(hadithSearchResultsProvider);
                      if (query.trim().isEmpty) {
                        return const QibraEmptyState(
                          icon: Icons.search_rounded,
                          title: 'Search the collections',
                          message: 'Try words such as prayer, patience, or charity.',
                        );
                      }
                      return results.when(
                        data: (items) {
                          if (items.isEmpty) {
                            return const QibraEmptyState(
                              icon: Icons.search_off_rounded,
                              title: 'No matches',
                            );
                          }
                          return ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: items.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (context, index) {
                              final hadith = items[index].hadith;
                              return _HadithTile(
                                hadith: hadith,
                                onTap: () => _showDetail(context, hadith),
                              );
                            },
                          );
                        },
                        loading: () => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        error: (error, _) => Center(child: Text('$error')),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      ref.read(hadithSearchQueryProvider.notifier).state = '';
    });
  }

  void _showCollectionsSheet(BuildContext context) {
    final colors = QibraColors.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return PatternBackdrop(
          child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 24),
            shrinkWrap: true,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Text(
                  'Collections',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ),
              for (final collection in _collections)
                ListTile(
                  title: Text(collection['name']!),
                  subtitle: Text(collection['author']!),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _openBook(context, collection['slug']!);
                  },
                ),
            ],
          ),
        ),
        );
      },
    );
  }
}

class _TodaysHadithCard extends ConsumerWidget {
  const _TodaysHadithCard({
    required this.hadith,
    required this.onRead,
    required this.onBookmark,
    required this.onShare,
  });

  final HadithModel? hadith;
  final VoidCallback onRead;
  final VoidCallback onBookmark;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = QibraColors.of(context);
    if (hadith == null) {
      return const QibraEmptyState(
        icon: Icons.menu_book_outlined,
        title: 'No hadith for today',
      );
    }
    final bookmarked = ref.watch(isHadithBookmarkedProvider(hadith!.id));
    final lang = ref.watch(hadithLanguageProvider);
    final translation = hadithTextForLanguage(hadith!, lang);
    return QibraCard(
      accentBorder: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(
            height: 88,
            width: double.infinity,
            child: SafeImage(
              assetPath: AppAssets.hadithArt,
              height: 88,
              fit: BoxFit.cover,
              fallback: SafeImageFallback.mosque,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Today\'s hadith',
            style: AppTextStyles.labelMedium.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (hadith!.hasArabic) ...[
            const SizedBox(height: 12),
            Text(
              hadith!.textArabic,
              textAlign: TextAlign.right,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: AppArabicStyles.hadithArabic.copyWith(
                color: colors.textPrimary,
              ),
            ),
          ],
          if (lang != 'ar') ...[
            const SizedBox(height: 10),
            Text(
              translation ??
                  'Verified translation unavailable for this language.',
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMedium.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  hadith!.displayReference,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
              ),
              if (hadith!.grade != HadithGrade.unknown)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: colors.accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                        color: colors.accent.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    hadith!.grade == HadithGrade.sahih
                        ? 'Grade: ${hadith!.grade.label} · collection grade'
                        : 'Grade: ${hadith!.grade.label}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: colors.goldText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              QibraSoftButton(
                icon: Icons.menu_book_outlined,
                label: 'Read',
                onTap: onRead,
              ),
              QibraSoftButton(
                icon: bookmarked
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                label: bookmarked ? 'Saved' : 'Bookmark',
                onTap: onBookmark,
              ),
              QibraSoftButton(
                icon: Icons.ios_share_rounded,
                label: 'Share',
                onTap: onShare,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HadithTile extends ConsumerWidget {
  const _HadithTile({required this.hadith, required this.onTap});

  final HadithModel hadith;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = QibraColors.of(context);
    final bookmarked = ref.watch(isHadithBookmarkedProvider(hadith.id));
    final lang = ref.watch(hadithLanguageProvider);
    final translation = hadithTextForLanguage(hadith, lang);
    return QibraCard(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  hadith.displayReference,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: colors.primary,
                  ),
                ),
              ),
              if (hadith.grade != HadithGrade.unknown)
                Text(
                  hadith.grade.label,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              IconButton(
                icon: Icon(
                  bookmarked
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: bookmarked ? colors.primary : colors.textTertiary,
                ),
                onPressed: () {
                  ref
                      .read(hadithBookmarksProvider.notifier)
                      .toggleBookmark(hadith);
                },
              ),
            ],
          ),
          if (hadith.hasArabic)
            Text(
              hadith.textArabic,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppArabicStyles.quranSmall.copyWith(
                color: colors.textPrimary,
              ),
            ),
          if (hadith.hasEnglish) ...[
            const SizedBox(height: 6),
            Text(
              hadith.textEnglish,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
