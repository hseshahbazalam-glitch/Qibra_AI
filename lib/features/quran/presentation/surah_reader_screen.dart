// lib/features/quran/presentation/surah_reader_screen.dart

// ============================================================
// QIBRA AI — SURAH READER SCREEN (v3.0 — Simple Reader)
// ============================================================
// Peaceful reading experience:
// - Continuous Arabic text (full surah flowing)
// - Translations below
// - Single play button
// - No clutter (bookmark/copy moved to Tafseer)
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
import '../../tafseer/presentation/tafseer_screen.dart';

// ============================================================
// FONT SIZE ENUM
// ============================================================

enum QuranFontSize {
  small,
  medium,
  large,
  extraLarge;

  double get arabicSize {
    return switch (this) {
      QuranFontSize.small => 22.0,
      QuranFontSize.medium => 28.0,
      QuranFontSize.large => 34.0,
      QuranFontSize.extraLarge => 40.0,
    };
  }

  double get translationSize {
    return switch (this) {
      QuranFontSize.small => 13.0,
      QuranFontSize.medium => 15.0,
      QuranFontSize.large => 17.0,
      QuranFontSize.extraLarge => 19.0,
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
// LOCAL PROVIDERS
// ============================================================

final _readerFontSizeProvider =
    StateProvider.autoDispose<QuranFontSize>((ref) => QuranFontSize.medium);

final _showEnglishProvider = StateProvider.autoDispose<bool>((ref) => true);
final _showUrduProvider = StateProvider.autoDispose<bool>((ref) => true);
final _showRomanProvider = StateProvider.autoDispose<bool>((ref) => false);

// ============================================================
// MAIN SCREEN
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

class _SurahReaderScreenState extends ConsumerState<SurahReaderScreen> {
  final ScrollController _scrollController = ScrollController();
  bool _hasTrackedInitialRead = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _updateLastRead(SurahModel surah, int ayahNumber) {
    ref.read(lastReadProvider.notifier).updateLastRead(
          surahNumber: surah.number,
          ayahNumber: ayahNumber,
          surahName: surah.name,
          totalAyahsInSurah: surah.numberOfAyahs,
        );
  }

  void _showFontSizeSheet() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _FontSizeBottomSheet(),
    );
  }

  void _showSettingsSheet() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => const _ReaderSettingsSheet(),
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
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (error, _) => _buildError(error.toString()),
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
              _buildAppBar(surah),
              SliverToBoxAdapter(
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
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.lg,
                    0,
                  ),
                  child: _PlayFullSurahButton(surah: surah),
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
              // Continuous flowing Arabic text
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.lg,
                    AppSpacing.lg,
                    0,
                  ),
                  child: _ArabicContinuousText(surah: surah),
                ),
              ),
              // Translations
              SliverToBoxAdapter(
                child: _TranslationsSection(surah: surah),
              ),
              // Tafseer button
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.xl,
                    AppSpacing.lg,
                    AppSpacing.xl3 + AppSpacing.xl4 + AppSpacing.xl3,
                  ),
                  child: _TafseerButton(surah: surah),
                ),
              ),
            ],
          ),
        ),
        // Audio player at bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: QuranMiniPlayer(surahName: surah.name),
        ),
      ],
    );
  }

  Widget _buildAppBar(SurahModel surah) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      pinned: true,
      toolbarHeight: 64,
      leading: const SizedBox.shrink(),
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            color: AppColors.background.withValues(alpha: 0.7),
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
                _AppBarButton(
                  icon: Icons.text_fields_rounded,
                  onTap: _showFontSizeSheet,
                ),
                const SizedBox(width: AppSpacing.sm),
                _AppBarButton(
                  icon: Icons.tune_rounded,
                  onTap: _showSettingsSheet,
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off_rounded,
                size: 64, color: AppColors.textTertiary),
            const SizedBox(height: AppSpacing.lg),
            Text('Surah not found',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                )),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String error) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 64, color: AppColors.error),
            const SizedBox(height: AppSpacing.lg),
            Text('Unable to Load Surah',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                )),
            const SizedBox(height: AppSpacing.md),
            ElevatedButton(
              onPressed: () =>
                  ref.invalidate(surahDetailProvider(widget.surahNumber)),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SURAH HEADER CARD
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
      child: Column(
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
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================
// PLAY FULL SURAH BUTTON
// ============================================================

class _PlayFullSurahButton extends ConsumerWidget {
  const _PlayFullSurahButton({required this.surah});

  final SurahModel surah;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioState = ref.watch(audioProvider);
    final isThisSurahActive = audioState.surahNumber == surah.number;
    final isPlaying = isThisSurahActive && audioState.isPlaying;
    final isPaused = isThisSurahActive && audioState.isPaused;
    final isLoading = isThisSurahActive && audioState.isLoading;

    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            HapticFeedback.mediumImpact();

            if (isPlaying) {
              await ref.read(audioProvider.notifier).pause();
            } else if (isPaused) {
              await ref.read(audioProvider.notifier).resume();
            } else if (surah.ayahs.isNotEmpty) {
              final firstAyah = surah.ayahs.first;
              await ref.read(audioProvider.notifier).playAyah(
                    surahNumber: surah.number,
                    ayahNumber: firstAyah.number,
                    globalAyahNumber: firstAyah.numberInQuran,
                  );
            }
          },
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md + 4,
            ),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.accent],
              ),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                else
                  Icon(
                    isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  isLoading
                      ? 'Loading...'
                      : isPlaying
                          ? 'Playing Surah'
                          : isPaused
                              ? 'Resume Surah'
                              : 'Play Full Surah',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
                if (isPlaying || isPaused) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Ayah ${audioState.ayahNumber}',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// BISMILLAH
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
      child: const Column(
        children: [
          Text(
            'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 28,
              color: AppColors.accent,
              fontWeight: FontWeight.w600,
              height: 1.8,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ARABIC CONTINUOUS TEXT (FULL SURAH)
// ============================================================

class _ArabicContinuousText extends ConsumerWidget {
  const _ArabicContinuousText({required this.surah});

  final SurahModel surah;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontSize = ref.watch(_readerFontSizeProvider);

    // Build continuous text with ayah numbers
    final buffer = StringBuffer();
    for (int i = 0; i < surah.ayahs.length; i++) {
      final ayah = surah.ayahs[i];
      buffer.write(ayah.text);
      buffer.write(' ﴿${_toArabicNumeral(ayah.number)}﴾ ');
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.60),
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.15),
        ),
      ),
      child: Text(
        buffer.toString(),
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        style: TextStyle(
          fontFamily: 'Amiri',
          fontSize: fontSize.arabicSize,
          color: AppColors.textPrimary,
          height: 2.4,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  String _toArabicNumeral(int number) {
    const arabicDigits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return number
        .toString()
        .split('')
        .map((d) => arabicDigits[int.parse(d)])
        .join();
  }
}

// ============================================================
// TRANSLATIONS SECTION
// ============================================================

class _TranslationsSection extends ConsumerWidget {
  const _TranslationsSection({required this.surah});

  final SurahModel surah;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontSize = ref.watch(_readerFontSizeProvider);
    final showEnglish = ref.watch(_showEnglishProvider);
    final showUrdu = ref.watch(_showUrduProvider);
    final showRoman = ref.watch(_showRomanProvider);

    // Build continuous translations
    final englishBuffer = StringBuffer();
    final urduBuffer = StringBuffer();
    final romanBuffer = StringBuffer();

    for (int i = 0; i < surah.ayahs.length; i++) {
      final ayah = surah.ayahs[i];
      if (ayah.translation != null) {
        englishBuffer.write('${ayah.translation} (${ayah.number}) ');
      }
      if (ayah.translationUrdu != null) {
        urduBuffer.write('${ayah.translationUrdu} (${ayah.number}) ');
      }
      if (ayah.translationRoman != null) {
        romanBuffer.write('${ayah.translationRoman} (${ayah.number}) ');
      }
    }

    return Column(
      children: [
        if (showEnglish && englishBuffer.isNotEmpty)
          _TranslationBlock(
            label: 'English Translation',
            text: englishBuffer.toString(),
            color: const Color(0xFF4CAF50),
            icon: Icons.language_rounded,
            fontSize: fontSize.translationSize,
          ),
        if (showUrdu && urduBuffer.isNotEmpty)
          _TranslationBlock(
            label: 'اردو ترجمہ',
            text: urduBuffer.toString(),
            color: const Color(0xFF00A86B),
            icon: Icons.translate_rounded,
            fontSize: fontSize.translationSize + 3,
            isRtl: true,
            useUrduFont: true,
          ),
        if (showRoman && romanBuffer.isNotEmpty)
          _TranslationBlock(
            label: 'Roman Urdu',
            text: romanBuffer.toString(),
            color: const Color(0xFFFF9800),
            icon: Icons.abc_rounded,
            fontSize: fontSize.translationSize,
          ),
      ],
    );
  }
}

class _TranslationBlock extends StatelessWidget {
  const _TranslationBlock({
    required this.label,
    required this.text,
    required this.color,
    required this.icon,
    required this.fontSize,
    this.isRtl = false,
    this.useUrduFont = false,
  });

  final String label;
  final String text;
  final Color color;
  final IconData icon;
  final double fontSize;
  final bool isRtl;
  final bool useUrduFont;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.xl2),
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
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            text,
            textAlign: isRtl ? TextAlign.right : TextAlign.left,
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            style: TextStyle(
              fontFamily: useUrduFont ? 'Amiri' : null,
              fontSize: fontSize,
              color: AppColors.textPrimary,
              height: useUrduFont ? 2.2 : 1.7,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TAFSEER BUTTON (Coming Soon)
// ============================================================

class _TafseerButton extends StatelessWidget {
  const _TafseerButton({required this.surah});

  final SurahModel surah;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TafseerScreen(
                  surahNumber: surah.number,
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md + 4,
            ),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated.withValues(alpha: 0.70),
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.30),
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.menu_book_rounded,
                  color: AppColors.accent,
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Open Tafseer Ibn Kathir',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.accent,
                  size: 20,
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
// APP BAR BUTTON
// ============================================================

class _AppBarButton extends StatelessWidget {
  const _AppBarButton({required this.icon, required this.onTap});

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
        child: Icon(icon, color: AppColors.textPrimary, size: 18),
      ),
    );
  }
}

