// lib/features/duas/presentation/dua_detail_screen.dart

// ============================================================
// QIBRA AI — DUA DETAIL SCREEN
// Full dua with all details, share, copy
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qibra_ai/core/design_system/qibra_colors.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';
import 'package:qibra_ai/features/duas/providers/dua_provider.dart';

class DuaDetailScreen extends ConsumerStatefulWidget {
  final String duaId;

  const DuaDetailScreen({super.key, required this.duaId});

  @override
  ConsumerState<DuaDetailScreen> createState() => _DuaDetailScreenState();
}

class _DuaDetailScreenState extends ConsumerState<DuaDetailScreen> {
  bool _showTransliteration = true;
  bool _showUrdu = true;
  bool _showEnglish = true;

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    final dua = ref.watch(duaByIdProvider(widget.duaId));

    if (dua == null) {
      return Scaffold(
        backgroundColor: colors.background,
        body: SafeArea(
          child: Center(
            child: Text('Dua not found'),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // APP BAR
            SliverAppBar(
              pinned: true,
              backgroundColor: colors.background,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.border),
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 16,
                    color: colors.textPrimary,
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                // Favorite button
                IconButton(
                  icon: Icon(
                    dua.isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: dua.isFavorite
                        ? const Color(0xFFFF6B6B)
                        : colors.textSecondary,
                  ),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    ref
                        .read(favoriteDuaIdsProvider.notifier)
                        .toggleFavorite(dua.id);
                  },
                ),
                // Share button
                IconButton(
                  icon: Icon(
                    Icons.share_rounded,
                    color: colors.textSecondary,
                  ),
                  onPressed: () => _shareDua(),
                ),
                // Copy button
                IconButton(
                  icon: Icon(
                    Icons.copy_rounded,
                    color: colors.textSecondary,
                  ),
                  onPressed: () => _copyDua(),
                ),
              ],
              title: Text(
                'Dua',
                style: AppTextStyles.titleMedium,
              ),
            ),

            // CONTENT
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTitleCard(
                      dua.titleEnglish,
                      dua.titleUrdu,
                      dua.titleArabic,
                      dua.grade,
                    ),
                    const SizedBox(height: 20),
                    _buildArabicCard(dua.arabic),
                    const SizedBox(height: 16),
                    _buildToggles(),
                    const SizedBox(height: 16),
                    if (_showTransliteration)
                      _buildInfoCard(
                        icon: Icons.translate_rounded,
                        iconColor: const Color(0xFF123F36),
                        label: 'Transliteration',
                        content: dua.transliteration,
                        isItalic: true,
                      ),
                    if (_showUrdu)
                      _buildInfoCard(
                        icon: Icons.language_rounded,
                        iconColor: const Color(0xFFC6A15B),
                        label: 'Urdu Translation',
                        content: dua.translationUrdu,
                        isRtl: true,
                      ),
                    if (_showEnglish)
                      _buildInfoCard(
                        icon: Icons.article_rounded,
                        iconColor: const Color(0xFF2F6B5D),
                        label: 'English Translation',
                        content: dua.translationEnglish,
                      ),
                    const SizedBox(height: 8),
                    _buildReferenceCard(
                      dua.reference,
                      dua.referenceBook,
                      dua.referenceNumber,
                      dua.grade,
                    ),
                    const SizedBox(height: 16),
                    _buildDetailSection(
                      icon: '🕐',
                      title: 'When to Recite',
                      content: dua.whenToRecite,
                    ),
                    _buildDetailSection(
                      icon: '📿',
                      title: 'How to Recite',
                      content: dua.howToRecite,
                    ),
                    _buildDetailSection(
                      icon: '✨',
                      title: 'Benefits & Fazilat',
                      content: dua.benefits,
                      isHighlighted: true,
                    ),
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TITLE CARD
  // ============================================================

  Widget _buildTitleCard(
    String titleEn,
    String titleUr,
    String titleAr,
    String grade,
  ) {
    final colors = QibraColors.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF123F36),
            Color(0xFF123F36),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titleEn,
                      style: AppTextStyles.titleLarge.copyWith(
                        color: colors.onPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      titleUr,
                      style: AppTextStyles.arabicSmall.copyWith(
                        color: colors.onPrimary.withValues(alpha: 0.8),
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: colors.onPrimary.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  grade,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: colors.onPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            titleAr,
            style: AppTextStyles.arabicMedium.copyWith(
              color: colors.onPrimary.withValues(alpha: 0.9),
              fontSize: 18,
            ),
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ARABIC TEXT CARD
  // ============================================================

  Widget _buildArabicCard(String arabic) {
    final colors = QibraColors.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.05),
            blurRadius: 20,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: 18,
                decoration: BoxDecoration(
                  gradient: AppGradients.emerald,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Arabic Text',
                style: AppTextStyles.labelMedium.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            arabic,
            style: AppTextStyles.arabicLarge.copyWith(
              fontSize: 24,
              height: 2.2,
              color: colors.textPrimary,
            ),
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TOGGLES ROW
  // ============================================================

  Widget _buildToggles() {
    final colors = QibraColors.of(context);
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          _buildToggleBtn(
            'Transliteration',
            _showTransliteration,
            () => setState(() => _showTransliteration = !_showTransliteration),
          ),
          _buildToggleBtn(
            'Urdu',
            _showUrdu,
            () => setState(() => _showUrdu = !_showUrdu),
          ),
          _buildToggleBtn(
            'English',
            _showEnglish,
            () => setState(() => _showEnglish = !_showEnglish),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleBtn(String label, bool isOn, VoidCallback onTap) {
    final colors = QibraColors.of(context);
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: AppDurations.fast,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isOn ? colors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: isOn ? colors.onPrimary : colors.textSecondary,
              fontWeight: isOn ? FontWeight.w700 : FontWeight.w500,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // INFO CARD (Translation, Transliteration)
  // ============================================================

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String content,
    bool isItalic = false,
    bool isRtl = false,
  }) {
    final colors = QibraColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTextStyles.labelMedium.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: isRtl
                ? AppTextStyles.arabicSmall.copyWith(
                    fontSize: 14,
                    height: 1.8,
                    color: colors.textPrimary,
                  )
                : AppTextStyles.bodyMedium.copyWith(
                    height: 1.7,
                    fontStyle: isItalic ? FontStyle.italic : FontStyle.normal,
                  ),
            textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
            textAlign: isRtl ? TextAlign.right : TextAlign.left,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // REFERENCE CARD
  // ============================================================

  Widget _buildReferenceCard(
    String reference,
    String book,
    String number,
    String grade,
  ) {
    final colors = QibraColors.of(context);
    Color gradeColor;
    switch (grade.toLowerCase()) {
      case 'sahih':
        gradeColor = colors.primary;
        break;
      case 'hasan':
        gradeColor = const Color(0xFF123F36);
        break;
      case 'quran':
        gradeColor = const Color(0xFFC6A15B);
        break;
      default:
        gradeColor = colors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: gradeColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: gradeColor.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.verified_rounded,
            color: gradeColor,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reference,
                  style: AppTextStyles.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Hadith #$number',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 5,
            ),
            decoration: BoxDecoration(
              color: gradeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              grade,
              style: AppTextStyles.labelSmall.copyWith(
                color: gradeColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DETAIL SECTION (When, How, Benefits)
  // ============================================================

  Widget _buildDetailSection({
    required String icon,
    required String title,
    required String content,
    bool isHighlighted = false,
  }) {
    final colors = QibraColors.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighlighted
            ? colors.primary.withValues(alpha: 0.06)
            : colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlighted
              ? colors.primary.withValues(alpha: 0.2)
              : colors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color:
                      isHighlighted ? colors.primary : colors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: AppTextStyles.bodyMedium.copyWith(
              height: 1.7,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ACTIONS
  // ============================================================

  void _copyDua() {
    final colors = QibraColors.of(context);
    final dua = ref.read(duaByIdProvider(widget.duaId));
    if (dua == null) return;

    final text = '''${dua.titleEnglish}

${dua.arabic}

${dua.transliteration}

Urdu: ${dua.translationUrdu}

English: ${dua.translationEnglish}

Reference: ${dua.reference} (${dua.grade})

— QIBRA AI''';

    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: const Color(0xFF19312C), size: 18),
            const SizedBox(width: 10),
            Text(
              'Dua copied to clipboard',
              style: AppTextStyles.labelMedium.copyWith(
                color: colors.onPrimary,
              ),
            ),
          ],
        ),
        backgroundColor: colors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _shareDua() {
    final colors = QibraColors.of(context);
    final dua = ref.read(duaByIdProvider(widget.duaId));
    if (dua == null) return;

    final text = '''🤲 ${dua.titleEnglish}

${dua.arabic}

${dua.transliteration}

"${dua.translationEnglish}"

📚 ${dua.reference} — ${dua.grade}

Shared via QIBRA AI''';

    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.mediumImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.share_rounded, color: const Color(0xFF19312C), size: 18),
            const SizedBox(width: 10),
            Text(
              'Copied — paste to share anywhere',
              style: AppTextStyles.labelMedium.copyWith(
                color: colors.onPrimary,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF123F36),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
