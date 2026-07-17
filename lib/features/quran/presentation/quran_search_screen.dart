// lib/features/quran/presentation/quran_search_screen.dart

// ============================================================
// QIBRA AI — QURAN SEARCH SCREEN (v1.0)
// Phase: 8.6 — Full-Text Quran Search
// ============================================================

import 'dart:async';
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
// SECTION 1 — RECENT SEARCHES PROVIDER (local)
// ============================================================

class RecentSearchesNotifier extends StateNotifier<List<String>> {
  RecentSearchesNotifier() : super([]);

  void add(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    final newList = [trimmed, ...state.where((q) => q != trimmed)];
    if (newList.length > 10) {
      state = newList.sublist(0, 10);
    } else {
      state = newList;
    }
  }

  void remove(String query) {
    state = state.where((q) => q != query).toList();
  }

  void clear() {
    state = [];
  }
}

final recentSearchesProvider =
    StateNotifierProvider<RecentSearchesNotifier, List<String>>((ref) {
  return RecentSearchesNotifier();
});

// ============================================================
// SECTION 2 — POPULAR TOPICS
// ============================================================

class PopularTopic {
  const PopularTopic({
    required this.label,
    required this.icon,
    required this.color,
    required this.searchQuery,
  });

  final String label;
  final IconData icon;
  final Color color;
  final String searchQuery;
}

const _popularTopics = [
  PopularTopic(
    label: 'Mercy',
    icon: Icons.favorite_rounded,
    color: Color(0xFFEC407A),
    searchQuery: 'mercy',
  ),
  PopularTopic(
    label: 'Patience',
    icon: Icons.self_improvement_rounded,
    color: Color(0xFF7E57C2),
    searchQuery: 'patience',
  ),
  PopularTopic(
    label: 'Paradise',
    icon: Icons.park_rounded,
    color: Color(0xFF66BB6A),
    searchQuery: 'paradise',
  ),
  PopularTopic(
    label: 'Prayer',
    icon: Icons.mosque_rounded,
    color: Color(0xFF42A5F5),
    searchQuery: 'prayer',
  ),
  PopularTopic(
    label: 'Faith',
    icon: Icons.light_mode_rounded,
    color: Color(0xFFFFA726),
    searchQuery: 'faith',
  ),
  PopularTopic(
    label: 'Guidance',
    icon: Icons.explore_rounded,
    color: Color(0xFF26A69A),
    searchQuery: 'guidance',
  ),
  PopularTopic(
    label: 'Forgiveness',
    icon: Icons.healing_rounded,
    color: Color(0xFFAB47BC),
    searchQuery: 'forgive',
  ),
  PopularTopic(
    label: 'Charity',
    icon: Icons.volunteer_activism_rounded,
    color: Color(0xFFEF5350),
    searchQuery: 'charity',
  ),
];

// ============================================================
// SECTION 3 — MAIN SCREEN
// ============================================================

class QuranSearchScreen extends ConsumerStatefulWidget {
  const QuranSearchScreen({super.key});

  @override
  ConsumerState<QuranSearchScreen> createState() => _QuranSearchScreenState();
}

