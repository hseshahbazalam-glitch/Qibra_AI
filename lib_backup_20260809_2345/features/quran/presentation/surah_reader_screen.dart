// lib/features/quran/presentation/surah_reader_screen.dart

// ============================================================
// QIBRA AI — SURAH READER (v7.0 — No Audio Dependencies)
// ============================================================

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ayah_options_sheet.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_design_system.dart';
import '../../../core/design_system/app_typography.dart';
import '../data/models/quran_models.dart';
import '../providers/quran_provider.dart';

// ============================================================
// FONT SIZE ENUM
// ============================================================

enum QuranFontSize {
  small,
  medium,
  large,
  extraLarge;

  double get arabicSize => switch (this) {
        QuranFontSize.small => 22.0,
        QuranFontSize.medium => 26.0,
        QuranFontSize.large => 30.0,
        QuranFontSize.extraLarge => 34.0,
      };

  double get translationSize => switch (this) {
        QuranFontSize.small => 13.0,
        QuranFontSize.medium => 15.0,
        QuranFontSize.large => 17.0,
        QuranFontSize.extraLarge => 19.0,
      };

  String get label => switch (this) {
        QuranFontSize.small => 'S',
        QuranFontSize.medium => 'M',
        QuranFontSize.large => 'L',
        QuranFontSize.extraLarge => 'XL',
      };

  String get fullLabel => switch (this) {
        QuranFontSize.small => 'Small',
        QuranFontSize.medium => 'Medium',
        QuranFontSize.large => 'Large',
        QuranFontSize.extraLarge => 'Extra Large',
      };
}

// ============================================================
// PROVIDERS
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
    return Container(
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
              0,
            ),
            sliver: SliverList.separated(
              itemCount: surah.ayahs.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final ayah = surah.ayahs[index];
                return _AyahCard(
                  ayah: ayah,
                  surahNumber: surah.number,
                  surahName: surah.name,
                );
              },
            ),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: AppSpacing.xl3),
          ),
        ],
      ),
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
      child: Center(
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
      child: Center(
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
// AYAH CARD
// ============================================================

class _AyahCard extends ConsumerWidget {
  const _AyahCard({
    required this.ayah,
    required this.surahNumber,
    required this.surahName,
  });

  final AyahModel ayah;
  final int surahNumber;
  final String surahName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontSize = ref.watch(_readerFontSizeProvider);
    final showEnglish = ref.watch(_showEnglishProvider);
    final showUrdu = ref.watch(_showUrduProvider);
    final showRoman = ref.watch(_showRomanProvider);

    return GestureDetector(
      onLongPress: () {
        HapticFeedback.mediumImpact();
        showAyahOptions(
          context: context,
          surahNumber: surahNumber,
          ayahNumber: ayah.number,
          surahName: surahName,
          ayah: ayah,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated.withValues(alpha: 0.60),
          borderRadius: BorderRadius.circular(AppRadius.xl2),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.10),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Bar
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                showAyahOptions(
                  context: context,
                  surahNumber: surahNumber,
                  ayahNumber: ayah.number,
                  surahName: surahName,
                  ayah: ayah,
                );
              },
              child: Container(
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
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.60),
                            AppColors.accent.withValues(alpha: 0.40),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          ayah.number.toString(),
                          style: AppTextStyles.labelMedium.copyWith(
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Page ${ayah.page}',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textTertiary,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.more_horiz_rounded,
                            color: AppColors.accent,
                            size: 14,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Arabic Text
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
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // Translations
            if (showEnglish && ayah.translation != null)
              _buildTranslation(
                label: 'English',
                text: ayah.translation!,
                color: const Color(0xFF4CAF50),
                icon: Icons.language_rounded,
                fontSize: fontSize.translationSize,
              ),

            if (showUrdu && ayah.translationUrdu != null)
              _buildTranslation(
                label: 'اردو',
                text: ayah.translationUrdu!,
                color: const Color(0xFF00A86B),
                icon: Icons.translate_rounded,
                fontSize: fontSize.translationSize + 2,
                isRtl: true,
                useUrduFont: true,
              ),

            if (showRoman && ayah.translationRoman != null)
              _buildTranslation(
                label: 'Roman Urdu',
                text: ayah.translationRoman!,
                color: const Color(0xFFFF9800),
                icon: Icons.abc_rounded,
                fontSize: fontSize.translationSize,
              ),

            const SizedBox(height: AppSpacing.sm),
          ],
        ),
      ),
    );
  }

  Widget _buildTranslation({
    required String label,
    required String text,
    required Color color,
    required IconData icon,
    required double fontSize,
    bool isRtl = false,
    bool useUrduFont = false,
  }) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: color.withValues(alpha: 0.20),
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
              fontSize: fontSize,
              color: AppColors.textPrimary,
              height: useUrduFont ? 2.0 : 1.6,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
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
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              gradient: AppGradients.gold,
              shape: BoxShape.circle,
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
      child: const Text(
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
