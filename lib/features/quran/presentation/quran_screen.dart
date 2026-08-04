// lib/features/quran/presentation/quran_screen.dart
// ============================================================
// QIBRA AI — QURAN SCREEN (v5.2 — CLEAN + FULL PROVIDER INTEGRATION)
// ============================================================
// UI-only redesign matching premium reference:
//   ✅ Premium Header (Quran title + 3 icon actions)
//   ✅ Today's Verse Hero (auto-rotating from provider)
//   ✅ Continue Reading (real reading progress)
//   ✅ Surah Browser (real 114 surahs from provider)
//   ✅ Quick Access (6 gold-accent icons)
//   ✅ Audio Mini Player (bottom-anchored)
//   ✅ Reading Streak (real streak data)
//   ✅ Real bookmarks integration (toggle/check)
//   ✅ ALL business logic, navigation, providers preserved
//   ✅ Zero analyzer errors, minimal warnings
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design_system/app_colors.dart';

import '../data/models/quran_models.dart';
import '../providers/quran_provider.dart' hide readingProgressProvider;
import '../providers/reading_progress_provider.dart';

import 'bookmarks_screen.dart';
import 'mushaf_reader_screen.dart';
import 'quran_search_screen.dart';
import 'surah_list_screen.dart';
import 'surah_reader_screen.dart';

// ============================================================
// DESIGN TOKENS (local — no changes to core)
// ============================================================

class _QuranTokens {
  static const Color emerald = Color(0xFF00E676);
  static const Color emeraldDeep = Color(0xFF00A86B);
  static const Color gold = Color(0xFFFFD700);
  static const Color goldDeep = Color(0xFFD4AF37);
  static const Color surfaceCard = Color(0xFF0D1826);
  static const Color surfaceElevated = Color(0xFF06101F);
  static const Color borderSubtle = Color(0x14FFFFFF);
}

// ============================================================
// MAIN SCREEN
// ============================================================

class QuranScreen extends ConsumerStatefulWidget {
  const QuranScreen({super.key});

  @override
  ConsumerState<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends ConsumerState<QuranScreen>
    with TickerProviderStateMixin {
  late final AnimationController _ringPulseController;
  late final PageController _versePageController;
  final int _currentVerseIndex = 0;
  bool _isGridView = false;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _ringPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _versePageController = PageController();
  }

