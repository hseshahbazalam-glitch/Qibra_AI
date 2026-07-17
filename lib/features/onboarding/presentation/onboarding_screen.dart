// lib/features/onboarding/presentation/onboarding_screen.dart

// ============================================================
// QIBRA AI — PREMIUM ONBOARDING SCREEN (Phase 2)
// Version: 2.0.0
// Description: Apple-quality onboarding with glassmorphism,
//              animated illustrations, and premium UX.
// ============================================================

import 'dart:math' as math;
import 'dart:ui';

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
// ONBOARDING SLIDE DATA MODEL
// ============================================================

class _OnboardingSlide {
  final String title;
  final String description;
  final IconData icon;
  final String arabicText;
  final String arabicTranslation;
  final Color primaryColor;
  final Color secondaryColor;
  final List<Color> backgroundGradient;

  const _OnboardingSlide({
    required this.title,
    required this.description,
    required this.icon,
    required this.arabicText,
    required this.arabicTranslation,
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundGradient,
  });
}

// ============================================================
// 4 PREMIUM SLIDES DATA
// ============================================================

const List<_OnboardingSlide> _slides = [
  _OnboardingSlide(
    title: 'Read the Holy Quran',
    description:
        'Access the complete Quran with beautiful Arabic text, audio recitations by renowned Qaris, and translations in multiple languages.',
    icon: Icons.menu_book_rounded,
    arabicText: 'اقْرَأْ',
    arabicTranslation: 'Read',
    primaryColor: AppColors.primary,
    secondaryColor: AppColors.primaryLight,
    backgroundGradient: [
      Color(0xFF0A1628),
      Color(0xFF0D2E1A),
      Color(0xFF050D14),
    ],
  ),
  _OnboardingSlide(
    title: 'Never Miss a Prayer',
    description:
        'Get accurate prayer times based on your location, Qibla direction compass, and beautiful Adhan notifications for all five daily prayers.',
    icon: Icons.access_time_filled_rounded,
    arabicText: 'الصَّلَاة',
    arabicTranslation: 'Prayer',
    primaryColor: AppColors.accent,
    secondaryColor: AppColors.accentBright,
    backgroundGradient: [
      Color(0xFF0A1628),
      Color(0xFF2D2410),
      Color(0xFF050D14),
    ],
  ),
  _OnboardingSlide(
    title: 'Islamic AI Assistant',
    description:
        'Ask any Islamic question and get instant, authentic answers from our AI trained on Quran, Hadith, and scholarly texts.',
    icon: Icons.smart_toy_rounded,
    arabicText: 'الْحِكْمَة',
    arabicTranslation: 'Wisdom',
    primaryColor: Color(0xFF7C3AED),
    secondaryColor: Color(0xFF8B5CF6),
    backgroundGradient: [
      Color(0xFF0A1628),
      Color(0xFF1F1B3D),
      Color(0xFF050D14),
    ],
  ),
  _OnboardingSlide(
    title: 'Your Islamic Companion',
    description:
        'Duas, Tasbih counter, Hijri calendar, nearby mosques, and much more — everything you need for your spiritual journey.',
    icon: Icons.mosque_rounded,
    arabicText: 'بِسْمِ اللَّه',
    arabicTranslation: 'In the name of Allah',
    primaryColor: AppColors.accent,
    secondaryColor: AppColors.primary,
    backgroundGradient: [
      Color(0xFF0A1628),
      Color(0xFF1A3D2A),
      Color(0xFF050D14),
    ],
  ),
];

