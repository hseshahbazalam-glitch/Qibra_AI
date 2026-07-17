// lib/features/quran/presentation/quran_screen.dart
// ============================================================
// QIBRA AI — QURAN SCREEN (PREMIUM v1.0)
// Phase: 8.1 — Quran Module Core (Reference Match)
// ============================================================
// Description: Production-grade Quran home screen with:
//   ── REFERENCE MATCH SECTIONS ──
//   ✨ Al-Fatihah Hero Card (with 3D Quran image + glow)
//   ✨ 4 Circular Category Buttons (Juz Index, Bookmarks, Last Read, Notes)
//   ✨ Reading Progress Card (with gold ornament + progress bar)
//   ✨ Recently Read Surahs (horizontal star badges)
//   ✨ Daily Verse Card (with mosque background)
//   ✨ Listen to Quran Card (with animated waveform)
//
// Widgets Used (from Phase 8 Setup):
//   - AppHeroImageCard (Step 2)
//   - AppCircularProgressRing (Step 3)
//   - AppOrnamentalStarBadge (Step 4)
//   - AppRecentSurahCard + AppRecentSurahList (Step 5)
//   - AppListenCard + AppQuranListenCard (Step 6)
//   - AppFeatureIllustrationCard (Step 7 — future use)
// ============================================================
import 'quran_search_screen.dart';
import 'bookmarks_screen.dart';
import 'surah_reader_screen.dart';
import 'surah_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/audio_provider.dart';
// ── Core ─────────────────────────────────────────────────
import 'package:qibra_ai/core/design_system/app_colors.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';

// ── 🆕 Premium Widgets (Phase 8 Setup — Steps 2-7) ──────
import 'package:qibra_ai/shared/widgets/cards/app_hero_image_card.dart';
import 'package:qibra_ai/shared/widgets/cards/app_recent_surah_card.dart';
import 'package:qibra_ai/shared/widgets/cards/app_listen_card.dart';
import 'package:qibra_ai/shared/widgets/badges/app_ornamental_star_badge.dart';

// ============================================================
// SECTION 1 — DATA MODELS
// ============================================================

/// Featured Surah data model (for Al-Fatihah hero)
class _FeaturedSurah {
  final int surahNumber;
  final String surahName;
  final String surahNameArabic;
  final int versesCount;
  final String revelationType; // "Makki" or "Madani"
  final String? description;

  const _FeaturedSurah({
    required this.surahNumber,
    required this.surahName,
    required this.surahNameArabic,
    required this.versesCount,
    required this.revelationType,
    this.description,
  });
}

/// Category button data model
class _QuranCategory {
  final String label;
  final IconData icon;
  final Color themeColor;
  final VoidCallback? onTap;

  const _QuranCategory({
    required this.label,
    required this.icon,
    required this.themeColor,
    this.onTap,
  });
}

/// Reading progress data model
class _ReadingProgress {
  final int currentJuz;
  final int totalJuz;
  final String currentSurah;
  final int currentAyah;
  final double progressPercent; // 0.0 - 1.0

  const _ReadingProgress({
    required this.currentJuz,
    required this.totalJuz,
    required this.currentSurah,
    required this.currentAyah,
    required this.progressPercent,
  });
}

/// 🆕 Popular Surah data model
class _PopularSurah {
  final int surahNumber;
  final String name;
  final String nameArabic;
  final int verses;
  final Color themeColor;
  final IconData decorativeIcon;
  final String? badge;

  const _PopularSurah({
    required this.surahNumber,
    required this.name,
    required this.nameArabic,
    required this.verses,
    required this.themeColor,
    required this.decorativeIcon,
    this.badge,
  });
}

/// Daily verse data model
class _DailyVerse {
  final String arabicText;
  final String translationText;
  final String surahName;
  final String surahNameArabic;
  final int surahNumber;
  final int ayahNumber;

  const _DailyVerse({
    required this.arabicText,
    required this.translationText,
    required this.surahName,
    required this.surahNameArabic,
    required this.surahNumber,
    required this.ayahNumber,
  });
}

// ============================================================
// SECTION 2 — STATIC DATA
// ============================================================

/// Featured Surah — Al-Fatihah (reference image match)
const _FeaturedSurah _featuredSurah = _FeaturedSurah(
  surahNumber: 1,
  surahName: 'Al-Fatihah',
  surahNameArabic: 'الفاتحة',
  versesCount: 7,
  revelationType: 'Makki',
  description: 'The Opening',
);

/// Current reading progress (dummy data — reference match)
const _ReadingProgress _currentReadingProgress = _ReadingProgress(
  currentJuz: 2,
  totalJuz: 30,
  currentSurah: 'Al-Baqarah',
  currentAyah: 45,
  progressPercent: 0.35,
);

/// Daily verse (reference image match)
const _DailyVerse _dailyVerse = _DailyVerse(
  arabicText: 'إِنَّ مَعَ الْعُسْرِ يُسْرًا',
  translationText: 'Indeed, with hardship [will be] ease.',
  surahName: 'Al-Inshirah',
  surahNameArabic: 'الشرح',
  surahNumber: 94,
  ayahNumber: 6,
);

