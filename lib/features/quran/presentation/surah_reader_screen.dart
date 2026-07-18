// lib/features/quran/presentation/surah_reader_screen.dart

// ============================================================
// QIBRA AI — SURAH READER SCREEN (v2.0)
// Version: 2.0.0 — Multi-language translations (En/Ur/Roman)
// ============================================================

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_design_system.dart';
import '../../../core/design_system/app_typography.dart';
import '../data/models/quran_models.dart';
import '../providers/audio_provider.dart';
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

// Language toggles
final _showEnglishProvider = StateProvider.autoDispose<bool>((ref) => true);
final _showUrduProvider = StateProvider.autoDispose<bool>((ref) => true);
final _showRomanProvider = StateProvider.autoDispose<bool>((ref) => false);

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

  void _onScroll() {
    final shouldCollapse = _scrollController.offset > 120;
    if (shouldCollapse != !_isAppBarExpanded) {
      setState(() => _isAppBarExpanded = !shouldCollapse);
    }
  }

  void _updateLastRead(SurahModel surah, int ayahNumber) {
    ref.read(lastReadProvider.notifier).updateLastRead(
          surahNumber: surah.number,
          ayahNumber: ayahNumber,
          surahName: surah.name,
          totalAyahsInSurah: surah.numberOfAyahs,
        );
  }

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

  void _copyAyah(SurahModel surah, AyahModel ayah) {
    final buffer = StringBuffer();
    buffer.writeln(ayah.text);
    buffer.writeln();
    if (ayah.translation != null) {
      buffer.writeln(ayah.translation);
      buffer.writeln();
    }
    if (ayah.translationUrdu != null) {
      buffer.writeln(ayah.translationUrdu);
      buffer.writeln();
    }
    if (ayah.translationRoman != null) {
      buffer.writeln(ayah.translationRoman);
      buffer.writeln();
    }
    buffer.write('— ${surah.name} ${surah.number}:${ayah.number}');

    Clipboard.setData(ClipboardData(text: buffer.toString()));
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

  Widget _buildReaderBody(SurahModel surah) {
    return Stack(
      children: [
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
              _buildSliverAppBar(surah),
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
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.lg,
                  AppSpacing.lg,
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
              'Surah ${widget.surahNumber} load nahi ho saka.',
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
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 26,
              color: AppColors.accent,
              fontWeight: FontWeight.w600,
              height: 1.8,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'In the name of Allah, the Most Gracious, the Most Merciful',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
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
    final showEnglish = ref.watch(_showEnglishProvider);
    final showUrdu = ref.watch(_showUrduProvider);
    final showRoman = ref.watch(_showRomanProvider);

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
          if (showTranslation && !arabicOnly)
            _buildAllTranslations(
              ayah: ayah,
              fontSize: fontSize,
              showEnglish: showEnglish,
              showUrdu: showUrdu,
              showRoman: showRoman,
            ),
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
          Text(
            'Juz ${ayah.juz}',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          // Play/Pause button for this ayah
          _AyahPlayButton(
            surahNumber: surah.number,
            ayahNumber: ayah.number,
            globalAyahNumber: ayah.numberInQuran,
          ),
          const SizedBox(width: AppSpacing.xs),
          GestureDetector(
            onTap: onBookmark,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isBookmarked
                    ? AppColors.accent.withValues(alpha: 0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isBookmarked
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_outline_rounded,
                color:
                    isBookmarked ? AppColors.accent : AppColors.textSecondary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          GestureDetector(
            onTap: onCopy,
            child: Container(
              padding: const EdgeInsets.all(6),
              child: Icon(
                Icons.copy_rounded,
                color: AppColors.textSecondary,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSajdahBadge() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFC107).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.star_rounded,
            color: Color(0xFFFFC107),
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            'Sajdah',
            style: AppTextStyles.labelSmall.copyWith(
              color: const Color(0xFFFFC107),
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // NEW: All translations widget
  Widget _buildAllTranslations({
    required AyahModel ayah,
    required QuranFontSize fontSize,
    required bool showEnglish,
    required bool showUrdu,
    required bool showRoman,
  }) {
    return Column(
      children: [
        if (showEnglish &&
            ayah.translation != null &&
            ayah.translation!.isNotEmpty)
          _buildTranslationCard(
            label: 'English',
            text: ayah.translation!,
            fontSize: fontSize,
            color: const Color(0xFF4CAF50),
            icon: Icons.language_rounded,
          ),
        if (showUrdu &&
            ayah.translationUrdu != null &&
            ayah.translationUrdu!.isNotEmpty)
          _buildTranslationCard(
            label: 'اردو',
            text: ayah.translationUrdu!,
            fontSize: fontSize,
            color: const Color(0xFF00A86B),
            icon: Icons.translate_rounded,
            isRtl: true,
            useUrduFont: true,
          ),
        if (showRoman &&
            ayah.translationRoman != null &&
            ayah.translationRoman!.isNotEmpty)
          _buildTranslationCard(
            label: 'Roman Urdu',
            text: ayah.translationRoman!,
            fontSize: fontSize,
            color: const Color(0xFFFF9800),
            icon: Icons.abc_rounded,
          ),
      ],
    );
  }

  Widget _buildTranslationCard({
    required String label,
    required String text,
    required QuranFontSize fontSize,
    required Color color,
    required IconData icon,
    bool isRtl = false,
    bool useUrduFont = false,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: color.withValues(alpha: 0.20),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            text,
            textAlign: isRtl ? TextAlign.right : TextAlign.left,
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            style: TextStyle(
              fontFamily: useUrduFont ? 'Amiri' : null,
              fontSize: fontSize.translationSize + (useUrduFont ? 2 : 0),
              color: AppColors.textPrimary,
              height: useUrduFont ? 2.0 : 1.6,
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
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on_rounded,
            size: 12,
            color: AppColors.textTertiary,
          ),
          const SizedBox(width: 4),
          Text(
            'Page ${ayah.page}',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Icon(
            Icons.numbers_rounded,
            size: 12,
            color: AppColors.textTertiary,
          ),
          const SizedBox(width: 4),
          Text(
            '#${ayah.numberInQuran}',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SECTION 7 — APP BAR BUTTON
// ============================================================

class _AppBarButton extends StatelessWidget {
  const _AppBarButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.60),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.15),
          ),
        ),
        child: Icon(
          icon,
          color: AppColors.textPrimary,
          size: 18,
        ),
      ),
    );
  }
}

// ============================================================
// SECTION 8 — META PILL
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
        horizontal: AppSpacing.sm + 2,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.24),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 4),
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

// ============================================================
// SECTION 9 — LOADING & ERROR STATES
// ============================================================

class _ReaderLoadingState extends StatelessWidget {
  const _ReaderLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.primary,
      ),
    );
  }
}

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
            const Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: AppColors.error,
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
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              error,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textTertiary,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: AppSpacing.xl2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: onBack,
                  child: const Text('Go Back'),
                ),
                const SizedBox(width: AppSpacing.md),
                ElevatedButton(
                  onPressed: onRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SECTION 10 — FONT SIZE BOTTOM SHEET
// ============================================================

class _FontSizeBottomSheet extends ConsumerWidget {
  const _FontSizeBottomSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSize = ref.watch(_readerFontSizeProvider);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Font Size',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ...QuranFontSize.values.map((size) {
            final isSelected = size == currentSize;
            return InkWell(
              onTap: () {
                ref.read(_readerFontSizeProvider.notifier).state = size;
                HapticFeedback.selectionClick();
                Navigator.pop(context);
              },
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.15)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(
                    color:
                        isSelected ? AppColors.primary : AppColors.borderSubtle,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        size.label,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Text(
                      size.fullLabel,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    if (isSelected)
                      const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

// ============================================================
// SECTION 11 — READER SETTINGS SHEET (Multi-Language)
// ============================================================

// ============================================================
// AYAH PLAY BUTTON (NEW)
// ============================================================

class _AyahPlayButton extends ConsumerWidget {
  const _AyahPlayButton({
    required this.surahNumber,
    required this.ayahNumber,
    required this.globalAyahNumber,
  });

  final int surahNumber;
  final int ayahNumber;
  final int globalAyahNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPlaying = ref.watch(
      isAyahPlayingProvider((surah: surahNumber, ayah: ayahNumber)),
    );
    final isActive = ref.watch(
      isAyahActiveProvider((surah: surahNumber, ayah: ayahNumber)),
    );
    final audioState = ref.watch(audioProvider);

    final isLoading = isActive && audioState.isLoading;

    return GestureDetector(
      onTap: () async {
        HapticFeedback.mediumImpact();

        if (isPlaying) {
          // Pause if currently playing
          await ref.read(audioProvider.notifier).pause();
        } else if (isActive && audioState.isPaused) {
          // Resume if paused
          await ref.read(audioProvider.notifier).resume();
        } else {
          // Play new ayah
          await ref.read(audioProvider.notifier).playAyah(
                surahNumber: surahNumber,
                ayahNumber: ayahNumber,
                globalAyahNumber: globalAyahNumber,
              );
        }
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          gradient: isActive
              ? LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.accent,
                  ],
                )
              : null,
          color: isActive ? null : AppColors.surface.withValues(alpha: 0.60),
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive
                ? Colors.transparent
                : AppColors.primary.withValues(alpha: 0.25),
            width: 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: isLoading
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(
                      isActive ? Colors.white : AppColors.primary,
                    ),
                  ),
                )
              : Icon(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  color: isActive ? Colors.white : AppColors.primary,
                  size: 20,
                ),
        ),
      ),
    );
  }
}

