// lib/features/settings/presentation/language_selection_screen.dart

// ============================================================
// QIBRA AI — LANGUAGE SELECTION SCREEN (Phase 2)
// Version: 2.0.0
// Description: Premium language selection with 3 options.
//              Beautiful cards, animated selection, save to provider.
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
// LANGUAGE DATA MODEL
// ============================================================

class _LanguageOption {
  final String code;
  final String name;
  final String nativeName;
  final String description;
  final String flagEmoji;
  final String greeting;
  final bool isRTL;
  final Color accentColor;

  const _LanguageOption({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.description,
    required this.flagEmoji,
    required this.greeting,
    required this.isRTL,
    required this.accentColor,
  });
}

const List<_LanguageOption> _languages = [
  _LanguageOption(
    code: 'en',
    name: 'English',
    nativeName: 'English',
    description: 'Continue in English',
    flagEmoji: '🌍',
    greeting: 'Hello',
    isRTL: false,
    accentColor: AppColors.primary,
  ),
  _LanguageOption(
    code: 'ar',
    name: 'Arabic',
    nativeName: 'العربية',
    description: 'المتابعة باللغة العربية',
    flagEmoji: '🕌',
    greeting: 'مرحبا',
    isRTL: true,
    accentColor: AppColors.accent,
  ),
  _LanguageOption(
    code: 'ur',
    name: 'Urdu',
    nativeName: 'اردو',
    description: 'اردو میں جاری رکھیں',
    flagEmoji: '☪️',
    greeting: 'السلام علیکم',
    isRTL: true,
    accentColor: Color(0xFF10B981),
  ),
];

// ============================================================
// LANGUAGE SELECTION SCREEN
// ============================================================

