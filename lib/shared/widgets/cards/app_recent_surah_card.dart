// lib/shared/widgets/cards/app_recent_surah_card.dart
// ============================================================
// QIBRA AI — RECENT SURAH CARD WIDGET (v1.0)
// Phase: 8 — Premium UI Redesign
// Description: Horizontal Surah card with:
//   - Ornamental star badge (Step 4 widget)
//   - Surah name (English + optional Arabic)
//   - Verses count
//   - Optional progress indicator
//   - Optional revelation type (Makki/Madani)
//   - Tap handler with haptic feedback
//   - Multiple sizes (compact, standard, expanded)
// Usage: Home "Recently Read", Quran screen, Bookmarks
// Reference: Recently Read section in reference image Screen 2
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qibra_ai/core/design_system/app_colors.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';
import 'package:qibra_ai/shared/widgets/badges/app_ornamental_star_badge.dart';

// ============================================================
// SECTION 1 — ENUMS
// ============================================================

/// Card size variants
enum RecentSurahCardSize {
  /// Compact (width 100) - for tight spaces
  compact,

  /// Standard (width 120) - default, reference match
  standard,

  /// Expanded (width 160) - for detailed view
  expanded,
}

/// Revelation type
enum SurahRevelationType {
  makki, // Revealed in Makkah
  madani, // Revealed in Madinah
}

// ============================================================
// SECTION 2 — RECENT SURAH CARD WIDGET
// ============================================================

/// Premium horizontal Surah card with ornamental star badge
///
/// Example usage:
/// ```dart
/// AppRecentSurahCard(
///   surahNumber: 1,
///   surahName: 'Al-Fatihah',
///   versesCount: 7,
///   onTap: () => print('Tapped Al-Fatihah'),
/// )
/// ```
class AppRecentSurahCard extends StatelessWidget {
  /// Surah number (1-114)
  final int surahNumber;

  /// Surah name in English (e.g., "Al-Fatihah")
  final String surahName;

  /// Total verses count
  final int versesCount;

  /// Optional Arabic name (e.g., "الفاتحة")
  final String? surahNameArabic;

  /// Optional revelation type (Makki/Madani)
  final SurahRevelationType? revelationType;

  /// Optional reading progress (0.0 - 1.0)
  final double? progress;

  /// Card size variant
  final RecentSurahCardSize size;

  /// Tap handler
  final VoidCallback? onTap;

  /// Long press handler (for bookmarks/options menu)
  final VoidCallback? onLongPress;

  /// Show glow around star badge
  final bool showBadgeGlow;

  /// Custom badge theme (default: emerald)
  final BadgeColorTheme badgeTheme;

  /// Show subtle border
  final bool showBorder;

  const AppRecentSurahCard({
    super.key,
    required this.surahNumber,
    required this.surahName,
    required this.versesCount,
    this.surahNameArabic,
    this.revelationType,
    this.progress,
    this.size = RecentSurahCardSize.standard,
    this.onTap,
    this.onLongPress,
    this.showBadgeGlow = true,
    this.badgeTheme = BadgeColorTheme.emerald,
    this.showBorder = true,
  });

  // ============================================================
  // BUILD METHOD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final _CardDimensions dims = _getDimensions(size);

