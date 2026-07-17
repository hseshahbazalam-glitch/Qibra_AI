// lib/features/onboarding/presentation/onboarding_v3_screen.dart

// ============================================================
// QIBRA AI — PREMIUM ONBOARDING V3 (Cinematic)
// Version: 2.0.0
// Description: Full-screen cinematic onboarding with
//              video/lottie animations, minimal text.
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

// ============================================================
// CINEMATIC SLIDE DATA
// ============================================================

class _CinematicSlide {
  final String title;
  final String subtitle;
  final String arabicText;
  final IconData centerIcon;
  final Color primaryColor;
  final Color secondaryColor;
  final List<Color> backgroundGradient;

  const _CinematicSlide({
    required this.title,
    required this.subtitle,
    required this.arabicText,
    required this.centerIcon,
    required this.primaryColor,
    required this.secondaryColor,
    required this.backgroundGradient,
  });
}

const List<_CinematicSlide> _slides = [
  _CinematicSlide(
    title: 'Read',
    subtitle: 'The Sacred Words of Allah',
    arabicText: 'اقْرَأْ',
    centerIcon: Icons.menu_book_rounded,
    primaryColor: AppColors.primary,
    secondaryColor: Color(0xFF00CF82),
    backgroundGradient: [
      Color(0xFF001F0F),
      Color(0xFF0A3D24),
      Color(0xFF002E1A),
    ],
  ),
  _CinematicSlide(
    title: 'Pray',
    subtitle: 'Connect with the Divine',
    arabicText: 'صَلِّ',
    centerIcon: Icons.mosque_rounded,
    primaryColor: AppColors.accent,
    secondaryColor: Color(0xFFFFD700),
    backgroundGradient: [
      Color(0xFF2D2410),
      Color(0xFF3D3416),
      Color(0xFF1F1808),
    ],
  ),
  _CinematicSlide(
    title: 'Learn',
    subtitle: 'Grow in Knowledge & Faith',
    arabicText: 'تَعَلَّمْ',
    centerIcon: Icons.auto_stories_rounded,
    primaryColor: Color(0xFF7C3AED),
    secondaryColor: Color(0xFFA78BFA),
    backgroundGradient: [
      Color(0xFF1E1035),
      Color(0xFF2D1B4E),
      Color(0xFF15092A),
    ],
  ),
  _CinematicSlide(
    title: 'Belong',
    subtitle: 'Your Islamic Community Awaits',
    arabicText: 'انْتَمِ',
    centerIcon: Icons.diversity_3_rounded,
    primaryColor: Color(0xFF3B82F6),
    secondaryColor: Color(0xFF60A5FA),
    backgroundGradient: [
      Color(0xFF0A1F35),
      Color(0xFF122B47),
      Color(0xFF05132D),
    ],
  ),
];

// ============================================================
// ONBOARDING V3 SCREEN
// ============================================================

class OnboardingV3Screen extends ConsumerStatefulWidget {
  const OnboardingV3Screen({super.key});

  @override
  ConsumerState<OnboardingV3Screen> createState() => _OnboardingV3ScreenState();
}