class _QuranSearchScreenState extends ConsumerState<QuranSearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  Timer? _debounce;
  String _currentQuery = '';

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    _searchController.addListener(_onSearchChanged);
    _searchFocusNode.addListener(() => setState(() {}));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _animController.forward();
        _searchFocusNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _animController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();

    // Debounce search
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (query != _currentQuery) {
        setState(() => _currentQuery = query);
        if (query.isNotEmpty) {
          ref.read(searchQuranProvider.notifier).search(query);
        } else {
          ref.read(searchQuranProvider.notifier).clear();
        }
      }
    });
  }

  void _performSearch(String query) {
    HapticFeedback.selectionClick();
    _searchController.text = query;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: query.length),
    );
    setState(() => _currentQuery = query);
    ref.read(searchQuranProvider.notifier).search(query);
    ref.read(recentSearchesProvider.notifier).add(query);
    _searchFocusNode.unfocus();
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(searchQuranProvider.notifier).clear();
    setState(() => _currentQuery = '');
    HapticFeedback.lightImpact();
  }

  void _openAyah(SearchResultModel result) {
    HapticFeedback.selectionClick();
    ref.read(recentSearchesProvider.notifier).add(_currentQuery);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SurahReaderScreen(
          surahNumber: result.surahNumber,
          initialAyah: result.ayahNumber,
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchQuranProvider);
    final recentSearches = ref.watch(recentSearchesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary.withValues(alpha: 0.07),
              AppColors.background,
              AppColors.background,
            ],
            stops: const [0.0, 0.18, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: _buildBody(searchState, recentSearches),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        children: [
          Row(
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
                      'EXPLORE THE QURAN',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Search',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          _buildSearchBar(),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    final isFocused = _searchFocusNode.hasFocus;
    final hasText = _currentQuery.isNotEmpty;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.xl2),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(AppRadius.xl2),
            border: Border.all(
              color: isFocused
                  ? AppColors.primary.withValues(alpha: 0.50)
                  : AppColors.primary.withValues(alpha: 0.16),
              width: 1.4,
            ),
            boxShadow: isFocused
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.14),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            cursorColor: AppColors.primary,
            textInputAction: TextInputAction.search,
            onSubmitted: _performSearch,
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md + 4,
              ),
              border: InputBorder.none,
              prefixIcon: Icon(
                Icons.search_rounded,
                color: AppColors.primary.withValues(alpha: 0.90),
                size: 24,
              ),
              hintText: 'Search Quran (English or Arabic)...',
              hintStyle: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textTertiary,
                fontWeight: FontWeight.w500,
              ),
              suffixIcon: hasText
                  ? IconButton(
                      onPressed: _clearSearch,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    )
                  : Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.md),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs + 2,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          '6236',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────

  Widget _buildBody(SearchState searchState, List<String> recentSearches) {
    // No search query - show suggestions
    if (_currentQuery.isEmpty) {
      return _buildSuggestionsView(recentSearches);
    }

    // Loading
    if (searchState.isLoading) {
      return _buildLoadingState();
    }

    // Error
    if (searchState.error != null) {
      return _buildErrorState(searchState.error!);
    }

    // No results
    if (searchState.results.isEmpty) {
      return _buildNoResults();
    }

    // Results
    return _buildResultsList(searchState.results);
  }

  Widget _buildSuggestionsView(List<String> recentSearches) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.xl3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent searches
          if (recentSearches.isNotEmpty) ...[
            Row(
              children: [
                const Icon(
                  Icons.history_rounded,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Recent Searches',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    ref.read(recentSearchesProvider.notifier).clear();
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                  ),
                  child: Text(
                    'Clear',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: recentSearches.map((query) {
                return _RecentSearchChip(
                  query: query,
                  onTap: () => _performSearch(query),
                  onRemove: () {
                    HapticFeedback.lightImpact();
                    ref.read(recentSearchesProvider.notifier).remove(query);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],

          // Popular topics
          Row(
            children: [
              const Icon(
                Icons.trending_up_rounded,
                color: AppColors.accent,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Popular Topics',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: AppSpacing.sm,
              mainAxisSpacing: AppSpacing.sm,
              childAspectRatio: 0.95,
            ),
            itemCount: _popularTopics.length,
            itemBuilder: (context, index) {
              final topic = _popularTopics[index];
              return _TopicCard(
                topic: topic,
                onTap: () => _performSearch(topic.searchQuery),
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),

          // Tips
          _buildTipsCard(),
        ],
      ),
    );
  }

  Widget _buildTipsCard() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.14),
            AppColors.accent.withValues(alpha: 0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.20),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lightbulb_outline_rounded,
                  color: AppColors.accent,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Search Tips',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildTip('🔤', 'Search in English or Arabic text'),
          _buildTip('📖', 'Type surah name like "Al-Fatiha"'),
          _buildTip('🔢', 'Enter numbers for surah 1-114'),
          _buildTip('✨', 'Try topics: mercy, forgiveness, prayer'),
        ],
      ),
    );
  }

  Widget _buildTip(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildResultsHeader(searchingText: true),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: ListView.separated(
              itemCount: 6,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) => Container(
                height: 140,
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh.withValues(alpha: 0.60),
                  borderRadius: BorderRadius.circular(AppRadius.xl2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.error.withValues(alpha: 0.12),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                color: AppColors.error,
                size: 40,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Search Failed',
              style: AppTextStyles.titleSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              error,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.surfaceElevated,
              ),
              child: const Icon(
                Icons.search_off_rounded,
                color: AppColors.textTertiary,
                size: 50,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No matches found',
              style: AppTextStyles.titleSmall.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Try different keywords or\nexplore popular topics',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList(List<SearchResultModel> results) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: _buildResultsHeader(
            count: results.length,
            searchingText: false,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.lg,
              AppSpacing.xl3,
            ),
            itemCount: results.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final result = results[index];
              return _SearchResultCard(
                result: result,
                query: _currentQuery,
                onTap: () => _openAyah(result),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResultsHeader({int? count, required bool searchingText}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(AppRadius.full),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                searchingText
                    ? Icons.search_rounded
                    : Icons.check_circle_rounded,
                size: 12,
                color: AppColors.primary,
              ),
              const SizedBox(width: 4),
              Text(
                searchingText ? 'Searching...' : '${count ?? 0} results',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Text(
          '"$_currentQuery"',
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

// ============================================================
// SECTION 4 — SEARCH RESULT CARD
// ============================================================

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({
    required this.result,
    required this.query,
    required this.onTap,
  });

  final SearchResultModel result;
  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        splashColor: AppColors.primary.withValues(alpha: 0.10),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated.withValues(alpha: 0.90),
            borderRadius: BorderRadius.circular(AppRadius.xl2),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.14),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.60),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppRadius.xl2),
                    topRight: Radius.circular(AppRadius.xl2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.90),
                            AppColors.accent.withValues(alpha: 0.70),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${result.ayahNumber}',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            result.surahName,
                            style: AppTextStyles.labelLarge.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Surah ${result.surahNumber} • Ayah ${result.ayahNumber}',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.textTertiary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs + 2,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: result.isArabicMatch
                            ? AppColors.accent.withValues(alpha: 0.14)
                            : const Color(0xFF1E88E5).withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        border: Border.all(
                          color: result.isArabicMatch
                              ? AppColors.accent.withValues(alpha: 0.24)
                              : const Color(0xFF1E88E5).withValues(alpha: 0.24),
                        ),
                      ),
                      child: Text(
                        result.isArabicMatch ? 'AR' : 'EN',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: result.isArabicMatch
                              ? AppColors.accent
                              : const Color(0xFF1E88E5),
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Arabic text
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Text(
                  result.ayahText,
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 20,
                    color: AppColors.textPrimary,
                    height: 2.0,
                  ),
                ),
              ),

              // Translation with highlight
              if (result.translation != null && result.translation!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.md,
                  ),
                  child: _buildHighlightedText(
                    result.translation!,
                    query,
                    AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),

              // Bottom bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface.withValues(alpha: 0.40),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(AppRadius.xl2),
                    bottomRight: Radius.circular(AppRadius.xl2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.touch_app_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Tap to open in reader',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHighlightedText(String text, String query, TextStyle style) {
    if (query.isEmpty) {
      return Text(text,
          style: style, maxLines: 3, overflow: TextOverflow.ellipsis);
    }

    final lowerText = text.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final matches = <TextSpan>[];
    int lastIndex = 0;

    int index = lowerText.indexOf(lowerQuery);
    while (index != -1) {
      // Text before match
      if (index > lastIndex) {
        matches.add(TextSpan(
          text: text.substring(lastIndex, index),
          style: style,
        ));
      }

      // Matched text
      matches.add(TextSpan(
        text: text.substring(index, index + query.length),
        style: style.copyWith(
          color: AppColors.accent,
          fontWeight: FontWeight.w800,
          backgroundColor: AppColors.accent.withValues(alpha: 0.16),
        ),
      ));

      lastIndex = index + query.length;
      index = lowerText.indexOf(lowerQuery, lastIndex);
    }

    // Remaining text
    if (lastIndex < text.length) {
      matches.add(TextSpan(
        text: text.substring(lastIndex),
        style: style,
      ));
    }

    return RichText(
      text: TextSpan(children: matches),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }
}

// ============================================================
// SECTION 5 — RECENT SEARCH CHIP
// ============================================================

class _RecentSearchChip extends StatelessWidget {
  const _RecentSearchChip({
    required this.query,
    required this.onTap,
    required this.onRemove,
  });

  final String query;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated.withValues(alpha: 0.78),
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.14),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.history_rounded,
                size: 14,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                query,
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: AppColors.textTertiary,
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
// SECTION 6 — POPULAR TOPIC CARD
// ============================================================

class _TopicCard extends StatelessWidget {
  const _TopicCard({
    required this.topic,
    required this.onTap,
  });

  final PopularTopic topic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated.withValues(alpha: 0.80),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: topic.color.withValues(alpha: 0.24),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: topic.color.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  topic.icon,
                  color: topic.color,
                  size: 20,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                topic.label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
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
// SECTION 7 — CIRCLE BUTTON
// ============================================================

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
          child: Icon(icon, size: 20, color: AppColors.textPrimary),
        ),
      ),
    );
  }
}

// ============================================================
// END OF FILE — quran_search_screen.dart
// ============================================================
