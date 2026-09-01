// lib/features/quran/presentation/quran_search_screen.dart

// ============================================================
// QIBRA AI — QURAN SEARCH SCREEN (v1.0)
// Phase: 8.6 — Full-Text Quran Search
// ============================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/qibra_colors.dart';
import '../../../core/utils/search_normalizer.dart';
import '../../../core/design_system/app_design_system.dart';
import '../../../core/design_system/app_typography.dart';
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

List<PopularTopic> _popularTopicsFor(QibraColors colors) => [
  PopularTopic(
    label: 'Mercy',
    icon: Icons.favorite_rounded,
    color: colors.primary,
    searchQuery: 'mercy',
  ),
  PopularTopic(
    label: 'Patience',
    icon: Icons.self_improvement_rounded,
    color: colors.primarySoft,
    searchQuery: 'patience',
  ),
  PopularTopic(
    label: 'Paradise',
    icon: Icons.park_rounded,
    color: colors.primarySoft,
    searchQuery: 'paradise',
  ),
  PopularTopic(
    label: 'Prayer',
    icon: Icons.mosque_rounded,
    color: colors.primary,
    searchQuery: 'prayer',
  ),
  PopularTopic(
    label: 'Faith',
    icon: Icons.light_mode_rounded,
    color: colors.primary,
    searchQuery: 'faith',
  ),
  PopularTopic(
    label: 'Guidance',
    icon: Icons.explore_rounded,
    color: colors.primarySoft,
    searchQuery: 'guidance',
  ),
  PopularTopic(
    label: 'Forgiveness',
    icon: Icons.healing_rounded,
    color: colors.primary,
    searchQuery: 'forgive',
  ),
  PopularTopic(
    label: 'Charity',
    icon: Icons.volunteer_activism_rounded,
    color: colors.primary,
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
    final colors = QibraColors.of(context);
    final searchState = ref.watch(searchQuranProvider);
    final recentSearches = ref.watch(recentSearchesProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colors.primary.withValues(alpha: 0.07),
              colors.background,
              colors.background,
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
    final colors = QibraColors.of(context);
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
                tooltip: 'Back',
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
                      'Explore the Quran',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Search',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: colors.textPrimary,
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
    final colors = QibraColors.of(context);
    final isFocused = _searchFocusNode.hasFocus;
    final hasText = _currentQuery.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        border: Border.all(
          color: isFocused ? colors.primary : colors.border,
        ),
      ),
      child: TextField(
        controller: _searchController,
        focusNode: _searchFocusNode,
        style: AppTextStyles.bodyMedium.copyWith(
          color: colors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        cursorColor: colors.primary,
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
            color: colors.primary,
            size: 24,
          ),
          hintText: 'Search Quran (English or Arabic)...',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: colors.textTertiary,
            fontWeight: FontWeight.w500,
          ),
          suffixIcon: hasText
              ? IconButton(
                  onPressed: _clearSearch,
                  icon: Icon(
                    Icons.close_rounded,
                    color: colors.textSecondary,
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
                      color: colors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                    ),
                    child: Text(
                      '6236',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
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
    final colors = QibraColors.of(context);
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
    final colors = QibraColors.of(context);
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
                Icon(
                  Icons.history_rounded,
                  color: colors.textSecondary,
                  size: 18,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Recent Searches',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: colors.textPrimary,
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
                      color: colors.error,
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
              Icon(
                Icons.trending_up_rounded,
                color: colors.primary,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Popular Topics',
                style: AppTextStyles.labelLarge.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final cols = constraints.maxWidth < 360 ? 2 : 4;
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  crossAxisSpacing: AppSpacing.sm,
                  mainAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 0.95,
                ),
                itemCount: _popularTopicsFor(colors).length,
                itemBuilder: (context, index) {
                  final topic = _popularTopicsFor(colors)[index];
                  return _TopicCard(
                    topic: topic,
                    onTap: () => _performSearch(topic.searchQuery),
                  );
                },
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
    final colors = QibraColors.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        border: Border.all(color: colors.border),
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
                  color: colors.cardMuted,
                  shape: BoxShape.circle,
                  border: Border.all(color: colors.border),
                ),
                child: Icon(
                  Icons.lightbulb_outline_rounded,
                  color: colors.textSecondary,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Search Tips',
                style: AppTextStyles.labelLarge.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildTip(Icons.translate_rounded, 'Search in English or Arabic text'),
          _buildTip(Icons.menu_book_rounded, 'Type surah name like "Al-Fatiha"'),
          _buildTip(Icons.format_list_numbered_rounded, 'Enter numbers for surah 1-114'),
          _buildTip(Icons.auto_awesome_rounded, 'Try topics: mercy, forgiveness, prayer'),
        ],
      ),
    );
  }

  Widget _buildTip(IconData icon, String text) {
    final colors = QibraColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 14, color: colors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: colors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    final colors = QibraColors.of(context);
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
                  color: colors.cardMuted,
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
    final colors = QibraColors.of(context);
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
                color: colors.error.withValues(alpha: 0.12),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                color: colors.error,
                size: 40,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Search Failed',
              style: AppTextStyles.titleSmall.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              error,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    final colors = QibraColors.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.surfaceElevated,
              ),
              child: Icon(
                Icons.search_off_rounded,
                color: colors.textTertiary,
                size: 50,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'No matches found',
              style: AppTextStyles.titleSmall.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Try different keywords or\nexplore popular topics',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(
                color: colors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList(List<SearchResultModel> results) {
    final colors = QibraColors.of(context);
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
    final colors = QibraColors.of(context);
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: 4,
          ),
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.14),
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
                color: colors.primary,
              ),
              const SizedBox(width: 4),
              Text(
                searchingText ? 'Searching...' : '${count ?? 0} results',
                style: AppTextStyles.labelSmall.copyWith(
                  color: colors.primary,
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
            color: colors.textSecondary,
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
    final colors = QibraColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        splashColor: colors.primary.withValues(alpha: 0.10),
        child: Ink(
          decoration: BoxDecoration(
            color: colors.surfaceElevated,
            borderRadius: BorderRadius.circular(AppRadius.xl2),
            border: Border.all(color: colors.border),
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
                  color: colors.surface,
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
                        color: colors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${result.ayahNumber}',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: colors.onPrimary,
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
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Surah ${result.surahNumber} • Ayah ${result.ayahNumber}',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: colors.textTertiary,
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
                        color: colors.cardMuted,
                        borderRadius: BorderRadius.circular(AppRadius.full),
                        border: Border.all(color: colors.border),
                      ),
                      child: Text(
                        result.isArabicMatch ? 'AR' : 'EN',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: result.isArabicMatch
                              ? colors.textPrimary
                              : colors.textSecondary,
                          fontWeight: FontWeight.w700,
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
                  style: AppArabicStyles.quranMedium
                      .copyWith(color: colors.textPrimary),
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
                    context,
                    result.translation!,
                    query,
                    AppTextStyles.bodySmall.copyWith(
                      color: colors.textSecondary,
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
                  color: colors.surface,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(AppRadius.xl2),
                    bottomRight: Radius.circular(AppRadius.xl2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.touch_app_rounded,
                      size: 14,
                      color: colors.primary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Tap to open in reader',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: colors.primary,
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

  Widget _buildHighlightedText(
    BuildContext context,
    String text,
    String query,
    TextStyle style,
  ) {
    final colors = QibraColors.of(context);
    if (query.isEmpty) {
      return Text(text,
          style: style, maxLines: 3, overflow: TextOverflow.ellipsis);
    }

    // Diacritic/hamza-aware matching (Stage 3: SearchNormalizer) — spans
    // come back in ORIGINAL-text coordinates, so highlights never shift.
    final spans = SearchNormalizer.allMatches(text, query);
    final matches = <TextSpan>[];
    int lastIndex = 0;

    for (final m in spans) {
      if (m.start > lastIndex) {
        matches.add(TextSpan(
          text: text.substring(lastIndex, m.start),
          style: style,
        ));
      }
      matches.add(TextSpan(
        text: text.substring(m.start, m.end),
        style: style.copyWith(
          color: colors.primary,
          fontWeight: FontWeight.w800,
          backgroundColor: colors.primary.withValues(alpha: 0.14),
        ),
      ));
      lastIndex = m.end;
    }

    if (lastIndex < text.length) {
      matches.add(TextSpan(
        text: text.substring(lastIndex),
        style: style,
      ));
    }

    return RichText(
      text: TextSpan(children: matches, style: style),
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
    final colors = QibraColors.of(context);
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
            color: colors.surfaceElevated,
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.history_rounded,
                size: 14,
                color: colors.textTertiary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                query,
                style: AppTextStyles.labelMedium.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              GestureDetector(
                onTap: onRemove,
                child: Container(
                  padding: const EdgeInsets.all(2),
                  child: Icon(
                    Icons.close_rounded,
                    size: 14,
                    color: colors.textTertiary,
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
    final colors = QibraColors.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Ink(
          decoration: BoxDecoration(
            color: colors.surfaceElevated,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: colors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
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
                  color: colors.textPrimary,
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
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    final button = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        child: Ink(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: colors.surfaceElevated,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            border: Border.all(color: colors.border),
          ),
          child: Icon(icon, size: 20, color: colors.textPrimary),
        ),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

// ============================================================
// END OF FILE — quran_search_screen.dart
// ============================================================
