// lib/features/quran/presentation/surah_reader_screen.dart
// ============================================================
// QIBRA AI — SURAH READER (Stage B rewrite, midnight navy)
//
// What changed vs the legacy screen (audit findings):
//  • 76 hardcoded hexes -> QibraColors tokens (theme-driven:
//    navy by default, sanctioned ivory when the app theme is light).
//  • Deleted the floating audio-player bar: it carried a mic chip,
//    skip controls and fabricated 00:09/01:01 timestamps for audio
//    that is NOT bundled. The honesty notice now lives as plain
//    text in the reading-settings sheet (no fake player chrome).
//  • Deleted dead affordances: no-op search/bookmark appbar icons
//    (they now route to the real screens), the font-family pill
//    (labelled with the Amiri font that is not bundled as a local
//    asset) and the empty agenda pill.
//  • Deleted the 'Tafsir' mode tab — the reader has no tafsir
//    data; the verified Tafseer screen is reachable from every
//    ayah through the options sheet.
//  • Header shows REAL metadata (revelation type, ayah count,
//    starting juz/page) instead of the hardcoded 'Juz 1 • Page 1'.
//  • Tapping an ayah opens the real options sheet (copy / share /
//    note / bookmark / tafsir / AI explain); the row bookmark
//    toggle writes to the real bookmarks provider.
//  • Loading/error go through QibraStatus (skeleton + retry).
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/qibra_colors.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../shared/widgets/controls/app_switch_tile.dart';
import '../../../shared/widgets/qibra_status.dart';
import '../../../shared/widgets/qibra_ui.dart';
import '../data/models/quran_models.dart';
import '../providers/quran_provider.dart' hide readingProgressProvider;
import '../providers/reading_preferences_provider.dart';
import 'ayah_options_sheet.dart';

class SurahReaderScreen extends ConsumerStatefulWidget {
  const SurahReaderScreen({
    super.key,
    required this.surahNumber,
    this.initialAyah,
  });

  final int surahNumber;
  final int? initialAyah;

  @override
  ConsumerState<SurahReaderScreen> createState() => _SurahReaderScreenState();
}

class _SurahReaderScreenState extends ConsumerState<SurahReaderScreen> {
  static const _tabs = ['Arabic', 'Translation', 'Transliteration'];

  /// Text-size stops offered by the pill and the settings sheet.
  static const scales = <double>[1.0, 1.25, 1.5];

  String _activeTab = 'Arabic';
  final ScrollController _scroll = ScrollController();
  bool _didInitialScroll = false;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _stepFontScale() {
    HapticFeedback.selectionClick();
    final prefs = ref.read(readingPreferencesProvider);
    final i = scales.indexOf(prefs.fontScale);
    ref
        .read(readingPreferencesProvider.notifier)
        .setFontScale(scales[(i + 1) % scales.length]);
  }

