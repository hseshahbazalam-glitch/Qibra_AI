// lib/features/onboarding/presentation/onboarding_v2_screen.dart

// ============================================================
// QIBRA AI — PREMIUM ONBOARDING V2 (Alternative Variant)
// Version: 2.0.0
// Description: Story-telling onboarding with vertical scroll,
//              hero cards, feature highlights.
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
// FEATURE DATA MODEL
// ============================================================

class _FeatureData {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final String arabicText;

  const _FeatureData({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.arabicText,
  });
}

const List<_FeatureData> _features = [
  _FeatureData(
    icon: Icons.menu_book_rounded,
    title: 'Complete Quran',
    description:
        'Beautiful Arabic text with 40+ translations and 30+ recitations by renowned Qaris',
    color: AppColors.primary,
    arabicText: 'الْقُرْآن',
  ),
  _FeatureData(
    icon: Icons.access_time_filled_rounded,
    title: 'Precise Prayer Times',
    description:
        'GPS-accurate prayer times for anywhere in the world with Adhan notifications',
    color: AppColors.accent,
    arabicText: 'الصَّلَاة',
  ),
  _FeatureData(
    icon: Icons.explore_rounded,
    title: 'Qibla Direction',
    description:
        'Real-time compass showing exact direction to Masjid al-Haram in Makkah',
    color: Color(0xFF7C3AED),
    arabicText: 'الْقِبْلَة',
  ),
  _FeatureData(
    icon: Icons.smart_toy_rounded,
    title: 'AI Islamic Assistant',
    description:
        'Ask any Islamic question and get authentic answers based on Quran and Hadith',
    color: Color(0xFF3B82F6),
    arabicText: 'الذَّكَاء',
  ),
  _FeatureData(
    icon: Icons.library_books_rounded,
    title: 'Authentic Hadiths',
    description:
        'Complete collections including Sahih al-Bukhari, Muslim, and other major works',
    color: Color(0xFFF59E0B),
    arabicText: 'الْحَدِيث',
  ),
  _FeatureData(
    icon: Icons.calendar_month_rounded,
    title: 'Islamic Calendar',
    description:
        'Hijri dates, important Islamic events, Ramadan calendar and prayer schedules',
    color: Color(0xFF10B981),
    arabicText: 'التَّقْوِيم',
  ),
];

// ============================================================
// ONBOARDING V2 SCREEN
// ============================================================

class OnboardingV2Screen extends ConsumerStatefulWidget {
  const OnboardingV2Screen({super.key});

  @override
  ConsumerState<OnboardingV2Screen> createState() => _OnboardingV2ScreenState();
}

