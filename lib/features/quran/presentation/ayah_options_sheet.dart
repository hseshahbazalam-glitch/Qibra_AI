// lib/features/quran/presentation/ayah_options_sheet.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../ai/presentation/ai_explain_screen.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/qibra_colors.dart';
import '../../../shared/widgets/qibra_ui.dart';
import '../../tafseer/presentation/tafseer_screen.dart';
import '../data/models/quran_models.dart';
import 'surah_reader_screen.dart';

Future<void> showAyahOptions({
  required BuildContext context,
  required int surahNumber,
  required int ayahNumber,
  required String surahName,
  AyahModel? ayah,
}) async {
  HapticFeedback.mediumImpact();

  await showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (_) => AyahOptionsSheet(
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      surahName: surahName,
      ayah: ayah,
    ),
  );
}

class AyahOptionsSheet extends ConsumerStatefulWidget {
  const AyahOptionsSheet({
    super.key,
    required this.surahNumber,
    required this.ayahNumber,
    required this.surahName,
    this.ayah,
  });

  final int surahNumber;
  final int ayahNumber;
  final String surahName;
  final AyahModel? ayah;

  @override
  ConsumerState<AyahOptionsSheet> createState() => _AyahOptionsSheetState();
}

class _AyahOptionsSheetState extends ConsumerState<AyahOptionsSheet> {
  bool _isFavorite = false;
  bool _isBookmarked = false;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    final key = 'ayah_${widget.surahNumber}_${widget.ayahNumber}';
    setState(() {
      _isFavorite = prefs.getBool('${key}_fav') ?? false;
      _isBookmarked = prefs.getBool('${key}_bookmark') ?? false;
    });
  }

  Future<void> _saveState() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'ayah_${widget.surahNumber}_${widget.ayahNumber}';
    await prefs.setBool('${key}_fav', _isFavorite);
    await prefs.setBool('${key}_bookmark', _isBookmarked);
  }

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              decoration: BoxDecoration(
                color: colors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _buildHeader(),
            Divider(color: colors.border, height: 1),
            const SizedBox(height: 20),
            _buildPrimaryActions(),
            const SizedBox(height: 16),
            _buildSecondaryActions(),
            const SizedBox(height: 24),
            _buildRelatedContent(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final colors = QibraColors.of(context);
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: colors.cardMuted,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: colors.border),
                      ),
                      child: Text(
                        'AYAH ${widget.ayahNumber}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: colors.primary,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    if (widget.ayah != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        'Juz ${widget.ayah!.juz}',
                        style: AppTextStyles.labelSmall
                            .copyWith(color: colors.textTertiary),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  widget.surahName,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${widget.surahNumber}:${widget.ayahNumber}',
                  style: AppTextStyles.bodySmall
                      .copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ),
          Row(
            children: [
              GestureDetector(
                onTap: () async {
                  HapticFeedback.selectionClick();
                  setState(() => _isFavorite = !_isFavorite);
                  await _saveState();
                  _showToast(_isFavorite
                      ? 'Added to favorites'
                      : 'Removed from favorites');
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _isFavorite
                        ? colors.primarySoft
                        : colors.cardMuted,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.border),
                  ),
                  child: Icon(
                    _isFavorite
                        ? Icons.star_rounded
                        : Icons.star_border_rounded,
                    color: _isFavorite
                        ? colors.primary
                        : colors.textSecondary,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.pop(context);
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colors.cardMuted,
                    shape: BoxShape.circle,
                    border: Border.all(color: colors.border),
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    color: colors.textPrimary,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _actionButton(
            icon: Icons.translate_rounded,
            label: 'Translation',
            onTap: _openTranslation,
          ),
          _actionButton(
            icon: Icons.menu_book_rounded,
            label: 'Tafsir',
            onTap: _openTafsir,
          ),
          _actionButton(
            icon: Icons.copy_rounded,
            label: 'Copy',
            onTap: _copyAyah,
          ),
          _actionButton(
            icon: Icons.psychology_rounded,
            label: 'AI\nExplain',
            onTap: _openAIExplain,
          ),
        ],
      ),
    );
  }

  Widget _buildSecondaryActions() {
    // No recitation player here — audio files are not bundled with
    // the app, so a Play tile would be a dead end (deleted, not wired).
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _actionButton(
            icon: _isBookmarked
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            label: 'Bookmark',
            onTap: _toggleBookmark,
            isActive: _isBookmarked,
          ),
          _actionButton(
            icon: Icons.edit_note_rounded,
            label: 'Note',
            onTap: _addNote,
          ),
          _actionButton(
            icon: Icons.share_rounded,
            label: 'Share',
            onTap: _shareAyah,
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
  }) {
    final colors = QibraColors.of(context);
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Column(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isActive ? colors.primarySoft : colors.cardMuted,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isActive ? colors.primary : colors.border,
                    width: isActive ? 2 : 1,
                  ),
                ),
                child: Icon(
                  icon,
                  color: isActive ? colors.primary : colors.textPrimary,
                  size: 26,
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 28,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: colors.textSecondary,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRelatedContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const QibraSectionHeader(title: 'Related Content'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _relatedCard(
                  icon: Icons.auto_stories_rounded,
                  title: 'Related Ayahs',
                  subtitle: _getRelatedAyahs(),
                  onTap: _openRelatedAyah,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _relatedCard(
                  icon: Icons.article_rounded,
                  title: 'Read Full Surah',
                  subtitle: widget.surahName,
                  onTap: _openFullSurah,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _relatedCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final colors = QibraColors.of(context);
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colors.cardMuted,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colors.textSecondary, size: 22),
            const SizedBox(height: 8),
            Text(
              title,
              style: AppTextStyles.labelLarge.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTextStyles.bodySmall
                  .copyWith(color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // ACTIONS (all backed by real behavior)
  // ─────────────────────────────────────────────────

  void _openTranslation() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TafseerScreen(
          surahNumber: widget.surahNumber,
          initialAyah: widget.ayahNumber,
        ),
      ),
    );
  }

  void _openTafsir() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TafseerScreen(
          surahNumber: widget.surahNumber,
          initialAyah: widget.ayahNumber,
        ),
      ),
    );
  }

  void _openAIExplain() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AIExplainScreen(
          ayahText: widget.ayah?.text,
          surahName: widget.surahName,
          ayahNumber: widget.ayahNumber,
          surahNumber: widget.surahNumber,
        ),
      ),
    );
  }

  // COPY AYAH (Real)
  void _copyAyah() {
    final text = _buildShareText();
    Clipboard.setData(ClipboardData(text: text));
    Navigator.pop(context);
    _showToast('Ayah copied to clipboard');
  }

  // BOOKMARK (Real - saves to SharedPreferences)
  Future<void> _toggleBookmark() async {
    setState(() => _isBookmarked = !_isBookmarked);
    await _saveState();
    _showToast(_isBookmarked
        ? 'Bookmarked ${widget.surahName}:${widget.ayahNumber}'
        : 'Bookmark removed');
  }

  // ADD NOTE (Real - opens dialog)
  Future<void> _addNote() async {
    final colors = QibraColors.of(context);
    Navigator.pop(context);
    final noteKey = 'note_${widget.surahNumber}_${widget.ayahNumber}';
    final prefs = await SharedPreferences.getInstance();
    final existingNote = prefs.getString(noteKey) ?? '';

    if (!mounted) return;

    final controller = TextEditingController(text: existingNote);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(Icons.edit_note_rounded,
                color: colors.textSecondary, size: 22),
            const SizedBox(width: 8),
            Text(
              'Note for ${widget.surahName}:${widget.ayahNumber}',
              style: AppTextStyles.titleSmall.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: TextField(
          controller: controller,
          maxLines: 5,
          autofocus: true,
          style: AppTextStyles.bodyMedium
              .copyWith(color: colors.textPrimary),
          decoration: InputDecoration(
            hintText: 'Write your reflection or note...',
            hintStyle: AppTextStyles.bodyMedium
                .copyWith(color: colors.textTertiary),
            filled: true,
            fillColor: colors.cardMuted,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: AppTextStyles.labelLarge
                  .copyWith(color: colors.textSecondary),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colors.primary,
              foregroundColor: colors.onPrimary,
            ),
            onPressed: () async {
              if (controller.text.trim().isEmpty) {
                await prefs.remove(noteKey);
                if (ctx.mounted) Navigator.pop(ctx);
                _showToast('Note removed');
              } else {
                await prefs.setString(noteKey, controller.text.trim());
                if (ctx.mounted) Navigator.pop(ctx);
                _showToast('Note saved');
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // SHARE AYAH (Real - uses clipboard)
  void _shareAyah() {
    final text = _buildShareText();
    Clipboard.setData(ClipboardData(text: text));
    Navigator.pop(context);
    _showToast('Ayah copied — paste anywhere to share');
  }

  // RELATED AYAHS (Real - navigate to prev/next)
  void _openRelatedAyah() {
    Navigator.pop(context);
    final targetAyah =
        widget.ayahNumber > 1 ? widget.ayahNumber - 1 : widget.ayahNumber + 1;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SurahReaderScreen(
          surahNumber: widget.surahNumber,
          initialAyah: targetAyah,
        ),
      ),
    );
  }

  // FULL SURAH
  void _openFullSurah() {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SurahReaderScreen(
          surahNumber: widget.surahNumber,
          initialAyah: widget.ayahNumber,
        ),
      ),
    );
  }

  // Build share text
  String _buildShareText() {
    final buffer = StringBuffer();

    if (widget.ayah?.text != null) {
      buffer.writeln(widget.ayah!.text);
      buffer.writeln();
    }

    if (widget.ayah?.translation != null) {
      buffer.writeln('"${widget.ayah!.translation}"');
      buffer.writeln();
    }

    buffer.writeln(
        '— ${widget.surahName} (${widget.surahNumber}:${widget.ayahNumber})');
    buffer.writeln();
    buffer.writeln('Shared via QIBRA AI');

    return buffer.toString();
  }

  String _getRelatedAyahs() {
    final prev = widget.ayahNumber - 1;
    final next = widget.ayahNumber + 1;
    if (prev < 1) return 'Ayah $next';
    return 'Ayah $prev, Ayah $next';
  }

  void _showToast(String message) {
    final colors = QibraColors.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        backgroundColor: colors.cardMuted,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