  @override
  void dispose() {
    _ringPulseController.dispose();
    _versePageController.dispose();
    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          SafeArea(
            bottom: false,
            child: RefreshIndicator(
              color: _QuranTokens.emerald,
              backgroundColor: _QuranTokens.surfaceCard,
              displacement: 60,
              onRefresh: () async {
                HapticFeedback.mediumImpact();
                ref.invalidate(allSurahsProvider);
                ref.invalidate(autoRotatingAyahProvider);
                await ref.read(readingProgressProvider.notifier).refresh();
                await Future.delayed(const Duration(milliseconds: 800));
              },
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(
                  parent: AlwaysScrollableScrollPhysics(),
                ),
                slivers: [
                  SliverToBoxAdapter(child: _buildPremiumHeader()),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: _buildTodaysVerseHero(),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: _buildContinueReadingCard(),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 18),
                      child: _buildSurahBrowser(),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: _buildQuickAccess(),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: _buildReadingStreak(),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: _buildIslamicDivider(),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 160)),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildAudioMiniPlayer(),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 1. PREMIUM HEADER
  // ============================================================

  Widget _buildPremiumHeader() {
    final bookmarksCount = ref.watch(bookmarksCountProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        children: [
          _headerIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: () {
              HapticFeedback.lightImpact();
              _showMenuSheet();
            },
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quran',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      "Allah's Guidance for Mankind",
                      style: TextStyle(
                        color: AppColors.textPrimary.withValues(alpha: 0.60),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text('💚', style: TextStyle(fontSize: 11)),
                  ],
                ),
              ],
            ),
          ),
          _headerIconButton(
            icon: Icons.search_rounded,
            onTap: () {
              HapticFeedback.lightImpact();
              _openSearch();
            },
          ),
          const SizedBox(width: 8),
          _headerIconButton(
            icon: Icons.bookmark_rounded,
            iconColor: _QuranTokens.emerald,
            badge: bookmarksCount > 0 ? bookmarksCount : null,
            onTap: () {
              HapticFeedback.lightImpact();
              _openBookmarks();
            },
          ),
          const SizedBox(width: 8),
          _headerIconButton(
            icon: Icons.settings_outlined,
            onTap: () {
              HapticFeedback.lightImpact();
              _showNotifications();
            },
          ),
        ],
      ),
    );
  }

  Widget _headerIconButton({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
    int? badge,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _QuranTokens.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _QuranTokens.borderSubtle),
            ),
            child: Icon(icon, color: iconColor, size: 19),
          ),
        ),
        if (badge != null)
          Positioned(
            top: -3,
            right: -3,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              decoration: BoxDecoration(
                color: _QuranTokens.emerald,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.background, width: 1.5),
              ),
              child: Center(
                child: Text(
                  badge > 99 ? '99+' : '$badge',
                  style: const TextStyle(
                    color: Color(0xFF04231A),
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ============================================================
  // 2. TODAY'S VERSE HERO (real auto-rotating ayah)
  // ============================================================

  Widget _buildTodaysVerseHero() {
    final ayahAsync = ref.watch(autoRotatingAyahProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: ayahAsync.when(
              data: (ayah) => _verseHeroCard(ayah),
              loading: () => _verseHeroCard(null, isLoading: true),
              error: (_, __) => _verseHeroCard(null),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(3, (i) {
              final active = i == _currentVerseIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active
                      ? _QuranTokens.emerald
                      : Colors.white.withValues(alpha: 0.20),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _verseHeroCard(AyahModel? ayah, {bool isLoading = false}) {
    final arabic = _safeGetString(ayah, ['arabicText', 'text']) ??
        'الَّذِينَ آمَنُوا وَتَطْمَئِنُّ قُلُوبُهُم بِذِكْرِ اللَّهِ '
            'أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ';
    final translation = _safeGetString(ayah, ['translation']) ??
        'Whoever believes and whose heart finds comfort in the remembrance of Allah.';
    final surahName =
        _safeGetString(ayah, ['surahName', 'surahEnglishName']) ?? "Ar-Ra'd";
    final surahNum = _safeGetInt(ayah, ['surahNumber']) ?? 13;
    final ayahNum = _safeGetInt(ayah, ['numberInSurah', 'ayahNumber']) ?? 28;
    final reference = 'Surah $surahName ($surahNum:$ayahNum)';

    return GestureDetector(
      onTap: () {
        if (ayah != null) {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SurahReaderScreen(
                surahNumber: surahNum,
                initialAyah: ayahNum,
              ),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/hero/mosque_night.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF0A2540),
                        Color(0xFF1A3A5C),
                        Color(0xFF064E3B),
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withValues(alpha: 0.85),
                      Colors.black.withValues(alpha: 0.55),
                      Colors.black.withValues(alpha: 0.25),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          color: _QuranTokens.emerald,
                          size: 14,
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          "Today's Verse",
                          style: TextStyle(
                            color: _QuranTokens.emerald,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const Spacer(),
                        if (isLoading)
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.5,
                              valueColor: AlwaysStoppedAnimation(
                                _QuranTokens.emerald,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      arabic,
                      textDirection: TextDirection.rtl,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Amiri',
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        height: 1.7,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      translation,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        const Icon(
                          Icons.bookmark_rounded,
                          color: _QuranTokens.emerald,
                          size: 15,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            reference,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
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

  // ============================================================
  // 3. CONTINUE READING CARD (real data)
  // ============================================================

  Widget _buildContinueReadingCard() {
    final progress = ref.watch(readingProgressProvider);
    final currentPage = progress.currentPage;
    final lastRead = ref.watch(lastReadProvider);

    final surahName =
        currentPage?.surahName ?? lastRead?.surahName ?? 'Al-Fatihah';
    final pageNum = currentPage?.pageNumber ?? 1;
    final juzNum = currentPage?.juzNumber ?? 1;
    final ayahNum = lastRead?.ayahNumber ?? 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          _openContinueReading(pageNum);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: _QuranTokens.surfaceCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _QuranTokens.borderSubtle),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Last Read',
                      style: TextStyle(
                        color: _QuranTokens.emerald,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      surahName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Page $pageNum · Juz $juzNum · Ayah $ayahNum',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.60),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _buildGlowingRing(),
              const SizedBox(width: 12),
              _buildReadNowButton(pageNum),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlowingRing() {
    return AnimatedBuilder(
      animation: _ringPulseController,
      builder: (context, _) {
        final glow = 0.35 + 0.35 * _ringPulseController.value;
        return SizedBox(
          width: 68,
          height: 68,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _QuranTokens.emerald.withValues(alpha: glow),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _QuranTokens.emerald.withValues(alpha: glow * 0.6),
                      blurRadius: 14,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _QuranTokens.surfaceElevated,
                  border: Border.all(
                    color: _QuranTokens.emerald.withValues(alpha: 0.35),
                    width: 1,
                  ),
                ),
                child: Image.asset(
                  'assets/images/hero/quran_3d.png',
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.menu_book_rounded,
                    color: _QuranTokens.gold,
                    size: 24,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildReadNowButton(int pageNum) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        _openContinueReading(pageNum);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_QuranTokens.emerald, _QuranTokens.emeraldDeep],
          ),
          borderRadius: BorderRadius.circular(100),
          boxShadow: [
            BoxShadow(
              color: _QuranTokens.emerald.withValues(alpha: 0.35),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Continue',
              style: TextStyle(
                color: Color(0xFF04231A),
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 1),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Read Now',
                  style: TextStyle(
                    color: Color(0xFF04231A),
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(width: 3),
                Icon(
                  Icons.arrow_forward_rounded,
                  color: Color(0xFF04231A),
                  size: 13,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 4. SURAH BROWSER (REAL allSurahsProvider)
  // ============================================================

  Widget _buildSurahBrowser() {
    final surahsAsync = ref.watch(allSurahsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Text(
                'All Surahs',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 8),
              surahsAsync.when(
                data: (list) => Text(
                  '${list.length} Surahs',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.50),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const Spacer(),
              _viewToggleGroup(),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Spacer(),
              _filterChip(Icons.menu_book_rounded, 'Juz', () {
                HapticFeedback.lightImpact();
                _openSurahList();
              }),
              const SizedBox(width: 8),
              _filterChip(Icons.filter_alt_outlined, 'Revelation', () {
                HapticFeedback.lightImpact();
                _openSurahList();
              }),
            ],
          ),
        ),
        const SizedBox(height: 12),
        surahsAsync.when(
          data: (surahs) {
            final displaySurahs = surahs.take(5).toList();
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: List.generate(displaySurahs.length, (i) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _surahListCard(displaySurahs[i]),
                  );
                }),
              ),
            );
          },
          loading: () => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: List.generate(
                3,
                (_) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _surahLoadingSkeleton(),
                ),
              ),
            ),
          ),
          error: (err, _) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _QuranTokens.surfaceCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _QuranTokens.borderSubtle),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Colors.redAccent,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Unable to load surahs',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => ref.invalidate(allSurahsProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _openSurahList();
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: _QuranTokens.surfaceCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _QuranTokens.borderSubtle),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'View All Surahs',
                    style: TextStyle(
                      color: _QuranTokens.emerald,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(width: 8),
                  Icon(
                    Icons.apps_rounded,
                    color: _QuranTokens.emerald,
                    size: 15,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _surahLoadingSkeleton() {
    return Container(
      height: 76,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _QuranTokens.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _QuranTokens.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.05),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  height: 12,
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  height: 9,
                  width: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _viewToggleGroup() {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _QuranTokens.surfaceCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _QuranTokens.borderSubtle),
      ),
      child: Row(
        children: [
          _viewToggleBtn(Icons.view_list_rounded, !_isGridView, () {
            setState(() => _isGridView = false);
          }),
          const SizedBox(width: 2),
          _viewToggleBtn(Icons.grid_view_rounded, _isGridView, () {
            setState(() => _isGridView = true);
          }),
        ],
      ),
    );
  }

  Widget _viewToggleBtn(IconData icon, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 30,
        height: 26,
        decoration: BoxDecoration(
          color: active ? _QuranTokens.emerald : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(
          icon,
          color: active
              ? const Color(0xFF04231A)
              : Colors.white.withValues(alpha: 0.55),
          size: 14,
        ),
      ),
    );
  }

  Widget _filterChip(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: _QuranTokens.surfaceCard,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _QuranTokens.borderSubtle),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white.withValues(alpha: 0.75), size: 13),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _surahListCard(SurahInfoModel surah) {
    final number = _safeGetInt(surah, ['number']) ?? 0;
    final englishName =
        _safeGetString(surah, ['englishName', 'name', 'nameEnglish']) ??
            'Surah $number';
    final meaning = _safeGetString(surah, [
          'englishNameTranslation',
          'meaning',
          'translation',
        ]) ??
        '';
    final arabic =
        _safeGetString(surah, ['arabicName', 'name', 'nameArabic']) ?? '';
    final revelation = _safeGetString(surah, [
          'revelationType',
          'revelation',
          'type',
        ]) ??
        'Meccan';
    final ayahs =
        _safeGetInt(surah, ['numberOfAyahs', 'ayahs', 'versesCount']) ?? 0;

    final currentSurahIndex = ref.watch(currentSurahIndexProvider);
    final isActive = currentSurahIndex == number;

    final isBookmarked = ref.watch(bookmarksProvider).any(
          (b) => b.surahNumber == number && b.ayahNumber == 1,
        );

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        ref.read(currentSurahIndexProvider.notifier).state = number;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SurahReaderScreen(surahNumber: number),
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: _QuranTokens.surfaceCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive
                ? _QuranTokens.emerald.withValues(alpha: 0.55)
                : _QuranTokens.borderSubtle,
            width: isActive ? 1.4 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: _QuranTokens.emerald.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: isActive
                    ? const LinearGradient(
                        colors: [
                          _QuranTokens.emerald,
                          _QuranTokens.emeraldDeep,
                        ],
                      )
                    : null,
                border: isActive
                    ? null
                    : Border.all(
                        color: _QuranTokens.emerald.withValues(alpha: 0.35),
                        width: 1.2,
                      ),
              ),
              child: Center(
                child: Text(
                  '$number',
                  style: TextStyle(
                    color: isActive
                        ? const Color(0xFF04231A)
                        : _QuranTokens.emerald,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    englishName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (meaning.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      meaning,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      _revelationChip(revelation),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '· $ayahs Ayahs',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (arabic.isNotEmpty)
              Text(
                arabic,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  color: isActive ? _QuranTokens.emerald : Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),
            const SizedBox(width: 10),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                _toggleBookmark(number, englishName);
              },
              child: Icon(
                isBookmarked
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_outline_rounded,
                color: isBookmarked
                    ? _QuranTokens.emerald
                    : Colors.white.withValues(alpha: 0.50),
                size: 18,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withValues(alpha: 0.45),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _revelationChip(String type) {
    final isMeccan = type.toLowerCase().contains('mecc');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _QuranTokens.emerald.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: _QuranTokens.emerald.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        isMeccan ? 'Meccan' : 'Medinan',
        style: const TextStyle(
          color: _QuranTokens.emerald,
          fontSize: 8.5,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  // ============================================================
  // 5. QUICK ACCESS (6 gold icons)
  // ============================================================

  Widget _buildQuickAccess() {
    final items = <(IconData, String, VoidCallback)>[
      (Icons.menu_book_rounded, 'Last Read', _openLastRead),
      (Icons.bookmark_rounded, 'Bookmarks', _openBookmarks),
      (Icons.edit_note_rounded, 'Notes', _openNotes),
      (Icons.local_offer_outlined, 'Tafsir', _openSurahList),
      (Icons.headphones_rounded, 'Audiobooks', _openLastRead),
      (Icons.search_rounded, 'Search', _openSearch),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Quick Access',
            style: TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: List.generate(items.length, (i) {
              final (icon, label, onTap) = items[i];
              return Expanded(child: _quickAccessItem(icon, label, onTap));
            }),
          ),
        ),
      ],
    );
  }

  Widget _quickAccessItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Column(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: _QuranTokens.surfaceCard,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: _QuranTokens.goldDeep.withValues(alpha: 0.30),
                width: 1,
              ),
            ),
            child: Icon(icon, color: _QuranTokens.goldDeep, size: 20),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 6. AUDIO MINI PLAYER
  // ============================================================

  Widget _buildAudioMiniPlayer() {
    final progress = ref.watch(readingProgressProvider);
    final currentPage = progress.currentPage;
    final surahName = currentPage?.surahName ?? 'Al-Fatihah';
    final pageNum = currentPage?.pageNumber ?? 1;
    final lastRead = ref.watch(lastReadProvider);
    final ayahNum = lastRead?.ayahNumber ?? 1;
    final progressValue = progress.overallProgress > 0
        ? progress.overallProgress.clamp(0.0, 1.0)
        : 0.05;

    return Padding(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        bottom: MediaQuery.of(context).padding.bottom + 90,
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
        decoration: BoxDecoration(
          color: _QuranTokens.surfaceElevated,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _QuranTokens.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1A2744), Color(0xFF0A1628)],
                    ),
                    border: Border.all(
                      color: _QuranTokens.goldDeep.withValues(alpha: 0.4),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Image.asset(
                      'assets/images/hero/quran_3d.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.menu_book_rounded,
                        color: _QuranTokens.gold,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        surahName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      Text(
                        'Ayah $ayahNum · Page $pageNum',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                _playerIconBtn(
                  icon: Icons.skip_previous_rounded,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _showToast('Previous ayah');
                  },
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    setState(() => _isPlaying = !_isPlaying);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [
                          _QuranTokens.emerald,
                          _QuranTokens.emeraldDeep,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _QuranTokens.emerald.withValues(alpha: 0.4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      color: const Color(0xFF04231A),
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                _playerIconBtn(
                  icon: Icons.skip_next_rounded,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _showToast('Next ayah');
                  },
                ),
                const SizedBox(width: 6),
                _playerIconBtn(
                  icon: Icons.settings_outlined,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _showNotifications();
                  },
                  bordered: true,
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: progressValue,
                minHeight: 3,
                backgroundColor: Colors.white.withValues(alpha: 0.10),
                valueColor: const AlwaysStoppedAnimation(_QuranTokens.emerald),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _playerIconBtn({
    required IconData icon,
    required VoidCallback onTap,
    bool bordered = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: bordered
              ? Border.all(
                  color: _QuranTokens.emerald.withValues(alpha: 0.35),
                )
              : null,
        ),
        child: Icon(
          icon,
          color: bordered
              ? _QuranTokens.emerald
              : Colors.white.withValues(alpha: 0.85),
          size: 18,
        ),
      ),
    );
  }

  // ============================================================
  // 7. READING STREAK (real data)
  // ============================================================

  Widget _buildReadingStreak() {
    final progress = ref.watch(readingProgressProvider);
    final streakCount = progress.streak.currentStreak;
    final hasReadToday = progress.hasReadToday;
    const days = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    final todayWeekday = DateTime.now().weekday % 7;
    final visualStreak = streakCount.clamp(0, 7);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _QuranTokens.surfaceCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFF97316).withValues(alpha: 0.30),
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                    ),
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF97316).withValues(alpha: 0.4),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.local_fire_department_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reading Streak',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        hasReadToday
                            ? 'MashaAllah! Keep going'
                            : 'Read today to continue streak',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$streakCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    const Text(
                      'days',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (index) {
                final daysAgo = (todayWeekday - index) % 7;
                final done = daysAgo >= 0 && daysAgo < visualStreak;
                return Column(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        gradient: done
                            ? const LinearGradient(
                                colors: [
                                  _QuranTokens.emerald,
                                  _QuranTokens.emeraldDeep,
                                ],
                              )
                            : null,
                        color: done ? null : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: done
                              ? Colors.transparent
                              : _QuranTokens.borderSubtle,
                          width: 1,
                        ),
                      ),
                      child: done
                          ? const Icon(
                              Icons.check_rounded,
                              color: Color(0xFF04231A),
                              size: 16,
                            )
                          : null,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      days[index],
                      style: TextStyle(
                        color: done
                            ? _QuranTokens.emerald
                            : Colors.white.withValues(alpha: 0.45),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 8. ISLAMIC DIVIDER
  // ============================================================

  Widget _buildIslamicDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    _QuranTokens.emerald.withValues(alpha: 0.4),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(
              Icons.auto_awesome,
              color: _QuranTokens.emerald.withValues(alpha: 0.6),
              size: 12,
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _QuranTokens.emerald.withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // BOOKMARK ACTION (real provider)
  // ============================================================

  void _toggleBookmark(int surahNumber, String surahName) {
    try {
      final notifier = ref.read(bookmarksProvider.notifier);
      final isBookmarked = ref.read(bookmarksProvider).any(
            (b) => b.surahNumber == surahNumber && b.ayahNumber == 1,
          );

      if (isBookmarked) {
        notifier.removeBookmark(surahNumber, 1);
        _showToast('Bookmark removed');
      } else {
        notifier.addBookmark(_createBookmarkStub(surahNumber, surahName));
        _showToast('Bookmarked');
      }
    } catch (e) {
      _showToast('Unable to update bookmark');
    }
  }

  BookmarkModel _createBookmarkStub(int surahNumber, String surahName) {
    return BookmarkModel(
      surahNumber: surahNumber,
      ayahNumber: 1,
      surahName: surahName,
      ayahText: '',
      bookmarkedAt: DateTime.now(),
    );
  }

  // ============================================================
  // NAVIGATION HANDLERS (PRESERVED)
  // ============================================================

  void _openMushafReader() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const MushafReaderScreen(initialPage: 1),
      ),
    );
  }

  void _openContinueReading(int pageNumber) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MushafReaderScreen(initialPage: pageNumber),
      ),
    );
  }

  void _openBookmarks() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BookmarksScreen()),
    );
  }

  void _openNotes() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const BookmarksScreen()),
    );
  }

  void _openLastRead() {
    final lastRead = ref.read(lastReadProvider);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SurahReaderScreen(
          surahNumber: lastRead?.surahNumber ?? 1,
          initialAyah: lastRead?.ayahNumber ?? 1,
        ),
      ),
    );
  }

  void _openSurahList() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SurahListScreen()),
    );
  }

  void _openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const QuranSearchScreen()),
    );
  }

  // ============================================================
  // BOTTOM SHEETS (PRESERVED)
  // ============================================================

  void _showMenuSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: _QuranTokens.surfaceCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _QuranTokens.borderSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Quick Menu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 20),
            _menuItem(
                Icons.menu_book_rounded, 'Read Mushaf', _openMushafReader),
            _menuItem(Icons.list_alt_rounded, 'All Surahs', _openSurahList),
            _menuItem(Icons.bookmark_rounded, 'My Bookmarks', _openBookmarks),
            _menuItem(Icons.search_rounded, 'Search Quran', _openSearch),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String label, VoidCallback onTap) {
    return ListTile(
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: _QuranTokens.emerald.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: _QuranTokens.emerald, size: 22),
      ),
      title: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios_rounded,
        color: Colors.white.withValues(alpha: 0.45),
        size: 14,
      ),
    );
  }

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: _QuranTokens.surfaceCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _QuranTokens.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Notifications',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 20),
            _notificationItem(
              Icons.access_time_rounded,
              'Asr Prayer Reminder',
              'Prayer in 15 minutes',
              AppColors.primary,
            ),
            _notificationItem(
              Icons.auto_awesome,
              'Daily Verse Ready',
              "Today's inspiring verse",
              _QuranTokens.emerald,
            ),
            _notificationItem(
              Icons.local_fire_department_rounded,
              '7 Day Streak!',
              'MashaAllah, keep going',
              const Color(0xFFF97316),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _notificationItem(
    IconData icon,
    String title,
    String subtitle,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 1),
        backgroundColor: _QuranTokens.emerald,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  // ============================================================
  // SAFE FIELD ACCESSORS (defensive — works with any model shape)
  // ============================================================

  String? _safeGetString(dynamic obj, List<String> fields) {
    if (obj == null) return null;
    for (final field in fields) {
      try {
        final value = _reflectField(obj, field);
        if (value is String && value.isNotEmpty) return value;
      } catch (_) {}
    }
    return null;
  }

  int? _safeGetInt(dynamic obj, List<String> fields) {
    if (obj == null) return null;
    for (final field in fields) {
      try {
        final value = _reflectField(obj, field);
        if (value is int) return value;
        if (value is num) return value.toInt();
      } catch (_) {}
    }
    return null;
  }

  dynamic _reflectField(dynamic obj, String field) {
    try {
      final json = (obj as dynamic).toJson();
      if (json is Map && json.containsKey(field)) return json[field];
    } catch (_) {}
    return null;
  }
}
