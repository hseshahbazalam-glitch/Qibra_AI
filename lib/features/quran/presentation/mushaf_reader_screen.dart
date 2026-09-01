// lib/features/quran/presentation/mushaf_reader_screen.dart
// ============================================================
// QIBRA AI — MUSHAF READER (Stage B rewrite, midnight navy)
//
// Honesty upgrade over the legacy screen:
//  • The old viewer rendered assets/mushaf_pages/<n>.png — a path
//    that does not exist in the bundle — so all 604 pages showed
//    the same fallback artwork, and its surah/juz tables were
//    fabricated (every page past 221 claimed 'Al-Quran', juz was
//    '(page-1)/20'). It now renders the REAL verses of each page
//    from the bundled Uthmaniya dataset, whose per-ayah page and
//    juz fields are authentic (alquran.cloud).
//  • 'Audio' action deleted (recitation is not bundled — no fake
//    player chrome); all toast/share emoji removed.
//  • All colors are theme tokens (navy); no bespoke night-mode
//    inversion of a page that is now text.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/a11y/app_a11y.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/qibra_colors.dart';
import '../../../shared/widgets/qibra_status.dart';
import '../data/models/quran_models.dart';
import '../providers/quran_provider.dart';
import '../../tafseer/presentation/tafseer_screen.dart';

/// One ayah occurrence on a mushaf page, with its surah context.
class MushafPageEntry {
  const MushafPageEntry({
    required this.surahNumber,
    required this.surahName,
    required this.ayah,
  });

  final int surahNumber;
  final String surahName;
  final AyahModel ayah;
}

/// Real page -> ayahs index built once from the bundled corpus.
final mushafPageIndexProvider =
    FutureProvider<Map<int, List<MushafPageEntry>>>((ref) async {
  final repository = ref.watch(quranRepositoryProvider);
  final infos = await repository.getAllSurahsInfo();
  final byPage = <int, List<MushafPageEntry>>{};
  for (final info in infos) {
    final surah = await repository.getSurah(info.number);
    if (surah == null) continue;
    for (final ayah in surah.ayahs) {
      byPage
          .putIfAbsent(ayah.page, () => <MushafPageEntry>[])
          .add(
            MushafPageEntry(
              surahNumber: surah.number,
              surahName: surah.name,
              ayah: ayah,
            ),
          );
    }
  }
  return byPage;
});

final _currentPageProvider = StateProvider.autoDispose<int>((ref) => 1);
final _showControlsProvider = StateProvider.autoDispose<bool>((ref) => true);

class MushafReaderScreen extends ConsumerStatefulWidget {
  const MushafReaderScreen({
    super.key,
    this.initialPage = 1,
    this.surahNumber,
  });

  final int initialPage;
  final int? surahNumber;

  @override
  ConsumerState<MushafReaderScreen> createState() =>
      _MushafReaderScreenState();
}

