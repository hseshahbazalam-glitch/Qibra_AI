// lib/features/quran/presentation/mushaf_reader_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/a11y/app_a11y.dart';
import '../../../core/design_system/qibra_colors.dart';
import '../../../shared/widgets/media/safe_image.dart';
import '../../tafseer/presentation/tafseer_screen.dart';
import 'surah_reader_screen.dart';

final _currentPageProvider = StateProvider.autoDispose<int>((ref) => 1);
final _isNightModeProvider = StateProvider.autoDispose<bool>((ref) => false);
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
  ConsumerState<MushafReaderScreen> createState() => _MushafReaderScreenState();
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

  // ═══════════════════════════════════════════════
  // BOOKMARKS (Real - SharedPreferences)
  // ═══════════════════════════════════════════════

  Future<void> _loadBookmarks() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final bookmarks = prefs.getStringList('mushaf_bookmarked_pages') ?? [];
    setState(() {
      _bookmarkedPages =
          bookmarks.map((e) => int.tryParse(e)).whereType<int>().toSet();
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
    _showToast(
      _bookmarkedPages.contains(page)
          ? '🔖 Page $page bookmarked'
          : 'Bookmark removed from page $page',
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    final currentPage = ref.watch(_currentPageProvider);
    final isNightMode = ref.watch(_isNightModeProvider);
    final showControls = ref.watch(_showControlsProvider);

    return Scaffold(
      backgroundColor: isNightMode ? Colors.black : const Color(0xFFF5EEDC),
      body: SafeArea(
        child: Stack(
          children: [
            GestureDetector(
              onTap: () {
                ref.read(_showControlsProvider.notifier).state = !showControls;
              },
              child: PageView.builder(
                controller: _pageController,
                reverse: true,
                itemCount: 604,
                onPageChanged: (index) {
                  HapticFeedback.selectionClick();
                  ref.read(_currentPageProvider.notifier).state = index + 1;
                },
                itemBuilder: (context, index) {
                  return _MushafPage(
                    pageNumber: index + 1,
                    isNightMode: isNightMode,
                  );
                },
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              top: showControls ? 0 : -100,
              left: 0,
              right: 0,
              child: _buildTopBar(currentPage, isNightMode),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 300),
              bottom: showControls ? 0 : -200,
              left: 0,
              right: 0,
              child: _buildBottomBar(currentPage, isNightMode),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(int currentPage, bool isNightMode) {
    final colors = QibraColors.of(context);
    final isBookmarked = _bookmarkedPages.contains(currentPage);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isNightMode
            ? Colors.black.withValues(alpha: 0.85)
            : colors.primary.withValues(alpha: 0.95),
        border: Border(
          bottom: BorderSide(color: colors.accent.withValues(alpha: 0.3)),
        ),
      ),
      child: Row(
        children: [
          _iconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getSurahName(currentPage),
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'Juz ${_getJuzForPage(currentPage)} • Page $currentPage',
                  style: TextStyle(
                    color: colors.textPrimary.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          _iconButton(
            icon: isBookmarked
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            onTap: () => _toggleBookmark(currentPage),
            highlight: isBookmarked,
          ),
          const SizedBox(width: 8),
          _iconButton(
            icon: isNightMode ? Icons.wb_sunny_rounded : Icons.nightlight_round,
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(_isNightModeProvider.notifier).state = !isNightMode;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(int currentPage, bool isNightMode) {
    final colors = QibraColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: isNightMode
            ? Colors.black.withValues(alpha: 0.85)
            : colors.primary.withValues(alpha: 0.95),
        border: Border(
          top: BorderSide(color: colors.accent.withValues(alpha: 0.3)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '1',
                  style: TextStyle(
                    color: colors.textPrimary.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      activeTrackColor: colors.accent,
                      inactiveTrackColor: colors.onPrimary.withValues(alpha: 0.2),
                      thumbColor: colors.accent,
                      overlayColor: colors.accent.withValues(alpha: 0.2),
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 8,
                      ),
                    ),
                    child: Slider(
                      value: currentPage.toDouble(),
                      min: 1,
                      max: 604,
                      onChanged: (value) {
                        ref.read(_currentPageProvider.notifier).state =
                            value.toInt();
                      },
                      onChangeEnd: (value) {
                        _pageController.jumpToPage(value.toInt() - 1);
                        HapticFeedback.selectionClick();
                      },
                    ),
                  ),
                ),
                Text(
                  '604',
                  style: TextStyle(
                    color: colors.textPrimary.withValues(alpha: 0.7),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                _iconButton(
                  icon: Icons.chevron_left_rounded,
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
                  child: GestureDetector(
                    onTap: _showGoToPageSheet,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: colors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: colors.accent.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        '$currentPage / 604',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                _iconButton(
                  icon: Icons.chevron_right_rounded,
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
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: colors.accent.withValues(alpha: 0.2)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _actionButton(
                  icon: Icons.article_outlined,
                  label: 'Go to',
                  onTap: _showGoToPageSheet,
                ),
                _actionButton(
                  icon: Icons.menu_book_outlined,
                  label: 'Tafsir',
                  onTap: _openTafsir,
                ),
                _actionButton(
                  icon: Icons.play_arrow_rounded,
                  label: 'Audio',
                  onTap: _playAudio,
                ),
                _actionButton(
                  icon: Icons.translate_rounded,
                  label: 'Translate',
                  onTap: _openTranslation,
                ),
                _actionButton(
                  icon: Icons.more_horiz_rounded,
                  label: 'More',
                  onTap: _showMoreOptions,
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
    required VoidCallback onTap,
    bool highlight = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: AppA11y.minTapTarget,
        height: AppA11y.minTapTarget,
        decoration: BoxDecoration(
          color: highlight
              ? colors.accent.withValues(alpha: 0.35)
              : colors.accent.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: highlight ? colors.accent : colors.onPrimary,
          size: 20,
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
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: colors.textPrimary, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  int _getSurahNumberForPage(int page) {
    if (page == 1) return 1;
    if (page <= 49) return 2;
    if (page <= 76) return 3;
    if (page <= 106) return 4;
    if (page <= 127) return 5;
    if (page <= 149) return 6;
    if (page <= 176) return 7;
    if (page <= 187) return 8;
    if (page <= 207) return 9;
    if (page <= 221) return 10;
    return 1;
  }

  void _openTafsir() {
    HapticFeedback.mediumImpact();
    final currentPage = ref.read(_currentPageProvider);
    final surahNum = _getSurahNumberForPage(currentPage);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TafseerScreen(
          surahNumber: surahNum,
          initialAyah: 1,
        ),
      ),
    );
  }

  void _openTranslation() {
    HapticFeedback.mediumImpact();
    final currentPage = ref.read(_currentPageProvider);
    final surahNum = _getSurahNumberForPage(currentPage);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SurahReaderScreen(surahNumber: surahNum),
      ),
    );
  }

  // ✅ AUDIO - Opens Surah Reader with audio
  void _playAudio() {
    HapticFeedback.mediumImpact();
    final currentPage = ref.read(_currentPageProvider);
    final surahNum = _getSurahNumberForPage(currentPage);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SurahReaderScreen(surahNumber: surahNum),
      ),
    );
    _showToast('🎵 Opening surah reader with audio');
  }

  // ✅ MORE OPTIONS - Real menu
  void _showMoreOptions() {
    final colors = QibraColors.of(context);
    HapticFeedback.selectionClick();
    final currentPage = ref.read(_currentPageProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                        color: colors.accent, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Page $currentPage Options',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: colors.border, height: 1),
              _menuOption(
                icon: Icons.copy_rounded,
                label: 'Copy Page Info',
                color: colors.primarySoft,
                onTap: () {
                  Navigator.pop(context);
                  _copyPageInfo(currentPage);
                },
              ),
              _menuOption(
                icon: Icons.share_rounded,
                label: 'Share Page',
                color: colors.primarySoft,
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
                    ? 'Remove Bookmark'
                    : 'Bookmark Page',
                color: colors.accent,
                onTap: () {
                  Navigator.pop(context);
                  _toggleBookmark(currentPage);
                },
              ),
              _menuOption(
                icon: Icons.list_alt_rounded,
                label: 'View All Bookmarks',
                color: colors.accent,
                onTap: () {
                  Navigator.pop(context);
                  _showBookmarksList();
                },
              ),
              _menuOption(
                icon: Icons.info_outline_rounded,
                label: 'Page Info',
                color: colors.accent,
                onTap: () {
                  Navigator.pop(context);
                  _showPageInfo(currentPage);
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
    required Color color,
    required VoidCallback onTap,
  }) {
    final colors = QibraColors.of(context);
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(
        label,
        style: TextStyle(
          color: colors.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        color: colors.textTertiary,
        size: 14,
      ),
    );
  }

  // ✅ COPY PAGE INFO
  void _copyPageInfo(int page) {
    final text = '''📖 Quran Reading Progress

Page: $page / 604
Surah: ${_getSurahName(page)}
Juz: ${_getJuzForPage(page)}

Shared via Qibra AI''';

    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.mediumImpact();
    _showToast('📋 Page info copied');
  }

  // ✅ SHARE PAGE
  void _sharePage(int page) {
    final text = '''📖 I'm reading Quran

Currently on Page $page of 604
Surah: ${_getSurahName(page)}
Juz: ${_getJuzForPage(page)}

Join me on Qibra AI 🕌''';

    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.mediumImpact();
    _showToast('📤 Page info copied - paste to share');
  }

  // ✅ SHOW PAGE INFO DIALOG
  void _showPageInfo(int page) {
    final colors = QibraColors.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: colors.accent),
            const SizedBox(width: 8),
            Text(
              'Page $page',
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoRow('Surah', _getSurahName(page)),
            _infoRow('Juz', 'Para ${_getJuzForPage(page)}'),
            _infoRow('Position', '$page of 604'),
            _infoRow('Progress', '${(page / 604 * 100).toStringAsFixed(1)}%'),
            _infoRow(
              'Bookmarked',
              _bookmarkedPages.contains(page) ? 'Yes ✓' : 'No',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Close',
              style: TextStyle(color: colors.goldText),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    final colors = QibraColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: colors.textPrimary.withValues(alpha: 0.7),
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ✅ BOOKMARKS LIST
  void _showBookmarksList() {
    final colors = QibraColors.of(context);
    if (_bookmarkedPages.isEmpty) {
      _showToast('No bookmarks yet. Bookmark pages to see them here!');
      return;
    }

    final sortedBookmarks = _bookmarkedPages.toList()..sort();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        minChildSize: 0.4,
        expand: false,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
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
                    Icon(Icons.bookmark_rounded,
                        color: colors.accent, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Bookmarked Pages',
                      style: TextStyle(
                        color: colors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${sortedBookmarks.length} pages',
                      style: TextStyle(
                        color: colors.textPrimary.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: colors.border, height: 1),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  padding: const EdgeInsets.all(12),
                  itemCount: sortedBookmarks.length,
                  itemBuilder: (context, index) {
                    final page = sortedBookmarks[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: colors.textPrimary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        onTap: () {
                          Navigator.pop(context);
                          _pageController.jumpToPage(page - 1);
                          HapticFeedback.mediumImpact();
                        },
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                colors.primary,
                                colors.accent,
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '$page',
                              style: TextStyle(
                                color: colors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          'Page $page',
                          style: TextStyle(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          '${_getSurahName(page)} • Juz ${_getJuzForPage(page)}',
                          style: TextStyle(
                            color: colors.textPrimary.withValues(alpha: 0.6),
                            fontSize: 12,
                          ),
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.delete_outline_rounded,
                            color: colors.error,
                          ),
                          onPressed: () async {
                            _toggleBookmark(page);
                            Navigator.pop(context);
                          },
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

  // ✅ GO TO PAGE - Real dialog
  void _showGoToPageSheet() {
    final colors = QibraColors.of(context);
    HapticFeedback.selectionClick();
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.article_outlined, color: colors.accent),
            SizedBox(width: 8),
            Text(
              'Go to Page',
              style: TextStyle(
                color: colors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Enter page number (1 - 604)',
              style: TextStyle(
                color: colors.textPrimary.withValues(alpha: 0.7),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                hintText: 'e.g. 100',
                hintStyle: TextStyle(
                  color: colors.textPrimary.withValues(alpha: 0.3),
                ),
                filled: true,
                fillColor: colors.onPrimary.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
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
              style: TextStyle(color: colors.textPrimary.withValues(alpha: 0.7)),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
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
      _showToast('❌ Please enter a valid page (1-604)');
      return;
    }

    Navigator.pop(dialogContext);
    _pageController.jumpToPage(page - 1);
    HapticFeedback.mediumImpact();
    _showToast('📄 Jumped to page $page');
  }

  String _getSurahName(int page) {
    if (page == 1) return 'Al-Fatihah';
    if (page <= 49) return 'Al-Baqarah';
    if (page <= 76) return 'Aal-Imran';
    if (page <= 106) return 'An-Nisa';
    if (page <= 127) return 'Al-Maidah';
    if (page <= 149) return 'Al-Anam';
    if (page <= 176) return 'Al-Araf';
    if (page <= 187) return 'Al-Anfal';
    if (page <= 207) return 'At-Tawbah';
    if (page <= 221) return 'Yunus';
    return 'Al-Quran';
  }

  int _getJuzForPage(int page) {
    return ((page - 1) ~/ 20) + 1;
  }

  void _showToast(String message) {
    final colors = QibraColors.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: colors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

class _MushafPage extends StatelessWidget {
  const _MushafPage({
    required this.pageNumber,
    required this.isNightMode,
  });

  final int pageNumber;
  final bool isNightMode;

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    return Container(
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 60,
        bottom: MediaQuery.of(context).padding.bottom + 80,
      ),
      child: Center(
        child: InteractiveViewer(
          minScale: 1.0,
          maxScale: 4.0,
          child: ColorFiltered(
            colorFilter: isNightMode
                ? const ColorFilter.matrix([
                    -1,
                    0,
                    0,
                    0,
                    255,
                    0,
                    -1,
                    0,
                    0,
                    255,
                    0,
                    0,
                    -1,
                    0,
                    255,
                    0,
                    0,
                    0,
                    1,
                    0,
                  ])
                : const ColorFilter.matrix([
                    1,
                    0,
                    0,
                    0,
                    0,
                    0,
                    1,
                    0,
                    0,
                    0,
                    0,
                    0,
                    1,
                    0,
                    0,
                    0,
                    0,
                    0,
                    1,
                    0,
                  ]),
            child: SafeImage(
              assetPath: 'assets/mushaf_pages/$pageNumber.png',
              fit: BoxFit.contain,
              fallback: SafeImageFallback.quran,
            ),
          ),
        ),
      ),
    );
  }
}
