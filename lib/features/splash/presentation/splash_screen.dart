// lib/features/splash/presentation/splash_screen.dart

// ============================================================
// QIBRA AI — PREMIUM SPLASH SCREEN v3.0
// Updated: 2026 + Shahbaz Alam credit
// ============================================================

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qibra_ai/core/constants/app_constants.dart';
import 'package:qibra_ai/core/design_system/qibra_colors.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';
import 'package:qibra_ai/core/providers/auth_provider.dart';
import 'package:qibra_ai/core/providers/theme_provider.dart';
import 'package:qibra_ai/shared/widgets/media/pattern_backdrop.dart';
import 'package:qibra_ai/shared/widgets/media/safe_image.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _patternController;
  late AnimationController _particleController;
  late AnimationController _logoController;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _logoGlow;
  late AnimationController _bismillahController;
  late Animation<double> _bismillahFade;
  late Animation<Offset> _bismillahSlide;
  late AnimationController _nameController;
  late Animation<double> _nameReveal;
  late AnimationController _taglineController;
  late Animation<double> _taglineFade;
  late AnimationController _loadingController;

  // Timers are tracked so widget tests and rapid navigation never leave
  // delayed callbacks alive after this screen is disposed.
  final List<Timer> _pendingTimers = [];

  @override
  void initState() {
    super.initState();

    _patternController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 40),
    )..repeat();

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.elasticOut),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _logoGlow = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _bismillahController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _bismillahFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _bismillahController, curve: Curves.easeIn),
    );

    _bismillahSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _bismillahController,
        curve: Curves.easeOutCubic,
      ),
    );

    _nameController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _nameReveal = CurvedAnimation(
      parent: _nameController,
      curve: Curves.easeOutCubic,
    );

    _taglineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _taglineController, curve: Curves.easeIn),
    );

    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    _startAnimationSequence();
    _scheduleNavigation();
  }

  void _scheduleTimer(Duration delay, VoidCallback callback) {
    late final Timer timer;
    timer = Timer(delay, () {
      _pendingTimers.remove(timer);
      if (!mounted) return;
      callback();
    });
    _pendingTimers.add(timer);
  }

  void _startAnimationSequence() {
    _scheduleTimer(
      const Duration(milliseconds: 200),
      () => _bismillahController.forward(),
    );
    _scheduleTimer(
      const Duration(milliseconds: 700),
      () => _logoController.forward(),
    );
    _scheduleTimer(
      const Duration(milliseconds: 1500),
      () => _nameController.forward(),
    );
    _scheduleTimer(
      const Duration(milliseconds: 2100),
      () => _taglineController.forward(),
    );
  }

  void _scheduleNavigation() {
    _scheduleTimer(const Duration(milliseconds: 3500), () {
      final authState = ref.read(authProvider);
      final hasSeenOnboarding = ref.read(onboardingProvider);

      if (!hasSeenOnboarding) {
        context.go(AppRoutes.onboarding);
      } else if (!authState.isAuthenticated) {
        context.go(AppRoutes.login);
      } else {
        context.go(AppRoutes.home);
      }
    });
  }

  @override
  void dispose() {
    for (final timer in _pendingTimers) {
      timer.cancel();
    }
    _pendingTimers.clear();

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
    final colors = QibraColors.of(context);
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          _buildBackgroundGradient(),
          _buildRotatingPattern(size),
          if (!MediaQuery.of(context).disableAnimations)
            _buildFloatingParticles(size),
          _buildGlassOverlay(),
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 3),
                _buildBismillah(),
                const SizedBox(height: AppSpacing.xl4),
                _buildPremiumLogo(),
                const SizedBox(height: AppSpacing.xl3),
                _buildAppNameReveal(),
                const SizedBox(height: AppSpacing.md),
                _buildDecorativeDivider(),
                const SizedBox(height: AppSpacing.md),
                _buildTagline(),
                const Spacer(flex: 3),
                _buildLoadingIndicator(),
                const SizedBox(height: AppSpacing.xl2),
                _buildPremiumFooter(),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundGradient() {
    final colors = QibraColors.of(context);
    return Positioned.fill(
      child: PatternBackdrop(
        child: Stack(
          fit: StackFit.expand,
          children: [
            SafeImage(
              assetPath: AppAssets.splashBackground,
              fit: BoxFit.cover,
              fallback: SafeImageFallback.mosque,
            ),
            ColoredBox(color: colors.background.withValues(alpha: 0.35)),
          ],
        ),
      ),
    );
  }

  Widget _buildRotatingPattern(Size size) {
    final colors = QibraColors.of(context);
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

  Widget _buildFloatingParticles(Size size) {
    final colors = QibraColors.of(context);
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

  Widget _buildGlassOverlay() {
    final colors = QibraColors.of(context);
    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 0.5, sigmaY: 0.5),
        child: Container(
          color: colors.background.withValues(alpha: 0.10),
        ),
      ),
    );
  }

  Widget _buildBismillah() {
    final colors = QibraColors.of(context);
    return SlideTransition(
      position: _bismillahSlide,
      child: FadeTransition(
        opacity: _bismillahFade,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl2),
          child: Column(
            children: [
              Text(
                AppIslamicConstants.bismillah,
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: colors.goldText,
                  height: 1.5,
                ),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'In the name of Allah, the Most Gracious, the Most Merciful',
                style: AppTextStyles.labelSmall.copyWith(
                  color: colors.textSecondary,
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

  Widget _buildPremiumLogo() {
    final colors = QibraColors.of(context);
    return AnimatedBuilder(
      animation: _logoController,
      builder: (context, child) {
        return FadeTransition(
          opacity: _logoFade,
          child: ScaleTransition(scale: _logoScale, child: child),
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
                BoxShadow(
                  color: colors.accent
                      .withValues(alpha: 0.60 * _logoGlow.value),
                  blurRadius: 40,
                  spreadRadius: 8,
                ),
                BoxShadow(
                  color: colors.accent
                      .withValues(alpha: 0.40 * _logoGlow.value),
                  blurRadius: 80,
                  spreadRadius: 16,
                ),
                BoxShadow(
                  color: colors.primary
                      .withValues(alpha: 0.20 * _logoGlow.value),
                  blurRadius: 120,
                  spreadRadius: 24,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 145,
                  height: 145,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: colors.onPrimary.withValues(alpha: 0.40),
                      width: 1.5,
                    ),
                  ),
                ),
                ClipOval(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      width: 130,
                      height: 130,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.background.withValues(alpha: 0.90),
                        border: Border.all(
                          color: colors.accent.withValues(alpha: 0.50),
                          width: 2,
                        ),
                      ),
                      child: const Center(
                        child: SafeImage(
                          assetPath: AppAssets.logo,
                          width: 96,
                          height: 96,
                          cacheWidth: 288,
                          fit: BoxFit.contain,
                          fallback: SafeImageFallback.logo,
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

  Widget _buildAppNameReveal() {
    final colors = QibraColors.of(context);
    const appName = 'QIBRA AI';
    final letters = appName.split('');

    return AnimatedBuilder(
      animation: _nameReveal,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(letters.length, (index) {
            final letterProgress =
                (_nameReveal.value * letters.length - index).clamp(0.0, 1.0);

            return Opacity(
              opacity: letterProgress,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - letterProgress)),
                child: Text(
                  letters[index],
                  style: AppTextStyles.displaySmall.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 6,
                    height: 1.0,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildDecorativeDivider() {
    final colors = QibraColors.of(context);
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
                  colors.accent.withValues(alpha: 0.60),
                ],
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Icon(Icons.star, color: colors.accent, size: 12),
          ),
          Container(
            width: 40,
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colors.accent.withValues(alpha: 0.60),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTagline() {
    final colors = QibraColors.of(context);
    return FadeTransition(
      opacity: _taglineFade,
      child: Text(
        'Quran, Hadith, prayer, and tools',
        style: AppTextStyles.bodyMedium.copyWith(
          color: colors.textSecondary,
          letterSpacing: 2,
          fontWeight: FontWeight.w300,
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    final colors = QibraColors.of(context);
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
                      colors.accent.withValues(alpha: 0.30 + (wave * 0.70)),
                  boxShadow: [
                    BoxShadow(
                      color: colors.accent.withValues(alpha: wave * 0.60),
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

  // ============================================================
  // PREMIUM FOOTER — NEW DESIGN with Shahbaz Alam
  // ============================================================

  Widget _buildPremiumFooter() {
    final colors = QibraColors.of(context);
    return FadeTransition(
      opacity: _taglineFade,
      child: Column(
        children: [
          // Version + BETA badge
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.15),
                  borderRadius: AppRadius.pillRadius,
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'v1.0.0',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: colors.error,
                  borderRadius: AppRadius.pillRadius,
                ),
                child: Text(
                  'BETA',
                  style: TextStyle(
                    color: colors.onPrimary,
                    fontWeight: FontWeight.w900,
                    fontSize: 9,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Developer credit
          Text(
            'Designed & Developed by',
            style: AppTextStyles.labelXSmall.copyWith(
              color: colors.textTertiary.withValues(alpha: 0.70),
              fontSize: 8,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 3),
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [
                Color(0xFFC6A15B),
                Color(0xFFB8960C),
                Color(0xFFC6A15B),
              ],
            ).createShader(bounds),
            child: Text(
              'SHAHBAZ ALAM',
              style: AppTextStyles.labelSmall.copyWith(
                color: const Color(0xFF19312C),
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 2.5,
              ),
            ),
          ),

          const SizedBox(height: 6),

          // Copyright
          Text(
            '© 2026 QIBRA AI · All Rights Reserved',
            style: AppTextStyles.labelXSmall.copyWith(
              color: colors.textTertiary.withValues(alpha: 0.50),
              fontSize: 8,
              letterSpacing: 0.5,
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
      ..color = const Color(0xFFC6A15B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 4;

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

    for (int i = 1; i <= 5; i++) {
      canvas.drawCircle(center, radius * i * 0.3, paint);
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
    final random = math.Random(42);

    for (int i = 0; i < 12; i++) {
      final baseX = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;
      final offset = math.sin((animationValue * 2 * math.pi) + i);
      final x = baseX + (offset * 20);
      final y = baseY + (offset * 30);
      final particleSize = 1.5 + random.nextDouble() * 2;
      final isGold = i % 3 == 0;
      final color = isGold ? const Color(0xFFC6A15B) : const Color(0xFF123F36);
      final alpha = 0.20 + (random.nextDouble() * 0.30);

      final paint = Paint()
        ..color = color.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), particleSize, paint);

      final glowPaint = Paint()
        ..color = color.withValues(alpha: alpha * 0.3)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      canvas.drawCircle(Offset(x, y), particleSize * 3, glowPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}
