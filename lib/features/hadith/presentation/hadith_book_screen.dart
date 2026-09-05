// lib/features/hadith/presentation/hadith_book_screen.dart
// ============================================================
// QIBRA AI — HADITH BOOK DETAIL SCREEN (Flagship Luxury Reader)
// Complete Arabic + Urdu + English translations with chapter selector & search
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/qibra_navy.dart';
import '../../../core/utils/search_normalizer.dart';
import '../../../shared/widgets/controls/app_switch_tile.dart';
import '../../../shared/widgets/qibra_ui.dart';
import '../data/hadith_availability.dart';
import '../data/models/hadith_models.dart';
import '../data/services/hadith_database_service.dart';
import '../providers/hadith_provider.dart';
import '../providers/hadith_preferences_provider.dart';
import 'hadith_related_section.dart';

class HadithBookScreen extends ConsumerStatefulWidget {
  final HadithBook book;

  /// World-class hadith pass (item 5): when the bookmarks manager taps
  /// an entry it pushes this screen with the target's number — an
  /// EXPLICIT user action, so opening that hadith's detail on arrival
  /// is the honest jump. 0 = nothing requested (normal book open).
  final int focusHadithNumber;

  const HadithBookScreen({
    super.key,
    required this.book,
    this.focusHadithNumber = 0,
  });

  /// Reference prev/next: pure walk over the book's published, ascending
  /// hadith numbers. Returns null when [from] is the last/first entry or
  /// not in the corpus at all — the sheet DISABLES the button there
  /// (no wrap, no invented records). Pinned in
  /// test/hadith_redesign_test.dart.
  @visibleForTesting
  static int? neighbourNumber(List<int> numbers, int from, int step) {
    final i = numbers.indexOf(from);
    if (i < 0) return null;
    final j = i + step;
    if (j < 0 || j >= numbers.length) return null;
    return numbers[j];
  }

  @override
  ConsumerState<HadithBookScreen> createState() => _HadithBookScreenState();
}

class _HadithBookScreenState extends ConsumerState<HadithBookScreen> {
  int? _selectedChapterNumber;
  String _searchQuery = '';
  bool _showArabic = true;
  // Phase B: the old separate Urdu/English switches became ONE
  // translation switch — the reader's selected language drives which
  // translation is shown (hadithTextForLanguage), everywhere.
  bool _showTranslation = true;

  // Resume/jump plumbing (world-class pass, item 3).
  final ScrollController _scroll = ScrollController();
  final GlobalKey _resumeKey = GlobalKey();
  int? _resumeIndex;
  int? _pendingResumeNumber;