/// Recently read surahs (reference match — 4 surahs)
const List<RecentSurahItem> _recentlyReadSurahs = [
  RecentSurahItem(
    surahNumber: 1,
    surahName: 'Al-Fatihah',
    versesCount: 7,
    surahNameArabic: 'الفاتحة',
    revelationType: SurahRevelationType.makki,
  ),
  RecentSurahItem(
    surahNumber: 2,
    surahName: 'Al-Baqarah',
    versesCount: 286,
    surahNameArabic: 'البقرة',
    revelationType: SurahRevelationType.madani,
  ),
  RecentSurahItem(
    surahNumber: 3,
    surahName: 'Aal-E-Imran',
    versesCount: 200,
    surahNameArabic: 'آل عمران',
    revelationType: SurahRevelationType.madani,
  ),
  RecentSurahItem(
    surahNumber: 4,
    surahName: 'An-Nisa',
    versesCount: 176,
    surahNameArabic: 'النساء',
    revelationType: SurahRevelationType.madani,
  ),
];

/// 🆕 Popular surahs (recommended for daily reading)
const List<_PopularSurah> _popularSurahs = [
  _PopularSurah(
    surahNumber: 18,
    name: 'Al-Kahf',
    nameArabic: 'الكهف',
    verses: 110,
    themeColor: Color(0xFF7C3AED),
    decorativeIcon: Icons.wb_sunny_rounded,
    badge: 'FRIDAY',
  ),
  _PopularSurah(
    surahNumber: 36,
    name: 'Ya-Sin',
    nameArabic: 'يس',
    verses: 83,
    themeColor: Color(0xFFEF4444),
    decorativeIcon: Icons.favorite_rounded,
    badge: 'HEART',
  ),
  _PopularSurah(
    surahNumber: 55,
    name: 'Ar-Rahman',
    nameArabic: 'الرحمن',
    verses: 78,
    themeColor: Color(0xFFF59E0B),
    decorativeIcon: Icons.brightness_5_rounded,
    badge: 'BEAUTY',
  ),
  _PopularSurah(
    surahNumber: 67,
    name: 'Al-Mulk',
    nameArabic: 'الملك',
    verses: 30,
    themeColor: Color(0xFF10B981),
    decorativeIcon: Icons.nights_stay_rounded,
    badge: 'NIGHT',
  ),
  _PopularSurah(
    surahNumber: 56,
    name: 'Al-Waqiah',
    nameArabic: 'الواقعة',
    verses: 96,
    themeColor: Color(0xFF0891B2),
    decorativeIcon: Icons.star_rounded,
    badge: 'DAILY',
  ),
];

// ============================================================
// SECTION 3 — QURAN SCREEN WIDGET
// ============================================================

class QuranScreen extends ConsumerStatefulWidget {
  const QuranScreen({super.key});

  @override
  ConsumerState<QuranScreen> createState() => _QuranScreenState();
}

// ============================================================
// SECTION 4 — STATE CLASS
// ============================================================