// ============================================================
// META PILL
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
        border: Border.all(color: color.withValues(alpha: 0.24), width: 0.8),
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
// FONT SIZE BOTTOM SHEET
// ============================================================

class _FontSizeBottomSheet extends ConsumerWidget {
  const _FontSizeBottomSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSize = ref.watch(_readerFontSizeProvider);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
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
          Text('Font Size',
              style: AppTextStyles.titleMedium
                  .copyWith(fontWeight: FontWeight.w800)),
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
                      const Icon(Icons.check_circle_rounded,
                          color: AppColors.primary, size: 20),
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
// READER SETTINGS SHEET
// ============================================================

class _ReaderSettingsSheet extends ConsumerWidget {
  const _ReaderSettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showEnglish = ref.watch(_showEnglishProvider);
    final showUrdu = ref.watch(_showUrduProvider);
    final showRoman = ref.watch(_showRomanProvider);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(
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
          Text('Translation Languages',
              style: AppTextStyles.titleMedium.copyWith(
                fontWeight: FontWeight.w800,
              )),
          const SizedBox(height: AppSpacing.lg),
          _buildToggle(
            title: 'English',
            subtitle: 'Standard English translation',
            value: showEnglish,
            onChanged: (v) => ref.read(_showEnglishProvider.notifier).state = v,
            color: const Color(0xFF4CAF50),
          ),
          _buildToggle(
            title: 'اردو',
            subtitle: 'Fateh Muhammad Jalandhry',
            value: showUrdu,
            onChanged: (v) => ref.read(_showUrduProvider.notifier).state = v,
            color: const Color(0xFF00A86B),
          ),
          _buildToggle(
            title: 'Roman Urdu',
            subtitle: 'Maududi Roman transliteration',
            value: showRoman,
            onChanged: (v) => ref.read(_showRomanProvider.notifier).state = v,
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
            activeThumbColor: color ?? AppColors.primary,
          ),
        ],
      ),
    );
  }
}
