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
import '../../../core/utils/search_normalizer.dart';
import '../../../shared/widgets/buttons/app_button.dart';
import '../../../shared/widgets/media/pattern_backdrop.dart';
import '../../../shared/widgets/qibra_status.dart';
import '../../../shared/widgets/qibra_ui.dart';
import '../data/models/hadith_models.dart';
import '../data/services/hadith_database_service.dart';
import '../data/services/hadith_view_history.dart';
import '../providers/hadith_provider.dart';
import '../providers/hadith_preferences_provider.dart';
import 'hadith_book_screen.dart';
import 'hadith_related_section.dart';

class HadithScreen extends ConsumerStatefulWidget {
  const HadithScreen({super.key});

  @override
  ConsumerState<HadithScreen> createState() => _HadithScreenState();
}

class _HadithScreenState extends ConsumerState<HadithScreen> {
  String _filterSlug = '';

  /// Reference segment rail: 0 Discover, 1 Collections, 2 My Library.
  /// Every pane renders EXISTING providers — there is deliberately no
  /// fourth topic tab: the corpus carries no topic data to back one.
  int _pane = 0;

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
        return QibraNavy.emerald;
      case 'muslim':
        return QibraNavy.blue;
      case 'tirmidhi':
        return QibraNavy.emerald;
      case 'abudawud':
        return QibraNavy.gold;
      case 'nasai':
        return QibraNavy.cyan;
      case 'ibnmajah':
        return QibraNavy.blue;
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
            _buildHero(context, colors, daily),
            const SizedBox(height: 14),
            // Segment rail (reference): three REAL views over the same
            // providers. QibraChip carries the filled-emerald selected
            // state, matching the reference's active pill.
            Row(
              children: [
                for (final (index, label) in const [
                  'Discover',
                  'Collections',
                  'My Library',
                ].indexed) ...[
                  QibraChip(
                    label: label,
                    selected: _pane == index,
                    onTap: () => setState(() => _pane = index),
                  ),
                  if (index != 2) const SizedBox(width: 8),
                ],
              ],
            ),
            const SizedBox(height: 16),
            ...switch (_pane) {
              1 => _collectionsPane(context, colors, books),
              2 => _libraryPane(context),
              _ => _discoverPane(context, daily, featured),
            },
          ],
        ),
    );
  }

  // ── Hadith redesign (reference image) ──────────────────────────────
  // Discover hero: the day's REAL hadith as the quote card (stable
  // daily pick, reading-language preview, true attribution — never an
  // invented aphorism) over the hadith art band, plus the search pill
  // wired to the same sheet as the header action. Art decode stays
  // inside QibraHeroCard's dpr-capped SafeImage (perf pass); no
  // translucent full-area layers were introduced.
  Widget _buildHero(
    BuildContext context,
    QibraColors colors,
    AsyncValue<HadithModel?> daily,
  ) {
    return QibraHeroCard(
      backgroundAsset: AppAssets.hadithArt,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          daily.when(
            loading: () => QibraStatus.skeleton(height: 54),
            error: (_, __) => Text(
              'The sayings of the Prophet ﷺ',
              style: AppTextStyles.bodyMedium.copyWith(
                color: colors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
            data: (hadith) {
              if (hadith == null) {
                return Text(
                  'Open a collection to start reading.',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: colors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                );
              }
              final lang = ref.watch(hadithLanguageProvider);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hadithQuotePreview(
                      hadith,
                      translation: lang == 'ar'
                          ? hadith.textArabic
                          : hadithTextForLanguage(hadith, lang),
                    ),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: colors.textPrimary,
                      fontStyle: FontStyle.italic,
                      height: 1.55,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '— ${hadith.displayReference}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: colors.goldText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          _SearchPill(onTap: () => _showSearchSheet(context)),
        ],
      ),
    );
  }

  List<Widget> _discoverPane(
    BuildContext context,
    AsyncValue<HadithModel?> daily,
    AsyncValue<List<HadithModel>> featured,
  ) {
    return [
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
      const SizedBox(height: 24),
    ];
  }

  // Collections pane (reference 'Collections / See all'): a horizontal
  // rail of cover-style cards. No book-cover art is bundled, so the
  // 'cover' is the REAL per-collection accent + icon — never a fake
  // stock cover. Counts come from the downloaded-book metadata.
  List<Widget> _collectionsPane(
    BuildContext context,
    QibraColors colors,
    AsyncValue<List<HadithBook>> books,
  ) {
    return [
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
          return SizedBox(
            height: 176,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: source.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final book = source[index];
                final accent = collectionAccent(book.slug, colors.primary);
                return SizedBox(
                  width: 140,
                  child: QibraCard(
                    padding: const EdgeInsets.all(12),
                    onTap: () => _openBook(context, book.slug),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  accent.withValues(alpha: 0.38),
                                  accent.withValues(alpha: 0.06),
                                ],
                              ),
                              border: Border.all(
                                color: accent.withValues(alpha: 0.45),
                              ),
                            ),
                            child: Icon(
                              Icons.auto_stories_rounded,
                              color: accent,
                              size: 26,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          book.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelMedium.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          book.totalHadiths > 0
                              ? '${book.totalHadiths} hadiths'
                              : (book.author.isEmpty ? '—' : book.author),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: colors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => QibraStatus.skeleton(height: 160),
        error: (_, __) => QibraStatus.error(
          title: 'Collections unavailable',
          message: 'Cached books will appear when they finish loading.',
        ),
      ),
      const SizedBox(height: 24),
    ];
  }

  // My Library pane (reference rail slot): the REAL shelves only —
  // saved hadiths from the bookmark store and the Recently-Read LRU.
  // Saved rows render the stored snapshot; a tap re-opens the hadith
  // from the on-device corpus, or routes to the collection when that
  // book is not downloaded yet (verified behavior, never a dead card).
  List<Widget> _libraryPane(BuildContext context) {
    final saved = ref.watch(hadithBookmarksProvider);
    return [
      QibraSectionHeader(
        title: 'Saved Hadith',
        actionLabel: 'All',
        onAction: () => context.go(AppRoutes.bookmarks),
      ),
      if (saved.isEmpty)
        const QibraEmptyState(
          icon: Icons.bookmark_border_rounded,
          title: 'No saved hadith yet',
          message: 'Tap the bookmark on any hadith to keep it here.',
        )
      else ...[
        for (final bookmark in saved.take(20))
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SavedHadithRow(
              bookmark: bookmark,
              onTap: () => _openSaved(context, bookmark),
            ),
          ),
        if (saved.length > 20)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: () => context.go(AppRoutes.bookmarks),
              child: Text('View all ${saved.length} saved hadith'),
            ),
          ),
      ],
      const SizedBox(height: 20),
      _buildRecentlyRead(ref.watch(hadithHistoryProvider)),
    ];
  }

  void _openSaved(BuildContext context, HadithBookmark bookmark) {
    final local = HadithDatabaseService()
        .getHadith(bookmark.bookSlug, bookmark.hadithNumber);
    if (local != null) {
      _showDetail(context, localToHadithModel(local));
    } else {
      _openBook(context, bookmark.bookSlug);
    }
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

  // P1 · Item 4 — Recently Read (persisted LRU, cap 50). Renders
  // nothing while history is empty; the Clear action clears the real
  // store, not just the view.
  Widget _buildRecentlyRead(AsyncValue<List<HadithModel>> history) {
    final items = history.valueOrNull ?? const <HadithModel>[];
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        QibraSectionHeader(
          title: 'Recently Read',
          actionLabel: 'Clear',
          onAction: () async {
            await HadithViewHistory.clear();
            if (!mounted) return;
            ref.invalidate(hadithHistoryProvider);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Reading history cleared')),
            );
          },
        ),
        SizedBox(
          height: 108,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, i) => _RecentlyReadCard(
              hadith: items[i],
              onTap: () => _showDetail(context, items[i]),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  void _copyHadith(BuildContext context, HadithModel hadith) {
    final copyTranslation = hadithTextForLanguage(
        hadith, ref.read(hadithLanguageProvider));
    final text =
        '${hadith.textArabic}\n\n${copyTranslation ?? hadith.textEnglish}\n\n— ${hadith.displayReference}';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Hadith copied')),
    );
  }

  void _showDetail(BuildContext context, HadithModel hadith) {
    final colors = QibraColors.of(context);
    // P1 · Item 4 — opening a hadith detail (here or in the book
    // reader) is the one true view event; record it in the LRU.
    recordHadithView(ref, hadith);
    // Phase B: one language-driven translation block replaces the old
    // fixed Urdu+English stack (snapshot at open, like the scales).
    final sheetLang = ref.read(hadithLanguageProvider);
    final sheetRtl = sheetLang == 'ur';
    final sheetTranslation = sheetLang == 'ar'
        ? null
        : hadithTextForLanguage(hadith, sheetLang);
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
            // World-class hadith pass (item 1): detail-sheet text
            // follows the persisted split scales.
            final prefs = ref.watch(hadithReadingPreferencesProvider);
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
                        // Reference header parity: accent book chip next
                        // to the real reference line; the actions beside
                        // it are all real (bookmark toggle, copy).
                        Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(9),
                            color: colors.primary.withValues(alpha: 0.14),
                            border: Border.all(
                              color: colors.primary.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Icon(
                            Icons.auto_stories_rounded,
                            size: 16,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
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
                          fontSize: AppFontSize.arabicMedium *
                              prefs.arabicScale,
                        ),
                      ),
                    ],
                    if (sheetLang != 'ar' && sheetTranslation != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        sheetTranslation,
                        textAlign:
                            sheetRtl ? TextAlign.right : TextAlign.start,
                        textDirection: sheetRtl
                            ? TextDirection.rtl
                            : TextDirection.ltr,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: colors.textPrimary,
                          fontSize:
                              AppFontSize.bodyLarge * prefs.translationScale,
                        ),
                      ),
                    ] else if (sheetLang != 'ar') ...[
                      const SizedBox(height: 16),
                      Text(
                        'Verified translation unavailable for this language.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: colors.textSecondary,
                          fontStyle: FontStyle.italic,
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
                    HadithMoreFromChapter(
                      hadith: hadith,
                      onOpen: (ctx, target) => _showDetail(ctx, target),
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
    // World-class hadith pass (item 2): a sheet-local controller makes
    // the recents chips REAL — tapping one writes the query back into
    // the same field the user types in, then re-runs it.
    final controller = TextEditingController();
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
                    controller: controller,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Search hadiths',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                    onChanged: (value) {
                      ref.read(hadithSearchQueryProvider.notifier).state =
                          value;
                    },
                    onSubmitted: (value) {
                      final trimmed = value.trim();
                      if (trimmed.isEmpty) return;
                      ref
                          .read(hadithRecentSearchesProvider.notifier)
                          .add(trimmed);
                    },
                  ),
                ),
                Expanded(
                  child: Consumer(
                    builder: (context, ref, _) {
                      final query = ref.watch(hadithSearchQueryProvider);
                      final results = ref.watch(hadithSearchResultsProvider);
                      if (query.trim().isEmpty) {
                        final recents =
                            ref.watch(hadithRecentSearchesProvider);
                        return Column(
                          children: [
                            if (recents.isNotEmpty) ...[
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 8, 0),
                                child: Row(
                                  children: [
                                    Icon(Icons.history_rounded,
                                        size: 16,
                                        color: colors.textSecondary),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Recent searches',
                                      style: AppTextStyles.labelMedium
                                          .copyWith(
                                        color: colors.textPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const Spacer(),
                                    TextButton(
                                      onPressed: () => ref
                                          .read(hadithRecentSearchesProvider
                                              .notifier)
                                          .clear(),
                                      child: Text(
                                        'Clear',
                                        style: AppTextStyles.labelSmall
                                            .copyWith(
                                          color: colors.error,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 8),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (final entry in recents)
                                      QibraChip(
                                        label: entry,
                                        selected: false,
                                        onTap: () {
                                          controller.text = entry;
                                          ref
                                              .read(hadithSearchQueryProvider
                                                  .notifier)
                                              .state = entry;
                                          ref
                                              .read(
                                                  hadithRecentSearchesProvider
                                                      .notifier)
                                              .add(entry);
                                        },
                                      ),
                                  ],
                                ),
                              ),
                            ],
                            const Expanded(
                              child: QibraEmptyState(
                                icon: Icons.search_rounded,
                                title: 'Search the collections',
                                message:
                                    'Try words such as prayer, patience, or charity.',
                              ),
                            ),
                          ],
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
                                highlightQuery: query.trim(),
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
      controller.dispose();
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
    // World-class hadith pass (item 1): today's card text follows the
    // persisted split scales like every other hadith body surface.
    final prefs = ref.watch(hadithReadingPreferencesProvider);
    return QibraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Reference treatment: calendar glyph + section label. The art
          // band now lives once, in the page hero (QibraHeroCard's
          // dpr-capped SafeImage) — one image decode per screen.
          Row(
            children: [
              Icon(
                Icons.calendar_month_rounded,
                size: 16,
                color: colors.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Today\'s hadith',
                style: AppTextStyles.labelMedium.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
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
                fontSize: AppFontSize.arabicMedium * prefs.arabicScale,
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
              textAlign: lang == 'ur' ? TextAlign.right : TextAlign.start,
              textDirection:
                  lang == 'ur' ? TextDirection.rtl : TextDirection.ltr,
              style: AppTextStyles.bodyMedium.copyWith(
                color: colors.textSecondary,
                fontSize: AppFontSize.bodyMedium * prefs.translationScale,
              ),
            ),
          ],
          const SizedBox(height: 12),
          // Reference chip row: real reference + real grade. The grade
          // chip renders ONLY when the corpus actually knows it —
          // UNKNOWN stays UNKNOWN (no invented "Authentic" badge).
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _MetaChip(
                label: hadith!.displayReference,
                accent: colors.primary,
              ),
              if (hadith!.grade != HadithGrade.unknown)
                _MetaChip(
                  // Honest qualifier kept from the pre-redesign pill
                  // (pinned by phase18_stage2_honesty_test): a known
                  // Sahih label on these files is collection-level.
                  label: hadith!.grade == HadithGrade.sahih
                      ? '${hadith!.grade.label} · collection grade'
                      : hadith!.grade.label,
                  accent: colors.primary,
                  filled: true,
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Gold CTA opens the same reader sheet the old 'Read' button
          // drove; bookmark/share keep their existing real handlers
          // (share = the clipboard flow, unchanged). The reference's
          // audio-playback control has no TTS feature behind it —
          // deliberately omitted.
          Row(
            children: [
              Expanded(
                child: AppGoldButton(
                  label: 'Read Full Hadith',
                  size: AppButtonSize.small,
                  fullWidth: true,
                  suffixIcon: Icons.arrow_forward_rounded,
                  onPressed: onRead,
                ),
              ),
              const SizedBox(width: 8),
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

/// Outline/filled pill used on the today card (reference chip row).
class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.label,
    required this.accent,
    this.filled = false,
  });

  final String label;
  final Color accent;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: filled ? accent.withValues(alpha: 0.18) : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: filled ? accent : colors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HadithTile extends ConsumerWidget {
  const _HadithTile({
    required this.hadith,
    required this.onTap,
    this.highlightQuery = '',
  });

  final HadithModel hadith;
  final VoidCallback onTap;

  /// World-class hadith pass (item 2): when non-empty (search results
  /// only), query terms are emphasised inside the previews — folded
  /// matching on ORIGINAL coordinates, restrained primary wash. The
  /// featured list leaves it empty and renders plain Text.
  final String highlightQuery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = QibraColors.of(context);
    final bookmarked = ref.watch(isHadithBookmarkedProvider(hadith.id));
    // World-class hadith pass (item 1): list-card text follows the
    // persisted split scales. Phase B: the preview follows the READING
    // LANGUAGE (was always English); the Arabic viewing keeps the
    // English preview because the Arabic block above already shows the
    // selected text itself.
    final prefs = ref.watch(hadithReadingPreferencesProvider);
    final lang = ref.watch(hadithLanguageProvider);
    final translation =
        lang == 'ar' ? null : hadithTextForLanguage(hadith, lang);
    final previewText = translation ?? hadith.textEnglish;
    final previewRtl = lang == 'ur' && translation != null;
    final q = highlightQuery.trim();
    final arabicStyle = AppArabicStyles.quranSmall.copyWith(
      color: colors.textPrimary,
      fontSize: AppFontSize.arabicSmall * prefs.arabicScale,
    );
    final translationStyle = AppTextStyles.bodySmall.copyWith(
      color: colors.textSecondary,
      fontSize: AppFontSize.bodySmall * prefs.translationScale,
    );
    return QibraCard(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Reference feed card: the hadith number rides a solid
              // emerald badge; the book + number line keeps primary
              // teal. No topic chips — the corpus has no topic tags.
              Container(
                width: 26,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.primary,
                ),
                child: Text(
                  '${hadith.hadithNumber}',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
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
            q.isEmpty
                ? Text(
                    hadith.textArabic,
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: arabicStyle,
                  )
                : RichText(
                    textAlign: TextAlign.right,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      children: hadithHighlightSpans(
                        hadith.textArabic,
                        q,
                        arabicStyle,
                        colors.primary,
                      ),
                    ),
                  ),
          if (previewText.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            q.isEmpty
                ? Text(
                    previewText,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign:
                        previewRtl ? TextAlign.right : TextAlign.start,
                    textDirection: previewRtl
                        ? TextDirection.rtl
                        : TextDirection.ltr,
                    style: translationStyle,
                  )
                : RichText(
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign:
                        previewRtl ? TextAlign.right : TextAlign.start,
                    text: TextSpan(
                      children: hadithHighlightSpans(
                        previewText,
                        q,
                        translationStyle,
                        colors.primary,
                      ),
                    ),
                  ),
          ],
        ],
      ),
    );
  }
}

/// Pure span builder behind the search previews (unit-tested, item 2):
/// [SearchNormalizer.allMatches] folds diacritics/hamza (Arabic/Urdu)
/// and case (latin) but answers in ORIGINAL-text coordinates, so the
/// substrings emitted here are verbatim corpus text — emphasis never
/// rewrites or reorders the hadith. No folded match -> plain single
/// span, never a fabricated highlight.
List<TextSpan> hadithHighlightSpans(
  String text,
  String query,
  TextStyle style,
  Color accent,
) {
  final matches = SearchNormalizer.allMatches(text, query);
  if (matches.isEmpty) return [TextSpan(text: text, style: style)];
  final out = <TextSpan>[];
  var last = 0;
  for (final m in matches) {
    if (m.start > last) {
      out.add(TextSpan(text: text.substring(last, m.start), style: style));
    }
    out.add(TextSpan(
      text: text.substring(m.start, m.end),
      style: style.copyWith(
        color: accent,
        fontWeight: FontWeight.w800,
        backgroundColor: accent.withValues(alpha: 0.14),
      ),
    ));
    last = m.end;
  }
  if (last < text.length) {
    out.add(TextSpan(text: text.substring(last), style: style));
  }
  return out;
}

// ============================================================
// RECENTLY READ CARD (P1 · Item 4)
// ============================================================

class _RecentlyReadCard extends ConsumerWidget {
  const _RecentlyReadCard({required this.hadith, required this.onTap});

  final HadithModel hadith;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = QibraColors.of(context);
    // Phase B: previews everywhere follow the reading language.
    final preview = (hadithTextForLanguage(
                hadith, ref.watch(hadithLanguageProvider)) ??
            hadith.textEnglish)
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
    return SizedBox(
      width: 190,
      child: Material(
        color: colors.card,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: colors.border),
          borderRadius: BorderRadius.circular(14),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hadith.bookName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: colors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Text(
                    preview.isEmpty ? hadith.displayReference : preview,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: colors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '#${hadith.hadithNumber}',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// HADITH REDESIGN (reference image) — pure helper + small widgets
// ============================================================

/// The hero quote is the REAL daily hadith in the reading language,
/// trimmed word-safely to one glanceable block (cap 220 chars; the
/// ellipsis appears only on genuine truncation, and a row without any
/// preview text falls back to its reference). Pure — pinned in
/// test/hadith_redesign_test.dart; never invents or rewrites wording.
@visibleForTesting
String hadithQuotePreview(HadithModel hadith, {String? translation}) {
  final raw = (translation ?? hadith.textEnglish)
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');
  if (raw.isEmpty) return hadith.displayReference;
  if (raw.length <= 220) return raw;
  final window = raw.substring(0, 220);
  final space = window.lastIndexOf(' ');
  return '${window.substring(0, space > 100 ? space : 220)}…';
}

/// Search entry on the hero (reference pill) — opens the existing
/// search sheet; deliberately NO trailing filter glyph: the feed
/// filters are the collection chips, and inventing an affordance with
/// no sheet behind it is exactly what this pass forbids.
class _SearchPill extends StatelessWidget {
  const _SearchPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    return Material(
      color: colors.card,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(999),
        side: BorderSide(color: colors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                Icons.search_rounded,
                size: 18,
                color: colors.textSecondary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Search hadith…',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// My Library row for a saved hadith: renders the REAL bookmark
/// snapshot (book · number line + stored preview text) — no fetch
/// claims, no fake metadata.
class _SavedHadithRow extends StatelessWidget {
  const _SavedHadithRow({required this.bookmark, required this.onTap});

  final HadithBookmark bookmark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    final preview = bookmark.textPreview.trim();
    return QibraCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          Icon(Icons.bookmark_rounded, color: colors.goldText, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${bookmark.bookName} · #${bookmark.hadithNumber}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  preview.isEmpty ? bookmark.chapterName : preview,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: colors.textTertiary,
            size: 20,
          ),
        ],
      ),
    );
  }
}
