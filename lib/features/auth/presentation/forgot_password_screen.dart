// lib/features/auth/presentation/forgot_password_screen.dart

// ============================================================
// QIBRA AI — PREMIUM FORGOT PASSWORD SCREEN (Phase 2)
// Version: 2.0.0
// Description: Apple-quality forgot password with glassmorphism,
//              animated illustrations, and premium success state.
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

// ============================================================
// FORGOT PASSWORD SCREEN
// ============================================================

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  // ── FORM ─────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _emailFocus = FocusNode();

  bool _isEmailFocused = false;
  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMessage;
  String? _sentEmail;

  // ── ANIMATIONS ───────────────────────────────────────
  late AnimationController _particleController;
  late AnimationController _entranceController;
  late Animation<double> _entranceFade;

  late AnimationController _iconPulseController;
  late Animation<double> _iconPulse;

  late AnimationController _successController;
  late Animation<double> _successScale;
  late Animation<double> _successFade;

  @override
  void initState() {
    super.initState();

    // Focus listener
    _emailFocus.addListener(() {
      setState(() => _isEmailFocused = _emailFocus.hasFocus);
      if (_emailFocus.hasFocus) HapticFeedback.selectionClick();
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

    // Icon pulse
    _iconPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _iconPulse = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _iconPulseController,
      curve: Curves.easeInOut,
    ));

    // Success animation
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _successScale = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _successController,
      curve: Curves.elasticOut,
    ));

    _successFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _successController,
      curve: Curves.easeIn,
    ));

    _entranceController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocus.dispose();
    _particleController.dispose();
    _entranceController.dispose();
    _iconPulseController.dispose();
    _successController.dispose();
    super.dispose();
  }

  // ── VALIDATE EMAIL ───────────────────────────────────
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return AppValidation.errorRequired;
    }
    if (!AppValidation.emailRegex.hasMatch(value)) {
      return AppValidation.errorEmail;
    }
    return null;
  }

  // ── SEND RESET LINK ──────────────────────────────────
  Future<void> _handleSendResetLink() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }

    HapticFeedback.mediumImpact();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Simulate API call
      await Future.delayed(const Duration(seconds: 2));

      final email = _emailController.text.trim();

      setState(() {
        _isLoading = false;
        _emailSent = true;
        _sentEmail = email;
      });

      HapticFeedback.heavyImpact();
      _successController.forward();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to send reset link. Please try again.';
      });
    }
  }

  // ── RESEND ───────────────────────────────────────────
  Future<void> _handleResend() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _emailSent = false;
      _errorMessage = null;
    });
    _successController.reset();
    await _handleSendResetLink();
  }

  // ── OPEN EMAIL APP ───────────────────────────────────
  void _handleOpenEmail() {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(
              Icons.mail_rounded,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: AppSpacing.sm),
            Text('Opening email app...'),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardRadius,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    return Scaffold(
      body: Stack(
        children: [
          // ── LAYER 1: Background ──
          _buildBackground(),

          // ── LAYER 2: Particles ──
          _buildParticles(size),

          // ── LAYER 3: Content ──
          SafeArea(
            child: FadeTransition(
              opacity: _entranceFade,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 500),
                  child: _emailSent ? _buildSuccessState() : _buildFormState(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // BACKGROUND
  // ══════════════════════════════════════════

  Widget _buildBackground() {
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: _emailSent
                ? [
                    AppColors.success.withValues(alpha: 0.20),
                    const Color(0xFF0A1628),
                    AppColors.background,
                  ]
                : [
                    const Color(0xFF0D3320),
                    const Color(0xFF0A1628),
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

  Widget _buildParticles(Size size) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _particleController,
        builder: (context, child) {
          return CustomPaint(
            painter: _ForgotParticlePainter(
              animationValue: _particleController.value,
              isSuccess: _emailSent,
            ),
            size: size,
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════
  // FORM STATE
  // ══════════════════════════════════════════

  Widget _buildFormState() {
    return Column(
      key: const ValueKey('form'),
      children: [
        const SizedBox(height: AppSpacing.md),

        // Header
        _buildHeader(),

        const SizedBox(height: AppSpacing.xl2),

        // Icon
        _buildAnimatedIcon(),

        const SizedBox(height: AppSpacing.xl2),

        // Title
        _buildTitle(),

        const SizedBox(height: AppSpacing.xl2),

        // Form
        Form(
          key: _formKey,
          child: _buildFormCard(),
        ),

        const SizedBox(height: AppSpacing.xl2),

        // Back to login
        _buildBackToLoginLink(),

        const SizedBox(height: AppSpacing.xl2),
      ],
    );
  }

  // ══════════════════════════════════════════
  // SUCCESS STATE
  // ══════════════════════════════════════════

  Widget _buildSuccessState() {
    return Column(
      key: const ValueKey('success'),
      children: [
        const SizedBox(height: AppSpacing.md),

        // Header
        _buildHeader(),

        const SizedBox(height: AppSpacing.xl3),

        // Success icon
        ScaleTransition(
          scale: _successScale,
          child: FadeTransition(
            opacity: _successFade,
            child: _buildSuccessIcon(),
          ),
        ),

        const SizedBox(height: AppSpacing.xl2),

        // Success text
        FadeTransition(
          opacity: _successFade,
          child: _buildSuccessText(),
        ),

        const SizedBox(height: AppSpacing.xl2),

        // Info card
        FadeTransition(
          opacity: _successFade,
          child: _buildInfoCard(),
        ),

        const SizedBox(height: AppSpacing.xl2),

        // Action buttons
        FadeTransition(
          opacity: _successFade,
          child: _buildSuccessActions(),
        ),

        const SizedBox(height: AppSpacing.xl2),

        // Back to login
        FadeTransition(
          opacity: _successFade,
          child: _buildBackToLoginLink(),
        ),

        const SizedBox(height: AppSpacing.xl2),
      ],
    );
  }

  // ══════════════════════════════════════════
  // HEADER (Back button)
  // ══════════════════════════════════════════

  Widget _buildHeader() {
    return Row(
      children: [
        // Back button
        GestureDetector(
          onTap: () => context.go(AppRoutes.login),
          child: ClipOval(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.10),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════
  // ANIMATED ICON (Form state)
  // ══════════════════════════════════════════

  Widget _buildAnimatedIcon() {
    return ScaleTransition(
      scale: _iconPulse,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              AppColors.primary.withValues(alpha: 0.30),
              AppColors.primary.withValues(alpha: 0.05),
            ],
          ),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.50),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.40),
              blurRadius: 40,
              spreadRadius: 8,
            ),
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.20),
              blurRadius: 80,
              spreadRadius: 16,
            ),
          ],
        ),
        child: Center(
          child: ShaderMask(
            shaderCallback: (bounds) =>
                AppGradients.emerald.createShader(bounds),
            child: const Icon(
              Icons.lock_reset_rounded,
              color: Colors.white,
              size: 48,
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // SUCCESS ICON
  // ══════════════════════════════════════════

  Widget _buildSuccessIcon() {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            AppColors.success.withValues(alpha: 0.30),
            AppColors.success.withValues(alpha: 0.05),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.50),
            blurRadius: 40,
            spreadRadius: 8,
          ),
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.30),
            blurRadius: 80,
            spreadRadius: 16,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.success,
            boxShadow: [
              BoxShadow(
                color: AppColors.success.withValues(alpha: 0.60),
                blurRadius: 24,
              ),
            ],
          ),
          child: const Icon(
            Icons.mark_email_read_rounded,
            color: Colors.white,
            size: 48,
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // TITLE (Form)
  // ══════════════════════════════════════════

  Widget _buildTitle() {
    return Column(
      children: [
        ShaderMask(
          shaderCallback: (bounds) => AppGradients.emerald.createShader(bounds),
          child: Text(
            'PASSWORD RECOVERY',
            style: AppTextStyles.labelSmall.copyWith(
              color: Colors.white,
              letterSpacing: 3,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'Forgot Password?',
          style: AppTextStyles.headlineLarge.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
          ),
          child: Text(
            'No worries! Enter your email and we\'ll send you a link to reset your password.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════
  // SUCCESS TEXT
  // ══════════════════════════════════════════

  Widget _buildSuccessText() {
    return Column(
      children: [
        Text(
          'Check Your Email',
          style: AppTextStyles.displaySmall.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 32,
            color: AppColors.success,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'We\'ve sent a password reset link to',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        // Email badge
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.20),
                AppColors.primary.withValues(alpha: 0.10),
              ],
            ),
            borderRadius: AppRadius.pillRadius,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.40),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.mail_outline_rounded,
                color: AppColors.primary,
                size: 16,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                _sentEmail ?? '',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════
  // FORM CARD (Glassmorphism)
  // ══════════════════════════════════════════

  Widget _buildFormCard() {
    return ClipRRect(
      borderRadius: AppRadius.cardRadiusLarge,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
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
          child: Column(
            children: [
              // Error banner
              if (_errorMessage != null) ...[
                _buildErrorBanner(_errorMessage!),
                const SizedBox(height: AppSpacing.md),
              ],

              // Email field
              _buildPremiumTextField(),

              const SizedBox(height: AppSpacing.md),

              // Helper text
              Row(
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: AppColors.textTertiary,
                    size: 14,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'We\'ll send a password reset link to this email',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // Send button
              _buildSendButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // ERROR BANNER
  // ══════════════════════════════════════════

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.error.withValues(alpha: 0.20),
            AppColors.error.withValues(alpha: 0.10),
          ],
        ),
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.40),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.20),
              borderRadius: AppRadius.pillRadius,
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 16,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // PREMIUM TEXT FIELD
  // ══════════════════════════════════════════

  Widget _buildPremiumTextField() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: AppRadius.cardRadius,
        boxShadow: _isEmailFocused
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.30),
                  blurRadius: 20,
                ),
              ]
            : null,
      ),
      child: TextFormField(
        controller: _emailController,
        focusNode: _emailFocus,
        keyboardType: TextInputType.emailAddress,
        textInputAction: TextInputAction.done,
        validator: _validateEmail,
        enabled: !_isLoading,
        onFieldSubmitted: (_) => _handleSendResetLink(),
        style: AppTextStyles.bodyMedium.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          labelText: 'Email Address',
          hintText: 'you@example.com',
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textTertiary,
          ),
          labelStyle: AppTextStyles.bodyMedium.copyWith(
            color:
                _isEmailFocused ? AppColors.primary : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
          prefixIcon: Icon(
            Icons.mail_outline_rounded,
            color:
                _isEmailFocused ? AppColors.primary : AppColors.textSecondary,
            size: 22,
          ),
          filled: true,
          fillColor: _isEmailFocused
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.white.withValues(alpha: 0.02),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          border: OutlineInputBorder(
            borderRadius: AppRadius.cardRadius,
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.10),
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: AppRadius.cardRadius,
            borderSide: BorderSide(
              color: Colors.white.withValues(alpha: 0.10),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: AppRadius.cardRadius,
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: AppRadius.cardRadius,
            borderSide: const BorderSide(
              color: AppColors.error,
              width: 1,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: AppRadius.cardRadius,
            borderSide: const BorderSide(
              color: AppColors.error,
              width: 2,
            ),
          ),
          errorStyle: AppTextStyles.labelSmall.copyWith(
            color: AppColors.error,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // SEND BUTTON
  // ══════════════════════════════════════════

  Widget _buildSendButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _handleSendResetLink,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 56,
        decoration: BoxDecoration(
          gradient: _isLoading
              ? LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.60),
                    AppColors.primaryDark.withValues(alpha: 0.60),
                  ],
                )
              : AppGradients.emerald,
          borderRadius: AppRadius.buttonRadiusLg,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.50),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Send Reset Link',
                      style: AppTextStyles.buttonLarge.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // INFO CARD (Success state)
  // ══════════════════════════════════════════

  Widget _buildInfoCard() {
    return ClipRRect(
      borderRadius: AppRadius.cardRadiusLarge,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppColors.accent.withValues(alpha: 0.30),
                          AppColors.accent.withValues(alpha: 0.10),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.40),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.checklist_rounded,
                      color: AppColors.accent,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'NEXT STEPS',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.accent,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppSpacing.lg),

              // Steps
              _buildStepItem(1, 'Check your email inbox (also spam folder)'),
              const SizedBox(height: AppSpacing.md),
              _buildStepItem(2, 'Click the reset link in the email'),
              const SizedBox(height: AppSpacing.md),
              _buildStepItem(3, 'Create your new password'),

              const SizedBox(height: AppSpacing.lg),

              // Warning
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.warning.withValues(alpha: 0.15),
                      AppColors.warning.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: AppRadius.buttonRadius,
                  border: Border.all(
                    color: AppColors.warning.withValues(alpha: 0.40),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.access_time_rounded,
                      color: AppColors.warning,
                      size: 16,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Link expires in 15 minutes',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.warning,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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

  // ══════════════════════════════════════════
  // STEP ITEM
  // ══════════════════════════════════════════

  Widget _buildStepItem(int number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary.withValues(alpha: 0.30),
                AppColors.primary.withValues(alpha: 0.10),
              ],
            ),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.50),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.20),
                blurRadius: 8,
              ),
            ],
          ),
          child: Center(
            child: Text(
              '$number',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════
  // SUCCESS ACTIONS
  // ══════════════════════════════════════════

  Widget _buildSuccessActions() {
    return Column(
      children: [
        // Open Email button
        GestureDetector(
          onTap: _handleOpenEmail,
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              gradient: AppGradients.emerald,
              borderRadius: AppRadius.buttonRadiusLg,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.50),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.mail_rounded,
                  color: Colors.white,
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Open Email App',
                  style: AppTextStyles.buttonLarge.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // Resend button
        GestureDetector(
          onTap: _isLoading ? null : _handleResend,
          child: ClipRRect(
            borderRadius: AppRadius.buttonRadiusLg,
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: AppRadius.buttonRadiusLg,
                  border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.40),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.accent,
                          ),
                        ),
                      )
                    else
                      ShaderMask(
                        shaderCallback: (bounds) =>
                            AppGradients.gold.createShader(bounds),
                        child: const Icon(
                          Icons.refresh_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    const SizedBox(width: AppSpacing.sm),
                    ShaderMask(
                      shaderCallback: (bounds) =>
                          AppGradients.gold.createShader(bounds),
                      child: Text(
                        _isLoading ? 'Sending...' : 'Resend Link',
                        style: AppTextStyles.buttonMedium.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════
  // BACK TO LOGIN LINK
  // ══════════════════════════════════════════

  Widget _buildBackToLoginLink() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        context.go(AppRoutes.login);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.primary,
            size: 16,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'Back to Login',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// FORGOT PARTICLE PAINTER
// ============================================================

class _ForgotParticlePainter extends CustomPainter {
  final double animationValue;
  final bool isSuccess;

  _ForgotParticlePainter({
    required this.animationValue,
    required this.isSuccess,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(44);

    for (int i = 0; i < 22; i++) {
      final baseX = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;

      final offset = math.sin(
        (animationValue * 2 * math.pi) + i,
      );

      final x = baseX + (offset * 25);
      final y = baseY + (offset * 35);

      final particleSize = 1.5 + random.nextDouble() * 2;
      final isGold = i % 3 == 0;
      final color = isSuccess
          ? (isGold ? AppColors.accent : AppColors.success)
          : (isGold ? AppColors.accent : AppColors.primary);
      final alpha = 0.15 + (random.nextDouble() * 0.25);

      final paint = Paint()
        ..color = color.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(Offset(x, y), particleSize, paint);

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
    covariant _ForgotParticlePainter oldDelegate,
  ) =>
      oldDelegate.animationValue != animationValue ||
      oldDelegate.isSuccess != isSuccess;
}