class _ReaderSettingsSheet extends ConsumerWidget {
  const _ReaderSettingsSheet({required this.surah});

  final SurahModel surah;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showTranslation = ref.watch(_showTranslationProvider);
    final arabicOnly = ref.watch(_showArabicOnlyProvider);
    final showEnglish = ref.watch(_showEnglishProvider);
    final showUrdu = ref.watch(_showUrduProvider);
    final showRoman = ref.watch(_showRomanProvider);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Reading Settings',
            style: AppTextStyles.titleMedium.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildToggle(
            title: 'Show Translations',
            subtitle: 'Display translations below Arabic',
            value: showTranslation,
            onChanged: (v) {
              ref.read(_showTranslationProvider.notifier).state = v;
            },
          ),
          _buildToggle(
            title: 'Arabic Only',
            subtitle: 'Hide all translations',
            value: arabicOnly,
            onChanged: (v) {
              ref.read(_showArabicOnlyProvider.notifier).state = v;
            },
          ),
          const Divider(),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Translation Languages',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildToggle(
            title: 'English',
            subtitle: 'Standard English translation',
            value: showEnglish,
            onChanged: (v) {
              ref.read(_showEnglishProvider.notifier).state = v;
            },
            color: const Color(0xFF4CAF50),
          ),
          _buildToggle(
            title: 'اردو (Urdu)',
            subtitle: 'Fateh Muhammad Jalandhry',
            value: showUrdu,
            onChanged: (v) {
              ref.read(_showUrduProvider.notifier).state = v;
            },
            color: const Color(0xFF00A86B),
          ),
          _buildToggle(
            title: 'Roman Urdu',
            subtitle: 'Maududi Roman transliteration',
            value: showRoman,
            onChanged: (v) {
              ref.read(_showRomanProvider.notifier).state = v;
            },
            color: const Color(0xFFFF9800),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Widget _buildToggle({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color ?? AppColors.textPrimary,
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
            activeColor: color ?? AppColors.primary,
          ),
        ],
      ),
    );
  }
}