// ============================================================
// PREMIUM ONBOARDING SCREEN
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
  double _pageOffset = 0.0;

  // ── ICON ANIMATION ───────────────────────────────────
  late AnimationController _iconController;
  late Animation<double> _iconScale;
  late Animation<double> _iconRotation;

  // ── PARTICLE ANIMATION ───────────────────────────────
  late AnimationController _particleController;

  // ── CONTENT ANIMATION ────────────────────────────────
  late AnimationController _contentController;
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;

  @override
  void initState() {
    super.initState();

    _pageController = PageController();

    // Listen to page offset for parallax
    _pageController.addListener(() {
      setState(() {
        _pageOffset = _pageController.page ?? 0;
      });
    });

    // Icon animation
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _iconScale = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: Curves.elasticOut,
    ));

    _iconRotation = Tween<double>(
      begin: -0.2,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: Curves.easeOutCubic,
    ));

    // Particle background
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();

    // Content animation
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _contentFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeIn,
    ));

    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOutCubic,
    ));

    // Start animations
    _iconController.forward();
    _contentController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _iconController.dispose();
    _particleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  // ── PAGE CHANGE ──────────────────────────────────────
  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    HapticFeedback.mediumImpact();

    // Restart animations for new page
    _iconController.reset();
    _iconController.forward();
    _contentController.reset();
    _contentController.forward();
  }

  // ── NEXT ─────────────────────────────────────────────
  Future<void> _handleNext() async {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    } else {
      await _completeOnboarding();
    }
  }

  // ── SKIP ─────────────────────────────────────────────
  Future<void> _handleSkip() async {
    HapticFeedback.selectionClick();
    await _completeOnboarding();
  }

  // ── PREVIOUS ─────────────────────────────────────────
  void _handlePrevious() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    }
  }

  // ── COMPLETE ─────────────────────────────────────────
  Future<void> _completeOnboarding() async {
    await ref.read(onboardingProvider.notifier).markComplete();
    if (mounted) {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentSlide = _slides[_currentPage];
    final isLastPage = _currentPage == _slides.length - 1;
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: Stack(
        children: [
          // ── LAYER 1: Animated background gradient ──
          AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: currentSlide.backgroundGradient,
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),

          // ── LAYER 2: Floating particles ──
          _buildParticleBackground(size, currentSlide),

          // ── LAYER 3: Content ──
          SafeArea(
            child: Column(
              children: [
                // Top bar
                _buildTopBar(),

                // Page view
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: _onPageChanged,
                    itemCount: _slides.length,
                    itemBuilder: (context, index) {
                      return _buildSlide(_slides[index], index);
                    },
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                // Page indicators
                _buildPageIndicators(),

                const SizedBox(height: AppSpacing.xl2),

                // Bottom buttons
                _buildBottomButtons(isLastPage, currentSlide),

                const SizedBox(height: AppSpacing.xl2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // PARTICLE BACKGROUND
  // ══════════════════════════════════════════

  Widget _buildParticleBackground(Size size, _OnboardingSlide slide) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _particleController,
        builder: (context, child) {
          return CustomPaint(
            painter: _OnboardingParticlePainter(
              animationValue: _particleController.value,
              primaryColor: slide.primaryColor,
              secondaryColor: slide.secondaryColor,
            ),
            size: size,
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════
  // TOP BAR — Logo + Skip
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
          // Logo + App name
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: AppGradients.gold,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.40),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.mosque_rounded,
                  color: AppColors.background,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppGradients.gold.createShader(bounds),
                child: Text(
                  AppInfo.appName,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),

          // Skip button — glassmorphism
          _buildGlassButton(
            label: 'Skip',
            onTap: _handleSkip,
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // GLASS BUTTON (Reusable)
  // ══════════════════════════════════════════

  Widget _buildGlassButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: AppRadius.pillRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: AppRadius.pillRadius,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.20),
                width: 1,
              ),
            ),
            child: Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // SINGLE SLIDE
  // ══════════════════════════════════════════

  Widget _buildSlide(_OnboardingSlide slide, int index) {
    // Parallax calculation
    final delta = (_pageOffset - index).clamp(-1.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl2,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated illustration
          Transform.translate(
            offset: Offset(delta * -50, 0),
            child: _buildIllustration(slide),
          ),

          const SizedBox(height: AppSpacing.xl4),

          // Content in glass card
          Transform.translate(
            offset: Offset(delta * -30, 0),
            child: _buildContentCard(slide),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // ILLUSTRATION
  // ══════════════════════════════════════════

  Widget _buildIllustration(_OnboardingSlide slide) {
    return AnimatedBuilder(
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
      child: Container(
        width: 200,
        height: 200,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              slide.primaryColor.withValues(alpha: 0.30),
              slide.primaryColor.withValues(alpha: 0.05),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: slide.primaryColor.withValues(alpha: 0.40),
              blurRadius: 60,
              spreadRadius: 10,
            ),
            BoxShadow(
              color: slide.primaryColor.withValues(alpha: 0.20),
              blurRadius: 120,
              spreadRadius: 20,
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer ring
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: slide.primaryColor.withValues(alpha: 0.30),
                  width: 1,
                ),
              ),
            ),

            // Middle ring
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: slide.primaryColor.withValues(alpha: 0.50),
                  width: 1.5,
                ),
              ),
            ),

            // Icon container with glassmorphism
            ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        slide.primaryColor.withValues(alpha: 0.30),
                        slide.primaryColor.withValues(alpha: 0.10),
                      ],
                    ),
                    border: Border.all(
                      color: slide.primaryColor,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          slide.primaryColor,
                          slide.secondaryColor,
                        ],
                      ).createShader(bounds),
                      child: Icon(
                        slide.icon,
                        size: 56,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // CONTENT CARD (Glassmorphism)
  // ══════════════════════════════════════════

  Widget _buildContentCard(_OnboardingSlide slide) {
    return SlideTransition(
      position: _contentSlide,
      child: FadeTransition(
        opacity: _contentFade,
        child: ClipRRect(
          borderRadius: AppRadius.cardRadiusLarge,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.xl2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.10),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                ),
                borderRadius: AppRadius.cardRadiusLarge,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  // Arabic badge
                  _buildArabicBadge(slide),

                  const SizedBox(height: AppSpacing.lg),

                  // Title
                  Text(
                    slide.title,
                    style: AppTextStyles.headlineSmall.copyWith(
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Description
                  Text(
                    slide.description,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // ARABIC BADGE
  // ══════════════════════════════════════════

  Widget _buildArabicBadge(_OnboardingSlide slide) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            slide.primaryColor.withValues(alpha: 0.20),
            slide.secondaryColor.withValues(alpha: 0.15),
          ],
        ),
        borderRadius: AppRadius.pillRadius,
        border: Border.all(
          color: slide.primaryColor.withValues(alpha: 0.40),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            slide.arabicText,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: slide.primaryColor,
              height: 1.0,
            ),
            textDirection: TextDirection.rtl,
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            width: 3,
            height: 3,
            decoration: BoxDecoration(
              color: slide.primaryColor.withValues(alpha: 0.50),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            slide.arabicTranslation,
            style: AppTextStyles.labelSmall.copyWith(
              color: slide.primaryColor,
              letterSpacing: 1.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // PAGE INDICATORS (Premium)
  // ══════════════════════════════════════════

  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_slides.length, (index) {
        final isActive = index == _currentPage;
        final slide = _slides[_currentPage];

        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: isActive ? 32 : 8,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: AppRadius.pillRadius,
            gradient: isActive
                ? LinearGradient(
                    colors: [
                      slide.primaryColor,
                      slide.secondaryColor,
                    ],
                  )
                : null,
            color: isActive ? null : Colors.white.withValues(alpha: 0.20),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: slide.primaryColor.withValues(alpha: 0.60),
                      blurRadius: 12,
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

  Widget _buildBottomButtons(
    bool isLastPage,
    _OnboardingSlide slide,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl2,
      ),
      child: Row(
        children: [
          // Previous button (only when not first)
          if (_currentPage > 0) ...[
            _buildIconButton(
              icon: Icons.arrow_back_rounded,
              onTap: _handlePrevious,
            ),
            const SizedBox(width: AppSpacing.md),
          ],

          // Main action button
          Expanded(
            child: isLastPage
                ? AppGoldButton(
                    label: 'Get Started',
                    suffixIcon: Icons.arrow_forward_rounded,
                    onPressed: _handleNext,
                  )
                : _buildNextButton(slide),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // NEXT BUTTON (Premium)
  // ══════════════════════════════════════════

  Widget _buildNextButton(_OnboardingSlide slide) {
    return GestureDetector(
      onTap: _handleNext,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              slide.primaryColor,
              slide.secondaryColor,
            ],
          ),
          borderRadius: AppRadius.buttonRadiusLg,
          boxShadow: [
            BoxShadow(
              color: slide.primaryColor.withValues(alpha: 0.50),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Continue',
              style: AppTextStyles.buttonLarge.copyWith(
                color: Colors.white,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // ICON BUTTON (Glass)
  // ══════════════════════════════════════════

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.10),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.20),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: AppColors.textPrimary,
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// ONBOARDING PARTICLE PAINTER
// ============================================================

class _OnboardingParticlePainter extends CustomPainter {
  final double animationValue;
  final Color primaryColor;
  final Color secondaryColor;

  _OnboardingParticlePainter({
    required this.animationValue,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);

    // Draw 25 floating particles
    for (int i = 0; i < 25; i++) {
      final baseX = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;

      // Floating motion
      final offset = math.sin(
        (animationValue * 2 * math.pi) + i,
      );

      final x = baseX + (offset * 25);
      final y = baseY + (offset * 35);

      final particleSize = 1.5 + random.nextDouble() * 2.5;
      final isSecondary = i % 3 == 0;
      final color = isSecondary ? secondaryColor : primaryColor;
      final alpha = 0.20 + (random.nextDouble() * 0.30);

      final paint = Paint()
        ..color = color.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), particleSize, paint);

      // Glow
      final glowPaint = Paint()
        ..color = color.withValues(alpha: alpha * 0.3)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawCircle(
        Offset(x, y),
        particleSize * 3,
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant _OnboardingParticlePainter oldDelegate,
  ) =>
      oldDelegate.animationValue != animationValue ||
      oldDelegate.primaryColor != primaryColor;
}
