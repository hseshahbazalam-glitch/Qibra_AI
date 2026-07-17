// lib/features/splash/presentation/splash_screen.dart

// ============================================================
// QIBRA AI — PREMIUM SPLASH SCREEN (Phase 2)
// Version: 2.0.0
// Description: Apple-quality splash with glassmorphism,
//              glowing particles, and Islamic patterns.
// ============================================================

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qibra_ai/core/constants/app_constants.dart';
import 'package:qibra_ai/core/design_system/app_colors.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';
import 'package:qibra_ai/core/providers/auth_provider.dart';
import 'package:qibra_ai/core/providers/theme_provider.dart';

// ============================================================
// SPLASH SCREEN WIDGET
// ============================================================

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  // ── ANIMATION CONTROLLERS ────────────────────────────

  /// Background rotating pattern
  late AnimationController _patternController;

  /// Floating particles animation
  late AnimationController _particleController;

  /// Logo scale + fade
  late AnimationController _logoController;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _logoGlow;

  /// Bismillah fade + slide
  late AnimationController _bismillahController;
  late Animation<double> _bismillahFade;
  late Animation<Offset> _bismillahSlide;

  /// App name reveal (letter by letter)
  late AnimationController _nameController;
  late Animation<double> _nameReveal;

  /// Tagline fade
  late AnimationController _taglineController;
  late Animation<double> _taglineFade;

  /// Loading dots
  late AnimationController _loadingController;

  @override
  void initState() {
    super.initState();

    // ── Background Pattern (very slow, continuous) ──
    _patternController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();

    // ── Floating Particles (continuous) ──
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // ── Logo Animation ──
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _logoScale = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    _logoFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    ));

    _logoGlow = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    ));

    // ── Bismillah Animation ──
    _bismillahController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _bismillahFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _bismillahController,
      curve: Curves.easeIn,
    ));

    _bismillahSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _bismillahController,
      curve: Curves.easeOutCubic,
    ));

    // ── App Name Reveal Animation ──
    _nameController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _nameReveal = CurvedAnimation(
      parent: _nameController,
      curve: Curves.easeOutCubic,
    );

    // ── Tagline Animation ──
    _taglineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _taglineFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _taglineController,
      curve: Curves.easeIn,
    ));

    // ── Loading Dots (continuous) ──
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    // Start choreographed animation sequence
    _startAnimationSequence();

    // Schedule navigation
    _scheduleNavigation();
  }

  /// Animation sequence with proper timing
  Future<void> _startAnimationSequence() async {
    // Wait 200ms
    await Future.delayed(const Duration(milliseconds: 200));
    if (!mounted) return;

    // Bismillah appears first
    _bismillahController.forward();

    // Wait 500ms then logo
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    _logoController.forward();

    // Wait 800ms then app name
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    _nameController.forward();

    // Wait 600ms then tagline
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    _taglineController.forward();
  }

  /// Navigate after splash duration
  Future<void> _scheduleNavigation() async {
    await Future.delayed(const Duration(milliseconds: 3500));

    if (!mounted) return;

    final authState = ref.read(authProvider);
    final hasSeenOnboarding = ref.read(onboardingProvider);

    if (!hasSeenOnboarding) {
      context.go(AppRoutes.onboarding);
    } else if (!authState.isAuthenticated) {
      context.go(AppRoutes.login);
    } else {
      context.go(AppRoutes.home);
    }
  }

  @override
  void dispose() {
    _patternController.dispose();
    _particleController.dispose();
    _logoController.dispose();
    _bismillahController.dispose();
    _nameController.dispose();
    _taglineController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── LAYER 1: Deep gradient background ──
          _buildBackgroundGradient(),

          // ── LAYER 2: Rotating Islamic pattern ──
          _buildRotatingPattern(size),

          // ── LAYER 3: Floating particles ──
          _buildFloatingParticles(size),

          // ── LAYER 4: Glassmorphism blur overlay ──
          _buildGlassOverlay(),

          // ── LAYER 5: Main content ──
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),

                // Bismillah
                _buildBismillah(),

                const SizedBox(height: AppSpacing.xl4),

                // Premium Logo
                _buildPremiumLogo(),

                const SizedBox(height: AppSpacing.xl3),

                // App Name with reveal
                _buildAppNameReveal(),

                const SizedBox(height: AppSpacing.md),

                // Decorative divider
                _buildDecorativeDivider(),

                const SizedBox(height: AppSpacing.md),

                // Tagline
                _buildTagline(),

                const Spacer(flex: 3),

                // Loading indicator
                _buildLoadingIndicator(),

                const SizedBox(height: AppSpacing.xl2),

                // Version + copyright
                _buildFooter(),

                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // LAYER 1: Background Gradient
  // ══════════════════════════════════════════

  Widget _buildBackgroundGradient() {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.5,
            colors: [
              Color(0xFF0D3320), // Emerald center
              Color(0xFF071A14), // Deep emerald
              Color(0xFF020A08), // Almost black
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // LAYER 2: Rotating Islamic Pattern
  // ══════════════════════════════════════════

  Widget _buildRotatingPattern(Size size) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _patternController,
        builder: (context, child) {
          return Transform.rotate(
            angle: _patternController.value * 2 * math.pi,
            child: Opacity(
              opacity: 0.06,
              child: CustomPaint(
                painter: _IslamicPatternPainter(),
                size: Size(size.width * 2, size.height * 2),
              ),
            ),
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════
  // LAYER 3: Floating Particles
  // ══════════════════════════════════════════

  Widget _buildFloatingParticles(Size size) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _particleController,
        builder: (context, child) {
          return CustomPaint(
            painter: _ParticlePainter(
              animationValue: _particleController.value,
            ),
            size: size,
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════
  // LAYER 4: Glassmorphism Overlay
  // ══════════════════════════════════════════

  Widget _buildGlassOverlay() {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
        child: Container(
          color: AppColors.background.withValues(alpha: 0.10),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // BISMILLAH
  // ══════════════════════════════════════════

  Widget _buildBismillah() {
    return SlideTransition(
      position: _bismillahSlide,
      child: FadeTransition(
        opacity: _bismillahFade,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl2,
          ),
          child: Column(
            children: [
              // Arabic Bismillah
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [
                    AppColors.accent,
                    AppColors.accentBright,
                    AppColors.accent,
                  ],
                ).createShader(bounds),
                child: Text(
                  AppIslamicConstants.bismillah,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    height: 1.5,
                    shadows: [
                      Shadow(
                        color: AppColors.accent.withValues(alpha: 0.60),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              // English translation
              Text(
                'In the name of Allah, the Most Gracious, the Most Merciful',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontStyle: FontStyle.italic,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // PREMIUM LOGO
  // ══════════════════════════════════════════

  Widget _buildPremiumLogo() {
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _logoFade,
          child: ScaleTransition(
            scale: _logoScale,
            child: child,
          ),
        );
      },
      child: AnimatedBuilder(
        animation: _logoGlow,
        builder: (context, child) {
          return Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppGradients.gold,
              boxShadow: [
                // Multi-layer glow effect
                BoxShadow(
                  color: AppColors.accent
                      .withValues(alpha: 0.60 * _logoGlow.value),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
                BoxShadow(
                  color: AppColors.accent
                      .withValues(alpha: 0.40 * _logoGlow.value),
                  blurRadius: 80,
                  spreadRadius: 16,
                ),
                BoxShadow(
                  color: AppColors.primary
                      .withValues(alpha: 0.20 * _logoGlow.value),
                  blurRadius: 120,
                  spreadRadius: 24,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer ring
                Container(
                  width: 145,
                  height: 145,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.40),
                      width: 1.5,
                    ),
                  ),
                ),

                // Inner dark circle with glass effect
                ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: 10,
                      sigmaY: 10,
                    ),
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.background.withValues(alpha: 0.90),
                        border: Border.all(
                          color: AppColors.accent.withValues(alpha: 0.50),
                          width: 2,
                        ),
                      ),
                      child: Center(
                        // Mosque icon with gradient
                        child: ShaderMask(
                          shaderCallback: (bounds) =>
                              AppGradients.gold.createShader(bounds),
                          child: const Icon(
                            Icons.mosque_rounded,
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
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════
  // APP NAME REVEAL
  // ══════════════════════════════════════════

  Widget _buildAppNameReveal() {
    const appName = 'QIBRA AI';
    final letters = appName.split('');

    return AnimatedBuilder(
      animation: _nameReveal,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(letters.length, (index) {
            // Each letter appears at different time
            final letterProgress =
                (_nameReveal.value * letters.length - index).clamp(0.0, 1.0);

            return Opacity(
              opacity: letterProgress,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - letterProgress)),
                child: ShaderMask(
                  shaderCallback: (bounds) =>
                      AppGradients.gold.createShader(bounds),
                  child: Text(
                    letters[index],
                    style: AppTextStyles.displaySmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 6,
                      height: 1.0,
                      shadows: [
                        Shadow(
                          color: AppColors.accent.withValues(alpha: 0.60),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  // ══════════════════════════════════════════
  // DECORATIVE DIVIDER
  // ══════════════════════════════════════════

  Widget _buildDecorativeDivider() {
    return FadeTransition(
      opacity: _taglineFade,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.accent.withValues(alpha: 0.60),
                ],
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
            ),
            child: Icon(
              Icons.star,
              color: AppColors.accent,
              size: 12,
            ),
          ),
          Container(
            width: 40,
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.accent.withValues(alpha: 0.60),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // TAGLINE
  // ══════════════════════════════════════════

  Widget _buildTagline() {
    return FadeTransition(
      opacity: _taglineFade,
      child: Text(
        AppInfo.tagline,
        style: AppTextStyles.bodyMedium.copyWith(
          color: AppColors.textSecondary,
          letterSpacing: 2,
          fontWeight: FontWeight.w300,
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // LOADING INDICATOR (Premium)
  // ══════════════════════════════════════════

  Widget _buildLoadingIndicator() {
    return AnimatedBuilder(
      animation: _loadingController,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            final delay = index * 0.15;
            final animationValue =
                (_loadingController.value - delay).clamp(0.0, 1.0);
            final wave = math.sin(animationValue * math.pi);

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      AppColors.accent.withValues(alpha: 0.30 + (wave * 0.70)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: wave * 0.60),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            );
          }),
        );
      },
    );
  }

  // ══════════════════════════════════════════
  // FOOTER
  // ══════════════════════════════════════════

  Widget _buildFooter() {
    return FadeTransition(
      opacity: _taglineFade,
      child: Column(
        children: [
          Text(
            AppInfo.versionFull,
            style: AppTextStyles.labelXSmall.copyWith(
              color: AppColors.textTertiary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppInfo.copyright,
            style: AppTextStyles.labelXSmall.copyWith(
              color: AppColors.textTertiary.withValues(alpha: 0.60),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// ISLAMIC PATTERN PAINTER
// ============================================================

class _IslamicPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 4;

    // Draw 8-pointed star pattern
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi / 4);
      final path = Path();

      for (int j = 0; j < 8; j++) {
        final r = j % 2 == 0 ? radius : radius * 0.6;
        final x = center.dx + r * math.cos(angle + (j * math.pi / 4));
        final y = center.dy + r * math.sin(angle + (j * math.pi / 4));

        if (j == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }

      path.close();
      canvas.drawPath(path, paint);
    }

    // Concentric circles
    for (int i = 1; i <= 5; i++) {
      canvas.drawCircle(
        center,
        radius * i * 0.3,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ============================================================
// FLOATING PARTICLES PAINTER
// ============================================================

class _ParticlePainter extends CustomPainter {
  final double animationValue;

  _ParticlePainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42); // Fixed seed for consistency

    // Draw 30 floating particles
    for (int i = 0; i < 30; i++) {
      final baseX = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;

      // Floating motion
      final offset = math.sin(
        (animationValue * 2 * math.pi) + i,
      );

      final x = baseX + (offset * 20);
      final y = baseY + (offset * 30);

      // Particle size varies
      final particleSize = 1.5 + random.nextDouble() * 2;

      // Alternate emerald and gold particles
      final isGold = i % 3 == 0;
      final color = isGold ? AppColors.accent : AppColors.primary;

      // Fade in/out based on position
      final alpha = 0.20 + (random.nextDouble() * 0.30);

      final paint = Paint()
        ..color = color.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      // Draw particle with glow
      canvas.drawCircle(
        Offset(x, y),
        particleSize,
        paint,
      );

      // Draw glow effect
      final glowPaint = Paint()
        ..color = color.withValues(alpha: alpha * 0.3)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(
          BlurStyle.normal,
          6,
        );

      canvas.drawCircle(
        Offset(x, y),
        particleSize * 3,
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}
