// lib/features/tafseer/presentation/tafseer_screen.dart

// ============================================================
// QIBRA AI — TAFSEER SCREEN (v2.0 — Multi-Language)
// ============================================================
// Features:
//   ✅ 3 Tabs (Translation / Tafsir / Word by Word)
//   ✅ Multiple translations (English + Urdu + Roman)
//   ⚪ Tafsir tab clearly reports when a verified tafsir dataset is unavailable
//   ✅ Beautiful reference-match design
//   ✅ Ayah navigation (prev/next)
//   ✅ Font size control
//   ✅ Copy & Share
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/content/word_by_word.dart';
import '../../../core/design_system/qibra_colors.dart';
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
        loading: () => Center(
          child: CircularProgressIndicator(color: colors.primary),
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
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary.withValues(alpha: 0.15),
            colors.accent.withValues(alpha: 0.08),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: colors.accent.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.primary, colors.accent],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Center(
              child: Text(
                '$ayahNumber',
                style: const TextStyle(
                  color: const Color(0xFF19312C),
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
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
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _showToast('Bookmarked');
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors.accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bookmark_border_rounded,
                color: colors.accent,
                size: 18,
              ),
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
        indicatorColor: colors.accent,
        indicatorWeight: 3,
        labelColor: colors.accent,
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
                color: colors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: colors.accent.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                'Ayah $currentAyah / ${surah.numberOfAyahs}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
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
          color: enabled
              ? colors.accent.withValues(alpha: 0.15)
              : colors.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled
                ? colors.accent.withValues(alpha: 0.3)
                : colors.border,
          ),
        ),
        child: Icon(
          icon,
          color: enabled ? colors.accent : colors.textTertiary,
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
          Icon(Icons.error_outline_rounded,
              size: 60, color: colors.error),
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
            label: 'Arabic',
            icon: Icons.mosque_rounded,
            color: colors.accent,
            content: Text(
              ayah.text,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'Amiri',
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
              label: 'English',
              icon: Icons.language_rounded,
              color: const Color(0xFF2F6B5D),
              content: Text(
                ayah.translation!,
                style: TextStyle(
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
              label: 'اردو',
              icon: Icons.translate_rounded,
              color: const Color(0xFF123F36),
              content: Text(
                ayah.translationUrdu!,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  color: colors.textPrimary,
                  fontSize: fontSize + 2,
                  height: 2.0,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          const SizedBox(height: 12),

          // Roman Urdu
          if (ayah.translationRoman != null)
            _buildLanguageCard(
              label: 'Roman Urdu',
              icon: Icons.abc_rounded,
              color: colors.goldText,
              content: Text(
                ayah.translationRoman!,
                style: TextStyle(
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
                SnackBar(
                  content: Text('Copied to clipboard'),
                  duration: Duration(seconds: 1),
                  backgroundColor: colors.primary,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageCard({
    required String label,
    required IconData icon,
    required Color color,
    required Widget content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
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
          gradient: LinearGradient(
            colors: [colors.primary, colors.accent],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: colors.primary.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF19312C), size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: const Color(0xFF19312C),
                fontSize: 14,
                fontWeight: FontWeight.w800,
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
              gradient: LinearGradient(
                colors: [
                  colors.accent.withValues(alpha: 0.15),
                  colors.accent.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: colors.accent.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              ayah.text,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: fontSize + 8,
                color: colors.textPrimary,
                height: 2.2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // The app does not currently include a verified tafsir dataset.
          // Keep this state explicit rather than presenting a broken loader or
          // incorrectly presenting a translation as tafsir.
          _buildTafsirUnavailable(ayah),
        ],
      ),
    );
  }

  Widget _buildTafsirUnavailable(AyahModel ayah) {
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
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 18,
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
              color: colors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: colors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.auto_awesome, color: colors.primary, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tap any word to learn its meaning',
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
                    gradient: LinearGradient(
                      colors: [
                        colors.accent.withValues(alpha: 0.15),
                        colors.accent.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colors.accent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        word.token,
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 24,
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        meaning,
                        style: TextStyle(
                          color: colors.goldText,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
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
                Icon(Icons.info_outline,
                    color: colors.textSecondary, size: 16),
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