class _OnboardingV3ScreenState extends ConsumerState<OnboardingV3Screen>
    with TickerProviderStateMixin {
  // ── PAGE CONTROLLER ──────────────────────────────────
  late PageController _pageController;
  int _currentPage = 0;
  double _pageOffset = 0.0;

  // ── PARTICLE ANIMATION ───────────────────────────────
  late AnimationController _particleController;

  // ── ICON PULSE ANIMATION ─────────────────────────────
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // ── RING ROTATION ────────────────────────────────────
  late AnimationController _ringController;

  // ── CONTENT REVEAL ───────────────────────────────────
  late AnimationController _contentController;
  late Animation<double> _titleFade;
  late Animation<Offset> _titleSlide;
  late Animation<double> _subtitleFade;

  // ── PROGRESS BAR ─────────────────────────────────────
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();

    _pageController = PageController();

    _pageController.addListener(() {
      setState(() {
        _pageOffset = _pageController.page ?? 0;
      });
    });

    // Particles
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // Pulse
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // Ring rotation
    _ringController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    // Content animations
    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _titleFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    _titleSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    ));

    _subtitleFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
    ));

    // Progress bar
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );

    _startAutoAdvance();
    _contentController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _particleController.dispose();
    _pulseController.dispose();
    _ringController.dispose();
    _contentController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  // ── AUTO ADVANCE ─────────────────────────────────────
  void _startAutoAdvance() {
    _progressController.forward(from: 0).then((_) {
      if (mounted && _currentPage < _slides.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  // ── PAGE CHANGE ──────────────────────────────────────
  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    HapticFeedback.mediumImpact();

    _contentController.reset();
    _contentController.forward();

    _progressController.reset();
    _startAutoAdvance();
  }

  // ── HANDLERS ─────────────────────────────────────────

  Future<void> _handleGetStarted() async {
    HapticFeedback.heavyImpact();
    await ref.read(onboardingProvider.notifier).markComplete();
    if (mounted) {
      context.go(AppRoutes.login);
    }
  }

  Future<void> _handleSkip() async {
    HapticFeedback.selectionClick();
    await ref.read(onboardingProvider.notifier).markComplete();
    if (mounted) {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final currentSlide = _slides[_currentPage];
    final isLastPage = _currentPage == _slides.length - 1;

    return Scaffold(
      body: Stack(
        children: [
          // ── LAYER 1: Animated background ──
          _buildAnimatedBackground(currentSlide),

          // ── LAYER 2: Particles ──
          _buildParticles(size, currentSlide),

          // ── LAYER 3: Cinematic content (PageView) ──
          PageView.builder(
            controller: _pageController,
            onPageChanged: _onPageChanged,
            itemCount: _slides.length,
            itemBuilder: (context, index) {
              return _buildCinematicSlide(_slides[index], index);
            },
          ),

          // ── LAYER 4: Top overlay (progress + skip) ──
          _buildTopOverlay(),

          // ── LAYER 5: Bottom overlay (CTA + indicator) ──
          _buildBottomOverlay(isLastPage, currentSlide),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // ANIMATED BACKGROUND
  // ══════════════════════════════════════════

  Widget _buildAnimatedBackground(_CinematicSlide slide) {
    return Positioned.fill(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 800),
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: slide.backgroundGradient,
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // PARTICLES
  // ══════════════════════════════════════════

  Widget _buildParticles(Size size, _CinematicSlide slide) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _particleController,
        builder: (context, child) {
          return CustomPaint(
            painter: _CinematicParticlePainter(
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
  // CINEMATIC SLIDE
  // ══════════════════════════════════════════

  Widget _buildCinematicSlide(_CinematicSlide slide, int index) {
    // Parallax
    final delta = (_pageOffset - index).clamp(-1.0, 1.0);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),

          // Icon with rings
          Transform.translate(
            offset: Offset(delta * -80, 0),
            child: _buildCenterIcon(slide),
          ),

          const SizedBox(height: AppSpacing.xl4),

          // Arabic word
          Transform.translate(
            offset: Offset(delta * -40, 0),
            child: _buildArabicWord(slide),
          ),

          const SizedBox(height: AppSpacing.xl2),

          // Title (large)
          SlideTransition(
            position: _titleSlide,
            child: FadeTransition(
              opacity: _titleFade,
              child: Transform.translate(
                offset: Offset(delta * -20, 0),
                child: _buildTitle(slide),
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Subtitle
          FadeTransition(
            opacity: _subtitleFade,
            child: Transform.translate(
              offset: Offset(delta * -10, 0),
              child: _buildSubtitle(slide),
            ),
          ),

          const Spacer(flex: 2),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // CENTER ICON (Animated with rings)
  // ══════════════════════════════════════════

  Widget _buildCenterIcon(_CinematicSlide slide) {
    return ScaleTransition(
      scale: _pulseAnimation,
      child: SizedBox(
        width: 240,
        height: 240,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Rotating outer ring
            AnimatedBuilder(
              animation: _ringController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _ringController.value * 2 * math.pi,
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: slide.primaryColor.withValues(alpha: 0.20),
                        width: 1,
                      ),
                    ),
                    child: CustomPaint(
                      painter: _RingDotsPainter(
                        color: slide.primaryColor,
                      ),
                    ),
                  ),
                );
              },
            ),

            // Rotating middle ring (opposite direction)
            AnimatedBuilder(
              animation: _ringController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: -_ringController.value * 2 * math.pi,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: slide.secondaryColor.withValues(alpha: 0.30),
                        width: 1.5,
                      ),
                    ),
                  ),
                );
              },
            ),

            // Static inner ring
            Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    slide.primaryColor.withValues(alpha: 0.30),
                    slide.primaryColor.withValues(alpha: 0.05),
                  ],
                ),
                border: Border.all(
                  color: slide.primaryColor.withValues(alpha: 0.50),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: slide.primaryColor.withValues(alpha: 0.40),
                    blurRadius: 60,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),

            // Icon container with glass
            ClipOval(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.background.withValues(alpha: 0.60),
                    border: Border.all(
                      color: slide.secondaryColor,
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
                        slide.centerIcon,
                        size: 64,
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
  // ARABIC WORD (Large)
  // ══════════════════════════════════════════

  Widget _buildArabicWord(_CinematicSlide slide) {
    return ShaderMask(
      shaderCallback: (bounds) => LinearGradient(
        colors: [
          slide.primaryColor,
          slide.secondaryColor,
        ],
      ).createShader(bounds),
      child: Text(
        slide.arabicText,
        style: TextStyle(
          fontFamily: 'Amiri',
          fontSize: 56,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          height: 1.0,
          shadows: [
            Shadow(
              color: slide.primaryColor.withValues(alpha: 0.60),
              blurRadius: 30,
            ),
          ],
        ),
        textDirection: TextDirection.rtl,
      ),
    );
  }

  // ══════════════════════════════════════════
  // TITLE (Large)
  // ══════════════════════════════════════════

  Widget _buildTitle(_CinematicSlide slide) {
    return Text(
      slide.title,
      style: AppTextStyles.displayLarge.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w900,
        fontSize: 64,
        letterSpacing: -1,
        height: 1.0,
      ),
    );
  }

  // ══════════════════════════════════════════
  // SUBTITLE
  // ══════════════════════════════════════════

  Widget _buildSubtitle(_CinematicSlide slide) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl3,
      ),
      child: Text(
        slide.subtitle,
        style: AppTextStyles.bodyLarge.copyWith(
          color: AppColors.textSecondary,
          height: 1.5,
          letterSpacing: 0.5,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  // ══════════════════════════════════════════
  // TOP OVERLAY (Progress + Skip)
  // ══════════════════════════════════════════

  Widget _buildTopOverlay() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Column(
            children: [
              // Progress bars for each slide
              Row(
                children: List.generate(_slides.length, (index) {
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        right: index < _slides.length - 1 ? 6 : 0,
                      ),
                      child: _buildProgressBar(index),
                    ),
                  );
                }),
              ),

              const SizedBox(height: AppSpacing.md),

              // Skip button aligned right
              Align(
                alignment: Alignment.centerRight,
                child: _buildSkipButton(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // PROGRESS BAR
  // ══════════════════════════════════════════

  Widget _buildProgressBar(int index) {
    return Container(
      height: 3,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.20),
        borderRadius: AppRadius.pillRadius,
      ),
      child: AnimatedBuilder(
        animation: _progressController,
        builder: (context, child) {
          double progress = 0.0;

          if (index < _currentPage) {
            progress = 1.0;
          } else if (index == _currentPage) {
            progress = _progressController.value;
          }

          return ClipRRect(
            borderRadius: AppRadius.pillRadius,
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.white.withValues(alpha: 0.90),
              ),
              minHeight: 3,
            ),
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════
  // SKIP BUTTON
  // ══════════════════════════════════════════

  Widget _buildSkipButton() {
    return GestureDetector(
      onTap: _handleSkip,
      child: ClipRRect(
        borderRadius: AppRadius.pillRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: AppRadius.pillRadius,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.20),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Skip',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 10,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // BOTTOM OVERLAY (CTA + Page Indicator)
  // ══════════════════════════════════════════

  Widget _buildBottomOverlay(
    bool isLastPage,
    _CinematicSlide slide,
  ) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.30),
              Colors.black.withValues(alpha: 0.60),
            ],
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                // Page indicator dots
                _buildPageIndicators(slide),

                const SizedBox(height: AppSpacing.xl2),

                // CTA button
                _buildCTAButton(isLastPage, slide),

                const SizedBox(height: AppSpacing.md),

                // Swipe hint
                if (!isLastPage) _buildSwipeHint(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // PAGE INDICATORS (Minimal)
  // ══════════════════════════════════════════

  Widget _buildPageIndicators(_CinematicSlide slide) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_slides.length, (index) {
        final isActive = index == _currentPage;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: isActive ? 24 : 6,
          height: 6,
          decoration: BoxDecoration(
            borderRadius: AppRadius.pillRadius,
            color: isActive
                ? slide.primaryColor
                : Colors.white.withValues(alpha: 0.30),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: slide.primaryColor.withValues(alpha: 0.60),
                      blurRadius: 8,
                    ),
                  ]
                : null,
          ),
        );
      }),
    );
  }

  // ══════════════════════════════════════════
  // CTA BUTTON (Cinematic)
  // ══════════════════════════════════════════

  Widget _buildCTAButton(bool isLastPage, _CinematicSlide slide) {
    return GestureDetector(
      onTap: isLastPage
          ? _handleGetStarted
          : () {
              _pageController.nextPage(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
              );
            },
      child: Container(
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              slide.primaryColor,
              slide.secondaryColor,
            ],
          ),
          borderRadius: AppRadius.pillRadius,
          boxShadow: [
            BoxShadow(
              color: slide.primaryColor.withValues(alpha: 0.60),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              isLastPage ? 'Get Started' : 'Continue',
              style: AppTextStyles.buttonLarge.copyWith(
                color: Colors.white,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // SWIPE HINT
  // ══════════════════════════════════════════

  Widget _buildSwipeHint() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, child) {
        return Opacity(
          opacity: 0.6 +
              (math.sin(_particleController.value * 2 * math.pi) * 0.4).abs(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.swipe_left_rounded,
                color: Colors.white.withValues(alpha: 0.60),
                size: 16,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Swipe to explore',
                style: AppTextStyles.labelSmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.60),
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================
// CINEMATIC PARTICLE PAINTER
// ============================================================

class _CinematicParticlePainter extends CustomPainter {
  final double animationValue;
  final Color primaryColor;
  final Color secondaryColor;

  _CinematicParticlePainter({
    required this.animationValue,
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(123);

    // 40 particles for cinematic feel
    for (int i = 0; i < 40; i++) {
      final baseX = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;

      // Smooth floating motion
      final xOffset = math.sin(
        (animationValue * 2 * math.pi) + i * 0.5,
      );
      final yOffset = math.cos(
        (animationValue * 2 * math.pi) + i * 0.3,
      );

      final x = baseX + (xOffset * 30);
      final y = baseY + (yOffset * 40);

      final particleSize = 1.0 + random.nextDouble() * 3;
      final isSecondary = i % 3 == 0;
      final color = isSecondary ? secondaryColor : primaryColor;
      final alpha = 0.15 + (random.nextDouble() * 0.35);

      // Solid particle
      final paint = Paint()
        ..color = color.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), particleSize, paint);

      // Big glow
      final glowPaint = Paint()
        ..color = color.withValues(alpha: alpha * 0.3)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(
          BlurStyle.normal,
          12,
        );

      canvas.drawCircle(
        Offset(x, y),
        particleSize * 5,
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant _CinematicParticlePainter oldDelegate,
  ) =>
      oldDelegate.animationValue != animationValue ||
      oldDelegate.primaryColor != primaryColor;
}

// ============================================================
// RING DOTS PAINTER
// ============================================================

class _RingDotsPainter extends CustomPainter {
  final Color color;

  _RingDotsPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    // 12 dots on ring
    for (int i = 0; i < 12; i++) {
      final angle = (i * math.pi / 6);
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);

      final dotSize = i % 3 == 0 ? 3.0 : 1.5;

      final paint = Paint()
        ..color = color.withValues(alpha: 0.60)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), dotSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
