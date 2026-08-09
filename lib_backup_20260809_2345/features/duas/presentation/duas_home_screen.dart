// lib/features/duas/presentation/duas_home_screen.dart

// ============================================================
// QIBRA AI — DUAS HOME SCREEN
// Premium Islamic Duas Collection
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qibra_ai/core/design_system/app_colors.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';
import 'package:qibra_ai/features/duas/data/models/dua_model.dart';
import 'package:qibra_ai/features/duas/providers/dua_provider.dart';
import 'duas_list_screen.dart';
import 'dua_detail_screen.dart';

// ============================================================
// MAIN SCREEN
// ============================================================

class DuasHomeScreen extends ConsumerStatefulWidget {
  const DuasHomeScreen({super.key});

  @override
  ConsumerState<DuasHomeScreen> createState() => _DuasHomeScreenState();
}

class _DuasHomeScreenState extends ConsumerState<DuasHomeScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    ref.read(duaSearchQueryProvider.notifier).state = value;
    setState(() => _isSearching = value.isNotEmpty);
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(duaSearchQueryProvider.notifier).state = '';
    setState(() => _isSearching = false);
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── APP BAR ─────────────────────────────────────
            _buildSliverAppBar(),

            // ── SEARCH BAR ──────────────────────────────────
            SliverToBoxAdapter(
              child: _buildSearchBar(),
            ),

            // ── SEARCH RESULTS ──────────────────────────────
            if (_isSearching) ...[
              SliverToBoxAdapter(
                child: _buildSearchResults(),
              ),
            ] else ...[
              // ── DAILY DUA CARD ───────────────────────────
              SliverToBoxAdapter(
                child: _buildDailyDuaCard(),
              ),

              // ── SECTION TITLE ─────────────────────────────
              SliverToBoxAdapter(
                child: _buildSectionTitle(
                  'Categories',
                  'تمام اقسام',
                ),
              ),

              // ── CATEGORIES GRID ──────────────────────────
              SliverToBoxAdapter(
                child: _buildCategoriesGrid(),
              ),

              // ── FAVORITES SECTION ────────────────────────
              SliverToBoxAdapter(
                child: _buildFavoritesSection(),
              ),

              // ── BOTTOM PADDING ───────────────────────────
              const SliverToBoxAdapter(
                child: SizedBox(height: 120),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // SLIVER APP BAR
  // ──────────────────────────────────────────────────────────

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 160,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0C1A0E),
                Color(0xFF0F2012),
                AppColors.background,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Arabic title
                  Text(
                    'الأدعية المأثورة',
                    style: AppTextStyles.arabicLarge.copyWith(
                      color: AppColors.primary.withValues(alpha: 0.9),
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Masnoon Duas',
                    style: AppTextStyles.displaySmall.copyWith(
                      fontWeight: FontWeight.w800,
                      fontSize: 28,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Stats row
                  Consumer(builder: (context, ref, _) {
                    final stats = ref.watch(duaStatsProvider);
                    return Text(
                      '${stats.totalDuas} Duas  •  ${stats.totalCategories} Categories',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // SEARCH BAR
  // ──────────────────────────────────────────────────────────

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isSearching
                ? AppColors.primary.withValues(alpha: 0.5)
                : AppColors.borderSubtle,
          ),
          boxShadow: _isSearching
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(
              Icons.search_rounded,
              color: _isSearching ? AppColors.primary : AppColors.iconSecondary,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: AppTextStyles.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Search duas, topics, Arabic...',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textTertiary,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                ),
              ),
            ),
            if (_isSearching)
              GestureDetector(
                onTap: _clearSearch,
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceElevated,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: AppColors.iconSecondary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // SEARCH RESULTS
  // ──────────────────────────────────────────────────────────

  Widget _buildSearchResults() {
    final results = ref.watch(filteredDuasProvider);

    if (results.isEmpty) {
      return SizedBox(
        height: 300,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 56,
                color: AppColors.textTertiary.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No duas found',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Try different keywords',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textTertiary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Text(
            '${results.length} results found',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
        ...results.map((dua) => _buildDuaListTile(dua)),
        const SizedBox(height: 120),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────
  // DAILY DUA CARD
  // ──────────────────────────────────────────────────────────

  Widget _buildDailyDuaCard() {
    final dailyDua = ref.watch(dailyDuaProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          _openDuaDetail(dailyDua);
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF064E3B),
                Color(0xFF065F46),
                Color(0xFF047857),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('✨', style: TextStyle(fontSize: 12)),
                        const SizedBox(width: 6),
                        Text(
                          'Dua of the Day',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  // Favorite button
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ref
                          .read(favoriteDuaIdsProvider.notifier)
                          .toggleFavorite(dailyDua.id);
                    },
                    child: Icon(
                      dailyDua.isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: dailyDua.isFavorite
                          ? const Color(0xFFFF6B6B)
                          : AppColors.white.withValues(alpha: 0.7),
                      size: 22,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Title
              Text(
                dailyDua.titleEnglish,
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 12),

              // Arabic text
              Text(
                dailyDua.arabic.length > 120
                    ? '${dailyDua.arabic.substring(0, 120)}...'
                    : dailyDua.arabic,
                style: AppTextStyles.arabicMedium.copyWith(
                  color: AppColors.white.withValues(alpha: 0.95),
                  height: 1.8,
                  fontSize: 18,
                ),
                textAlign: TextAlign.right,
                textDirection: TextDirection.rtl,
              ),

              const SizedBox(height: 12),

              // Divider
              Divider(
                color: AppColors.white.withValues(alpha: 0.2),
                height: 1,
              ),

              const SizedBox(height: 12),

              // Reference row
              Row(
                children: [
                  Icon(
                    Icons.verified_rounded,
                    size: 14,
                    color: AppColors.white.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      dailyDua.reference,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      dailyDua.grade,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // SECTION TITLE
  // ──────────────────────────────────────────────────────────

  Widget _buildSectionTitle(String title, String arabic) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Row(
        children: [
          // Accent line
          Container(
            width: 3,
            height: 22,
            decoration: BoxDecoration(
              gradient: AppGradients.emerald,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: AppTextStyles.titleLarge.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          Text(
            arabic,
            style: AppTextStyles.arabicSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // CATEGORIES GRID
  // ──────────────────────────────────────────────────────────

  Widget _buildCategoriesGrid() {
    final categories = ref.watch(duaCategoriesProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.9,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          return _buildCategoryCard(categories[index]);
        },
      ),
    );
  }

  Widget _buildCategoryCard(DuaCategoryModel category) {
    // Parse hex color
    Color cardColor;
    try {
      final hex = category.colorHex.replaceAll('#', '');
      cardColor = Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      cardColor = AppColors.primary;
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DuasListScreen(
              categoryId: category.id,
              categoryName: category.nameEnglish,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon circle
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: cardColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  category.icon,
                  style: const TextStyle(fontSize: 24),
                ),
              ),
            ),

            const SizedBox(height: 8),

            // Name
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                category.nameEnglish,
                style: AppTextStyles.labelSmall.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 4),

            // Count badge
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: cardColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${category.duaCount}',
                style: AppTextStyles.labelSmall.copyWith(
                  color: cardColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // FAVORITES SECTION
  // ──────────────────────────────────────────────────────────

  Widget _buildFavoritesSection() {
    final favorites = ref.watch(favoriteDuasProvider);
    if (favorites.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Favorites', 'المفضلة'),
        ...favorites.map((dua) => _buildDuaListTile(dua)),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────
  // DUA LIST TILE (Search results + Favorites)
  // ──────────────────────────────────────────────────────────

  Widget _buildDuaListTile(DuaModel dua) {
    // Category color
    Color tileColor = AppColors.primary;
    try {
      final cat = ref
          .read(duaCategoriesProvider)
          .firstWhere((c) => c.id == dua.category);
      final hex = cat.colorHex.replaceAll('#', '');
      tileColor = Color(int.parse('FF$hex', radix: 16));
    } catch (_) {}

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        _openDuaDetail(dua);
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          children: [
            // Category color dot
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: tileColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  _getCategoryIcon(dua.category),
                  style: const TextStyle(fontSize: 20),
                ),
              ),
            ),

            const SizedBox(width: 14),

            // Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dua.titleEnglish,
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    dua.arabic.length > 60
                        ? '${dua.arabic.substring(0, 60)}...'
                        : dua.arabic,
                    style: AppTextStyles.arabicSmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                    textDirection: TextDirection.rtl,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        size: 11,
                        color: AppColors.primary.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          dua.reference,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textTertiary,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Favorite icon
            GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                ref
                    .read(favoriteDuaIdsProvider.notifier)
                    .toggleFavorite(dua.id);
              },
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
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────────────────
  // HELPERS
  // ──────────────────────────────────────────────────────────

  String _getCategoryIcon(String categoryId) {
    try {
      final cat =
          ref.read(duaCategoriesProvider).firstWhere((c) => c.id == categoryId);
      return cat.icon;
    } catch (_) {
      return '🤲';
    }
  }

  void _openDuaDetail(DuaModel dua) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DuaDetailScreen(duaId: dua.id),
      ),
    );
  }
}