class _MushafReaderScreenState extends ConsumerState<MushafReaderScreen> {
  late PageController _pageController;
  Set<int> _bookmarkedPages = {};

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: widget.initialPage - 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(_currentPageProvider.notifier).state = widget.initialPage;
    });
    _loadBookmarks();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  // ── Bookmarks (real — SharedPreferences) ────────────────────

  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final raw = prefs.getStringList('mushaf_bookmarked_pages') ?? const [];
    setState(() {
      _bookmarkedPages =
          raw.map((e) => int.tryParse(e)).whereType<int>().toSet();
    });
  }

  Future<void> _toggleBookmark(int page) async {
    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      if (_bookmarkedPages.contains(page)) {
        _bookmarkedPages.remove(page);
      } else {
        _bookmarkedPages.add(page);
      }
    });
    await prefs.setStringList(
      'mushaf_bookmarked_pages',
      _bookmarkedPages.map((e) => e.toString()).toList(),
    );
    if (!mounted) return;
    _showToast(_bookmarkedPages.contains(page)
        ? 'Page $page bookmarked'
        : 'Bookmark removed from page $page');
  }

  // ── Page helpers (REAL data from the index) ─────────────────

  List<MushafPageEntry> _entriesFor(
    Map<int, List<MushafPageEntry>> index,
    int page,
  ) =>
      index[page] ?? const [];

  Map<int, List<MushafPageEntry>>? _index(WidgetRef ref) =>
      ref.read(mushafPageIndexProvider).value;

  int? _firstSurahOnPage(int page) {
    final list = _index(ref)?[page];
    if (list == null || list.isEmpty) return null;
    return list.first.surahNumber;
  }

  int? _juzOnPage(int page) {
    final list = _index(ref)?[page];
    if (list == null || list.isEmpty) return null;
    return list.first.ayah.juz;
  }

  String _pageSurahLabel(int page) {
    final list = _index(ref)?[page];
    if (list == null || list.isEmpty) return '—';
    final names = <String>[];
    for (final e in list) {
      if (names.isEmpty || names.last != e.surahName) {
        names.add(e.surahName);
      }
    }
    return names.join(' · ');
  }

  void _showToast(String message) {
    final colors = QibraColors.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: colors.cardMuted,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
    );
  }

  // ── Actions ─────────────────────────────────────────────────

  void _openTafsir(int page) {
    final surah = _firstSurahOnPage(page);
    if (surah == null) {
      _showToast('Tafsir is available once the Quran data is loaded');
      return;
    }
    HapticFeedback.mediumImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TafseerScreen(
          surahNumber: surah,
          initialAyah: _firstAyahOfSurahOnPage(page, surah) ?? 1,
        ),
      ),
    );
  }

  int? _firstAyahOfSurahOnPage(int page, int surahNumber) {
    final list = _index(ref)?[page];
    if (list == null) return null;
    for (final e in list) {
      if (e.surahNumber == surahNumber) return e.ayah.numberInSurah;
    }
    return null;
  }

  void _openTranslation(int page) {
    final surah = _firstSurahOnPage(page);
    if (surah == null) {
      _showToast('The text is available once the Quran data is loaded');
      return;
    }
    HapticFeedback.mediumImpact();
    context.push(
      '${AppRoutes.surahReader}?surah=$surah'
      '&ayah=${_firstAyahOfSurahOnPage(page, surah) ?? 1}'
      '&tab=Translation',
    );
  }

  void _copyPageInfo(int page) {
    final juz = _juzOnPage(page);
    final text = '''QIBRA AI — Quran reading progress

Page: $page / 604
Surah: ${_pageSurahLabel(page)}
Juz: ${juz ?? '—'}''';
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.mediumImpact();
    _showToast('Page info copied');
  }

  void _sharePage(int page) {
    // Sharing goes through the same clipboard handoff the rest of the
    // app uses (no share plugin is bundled).
    _copyPageInfo(page);
    _showToast('Page info copied — paste it anywhere to share');
  }

  void _showPageInfo(int page) {
    final colors = QibraColors.of(context);
    final juz = _juzOnPage(page);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.card,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        title: Row(
          children: [
            Icon(Icons.info_outline_rounded,
                color: colors.textSecondary, size: 22),
            const SizedBox(width: 8),
            Text(
              'Page $page',
              style: AppTextStyles.titleMedium.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow(colors, 'Surah', _pageSurahLabel(page)),
            _infoRow(colors, 'Juz', juz == null ? '—' : 'Juz $juz'),
            _infoRow(colors, 'Position', '$page of 604'),
            _infoRow(
              colors,
              'Progress',
              '${(page / 604 * 100).toStringAsFixed(1)}%',
            ),
            _infoRow(
              colors,
              'Bookmarked',
              _bookmarkedPages.contains(page) ? 'Yes' : 'No',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Close',
              style:
                  AppTextStyles.labelLarge.copyWith(color: colors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(QibraColors colors, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTextStyles.bodySmall
                .copyWith(color: colors.textTertiary),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.bodyMedium.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showGoToPageSheet() {
    HapticFeedback.selectionClick();
    final colors = QibraColors.of(context);
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.card,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(20)),
        ),
        title: Row(
          children: [
            Icon(Icons.article_outlined,
                color: colors.textSecondary, size: 22),
            const SizedBox(width: 8),
            Text(
              'Go to page',
              style: AppTextStyles.titleMedium.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enter a page number (1 – 604)',
              style: AppTextStyles.bodySmall
                  .copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              style: AppTextStyles.titleLarge.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
              decoration: InputDecoration(
                hintText: 'e.g. 100',
                hintStyle: AppTextStyles.titleLarge
                    .copyWith(color: colors.textTertiary),
                filled: true,
                fillColor: colors.cardMuted,
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: (value) => _goToPage(value, ctx),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: AppTextStyles.labelLarge
                  .copyWith(color: colors.textSecondary),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
            ),
            onPressed: () => _goToPage(controller.text, ctx),
            child: const Text('Go'),
          ),
        ],
      ),
    );
  }

  void _goToPage(String text, BuildContext dialogContext) {
    final page = int.tryParse(text);
    if (page == null || page < 1 || page > 604) {
      _showToast('Enter a valid page (1–604)');
      return;
    }
    Navigator.pop(dialogContext);
    _pageController.jumpToPage(page - 1);
    HapticFeedback.mediumImpact();
    _showToast('On page $page');
  }

  // ── Build ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    final currentPage = ref.watch(_currentPageProvider);
    final showControls = ref.watch(_showControlsProvider);
    final indexAsync = ref.watch(mushafPageIndexProvider);

    return indexAsync.when(
      loading: () => Scaffold(
        backgroundColor: colors.background,
        body: Center(child: QibraStatus.skeleton(height: 420)),
      ),
      error: (e, st) => Scaffold(
        backgroundColor: colors.background,
        body: QibraStatus.error(
          title: 'Quran text unavailable',
          message: 'The bundled Quran data could not be read.',
          onRetry: () => ref.invalidate(mushafPageIndexProvider),
        ),
      ),
      data: (index) {
        return Scaffold(
          backgroundColor: colors.background,
          body: SafeArea(
            child: Stack(
              children: [
                GestureDetector(
                  onTap: () => ref
                      .read(_showControlsProvider.notifier)
                      .state = !showControls,
                  child: PageView.builder(
                    controller: _pageController,
                    reverse: true,
                    itemCount: 604,
                    onPageChanged: (page) {
                      HapticFeedback.selectionClick();
                      ref.read(_currentPageProvider.notifier).state = page + 1;
                    },
                    itemBuilder: (context, page) => _MushafPage(
                      pageNumber: page + 1,
                      entries: _entriesFor(index, page + 1),
                    ),
                  ),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  top: showControls ? 0 : -140,
                  left: 0,
                  right: 0,
                  child: _buildTopBar(currentPage),
                ),
                AnimatedPositioned(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutCubic,
                  bottom: showControls ? 0 : -220,
                  left: 0,
                  right: 0,
                  child: _buildBottomBar(currentPage),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTopBar(int currentPage) {
    final colors = QibraColors.of(context);
    final isBookmarked = _bookmarkedPages.contains(currentPage);
    final juz = _juzOnPage(currentPage);
    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          _iconButton(
            icon: Icons.arrow_back_rounded,
            tooltip: 'Back',
            onTap: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _pageSurahLabel(currentPage),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  juz == null
                      ? 'Page $currentPage of 604'
                      : 'Juz $juz · Page $currentPage / 604',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ),
          _iconButton(
            icon: isBookmarked
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            tooltip: isBookmarked ? 'Remove bookmark' : 'Bookmark page',
            highlight: isBookmarked,
            onTap: () => _toggleBookmark(currentPage),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(int currentPage) {
    final colors = QibraColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  '1',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: colors.textTertiary),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      activeTrackColor: colors.primary,
                      inactiveTrackColor: colors.border,
                      thumbColor: colors.primary,
                      overlayColor: colors.primary.withValues(alpha: 0.15),
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 8,
                      ),
                    ),
                    child: Slider(
                      value: currentPage.toDouble().clamp(1, 604),
                      min: 1,
                      max: 604,
                      onChanged: (value) =>
                          ref.read(_currentPageProvider.notifier).state =
                              value.toInt(),
                      onChangeEnd: (value) {
                        _pageController.jumpToPage(value.toInt() - 1);
                        HapticFeedback.selectionClick();
                      },
                    ),
                  ),
                ),
                Text(
                  '604',
                  style: AppTextStyles.labelSmall
                      .copyWith(color: colors.textTertiary),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            child: Row(
              children: [
                _iconButton(
                  icon: Icons.chevron_left_rounded,
                  tooltip: 'Next page (right-to-left)',
                  onTap: () {
                    if (currentPage < 604) {
                      _pageController.nextPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                ),
                Expanded(
                  child: InkWell(
                    onTap: _showGoToPageSheet,
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: colors.cardMuted,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colors.border),
                      ),
                      child: Text(
                        '$currentPage / 604',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                _iconButton(
                  icon: Icons.chevron_right_rounded,
                  tooltip: 'Previous page (right-to-left)',
                  onTap: () {
                    if (currentPage > 1) {
                      _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: colors.border)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _actionButton(
                  icon: Icons.article_outlined,
                  label: 'Go to',
                  onTap: _showGoToPageSheet,
                ),
                _actionButton(
                  icon: Icons.menu_book_outlined,
                  label: 'Tafsir',
                  onTap: () => _openTafsir(currentPage),
                ),
                _actionButton(
                  icon: Icons.translate_rounded,
                  label: 'Translate',
                  onTap: () => _openTranslation(currentPage),
                ),
                _actionButton(
                  icon: Icons.more_horiz_rounded,
                  label: 'More',
                  onTap: () => _showMoreOptions(currentPage),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    bool highlight = false,
  }) {
    final colors = QibraColors.of(context);
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: AppA11y.minTapTarget,
          height: AppA11y.minTapTarget,
          decoration: BoxDecoration(
            color: highlight ? colors.primarySoft : colors.cardMuted,
            shape: BoxShape.circle,
            border: Border.all(color: colors.border),
          ),
          child: Icon(
            icon,
            color: highlight ? colors.primary : colors.textPrimary,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final colors = QibraColors.of(context);
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: colors.textPrimary, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMoreOptions(int currentPage) {
    final colors = QibraColors.of(context);
    HapticFeedback.selectionClick();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: colors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.more_horiz_rounded,
                        color: colors.textSecondary, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Page $currentPage options',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: colors.border, height: 1),
              _menuOption(
                icon: Icons.copy_rounded,
                label: 'Copy page info',
                onTap: () {
                  Navigator.pop(context);
                  _copyPageInfo(currentPage);
                },
              ),
              _menuOption(
                icon: Icons.share_outlined,
                label: 'Share page',
                onTap: () {
                  Navigator.pop(context);
                  _sharePage(currentPage);
                },
              ),
              _menuOption(
                icon: _bookmarkedPages.contains(currentPage)
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                label: _bookmarkedPages.contains(currentPage)
                    ? 'Remove bookmark'
                    : 'Bookmark page',
                onTap: () {
                  Navigator.pop(context);
                  _toggleBookmark(currentPage);
                },
              ),
              _menuOption(
                icon: Icons.list_alt_rounded,
                label: 'View all bookmarks',
                onTap: () {
                  Navigator.pop(context);
                  _showBookmarksList();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _menuOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final colors = QibraColors.of(context);
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: colors.cardMuted,
          shape: BoxShape.circle,
          border: Border.all(color: colors.border),
        ),
        child: Icon(icon, color: colors.textPrimary, size: 20),
      ),
      title: Text(
        label,
        style: AppTextStyles.bodyMedium.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _showBookmarksList() {
    final colors = QibraColors.of(context);
    if (_bookmarkedPages.isEmpty) {
      _showToast('No bookmarks yet — long-press the bookmark to save one');
      return;
    }
    final pages = _bookmarkedPages.toList()..sort();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.bookmark_rounded,
                        color: colors.primary, size: 22),
                    const SizedBox(width: 8),
                    Text(
                      'Bookmarked pages',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${pages.length} pages',
                      style: AppTextStyles.labelSmall
                          .copyWith(color: colors.textTertiary),
                    ),
                  ],
                ),
              ),
              Divider(color: colors.border, height: 1),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  padding: const EdgeInsets.all(12),
                  itemCount: pages.length,
                  itemBuilder: (context, i) {
                    final page = pages[i];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Container(
                        decoration: BoxDecoration(
                          color: colors.cardMuted,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colors.border),
                        ),
                        child: ListTile(
                          onTap: () {
                            Navigator.pop(sheetContext);
                            _pageController.jumpToPage(page - 1);
                            HapticFeedback.mediumImpact();
                          },
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: colors.primarySoft,
                              shape: BoxShape.circle,
                              border: Border.all(color: colors.border),
                            ),
                            child: Center(
                              child: Text(
                                '$page',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            'Page $page',
                            style: AppTextStyles.titleSmall.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            _pageSurahLabel(page),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: colors.textSecondary,
                            ),
                          ),
                          trailing: IconButton(
                            tooltip: 'Remove bookmark',
                            icon: Icon(Icons.delete_outline_rounded,
                                color: colors.textTertiary),
                            onPressed: () {
                              _toggleBookmark(page);
                              Navigator.pop(sheetContext);
                            },
                          ),
                        ),
                      ),
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

// ─────────────────────────────────────────────────────────────
// One real mushaf page rendered from bundled text data
// ─────────────────────────────────────────────────────────────

class _MushafPage extends StatelessWidget {
  const _MushafPage({required this.pageNumber, required this.entries});

  final int pageNumber;
  final List<MushafPageEntry> entries;

  static const _arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];

  static String _toArabicDigits(int value) =>
      value.toString().split('').map((d) {
        final n = int.parse(d);
        return _arabicDigits[n];
      }).join();

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    if (entries.isEmpty) {
      return Center(
        child: Text(
          'No verses recorded for this page in the bundled data.',
          style: AppTextStyles.bodyMedium
              .copyWith(color: colors.textTertiary),
        ),
      );
    }
    final hasSajdah = entries.any((e) => e.ayah.sajdah);

    final spans = <InlineSpan>[];
    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      final startsSurahHere = e.ayah.numberInSurah == 1 &&
          (i == 0 || entries[i - 1].surahNumber != e.surahNumber);
      if (startsSurahHere) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Expanded(child: Container(height: 1, color: colors.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      'سُورَة ${e.surahName}',
                      style: AppArabicStyles.quranSmall.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Expanded(child: Container(height: 1, color: colors.border)),
                ],
              ),
            ),
          ),
        );
      }
      spans.add(
        TextSpan(
          text: '${e.ayah.text} ',
          style: AppArabicStyles.quranMedium
              .copyWith(color: colors.textPrimary),
        ),
      );
      spans.add(
        TextSpan(
          text: '(${_toArabicDigits(e.ayah.numberInSurah)}) ',
          style: AppTextStyles.bodyMedium.copyWith(
            color: colors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 84, 20, 148),
      child: Column(
        children: [
          Expanded(
            child: Scrollbar(
              child: SingleChildScrollView(
                child: SelectableText.rich(
                  TextSpan(children: spans),
                  textAlign: TextAlign.justify,
                  textDirection: TextDirection.rtl,
                ),
              ),
            ),
          ),
          if (hasSajdah)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mosque, size: 14, color: colors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    'Sajdah of recitation on this page',
                    style: AppTextStyles.labelSmall
                        .copyWith(color: colors.textSecondary),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
