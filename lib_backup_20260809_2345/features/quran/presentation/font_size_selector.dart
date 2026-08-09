// lib/features/quran/presentation/font_size_selector.dart

// ============================================================
// QIBRA AI — FONT SIZE SELECTOR (v1.0)
// Phase: 8.3 — Surah Reader Component
// Description: Standalone reusable font size selector widget.
//              Can be shown as bottom sheet from any screen.
//              Works with callback pattern — no hard provider
//              dependency so it can be embedded anywhere.
//
// Usage (as bottom sheet):
//   FontSizeSelector.show(
//     context: context,
//     currentSize: QuranFontSize.medium,
//     onSizeSelected: (size) {
//       ref.read(myFontProvider.notifier).state = size;
//     },
//   );
//
// Usage (as inline widget):
//   FontSizeSelectorWidget(
//     currentSize: QuranFontSize.medium,
//     onSizeSelected: (size) { ... },
//   )
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_design_system.dart';
import '../../../core/design_system/app_typography.dart';

// ============================================================
// SECTION 1 — FONT SIZE ENUM (re-exported from here)
// ============================================================
// Note: SurahReaderScreen uses its own local QuranFontSize enum.
// This file defines a standalone identical enum so this widget
// is 100% self-contained and portable.
// ============================================================

enum QuranFontSize {
  small,
  medium,
  large,
  extraLarge;

  /// Arabic text font size
  double get arabicSize {
    return switch (this) {
      QuranFontSize.small => 18.0,
      QuranFontSize.medium => 22.0,
      QuranFontSize.large => 26.0,
      QuranFontSize.extraLarge => 30.0,
    };
  }

  /// Translation/English text font size
  double get translationSize {
    return switch (this) {
      QuranFontSize.small => 12.0,
      QuranFontSize.medium => 14.0,
      QuranFontSize.large => 16.0,
      QuranFontSize.extraLarge => 18.0,
    };
  }

  /// Short label shown on button
  String get label {
    return switch (this) {
      QuranFontSize.small => 'S',
      QuranFontSize.medium => 'M',
      QuranFontSize.large => 'L',
      QuranFontSize.extraLarge => 'XL',
    };
  }

  /// Full readable name
  String get fullLabel {
    return switch (this) {
      QuranFontSize.small => 'Small',
      QuranFontSize.medium => 'Medium',
      QuranFontSize.large => 'Large',
      QuranFontSize.extraLarge => 'Extra Large',
    };
  }

  /// Arabic sample letter display size (scaled for visual preview)
  double get previewArabicSize {
    return switch (this) {
      QuranFontSize.small => 20.0,
      QuranFontSize.medium => 26.0,
      QuranFontSize.large => 32.0,
      QuranFontSize.extraLarge => 38.0,
    };
  }

  /// Description for accessibility / subtitle
  String get description {
    return switch (this) {
      QuranFontSize.small => 'Compact — more ayahs visible',
      QuranFontSize.medium => 'Comfortable — recommended',
      QuranFontSize.large => 'Spacious — easier reading',
      QuranFontSize.extraLarge => 'Maximum — best for elders',
    };
  }

  /// Icon for each size option
  IconData get icon {
    return switch (this) {
      QuranFontSize.small => Icons.text_fields_rounded,
      QuranFontSize.medium => Icons.format_size_rounded,
      QuranFontSize.large => Icons.text_increase_rounded,
      QuranFontSize.extraLarge => Icons.accessibility_new_rounded,
    };
  }
}

// ============================================================
// SECTION 2 — STATIC LAUNCHER CLASS
// ============================================================

/// Font Size Selector — Static launcher + inline widget
///
/// Shows a premium bottom sheet to select Quran font size.
///
/// ```dart
/// FontSizeSelector.show(
///   context: context,
///   currentSize: QuranFontSize.medium,
///   onSizeSelected: (size) {
///     ref.read(fontSizeProvider.notifier).state = size;
///   },
/// );
/// ```
class FontSizeSelector {
  FontSizeSelector._(); // prevent instantiation

  /// Show font size selector as bottom sheet
  static Future<void> show({
    required BuildContext context,
    required QuranFontSize currentSize,
    required ValueChanged<QuranFontSize> onSizeSelected,
    String? title,
    String? subtitle,
  }) {
    HapticFeedback.selectionClick();
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: false,
      builder: (_) => FontSizeSelectorWidget(
        currentSize: currentSize,
        onSizeSelected: (size) {
          onSizeSelected(size);
        },
        title: title,
        subtitle: subtitle,
      ),
    );
  }
}

// ============================================================
// SECTION 3 — INLINE WIDGET (also used inside bottom sheet)
// ============================================================

class FontSizeSelectorWidget extends StatefulWidget {
  const FontSizeSelectorWidget({
    super.key,
    required this.currentSize,
    required this.onSizeSelected,
    this.title,
    this.subtitle,
    this.showDoneButton = true,
    this.showPreview = true,
    this.showDescriptions = true,
  });

  final QuranFontSize currentSize;
  final ValueChanged<QuranFontSize> onSizeSelected;
  final String? title;
  final String? subtitle;
  final bool showDoneButton;
  final bool showPreview;
  final bool showDescriptions;

  @override
  State<FontSizeSelectorWidget> createState() => _FontSizeSelectorWidgetState();
}

class _FontSizeSelectorWidgetState extends State<FontSizeSelectorWidget> {
  late QuranFontSize _selectedSize;

