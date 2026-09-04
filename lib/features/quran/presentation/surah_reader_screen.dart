// lib/features/quran/presentation/surah_reader_screen.dart
// ============================================================
// QIBRA AI — SURAH READER (Stage B rewrite, midnight navy)
//
// What changed vs the legacy screen (audit findings):
//  • 76 hardcoded hexes -> QibraColors tokens (theme-driven:
//    navy by default, sanctioned ivory when the app theme is light).
//  • The deleted floating audio-player bar (fabricated play/duration
//    timestamps for unbundled audio) is GONE for good; the audio stage
//    restored recitation as REAL: a single app-wide just_audio player
//    (stream + offline), per-ayah play with live position from the
//    player's own streams, and a mini bar in the shell that renders
//    only while the player is active. Nothing here may fake a time.
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
import '../../../core/design_system/qibra_navy.dart';
import '../../../core/l10n/app_strings.dart';
import '../../../shared/widgets/controls/app_switch_tile.dart';
import '../../../shared/widgets/qibra_status.dart';
import '../../../shared/widgets/qibra_ui.dart';
import '../data/audio/tilawat.dart';
import '../data/models/quran_models.dart';
import '../providers/quran_audio_provider.dart';
import '../providers/quran_download_provider.dart';
import '../providers/reading_progress_provider.dart';
import '../providers/quran_provider.dart' hide readingProgressProvider;
import '../providers/reading_preferences_provider.dart';
import 'ayah_options_sheet.dart';

/// The reader's auto-advance queue, built from the REAL ayah list with
/// the app's own global ayah numbers (numberInQuran; QuranMeta prefix
/// sum as fallback). No invented entries.
/// The ONE resume-position definition (see LastReadNotifier): the last
/// opened card, else the last played ayah, else the entry position.
/// Pure — unit-tested.
int resumeAyahForVisit({
  required int? tapped,
  required int? played,
  required int? initialAyah,
}) {
  return tapped ?? played ?? initialAyah ?? 1;
}

List<PlayableAyah> tilawatQueueFor(SurahModel surah) => [
      for (final a in surah.ayahs)
        PlayableAyah(
          surah: surah.number,
          ayah: a.number,
          global: Tilawat.globalAyahNumber(
            surah: surah.number,
            ayah: a.number,
            numberInQuran: a.numberInQuran,
          ),
        ),
    ];

class SurahReaderScreen extends ConsumerStatefulWidget {
  const SurahReaderScreen({
    super.key,
    required this.surahNumber,
    this.initialAyah,
    this.initialTab,
  });

  final int surahNumber;
  final int? initialAyah;

  /// One of 'Arabic' | 'Translation' | 'Transliteration'.
  final String? initialTab;

  @override
  ConsumerState<SurahReaderScreen> createState() => _SurahReaderScreenState();
}