class LanguageSelectionScreen extends ConsumerStatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  ConsumerState<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState
    extends ConsumerState<LanguageSelectionScreen>
    with TickerProviderStateMixin {
  // ── SELECTED LANGUAGE ────────────────────────────────
  String _selectedLanguageCode = 'en';

  // ── ANIMATION CONTROLLERS ────────────────────────────
  late AnimationController _entranceController;
  late Animation<double> _entranceFade;

  late AnimationController _particleController;

  late AnimationController _iconController;
  late Animation<double> _iconScale;

  @override
  void initState() {
    super.initState();

    // Get current language from provider
    final currentLocale = ref.read(localeProvider);
    _selectedLanguageCode = currentLocale.languageCode;

    // Entrance animation
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

    // Particle animation
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    // Icon bounce animation
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _iconScale = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _iconController,
      curve: Curves.elasticOut,
    ));

    _entranceController.forward();
    _iconController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _particleController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  // ── HANDLERS ─────────────────────────────────────────

  void _selectLanguage(String code) {
    HapticFeedback.selectionClick();
    setState(() => _selectedLanguageCode = code);
  }

  Future<void> _handleContinue() async {
    HapticFeedback.mediumImpact();

    // Save selected language to provider
    await ref.read(localeProvider.notifier).setLocale(_selectedLanguageCode);

    // Navigate to permission screen (Step 2.6)
    // For now, navigate to login
    if (mounted) {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final selectedLanguage = _languages.firstWhere(
      (lang) => lang.code == _selectedLanguageCode,
    );

    return Scaffold(
      body: Stack(
        children: [
          // ── LAYER 1: Background gradient ──
          _buildBackground(selectedLanguage),

          // ── LAYER 2: Floating particles ──
          _buildParticles(size, selectedLanguage),

          // ── LAYER 3: Main content ──
          FadeTransition(
            opacity: _entranceFade,
            child: SafeArea(
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.md),

                  // Header
                  _buildHeader(),

                  const SizedBox(height: AppSpacing.xl3),

                  // Icon
                  _buildIcon(selectedLanguage),

                  const SizedBox(height: AppSpacing.xl2),

                  // Greeting card
                  _buildGreetingCard(selectedLanguage),

                  const SizedBox(height: AppSpacing.xl2),

                  // Language options
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                      ),
                      child: Column(
                        children: List.generate(_languages.length, (index) {
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.md,
                            ),
                            child: _buildLanguageCard(
                              _languages[index],
                              index,
                            ),
                          );
                        }),
                      ),
                    ),
                  ),

                  // Continue button
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: _buildContinueButton(selectedLanguage),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // BACKGROUND (Adaptive to selection)
  // ══════════════════════════════════════════

  Widget _buildBackground(_LanguageOption language) {
    return Positioned.fill(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 800),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color(0xFF0A1628),
              language.accentColor.withValues(alpha: 0.15),
              AppColors.background,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // PARTICLES
  // ══════════════════════════════════════════

  Widget _buildParticles(Size size, _LanguageOption language) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _particleController,
        builder: (context, child) {
          return CustomPaint(
            painter: _LanguageParticlePainter(
              animationValue: _particleController.value,
              color: language.accentColor,
            ),
            size: size,
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════
  // HEADER
  // ══════════════════════════════════════════

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Small logo
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
                  Icons.mosque_rounded,
                  color: AppColors.background,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppGradients.gold.createShader(bounds),
                child: Text(
                  AppInfo.appName,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),

          // Step indicator
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
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
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '1',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  ' / 3',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // ICON
  // ══════════════════════════════════════════

  Widget _buildIcon(_LanguageOption language) {
    return AnimatedBuilder(
      animation: _iconController,
      builder: (context, child) {
        return Transform.scale(
          scale: _iconScale.value,
          child: child,
        );
      },
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              language.accentColor.withValues(alpha: 0.30),
              language.accentColor.withValues(alpha: 0.05),
            ],
          ),
          border: Border.all(
            color: language.accentColor.withValues(alpha: 0.50),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: language.accentColor.withValues(alpha: 0.40),
              blurRadius: 40,
              spreadRadius: 8,
            ),
          ],
        ),
        child: Center(
          child: Icon(
            Icons.language_rounded,
            size: 48,
            color: language.accentColor,
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // GREETING CARD
  // ══════════════════════════════════════════

  Widget _buildGreetingCard(_LanguageOption language) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl2,
      ),
      child: Column(
        children: [
          Text(
            'CHOOSE YOUR LANGUAGE',
            style: AppTextStyles.labelSmall.copyWith(
              color: language.accentColor,
              letterSpacing: 3,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: Text(
              language.greeting,
              key: ValueKey(language.code),
              style: TextStyle(
                fontFamily: language.isRTL ? 'Amiri' : 'Poppins',
                fontSize: 32,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                height: 1.2,
              ),
              textDirection:
                  language.isRTL ? TextDirection.rtl : TextDirection.ltr,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Select your preferred language',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
              letterSpacing: 0.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // LANGUAGE CARD
  // ══════════════════════════════════════════

  Widget _buildLanguageCard(
    _LanguageOption language,
    int index,
  ) {
    final isSelected = _selectedLanguageCode == language.code;

    return GestureDetector(
      onTap: () => _selectLanguage(language.code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        child: ClipRRect(
          borderRadius: AppRadius.cardRadiusLarge,
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: isSelected ? 20 : 10,
              sigmaY: isSelected ? 20 : 10,
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isSelected
                      ? [
                          language.accentColor.withValues(alpha: 0.20),
                          language.accentColor.withValues(alpha: 0.10),
                        ]
                      : [
                          Colors.white.withValues(alpha: 0.06),
                          Colors.white.withValues(alpha: 0.02),
                        ],
                ),
                borderRadius: AppRadius.cardRadiusLarge,
                border: Border.all(
                  color: isSelected
                      ? language.accentColor.withValues(alpha: 0.60)
                      : Colors.white.withValues(alpha: 0.10),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: language.accentColor.withValues(alpha: 0.30),
                          blurRadius: 24,
                          spreadRadius: 0,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                children: [
                  // Flag/Emoji container
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: isSelected
                            ? [
                                language.accentColor.withValues(alpha: 0.30),
                                language.accentColor.withValues(alpha: 0.10),
                              ]
                            : [
                                Colors.white.withValues(alpha: 0.08),
                                Colors.white.withValues(alpha: 0.03),
                              ],
                      ),
                      border: Border.all(
                        color: isSelected
                            ? language.accentColor
                            : Colors.white.withValues(alpha: 0.15),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        language.flagEmoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                  ),

                  const SizedBox(width: AppSpacing.md),

                  // Text content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Native name (big)
                        Text(
                          language.nativeName,
                          style: TextStyle(
                            fontFamily: language.isRTL ? 'Amiri' : 'Poppins',
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                            height: 1.2,
                          ),
                          textDirection: language.isRTL
                              ? TextDirection.rtl
                              : TextDirection.ltr,
                        ),
                        const SizedBox(height: 2),
                        // English name + description
                        Row(
                          children: [
                            Text(
                              language.name,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: language.accentColor,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1,
                              ),
                            ),
                            Text(
                              ' · ',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textTertiary,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                language.description,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: AppColors.textSecondary,
                                ),
                                textDirection: language.isRTL
                                    ? TextDirection.rtl
                                    : TextDirection.ltr,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: AppSpacing.sm),

                  // Radio indicator
                  _buildRadioIndicator(isSelected, language),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // RADIO INDICATOR (Animated)
  // ══════════════════════════════════════════

  Widget _buildRadioIndicator(
    bool isSelected,
    _LanguageOption language,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: isSelected
            ? LinearGradient(
                colors: [
                  language.accentColor,
                  language.accentColor.withValues(alpha: 0.70),
                ],
              )
            : null,
        color: isSelected ? null : Colors.transparent,
        border: Border.all(
          color: isSelected
              ? language.accentColor
              : Colors.white.withValues(alpha: 0.30),
          width: 2,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: language.accentColor.withValues(alpha: 0.50),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ]
            : null,
      ),
      child: isSelected
          ? const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 18,
            )
          : null,
    );
  }

  // ══════════════════════════════════════════
  // CONTINUE BUTTON
  // ══════════════════════════════════════════

  Widget _buildContinueButton(_LanguageOption language) {
    return GestureDetector(
      onTap: _handleContinue,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              language.accentColor,
              language.accentColor.withValues(alpha: 0.80),
            ],
          ),
          borderRadius: AppRadius.buttonRadiusLg,
          boxShadow: [
            BoxShadow(
              color: language.accentColor.withValues(alpha: 0.50),
              blurRadius: 24,
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
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
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
}

// ============================================================
// LANGUAGE PARTICLE PAINTER
// ============================================================

class _LanguageParticlePainter extends CustomPainter {
  final double animationValue;
  final Color color;

  _LanguageParticlePainter({
    required this.animationValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(55);

    for (int i = 0; i < 20; i++) {
      final baseX = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;

      final offset = math.sin(
        (animationValue * 2 * math.pi) + i,
      );

      final x = baseX + (offset * 25);
      final y = baseY + (offset * 35);

      final particleSize = 1.5 + random.nextDouble() * 2;
      final alpha = 0.15 + (random.nextDouble() * 0.25);

      final paint = Paint()
        ..color = color.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), particleSize, paint);

      // Glow
      final glowPaint = Paint()
        ..color = color.withValues(alpha: alpha * 0.3)
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
  bool shouldRepaint(
    covariant _LanguageParticlePainter oldDelegate,
  ) =>
      oldDelegate.animationValue != animationValue ||
      oldDelegate.color != color;
}