  void _jumpToInitialAyah(SurahModel surah) {
    if (_didInitialScroll || widget.initialAyah == null) return;
    _didInitialScroll = true;
    final idx = surah.ayahs
        .indexWhere((a) => a.numberInSurah == widget.initialAyah);
    if (idx <= 0) return; // already near the top
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      // Approximate per-item height; lands close enough to fine-tune.
      _scroll.jumpTo((idx + 1) * 184.0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final surahAsync = ref.watch(surahDetailProvider(widget.surahNumber));
    final prefs = ref.watch(readingPreferencesProvider);
    final colors = QibraColors.of(context);
    final surah = surahAsync.value;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: QibraAppBar(
        title: surah?.name ?? 'Surah ${widget.surahNumber}',
        subtitle: surah == null ? null : 'Surah ${surah.number} of 114',
        actions: [
          IconButton(
            tooltip: 'Search the Quran',
            icon: const Icon(Icons.search_rounded),
            onPressed: () => context.go(AppRoutes.quranSearch),
          ),
          IconButton(
            tooltip: 'Bookmarks',
            icon: const Icon(Icons.bookmark_border_rounded),
            onPressed: () => context.push('/quran/bookmarks'),
          ),
          IconButton(
            tooltip: 'Reading settings',
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => _showSettingsSheet(context),
          ),
        ],
      ),
      body: surahAsync.when(
        data: (s) {
          if (s == null) {
            return QibraStatus.empty(
              title: 'Surah not found',
              message:
                  'Surah ${widget.surahNumber} is not in the bundled '
                  'Quran data.',
            );
          }
          _jumpToInitialAyah(s);
          return Column(
            children: [
              _ModeTabs(
                tabs: _tabs,
                active: _activeTab,
                fontScale: prefs.fontScale,
                onSelect: (tab) {
                  HapticFeedback.selectionClick();
                  setState(() => _activeTab = tab);
                },
                onSizeStep: _stepFontScale,
              ),
              Expanded(
                // ListView.builder keeps long surahs (286 ayahs) at
                // O(1) construction per frame.
                child: ListView.builder(
                  controller: _scroll,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  itemCount: s.ayahs.length + 3,
                  itemBuilder: (context, index) {
                    final showBismillah =
                        widget.surahNumber != 9 && widget.surahNumber != 1;
                    if (index == 0) return _SurahHeader(surah: s);
                    if (index == 1 && showBismillah) {
                      return const _BismillahHeader();
                    }
                    final ayahIndex = index - (showBismillah ? 2 : 1);
                    if (ayahIndex < s.ayahs.length) {
                      return _AyahCard(
                        surah: s,
                        ayah: s.ayahs[ayahIndex],
                        activeTab: _activeTab,
                        prefs: prefs,
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child:
                          _TranslationCompareCard(ayah: s.ayahs.first),
                    );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              QibraStatus.skeleton(height: 96),
              const SizedBox(height: 12),
              QibraStatus.skeleton(height: 220),
              const SizedBox(height: 12),
              QibraStatus.skeleton(height: 220),
            ],
          ),
        ),
        error: (e, st) => QibraStatus.error(
          title: 'Could not open this surah',
          message: 'The bundled Quran data could not be read.',
          onRetry: () => ref
              .invalidate(surahDetailProvider(widget.surahNumber)),
        ),
      ),
    );
  }

  void _showSettingsSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: QibraColors.of(context).card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _ReadingSettingsSheet(),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Mode tabs + text-size control
// ─────────────────────────────────────────────────────────────

class _ModeTabs extends StatelessWidget {
  const _ModeTabs({
    required this.tabs,
    required this.active,
    required this.fontScale,
    required this.onSelect,
    required this.onSizeStep,
  });

  final List<String> tabs;
  final String active;
  final double fontScale;
  final ValueChanged<String> onSelect;
  final VoidCallback onSizeStep;

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Row(
        children: [
          for (final tab in tabs)
            GestureDetector(
              onTap: () => onSelect(tab),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color:
                          active == tab ? colors.primary : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  tab,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: active == tab
                        ? colors.textPrimary
                        : colors.textSecondary,
                    fontWeight:
                        active == tab ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          const Spacer(),
          InkWell(
            onTap: onSizeStep,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 13,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.format_size_rounded,
                      size: 16, color: colors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    fontScale == 1.0
                        ? 'Aa'
                        : 'Aa+${((fontScale - 1) * 100).round()}',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Surah header — real metadata only
// ─────────────────────────────────────────────────────────────

class _SurahHeader extends StatelessWidget {
  const _SurahHeader({required this.surah});

  final SurahModel surah;

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    final first = surah.ayahs.isNotEmpty ? surah.ayahs.first : null;
    final meta = <String>[
      surah.revelationType == 'Meccan' ? 'Meccan' : 'Medinan',
      '${surah.numberOfAyahs} ayahs',
      if (first != null) 'Juz ${first.juz}',
      if (first != null) 'from page ${first.page}',
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: QibraCard(
        child: Column(
          children: [
            Text(
              surah.nameArabic,
              style: AppArabicStyles.surahName
                  .copyWith(color: colors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              '${surah.name} — ${surah.englishNameTranslation}',
              textAlign: TextAlign.center,
              style: AppTextStyles.titleSmall.copyWith(
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Container(height: 1, color: colors.border),
            const SizedBox(height: 8),
            Text(
              meta.join('  ·  '),
              style: AppTextStyles.labelSmall.copyWith(
                color: colors.textTertiary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BismillahHeader extends StatelessWidget {
  const _BismillahHeader();

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Text(
          'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
          style: AppArabicStyles.bismillah
              .copyWith(color: colors.textSecondary),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Ayah card
// ─────────────────────────────────────────────────────────────

class _AyahCard extends ConsumerWidget {
  const _AyahCard({
    required this.surah,
    required this.ayah,
    required this.activeTab,
    required this.prefs,
  });

  final SurahModel surah;
  final AyahModel ayah;
  final String activeTab;
  final ReadingPreferences prefs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = QibraColors.of(context);
    final bookmarked = ref.watch(
      isBookmarkedProvider((surah: surah.number, ayah: ayah.number)),
    );
    final strings = AppStrings.of(context);

    final arabicSize =
        AppFontSize.arabicMedium * prefs.fontScale;
    final showTranslation = activeTab != 'Arabic' && prefs.showTranslation;
    final showTranslit =
        activeTab == 'Transliteration' && prefs.showTransliteration;
    final translation = _translationFor(ayah, prefs);
    final roman = ayah.translationRoman?.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: QibraCard(
        onTap: () => showAyahOptions(
        context: context,
        surahNumber: surah.number,
        ayahNumber: ayah.number,
        surahName: surah.name,
        ayah: ayah,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: colors.primarySoft,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.border),
                ),
                child: Center(
                  child: Text(
                    '${ayah.numberInSurah}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: bookmarked ? 'Remove bookmark' : 'Bookmark ayah',
                onPressed: () {
                  HapticFeedback.selectionClick();
                  ref.read(bookmarksProvider.notifier).toggleBookmark(
                        BookmarkModel(
                          surahNumber: surah.number,
                          ayahNumber: ayah.number,
                          surahName: surah.name,
                          ayahText: ayah.text,
                          bookmarkedAt: DateTime.now(),
                        ),
                      );
                },
                icon: Icon(
                  bookmarked
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_border_rounded,
                  color: bookmarked ? colors.primary : colors.textTertiary,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            ayah.text,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: AppArabicStyles.quranMedium.copyWith(
              fontSize: arabicSize,
              height: prefs.lineHeight,
              color: colors.textPrimary,
            ),
          ),
          if (showTranslit) ...[
            const SizedBox(height: 8),
            Text(
              (roman != null && roman.isNotEmpty)
                  ? roman
                  : 'Transliteration is not bundled for this ayah.',
              style: AppTextStyles.bodySmall.copyWith(
                color: colors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (showTranslation) ...[
            const SizedBox(height: 8),
            Text(
              translation ?? strings.translationUnavailable,
              style: AppTextStyles.bodyMedium.copyWith(
                color: colors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
            ],
          ),
        ),
      );
  }

  static String? _translationFor(
    AyahModel ayah,
    ReadingPreferences prefs,
  ) {
    final id = prefs.translationId.toLowerCase();
    if (id.startsWith('ur')) {
      final urdu = ayah.translationUrdu?.trim();
      return (urdu == null || urdu.isEmpty) ? null : urdu;
    }
    final english = ayah.translation?.trim();
    return (english == null || english.isEmpty) ? null : english;
  }
}

// ─────────────────────────────────────────────────────────────
// Bundled-translation comparison (EN + UR side by side)
// ─────────────────────────────────────────────────────────────

class _TranslationCompareCard extends StatelessWidget {
  const _TranslationCompareCard({required this.ayah});

  final AyahModel ayah;

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    final strings = AppStrings.of(context);
    final english = ayah.translation?.trim();
    final urdu = ayah.translationUrdu?.trim();
    return QibraCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.language_rounded, size: 16, color: colors.primary),
              const SizedBox(width: 6),
              Text(
                'Bundled translations — first ayah',
                style: AppTextStyles.labelMedium.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _TranslationColumn(
                  lang: 'English',
                  text: (english != null && english.isNotEmpty)
                      ? english
                      : strings.translationUnavailable,
                  isRtl: false,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _TranslationColumn(
                  lang: 'اردو',
                  text: (urdu != null && urdu.isNotEmpty)
                      ? urdu
                      : strings.translationUnavailable,
                  isRtl: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TranslationColumn extends StatelessWidget {
  const _TranslationColumn({
    required this.lang,
    required this.text,
    required this.isRtl,
  });

  final String lang;
  final String text;
  final bool isRtl;

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.cardMuted,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment:
            isRtl ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            lang,
            style: AppTextStyles.labelSmall.copyWith(
              color: colors.textSecondary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            textAlign: isRtl ? TextAlign.right : TextAlign.left,
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            style: isRtl
                ? AppArabicStyles.quranSmall
                    .copyWith(color: colors.textPrimary)
                : AppTextStyles.bodySmall
                    .copyWith(color: colors.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Reading settings (all switches write real preferences)
// ─────────────────────────────────────────────────────────────

class _ReadingSettingsSheet extends ConsumerWidget {
  const _ReadingSettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = QibraColors.of(context);
    final prefs = ref.watch(readingPreferencesProvider);
    final strings = AppStrings.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reading settings',
              style: AppTextStyles.titleMedium.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            AppSwitchListTile(
              title: const Text('Show translation'),
              subtitle: Text(
                'Display the bundled translation under the Arabic.',
                style: AppTextStyles.bodySmall
                    .copyWith(color: colors.textSecondary),
              ),
              value: prefs.showTranslation,
              onChanged: (v) => ref
                  .read(readingPreferencesProvider.notifier)
                  .setShowTranslation(v),
            ),
            AppSwitchListTile(
              title: const Text('Show transliteration'),
              subtitle: Text(
                'Only where a roman edition exists in the bundle.',
                style: AppTextStyles.bodySmall
                    .copyWith(color: colors.textSecondary),
              ),
              value: prefs.showTransliteration,
              onChanged: (v) => ref
                  .read(readingPreferencesProvider.notifier)
                  .setShowTransliteration(v),
            ),
            const SizedBox(height: 4),
            Text(
              'Text size',
              style: AppTextStyles.labelMedium.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final scale in _SurahReaderScreenState.scales)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: QibraChip(
                      label: scale == 1.0
                          ? 'Default'
                          : '+${((scale - 1) * 100).round()}%',
                      selected: prefs.fontScale == scale,
                      onTap: () => ref
                          .read(readingPreferencesProvider.notifier)
                          .setFontScale(scale),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Container(height: 1, color: colors.border),
            const SizedBox(height: 10),
            Text(
              strings.recitationNotBundled,
              style: AppTextStyles.labelSmall
                  .copyWith(color: colors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}
