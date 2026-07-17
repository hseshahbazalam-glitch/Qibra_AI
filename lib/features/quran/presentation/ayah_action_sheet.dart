// lib/features/quran/presentation/ayah_action_sheet.dart

// ============================================================
// QIBRA AI — AYAH ACTION SHEET (v1.0)
// Phase: 8.3 — Surah Reader Component
// Description: Premium bottom sheet for Ayah actions (Bookmark,
//              Add Note, Copy, Share, Audio playback hook).
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_design_system.dart';
import '../../../core/design_system/app_typography.dart';
import '../data/models/quran_models.dart';
import '../providers/quran_provider.dart';

class AyahActionSheet extends ConsumerStatefulWidget {
  const AyahActionSheet({
    super.key,
    required this.surahNumber,
    required this.surahName,
    required this.ayah,
    this.onPlayAudio,
  });

  final int surahNumber;
  final String surahName;
  final AyahModel ayah;
  final VoidCallback? onPlayAudio;

  /// Helper launcher method for clean one-line invocation
  static Future<void> show({
    required BuildContext context,
    required int surahNumber,
    required String surahName,
    required AyahModel ayah,
    VoidCallback? onPlayAudio,
  }) {
    HapticFeedback.selectionClick();
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => AyahActionSheet(
        surahNumber: surahNumber,
        surahName: surahName,
        ayah: ayah,
        onPlayAudio: onPlayAudio,
      ),
    );
  }

  @override
  ConsumerState<AyahActionSheet> createState() => _AyahActionSheetState();
}

class _AyahActionSheetState extends ConsumerState<AyahActionSheet> {
  final TextEditingController _noteController = TextEditingController();
  bool _isAddingNote = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  // ── Helper methods ────────────────────────────────────────

  String get _formattedRef =>
      '${widget.surahName} (${widget.surahNumber}:${widget.ayah.number})';