  @override
  void initState() {
    super.initState();
    if (widget.focusHadithNumber > 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _openFocusHadith();
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final params = HadithsParams(
      bookSlug: widget.book.slug,
      chapterNumber: _selectedChapterNumber,
    );
    final hadithsAsync = ref.watch(hadithsProvider(params));
    final chaptersAsync = ref.watch(hadithChaptersProvider(widget.book.slug));
    // Resume position (item 3) is DERIVED, not duplicated: the first
    // persisted view-history entry belonging to this book IS the last
    // opened detail for this book. The ONE definition is last-opened
    // DETAIL (the recordHadithView seam) — scrolling is never recorded.
    final history = ref.watch(hadithHistoryProvider).valueOrNull ??
        const <HadithModel>[];
    HadithModel? resume;
    for (final entry in history) {
      if (entry.bookSlug == widget.book.slug) {
        resume = entry;
        break;
      }
    }
    // Effectively-final capture so the non-null promotion holds inside
    // the chip's onTap closure.
    final resumeTarget = resume;

    return Scaffold(
      backgroundColor: QibraNavy.canvas,
      body: SafeArea(
        child: CustomScrollView(
          controller: _scroll,
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. APP BAR
            _buildAppBar(context),

            // 2. BOOK HERO HEADER
            _buildBookHeader(),

            // 3. CHAPTERS & DISPLAY CONTROLS BAR
            _buildControlsBar(context, chaptersAsync.value ?? []),

            // 3b. RESUME (item 3): explicit chip only — opening a book
            // never hijacks the scroll position on its own.
            if (resumeTarget != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: QibraChip(
                      label: 'Continue — ${resumeTarget.displayReference}',
                      selected: false,
                      onTap: () =>
                          _jumpToHadithNumber(resumeTarget.hadithNumber),
                    ),
                  ),
                ),
              ),

            // 4. HADITH LIST
            hadithsAsync.when(
              data: (hadiths) {
                final filtered = _searchQuery.trim().isEmpty
                    ? hadiths
                    : hadiths.where((h) {
                        final q = _searchQuery.toLowerCase();
                        // Stage 3: diacritic/hamza-folded Arabic + Urdu,
                        // case-insensitive English.
                        return h.hadithNumber.toString().contains(q) ||
                            SearchNormalizer.contains(h.textEnglish, _searchQuery) ||
                            SearchNormalizer.contains(h.textUrdu, _searchQuery) ||
                            SearchNormalizer.contains(h.textArabic, _searchQuery) ||
                            SearchNormalizer.contains(h.textBengali, _searchQuery) ||
                            SearchNormalizer.contains(h.textTurkish, _searchQuery) ||
                            SearchNormalizer.contains(h.textIndonesian, _searchQuery) ||
                            SearchNormalizer.contains(h.textFrench, _searchQuery);
                      }).toList();

                // A filter reset queued a resume jump — consume it now
                // that the whole (unfiltered) list is on screen.
                if (_pendingResumeNumber != null) {
                  final number = _pendingResumeNumber!;
                  _pendingResumeNumber = null;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted) return;
                    final idx = _indexOfHadithNumber(filtered, number);
                    if (idx >= 0) {
                      _startJump(idx);
                    } else {
                      _resumeBeyondFirstPage();
                    }
                  });
                }

                if (filtered.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(40),
                        child: Text(
                          'No hadiths found.',
                          style:
                              TextStyle(color: QibraNavy.textSecondary, fontSize: 14),
                        ),
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final h = filtered[index];
                        final card = _HadithCard(
                          hadith: h,
                          showArabic: _showArabic,
                          showTranslation: _showTranslation,
                          onTap: () => _showHadithDetailSheet(context, h),
                        );
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _resumeIndex == index
                              ? KeyedSubtree(key: _resumeKey, child: card)
                              : card,
                        );
                      },
                      childCount: filtered.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(48),
                    child: CircularProgressIndicator(color: QibraNavy.emerald),
                  ),
                ),
              ),
              error: (error, _) => SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: QibraNavy.red, size: 48),
                        const SizedBox(height: 12),
                        const Text(
                          'Failed to load hadiths',
                          style: TextStyle(
                              color: QibraNavy.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.toString(),
                          style: const TextStyle(
                              color: QibraNavy.textSecondary, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────
  // 1. APP BAR
  // ────────────────────────────────────────────────────────
  Widget _buildAppBar(BuildContext context) {
    return SliverAppBar(
      backgroundColor: QibraNavy.canvas,
      pinned: true,
      elevation: 0,
      leading: SizedBox(
        width: 48,
        height: 48,
        child: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: QibraNavy.textPrimary, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      title: Text(
        widget.book.name,
        style: const TextStyle(
            color: QibraNavy.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          tooltip: 'Reading settings',
          icon: const Icon(Icons.display_settings_rounded,
              color: QibraNavy.gold, size: 20),
          onPressed: () => _showQuickSettingsSheet(context),
        ),
      ],
    );
  }

  // ────────────────────────────────────────────────────────
  // 2. BOOK HEADER
  // ────────────────────────────────────────────────────────
  Widget _buildBookHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: QibraNavy.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: QibraNavy.hairline),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: QibraNavy.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: QibraNavy.emeraldDeep),
                    ),
                    child: const Center(
                      child: Icon(Icons.menu_book_rounded,
                          color: QibraNavy.emerald, size: 24),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.book.name,
                          style: const TextStyle(
                              color: QibraNavy.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.book.author,
                          style: const TextStyle(
                              color: QibraNavy.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  _buildStatChip(Icons.article_rounded, 'Hadiths',
                      '${widget.book.totalHadiths}', QibraNavy.emerald),
                  const SizedBox(width: 8),
                  _buildStatChip(Icons.folder_rounded, 'Chapters',
                      '${widget.book.totalChapters}', QibraNavy.gold),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildStatChip(Icons.help_outline_rounded, 'Grade',
                        'UNKNOWN', QibraNavy.textSecondary),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(
      IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w800, fontSize: 11)),
              Text(label,
                  style:
                      const TextStyle(color: QibraNavy.textSecondary, fontSize: 8)),
            ],
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────
  // 3. CONTROLS BAR (Search + Chapter selector)
  // ────────────────────────────────────────────────────────
  Widget _buildControlsBar(BuildContext context, List<HadithChapter> chapters) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            TextField(
              style: const TextStyle(color: QibraNavy.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                filled: true,
                fillColor: QibraNavy.textPrimary,
                hintText: 'Search hadith number or text in this book...',
                hintStyle:
                    const TextStyle(color: QibraNavy.textSecondary, fontSize: 11.5),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: QibraNavy.gold, size: 18),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded,
                            color: QibraNavy.textSecondary, size: 16),
                        onPressed: () => setState(() => _searchQuery = ''),
                      )
                    : null,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: QibraNavy.hairline),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: QibraNavy.hairline),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: QibraNavy.emeraldDeep),
                ),
              ),
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
            const SizedBox(height: 8),
            if (chapters.isNotEmpty)
              SizedBox(
                height: 32,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: chapters.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      final isSelected = _selectedChapterNumber == null;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedChapterNumber = null),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? QibraNavy.textSecondary
                                  : QibraNavy.textPrimary,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: isSelected
                                      ? QibraNavy.emerald
                                      : QibraNavy.textMuted),
                            ),
                            child: Center(
                              child: Text(
                                'All Chapters',
                                style: TextStyle(
                                  color: isSelected
                                      ? QibraNavy.emerald
                                      : QibraNavy.textSecondary,
                                  fontSize: 10,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    final ch = chapters[index - 1];
                    final isSelected = _selectedChapterNumber == ch.number;

                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _selectedChapterNumber = ch.number),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? QibraNavy.textSecondary
                                : QibraNavy.textPrimary,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: isSelected
                                    ? QibraNavy.emerald
                                    : QibraNavy.textMuted),
                          ),
                          child: Center(
                            child: Text(
                              'Ch ${ch.number}: ${ch.name}',
                              style: TextStyle(
                                color: isSelected
                                    ? QibraNavy.emerald
                                    : QibraNavy.textSecondary,
                                fontSize: 10,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
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
    );
  }

  /// Reading-language picker for the quick-settings sheet. Deliberately
  /// a MIRROR of settings_screen's _showHadithLanguageSheet: identical
  /// derived option list (HadithAvailability.selectorOptions()), identical
  /// setLanguage call — the test pins both surfaces to the matrix so
  /// neither can drift back to a hardcoded list.
  void _showReadingLanguageSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: QibraNavy.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final current = ref.read(hadithLanguageProvider);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reading language',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: QibraNavy.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                for (final option in HadithAvailability.selectorOptions())
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      option.note == null
                          ? option.label
                          : '${option.label}  ·  ${option.note}',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: QibraNavy.textPrimary,
                      ),
                    ),
                    trailing: current == option.code
                        ? const Icon(Icons.check_rounded,
                            color: QibraNavy.emerald)
                        : null,
                    onTap: () {
                      ref
                          .read(hadithLanguageProvider.notifier)
                          .setLanguage(option.code);
                      Navigator.pop(ctx);
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// One compact quick-settings sheet (world-class pass, item 1): the
  /// three display toggles moved here from the old dialog UNCHANGED in
  /// behavior (session state, exactly as before) plus the two persisted
  /// split scales. Sliders reflect and write REAL SharedPreferences state
  /// — no decorative handles.
  void _showQuickSettingsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: QibraNavy.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Consumer(
          builder: (context, ref, _) {
            final prefs = ref.watch(hadithReadingPreferencesProvider);
            return StatefulBuilder(
              builder: (context, setSheetState) {
                return SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Reading settings',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.titleMedium.copyWith(
                            color: QibraNavy.textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Reading language (owner 2026-09-05 UX finding):
                        // a reader inside a book expects to switch language
                        // HERE, not only in Settings. Same derived options
                        // as the Settings sheet — one matrix, two entries.
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.translate_rounded,
                              color: QibraNavy.textSecondary),
                          title: Text(
                            'Language',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: QibraNavy.textPrimary,
                            ),
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                HadithAvailability.label(
                                    ref.watch(hadithLanguageProvider)),
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: QibraNavy.textSecondary,
                                ),
                              ),
                              const Icon(Icons.chevron_right_rounded,
                                  color: QibraNavy.textSecondary),
                            ],
                          ),
                          onTap: () => _showReadingLanguageSheet(sheetContext),
                        ),
                        const Divider(height: 20),
                        AppSwitchListTile(
                          activeColor: QibraNavy.emerald,
                          title: const Text('Arabic Text (عربي)',
                              style: TextStyle(
                                  color: QibraNavy.textPrimary,
                                  fontSize: 14)),
                          value: _showArabic,
                          onChanged: (v) {
                            setSheetState(() => _showArabic = v);
                            setState(() => _showArabic = v);
                          },
                        ),
                        if (ref.watch(hadithLanguageProvider) != 'ar')
                          AppSwitchListTile(
                            activeColor: QibraNavy.emerald,
                            title: Text(
                              'Translation (${HadithAvailability.label(ref.watch(hadithLanguageProvider))})',
                              style: const TextStyle(
                                  color: QibraNavy.textPrimary,
                                  fontSize: 14),
                            ),
                            value: _showTranslation,
                            onChanged: (v) {
                              setSheetState(() => _showTranslation = v);
                              setState(() => _showTranslation = v);
                            },
                          ),
                        const SizedBox(height: 8),
                        // Split font controls — same clamped range and
                        // label discipline as the Quran reader sheet.
                        for (final entry in const [
                          ('Arabic text', 'arabic'),
                          ('Translation text', 'translation'),
                        ]) ...[
                          Text(
                            entry.$1,
                            style: AppTextStyles.labelMedium.copyWith(
                              color: QibraNavy.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: Slider(
                                  value: entry.$2 == 'arabic'
                                      ? prefs.arabicScale
                                      : prefs.translationScale,
                                  min: HadithReadingPreferences.scaleMin,
                                  max: HadithReadingPreferences.scaleMax,
                                  divisions: 8,
                                  activeColor: QibraNavy.emerald,
                                  label:
                                      '${(((entry.$2 == 'arabic' ? prefs.arabicScale : prefs.translationScale) - 1) * 100).round()}%',
                                  onChanged: (v) => entry.$2 == 'arabic'
                                      ? ref
                                          .read(
                                              hadithReadingPreferencesProvider
                                                  .notifier)
                                          .setArabicScale(v)
                                      : ref
                                          .read(
                                              hadithReadingPreferencesProvider
                                                  .notifier)
                                          .setTranslationScale(v),
                                ),
                              ),
                              SizedBox(
                                width: 52,
                                child: Text(
                                  '${(entry.$2 == 'arabic' ? prefs.arabicScale : prefs.translationScale).toStringAsFixed(2)}\u00d7',
                                  textAlign: TextAlign.end,
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: QibraNavy.textSecondary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  // ────────────────────────────────────────────────────────
  // RESUME JUMP + BOOKMARK FOCUS (world-class pass, items 3 & 5)
  // ────────────────────────────────────────────────────────

  static int _indexOfHadithNumber(List<HadithModel> list, int number) {
    for (var k = 0; k < list.length; k++) {
      if (list[k].hadithNumber == number) return k;
    }
    return -1;
  }

  void _resumeBeyondFirstPage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
            'Saved hadith is beyond this book\'s first page — search its '
            'number above to find it.'),
      ),
    );
  }

  void _jumpToHadithNumber(int number) {
    if (_selectedChapterNumber != null || _searchQuery.isNotEmpty) {
      // The resume position refers to the whole book — clear the
      // filters first, then the pending jump lands on the next build.
      _pendingResumeNumber = number;
      setState(() {
        _selectedChapterNumber = null;
        _searchQuery = '';
      });
      return;
    }
    final hadiths = ref
        .read(hadithsProvider(
            HadithsParams(bookSlug: widget.book.slug)))
        .valueOrNull;
    if (hadiths == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('This collection is still loading — try again in a moment.')),
      );
      return;
    }
    final idx = _indexOfHadithNumber(hadiths, number);
    if (idx < 0) {
      _resumeBeyondFirstPage();
      return;
    }
    _startJump(idx);
  }

  void _startJump(int index) {
    setState(() => _resumeIndex = index);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ctx = _resumeKey.currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.08,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
      } else {
        // Estimate fallback (same discipline as the Quran pass): the
        // target is not built yet, so drive the viewport with a
        // documented per-card estimate, then re-key for precision.
        const estimatedCardExtent = 240.0;
        final target = (index * estimatedCardExtent)
            .clamp(0.0, _scroll.position.maxScrollExtent);
        _scroll.animateTo(
          target,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
        );
      }
      Future.delayed(const Duration(milliseconds: 420), () {
        if (mounted) setState(() => _resumeIndex = null);
      });
    });
  }

  /// Item 5: a bookmark-tap opened this screen with a target — resolve
  /// it through the REAL service lookup and open its detail sheet.
  Future<void> _openFocusHadith() async {
    try {
      await ref.read(hadithDatabaseInitProvider.future);
    } catch (_) {
      // fall through to the honest not-found path below
    }
    if (!mounted) return;
    final local =
        HadithDatabaseService().getHadith(widget.book.slug, widget.focusHadithNumber);
    if (local == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('That bookmark is not in the bundled data on this device.')),
      );
      return;
    }
    _showHadithDetailSheet(context, localToHadithModel(local));
  }

  void _showHadithDetailSheet(BuildContext context, HadithModel hadith) {
    // P1 · Item 4 — opening a hadith detail (here or on the hadith
    // home sheet) is the one true view event; record it in the LRU.
    recordHadithView(ref, hadith);
    // Text scales (item 1): snapshot at open — sliders live in the
    // quick-settings sheet, not inside an open detail sheet.
    final prefs = ref.read(hadithReadingPreferencesProvider);
    // Phase B: snapshot the reading language at open (same discipline
    // as the scales — language can change later only from Settings).
    final sheetLang = ref.read(hadithLanguageProvider);
    final sheetRtl = sheetLang == 'ar' || sheetLang == 'ur';
    final sheetTranslation = sheetLang == 'ar'
        ? null
        : hadithTextForLanguage(hadith, sheetLang);
    // Reference prev/next: walk the REAL neighbours in this book's
    // published sequence (corpus order, ascending). The pure helper
    // returns null at the ends — the buttons disable there.
    final neighbourNumbers = HadithDatabaseService()
        .getHadiths(widget.book.slug)
        .map((h) => h.hadithNumber)
        .toList(growable: false);
    final prevNumber = HadithBookScreen.neighbourNumber(
        neighbourNumbers, hadith.hadithNumber, -1);
    final nextNumber = HadithBookScreen.neighbourNumber(
        neighbourNumbers, hadith.hadithNumber, 1);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        void openNeighbour(int number) {
          // Pop, then open the neighbour's sheet on the SCREEN context:
          // the same entry point the list rows use, so history/record
          // semantics stay identical (no second code path to drift).
          Navigator.of(sheetContext).pop();
          final local =
              HadithDatabaseService().getHadith(widget.book.slug, number);
          if (local != null) {
            _showHadithDetailSheet(context, localToHadithModel(local));
          }
        }
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          decoration: const BoxDecoration(
            color: QibraNavy.card,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            border: Border(
              top: BorderSide(color: QibraNavy.hairline, width: 1.5),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: QibraNavy.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    // Reference reader header: accent book chip + the REAL
                    // location line; every action beside it is wired
                    // (bookmark toggle, prev/next in-corpus, copy-share,
                    // close). No narrator-chain or 'View details' — the
                    // corpus has no such data.
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: QibraNavy.emerald.withValues(alpha: 0.14),
                        border: Border.all(color: QibraNavy.emeraldDeep),
                      ),
                      child: const Icon(Icons.auto_stories_rounded,
                          size: 18, color: QibraNavy.emerald),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            hadith.bookName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: QibraNavy.emerald,
                                fontWeight: FontWeight.w800,
                                fontSize: 13),
                          ),
                          Text(
                            'Hadith ${hadith.hadithNumber}',
                            style: const TextStyle(
                                color: QibraNavy.textSecondary,
                                fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    Consumer(
                      builder: (context, ref, _) {
                        final isSaved =
                            ref.watch(isHadithBookmarkedProvider(hadith.id));
                        return IconButton(
                          tooltip: isSaved ? 'Remove bookmark' : 'Bookmark',
                          icon: Icon(
                            isSaved
                                ? Icons.bookmark_rounded
                                : Icons.bookmark_border_rounded,
                            color: isSaved
                                ? QibraNavy.gold
                                : QibraNavy.textSecondary,
                          ),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            ref
                                .read(hadithBookmarksProvider.notifier)
                                .toggleBookmark(hadith);
                          },
                        );
                      },
                    ),
                    IconButton(
                      tooltip: 'Previous hadith',
                      icon: const Icon(Icons.chevron_left_rounded,
                          color: QibraNavy.textSecondary),
                      onPressed: prevNumber == null
                          ? null
                          : () => openNeighbour(prevNumber),
                    ),
                    IconButton(
                      tooltip: 'Next hadith',
                      icon: const Icon(Icons.chevron_right_rounded,
                          color: QibraNavy.textSecondary),
                      onPressed: nextNumber == null
                          ? null
                          : () => openNeighbour(nextNumber),
                    ),
                    IconButton(
                      tooltip: 'Copy to share',
                      icon: const Icon(Icons.share_rounded,
                          color: QibraNavy.textSecondary),
                      onPressed: () {
                        final shareTranslation = hadithTextForLanguage(
                                hadith,
                                ref.read(hadithLanguageProvider)) ??
                            hadith.textEnglish;
                        final text =
                            '${hadith.textArabic}\n\n$shareTranslation\n\n— ${hadith.displayReference}';
                        Clipboard.setData(ClipboardData(text: text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Hadith copied to clipboard'),
                              backgroundColor: QibraNavy.surface),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded,
                          color: QibraNavy.textSecondary),
                      onPressed: () => Navigator.of(sheetContext).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(color: QibraNavy.textMuted, height: 1),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (hadith.hasArabic) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: QibraNavy.card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: QibraNavy.hairline),
                          ),
                          child: SelectableText(
                            hadith.textArabic,
                            textAlign: TextAlign.right,
                            style: AppArabicStyles.quranBold
                                .copyWith(
                                    color: QibraNavy.textPrimary,
                                    height: 1.8,
                                    fontSize: AppFontSize.arabicMedium *
                                        prefs.arabicScale),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      if (sheetLang == 'ar')
                        const SizedBox.shrink()
                      else if (sheetTranslation != null) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: QibraNavy.card,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: QibraNavy.hairline),
                          ),
                          child: SelectableText(
                            sheetTranslation,
                            textAlign:
                                sheetRtl ? TextAlign.right : TextAlign.start,
                            textDirection: sheetRtl
                                ? TextDirection.rtl
                                : TextDirection.ltr,
                            style: TextStyle(
                                color: QibraNavy.textPrimary,
                                fontSize: (sheetRtl ? 15 : 13.5) *
                                    prefs.translationScale,
                                height: sheetRtl ? 1.8 : 1.6),
                          ),
                        ),
                      ] else ...[
                        // Key-join found no text in this language for
                        // THIS hadith (e.g. French x Tirmidhi): say so,
                        // never substitute another translation silently.
                        Text(
                          'Verified translation unavailable for this language.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: QibraNavy.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                      // Reference authenticity banner — rendered ONLY when
                      // the corpus actually carries a grade for THIS row.
                      // UNKNOWN hadiths show no badge (data truth).
                      if (hadith.grade != HadithGrade.unknown) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color:
                                hadith.grade.color.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: hadith.grade.color
                                  .withValues(alpha: 0.35),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.verified_rounded,
                                  size: 18, color: hadith.grade.color),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Grade: ${hadith.grade.label}',
                                      style: const TextStyle(
                                          color: QibraNavy.textPrimary,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 12),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Source: ${hadith.bookName} (${hadith.hadithNumber})',
                                      style: const TextStyle(
                                          color: QibraNavy.textSecondary,
                                          fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      HadithMoreFromChapter(
                        hadith: hadith,
                        onOpen: (ctx, target) =>
                            _showHadithDetailSheet(ctx, target),
                      ),
                    ],
                  ),
                ),
              ),
              // Reference bottom rail: real prev/next through the corpus
              // + the EXISTING quick-settings sheet (split text scales AND
              // the Language row live there — same single source the list
              // bar opens; the detail sheet must not fork that sheet).
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: prevNumber == null
                            ? null
                            : () => openNeighbour(prevNumber),
                        icon:
                            const Icon(Icons.chevron_left_rounded, size: 18),
                        label: const Text('Previous',
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: QibraNavy.textPrimary,
                          side:
                              const BorderSide(color: QibraNavy.emeraldDeep),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      tooltip: 'Text size & language',
                      icon: const Icon(Icons.text_format_rounded,
                          color: QibraNavy.emerald),
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        _showQuickSettingsSheet(context);
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: nextNumber == null
                            ? null
                            : () => openNeighbour(nextNumber),
                        icon: const Icon(Icons.chevron_right_rounded,
                            size: 18),
                        label: const Text('Next',
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================
// HADITH CARD WIDGET
// ============================================================

class _HadithCard extends ConsumerWidget {
  final HadithModel hadith;
  final bool showArabic;
  final bool showTranslation;
  final VoidCallback onTap;

  const _HadithCard({
    required this.hadith,
    required this.showArabic,
    required this.showTranslation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isBookmarked = ref.watch(isHadithBookmarkedProvider(hadith.id));
    final language = ref.watch(hadithLanguageProvider);
    final rtl = language == 'ar' || language == 'ur';
    final translation =
        language == 'ar' ? null : hadithTextForLanguage(hadith, language);
    // World-class hadith pass (item 1): book-list cards follow the
    // persisted split scales.
    final prefs = ref.watch(hadithReadingPreferencesProvider);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: QibraNavy.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: QibraNavy.hairline),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Reference feed badge: solid emerald disc + number.
                Container(
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: QibraNavy.emeraldDeep,
                  ),
                  child: Text(
                    '${hadith.hadithNumber}',
                    style: const TextStyle(
                        color: QibraNavy.textPrimary,
                        fontWeight: FontWeight.w800,
                        fontSize: 10),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: hadith.grade.color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    hadith.grade.label,
                    style: TextStyle(
                        color: hadith.grade.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 10),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    isBookmarked
                        ? Icons.bookmark_rounded
                        : Icons.bookmark_border_rounded,
                    color: isBookmarked
                        ? QibraNavy.gold
                        : QibraNavy.textSecondary,
                    size: 20,
                  ),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    ref
                        .read(hadithBookmarksProvider.notifier)
                        .toggleBookmark(hadith);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.share_rounded,
                      color: QibraNavy.textSecondary, size: 18),
                  onPressed: () {
                    final shareText =
                        '${hadith.textArabic}\n\n${translation ?? hadith.textEnglish}\n\n— ${hadith.displayReference}';
                    Clipboard.setData(ClipboardData(text: shareText));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Hadith copied to clipboard'),
                          backgroundColor: QibraNavy.surface,
                          duration: Duration(seconds: 1)),
                    );
                  },
                ),
              ],
            ),
            if (showArabic && hadith.hasArabic) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: QibraNavy.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: QibraNavy.hairline),
                ),
                child: Text(
                  hadith.textArabic,
                  style: AppArabicStyles.quranBold.copyWith(
                      color: QibraNavy.textPrimary,
                      height: 1.7,
                      fontSize: AppFontSize.arabicMedium * prefs.arabicScale),
                  textAlign: TextAlign.right,
                ),
              ),
            ],
            if (language != 'ar' && showTranslation) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: QibraNavy.card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: QibraNavy.hairline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      language == 'ur' ? 'اردو ترجمہ' : HadithAvailability.label(language),
                      style: const TextStyle(
                          color: QibraNavy.emerald,
                          fontSize: 8.5,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5),
                      textDirection: language == 'ur'
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      textAlign: language == 'ur' ? TextAlign.right : TextAlign.start,
                    ),
                    const SizedBox(height: 4),
                    if (translation != null)
                      Text(
                        translation,
                        style: TextStyle(
                            color: QibraNavy.textPrimary,
                            fontSize: (rtl ? 14 : 12.5) *
                                prefs.translationScale,
                            height: rtl ? 1.7 : 1.5),
                        textDirection:
                            rtl ? TextDirection.rtl : TextDirection.ltr,
                        textAlign: rtl ? TextAlign.right : TextAlign.start,
                      )
                    else
                      Text(
                        'Verified translation unavailable for this language.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: QibraNavy.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
            ],
            if (hadith.chapterName.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Chapter: ${hadith.chapterName}',
                style: const TextStyle(color: QibraNavy.textSecondary, fontSize: 10),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
