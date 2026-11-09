// lib/features/hadith/presentation/hadith_book_screen.dart
// ============================================================
// QIBRA AI — HADITH BOOK DETAIL SCREEN (Flagship Luxury Reader)
// Complete Arabic + Urdu + English translations with chapter selector & search
// ============================================================

import 'package:flutter/material.dart';
import 'package:qibra_ai/shared/widgets/qibra_status.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:qibra_ai/core/design_system/app_typography.dart';
import 'package:qibra_ai/core/design_system/qibra_colors.dart';
import 'package:qibra_ai/core/design_system/qibra_navy.dart';
import 'package:qibra_ai/core/l10n/app_strings.dart';
import 'package:qibra_ai/core/utils/search_normalizer.dart';
import 'package:qibra_ai/shared/widgets/controls/app_switch_tile.dart';
import 'package:qibra_ai/shared/widgets/qibra_ui.dart';
import '../data/hadith_availability.dart';
import '../data/models/hadith_models.dart';
import '../data/services/hadith_database_service.dart';
import '../providers/hadith_provider.dart';
import '../providers/hadith_preferences_provider.dart';
import 'hadith_related_section.dart';
import 'package:qibra_ai/core/design_system/qibra_paper.dart';
import 'package:qibra_ai/features/quran/providers/reading_preferences_provider.dart';

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
  /// test/features/hadith/hadith_redesign_test.dart.
  @visibleForTesting
  static int? neighbourNumber(List<int> numbers, int from, int step) {
    final i = numbers.indexOf(from);
    if (i < 0) return null;
    final j = i + step;
    if (j < 0 || j >= numbers.length) return null;
    return numbers[j];
  }

  /// Top-class elevation (item 4b): the reader header's real position.
  /// 'of M' renders ONLY when M > 0 — totalHadiths is real book data
  /// (LocalBookInfo via getBookInfo); an unknown total honestly degrades
  /// to 'Hadith $number', never to a guessed total. Pure + static so the
  /// conditional is unit-pinned (neighbourNumber precedent).
  @visibleForTesting
  static String hadithPositionLabel(int number, int total) =>
      total > 0 ? 'Hadith $number of $total' : 'Hadith $number';

  /// Chapter-chip label (Pass H1). A book number the corpus does not
  /// name renders as the i18n honest fallback ('Book 0' for the
  /// sentinel group), never 'Ch 0: ' with a dangling colon and never an
  /// invented title. Pure + static in the neighbourNumber tradition so
  /// CI pins the rule without pumping the 234 MB corpus.
  @visibleForTesting
  static String chapterChipLabel(
      int number, String name, String unnamedLabel) {
    final trimmed = name.trim();
    return trimmed.isEmpty ? unnamedLabel : 'Ch $number: $trimmed';
  }

  /// `label · note · note` join over non-empty parts — null segments
  /// (undisclosed or uncounted) drop out silently instead of printing.
  static String _dotJoin(List<String?> parts) =>
      parts.whereType<String>().where((p) => p.isNotEmpty).join('  ·  ');

  @override
  ConsumerState<HadithBookScreen> createState() => _HadithBookScreenState();
}

class _HadithBookScreenState extends ConsumerState<HadithBookScreen> {
  int? _selectedChapterNumber;
  String _searchQuery = '';
  // H2-F: the search field became CONTROLLED — the old clear button
  // emptied the query but the uncontrolled TextField kept showing the
  // typed text. One controller, one truth.
  final TextEditingController _searchCtl = TextEditingController();
  // H2-D2: expansion state lives on the SCREEN (per card id) so it
  // survives scroll-away rebuilds — a card-local bool would reset.
  final Set<String> _expandedCards = <String>{};
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
    _searchCtl.dispose();
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