  String get _copyableText {
    final translationStr =
        widget.ayah.translation != null && widget.ayah.translation!.isNotEmpty
            ? '\n\n${widget.ayah.translation}'
            : '';
    return '${widget.ayah.text}$translationStr\n\n— $_formattedRef\nShared via QIBRA AI';
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _copyableText));
    HapticFeedback.lightImpact();
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded,
                color: Colors.white, size: 18),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                'Ayah ${widget.ayah.number} copied to clipboard!',
                style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        margin: const EdgeInsets.all(AppSpacing.lg),
      ),
    );
  }

  void _toggleBookmark() {
    HapticFeedback.mediumImpact();

    final bookmark = BookmarkModel(
      surahNumber: widget.surahNumber,
      ayahNumber: widget.ayah.number,
      surahName: widget.surahName,
      ayahText: widget.ayah.text,
      bookmarkedAt: DateTime.now(),
      note: _noteController.text.trim().isNotEmpty
          ? _noteController.text.trim()
          : null,
    );

    ref.read(bookmarksProvider.notifier).toggleBookmark(bookmark);

    final isBookmarkedNow = ref.read(
      isBookmarkedProvider(
        (surah: widget.surahNumber, ayah: widget.ayah.number),
      ),
    );

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isBookmarkedNow
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_remove_rounded,
              color: Colors.white,
              size: 18,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              isBookmarkedNow
                  ? 'Bookmarked Ayah ${widget.ayah.number}'
                  : 'Removed from Bookmarks',
              style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
            ),
          ],
        ),
        backgroundColor:
            isBookmarkedNow ? AppColors.primary : AppColors.surfaceHigh,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        margin: const EdgeInsets.all(AppSpacing.lg),
      ),
    );
  }

  void _saveNote() {
    if (_noteController.text.trim().isEmpty) return;

    HapticFeedback.lightImpact();

    // Ensure bookmarked with note
    final bookmark = BookmarkModel(
      surahNumber: widget.surahNumber,
      ayahNumber: widget.ayah.number,
      surahName: widget.surahName,
      ayahText: widget.ayah.text,
      bookmarkedAt: DateTime.now(),
      note: _noteController.text.trim(),
    );

    ref.read(bookmarksProvider.notifier).addBookmark(bookmark);
    ref.read(bookmarksProvider.notifier).updateNote(
          widget.surahNumber,
          widget.ayah.number,
          _noteController.text.trim(),
        );

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Personal note saved for Ayah ${widget.ayah.number}!',
          style: AppTextStyles.bodySmall.copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        margin: const EdgeInsets.all(AppSpacing.lg),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isBookmarked = ref.watch(
      isBookmarkedProvider(
        (surah: widget.surahNumber, ayah: widget.ayah.number),
      ),
    );

    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surfaceSheet,
          borderRadius: BorderRadius.circular(AppRadius.xl3),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.18),
            width: 1.1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: AppSpacing.md),
            // Handle bar
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textTertiary.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Preview Section
            _buildAyahPreview(),

            const SizedBox(height: AppSpacing.md),
            const Divider(color: AppColors.divider, height: 1),

            // Note input mode OR Actions list
            if (_isAddingNote)
              _buildNoteInputSection()
            else
              _buildActionsList(isBookmarked),

            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  // ── Preview Card ──────────────────────────────────────────

  Widget _buildAyahPreview() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.80),
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header info
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  gradient: AppGradients.gold,
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  '${widget.surahNumber}:${widget.ayah.number}',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.black87,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                widget.surahName,
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                'Juz ${widget.ayah.juz} • Page ${widget.ayah.page}',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Arabic preview
          Text(
            widget.ayah.text,
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.bodyMedium.copyWith(
              fontFamily: 'Amiri',
              fontSize: 20,
              color: AppColors.textPrimary,
              height: 1.8,
            ),
          ),

          if (widget.ayah.translation != null &&
              widget.ayah.translation!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              widget.ayah.translation!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Actions Grid/List ────────────────────────────────────

  Widget _buildActionsList(bool isBookmarked) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        children: [
          // Play Audio Action
          if (widget.onPlayAudio != null)
            _ActionTile(
              icon: Icons.play_circle_fill_rounded,
              iconColor: AppColors.primary,
              title: 'Recite Ayah',
              subtitle: 'Listen to audio recitation',
              onTap: () {
                Navigator.of(context).pop();
                widget.onPlayAudio?.call();
              },
            ),

          // Bookmark Action
          _ActionTile(
            icon: isBookmarked
                ? Icons.bookmark_rounded
                : Icons.bookmark_border_rounded,
            iconColor: AppColors.accent,
            title: isBookmarked ? 'Remove Bookmark' : 'Add to Bookmarks',
            subtitle: isBookmarked
                ? 'Remove from saved verses'
                : 'Save for quick reference',
            onTap: _toggleBookmark,
          ),

          // Personal Note Action
          _ActionTile(
            icon: Icons.edit_note_rounded,
            iconColor: const Color(0xFF7C4DFF),
            title: 'Add Personal Reflection',
            subtitle: 'Write a note or reflection on this verse',
            onTap: () {
              setState(() => _isAddingNote = true);
            },
          ),

          // Copy Action
          _ActionTile(
            icon: Icons.copy_rounded,
            iconColor: const Color(0xFF1E88E5),
            title: 'Copy Text',
            subtitle: 'Copy Arabic & English text to clipboard',
            onTap: _copyToClipboard,
          ),
        ],
      ),
    );
  }

  // ── Personal Note Input Section ───────────────────────────

  Widget _buildNoteInputSection() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.edit_note_rounded,
                color: Color(0xFF7C4DFF),
                size: 22,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Personal Note & Tadabbur',
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => setState(() => _isAddingNote = false),
                icon: const Icon(Icons.close_rounded, size: 20),
                color: AppColors.textTertiary,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _noteController,
            maxLines: 3,
            autofocus: true,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
            cursorColor: AppColors.accent,
            decoration: InputDecoration(
              hintText:
                  'Aap is ayah se kya sikhte hain? Personal thoughts likhein...',
              hintStyle: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textTertiary,
              ),
              filled: true,
              fillColor: AppColors.surfaceElevated,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.xl),
                borderSide: BorderSide(
                  color: AppColors.primary.withValues(alpha: 0.20),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.xl),
                borderSide: BorderSide(
                  color: AppColors.accent.withValues(alpha: 0.50),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _isAddingNote = false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.20),
                    ),
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveNote,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                  ),
                  child: Text(
                    'Save Reflection',
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
    );
  }
}

// ============================================================
// SECTION 10 — ACTION TILE WIDGET
// ============================================================

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        splashColor: iconColor.withValues(alpha: 0.10),
        highlightColor: iconColor.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: iconColor.withValues(alpha: 0.20),
                  ),
                ),
                child: Icon(icon, color: iconColor, size: 20),
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
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textTertiary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// END OF FILE — ayah_action_sheet.dart
// ============================================================
