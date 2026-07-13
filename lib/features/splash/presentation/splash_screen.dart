// lib/features/splash/presentation/splash_screen.dart

// ============================================================
// QIBRA AI — SPLASH SCREEN
// Version: 1.0.0
// Description: Premium animated splash screen.
//              Islamic theme with Bismillah, gold accents,
//              and smooth fade/scale animations.
// ============================================================

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
  // Alag-alag animations ke liye alag controllers

  /// Logo scale + fade animation
  late AnimationController _logoController;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;

  /// Text fade + slide animation
  late AnimationController _textController;
  late Animation<double> _textFade;
  late Animation<Offset> _textSlide;

  /// Bismillah fade animation
  late AnimationController _bismillahController;
  late Animation<double> _bismillahFade;

  /// Loading dots animation
  late AnimationController _loadingController;

  /// Background rotation animation (subtle)
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();

    // ── Logo Animation (scale + fade) ──────────────────
    // Duration: 800ms — smooth entry
    _logoController = AnimationController(
      vsync: this,
      duration: AppDurations.extraSlow,
    );

    // Scale: 0.5 → 1.0 (start small, grow to full)
    _logoScale = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _logoController,
        // easeOutBack = overshoot effect — premium feel
        curve: Curves.easeOutBack,
      ),
    );

    // Fade: 0 → 1 (invisible to visible)
    _logoFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.easeIn,
      ),
    );

    // ── Text Animation (fade + slide up) ───────────────
    _textController = AnimationController(
      vsync: this,
      duration: AppDurations.slow,
    );

    _textFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeIn,
      ),
    );

    // Slide from below (0.5 offset = below screen)
    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _textController,
        curve: Curves.easeOut,
      ),
    );

    // ── Bismillah Animation ─────────────────────────────
    _bismillahController = AnimationController(
      vsync: this,
      duration: AppDurations.slow,
    );

    _bismillahFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _bismillahController,
        curve: Curves.easeIn,
      ),
    );

    // ── Loading Animation (continuous) ─────────────────
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(); // Repeat forever

    // ── Background Rotation (very slow, subtle) ────────
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    // ── Start animation sequence ───────────────────────
    _startAnimations();

    // ── Auto navigate after splash duration ────────────
    _navigateAfterDelay();
  }

  /// Animations ko sequence mein play karo
  Future<void> _startAnimations() async {
    // Logo pehle animate ho
    await _logoController.forward();

    // Fir Bismillah dikhao
    await Future.delayed(const Duration(milliseconds: 200));
    await _bismillahController.forward();

    // Fir tagline text
    await Future.delayed(const Duration(milliseconds: 200));
    await _textController.forward();
  }

  /// 3 seconds ke baad navigate karo
  Future<void> _navigateAfterDelay() async {
    // Wait for splash duration (3 seconds)
    await Future.delayed(AppDurations.splash);

    // Check if widget still mounted (user navigate away nahi hua)
    if (!mounted) return;

    // Auth state check karo
    final authState = ref.read(authProvider);
    final hasSeenOnboarding = ref.read(onboardingProvider);

    // Navigation logic
    if (!hasSeenOnboarding) {
      // First time user — onboarding pe bhejo
      if (mounted) context.go(AppRoutes.onboarding);
    } else if (!authState.isAuthenticated) {
      // Logged out — login pe bhejo
      if (mounted) context.go(AppRoutes.login);
    } else {
      // Logged in — home pe bhejo
      if (mounted) context.go(AppRoutes.home);
    }
  }

  @override
  void dispose() {
    // Memory leak se bachne ke liye — sab controllers dispose karo
    _logoController.dispose();
    _textController.dispose();
    _bismillahController.dispose();
    _loadingController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Full screen radial gradient background
        decoration: const BoxDecoration(
          gradient: AppGradients.splashGradient,
        ),
        child: Stack(
          children: [
            // Layer 1: Rotating Islamic pattern background
            _buildRotatingPattern(),

            // Layer 2: Main content
            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),

                  // Bismillah text
                  _buildBismillah(),

                  const SizedBox(height: AppSpacing.xl4),

                  // Logo with animation
                  _buildLogo(),

                  const SizedBox(height: AppSpacing.xl3),

                  // App name + tagline
                  _buildAppInfo(),

                  const Spacer(flex: 2),

                  // Loading indicator
                  _buildLoadingIndicator(),

                  const SizedBox(height: AppSpacing.xl2),

                  // Version info at bottom
                  _buildVersionInfo(),

                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // BISMILLAH TEXT
  // ══════════════════════════════════════════

  Widget _buildBismillah() {
    return FadeTransition(
      opacity: _bismillahFade,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl2,
        ),
        child: Column(
          children: [
            // Arabic Bismillah
            Text(
              AppIslamicConstants.bismillah,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppColors.accent, // Royal gold
                height: 1.5,
                shadows: [
                  Shadow(
                    color: AppColors.accent.withValues(alpha: 0.30),
                    blurRadius: 12,
                  ),
                ],
              ),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: AppSpacing.xs),

            // English translation
            Text(
              'In the name of Allah, the Most Gracious, the Most Merciful',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // ANIMATED LOGO
  // ══════════════════════════════════════════

  Widget _buildLogo() {
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
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // Gold gradient background
          gradient: AppGradients.gold,
          // Gold glow shadow
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.50),
              blurRadius: 40,
              spreadRadius: 8,
            ),
            BoxShadow(
              color: AppColors.accent.withValues(alpha: 0.30),
              blurRadius: 80,
              spreadRadius: 16,
            ),
          ],
        ),
        child: Center(
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // Dark inner circle
              color: AppColors.background,
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.50),
                width: 2,
              ),
            ),
            child: Center(
              // Logo icon — mosque
              child: ShaderMask(
                shaderCallback: (bounds) =>
                    AppGradients.gold.createShader(bounds),
                child: const Icon(
                  Icons.mosque,
                  size: 60,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // APP NAME + TAGLINE
  // ══════════════════════════════════════════

  Widget _buildAppInfo() {
    return SlideTransition(
      position: _textSlide,
      child: FadeTransition(
        opacity: _textFade,
        child: Column(
          children: [
            // App name with gold gradient text
            ShaderMask(
              shaderCallback: (bounds) =>
                  AppGradients.gold.createShader(bounds),
              child: Text(
                AppInfo.appName,
                style: AppTextStyles.displaySmall.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 6,
                  height: 1.0,
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Decorative divider
            Container(
              width: 60,
              height: 2,
              decoration: BoxDecoration(
                gradient: AppGradients.gold,
                borderRadius: AppRadius.pillRadius,
              ),
            ),

            const SizedBox(height: AppSpacing.md),

            // Tagline
            Text(
              AppInfo.tagline,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w300,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // LOADING INDICATOR (Custom animated dots)
  // ══════════════════════════════════════════

  Widget _buildLoadingIndicator() {
    return AnimatedBuilder(
      animation: _loadingController,
      builder: (context, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            // Har dot ke liye alag delay
            final delay = index * 0.2;
            final animationValue =
                (_loadingController.value - delay).clamp(0.0, 1.0);
            // Wave effect — sin curve
            final scale = 0.5 + 0.5 * (1.0 - (2 * animationValue - 1).abs());

            return Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
              ),
              child: Transform.scale(
                scale: scale,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent.withValues(alpha: scale),
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
  // VERSION INFO
  // ══════════════════════════════════════════

  Widget _buildVersionInfo() {
    return FadeTransition(
      opacity: _bismillahFade,
      child: Column(
        children: [
          Text(
            AppInfo.versionFull,
            style: AppTextStyles.labelXSmall.copyWith(
              color: AppColors.textTertiary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '© ${DateTime.now().year} QIBRA Technologies',
            style: AppTextStyles.labelXSmall.copyWith(
              color: AppColors.textTertiary.withValues(alpha: 0.60),
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // ROTATING PATTERN BACKGROUND (subtle)
  // ══════════════════════════════════════════

  Widget _buildRotatingPattern() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _rotationController,
        builder: (context, child) {
          return Transform.rotate(
            angle: _rotationController.value * 2 * 3.14159,
            child: Opacity(
              opacity: 0.03, // Very subtle
              child: child,
            ),
          );
        },
        child: Center(
          child: Icon(
            Icons.star,
            size: MediaQuery.of(context).size.width * 1.5,
            color: AppColors.accent,
          ),
        ),
      ),
    );
  }
}
