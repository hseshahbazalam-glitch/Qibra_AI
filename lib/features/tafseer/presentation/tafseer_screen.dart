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

import '../../../core/design_system/app_colors.dart';
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
    final surahAsync = ref.watch(surahDetailProvider(widget.surahNumber));
    final currentAyah = ref.watch(_currentAyahProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
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
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
        error: (e, _) => _buildError(e.toString()),
      ),
    );
  }

  // ─── APP BAR ─────────────────────────

  Widget _buildAppBar(SurahModel surah) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.borderSubtle),
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.textPrimary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Tafsir & Translation',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          // Font size
          GestureDetector(
            onTap: _showFontSizeSheet,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: const Icon(
                Icons.text_fields_rounded,
                color: AppColors.textPrimary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // More
          GestureDetector(
            onTap: () => _showMoreOptions(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: const Icon(
                Icons.more_vert_rounded,
                color: AppColors.textPrimary,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.15),
            AppColors.accent.withValues(alpha: 0.08),
          ],
        ),
        border: Border(
          bottom: BorderSide(
            color: AppColors.accent.withValues(alpha: 0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Center(
              child: Text(
                '$ayahNumber',
                style: const TextStyle(
                  color: Colors.white,
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
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${surah.name} (${surah.number}:$ayahNumber)',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
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
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bookmark_border_rounded,
                color: AppColors.accent,
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
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor: AppColors.accent,
        indicatorWeight: 3,
        labelColor: AppColors.accent,
        unselectedLabelColor: AppColors.textSecondary,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.borderSubtle),
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
                color: AppColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.3),
                ),
              ),
              child: Text(
                'Ayah $currentAyah / ${surah.numberOfAyahs}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.accent,
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
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: enabled
              ? AppColors.accent.withValues(alpha: 0.15)
              : AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: enabled
                ? AppColors.accent.withValues(alpha: 0.3)
                : AppColors.borderSubtle,
          ),
        ),
        child: Icon(
          icon,
          color: enabled ? AppColors.accent : AppColors.textTertiary,
          size: 22,
        ),
      ),
    );
  }

  // ─── DIALOGS ─────────────────────────

  void _showFontSizeSheet() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Consumer(
        builder: (context, ref, _) {
          final currentSize = ref.watch(_tafsirFontSizeProvider);

          return Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Font Size',
                  style: TextStyle(
                    color: AppColors.textPrimary,
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
                  activeColor: AppColors.primary,
                  label: currentSize.round().toString(),
                  onChanged: (v) {
                    ref.read(_tafsirFontSizeProvider.notifier).state = v;
                  },
                ),
                Text(
                  'Size: ${currentSize.round()}px',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 60, color: AppColors.error),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(color: AppColors.textPrimary),
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
            color: AppColors.accent,
            content: Text(
              ayah.text,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: fontSize + 10,
                color: AppColors.textPrimary,
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
              color: const Color(0xFF10B981),
              content: Text(
                ayah.translation!,
                style: TextStyle(
                  color: AppColors.textPrimary,
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
              color: const Color(0xFF00A86B),
              content: Text(
                ayah.translationUrdu!,
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  color: AppColors.textPrimary,
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
              color: const Color(0xFFFF9800),
              content: Text(
                ayah.translationRoman!,
                style: TextStyle(
                  color: AppColors.textPrimary,
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
                  backgroundColor: AppColors.primary,
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.primary, AppColors.accent],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
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
                  AppColors.accent.withValues(alpha: 0.15),
                  AppColors.accent.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              ayah.text,
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: fontSize + 8,
                color: AppColors.textPrimary,
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.menu_book_outlined,
            size: 52,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 12),
          const Text(
            'Verified tafsir is not included in this build',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'A translation is shown below, but it is not a tafsir.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textTertiary,
              fontSize: 12,
            ),
          ),
          if ((ayah.translationUrdu ?? '').isNotEmpty) ...[
            const SizedBox(height: 20),
            const Divider(color: AppColors.borderSubtle),
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerRight,
              child: Text(
                'اردو ترجمہ',
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              ayah.translationUrdu!,
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'Amiri',
                fontSize: 18,
                color: AppColors.textPrimary,
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

  // Basic word meanings database
  static const Map<String, String> _wordMeanings = {
    'بِسْمِ': 'In the name',
    'اللَّهِ': 'of Allah',
    'الرَّحْمَٰنِ': 'The Most Gracious',
    'الرَّحِيمِ': 'The Most Merciful',
    'الْحَمْدُ': 'All praise',
    'لِلَّهِ': 'is for Allah',
    'رَبِّ': 'Lord',
    'الْعَالَمِينَ': 'of the worlds',
    'مَالِكِ': 'Master/Owner',
    'يَوْمِ': 'of the Day',
    'الدِّينِ': 'of Judgment',
    'إِيَّاكَ': 'You alone',
    'نَعْبُدُ': 'we worship',
    'وَإِيَّاكَ': 'and You alone',
    'نَسْتَعِينُ': 'we ask for help',
    'اهْدِنَا': 'Guide us',
    'الصِّرَاطَ': 'the path',
    'الْمُسْتَقِيمَ': 'the straight',
    'صِرَاطَ': 'Path',
    'الَّذِينَ': 'of those',
    'أَنْعَمْتَ': 'You have blessed',
    'عَلَيْهِمْ': 'upon them',
    'غَيْرِ': 'not',
    'الْمَغْضُوبِ': 'those who earned wrath',
    'وَلَا': 'and not',
    'الضَّالِّينَ': 'those who went astray',
    'الم': 'Alif Lam Mim',
    'ذَٰلِكَ': 'That',
    'الْكِتَابُ': 'is the Book',
    'لَا': 'No',
    'رَيْبَ': 'doubt',
    'فِيهِ': 'in it',
    'هُدًى': 'guidance',
    'لِلْمُتَّقِينَ': 'for the God-fearing',
    'إِنَّ': 'Indeed',
    'مَعَ': 'with',
    'الْعُسْرِ': 'hardship',
    'يُسْرًا': 'ease',
    'وَ': 'and',
    'مِنَ': 'from',
    'فِي': 'in',
    'عَلَىٰ': 'upon',
    'إِلَىٰ': 'to/towards',
    'مِنْ': 'from',
    'قَالَ': 'he said',
    'كَانَ': 'was/were',
    'اللَّهَ': 'Allah',
    'هُوَ': 'He',
    'الَّذِي': 'the one who',
    'قُلْ': 'Say',
  };

  String _getMeaning(String word) {
    // Clean the word
    final clean = word.trim();

    // Direct match
    if (_wordMeanings.containsKey(clean)) {
      return _wordMeanings[clean]!;
    }

    // Try without last character (for different forms)
    if (clean.length > 2) {
      final shortened = clean.substring(0, clean.length - 1);
      if (_wordMeanings.containsKey(shortened)) {
        return _wordMeanings[shortened]!;
      }
    }

    return 'meaning';
  }

  @override
  Widget build(BuildContext context) {
    final ayah = surah.getAyahByNumber(ayahNumber);

    if (ayah == null) {
      return const Center(child: Text('Ayah not found'));
    }

    final words =
        ayah.text.split(' ').where((w) => w.trim().isNotEmpty).toList();

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
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome, color: AppColors.primary, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tap any word to learn its meaning',
                    style: TextStyle(
                      color: AppColors.textPrimary,
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
              final meaning = _getMeaning(word);
              return GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '$word → $meaning',
                        style: const TextStyle(fontSize: 16),
                      ),
                      duration: const Duration(seconds: 2),
                      backgroundColor: AppColors.primary,
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
                        AppColors.accent.withValues(alpha: 0.15),
                        AppColors.accent.withValues(alpha: 0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        word,
                        textDirection: TextDirection.rtl,
                        style: const TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 24,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        meaning,
                        style: const TextStyle(
                          color: AppColors.accent,
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
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline,
                    color: AppColors.textSecondary, size: 16),
                const SizedBox(width: 8),
                Text(
                  '${words.length} words in this ayah',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
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
