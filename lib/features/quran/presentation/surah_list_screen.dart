// lib/features/quran/presentation/surah_list_screen.dart

// ============================================================
// QIBRA AI — SURAH LIST SCREEN (v1.0)
// Phase: 8.3 — Surah Reader
// Description: Premium list of all 114 Surahs with search,
//              filter by revelation type, and reader navigation.
// ============================================================

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_design_system.dart';
import '../../../core/design_system/app_typography.dart';
import '../data/models/quran_models.dart';
import '../providers/quran_provider.dart';
import 'surah_reader_screen.dart';
// ============================================================
// SECTION 1 — FILTER ENUM
// ============================================================

enum SurahFilterType {
  all,
  meccan,
  medinan,
}

// ============================================================
// SECTION 2 — MAIN SCREEN WIDGET
// ============================================================

class SurahListScreen extends ConsumerStatefulWidget {
  const SurahListScreen({super.key});

  @override
  ConsumerState<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends ConsumerState<SurahListScreen>
    with SingleTickerProviderStateMixin {
  // Controllers
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  // State
  String _searchQuery = '';
  SurahFilterType _selectedFilter = SurahFilterType.all;

  // Animation
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(() => setState(() {}));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _animationController.forward();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query != _searchQuery) {
      setState(() => _searchQuery = query);
    }
  }

  void _clearSearch() {
    _searchController.clear();
    _searchFocusNode.unfocus();
    HapticFeedback.lightImpact();
  }

  List<SurahInfoModel> _applyFilters(List<SurahInfoModel> surahs) {
    final query = _searchQuery.toLowerCase();

    return surahs.where((surah) {
      // Search matching
      final matchesSearch = query.isEmpty ||
          surah.name.toLowerCase().contains(query) ||
          surah.nameArabic.toLowerCase().contains(query) ||
          surah.englishNameTranslation.toLowerCase().contains(query) ||
          surah.number.toString().contains(query);

      // Filter matching
      final matchesFilter = switch (_selectedFilter) {
        SurahFilterType.all => true,
        SurahFilterType.meccan => surah.isMeccan,
        SurahFilterType.medinan => surah.isMedinan,
      };

      return matchesSearch && matchesFilter;
    }).toList();
  }

  Color _revelationColor(SurahInfoModel surah) {
    if (surah.isMeccan) return const Color(0xFF7C4DFF);
    if (surah.isMedinan) return const Color(0xFF1E88E5);
    return AppColors.primary;
  }

  String _revelationLabel(SurahInfoModel surah) {
    if (surah.isMeccan) return 'Meccan';
    if (surah.isMedinan) return 'Medinan';
    return surah.revelationType;
  }

  void _openReader(SurahInfoModel surah) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SurahReaderScreen(
          surahNumber: surah.number,
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final surahsAsync = ref.watch(allSurahsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _buildGradientBackground(
        child: SafeArea(
          child: surahsAsync.when(
            data: _buildContent,
            loading: () => const _SurahListLoadingState(),
            error: (error, _) => _SurahListErrorState(
              error: error.toString(),
              onRetry: () => ref.invalidate(allSurahsProvider),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGradientBackground({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            AppColors.primary.withValues(alpha: 0.07),
            AppColors.background,
            AppColors.background,
            AppColors.surfaceElevated.withValues(alpha: 0.90),
          ],
          stops: const [0.0, 0.18, 0.70, 1.0],
        ),
      ),
      child: child,
    );
  }

  Widget _buildContent(List<SurahInfoModel> surahs) {
    final filtered = _applyFilters(surahs);

    return CustomScrollView(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── Header Section ──
        SliverToBoxAdapter(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTopBar(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildHeroCard(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildSearchField(),
                    const SizedBox(height: AppSpacing.md),
                    _buildFilterRow(surahs),
                    const SizedBox(height: AppSpacing.lg),
                    _buildResultSummary(
                      total: surahs.length,
                      filtered: filtered.length,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                ),
              ),
            ),
          ),
        ),

        // ── List or Empty State ──
        if (filtered.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildEmptyState(),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.xl3 + AppSpacing.xl2,
            ),
            sliver: SliverList.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final surah = filtered[index];
                return _SurahCard(
                  surah: surah,
                  revelationColor: _revelationColor(surah),
                  revelationLabel: _revelationLabel(surah),
                  onTap: () => _openReader(surah),
                );
              },
            ),
          ),
      ],
    );
  }

  // ── Top Bar ───────────────────────────────────────────────

  Widget _buildTopBar() {
    return Row(
      children: [
        _CircleButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).maybePop();
          },
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Al-Quran Al-Kareem',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.accent,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Surah Index',
                style: AppTextStyles.titleLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        _CircleButton(
          icon: Icons.keyboard_arrow_up_rounded,
          onTap: () {
            HapticFeedback.selectionClick();
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
            );
          },
        ),
      ],
    );
  }

  // ── Hero Card ─────────────────────────────────────────────

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.26),
            AppColors.primary.withValues(alpha: 0.14),
            AppColors.accent.withValues(alpha: 0.10),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl3),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.20),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.10),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            top: -20,
            right: -14,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.accent.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            bottom: -28,
            left: -18,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.09),
              ),
            ),
          ),
          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Icon box
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: AppGradients.gold,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.24),
                          blurRadius: 14,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.menu_book_rounded,
                      color: Colors.black87,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Read all 114 Surahs',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Search by name, number, or revelation type. Tap any surah to begin reading.',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              // Info pills
              const Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  _InfoPill(
                    icon: Icons.auto_stories_rounded,
                    label: '114 Surahs',
                  ),
                  _InfoPill(
                    icon: Icons.format_list_numbered_rounded,
                    label: '6,236 Ayahs',
                  ),
                  _InfoPill(
                    icon: Icons.translate_rounded,
                    label: 'Arabic + English',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Search Field ──────────────────────────────────────────

  Widget _buildSearchField() {
    final isFocused = _searchFocusNode.hasFocus;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xl2),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(AppRadius.xl2),
            border: Border.all(
              color: isFocused
                  ? AppColors.accent.withValues(alpha: 0.44)
                  : AppColors.primary.withValues(alpha: 0.16),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            cursorColor: AppColors.accent,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md + 4,
              ),
              border: InputBorder.none,
              prefixIcon: Icon(
                Icons.search_rounded,
                color: AppColors.accent.withValues(alpha: 0.90),
                size: 22,
              ),
              hintText: 'Search surah by name, number, Arabic...',
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w500,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      onPressed: _clearSearch,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }

  // ── Filter Row ────────────────────────────────────────────

  Widget _buildFilterRow(List<SurahInfoModel> surahs) {
    final meccanCount = surahs.where((s) => s.isMeccan).length;
    final medinanCount = surahs.where((s) => s.isMedinan).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Filter by Revelation',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            _FilterChip(
              label: 'All',
              count: surahs.length,
              isSelected: _selectedFilter == SurahFilterType.all,
              color: AppColors.accent,
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedFilter = SurahFilterType.all);
              },
            ),
            _FilterChip(
              label: 'Meccan',
              count: meccanCount,
              isSelected: _selectedFilter == SurahFilterType.meccan,
              color: const Color(0xFF7C4DFF),
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedFilter = SurahFilterType.meccan);
              },
            ),
            _FilterChip(
              label: 'Medinan',
              count: medinanCount,
              isSelected: _selectedFilter == SurahFilterType.medinan,
              color: const Color(0xFF1E88E5),
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedFilter = SurahFilterType.medinan);
              },
            ),
          ],
        ),
      ],
    );
  }

  // ── Result Summary ────────────────────────────────────────

  Widget _buildResultSummary({
    required int total,
    required int filtered,
  }) {
    final isFiltering =
        _searchQuery.isNotEmpty || _selectedFilter != SurahFilterType.all;

    return Row(
      children: [
        Expanded(
          child: Text(
            isFiltering
                ? '$filtered surah${filtered == 1 ? '' : 's'} found'
                : 'Showing all $total surahs',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (isFiltering)
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() {
                _selectedFilter = SurahFilterType.all;
                _searchController.clear();
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs + 2,
              ),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppRadius.full),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.24),
                ),
              ),
              child: Text(
                'Reset',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── Empty State ───────────────────────────────────────────

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.xl2),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated.withValues(alpha: 0.86),
            borderRadius: BorderRadius.circular(AppRadius.xl3),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.16),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent.withValues(alpha: 0.10),
                ),
                child: Icon(
                  Icons.search_off_rounded,
                  size: 36,
                  color: AppColors.accent.withValues(alpha: 0.90),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'No Surah Found',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Aapki search ya filter se koi surah match nahi hui.\nSearch clear karke dobara try karein.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _selectedFilter = SurahFilterType.all;
                    _searchController.clear();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                ),
                icon: const Icon(Icons.restart_alt_rounded, size: 20),
                label: Text(
                  'Clear Filters',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SECTION 3 — SURAH CARD WIDGET
// ============================================================

class _SurahCard extends StatelessWidget {
  const _SurahCard({
    required this.surah,
    required this.revelationColor,
    required this.revelationLabel,
    required this.onTap,
  });

  final SurahInfoModel surah;
  final Color revelationColor;
  final String revelationLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl2 + 4),
        splashColor: AppColors.primary.withValues(alpha: 0.08),
        highlightColor: AppColors.primary.withValues(alpha: 0.04),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated.withValues(alpha: 0.90),
            borderRadius: BorderRadius.circular(AppRadius.xl2 + 4),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.12),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Number Badge
                _NumberBadge(number: surah.number),
                const SizedBox(width: AppSpacing.md),

                // Center Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name row
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              surah.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.titleSmall.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          _RevelationBadge(
                            label: revelationLabel,
                            color: revelationColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),

                      // English translation
                      Text(
                        surah.englishNameTranslation,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Ayah count + Read CTA
                      Row(
                        children: [
                          Icon(
                            Icons.format_list_numbered_rounded,
                            size: 14,
                            color: AppColors.accent.withValues(alpha: 0.88),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${surah.numberOfAyahs} Ayahs',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Icon(
                            Icons.chrome_reader_mode_outlined,
                            size: 14,
                            color: AppColors.primary.withValues(alpha: 0.88),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Read',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),

                // Right side: Arabic name + arrow
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      surah.nameArabic,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontFamily: 'Amiri',
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 15,
                      color: AppColors.accent.withValues(alpha: 0.88),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SECTION 4 — SMALL REUSABLE WIDGETS
// ============================================================

class _NumberBadge extends StatelessWidget {
  const _NumberBadge({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.92),
            AppColors.primary.withValues(alpha: 0.72),
            AppColors.accent.withValues(alpha: 0.68),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.20),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: Text(
          number.toString(),
          style: AppTextStyles.titleSmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _RevelationBadge extends StatelessWidget {
  const _RevelationBadge({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: color.withValues(alpha: 0.24),
        ),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 10,
        ),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs + 2,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.50),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: AppColors.accent.withValues(alpha: 0.92),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs + 2,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.16)
              : AppColors.surfaceElevated.withValues(alpha: 0.76),
          borderRadius: BorderRadius.circular(AppRadius.full),
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.48)
                : AppColors.primary.withValues(alpha: 0.14),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.10),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: isSelected ? color : AppColors.textSecondary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: AppSpacing.xs + 2),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xs + 2,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? color.withValues(alpha: 0.14)
                    : AppColors.primary.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(AppRadius.full),
              ),
              child: Text(
                '$count',
                style: AppTextStyles.labelSmall.copyWith(
                  color: isSelected ? color : AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 10,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Ink(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.14),
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SECTION 5 — LOADING STATE
// ============================================================

class _SurahListLoadingState extends StatelessWidget {
  const _SurahListLoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.xl3,
      ),
      children: [
        // Top bar shimmer
        Row(
          children: [
            _shimmerBox(width: 44, height: 44, radius: AppRadius.xl),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _shimmerBox(width: 110, height: 11, radius: AppRadius.full),
                  const SizedBox(height: 6),
                  _shimmerBox(width: 160, height: 18, radius: AppRadius.full),
                ],
              ),
            ),
            _shimmerBox(width: 44, height: 44, radius: AppRadius.xl),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Hero card shimmer
        _shimmerBox(width: double.infinity, height: 168, radius: AppRadius.xl3),
        const SizedBox(height: AppSpacing.lg),

        // Search shimmer
        _shimmerBox(width: double.infinity, height: 56, radius: AppRadius.xl2),
        const SizedBox(height: AppSpacing.md),

        // Filter chips shimmer
        _shimmerBox(width: 100, height: 12, radius: AppRadius.full),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            _shimmerBox(width: 76, height: 36, radius: AppRadius.full),
            const SizedBox(width: AppSpacing.sm),
            _shimmerBox(width: 102, height: 36, radius: AppRadius.full),
            const SizedBox(width: AppSpacing.sm),
            _shimmerBox(width: 108, height: 36, radius: AppRadius.full),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),

        // Summary shimmer
        _shimmerBox(width: 140, height: 14, radius: AppRadius.full),
        const SizedBox(height: AppSpacing.md),

        // Surah cards shimmer
        for (int i = 0; i < 8; i++) ...[
          _shimmerBox(
              width: double.infinity, height: 106, radius: AppRadius.xl2 + 4),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }

  static Widget _shimmerBox({
    required double width,
    required double height,
    required double radius,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

// ============================================================
// SECTION 6 — ERROR STATE
// ============================================================

class _SurahListErrorState extends StatelessWidget {
  const _SurahListErrorState({
    required this.error,
    required this.onRetry,
  });

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Center(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.xl2),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(AppRadius.xl3),
            border: Border.all(
              color: AppColors.error.withValues(alpha: 0.14),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 78,
                height: 78,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.error.withValues(alpha: 0.09),
                ),
                child: Icon(
                  Icons.error_outline_rounded,
                  size: 36,
                  color: AppColors.error.withValues(alpha: 0.84),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Unable to Load Surahs',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Quran data load karne mein kuch issue aaya. Retry karein.',
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                error,
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textTertiary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                  ),
                ),
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: Text(
                  'Retry',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// END OF FILE — surah_list_screen.dart
// ============================================================