    Widget card = Container(
      width: dims.width,
      padding: EdgeInsets.symmetric(
        horizontal: dims.horizontalPadding,
        vertical: dims.verticalPadding,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: showBorder
            ? Border.all(
                color: AppColors.primary.withValues(alpha: 0.15),
                width: 1,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 12,
            spreadRadius: 0,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Optional Revelation Type Badge (top-right) ─────
          if (revelationType != null)
            Align(
              alignment: Alignment.centerRight,
              child: _buildRevelationBadge(revelationType!),
            ),

          if (revelationType != null) SizedBox(height: dims.gapAfterRevelation),

          // ── Ornamental Star Badge (center) ─────────────────
          AppOrnamentalStarBadge(
            number: surahNumber,
            customSize: dims.badgeSize,
            theme: badgeTheme,
            showGlow: showBadgeGlow,
          ),

          SizedBox(height: dims.gapAfterBadge),

          // ── Surah Name (English) ───────────────────────────
          Text(
            surahName,
            style: AppTextStyles.titleSmall.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
              fontSize: dims.nameSize,
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),

          // ── Optional Arabic Name ───────────────────────────
          if (surahNameArabic != null) ...[
            const SizedBox(height: 2),
            Text(
              surahNameArabic!,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: dims.arabicSize,
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
                height: 1.0,
              ),
              textDirection: TextDirection.rtl,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],

          SizedBox(height: dims.gapAfterName),

          // ── Verses Count ────────────────────────────────────
          Text(
            '$versesCount Verses',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textTertiary,
              fontSize: dims.versesSize,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.3,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),

          // ── Optional Progress Bar ──────────────────────────
          if (progress != null) ...[
            SizedBox(height: dims.gapBeforeProgress),
            _buildProgressBar(progress!, dims),
          ],
        ],
      ),
    );

    // ── Wrap with tap handlers ──────────────────────────────
    if (onTap != null || onLongPress != null) {
      card = GestureDetector(
        onTapDown: (_) => HapticFeedback.lightImpact(),
        onTap: onTap,
        onLongPress: () {
          HapticFeedback.mediumImpact();
          onLongPress?.call();
        },
        child: card,
      );
    }

