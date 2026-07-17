// lib/features/quran/presentation/surah_reader_screen.dart

// ============================================================
// QIBRA AI — SURAH READER SCREEN (v1.1 — Audio Integrated)
// Phase: 8.3 + 8.4
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
import 'quran_audio_player.dart';
// ============================================================
// SECTION 1 — FONT SIZE ENUM
// ============================================================

enum QuranFontSize {
  small,
  medium,
  large,
  extraLarge;

  double get arabicSize {
    return switch (this) {
      QuranFontSize.small => 18.0,
      QuranFontSize.medium => 22.0,
      QuranFontSize.large => 26.0,
      QuranFontSize.extraLarge => 30.0,
    };
  }

  double get translationSize {
    return switch (this) {
      QuranFontSize.small => 12.0,
      QuranFontSize.medium => 14.0,
      QuranFontSize.large => 16.0,
      QuranFontSize.extraLarge => 18.0,
    };
  }

  String get label {
    return switch (this) {
      QuranFontSize.small => 'S',
      QuranFontSize.medium => 'M',
      QuranFontSize.large => 'L',
      QuranFontSize.extraLarge => 'XL',
    };
  }

  String get fullLabel {
    return switch (this) {
      QuranFontSize.small => 'Small',
      QuranFontSize.medium => 'Medium',
      QuranFontSize.large => 'Large',
      QuranFontSize.extraLarge => 'Extra Large',
    };
  }
}

// ============================================================
// SECTION 2 — LOCAL PROVIDERS
// ============================================================

final _readerFontSizeProvider =
    StateProvider.autoDispose<QuranFontSize>((ref) => QuranFontSize.medium);

final _showTranslationProvider = StateProvider.autoDispose<bool>((ref) => true);

final _showArabicOnlyProvider = StateProvider.autoDispose<bool>((ref) => false);

// ============================================================
// SECTION 3 — MAIN SCREEN WIDGET
// ============================================================

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