    // R (H2): the hadith book reader joins Pass D2's paper scope — the
    // only hadith surface that reads Settings → Reading Theme (persisted
    // in the shared reading store). Home and collections stay navy.
    // Night: QibraPaper.scope returns the child UNWRAPPED — the default
    // path gains literally nothing (D2 identity contract).
    return QibraPaper.scope(
      active:
          ref.watch(readingPreferencesProvider.select((p) => p.isPaper)),
      child: Builder(
        builder: (pageContext) {
          final pageBg = QibraPaper.isActive(pageContext)
              ? QibraColors.of(pageContext).background
              : QibraNavy.canvas;
          return Scaffold(
      backgroundColor: QibraNavy.canvas,
      body: SafeArea(
        child: CustomScrollView(
          controller: _scroll,
          physics: const BouncingScrollPhysics(),
          slivers: [
            // 1. APP BAR (+ D3's one sticky controls row as its bottom)
            _buildAppBar(context, chaptersAsync.value ?? const []),

            // 2. BOOK HERO HEADER — stats merged into its meta line (D3)
            _buildBookHeader(),

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
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: QibraStatus.empty(title: 'No hadiths found.'),
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
                        final card = HadithCard(
                          hadith: h,
                          showArabic: _showArabic,
                          showTranslation: _showTranslation,
                          positionLabel: HadithBookScreen.hadithPositionLabel(
                              h.hadithNumber, widget.book.totalHadiths),
                          expanded: _expandedCards.contains(h.id),
                          onToggleExpand: () => setState(() {
                            if (!_expandedCards.add(h.id)) {
                              _expandedCards.remove(h.id);
                            }
                          }),
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
              // D6: the shared status widget carries loading — a real
              // spinner; the feature keeps its no-skeleton-sweep restraint.
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(48),
                  child: Center(
                    child: QibraStatus(
                        kind: QibraStatusKind.loading),
                ),
                ),
              ),
              error: (error, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  // D6: shared error state + a REAL retry (the old block
                  // showed the message and left the reader stuck; the
                  // corpus providers are cheap to re-fetch).
                  child: QibraStatus.error(
                    title: 'Failed to load hadiths',
                    message: error.toString(),
                    onRetry: () {
                      ref.invalidate(hadithsProvider(params));
                      ref.invalidate(hadithChaptersProvider(widget.book.slug));
                    },
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
        },
      ),
    )
  }

  // ────────────────────────────────────────────────────────
  // 1. APP BAR
  // ────────────────────────────────────────────────────────
  Widget _buildAppBar(BuildContext context, List<HadithChapter> chapters) {
    return SliverAppBar(
      backgroundColor: QibraNavy.canvas,
      pinned: true,
      elevation: 0,
      leading: SizedBox(
        width: 48,
        height: 48,
        child: IconButton(
          tooltip: AppStrings.of(context).tooltipBack,
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: QibraNavy.textPrimary, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      title: Text(
        widget.book.name,
        style: AppTextStyles.titleSmall.copyWith(
            color: QibraNavy.textPrimary,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5),
      ),
      centerTitle: true,
      // D3 — the book's ONE sticky row. [search | chapter filter |
      // settings] rides the pinned bar's bottom so the controls survive
      // scrolling; the old scroll-away controls sliver (search above a
      // chapter chip rail) is retired. Settings left the action slot on
      // purpose: one row, one place, per the H2 brief.
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(66),
        child: _buildStickyControlsRow(context, chapters),
      ),
    );
  }

  static const String _allChaptersKey = '__all_chapters__';

  Widget _buildStickyControlsRow(
      BuildContext context, List<HadithChapter> chapters) {
    final strings = AppStrings.of(context);
    return Container(
      color: QibraNavy.canvas,
      padding: const EdgeInsets.fromLTRB(12, 0, 6, 8),
      child: Row(
        children: [
          Expanded(
            child: HadithSearchField(
              controller: _searchCtl,
              query: _searchQuery,
              hint: 'Search hadith number or text in this book...',
              onChanged: (v) => setState(() => _searchQuery = v),
            ),
          ),
          // Chapter filter — the chip rail condensed into a dropdown.
          // The GOLD icon marks an ACTIVE (narrowed) view — accent on
          // state, never on chrome.
          PopupMenuButton<String>(
            tooltip: strings.tooltipFilterChapters,
            enabled: chapters.isNotEmpty,
            position: PopupMenuPosition.under,
            color: QibraNavy.card,
            icon: Icon(
              Icons.filter_alt_rounded,
              color: _selectedChapterNumber == null
                  ? QibraNavy.textSecondary
                  : QibraNavy.gold,
              size: 22,
            ),
            onSelected: (v) => setState(() => _selectedChapterNumber =
                v == _allChaptersKey ? null : int.parse(v)),
            itemBuilder: (ctx) => [
              PopupMenuItem(
                value: _allChaptersKey,
                child: Text(strings.hadithAllChapters),
              ),
              for (final ch in chapters)
                PopupMenuItem(
                  value: '${ch.number}',
                  child: Text(HadithBookScreen.chapterChipLabel(
                      ch.number, ch.name, strings.hadithKitabLabel(ch.number))),
                ),
            ],
          ),
          IconButton(
            tooltip: strings.tooltipReadingSettings,
            icon: const Icon(Icons.display_settings_rounded,
                color: QibraNavy.gold, size: 20),
            onPressed: () => _showQuickSettingsSheet(context),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────────────────────────
  // 2. BOOK HEADER
  // ────────────────────────────────────────────────────────
  Widget _buildBookHeader() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        // Material (not Container) so the IconButton's ink below paints
        // ON this surface — colored-Container ink blocker, device-log fix.
        child: Material(
          color: QibraNavy.card,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
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
                          style: AppTextStyles.titleSmall.copyWith(
                              color: QibraNavy.textPrimary,
                              fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.book.author,
                          style: AppTextStyles.labelSmall.copyWith(
                              color: QibraNavy.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // D3: stats merge into a meta LINE. The chip trio repeated
              // numbers the list already shows and its third chip was a
              // 'Grade UNKNOWN' prop — an honest book header states the
              // totals it actually has; per-hadith grades speak for
              // themselves on every card.
              Text(
                '${widget.book.totalHadiths} hadiths \u00b7 ${widget.book.totalChapters} chapters',
                style: AppTextStyles.labelXSmall.copyWith(
                    color: QibraNavy.textMuted),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────────────────────────
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
        // Pass H1 parity disclosure, per BOOK: translation depth for
        // this row, computed from the loaded corpus. Read (not watched)
        // once per sheet open — this builder is outside the widget's
        // build scope; while the DB is still initializing the note is
        // simply absent, the sheet never renders a placeholder number.
        final cov = ref.read(hadithLanguageCoverageProvider).valueOrNull;
        final sheetStrings = AppStrings.of(context);
        String? depthNote(String code) {
          if (!HadithAvailability.hasBook(code, widget.book.slug)) {
            return sheetStrings.hadithNotAvailableForBook;
          }
          final c = cov?[widget.book.slug]?[code];
          if (c == null) return null;
          final pct =
              HadithAvailability.coveragePercent(c.nonEmpty, c.total);
          return pct >= 100 ? null : sheetStrings.hadithCoverageOfBook(pct);
        }
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
                      HadithBookScreen._dotJoin([
                        option.label,
                        option.note,
                        depthNote(option.code),
                      ]),
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
                          title: Text(AppStrings.of(context).arabicTextSection,
                              style: AppTextStyles.bodyMedium.copyWith(
                                  color: QibraNavy.textPrimary)),
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
                              style: AppTextStyles.bodyMedium.copyWith(
                                  color: QibraNavy.textPrimary),
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
      _searchCtl.clear();
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
        SnackBar(
            content: Text(AppStrings.of(context).collectionStillLoading)),
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
        SnackBar(
            content:
                Text(AppStrings.of(context).thatBookmarkNotBundled)),
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
        // Material body on the transparent modal: header IconButtons and
        // the FilledButton paint ink HERE, not behind a colored box
        // (device-log fix 1; same 2026-09-02 QibraCard precedent).
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.85,
          ),
          child: Material(
            color: QibraNavy.card,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            child: DecoratedBox(
              decoration: const BoxDecoration(
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
                            style: AppTextStyles.bodyMedium.copyWith(
                                color: QibraNavy.emerald,
                                fontWeight: FontWeight.w800),
                          ),
                          Text(
                            HadithBookScreen.hadithPositionLabel(
                                hadith.hadithNumber,
                                widget.book.totalHadiths),
                            style: AppTextStyles.labelSmall.copyWith(
                                color: QibraNavy.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Consumer(
                      builder: (context, ref, _) {
                        final isSaved =
                            ref.watch(isHadithBookmarkedProvider(hadith.id));
                        return IconButton(
                          tooltip: isSaved
                              ? AppStrings.of(context)
                                  .tooltipRemoveBookmark
                              : AppStrings.of(context).tooltipBookmark,
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
                      tooltip: AppStrings.of(context).tooltipPrevHadith,
                      icon: const Icon(Icons.chevron_left_rounded,
                          color: QibraNavy.textSecondary),
                      onPressed: prevNumber == null
                          ? null
                          : () {
                              // Elevation item 5: light impact on the
                              // tap itself (disabled state stays silent).
                              HapticFeedback.lightImpact();
                              openNeighbour(prevNumber);
                            },
                    ),
                    IconButton(
                      tooltip: AppStrings.of(context).tooltipNextHadith,
                      icon: const Icon(Icons.chevron_right_rounded,
                          color: QibraNavy.textSecondary),
                      onPressed: nextNumber == null
                          ? null
                          : () {
                              HapticFeedback.lightImpact();
                              openNeighbour(nextNumber);
                            },
                    ),
                    IconButton(
                      tooltip: AppStrings.of(context).tooltipCopyToShare,
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
                        HapticFeedback.lightImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(AppStrings.of(context).hadithCopiedToClipboard),
                              backgroundColor: QibraNavy.surface),
                        );
                      },
                    ),
                    IconButton(
                      tooltip: AppStrings.of(context).close,
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
                            style: AppTextStyles.bodyMedium.copyWith(
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
                                      style: AppTextStyles.bodySmall.copyWith(
                                          color: QibraNavy.textPrimary,
                                          fontWeight: FontWeight.w800),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Source: ${hadith.bookName} (${hadith.hadithNumber})',
                                      style: AppTextStyles.labelSmall.copyWith(
                                          color: QibraNavy.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // Pass H1: an ungraded hadith says so. The old
                        // silence-read-as-clean gap is closed — the row
                        // is NEVER blank and the grade is NEVER guessed.
                        // Data truth (H1 census): the corpus carries
                        // grade tags for all five Sunan/Muwatta
                        // collections (Tirmidhi 3954/3998, Abu Dawud
                        // 5274/5274, Nasa'i 5758/5765, Ibn Majah
                        // 4341/4343, Malik 1858/1858) — the line shows
                        // exactly where a tag is absent there (Nasa'i 7,
                        // Ibn Majah 2, Tirmidhi 44). Bukhari/Muslim rows
                        // ride the pre-existing collection-level Sahih
                        // rule (untouched by this pass), so they show
                        // the banner, not this line.
                        const SizedBox(height: 14),
                        Text(
                          AppStrings.of(context).hadithGradeNotRecorded,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: QibraNavy.textSecondary,
                            fontStyle: FontStyle.italic,
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
                        label: Text(AppStrings.of(context).previous,
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
                      tooltip: AppStrings.of(context).tooltipTextSizeLanguage,
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
                        label: Text(AppStrings.of(context).next,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            ),
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
// HADITH SEARCH FIELD (H2-F — the fill-bug carrier, RENDER-pinned)
// ============================================================

/// The book's search input, extracted as a public widget so F3 can PAINT
/// it: the bug was a fill set to a TEXT token (QibraNavy.textPrimary —
/// a cream slab with a cream caret), exactly the class a source grep can
/// hide forever. A painted InputDecoration cannot. Controlled by the
/// screen so clearing resets the field itself, not just the query.
class HadithSearchField extends StatelessWidget {
  const HadithSearchField({
    super.key,
    required this.controller,
    required this.query,
    required this.hint,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String query;
  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    return TextField(
      controller: controller,
      style: AppTextStyles.inputText.copyWith(
          color: colors.textPrimary, fontSize: 13.5),
      decoration: InputDecoration(
        filled: true,
        fillColor: colors.cardMuted,
        hintText: hint,
        hintStyle: AppTextStyles.inputHint.copyWith(
            color: colors.textTertiary, fontSize: 11.5),
        prefixIcon:
            const Icon(Icons.search_rounded, color: QibraNavy.gold, size: 18),
        suffixIcon: query.isNotEmpty
            ? IconButton(
                tooltip: AppStrings.of(context).tooltipClearSearch,
                icon: const Icon(Icons.clear_rounded,
                    color: QibraNavy.textSecondary, size: 16),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
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
      onChanged: onChanged,
    );
  }
}

// ============================================================
// HADITH CARD WIDGET
// ============================================================

/// H2-D1 — the hadith list card with the advance anatomy, top to bottom:
/// number badge → Arabic block → ornament divider → translation → meta
/// row. H2-D2 — a body longer than the line budget renders collapsed
/// behind a localized 'Read full hadith' expander; the state lives on
/// the screen (survives scroll-away rebuilds) and copy / bookmark
/// always act on the FULL hadith, collapsed or not.
///
/// Public so the pass's render pins pump the REAL card composition
/// (HadithGhostIconButton precedent). Every color rides QibraColors
/// under the screen scope — R2's QibraPaper will resolve textPrimary to
/// ink and textSecondary to inkSoft WITHOUT a single change here; the
/// card never hardcodes either family — F2 finished: this file holds
/// zero raw text-style constructions of any shape.
class HadithCard extends ConsumerWidget {
  const HadithCard({
    super.key,
    required this.hadith,
    required this.showArabic,
    required this.showTranslation,
    required this.positionLabel,
    required this.expanded,
    required this.onToggleExpand,
    required this.onTap,
  });

  final HadithModel hadith;
  final bool showArabic;
  final bool showTranslation;
  /// 'Hadith N of M' — or the honest 'Hadith N' when M is unknown.
  /// Built by the screen through HadithBookScreen.hadithPositionLabel
  /// so the pure formatter stays the single source.
  final String positionLabel;
  final bool expanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onTap;

  /// D2's budget, as a constant so the test can name it: more than
  /// EIGHT rendered body lines (Arabic + translation together) earns
  /// the expander. The measure is the laid-out count, never a
  /// character heuristic.
  static const int kHadithCollapseLineBudget = 8;

  @visibleForTesting
  static bool collapseFor(int bodyLines) =>
      bodyLines > kHadithCollapseLineBudget;

  /// Laid-out line count of one body text at [width] with its FINAL
  /// style (TextPainter, maxLines null — a short text is measured
  /// honestly, not guessed). One extra layout per text per build,
  /// inside the lazy SliverList — the D7 cost note in the pass report.
  @visibleForTesting
  static int laidLines(String text, TextStyle style, double width,
      TextDirection dir) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: dir,
      textWidthBasis: TextWidthBasis.longestLine,
    );
    tp.layout(maxWidth: width);
    final n = tp.computeLineMetrics().length;
    tp.dispose();
    return n;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = QibraColors.of(context);
    final isBookmarked = ref.watch(isHadithBookmarkedProvider(hadith.id));
    final language = ref.watch(hadithLanguageProvider);
    final rtl = language == 'ur' || language == 'ar';
    final translation =
        language == 'ar' ? null : hadithTextForLanguage(hadith, language);
    // The persisted split scales drive both bodies (world-class pass,
    // item 1 — unchanged wiring).
    final prefs = ref.watch(hadithReadingPreferencesProvider);

    // D1(b): the bundled Amiri family, RTL, leading inside the
    // 1.85–2.0 anatomy band; paper=ink / navy=textPrimary resolved by
    // the theme, not by this file.
    final arabicStyle = AppArabicStyles.quranBold.copyWith(
      color: colors.textPrimary,
      height: 1.9,
      fontSize: AppFontSize.arabicMedium * prefs.arabicScale,
    );
    // D1(d): translation on the soft body ink at leading 1.6.
    final translationStyle = AppTextStyles.bodyMedium.copyWith(
      color: colors.textSecondary,
      fontSize: (rtl ? 14 : 12.5) * prefs.translationScale,
      height: 1.6,
    );

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.all(12), // D4 rhythm: 12 in-card
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: colors.border),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // card padding 12×2 + block padding 12×2 = 48 of chrome.
            final textWidth = constraints.maxWidth - 48.0;
            var bodyLines = 0;
            final showArabicBlock = showArabic && hadith.hasArabic;
            final showTranslationBlock =
                language != 'ar' && showTranslation;
            if (showArabicBlock) {
              bodyLines += laidLines(
                  hadith.textArabic, arabicStyle, textWidth,
                  TextDirection.rtl);
            }
            if (showTranslationBlock && translation != null) {
              bodyLines += laidLines(translation, translationStyle,
                  textWidth, rtl ? TextDirection.rtl : TextDirection.ltr);
            }
            final collapse = !expanded && collapseFor(bodyLines);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // (a) number badge — compact rounded square, HAIRLINE
                // BORDER, no fill: F1's bug class remembered.
                Container(
                  key: const ValueKey('hadith-card-badge'),
                  width: 26,
                  height: 26,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: colors.border),
                  ),
                  child: Text(
                    '${hadith.hadithNumber}',
                    style: AppTextStyles.labelSmall.copyWith(
                        color: colors.textSecondary,
                        fontWeight: FontWeight.w800),
                  ),
                ),
                // (b) Arabic matn — the cream slab under paper, navy
                // cardMuted under night; same token, no second truth.
                if (showArabicBlock) ...[
                  const SizedBox(height: 10),
                  Container(
                    key: const ValueKey('hadith-card-arabic'),
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: colors.cardMuted,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      hadith.textArabic,
                      style: arabicStyle,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      maxLines: collapse ? 4 : null,
                      overflow:
                          collapse ? TextOverflow.ellipsis : null,
                    ),
                  ),
                ],
                // (c) ornament divider — hairline + centered 3px
                // diamond in the BORDER token; gold stays for active
                // states only (design-rules lock).
                Padding(
                  key: const ValueKey('hadith-card-ornament'),
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                          child: Container(
                              height: 1, color: colors.border)),
                      const SizedBox(width: 8),
                      RotatedBox(
                        quarterTurns: 1,
                        child:
                            Container(width: 3, height: 3, color: colors.border),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Container(
                              height: 1, color: colors.border)),
                    ],
                  ),
                ),
                // (d) translation block (language-driven since Phase B —
                // the one-block semantics the redesign pins stay).
                if (showTranslationBlock) ...[
                  SizedBox(
                    key: const ValueKey('hadith-card-translation'),
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          language == 'ur'
                              ? '\u0627\u0631\u062f\u0648 \u062a\u0631\u062c\u0645\u06c1'
                              : HadithAvailability.label(language),
                          style: AppTextStyles.labelXSmall.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5),
                          textDirection: language == 'ur'
                              ? TextDirection.rtl
                              : TextDirection.ltr,
                          textAlign: language == 'ur'
                              ? TextAlign.right
                              : TextAlign.start,
                        ),
                        const SizedBox(height: 4),
                        if (translation != null)
                          Text(
                            translation,
                            style: translationStyle,
                            textDirection: rtl
                                ? TextDirection.rtl
                                : TextDirection.ltr,
                            textAlign:
                                rtl ? TextAlign.right : TextAlign.start,
                            maxLines: collapse ? 4 : null,
                            overflow:
                                collapse ? TextOverflow.ellipsis : null,
                          )
                        else
                          Text(
                            'Verified translation unavailable for this language.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: colors.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
                // D2 expander — while collapsed; the collapse twin only
                // when THIS card actually has more to show.
                if (collapse)
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: onToggleExpand,
                      icon: const Icon(Icons.expand_more_rounded, size: 18),
                      label: Text(
                        AppStrings.of(context).readFullHadith,
                        style: AppTextStyles.labelMedium.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  )
                else if (expanded && collapseFor(bodyLines))
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: onToggleExpand,
                      icon: const Icon(Icons.expand_less_rounded, size: 18),
                      label: Text(
                        AppStrings.of(context).showLessHadith,
                        style: AppTextStyles.labelMedium.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                // (e) meta row — Wrap so 320dp folds, never overflows:
                // chapter pill, position, grade (honest-null), then the
                // real actions (tooltips = the a11y census contract).
                const SizedBox(height: 8),
                Wrap(
                  key: const ValueKey('hadith-card-meta'),
                  spacing: 8,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (hadith.chapterNumber > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: colors.border)),
                        child: Text(
                          AppStrings.of(context)
                              .hadithChapterShort(hadith.chapterNumber),
                          style: AppTextStyles.labelSmall.copyWith(
                              color: colors.textTertiary),
                        ),
                      ),
                    Text(
                      positionLabel,
                      style: AppTextStyles.labelSmall.copyWith(
                          color: colors.textTertiary),
                    ),
                    if (hadith.grade != HadithGrade.unknown)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color:
                              hadith.grade.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          hadith.grade.label,
                          style: AppTextStyles.labelSmall.copyWith(
                              color: hadith.grade.color,
                              fontWeight: FontWeight.w700),
                        ),
                      )
                    else
                      Text(
                        AppStrings.of(context).hadithGradeNotRecorded,
                        style: AppTextStyles.labelSmall.copyWith(
                            color: colors.textTertiary,
                            fontStyle: FontStyle.italic),
                      ),
                    IconButton(
                      tooltip: isBookmarked
                          ? AppStrings.of(context).tooltipRemoveBookmark
                          : AppStrings.of(context).tooltipBookmark,
                      icon: Icon(
                        isBookmarked
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                        color: isBookmarked
                            ? QibraNavy.gold
                            : colors.textSecondary,
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
                      tooltip: AppStrings.of(context).tooltipCopyToShare,
                      icon: Icon(Icons.share_rounded,
                          color: colors.textSecondary, size: 18),
                      onPressed: () {
                        // D2 honesty: the CLIPBOARD carries the FULL
                        // hadith even while the card shows four lines.
                        final shareText =
                            '${hadith.textArabic}\n\n${translation ?? hadith.textEnglish}\n\n\u2014 ${hadith.displayReference}';
                        Clipboard.setData(ClipboardData(text: shareText));
                        HapticFeedback.lightImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(AppStrings.of(context)
                                  .hadithCopiedToClipboard),
                              backgroundColor: QibraNavy.surface,
                              duration: const Duration(seconds: 1)),
                        );
                      },
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