class _QuranScreenState extends ConsumerState<QuranScreen>
    with TickerProviderStateMixin {
  // ── ANIMATION CONTROLLERS ───────────────────────────────
  late final AnimationController _headerAnimationController;
  late final AnimationController _heroGlowController;
  late final AnimationController _cardStaggerController;

  // ── ANIMATIONS ──────────────────────────────────────────
  late final Animation<double> _headerFadeAnimation;
  late final Animation<Offset> _headerSlideAnimation;
  late final Animation<double> _heroGlowAnimation;

  // ── STATE VARIABLES ─────────────────────────────────────
  ListenPlaybackState _listenPlaybackState = ListenPlaybackState.stopped;
  int _selectedCategoryIndex = -1; // -1 = none selected

  // ── SCROLL CONTROLLER ───────────────────────────────────
  final ScrollController _scrollController = ScrollController();

  // ── CATEGORIES LIST ─────────────────────────────────────
  List<_QuranCategory> get _categories => [
        _QuranCategory(
          label: 'Juz\' Index',
          icon: Icons.list_alt_rounded,
          themeColor: AppColors.primary,
          onTap: () => _handleCategoryTap(0, 'Juz Index'),
        ),
        _QuranCategory(
          label: 'Bookmarks',
          icon: Icons.bookmark_rounded,
          themeColor: AppColors.accent,
          onTap: () => _handleCategoryTap(1, 'Bookmarks'),
        ),
        _QuranCategory(
          label: 'Last Read',
          icon: Icons.access_time_filled_rounded,
          themeColor: const Color(0xFF7C3AED),
          onTap: () => _handleCategoryTap(2, 'Last Read'),
        ),
        _QuranCategory(
          label: 'Notes',
          icon: Icons.edit_note_rounded,
          themeColor: const Color(0xFF0891B2),
          onTap: () => _handleCategoryTap(3, 'Notes'),
        ),
      ];

  // ============================================================
  // INIT STATE
  // ============================================================

  @override
  void initState() {
    super.initState();
    _initializeAnimationControllers();
    _startAnimations();
  }

  // ── INITIALIZE ANIMATION CONTROLLERS ─────────────────────
  void _initializeAnimationControllers() {
    _headerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Hero glow pulse animation (for Al-Fatihah card)
    _heroGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    )..repeat(reverse: true);

    _cardStaggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: Curves.easeOut,
      ),
    );

    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _headerAnimationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _heroGlowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _heroGlowController,
        curve: Curves.easeInOut,
      ),
    );
  }

  // ── START ANIMATIONS ─────────────────────────────────────
  void _startAnimations() {
    _headerAnimationController.forward();

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _cardStaggerController.forward();
    });
  }

  // ============================================================
  // SECTION 5 — EVENT HANDLERS
  // ============================================================

  void _handleCategoryTap(int index, String categoryName) {
    HapticFeedback.mediumImpact();
    setState(() => _selectedCategoryIndex = index);

    _showComingSoonSnackbar('$categoryName opening in Phase 8.2');

    // Reset selection after animation
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() => _selectedCategoryIndex = -1);
      }
    });
  }

  void _handleContinueReading() {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SurahReaderScreen(
          surahNumber: _featuredSurah.surahNumber,
        ),
      ),
    );
  }

  void _handleSurahTap(RecentSurahItem surah) {
    HapticFeedback.mediumImpact();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SurahReaderScreen(
          surahNumber: surah.surahNumber,
        ),
      ),
    );
  }

  void _handleReadingProgressTap() {
    HapticFeedback.lightImpact();
    _showComingSoonSnackbar('Continue reading in Phase 8.2');
  }

  void _handleShareVerse() {
    HapticFeedback.lightImpact();
    _showComingSoonSnackbar('Share coming soon');
  }

  void _toggleListenPlayback() {
    HapticFeedback.mediumImpact();
    setState(() {
      if (_listenPlaybackState == ListenPlaybackState.playing) {
        _listenPlaybackState = ListenPlaybackState.paused;
      } else {
        _listenPlaybackState = ListenPlaybackState.playing;
      }
    });
    // v7.0: Real audio playback via audio provider
    // If not already playing, start Al-Fatihah ayah 1
    final audioNotifier = ref.read(audioProvider.notifier);
    final currentState = ref.read(audioProvider);

    if (currentState.isActive) {
      // Already loaded — just toggle
      audioNotifier.togglePlayPause();
    } else {
      // Start playing Al-Fatihah, Ayah 1 (globalAyahNumber = 1)
      audioNotifier.playAyah(
        surahNumber: 1,
        ayahNumber: 1,
        globalAyahNumber: 1,
      );
    }
  }

  Future<void> _handleRefresh() async {
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    setState(() {});
  }

  // ── HELPERS ──────────────────────────────────────────────
  void _showComingSoonSnackbar(String messageText) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.hourglass_empty_rounded,
              color: AppColors.white,
              size: 18,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                messageText,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.buttonRadius,
        ),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _headerAnimationController.dispose();
    _heroGlowController.dispose();
    _cardStaggerController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ============================================================
  // SECTION 6 — BUILD METHOD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        displacement: 60,
        strokeWidth: 2.5,
        onRefresh: _handleRefresh,
        child: CustomScrollView(
          controller: _scrollController,
          physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics(),
          ),
          slivers: [
            // 1. Premium App Bar
            _buildPremiumAppBar(),

            // Content
            SliverPadding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xl6),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // 2. Al-Fatihah Hero Card (with 3D Quran)
                  const SizedBox(height: AppSpacing.lg),
                  _buildFeaturedSurahCard(),

                  // 3. Category Buttons (4 circular)
                  const SizedBox(height: AppSpacing.xl2),
                  _buildCategoryButtonsRow(),

                  // 4. Reading Progress Card
                  const SizedBox(height: AppSpacing.xl2),
                  _buildReadingProgressCard(),

                  // 5. Recently Read Surahs
                  const SizedBox(height: AppSpacing.xl2),
                  _buildSectionHeader(
                    sectionTitle: 'RECENTLY READ',
                    sectionIcon: Icons.menu_book_rounded,
                    trailingWidget: _buildSeeAllButton(
                      onTapAction: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const BookmarksScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildRecentlyReadSection(),

                  // 6. Daily Verse Section Header
                  const SizedBox(height: AppSpacing.xl2),
                  _buildSectionHeader(
                    sectionTitle: 'DAILY VERSE',
                    sectionIcon: Icons.auto_awesome_rounded,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildDailyVerseCard(),

                  // 7. Listen to Quran Card
                  const SizedBox(height: AppSpacing.xl2),
                  _buildListenToQuranCard(),

                  // 🆕 NEW: Popular Surahs Section
                  const SizedBox(height: AppSpacing.xl2),
                  _buildSectionHeader(
                    sectionTitle: 'POPULAR SURAHS',
                    sectionIcon: Icons.trending_up_rounded,
                    trailingWidget: _buildSeeAllButton(
                      onTapAction: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SurahListScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _buildPopularSurahsSection(),

                  // 🆕 NEW: Islamic Pattern Divider
                  _buildIslamicPatternDivider(label: 'JUZ QUICK ACCESS'),

                  // 🆕 NEW: Juz Quick Access
                  const SizedBox(height: AppSpacing.md),
                  _buildJuzQuickAccessSection(),

                  // 🆕 NEW: Search Suggestions Card
                  const SizedBox(height: AppSpacing.xl2),
                  _buildSearchSuggestionsCard(),

                  // 🆕 NEW: Reading Streak Card
                  const SizedBox(height: AppSpacing.xl2),
                  _buildReadingStreakCard(),

                  // 🆕 NEW: Islamic Pattern Divider
                  _buildIslamicPatternDivider(),

                  // Bottom breathing room
                  const SizedBox(height: AppSpacing.xl6),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ⏸️ PART A ENDS HERE — Line count: ~500
  // ============================================================
  // PART B will contain:
  //   - _buildPremiumAppBar (back + search + bookmark)
  //   - _buildFeaturedSurahCard (Al-Fatihah hero with 3D)
  //   - _buildCategoryButtonsRow (4 circular categories)
  //   - _buildSingleCategoryButton (one circular button)
  //   - _buildReadingProgressCard (with progress bar)
  //   - _buildSectionHeader (reusable)
  //   - _buildSeeAllButton (reusable)
  //
  // PART C will contain:
  //   - _buildRecentlyReadSection (uses AppRecentSurahList!)
  //   - _buildDailyVerseCard (mosque bg + verse)
  //   - _buildListenToQuranCard (audio + waveform)
  //   - _buildBottomInfoCard (footer info)
  //   - END of file
  // ============================================================

  // ============================================================
  // SECTION 7 — PREMIUM APP BAR
  // ============================================================

  Widget _buildPremiumAppBar() {
    return SliverAppBar(
      backgroundColor: AppColors.background,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      pinned: false,
      floating: true,
      snap: true,
      leadingWidth: 56,
      leading: Padding(
        padding: const EdgeInsets.only(left: AppSpacing.lg),
        child: FadeTransition(
          opacity: _headerFadeAnimation,
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              context.pop();
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.borderSubtle,
                  width: 1,
                ),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.iconSecondary,
                size: 16,
              ),
            ),
          ),
        ),
      ),
      title: FadeTransition(
        opacity: _headerFadeAnimation,
        child: SlideTransition(
          position: _headerSlideAnimation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Quran',
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  height: 1.0,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                'The Book of Allah',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        // Search Button
        FadeTransition(
          opacity: _headerFadeAnimation,
          child: Container(
            margin: const EdgeInsets.only(top: 8, bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderSubtle, width: 1),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.search_rounded,
                color: AppColors.iconSecondary,
                size: 20,
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const QuranSearchScreen()),
                );
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),

        // Bookmarks Button (with green tint)
        FadeTransition(
          opacity: _headerFadeAnimation,
          child: Container(
            margin: const EdgeInsets.only(top: 8, bottom: 8),
            decoration: BoxDecoration(
              gradient: AppGradients.emerald,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.30),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Icons.bookmark_rounded,
                color: AppColors.white,
                size: 20,
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const BookmarksScreen()),
                );
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 38, minHeight: 38),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.lg),
      ],
    );
  }

  // ============================================================
  // SECTION 8 — ✨ AL-FATIHAH HERO CARD (Reference Match!)
  // ============================================================

  Widget _buildFeaturedSurahCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: FadeTransition(
        opacity: _headerFadeAnimation,
        child: SlideTransition(
          position: _headerSlideAnimation,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0A1F14), // Deep dark green
                  Color(0xFF042818), // Darker
                  Color(0xFF001A0F), // Deepest
                ],
                stops: [0.0, 0.5, 1.0],
              ),
              borderRadius: AppRadius.cardRadiusLarge,
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.30),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  blurRadius: 24,
                  spreadRadius: 0,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: AppRadius.cardRadiusLarge,
              child: Stack(
                children: [
                  // ── Decorative Islamic pattern (background) ──
                  Positioned(
                    right: -30,
                    top: -30,
                    child: Icon(
                      Icons.mosque_rounded,
                      size: 180,
                      color: AppColors.primary.withValues(alpha: 0.06),
                    ),
                  ),

                  // ── Main Content Row ──
                  Row(
                    children: [
                      // ── LEFT: 3D Quran Image (with glow) ──
                      _buildQuran3DImage(),

                      const SizedBox(width: AppSpacing.lg),

                      // ── RIGHT: Surah Info ──
                      Expanded(child: _buildSurahInfo()),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── 3D Quran Image with Animated Glow ──────────────────
  Widget _buildQuran3DImage() {
    return AnimatedBuilder(
      animation: _heroGlowAnimation,
      builder: (context, child) {
        return Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                AppColors.primary
                    .withValues(alpha: 0.30 * _heroGlowAnimation.value),
                AppColors.primary
                    .withValues(alpha: 0.10 * _heroGlowAnimation.value),
                Colors.transparent,
              ],
              stops: const [0.0, 0.6, 1.0],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary
                    .withValues(alpha: 0.30 * _heroGlowAnimation.value),
                blurRadius: 24,
                spreadRadius: 4,
              ),
              BoxShadow(
                color: AppColors.accent
                    .withValues(alpha: 0.15 * _heroGlowAnimation.value),
                blurRadius: 40,
                spreadRadius: 8,
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.accent.withValues(alpha: 0.90),
                    AppColors.primary.withValues(alpha: 0.85),
                    const Color(0xFF7A5A00),
                  ],
                ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.60),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.40),
                    blurRadius: 12,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Try to load image, fallback to icon
                  Image.asset(
                    'assets/images/hero/quran_3d.png',
                    width: 60,
                    height: 60,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      // Fallback: Beautiful Quran icon
                      return const Icon(
                        Icons.menu_book_rounded,
                        color: AppColors.white,
                        size: 40,
                      );
                    },
                  ),
                  // Sparkle overlay
                  Positioned(
                    top: 8,
                    right: 12,
                    child: Icon(
                      Icons.auto_awesome,
                      size: 10,
                      color: AppColors.white
                          .withValues(alpha: 0.70 * _heroGlowAnimation.value),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Right Side: Surah Info ─────────────────────────────
  Widget _buildSurahInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Surah name (English)
        Text(
          _featuredSurah.surahName,
          style: AppTextStyles.headlineSmall.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w900,
            height: 1.1,
            letterSpacing: -0.5,
          ),
        ),

        const SizedBox(height: 2),

        // Surah name (Arabic)
        Text(
          _featuredSurah.surahNameArabic,
          style: const TextStyle(
            fontFamily: 'Amiri',
            fontSize: 20,
            color: AppColors.accent,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
          textDirection: TextDirection.rtl,
        ),

        const SizedBox(height: AppSpacing.sm),

        // Verses + Type row
        Row(
          children: [
            Icon(
              Icons.menu_book_rounded,
              color: AppColors.white.withValues(alpha: 0.60),
              size: 12,
            ),
            const SizedBox(width: 4),
            Text(
              '${_featuredSurah.versesCount} Verses',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.white.withValues(alpha: 0.75),
                fontWeight: FontWeight.w600,
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 3,
              height: 3,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.40),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              _featuredSurah.revelationType,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.accent.withValues(alpha: 0.90),
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        // Continue Reading Button
        GestureDetector(
          onTap: _handleContinueReading,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              gradient: AppGradients.emerald,
              borderRadius: AppRadius.pillRadius,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.40),
                  blurRadius: 12,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Continue Reading',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(width: 5),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.white,
                  size: 14,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SECTION 9 — ✨ CATEGORY BUTTONS ROW (4 Circular)
  // ============================================================

  Widget _buildCategoryButtonsRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_categories.length, (index) {
          final _QuranCategory category = _categories[index];
          final bool isSelected = index == _selectedCategoryIndex;
          final Duration staggerDelay =
              Duration(milliseconds: 100 + (index * 60));

          return TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 600) + staggerDelay,
            curve: Curves.easeOutBack,
            builder: (context, value, child) => Transform.scale(
              scale: value,
              child: child,
            ),
            child: _buildSingleCategoryButton(
              category: category,
              isSelected: isSelected,
            ),
          );
        }),
      ),
    );
  }

  // ── Single Category Button ─────────────────────────────
  Widget _buildSingleCategoryButton({
    required _QuranCategory category,
    required bool isSelected,
  }) {
    return SizedBox(
      width: 74,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: category.onTap,
            child: AnimatedContainer(
              duration: AppDurations.fast,
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          category.themeColor,
                          category.themeColor.withValues(alpha: 0.70),
                        ],
                      )
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          category.themeColor.withValues(alpha: 0.18),
                          category.themeColor.withValues(alpha: 0.08),
                        ],
                      ),
                shape: BoxShape.circle,
                border: Border.all(
                  color: category.themeColor
                      .withValues(alpha: isSelected ? 0.80 : 0.35),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: category.themeColor
                        .withValues(alpha: isSelected ? 0.40 : 0.15),
                    blurRadius: isSelected ? 16 : 10,
                    spreadRadius: isSelected ? 2 : 0,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                category.icon,
                color: isSelected ? AppColors.white : category.themeColor,
                size: 24,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Label
          Text(
            category.label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 10,
              height: 1.0,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION 10 — ✨ READING PROGRESS CARD (Reference Match!)
  // ============================================================

  Widget _buildReadingProgressCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: GestureDetector(
        onTap: _handleReadingProgressTap,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.cardRadiusLarge,
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.25),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.08),
                blurRadius: 16,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // ── Gold Ornament Icon (left) ──────────────
              _buildGoldOrnamentIcon(),

              const SizedBox(width: AppSpacing.md),

              // ── Content (center) ───────────────────────
              Expanded(child: _buildProgressContent()),

              // ── Percentage (right) ─────────────────────
              _buildProgressPercentage(),
            ],
          ),
        ),
      ),
    );
  }

  // ── Gold Ornament Icon ──────────────────────────────────
  Widget _buildGoldOrnamentIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent.withValues(alpha: 0.20),
            AppColors.accent.withValues(alpha: 0.08),
          ],
        ),
        shape: BoxShape.circle,
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.40),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.15),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background star
          Icon(
            Icons.star_rounded,
            color: AppColors.accent.withValues(alpha: 0.30),
            size: 40,
          ),
          // Foreground ornament
          const Icon(
            Icons.auto_awesome,
            color: AppColors.accent,
            size: 22,
          ),
        ],
      ),
    );
  }

  // ── Progress Content (labels + text + bar) ─────────────
  Widget _buildProgressContent() {
    const _ReadingProgress progress = _currentReadingProgress;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label
        Row(
          children: [
            Container(
              width: 3,
              height: 10,
              decoration: BoxDecoration(
                gradient: AppGradients.gold,
                borderRadius: AppRadius.pillRadius,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'READING PROGRESS',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.accent,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w700,
                fontSize: 9,
              ),
            ),
          ],
        ),

        const SizedBox(height: 5),

        // "You are on Juz' 2" text
        RichText(
          text: TextSpan(
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12,
              height: 1.2,
            ),
            children: [
              const TextSpan(text: 'You are on '),
              TextSpan(
                text: 'Juz\' ${progress.currentJuz}',
                style: const TextStyle(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 3),

        // Surah + Ayah
        Text(
          '${progress.currentSurah} (Ayah ${progress.currentAyah})',
          style: AppTextStyles.titleSmall.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w800,
            fontSize: 13,
            height: 1.2,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),

        const SizedBox(height: 8),

        // Progress bar
        ClipRRect(
          borderRadius: AppRadius.pillRadius,
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: progress.progressPercent),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return LinearProgressIndicator(
                value: value,
                backgroundColor: AppColors.accent.withValues(alpha: 0.15),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppColors.accent,
                ),
                minHeight: 5,
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Progress Percentage ────────────────────────────────
  Widget _buildProgressPercentage() {
    final int percentage =
        (_currentReadingProgress.progressPercent * 100).round();

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '$percentage%',
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.accent,
            fontWeight: FontWeight.w900,
            fontSize: 20,
            height: 1.0,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'complete',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textTertiary,
            fontSize: 9,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SECTION 11 — SECTION HEADER + SEE ALL BUTTON (Reusable)
  // ============================================================

  Widget _buildSectionHeader({
    required String sectionTitle,
    required IconData sectionIcon,
    Widget? trailingWidget,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              gradient: AppGradients.gold,
              borderRadius: AppRadius.pillRadius,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Icon(sectionIcon, color: AppColors.accent, size: 16),
          const SizedBox(width: AppSpacing.xs),
          Text(
            sectionTitle,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.accent,
              letterSpacing: 2.0,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (trailingWidget != null) ...[
            const Spacer(),
            trailingWidget,
          ],
        ],
      ),
    );
  }

  Widget _buildSeeAllButton({required VoidCallback onTapAction}) {
    return GestureDetector(
      onTap: onTapAction,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.10),
          borderRadius: AppRadius.pillRadius,
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.30),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'View All',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.accent,
                fontWeight: FontWeight.w700,
                fontSize: 10,
              ),
            ),
            const SizedBox(width: 3),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: AppColors.accent,
              size: 9,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // ⏸️ PART B ENDS HERE — Line count: ~1400
  // ============================================================
  // PART C will contain:
  //   - _buildRecentlyReadSection (uses AppRecentSurahList!)
  //   - _buildDailyVerseCard (mosque bg + Arabic verse)
  //   - _buildListenToQuranCard (waveform + play)
  //   - _buildBottomInfoCard (footer info)
  //   - END of file
  // ============================================================

  // ============================================================
  // SECTION 12 — ✨ RECENTLY READ SECTION (Uses Step 5 Widget!)
  // ============================================================

  Widget _buildRecentlyReadSection() {
    return AppRecentSurahList(
      surahs: _recentlyReadSurahs,
      cardSize: RecentSurahCardSize.standard,
      onSurahTap: _handleSurahTap,
    );
  }

  // ============================================================
  // SECTION 13 — ✨ DAILY VERSE CARD (Mosque Background)
  // ============================================================

  Widget _buildDailyVerseCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: AppVerseHeroCard(
        height: 200,
        onTap: () {
          HapticFeedback.lightImpact();
          _showComingSoonSnackbar('Verse details coming soon');
        },
        childPadding: const EdgeInsets.all(AppSpacing.xl2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top row: Share button
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: _handleShareVerse,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.20),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.30),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.share_outlined,
                    color: AppColors.white,
                    size: 15,
                  ),
                ),
              ),
            ),

            // Center: Arabic + Translation + Reference
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Arabic text (larger)
                Text(
                  _dailyVerse.arabicText,
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 24,
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                    height: 1.6,
                  ),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: AppSpacing.sm),

                // Divider with subtle star
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 1,
                      color: AppColors.accent.withValues(alpha: 0.50),
                    ),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                      child: Icon(
                        Icons.star_rounded,
                        color: AppColors.accent.withValues(alpha: 0.70),
                        size: 10,
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 1,
                      color: AppColors.accent.withValues(alpha: 0.50),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.sm),

                // Translation
                Text(
                  '"${_dailyVerse.translationText}"',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.white.withValues(alpha: 0.90),
                    fontStyle: FontStyle.italic,
                    fontSize: 12,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                const SizedBox(height: AppSpacing.xs),

                // Reference (gold accent)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.20),
                    borderRadius: AppRadius.pillRadius,
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.40),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.bookmark_rounded,
                        color: AppColors.accent,
                        size: 10,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '— Surah ${_dailyVerse.surahName} (${_dailyVerse.surahNumber}:${_dailyVerse.ayahNumber})',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SECTION 14 — ✨ LISTEN TO QURAN CARD (Uses Step 6 Widget!)
  // ============================================================

  Widget _buildListenToQuranCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: AppQuranListenCard(
        qariName: 'Mishary Rashid',
        playbackState: _listenPlaybackState,
        onPlayTap: _toggleListenPlayback,
        onCardTap: () {
          // v7.0: Card tap just triggers play/pause (no popup)
          HapticFeedback.lightImpact();
          _toggleListenPlayback();
        },
      ),
    );
  }

  // ============================================================
  // SECTION 15 — ✨ BOTTOM INFO CARD (Footer)
  // ============================================================

  Widget _buildBottomInfoCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.cardRadiusLarge,
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // Stats row (Surahs, Ayahs, Juz)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoStat(
                  icon: Icons.menu_book_rounded,
                  value: '114',
                  label: 'Surahs',
                  color: AppColors.primary,
                ),
                _buildDivider(),
                _buildInfoStat(
                  icon: Icons.format_list_numbered_rounded,
                  value: '6,236',
                  label: 'Ayahs',
                  color: AppColors.accent,
                ),
                _buildDivider(),
                _buildInfoStat(
                  icon: Icons.book_rounded,
                  value: '30',
                  label: 'Juz',
                  color: const Color(0xFF7C3AED),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Divider
            Container(
              height: 1,
              color: AppColors.borderSubtle,
            ),

            const SizedBox(height: AppSpacing.md),

            // Arabic tagline
            const Text(
              'كِتَابُ اللَّهِ',
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 20,
                color: AppColors.accent,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 4),

            // English tagline
            Text(
              'The Book of Allah',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Explore button
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SurahListScreen(),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.15),
                      AppColors.accent.withValues(alpha: 0.10),
                    ],
                  ),
                  borderRadius: AppRadius.buttonRadius,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.30),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.explore_rounded,
                      color: AppColors.primary,
                      size: 16,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Explore All Surahs',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Info Stat (icon + value + label) ───────────────────
  Widget _buildInfoStat({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: color.withValues(alpha: 0.30),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: color,
            size: 18,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: AppTextStyles.titleMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 16,
            height: 1.0,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 10,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  // ── Vertical divider between stats ─────────────────────
  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 40,
      color: AppColors.borderSubtle,
    );
  }

  // ============================================================
  // SECTION 16 — ✨ POPULAR SURAHS SECTION (NEW!)
  // ============================================================

  Widget _buildPopularSurahsSection() {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        physics: const BouncingScrollPhysics(),
        itemCount: _popularSurahs.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.md),
        itemBuilder: (context, index) {
          final _PopularSurah surah = _popularSurahs[index];
          return _buildPopularSurahCard(surah, index);
        },
      ),
    );
  }

  Widget _buildPopularSurahCard(_PopularSurah surah, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 500 + (index * 80)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) => Transform.scale(
        scale: value,
        child: child,
      ),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SurahReaderScreen(
                surahNumber: surah.surahNumber,
              ),
            ),
          );
        },
        child: Container(
          width: 160,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                surah.themeColor.withValues(alpha: 0.20),
                surah.themeColor.withValues(alpha: 0.08),
                AppColors.surface,
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
            borderRadius: AppRadius.cardRadiusLarge,
            border: Border.all(
              color: surah.themeColor.withValues(alpha: 0.30),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: surah.themeColor.withValues(alpha: 0.15),
                blurRadius: 12,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: AppRadius.cardRadiusLarge,
            child: Stack(
              children: [
                // Decorative icon (background)
                Positioned(
                  right: -15,
                  bottom: -15,
                  child: Icon(
                    surah.decorativeIcon,
                    size: 90,
                    color: surah.themeColor.withValues(alpha: 0.08),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Top: Badge + Surah number
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Badge
                          if (surah.badge != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: surah.themeColor.withValues(alpha: 0.25),
                                borderRadius: AppRadius.pillRadius,
                                border: Border.all(
                                  color:
                                      surah.themeColor.withValues(alpha: 0.50),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                surah.badge!,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: surah.themeColor,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 8,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            )
                          else
                            const SizedBox.shrink(),

                          // Small star badge
                          AppOrnamentalStarBadge(
                            number: surah.surahNumber,
                            size: BadgeSize.small,
                            theme: BadgeColorTheme.custom,
                            customFillColor: surah.themeColor,
                            customBorderColor: AppColors.accent,
                            showGlow: false,
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.sm),

                      // Middle: Name + Arabic
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            surah.name,
                            style: AppTextStyles.titleSmall.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w800,
                              height: 1.2,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            surah.nameArabic,
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 16,
                              color: surah.themeColor,
                              fontWeight: FontWeight.w600,
                              height: 1.2,
                            ),
                            textDirection: TextDirection.rtl,
                          ),
                        ],
                      ),

                      // Bottom: Verses + Play
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.menu_book_rounded,
                                color: AppColors.textTertiary,
                                size: 10,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                '${surah.verses}',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.textTertiary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 10,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: surah.themeColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      surah.themeColor.withValues(alpha: 0.40),
                                  blurRadius: 6,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.play_arrow_rounded,
                              color: AppColors.white,
                              size: 16,
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
      ),
    );
  }

  // ============================================================
  // SECTION 17 — ✨ JUZ QUICK ACCESS (NEW!)
  // ============================================================

  Widget _buildJuzQuickAccessSection() {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        physics: const BouncingScrollPhysics(),
        itemCount: 6, // Show first 6 juz
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final int juzNumber = index + 1;
          final bool isCurrent =
              juzNumber == _currentReadingProgress.currentJuz;
          return _buildJuzMiniCard(juzNumber, isCurrent);
        },
      ),
    );
  }

  Widget _buildJuzMiniCard(int juzNumber, bool isCurrent) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const SurahListScreen(),
          ),
        );
      },
      child: AnimatedContainer(
        duration: AppDurations.fast,
        width: 80,
        decoration: BoxDecoration(
          gradient: isCurrent
              ? AppGradients.emerald
              : const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.surface,
                    AppColors.surfaceElevated,
                  ],
                ),
          borderRadius: AppRadius.cardRadius,
          border: Border.all(
            color: isCurrent
                ? Colors.transparent
                : AppColors.accent.withValues(alpha: 0.25),
            width: 1,
          ),
          boxShadow: isCurrent
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.30),
                    blurRadius: 10,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'JUZ',
                style: AppTextStyles.labelSmall.copyWith(
                  color: isCurrent
                      ? AppColors.white.withValues(alpha: 0.80)
                      : AppColors.textTertiary,
                  fontWeight: FontWeight.w700,
                  fontSize: 8,
                  letterSpacing: 1.5,
                ),
              ),
              Text(
                '$juzNumber',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: isCurrent ? AppColors.white : AppColors.accent,
                  fontWeight: FontWeight.w900,
                  fontSize: 24,
                  height: 1.0,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                _getJuzArabicName(juzNumber),
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 10,
                  color: isCurrent
                      ? AppColors.white.withValues(alpha: 0.85)
                      : AppColors.accent.withValues(alpha: 0.80),
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                ),
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper: Get Juz Arabic name
  String _getJuzArabicName(int juzNumber) {
    const List<String> juzNames = [
      'الم', // 1
      'سيقول', // 2
      'تلك الرسل', // 3
      'لن تنالوا', // 4
      'والمحصنات', // 5
      'لا يحب الله', // 6
    ];
    if (juzNumber <= juzNames.length) {
      return juzNames[juzNumber - 1];
    }
    return 'جزء $juzNumber';
  }

  // ============================================================
  // SECTION 18 — ✨ SEARCH SUGGESTIONS CARD (NEW!)
  // ============================================================

  Widget _buildSearchSuggestionsCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.cardRadiusLarge,
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.20),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: AppGradients.emerald,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.30),
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.search_rounded,
                    color: AppColors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Quick Search',
                        style: AppTextStyles.titleSmall.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Popular searches',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                // Voice search button
                GestureDetector(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    _showComingSoonSnackbar('Voice search coming in Phase 8.3');
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.mic_rounded,
                      color: AppColors.accent,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Suggestion chips
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _buildSearchChip('Ayat-ul-Kursi', Icons.star_rounded),
                _buildSearchChip('Al-Fatihah', Icons.book_rounded),
                _buildSearchChip('Ya-Sin', Icons.auto_awesome_rounded),
                _buildSearchChip('99 Names', Icons.language_rounded),
                _buildSearchChip('Duas', Icons.volunteer_activism_rounded),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchChip(String label, IconData icon) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _showComingSoonSnackbar('Searching "$label"...');
      },
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.10),
          borderRadius: AppRadius.pillRadius,
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary, size: 12),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SECTION 19 — ✨ READING STREAK CARD (NEW!)
  // ============================================================

  Widget _buildReadingStreakCard() {
    const int streakDays = 7;
    const int weeklyGoal = 7;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFEF4444),
              Color(0xFFDC2626),
              Color(0xFFB91C1C),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
          borderRadius: AppRadius.cardRadiusLarge,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEF4444).withValues(alpha: 0.30),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: AppRadius.cardRadiusLarge,
          child: Stack(
            children: [
              // Decorative fire
              Positioned(
                right: -20,
                bottom: -20,
                child: Icon(
                  Icons.local_fire_department_rounded,
                  size: 140,
                  color: AppColors.white.withValues(alpha: 0.10),
                ),
              ),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: 0.20),
                          borderRadius: AppRadius.buttonRadius,
                        ),
                        child: const Icon(
                          Icons.local_fire_department_rounded,
                          color: AppColors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'READING STREAK',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.white.withValues(alpha: 0.90),
                          letterSpacing: 2.0,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Streak count
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$streakDays',
                        style: AppTextStyles.displayLarge.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w900,
                          height: 1.0,
                          fontSize: 48,
                          letterSpacing: -2.0,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          'days',
                          style: AppTextStyles.titleLarge.copyWith(
                            color: AppColors.white.withValues(alpha: 0.80),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Text(
                    'MashaAllah! Keep it up! 🔥',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.white.withValues(alpha: 0.90),
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Weekly progress dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (index) {
                      final bool completed = index < streakDays;
                      final List<String> days = [
                        'S',
                        'M',
                        'T',
                        'W',
                        'T',
                        'F',
                        'S'
                      ];

                      return Column(
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: completed
                                  ? AppColors.white
                                  : AppColors.white.withValues(alpha: 0.20),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.white.withValues(alpha: 0.30),
                                width: 1,
                              ),
                            ),
                            child: completed
                                ? const Icon(
                                    Icons.check_rounded,
                                    color: Color(0xFFEF4444),
                                    size: 16,
                                  )
                                : null,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            days[index],
                            style: AppTextStyles.labelSmall.copyWith(
                              color: AppColors.white.withValues(alpha: 0.80),
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      );
                    }),
                  ),

                  const SizedBox(height: AppSpacing.sm),

                  // Progress bar
                  ClipRRect(
                    borderRadius: AppRadius.pillRadius,
                    child: LinearProgressIndicator(
                      value: streakDays / weeklyGoal,
                      backgroundColor: AppColors.white.withValues(alpha: 0.20),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(AppColors.white),
                      minHeight: 4,
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

  // ============================================================
  // SECTION 20 — ✨ ISLAMIC PATTERN DIVIDER (NEW WIDGET!)
  // ============================================================

  Widget _buildIslamicPatternDivider({String? label}) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          // Left decorative line
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    AppColors.accent.withValues(alpha: 0.40),
                  ],
                ),
              ),
            ),
          ),

          // Center ornament
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.star_rounded,
                  color: AppColors.accent.withValues(alpha: 0.40),
                  size: 10,
                ),
                if (label != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    label,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 10,
                      letterSpacing: 2.0,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ] else
                  const SizedBox(width: AppSpacing.xs),
                Icon(
                  Icons.auto_awesome,
                  color: AppColors.accent.withValues(alpha: 0.60),
                  size: 12,
                ),
                if (label == null) const SizedBox(width: AppSpacing.xs),
                if (label == null)
                  Icon(
                    Icons.star_rounded,
                    color: AppColors.accent.withValues(alpha: 0.40),
                    size: 10,
                  ),
              ],
            ),
          ),

          // Right decorative line
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.accent.withValues(alpha: 0.40),
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
} // ← END of _QuranScreenState

// ============================================================
// END OF FILE — quran_screen.dart (Premium v1.0)
// ============================================================
