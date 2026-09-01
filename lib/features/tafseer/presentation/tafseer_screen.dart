// lib/features/tafseer/presentation/tafseer_screen.dart

// ============================================================
// QIBRA AI — TAFSEER SCREEN (v2.0 — Multi-Language)
// ============================================================
// Features:
//   - 3 tabs: Translation / Tafsir / Word by Word
//   - Multiple translations (English + Urdu + Roman)
//   - Tafsir tab clearly reports when a verified tafsir
//     dataset is unavailable (never a placeholder commentary)
//   - Ayah navigation (prev/next) + font size control
//   - Copy & share via clipboard
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/content/word_by_word.dart';
import '../data/tafsir_bundle.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/qibra_colors.dart';
import '../../../shared/widgets/qibra_status.dart';
import '../../quran/data/models/quran_models.dart';
import '../../quran/providers/quran_provider.dart';

// ============================================================
// PROVIDERS
// ============================================================

// Tafsir content is intentionally not loaded from a guessed asset path.
// This repository does not currently bundle a licensed Ibn Kathir Urdu dataset.
// Do not substitute a translation for tafsir: they are different kinds of
// Islamic content and must be labelled accurately.

// Font size
final _tafsirFontSizeProvider =
    StateProvider.autoDispose<double>((ref) => 15.0);

// Current ayah
final _currentAyahProvider = StateProvider.autoDispose<int>((ref) => 1);

// ============================================================
// MAIN SCREEN
// ============================================================

class TafseerScreen extends ConsumerStatefulWidget {
  const TafseerScreen({
    super.key,
    required this.surahNumber,
    this.initialAyah = 1,
  });

  final int surahNumber;
  final int initialAyah;

  @override
  ConsumerState<TafseerScreen> createState() => _TafseerScreenState();
}