  @override
  void initState() {
    super.initState();
    _selectedSize = widget.currentSize;
  }

  void _selectSize(QuranFontSize size) {
    if (_selectedSize == size) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedSize = size);
    widget.onSizeSelected(size);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(AppSpacing.lg),
      padding: const EdgeInsets.all(AppSpacing.xl2),
      decoration: BoxDecoration(
        color: AppColors.surfaceSheet,
        borderRadius: BorderRadius.circular(AppRadius.xl3),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.18),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.30),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Handle ──
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textTertiary.withValues(alpha: 0.40),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // ── Header ──
          _buildHeader(),
          const SizedBox(height: AppSpacing.xl2),

          // ── Size Buttons Row ──
          _buildSizeButtonsRow(),
          const SizedBox(height: AppSpacing.lg),

          // ── Description ──
          if (widget.showDescriptions) _buildSelectedDescription(),

          // ── Live Preview ──
          if (widget.showPreview) ...[
            const SizedBox(height: AppSpacing.lg),
            _buildLivePreview(),
          ],

          const SizedBox(height: AppSpacing.lg),

          // ── Done Button ──
          if (widget.showDoneButton) _buildDoneButton(),
        ],
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: AppGradients.emerald,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.22),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Icon(
            Icons.text_fields_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title ?? 'Arabic Font Size',
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                widget.subtitle ?? 'Choose your preferred reading size',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        // Currently selected badge
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.28),
            ),
          ),
          child: Text(
            _selectedSize.fullLabel,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  // ── Size Buttons Row ──────────────────────────────────────

  Widget _buildSizeButtonsRow() {
    return Row(
      children: QuranFontSize.values.map((size) {
        final isSelected = size == _selectedSize;
        return Expanded(
          child: GestureDetector(
            onTap: () => _selectSize(size),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(
                vertical: AppSpacing.md,
                horizontal: AppSpacing.xs,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.18)
                    : AppColors.surfaceElevated.withValues(alpha: 0.78),
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.52)
                      : AppColors.primary.withValues(alpha: 0.12),
                  width: isSelected ? 1.5 : 1.0,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.14),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Arabic letter preview
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 220),
                    style: TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: size.previewArabicSize,
                      color: isSelected
                          ? AppColors.accent
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                    child: const Text('ب'),
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // Size label (S/M/L/XL)
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 220),
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textTertiary,
                      fontWeight:
                          isSelected ? FontWeight.w800 : FontWeight.w600,
                    ),
                    child: Text(size.label),
                  ),

                  // Selected indicator dot
                  const SizedBox(height: AppSpacing.xs),
                  AnimatedOpacity(
                    opacity: isSelected ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 200),
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Description ──────────────────────────────────────────

  Widget _buildSelectedDescription() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      child: Container(
        key: ValueKey(_selectedSize),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.14),
          ),
        ),
        child: Row(
          children: [
            Icon(
              _selectedSize.icon,
              size: 16,
              color: AppColors.primary,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                _selectedSize.description,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Live Preview ─────────────────────────────────────────

  Widget _buildLivePreview() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.14),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Preview label
          Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.accent,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Live Preview',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Arabic preview
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: _selectedSize.arabicSize,
              color: AppColors.textPrimary,
              height: 2.0,
            ),
            child: const Text(
              'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Divider
          Container(
            height: 1,
            color: AppColors.primary.withValues(alpha: 0.10),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Translation preview
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            style: TextStyle(
              fontSize: _selectedSize.translationSize,
              color: AppColors.textSecondary,
              height: 1.55,
              fontWeight: FontWeight.w400,
            ),
            child: const Text(
              'In the name of Allah, the Most Gracious, the Most Merciful.',
              textAlign: TextAlign.left,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Size indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Arabic: ${_selectedSize.arabicSize.toInt()}px  •  '
                'Translation: ${_selectedSize.translationSize.toInt()}px',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Done Button ───────────────────────────────────────────

  Widget _buildDoneButton() {
    return SizedBox(
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
          'Apply — ${_selectedSize.fullLabel}',
          style: AppTextStyles.labelLarge.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SECTION 4 — COMPACT FONT SIZE ROW WIDGET
// ============================================================
// Use this when you want an INLINE (non-modal) compact
// font size selector inside a toolbar or settings row.
//
// Usage:
//   FontSizeCompactRow(
//     currentSize: QuranFontSize.medium,
//     onSizeSelected: (size) { ... },
//   )
// ============================================================

class FontSizeCompactRow extends StatelessWidget {
  const FontSizeCompactRow({
    super.key,
    required this.currentSize,
    required this.onSizeSelected,
  });

  final QuranFontSize currentSize;
  final ValueChanged<QuranFontSize> onSizeSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Font:',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        ...QuranFontSize.values.map((size) {
          final isSelected = size == currentSize;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onSizeSelected(size);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.only(left: 4),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withValues(alpha: 0.18)
                    : AppColors.surfaceElevated.withValues(alpha: 0.70),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.50)
                      : AppColors.primary.withValues(alpha: 0.10),
                ),
              ),
              child: Center(
                child: Text(
                  size.label,
                  style: AppTextStyles.labelSmall.copyWith(
                    color:
                        isSelected ? AppColors.primary : AppColors.textTertiary,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ============================================================
// END OF FILE — font_size_selector.dart
// ============================================================
