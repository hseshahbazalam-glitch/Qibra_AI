// lib/features/onboarding/presentation/onboarding_screen.dart

// ============================================================
// QIBRA AI — ONBOARDING SCREEN
// Version: 1.0.0
// Description: Premium 4-slide onboarding experience.
//              Introduces app features with animations.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qibra_ai/core/constants/app_constants.dart';
import 'package:qibra_ai/core/design_system/app_colors.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';
import 'package:qibra_ai/core/providers/theme_provider.dart';
import 'package:qibra_ai/shared/widgets/buttons/app_button.dart';

// ============================================================
// ONBOARDING DATA MODEL
// ============================================================

class _OnboardingSlide {
  final String title;
  final String description;
  final IconData icon;
  final String arabicText;
  final String arabicTranslation;
  final Color accentColor;
  final List<Color> gradientColors;

  const _OnboardingSlide({
    required this.title,
    required this.description,
    required this.icon,
    required this.arabicText,
    required this.arabicTranslation,
    required this.accentColor,
    required this.gradientColors,
  });
}

// ============================================================
// ONBOARDING SLIDES DATA
// ============================================================

const List<_OnboardingSlide> _slides = [
  // Slide 1 — Quran
  _OnboardingSlide(
    title: 'Read the Holy Quran',
    description:
        'Complete Quran with beautiful Arabic text, audio recitation, and translations in multiple languages.',
    icon: Icons.menu_book_rounded,
    arabicText: 'اقْرَأْ',
    arabicTranslation: 'Read',
    accentColor: AppColors.primary,
    gradientColors: [
      Color(0xFF0A1628),
      Color(0xFF0D2E1A),
      Color(0xFF050D14),
    ],
  ),

  // Slide 2 — Prayer
  _OnboardingSlide(
    title: 'Accurate Prayer Times',
    description:
        'Never miss a prayer with precise timing based on your location, plus Qibla direction and Adhan alerts.',
    icon: Icons.access_time_filled_rounded,
    arabicText: 'الصَّلَاة',
    arabicTranslation: 'Prayer',
    accentColor: AppColors.accent,
    gradientColors: [
      Color(0xFF0A1628),
      Color(0xFF2D2410),
      Color(0xFF050D14),
    ],
  ),

  // Slide 3 — Hadith & AI
  _OnboardingSlide(
    title: 'Islamic Wisdom & AI',
    description:
        'Access authentic Hadiths and get instant answers to your Islamic questions from our AI assistant.',
    icon: Icons.smart_toy_rounded,
    arabicText: 'الْحِكْمَة',
    arabicTranslation: 'Wisdom',
    accentColor: AppColors.primary,
    gradientColors: [
      Color(0xFF0A1628),
      Color(0xFF1A2942),
      Color(0xFF050D14),
    ],
  ),

  // Slide 4 — Get Started
  _OnboardingSlide(
    title: 'Your Islamic Companion',
    description:
        'Duas, Tasbih, Hijri Calendar, and much more — everything you need in one beautiful app.',
    icon: Icons.mosque_rounded,
    arabicText: 'بِسْمِ اللَّه',
    arabicTranslation: 'In the name of Allah',
    accentColor: AppColors.accent,
    gradientColors: [
      Color(0xFF0A1628),
      Color(0xFF2D2410),
      Color(0xFF050D14),
    ],
  ),
];

