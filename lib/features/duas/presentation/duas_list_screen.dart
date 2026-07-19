// lib/features/duas/presentation/duas_list_screen.dart

// ============================================================
// QIBRA AI — DUAS LIST SCREEN (by Category)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qibra_ai/core/design_system/app_colors.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';
import 'package:qibra_ai/features/duas/data/models/dua_model.dart';
import 'package:qibra_ai/features/duas/providers/dua_provider.dart';
import 'dua_detail_screen.dart';

class DuasListScreen extends ConsumerWidget {
  final String categoryId;
  final String categoryName;

  const DuasListScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final duas = ref.watch(duasByCategoryProvider(categoryId));
    final categories = ref.watch(duaCategoriesProvider);

    // Get category info
    DuaCategoryModel? category;
    try {
      category = categories.firstWhere((c) => c.id == categoryId);
    } catch (_) {}

    Color catColor = AppColors.primary;
    if (category != null) {
      try {
        final hex = category.colorHex.replaceAll('#', '');
        catColor = Color(int.parse('FF$hex', radix: 16));
      } catch (_) {}
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── APP BAR ───────────────────────────────────────
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: AppColors.background,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new_rounded,
                  size: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      catColor.withValues(alpha: 0.15),
                      AppColors.background,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(72, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (category != null)
                          Text(
                            category.icon,
                            style: const TextStyle(fontSize: 36),
                          ),
                        const SizedBox(height: 8),
                        Text(
                          categoryName,
                          style: AppTextStyles.headlineMedium.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        if (category != null)
                          Text(
                            category.nameUrdu,
                            style: AppTextStyles.arabicSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ── COUNT BAR ─────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Text(
                '${duas.length} duas in this category',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ),

          // ── DUAS LIST ─────────────────────────────────────
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final dua = duas[index];
                return _DuaCard(
                  dua: dua,
                  catColor: catColor,
                  index: index,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DuaDetailScreen(duaId: dua.id),
                      ),
                    );
                  },
                );
              },
              childCount: duas.length,
            ),
          ),

          // ── EMPTY STATE ───────────────────────────────────
          if (duas.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '🤲',
                      style: const TextStyle(fontSize: 56),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No duas in this category yet',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'More duas coming soon',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SliverToBoxAdapter(
            child: SizedBox(height: 120),
          ),
        ],
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────
// DUA CARD WIDGET
// ──────────────────────────────────────────────────────────

class _DuaCard extends ConsumerWidget {
  final DuaModel dua;
  final Color catColor;
  final int index;
  final VoidCallback onTap;

  const _DuaCard({
    required this.dua,
    required this.catColor,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── HEADER ──────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: BoxDecoration(
                color: catColor.withValues(alpha: 0.08),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  // Number badge
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: catColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dua.titleEnglish,
                          style: AppTextStyles.titleSmall.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          dua.titleUrdu,
                          style: AppTextStyles.arabicSmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Favorite button
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ref
                          .read(favoriteDuaIdsProvider.notifier)
                          .toggleFavorite(dua.id);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        dua.isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        color: dua.isFavorite
                            ? const Color(0xFFFF6B6B)
                            : AppColors.iconSecondary,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── ARABIC TEXT ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                dua.arabic,
                style: AppTextStyles.arabicMedium.copyWith(
                  fontSize: 20,
                  height: 2.0,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
              ),
            ),

            // ── DIVIDER ──────────────────────────────────────
            Divider(
              color: AppColors.borderSubtle,
              indent: 16,
              endIndent: 16,
              height: 1,
            ),

            // ── TRANSLITERATION ──────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Text(
                dua.transliteration.length > 100
                    ? '${dua.transliteration.substring(0, 100)}...'
                    : dua.transliteration,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                  height: 1.5,
                ),
              ),
            ),

            // ── URDU TRANSLATION ─────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
              child: Text(
                dua.translationUrdu.length > 120
                    ? '${dua.translationUrdu.substring(0, 120)}...'
                    : dua.translationUrdu,
                style: AppTextStyles.arabicSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                  height: 1.6,
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
              ),
            ),

            // ── FOOTER ───────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(20),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.verified_rounded,
                    size: 13,
                    color: AppColors.primary.withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      dua.reference,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  // Grade chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: _gradeColor(dua.grade).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      dua.grade,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: _gradeColor(dua.grade),
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _gradeColor(String grade) {
    switch (grade.toLowerCase()) {
      case 'sahih':
        return AppColors.primary;
      case 'hasan':
        return const Color(0xFF3B82F6);
      case 'quran':
        return const Color(0xFF7C3AED);
      default:
        return AppColors.textSecondary;
    }
  }
}