class _TafseerScreenState extends ConsumerState<TafseerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(_currentAyahProvider.notifier).state = widget.initialAyah;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    final surahAsync = ref.watch(surahDetailProvider(widget.surahNumber));
    final currentAyah = ref.watch(_currentAyahProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: surahAsync.when(
        data: (surah) {
          if (surah == null) return _buildError('Surah not found');

          return SafeArea(
            child: Column(
              children: [
                // App Bar
                _buildAppBar(surah),

                // Ayah Header
                _buildAyahHeader(surah, currentAyah),

                // Tabs
                _buildTabs(),

                // Tab Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _TranslationTab(
                        surah: surah,
                        ayahNumber: currentAyah,
                      ),
                      _TafsirTab(
                        surah: surah,
                        ayahNumber: currentAyah,
                      ),
                      _WordByWordTab(
                        surah: surah,
                        ayahNumber: currentAyah,
                      ),
                    ],
                  ),
                ),

                // Bottom Navigation
                _buildBottomNav(surah, currentAyah),
              ],
            ),
          );
        },
        loading: () => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              QibraStatus.skeleton(height: 120),
              const SizedBox(height: 12),
              QibraStatus.skeleton(height: 200),
              const SizedBox(height: 12),
              QibraStatus.skeleton(height: 200),
            ],
          ),
        ),
        error: (e, _) => _buildError(e.toString()),
      ),
    );
  }

  // ─── APP BAR ─────────────────────────

  Widget _buildAppBar(SurahModel surah) {
    final colors = QibraColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          bottom: BorderSide(color: colors.border),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors.surfaceElevated,
                shape: BoxShape.circle,
                border: Border.all(color: colors.border),
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: colors.textPrimary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Tafsir & Translation',
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          // Font size
          GestureDetector(
            onTap: _showFontSizeSheet,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors.surfaceElevated,
                shape: BoxShape.circle,
                border: Border.all(color: colors.border),
              ),
              child: Icon(
                Icons.text_fields_rounded,
                color: colors.textPrimary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // More
          GestureDetector(
            onTap: () => _showMoreOptions(),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors.surfaceElevated,
                shape: BoxShape.circle,
                border: Border.all(color: colors.border),
              ),
              child: Icon(
                Icons.more_vert_rounded,
                color: colors.textPrimary,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── AYAH HEADER ─────────────────────────

  Widget _buildAyahHeader(SurahModel surah, int ayahNumber) {
    final colors = QibraColors.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        border: Border(
          bottom: BorderSide(color: colors.border),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.primarySoft,
              shape: BoxShape.circle,
              border: Border.all(color: colors.border),
            ),
            child: Center(
              child: Text(
                '$ayahNumber',
                style: AppTextStyles.titleMedium.copyWith(
                  color: colors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ayah $ayahNumber',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${surah.name} (${surah.number}:$ayahNumber)',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── TABS ─────────────────────────

  Widget _buildTabs() {
    final colors = QibraColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          bottom: BorderSide(color: colors.border),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: colors.primary,
        indicatorWeight: 3,
        labelColor: colors.primary,
        unselectedLabelColor: colors.textSecondary,
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        tabs: const [
          Tab(text: 'Translation'),
          Tab(text: 'Tafsir'),
          Tab(text: 'Word by Word'),
        ],
      ),
    );
  }

  // ─── BOTTOM NAV ─────────────────────────

  Widget _buildBottomNav(SurahModel surah, int currentAyah) {
    final colors = QibraColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(color: colors.border),
        ),
      ),
      child: Row(
        children: [
          _navButton(
            icon: Icons.chevron_left_rounded,
            enabled: currentAyah > 1,
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(_currentAyahProvider.notifier).state--;
            },
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: colors.cardMuted,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colors.border),
              ),
              child: Text(
                'Ayah $currentAyah / ${surah.numberOfAyahs}',
                textAlign: TextAlign.center,
                style: AppTextStyles.labelLarge.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          _navButton(
            icon: Icons.chevron_right_rounded,
            enabled: currentAyah < surah.numberOfAyahs,
            onTap: () {
              HapticFeedback.selectionClick();
              ref.read(_currentAyahProvider.notifier).state++;
            },
          ),
        ],
      ),
    );
  }

  Widget _navButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final colors = QibraColors.of(context);
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: enabled ? colors.primarySoft : colors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: colors.border),
        ),
        child: Icon(
          icon,
          color: enabled ? colors.primary : colors.textTertiary,
          size: 22,
        ),
      ),
    );
  }

  // ─── DIALOGS ─────────────────────────

  void _showFontSizeSheet() {
    final colors = QibraColors.of(context);
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Consumer(
        builder: (context, ref, _) {
          final currentSize = ref.watch(_tafsirFontSizeProvider);

          return Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Font Size',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                Slider(
                  value: currentSize,
                  min: 12,
                  max: 24,
                  divisions: 12,
                  activeColor: colors.primary,
                  label: currentSize.round().toString(),
                  onChanged: (v) {
                    ref.read(_tafsirFontSizeProvider.notifier).state = v;
                  },
                ),
                Text(
                  'Size: ${currentSize.round()}px',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showMoreOptions() {
    HapticFeedback.selectionClick();
    _showToast('More options coming soon');
  }

  void _showToast(String message) {
    final colors = QibraColors.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
        backgroundColor: colors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildError(String message) {
    final colors = QibraColors.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline_rounded, size: 60, color: colors.error),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(color: colors.textPrimary),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TAB 1: TRANSLATION (Multi-language)
// ============================================================

class _TranslationTab extends ConsumerWidget {
  const _TranslationTab({
    required this.surah,
    required this.ayahNumber,
  });

  final SurahModel surah;
  final int ayahNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = QibraColors.of(context);
    final fontSize = ref.watch(_tafsirFontSizeProvider);
    final ayah = surah.getAyahByNumber(ayahNumber);

    if (ayah == null) {
      return const Center(child: Text('Ayah not found'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Arabic Text
          _buildLanguageCard(
            context,
            label: 'Arabic',
            icon: Icons.mosque_rounded,
            content: Text(
              ayah.text,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: AppArabicStyles.quranMedium.copyWith(
                fontSize: fontSize + 10,
                color: colors.textPrimary,
                height: 2.2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // English
          if (ayah.translation != null)
            _buildLanguageCard(
              context,
              label: 'English',
              icon: Icons.language_rounded,
              content: Text(
                ayah.translation!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: colors.textPrimary,
                  fontSize: fontSize,
                  height: 1.7,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          const SizedBox(height: 12),

          // Urdu
          if (ayah.translationUrdu != null)
            _buildLanguageCard(
              context,
              label: 'اردو',
              icon: Icons.translate_rounded,
              content: Text(
                ayah.translationUrdu!,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: colors.textPrimary,
                  fontSize: fontSize + 2,
                  height: 1.9,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          const SizedBox(height: 12),

          // Roman Urdu
          if (ayah.translationRoman != null)
            _buildLanguageCard(
              context,
              label: 'Roman Urdu',
              icon: Icons.abc_rounded,
              content: Text(
                ayah.translationRoman!,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: colors.textPrimary,
                  fontSize: fontSize,
                  height: 1.7,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          const SizedBox(height: 20),

          // Copy button
          _actionButton(
            context: context,
            icon: Icons.copy_rounded,
            label: 'Copy Translation',
            onTap: () {
              Clipboard.setData(ClipboardData(
                text:
                    '${ayah.text}\n\n${ayah.translation ?? ""}\n\n${ayah.translationUrdu ?? ""}',
              ));
              HapticFeedback.mediumImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Copied to clipboard'),
                  duration: Duration(seconds: 1),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageCard(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Widget content,
  }) {
    final colors = QibraColors.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colors.textSecondary, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _actionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final colors = QibraColors.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: colors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: colors.onPrimary, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: AppTextStyles.labelLarge.copyWith(
                color: colors.onPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// TAB 2: TAFSIR (Ibn Kathir Urdu)
// ============================================================

class _TafsirTab extends ConsumerWidget {
  const _TafsirTab({
    required this.surah,
    required this.ayahNumber,
  });

  final SurahModel surah;
  final int ayahNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = QibraColors.of(context);
    final fontSize = ref.watch(_tafsirFontSizeProvider);
    final ayah = surah.getAyahByNumber(ayahNumber);

    if (ayah == null) {
      return const Center(child: Text('Ayah not found'));
    }

    final tafsirAsync = ref.watch(tafsirBundleProvider);
    final TafsirPassage? passage = tafsirAsync.hasValue
        ? tafsirAsync.value?.passageFor(surah.number, ayahNumber)
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Arabic verse
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
            ),
            child: Text(
              ayah.text,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: AppArabicStyles.quranMedium.copyWith(
                fontSize: fontSize + 8,
                color: colors.textPrimary,
                height: 2.2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // A verbatim-bundled English tafsir dataset ships at
          // assets/data/tafsir (provenance: assets/data/content_manifest.json).
          // If it ever fails to load, keep the explicit unavailable state
          // rather than presenting a translation as tafsir.
          if (passage != null)
            _buildBundledPassage(context, colors, passage, fontSize)
          else
            _buildTafsirUnavailable(context, ayah),
        ],
      ),
    );
  }

  Widget _buildBundledPassage(
      BuildContext context,
      QibraColors colors,
      TafsirPassage passage,
      double fontSize) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.menu_book_rounded, size: 16, color: colors.accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Tafsir Ibn Kathir (abridged, Eng. tr.)',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: colors.accent,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              Text(
                passage.start == passage.end
                    ? 'Ayah ${passage.start}'
                    : 'Ayahs ${passage.start}–${passage.end}',
                style: AppTextStyles.labelXSmall.copyWith(
                  color: colors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            passage.text,
            style: AppTextStyles.bodyMedium.copyWith(
              fontSize: fontSize,
              color: colors.textPrimary,
              height: 1.75,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTafsirUnavailable(BuildContext context, AyahModel ayah) {
    final colors = QibraColors.of(context);
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 52,
            color: colors.textTertiary,
          ),
          const SizedBox(height: 12),
          Text(
            'Verified tafsir is not included in this build',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'A translation is shown below, but it is not a tafsir.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textTertiary,
              fontSize: 12,
            ),
          ),
          if ((ayah.translationUrdu ?? '').isNotEmpty) ...[
            const SizedBox(height: 20),
            Divider(color: colors.border),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                'اردو ترجمہ',
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              ayah.translationUrdu!,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: AppArabicStyles.quranSmall.copyWith(
                color: colors.textPrimary,
                height: 1.8,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ============================================================
// TAB 3: WORD BY WORD (Coming Soon)
// ============================================================

class _WordByWordTab extends StatelessWidget {
  const _WordByWordTab({
    required this.surah,
    required this.ayahNumber,
  });

  final SurahModel surah;
  final int ayahNumber;

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    final ayah = surah.getAyahByNumber(ayahNumber);

    if (ayah == null) {
      return const Center(child: Text('Ayah not found'));
    }

    final words = WordByWordResolver.tokenize(ayah.text);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Info card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.primarySoft,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: colors.primary, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Word tokens only. Meanings are UNKNOWN — no licensed word corpus.',
                    style: TextStyle(
                      color: colors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Words grid
          Wrap(
            textDirection: TextDirection.rtl,
            spacing: 10,
            runSpacing: 14,
            alignment: WrapAlignment.center,
            children: words.map((word) {
              final meaning = word.gloss;
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '${word.token} → UNKNOWN (not a meaning)',
                        style: const TextStyle(fontSize: 16),
                      ),
                      duration: const Duration(seconds: 2),
                      backgroundColor: colors.primary,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: colors.cardMuted,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colors.border),
                  ),
                  child: Column(
                    children: [
                      Text(
                        word.token,
                        textDirection: TextDirection.rtl,
                        style: AppArabicStyles.quranMedium.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        meaning,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Total words info
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, color: colors.textSecondary, size: 16),
                const SizedBox(width: 8),
                Text(
                  '${words.length} words in this ayah',
                  style: TextStyle(
                    color: colors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