class _SurahReaderScreenState extends ConsumerState<SurahReaderScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();

  int _currentVisibleAyah = 1;
  bool _hasTrackedInitialRead = false;
  bool _isAppBarExpanded = true;

  late final AnimationController _headerAnimController;
  late final Animation<double> _headerFade;

  @override
  void initState() {
    super.initState();

    _headerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _headerFade = CurvedAnimation(
      parent: _headerAnimController,
      curve: Curves.easeOutCubic,
    );

    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _headerAnimController.forward();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _headerAnimController.dispose();
    super.dispose();
  }

  // ── Scroll ────────────────────────────────────────────────

  void _onScroll() {
    final shouldCollapse = _scrollController.offset > 120;
    if (shouldCollapse != !_isAppBarExpanded) {
      setState(() => _isAppBarExpanded = !shouldCollapse);
    }
  }

  // ── Last Read ─────────────────────────────────────────────

  void _updateLastRead(SurahModel surah, int ayahNumber) {
    ref.read(lastReadProvider.notifier).updateLastRead(
          surahNumber: surah.number,
          ayahNumber: ayahNumber,
          surahName: surah.name,
          totalAyahsInSurah: surah.numberOfAyahs,
        );
  }

  // ── Bookmark ──────────────────────────────────────────────

  void _toggleBookmark(SurahModel surah, AyahModel ayah) {
    HapticFeedback.mediumImpact();

    final bookmark = BookmarkModel(
      surahNumber: surah.number,
      ayahNumber: ayah.number,
      surahName: surah.name,
      ayahText: ayah.text,
      bookmarkedAt: DateTime.now(),
    );

    ref.read(bookmarksProvider.notifier).toggleBookmark(bookmark);

    final isNowBookmarked = ref.read(
      isBookmarkedProvider((surah: surah.number, ayah: ayah.number)),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                isNowBookmarked
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_remove_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                isNowBookmarked
                    ? 'Ayah ${ayah.number} bookmarked!'
                    : 'Bookmark removed',
                style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
              ),
            ],
          ),
          backgroundColor:
              isNowBookmarked ? AppColors.primary : AppColors.surfaceHigh,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.all(AppSpacing.lg),
        ),
      );
    }
  }

  // ── Copy ──────────────────────────────────────────────────

  void _copyAyah(SurahModel surah, AyahModel ayah) {
    final text = '${ayah.text}\n\n${ayah.translation ?? ''}\n\n'
        '— ${surah.name} ${surah.number}:${ayah.number}';
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Ayah ${ayah.number} copied!',
            style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
          ),
          backgroundColor: AppColors.surfaceHigh,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          duration: const Duration(seconds: 2),
          margin: const EdgeInsets.all(AppSpacing.lg),
        ),
      );
    }
  }

  // ── Sheets ────────────────────────────────────────────────

  void _showFontSizeSheet() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (_) => const _FontSizeBottomSheet(),
    );
  }

  void _showSettingsSheet(SurahModel surah) {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (_) => _ReaderSettingsSheet(surah: surah),
    );
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final surahAsync = ref.watch(surahDetailProvider(widget.surahNumber));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: surahAsync.when(
        data: (surah) {
          if (surah == null) return _buildNotFound();

          if (!_hasTrackedInitialRead) {
            _hasTrackedInitialRead = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _updateLastRead(surah, widget.initialAyah ?? 1);
            });
          }

          return _buildReaderBody(surah);
        },
        loading: () => const _ReaderLoadingState(),
        error: (error, _) => _ReaderErrorState(
          error: error.toString(),
          onRetry: () =>
              ref.invalidate(surahDetailProvider(widget.surahNumber)),
          onBack: () => Navigator.of(context).maybePop(),
        ),
      ),
    );
  }

  // ── Reader Body ───────────────────────────────────────────

  Widget _buildReaderBody(SurahModel surah) {
    return Stack(
      children: [
        // ── Main scrollable content ──
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary.withValues(alpha: 0.06),
                AppColors.background,
                AppColors.background,
              ],
              stops: const [0.0, 0.15, 1.0],
            ),
          ),
          child: CustomScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            slivers: [
              // App Bar
              _buildSliverAppBar(surah),

              // Surah Header
              SliverToBoxAdapter(
                child: FadeTransition(
                  opacity: _headerFade,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      0,
                    ),
                    child: _SurahHeaderCard(surah: surah),
                  ),
                ),
              ),

              // Bismillah
              if (surah.number != 1 && surah.number != 9)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      0,
                    ),
                    child: _BismillahWidget(),
                  ),
                ),

              // Ayahs List
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
                  // Extra bottom padding so mini player doesn't
                  // cover last ayah
                  AppSpacing.xl3 + AppSpacing.xl4 + AppSpacing.xl3,
                ),
                sliver: SliverList.separated(
                  itemCount: surah.ayahs.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final ayah = surah.ayahs[index];
                    return _AyahCard(
                      ayah: ayah,
                      surah: surah,
                      onBookmark: () => _toggleBookmark(surah, ayah),
                      onCopy: () => _copyAyah(surah, ayah),
                      onVisible: () {
                        if (_currentVisibleAyah != ayah.number) {
                          _currentVisibleAyah = ayah.number;
                          _updateLastRead(surah, ayah.number);
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),

        // ── Mini Player (floats above scroll content) ──
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: QuranMiniPlayer(
            surahName: surah.name,
          ),
        ),
      ],
    );
  }

  // ── Sliver App Bar ────────────────────────────────────────

  Widget _buildSliverAppBar(SurahModel surah) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      floating: false,
      expandedHeight: 0,
      toolbarHeight: 64,
      leading: const SizedBox.shrink(),
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: _isAppBarExpanded
              ? ImageFilter.blur(sigmaX: 0, sigmaY: 0)
              : ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            color: _isAppBarExpanded
                ? Colors.transparent
                : AppColors.background.withValues(alpha: 0.88),
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top,
              left: AppSpacing.lg,
              right: AppSpacing.lg,
            ),
            child: Row(
              children: [
                _AppBarButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).maybePop();
                  },
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: AnimatedOpacity(
                    opacity: _isAppBarExpanded ? 0.0 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          surah.name,
                          style: AppTextStyles.titleSmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${surah.numberOfAyahs} Ayahs • ${surah.revelationType}',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _AppBarButton(
                  icon: Icons.text_fields_rounded,
                  onTap: _showFontSizeSheet,
                ),
                const SizedBox(width: AppSpacing.sm),
                _AppBarButton(
                  icon: Icons.tune_rounded,
                  onTap: () => _showSettingsSheet(surah),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Not Found ─────────────────────────────────────────────

  Widget _buildNotFound() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Row(
              children: [
                _AppBarButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
            const Spacer(),
            const Icon(
              Icons.search_off_rounded,
              size: 64,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Surah not found',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Surah ${widget.surahNumber} load nahi ho saca.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SECTION 4 — SURAH HEADER CARD
// ============================================================

class _SurahHeaderCard extends StatelessWidget {
  const _SurahHeaderCard({required this.surah});

  final SurahModel surah;

  @override
  Widget build(BuildContext context) {
    final isMeccan = surah.isMeccan;
    final revelationColor =
        isMeccan ? const Color(0xFF7C4DFF) : const Color(0xFF1E88E5);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.28),
            AppColors.primary.withValues(alpha: 0.16),
            AppColors.accent.withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl3),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.22),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.20),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -20,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.06),
              ),
            ),
          ),
          Column(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppGradients.gold,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.24),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    surah.number.toString(),
                    style: AppTextStyles.titleSmall.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                surah.nameArabic,
                textDirection: TextDirection.rtl,
                style: AppTextStyles.titleLarge.copyWith(
                  fontFamily: 'Amiri',
                  fontSize: 32,
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                surah.name,
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                '"${surah.englishNameTranslation}"',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                alignment: WrapAlignment.center,
                children: [
                  _MetaPill(
                    icon: Icons.format_list_numbered_rounded,
                    label: '${surah.numberOfAyahs} Ayahs',
                    color: AppColors.accent,
                  ),
                  _MetaPill(
                    icon: isMeccan
                        ? Icons.wb_sunny_rounded
                        : Icons.water_drop_rounded,
                    label: surah.revelationType,
                    color: revelationColor,
                  ),
                  _MetaPill(
                    icon: Icons.auto_stories_rounded,
                    label: 'Surah ${surah.number}',
                    color: AppColors.primary,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SECTION 5 — BISMILLAH WIDGET
// ============================================================

class _BismillahWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl2,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        children: [
          Text(
            'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            style: AppTextStyles.titleLarge.copyWith(
              fontFamily: 'Amiri',
              fontSize: 26,
              color: AppColors.accent,
              fontWeight: FontWeight.w700,
              height: 2.0,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'In the name of Allah, the Most Gracious, the Most Merciful',
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SECTION 6 — AYAH CARD
// ============================================================

class _AyahCard extends ConsumerWidget {
  const _AyahCard({
    required this.ayah,
    required this.surah,
    required this.onBookmark,
    required this.onCopy,
    required this.onVisible,
  });

  final AyahModel ayah;
  final SurahModel surah;
  final VoidCallback onBookmark;
  final VoidCallback onCopy;
  final VoidCallback onVisible;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontSize = ref.watch(_readerFontSizeProvider);
    final showTranslation = ref.watch(_showTranslationProvider);
    final arabicOnly = ref.watch(_showArabicOnlyProvider);

    final isBookmarked = ref.watch(
      isBookmarkedProvider((surah: surah.number, ayah: ayah.number)),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => onVisible());

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        border: Border.all(
          color: isBookmarked
              ? AppColors.accent.withValues(alpha: 0.30)
              : AppColors.primary.withValues(alpha: 0.10),
          width: isBookmarked ? 1.2 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
          if (isBookmarked)
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildAyahBar(isBookmarked),
          if (ayah.sajdah) _buildSajdahBadge(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.sm,
            ),
            child: Text(
              ayah.text,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: fontSize.arabicSize,
                color: AppColors.textPrimary,
                height: 2.2,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          if (showTranslation && !arabicOnly && ayah.translation != null)
            _buildTranslation(ayah.translation!, fontSize),
          _buildMetaRow(),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }

  Widget _buildAyahBar(bool isBookmarked) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm + 2,
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
          // Ayah number badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppColors.primary.withValues(alpha: 0.90),
                  AppColors.accent.withValues(alpha: 0.70),
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.18),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                ayah.number.toString(),
                style: AppTextStyles.labelSmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Juz info
          Text(
            'Juz ${ayah.juz}',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),

          const Spacer(),

          // Audio play button
          // v7.0: Ayah-level play button removed
          // Main audio player (Quran tab) handles playback
          // Prevents multiple simultaneous player conflicts
          // Bookmark button
          GestureDetector(
            onTap: onBookmark,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: isBookmarked
                    ? AppColors.accent.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(
                isBookmarked
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                size: 20,
                color: isBookmarked ? AppColors.accent : AppColors.textTertiary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),

          // Copy button
          GestureDetector(
            onTap: onCopy,
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              child: const Icon(
                Icons.copy_rounded,
                size: 18,
                color: AppColors.textTertiary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSajdahBadge() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.expand_more_rounded,
            size: 14,
            color: AppColors.primary,
          ),
          const SizedBox(width: 4),
          Text(
            'Sajdah — Sujood required when reciting this ayah',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranslation(String translation, QuranFontSize fontSize) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 1,
            color: AppColors.primary.withValues(alpha: 0.10),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            translation,
            textAlign: TextAlign.left,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: fontSize.translationSize,
              color: AppColors.textSecondary,
              height: 1.65,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        0,
      ),
      child: Row(
        children: [
          Icon(
            Icons.menu_book_rounded,
            size: 13,
            color: AppColors.textTertiary.withValues(alpha: 0.70),
          ),
          const SizedBox(width: 4),
          Text(
            'Page ${ayah.page}',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textTertiary,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          if (ayah.ruku != null) ...[
            Icon(
              Icons.trip_origin_rounded,
              size: 11,
              color: AppColors.textTertiary.withValues(alpha: 0.70),
            ),
            const SizedBox(width: 4),
            Text(
              'Ruku ${ayah.ruku}',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textTertiary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// SECTION 7 — FONT SIZE BOTTOM SHEET
// ============================================================

class _FontSizeBottomSheet extends ConsumerWidget {
  const _FontSizeBottomSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSize = ref.watch(_readerFontSizeProvider);

    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.xl2),
      decoration: BoxDecoration(
        color: AppColors.surfaceSheet,
        borderRadius: BorderRadius.circular(AppRadius.xl3),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textTertiary.withValues(alpha: 0.40),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Arabic Font Size',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Choose your preferred reading size',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.xl2),
          Row(
            children: QuranFontSize.values.map((size) {
              final isSelected = size == currentSize;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(_readerFontSizeProvider.notifier).state = size;
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.18)
                          : AppColors.surfaceElevated.withValues(alpha: 0.80),
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.50)
                            : AppColors.primary.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'ب',
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: size.arabicSize * 0.7 + 8,
                            color: isSelected
                                ? AppColors.accent
                                : AppColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          size.label,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.textTertiary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated.withValues(alpha: 0.70),
              borderRadius: BorderRadius.circular(AppRadius.xl2),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.12),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'بِسْمِ اللَّهِ',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: currentSize.arabicSize,
                    color: AppColors.textPrimary,
                    height: 2.0,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'In the name of Allah',
                  style: TextStyle(
                    fontSize: currentSize.translationSize,
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Preview — ${currentSize.fullLabel}',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
              child: Text(
                'Done',
                style: AppTextStyles.labelLarge.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SECTION 8 — READER SETTINGS SHEET
// ============================================================

class _ReaderSettingsSheet extends ConsumerWidget {
  const _ReaderSettingsSheet({required this.surah});

  final SurahModel surah;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showTranslation = ref.watch(_showTranslationProvider);
    final arabicOnly = ref.watch(_showArabicOnlyProvider);

    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.xl2),
      decoration: BoxDecoration(
        color: AppColors.surfaceSheet,
        borderRadius: BorderRadius.circular(AppRadius.xl3),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.16),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.textTertiary.withValues(alpha: 0.40),
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Text(
                'Reader Settings',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated.withValues(alpha: 0.70),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.14),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: AppGradients.emerald,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                  child: Center(
                    child: Text(
                      surah.number.toString(),
                      style: AppTextStyles.labelLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      surah.name,
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${surah.numberOfAyahs} ayahs • ${surah.revelationType}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  surah.nameArabic,
                  style: AppTextStyles.titleMedium.copyWith(
                    fontFamily: 'Amiri',
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _SettingsToggle(
            icon: Icons.translate_rounded,
            iconColor: const Color(0xFF1E88E5),
            title: 'Show Translation',
            subtitle: 'English translation ke saath padhen',
            value: showTranslation,
            onChanged: (val) {
              HapticFeedback.selectionClick();
              ref.read(_showTranslationProvider.notifier).state = val;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _SettingsToggle(
            icon: Icons.text_format_rounded,
            iconColor: AppColors.accent,
            title: 'Arabic Only Mode',
            subtitle: 'Sirf Arabic text dikhaye — distraction free',
            value: arabicOnly,
            onChanged: (val) {
              HapticFeedback.selectionClick();
              ref.read(_showArabicOnlyProvider.notifier).state = val;
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.surfaceHigh,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
              ),
              child: Text(
                'Close',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SECTION 9 — SMALL REUSABLE WIDGETS
// ============================================================

class _MetaPill extends StatelessWidget {
  const _MetaPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: color.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _AppBarButton extends StatelessWidget {
  const _AppBarButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Ink(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated.withValues(alpha: 0.80),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.14),
            ),
          ),
          child: Icon(
            icon,
            size: 19,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _SettingsToggle extends StatelessWidget {
  const _SettingsToggle({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.70),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Icon(icon, size: 18, color: iconColor),
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
                Text(
                  subtitle,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.30),
            inactiveThumbColor: AppColors.textTertiary,
            inactiveTrackColor: AppColors.surfaceHigh,
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SECTION 10 — LOADING STATE
// ============================================================

class _ReaderLoadingState extends StatelessWidget {
  const _ReaderLoadingState();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Row(
            children: [
              _shimmer(width: 42, height: 42, radius: AppRadius.xl),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _shimmer(
                  width: double.infinity,
                  height: 16,
                  radius: AppRadius.full,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              _shimmer(width: 42, height: 42, radius: AppRadius.xl),
              const SizedBox(width: AppSpacing.sm),
              _shimmer(width: 42, height: 42, radius: AppRadius.xl),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _shimmer(width: double.infinity, height: 220, radius: AppRadius.xl3),
          const SizedBox(height: AppSpacing.lg),
          _shimmer(width: double.infinity, height: 80, radius: AppRadius.xl2),
          const SizedBox(height: AppSpacing.lg),
          for (int i = 0; i < 5; i++) ...[
            _shimmer(
              width: double.infinity,
              height: 130 + (i % 2 == 0 ? 30.0 : 0.0),
              radius: AppRadius.xl2,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }

  static Widget _shimmer({
    required double width,
    required double height,
    required double radius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ============================================================
// SECTION 11 — ERROR STATE
// ============================================================

class _ReaderErrorState extends StatelessWidget {
  const _ReaderErrorState({
    required this.error,
    required this.onRetry,
    required this.onBack,
  });

  final String error;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            Row(
              children: [
                _AppBarButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  onTap: onBack,
                ),
              ],
            ),
            const Spacer(),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.xl2),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated.withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(AppRadius.xl3),
                border: Border.all(
                  color: AppColors.error.withValues(alpha: 0.14),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.error.withValues(alpha: 0.09),
                    ),
                    child: Icon(
                      Icons.error_outline_rounded,
                      size: 34,
                      color: AppColors.error.withValues(alpha: 0.84),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Unable to Load Surah',
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Surah data load karne mein problem aayi. Retry karein.',
                    textAlign: TextAlign.center,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    error,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onBack,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            side: BorderSide(
                              color: AppColors.primary.withValues(alpha: 0.30),
                            ),
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                          ),
                          child: Text(
                            'Go Back',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onRetry,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md,
                            ),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.lg),
                            ),
                          ),
                          child: Text(
                            'Retry',
                            style: AppTextStyles.labelLarge.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// END OF FILE — surah_reader_screen.dart
// ============================================================