    return card;
  }

  // ============================================================
  // SECTION 3 — SUB-COMPONENTS
  // ============================================================

  /// Revelation type badge (Makki/Madani)
  Widget _buildRevelationBadge(SurahRevelationType type) {
    final bool isMakki = type == SurahRevelationType.makki;
    final Color badgeColor = isMakki
        ? AppColors.accent // Gold for Makki
        : const Color(0xFF10B981); // Green for Madani
    final String labelText = isMakki ? 'Makki' : 'Madani';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.12),
        borderRadius: AppRadius.pillRadius,
        border: Border.all(
          color: badgeColor.withValues(alpha: 0.30),
          width: 0.8,
        ),
      ),
      child: Text(
        labelText,
        style: AppTextStyles.labelSmall.copyWith(
          color: badgeColor,
          fontWeight: FontWeight.w700,
          fontSize: 8,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  /// Progress bar (for reading progress)
  Widget _buildProgressBar(double value, _CardDimensions dims) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: AppRadius.pillRadius,
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            backgroundColor: AppColors.borderSubtle,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 3,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${(value * 100).toStringAsFixed(0)}%',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
            fontSize: 9,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SECTION 4 — HELPERS
  // ============================================================

  /// Get card dimensions based on size variant
  _CardDimensions _getDimensions(RecentSurahCardSize size) {
    switch (size) {
      case RecentSurahCardSize.compact:
        return const _CardDimensions(
          width: 100,
          horizontalPadding: AppSpacing.sm,
          verticalPadding: AppSpacing.md,
          badgeSize: 44,
          nameSize: 11,
          arabicSize: 12,
          versesSize: 9,
          gapAfterRevelation: 4,
          gapAfterBadge: 8,
          gapAfterName: 4,
          gapBeforeProgress: 6,
        );

      case RecentSurahCardSize.standard:
        return const _CardDimensions(
          width: 120,
          horizontalPadding: AppSpacing.md,
          verticalPadding: AppSpacing.md,
          badgeSize: 56,
          nameSize: 13,
          arabicSize: 14,
          versesSize: 10,
          gapAfterRevelation: 4,
          gapAfterBadge: AppSpacing.sm,
          gapAfterName: AppSpacing.xs,
          gapBeforeProgress: AppSpacing.sm,
        );

      case RecentSurahCardSize.expanded:
        return const _CardDimensions(
          width: 160,
          horizontalPadding: AppSpacing.md,
          verticalPadding: AppSpacing.lg,
          badgeSize: 72,
          nameSize: 15,
          arabicSize: 16,
          versesSize: 11,
          gapAfterRevelation: 6,
          gapAfterBadge: AppSpacing.md,
          gapAfterName: AppSpacing.xs,
          gapBeforeProgress: AppSpacing.md,
        );
    }
  }
}

// ============================================================
// SECTION 5 — DIMENSIONS HELPER CLASS
// ============================================================

class _CardDimensions {
  final double width;
  final double horizontalPadding;
  final double verticalPadding;
  final double badgeSize;
  final double nameSize;
  final double arabicSize;
  final double versesSize;
  final double gapAfterRevelation;
  final double gapAfterBadge;
  final double gapAfterName;
  final double gapBeforeProgress;

  const _CardDimensions({
    required this.width,
    required this.horizontalPadding,
    required this.verticalPadding,
    required this.badgeSize,
    required this.nameSize,
    required this.arabicSize,
    required this.versesSize,
    required this.gapAfterRevelation,
    required this.gapAfterBadge,
    required this.gapAfterName,
    required this.gapBeforeProgress,
  });
}

// ============================================================
// SECTION 6 — HORIZONTAL LIST BUILDER (convenience widget)
// ============================================================

/// Data model for a Surah item
class RecentSurahItem {
  final int surahNumber;
  final String surahName;
  final int versesCount;
  final String? surahNameArabic;
  final SurahRevelationType? revelationType;
  final double? progress;

  const RecentSurahItem({
    required this.surahNumber,
    required this.surahName,
    required this.versesCount,
    this.surahNameArabic,
    this.revelationType,
    this.progress,
  });
}

/// Horizontal scrollable list of Recent Surah cards
///
/// Example usage:
/// ```dart
/// AppRecentSurahList(
///   surahs: [
///     RecentSurahItem(surahNumber: 1, surahName: 'Al-Fatihah', versesCount: 7),
///     RecentSurahItem(surahNumber: 2, surahName: 'Al-Baqarah', versesCount: 286),
///   ],
///   onSurahTap: (surah) => print('Tapped ${surah.surahName}'),
/// )
/// ```
class AppRecentSurahList extends StatelessWidget {
  final List<RecentSurahItem> surahs;
  final void Function(RecentSurahItem surah)? onSurahTap;
  final RecentSurahCardSize cardSize;
  final double horizontalPadding;
  final double cardSpacing;

  const AppRecentSurahList({
    super.key,
    required this.surahs,
    this.onSurahTap,
    this.cardSize = RecentSurahCardSize.standard,
    this.horizontalPadding = AppSpacing.lg,
    this.cardSpacing = AppSpacing.md,
  });

  @override
  Widget build(BuildContext context) {
    // Height based on card size
    final double listHeight = _getListHeight(cardSize);

    return SizedBox(
      height: listHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        physics: const BouncingScrollPhysics(),
        itemCount: surahs.length,
        separatorBuilder: (_, __) => SizedBox(width: cardSpacing),
        itemBuilder: (context, index) {
          final RecentSurahItem surah = surahs[index];
          return AppRecentSurahCard(
            surahNumber: surah.surahNumber,
            surahName: surah.surahName,
            versesCount: surah.versesCount,
            surahNameArabic: surah.surahNameArabic,
            revelationType: surah.revelationType,
            progress: surah.progress,
            size: cardSize,
            onTap: onSurahTap != null ? () => onSurahTap!(surah) : null,
          );
        },
      ),
    );
  }

  double _getListHeight(RecentSurahCardSize size) {
    switch (size) {
      case RecentSurahCardSize.compact:
        return 130;
      case RecentSurahCardSize.standard:
        return 160;
      case RecentSurahCardSize.expanded:
        return 210;
    }
  }
}

// ============================================================
// END OF FILE — app_recent_surah_card.dart (v1.0)
// ============================================================