// ============================================================
// ONBOARDING SCREEN WIDGET
// ============================================================

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with TickerProviderStateMixin {
  // ── PAGE CONTROLLER ──────────────────────────────────
  late PageController _pageController;
  int _currentPage = 0;

  // ── ICON ANIMATION ───────────────────────────────────
  late AnimationController _iconController;
  late Animation<double> _iconRotation;
  late Animation<double> _iconScale;

  @override
  void initState() {
    super.initState();

    _pageController = PageController();

    // Icon animation — rotation + scale
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _iconRotation = Tween<double>(
      begin: -0.1,
      end: 0.0,
    ).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: Curves.easeOutBack,
      ),
    );

    _iconScale = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: Curves.easeOutBack,
      ),
    );

    // Pehli slide ka icon animate karo
    _iconController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  // ── PAGE CHANGE HANDLER ──────────────────────────────
  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    HapticFeedback.selectionClick();

    // Har page change pe icon animation restart karo
    _iconController.reset();
    _iconController.forward();
  }

  // ── NEXT BUTTON HANDLER ──────────────────────────────
  Future<void> _handleNext() async {
    if (_currentPage < _slides.length - 1) {
      // Next slide pe jaao
      _pageController.nextPage(
        duration: AppDurations.medium,
        curve: Curves.easeInOut,
      );
    } else {
      // Last slide — onboarding complete karo
      await _completeOnboarding();
    }
  }

  // ── SKIP HANDLER ─────────────────────────────────────
  Future<void> _handleSkip() async {
    HapticFeedback.selectionClick();
    await _completeOnboarding();
  }

  // ── COMPLETE ONBOARDING ──────────────────────────────
  Future<void> _completeOnboarding() async {
    // Provider mein mark complete karo
    await ref.read(onboardingProvider.notifier).markComplete();

    // Navigate to login
    if (mounted) {
      context.go(AppRoutes.login);
    }
  }

  // ── PREVIOUS BUTTON ──────────────────────────────────
  void _handlePrevious() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: AppDurations.medium,
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentSlide = _slides[_currentPage];
    final isLastPage = _currentPage == _slides.length - 1;

    return Scaffold(
      body: AnimatedContainer(
        duration: AppDurations.slow,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: currentSlide.gradientColors,
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── TOP BAR: Skip button ─────────────────
              _buildTopBar(),

              // ── PAGE VIEW ────────────────────────────
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    return _buildSlide(_slides[index]);
                  },
                ),
              ),

              // ── PAGE INDICATORS ──────────────────────
              _buildPageIndicators(),

              const SizedBox(height: AppSpacing.xl2),

              // ── BOTTOM BUTTONS ───────────────────────
              _buildBottomButtons(isLastPage),

              const SizedBox(height: AppSpacing.xl2),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // TOP BAR — Logo + Skip Button
  // ══════════════════════════════════════════

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // App name
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  gradient: AppGradients.gold,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mosque,
                  color: AppColors.background,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                AppInfo.appName,
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.accent,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),

          // Skip button
          AppTextBtn(
            label: 'Skip',
            onPressed: _handleSkip,
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // SINGLE SLIDE
  // ══════════════════════════════════════════

  Widget _buildSlide(_OnboardingSlide slide) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl2,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon with animation
          AnimatedBuilder(
            animation: _iconController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _iconRotation.value,
                child: Transform.scale(
                  scale: _iconScale.value,
                  child: child,
                ),
              );
            },
            child: _buildIconContainer(slide),
          ),

          const SizedBox(height: AppSpacing.xl4),

          // Arabic text badge
          _buildArabicBadge(slide),

          const SizedBox(height: AppSpacing.xl2),

          // Title
          Text(
            slide.title,
            style: AppTextStyles.headlineMedium.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: AppSpacing.lg),

          // Description
          Text(
            slide.description,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // ICON CONTAINER
  // ══════════════════════════════════════════

  Widget _buildIconContainer(_OnboardingSlide slide) {
    return Container(
      width: 180,
      height: 180,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        // Gradient background
        gradient: RadialGradient(
          colors: [
            slide.accentColor.withValues(alpha: 0.20),
            slide.accentColor.withValues(alpha: 0.05),
          ],
        ),
        // Outer glow
        boxShadow: [
          BoxShadow(
            color: slide.accentColor.withValues(alpha: 0.30),
            blurRadius: 40,
            spreadRadius: 8,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer ring
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: slide.accentColor.withValues(alpha: 0.30),
                width: 1,
              ),
            ),
          ),

          // Inner ring
          Container(
            width: 130,
            height: 130,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: slide.accentColor.withValues(alpha: 0.50),
                width: 1.5,
              ),
            ),
          ),

          // Icon container
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.surface,
              border: Border.all(
                color: slide.accentColor,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: slide.accentColor.withValues(alpha: 0.40),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              slide.icon,
              size: 48,
              color: slide.accentColor,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // ARABIC BADGE
  // ══════════════════════════════════════════

  Widget _buildArabicBadge(_OnboardingSlide slide) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: slide.accentColor.withValues(alpha: 0.10),
        borderRadius: AppRadius.pillRadius,
        border: Border.all(
          color: slide.accentColor.withValues(alpha: 0.30),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Arabic text
          Text(
            slide.arabicText,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: slide.accentColor,
              height: 1.0,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(width: AppSpacing.sm),
          // Divider dot
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: slide.accentColor.withValues(alpha: 0.50),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // English translation
          Text(
            slide.arabicTranslation,
            style: AppTextStyles.labelSmall.copyWith(
              color: slide.accentColor,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // PAGE INDICATORS
  // ══════════════════════════════════════════

  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_slides.length, (index) {
        final isActive = index == _currentPage;
        final slide = _slides[_currentPage];

        return AnimatedContainer(
          duration: AppDurations.normal,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          // Active indicator wider, inactive smaller
          width: isActive ? 28 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: AppRadius.pillRadius,
            gradient: isActive
                ? LinearGradient(
                    colors: [
                      slide.accentColor,
                      slide.accentColor.withValues(alpha: 0.70),
                    ],
                  )
                : null,
            color: isActive
                ? null
                : AppColors.textSecondary.withValues(alpha: 0.30),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: slide.accentColor.withValues(alpha: 0.50),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }

  // ══════════════════════════════════════════
  // BOTTOM BUTTONS
  // ══════════════════════════════════════════

  Widget _buildBottomButtons(bool isLastPage) {
    final currentSlide = _slides[_currentPage];

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl2,
      ),
      child: Row(
        children: [
          // Previous button (sirf jab pehla page na ho)
          if (_currentPage > 0) ...[
            AppIconBtn(
              icon: Icons.arrow_back,
              onPressed: _handlePrevious,
              backgroundColor: AppColors.surface,
              isOutlined: true,
            ),
            const SizedBox(width: AppSpacing.md),
          ],

          // Main action button (Next / Get Started)
          Expanded(
            child: _buildActionButton(isLastPage, currentSlide),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // ACTION BUTTON (Next / Get Started)
  // ══════════════════════════════════════════

  Widget _buildActionButton(
    bool isLastPage,
    _OnboardingSlide slide,
  ) {
    // Last page pe gold button (Get Started)
    if (isLastPage) {
      return AppGoldButton(
        label: 'Get Started',
        suffixIcon: Icons.arrow_forward_rounded,
        onPressed: _handleNext,
      );
    }

    // Regular next button
    return AppPrimaryButton(
      label: 'Next',
      suffixIcon: Icons.arrow_forward_rounded,
      onPressed: _handleNext,
    );
  }
}