class _SurahReaderScreenState extends ConsumerState<SurahReaderScreen>
    with WidgetsBindingObserver {
  static const _tabs = ['Arabic', 'Translation', 'Transliteration'];

  /// Arabic text-size stops offered by the pill.
  static const scales = <double>[1.0, 1.25, 1.5];

  late final String _activeTab;
  final ScrollController _scroll = ScrollController();
  bool _didInitialScroll = false;

  // Last-read tracking (item 2). Written on dispose/app-pause; NOT
  // setState-bound — no UI depends on these mid-frame.
  int? _tappedAyah;
  int? _playedAyah;

  @override
  void initState() {
    super.initState();
    _activeTab =
        _tabs.contains(widget.initialTab) ? widget.initialTab! : 'Arabic';
    // Download status is read back from disk — check the real files.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(quranDownloadProvider.notifier).checkSurah(widget.surahNumber);
    });
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 'visibility pause' of the resume contract: backgrounding persists.
    if (state == AppLifecycleState.paused) _persistLastRead();
  }

  /// Store the visit's position using the documented definition. If the
  /// surah data never loaded there is nothing real to store — skip.
  void _persistLastRead() {
    final surah = ref.read(surahDetailProvider(widget.surahNumber)).value;
    if (surah == null || surah.ayahs.isEmpty) return;
    final ayah = resumeAyahForVisit(
      tapped: _tappedAyah,
      played: _playedAyah,
      initialAyah: widget.initialAyah,
    );
    ref.read(lastReadStoreProvider.notifier).record(
          surahNumber: surah.number,
          ayahNumber: ayah,
          surahName: surah.name,
          totalAyahsInSurah: surah.ayahs.length,
        );
  }

  @override
  void dispose() {
    _persistLastRead();
    WidgetsBinding.instance.removeObserver(this);
    _scroll.dispose();
    super.dispose();
  }

  void _stepArabicScale() {
    HapticFeedback.selectionClick();
    final prefs = ref.read(readingPreferencesProvider);
    final i = scales.indexOf(prefs.arabicScale);
    ref
        .read(readingPreferencesProvider.notifier)
        .setArabicScale(scales[(i + 1) % scales.length]);
  }

  void _jumpToInitialAyah(SurahModel surah) {
    if (_didInitialScroll || widget.initialAyah == null) return;
    _didInitialScroll = true;
    final idx = surah.ayahs.indexWhere((a) => a.number == widget.initialAyah);
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
    // Narrow selects so unrelated playback (or per-tick position
    // updates of a DIFFERENT track) never rebuild this list.
    //  -1: not playing this surah · 1: loading/buffering · 2: playing
    //   0: paused or failed on this surah (tap resumes/retries)
    final audioMark = ref.watch(quranAudioProvider.select((s) {
      if (s.surahNumber != widget.surahNumber || !s.active) return -1;
      if (s.buffering || s.phase == QuranAudioPhase.loading) return 1;
      if (s.isPlaying) return 2;
      return 0;
    }));
    final dlStatus = ref.watch(quranDownloadProvider
        .select((m) => m[widget.surahNumber] ?? const SurahAudioStatus()));
    // Resume tracking: remember the latest PLAYED ayah of this surah.
    ref.listen(
      quranAudioProvider.select((a) =>
          (a.active && a.surahNumber == widget.surahNumber && a.isPlaying)
              ? a.ayahNumber
              : null),
      (_, next) {
        if (next != null) _playedAyah = next;
      },
    );

    return Scaffold(
      backgroundColor: colors.background,
      appBar: QibraAppBar(
        title: surah?.name ?? 'Surah ${widget.surahNumber}',
        subtitle: surah == null ? null : 'Surah ${surah.number} of 114',
        actions: [
          IconButton(
            tooltip: audioMark == 2
                ? 'Pause recitation'
                : (audioMark == 1
                    ? 'Buffering…'
                    : (audioMark == 0
                        ? 'Resume / retry recitation'
                        : 'Play surah (auto-advances through the ayahs)')),
            icon: audioMark == 1
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colors.primary,
                    ),
                  )
                : Icon(
                    audioMark == 2
                        ? Icons.pause_circle_outline_rounded
                        : Icons.play_circle_outline_rounded,
                    color: audioMark == -1
                        ? colors.textSecondary
                        : colors.primary,
                  ),
            onPressed: () {
              final s = ref.read(surahDetailProvider(widget.surahNumber)).value;
              if (s == null || s.ayahs.isEmpty) return;
              final ctl = ref.read(quranAudioProvider.notifier);
              if (audioMark == -1) {
                ctl.startQueue(
                  surahNumber: s.number,
                  surahName: s.name,
                  queue: tilawatQueueFor(s),
                  startIndex: 0,
                );
              } else {
                ctl.toggle();
              }
            },
          ),
          IconButton(
            tooltip: dlStatus.label,
            onPressed: dlStatus.checking || dlStatus.downloading
                ? null
                : () {
                    final ctl = ref.read(quranDownloadProvider.notifier);
                    if (dlStatus.downloaded) {
                      _confirmDeleteDownload(ctl, dlStatus);
                    } else {
                      ctl.startDownload(widget.surahNumber);
                    }
                  },
            icon: dlStatus.checking || dlStatus.downloading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: dlStatus.downloading
                          ? colors.primary
                          : colors.textTertiary,
                    ),
                  )
                : Icon(
                    dlStatus.downloaded
                        ? Icons.download_done_rounded
                        : (dlStatus.failed > 0
                            ? Icons.sync_problem_rounded
                            : Icons.download_rounded),
                    color: dlStatus.downloaded
                        ? QibraNavy.emerald
                        : (dlStatus.failed > 0
                            ? QibraNavy.red
                            : colors.textSecondary),
                  ),
          ),
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
              message: 'Surah ${widget.surahNumber} is not in the bundled '
                  'Quran data.',
            );
          }
          _jumpToInitialAyah(s);
          return Column(
            children: [
              _ModeTabs(
                tabs: _tabs,
                active: _activeTab,
                arabicScale: prefs.arabicScale,
                onSelect: (tab) {
                  HapticFeedback.selectionClick();
                  setState(() => _activeTab = tab);
                },
                onSizeStep: _stepArabicScale,
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
                        onAyahOpened: () =>
                            _tappedAyah = s.ayahs[ayahIndex].number,
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: _TranslationCompareCard(ayah: s.ayahs.first),
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
          onRetry: () =>
              ref.invalidate(surahDetailProvider(widget.surahNumber)),
        ),
      ),
    );
  }

  /// Real disk facts only: size and counts are the ones checkSurah()
  /// read back from the filesystem.
  void _confirmDeleteDownload(
      QuranDownloadController ctl, SurahAudioStatus st) {
    final colors = QibraColors.of(context);
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: QibraColors.of(dialogContext).card,
        title: Text(
          'Offline recitation',
          style: AppTextStyles.titleSmall
              .copyWith(color: QibraColors.of(dialogContext).textPrimary),
        ),
        content: Text(
          '${st.done}/${st.total} files on disk · '
          '${SurahAudioStatus.bytesLabel(st.bytes)}. '
          'Delete this surah\'s download?',
          style: AppTextStyles.bodyMedium.copyWith(
            color: QibraColors.of(dialogContext).textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Keep',
              style: AppTextStyles.labelMedium
                  .copyWith(color: QibraColors.of(dialogContext).textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              ctl.deleteDownload(widget.surahNumber);
            },
            child: Text(
              'Delete',
              style: AppTextStyles.labelMedium
                  .copyWith(color: colors.textSecondary),
            ),
          ),
        ],
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
    required this.arabicScale,
    required this.onSelect,
    required this.onSizeStep,
  });

  final List<String> tabs;
  final String active;
  final double arabicScale;
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
                    arabicScale == 1.0
                        ? 'Aa'
                        : 'Aa+${((arabicScale - 1) * 100).round()}',
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
              style:
                  AppArabicStyles.surahName.copyWith(color: colors.textPrimary),
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
          style:
              AppArabicStyles.bismillah.copyWith(color: colors.textSecondary),
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
    this.onAyahOpened,
  });

  final SurahModel surah;
  final AyahModel ayah;
  final String activeTab;
  final ReadingPreferences prefs;

  /// Fires the instant the card's options sheet is opened — the
  /// last-read definition's primary signal (documented in item 2).
  final VoidCallback? onAyahOpened;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = QibraColors.of(context);
    final bookmarked = ref.watch(
      isBookmarkedProvider((surah: surah.number, ayah: ayah.number)),
    );
    final strings = AppStrings.of(context);
    // Only the card the single player is actually on re-renders with
    // position ticks; all other cards stay static (narrow select).
    final cur = ref.watch(quranAudioProvider.select((s) =>
        s.active &&
                s.surahNumber == surah.number &&
                s.ayahNumber == ayah.number
            ? s
            : null));

    // Split scales (world-class pass): Arabic follows arabicScale; the
    // latin body lines follow translationScale.
    final arabicSize = AppFontSize.arabicMedium * prefs.arabicScale;
    final translationSize = AppFontSize.bodyMedium * prefs.translationScale;
    final translitSize = AppFontSize.bodySmall * prefs.translationScale;
    final showTranslation = activeTab == 'Translation' ||
        (activeTab != 'Arabic' && prefs.showTranslation);
    final showTranslit =
        activeTab == 'Transliteration' && prefs.showTransliteration;
    final translation = _translationFor(ayah, prefs);
    final roman = ayah.translationRoman?.trim();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: QibraCard(
        onTap: () {
          onAyahOpened?.call();
          showAyahOptions(
          context: context,
          surahNumber: surah.number,
          ayahNumber: ayah.number,
          surahName: surah.name,
          ayah: ayah,
        );
        },
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
                      '${ayah.number}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: cur == null
                      ? 'Play from here'
                      : (cur.phase == QuranAudioPhase.failed
                          ? 'Retry'
                          : (cur.isPlaying
                              ? 'Pause'
                              : (cur.buffering ||
                                      cur.phase == QuranAudioPhase.loading
                                  ? 'Buffering…'
                                  : 'Resume'))),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    final ctl = ref.read(quranAudioProvider.notifier);
                    if (cur != null) {
                      ctl.toggle();
                      return;
                    }
                    final idx =
                        surah.ayahs.indexWhere((a) => a.number == ayah.number);
                    ctl.startQueue(
                      surahNumber: surah.number,
                      surahName: surah.name,
                      queue: tilawatQueueFor(surah),
                      startIndex: idx < 0 ? 0 : idx,
                    );
                  },
                  icon: cur != null &&
                          (cur.buffering ||
                              cur.phase == QuranAudioPhase.loading)
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.primary,
                          ),
                        )
                      : Icon(
                          cur != null && cur.isPlaying
                              ? Icons.pause_circle_filled_rounded
                              : Icons.play_circle_outline_rounded,
                          color: cur == null
                              ? colors.textTertiary
                              : colors.primary,
                          size: 20,
                        ),
                ),
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
                  fontSize: translitSize,
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
                  fontSize: translationSize,
                  color: colors.textSecondary,
                  height: 1.5,
                ),
              ),
            ],
            // Playback UI for THIS ayah exists only while the player is
            // on it: real reported progress, an honest indeterminate
            // line while buffering, and the truthful failure copy.
            if (cur != null) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: cur.progress != null
                    ? LinearProgressIndicator(
                        value: cur.progress,
                        minHeight: 3,
                        color: colors.primary,
                        backgroundColor: colors.border,
                      )
                    : const LinearProgressIndicator(minHeight: 3),
              ),
              const SizedBox(height: 6),
              Text(
                cur.phase == QuranAudioPhase.failed
                    ? (cur.error ?? Tilawat.offlineFailureMessage)
                    : (cur.buffering || cur.phase == QuranAudioPhase.loading
                        ? 'Buffering…'
                        : (cur.duration != null
                            ? '${Tilawat.clockLabel(cur.position)} / '
                                '${Tilawat.clockLabel(cur.duration!)}'
                            : Tilawat.clockLabel(cur.position))),
                textAlign: TextAlign.right,
                style: AppTextStyles.labelSmall.copyWith(
                  color: cur.phase == QuranAudioPhase.failed
                      ? QibraNavy.red
                      : colors.textTertiary,
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
                ? AppArabicStyles.quranSmall.copyWith(color: colors.textPrimary)
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
            const SizedBox(height: 8),
            // Split font controls (world-class pass): Arabic and
            // translation scale independently over the same clamped
            // range; the sliders reflect and persist REAL pref state.
            for (final entry in const [
              ('Arabic text', 'arabic'),
              ('Translation & transliteration', 'translation'),
            ]) ...[
              Text(
                entry.$1,
                style: AppTextStyles.labelMedium.copyWith(
                  color: colors.textSecondary,
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
                      min: ReadingPreferences.scaleMin,
                      max: ReadingPreferences.scaleMax,
                      divisions: 8,
                      activeColor: colors.primary,
                      label:
                          '${(((entry.$2 == 'arabic' ? prefs.arabicScale : prefs.translationScale) - 1) * 100).round()}%',
                      onChanged: (v) => entry.$2 == 'arabic'
                          ? ref
                              .read(readingPreferencesProvider.notifier)
                              .setArabicScale(v)
                          : ref
                              .read(readingPreferencesProvider.notifier)
                              .setTranslationScale(v),
                    ),
                  ),
                  SizedBox(
                    width: 52,
                    child: Text(
                      '${(entry.$2 == 'arabic' ? prefs.arabicScale : prefs.translationScale).toStringAsFixed(2)}\u00d7',
                      textAlign: TextAlign.end,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: colors.textTertiary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
            ],
            const SizedBox(height: 14),
            Container(height: 1, color: colors.border),
            const SizedBox(height: 10),
            Text(
              'Recitation (Mishary Alafasy) streams from everyayah.com with '
              'a cdn.islamic.network fallback; the download action in the '
              'app bar saves a surah to this device for offline play. No '
              'audio files are bundled with the app.',
              style:
                  AppTextStyles.labelSmall.copyWith(color: colors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }
}