class _OnboardingV2ScreenState extends ConsumerState<OnboardingV2Screen>
    with TickerProviderStateMixin {
  // ── SCROLL CONTROLLER ────────────────────────────────
  late ScrollController _scrollController;
  double _scrollOffset = 0.0;

  // ── PARTICLE ANIMATION ───────────────────────────────
  late AnimationController _particleController;

  // ── ENTRANCE ANIMATION ───────────────────────────────
  late AnimationController _entranceController;
  late Animation<double> _entranceFade;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });

    // Particles
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    // Entrance
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _entranceFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeIn,
    ));

    _entranceController.forward();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _particleController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  // ── HANDLERS ─────────────────────────────────────────

  Future<void> _handleGetStarted() async {
    HapticFeedback.mediumImpact();
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

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── LAYER 1: Background gradient ──
          _buildBackground(),

          // ── LAYER 2: Floating particles ──
          _buildParticleBackground(size),

          // ── LAYER 3: Main content (scrollable) ──
          FadeTransition(
            opacity: _entranceFade,
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                // Hero header
                SliverToBoxAdapter(child: _buildHeroHeader()),

                // Features section title
                SliverToBoxAdapter(
                  child: _buildSectionTitle(),
                ),

                // Feature cards
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildFeatureCard(
                        _features[index],
                        index,
                      ),
                      childCount: _features.length,
                    ),
                  ),
                ),

                // Bottom spacing for button
                const SliverToBoxAdapter(
                  child: SizedBox(height: 120),
                ),
              ],
            ),
          ),

          // ── LAYER 4: Fixed skip button (top) ──
          Positioned(
            top: 50,
            right: 20,
            child: _buildSkipButton(),
          ),

          // ── LAYER 5: Fixed bottom CTA ──
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildBottomCTA(),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // BACKGROUND GRADIENT
  // ══════════════════════════════════════════

  Widget _buildBackground() {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A1628),
              Color(0xFF0D2E1A),
              AppColors.background,
            ],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // PARTICLE BACKGROUND
  // ══════════════════════════════════════════

  Widget _buildParticleBackground(Size size) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _particleController,
        builder: (context, child) {
          return CustomPaint(
            painter: _V2ParticlePainter(
              animationValue: _particleController.value,
            ),
            size: size,
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════
  // HERO HEADER (with parallax)
  // ══════════════════════════════════════════

  Widget _buildHeroHeader() {
    // Parallax scroll effect
    final parallaxOffset = _scrollOffset * 0.3;

    return Container(
      height: 480,
      padding: const EdgeInsets.only(top: 60),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Parallax glow
          Transform.translate(
            offset: Offset(0, -parallaxOffset),
            child: _buildHeroGlow(),
          ),

          // App name + tagline
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),

              // Bismillah badge
              _buildBismillahBadge(),

              const SizedBox(height: AppSpacing.xl3),

              // Hero logo
              _buildHeroLogo(),

              const SizedBox(height: AppSpacing.xl2),

              // App name with gold gradient
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppGradients.gold.createShader(bounds),
                child: Text(
                  AppInfo.appName,
                  style: AppTextStyles.displayMedium.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    height: 1.0,
                    shadows: [
                      Shadow(
                        color: AppColors.accent.withValues(alpha: 0.60),
                        blurRadius: 24,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.sm),

              // Tagline
              Text(
                AppInfo.tagline,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w300,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppSpacing.xl3),

              // Scroll indicator
              _buildScrollIndicator(),
            ],
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // HERO GLOW (Background)
  // ══════════════════════════════════════════

  Widget _buildHeroGlow() {
    return Container(
      width: 400,
      height: 400,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.accent.withValues(alpha: 0.20),
            AppColors.primary.withValues(alpha: 0.10),
            Colors.transparent,
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // BISMILLAH BADGE
  // ══════════════════════════════════════════

  Widget _buildBismillahBadge() {
    return ClipRRect(
      borderRadius: AppRadius.pillRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.10),
            borderRadius: AppRadius.pillRadius,
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.30),
              width: 1,
            ),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.mosque_rounded,
                color: AppColors.accent,
                size: 14,
              ),
              SizedBox(width: AppSpacing.xs),
              Text(
                'بِسْمِ اللَّهِ',
                style: TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 14,
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                ),
                textDirection: TextDirection.rtl,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // HERO LOGO
  // ══════════════════════════════════════════

  Widget _buildHeroLogo() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppGradients.gold,
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.60),
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
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.background.withValues(alpha: 0.85),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.50),
                width: 2,
              ),
            ),
            child: Center(
              child: ShaderMask(
                shaderCallback: (bounds) =>
                    AppGradients.gold.createShader(bounds),
                child: const Icon(
                  Icons.mosque_rounded,
                  size: 48,
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
  // SCROLL INDICATOR
  // ══════════════════════════════════════════

  Widget _buildScrollIndicator() {
    return Column(
      children: [
        Text(
          'DISCOVER FEATURES',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.accent.withValues(alpha: 0.80),
            letterSpacing: 3,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        AnimatedContainer(
          duration: const Duration(seconds: 1),
          curve: Curves.easeInOut,
          child: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: AppColors.accent.withValues(alpha: 0.60),
            size: 32,
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════
  // SECTION TITLE
  // ══════════════════════════════════════════

  Widget _buildSectionTitle() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xl2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Everything You Need',
            style: AppTextStyles.headlineMedium.copyWith(
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'A complete Islamic companion in one app',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // FEATURE CARD (Glass)
  // ══════════════════════════════════════════

  Widget _buildFeatureCard(_FeatureData feature, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ClipRRect(
        borderRadius: AppRadius.cardRadiusLarge,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.08),
                  Colors.white.withValues(alpha: 0.03),
                ],
              ),
              borderRadius: AppRadius.cardRadiusLarge,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.10),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                // Icon container
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.cardRadius,
                    gradient: LinearGradient(
                      colors: [
                        feature.color.withValues(alpha: 0.30),
                        feature.color.withValues(alpha: 0.10),
                      ],
                    ),
                    border: Border.all(
                      color: feature.color.withValues(alpha: 0.50),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: feature.color.withValues(alpha: 0.30),
                        blurRadius: 20,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Center(
                    child: ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [
                          feature.color,
                          feature.color.withValues(alpha: 0.70),
                        ],
                      ).createShader(bounds),
                      child: Icon(
                        feature.icon,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: AppSpacing.md),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title + Arabic badge
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              feature.title,
                              style: AppTextStyles.titleSmall.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: feature.color.withValues(alpha: 0.15),
                              borderRadius: AppRadius.pillRadius,
                              border: Border.all(
                                color: feature.color.withValues(alpha: 0.30),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              feature.arabicText,
                              style: TextStyle(
                                fontFamily: 'Amiri',
                                fontSize: 12,
                                color: feature.color,
                                fontWeight: FontWeight.w700,
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: AppSpacing.xs),

                      // Description
                      Text(
                        feature.description,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
                        ),
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

  // ══════════════════════════════════════════
  // SKIP BUTTON
  // ══════════════════════════════════════════

  Widget _buildSkipButton() {
    return GestureDetector(
      onTap: _handleSkip,
      child: ClipRRect(
        borderRadius: AppRadius.pillRadius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.10),
              borderRadius: AppRadius.pillRadius,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Text(
                  'Skip',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: AppColors.textPrimary,
                  size: 12,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // BOTTOM CTA (Fixed)
  // ══════════════════════════════════════════

  Widget _buildBottomCTA() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.background.withValues(alpha: 0.0),
                AppColors.background.withValues(alpha: 0.90),
                AppColors.background,
              ],
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: AppGoldButton(
                label: 'Get Started',
                suffixIcon: Icons.arrow_forward_rounded,
                onPressed: _handleGetStarted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================
// V2 PARTICLE PAINTER
// ============================================================

class _V2ParticlePainter extends CustomPainter {
  final double animationValue;

  _V2ParticlePainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(88);

    // Draw 20 subtle floating particles
    for (int i = 0; i < 20; i++) {
      final baseX = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;

      final offset = math.sin(
        (animationValue * 2 * math.pi) + i,
      );

      final x = baseX + (offset * 30);
      final y = baseY + (offset * 40);

      final particleSize = 1.5 + random.nextDouble() * 2;
      final isGold = i % 4 == 0;
      final color = isGold ? AppColors.accent : AppColors.primary;
      final alpha = 0.15 + (random.nextDouble() * 0.20);

      final paint = Paint()
        ..color = color.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), particleSize, paint);

      // Soft glow
      final glowPaint = Paint()
        ..color = color.withValues(alpha: alpha * 0.4)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

      canvas.drawCircle(
        Offset(x, y),
        particleSize * 4,
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _V2ParticlePainter oldDelegate) =>
      oldDelegate.animationValue != animationValue;
}
