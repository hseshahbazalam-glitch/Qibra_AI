// lib/features/auth/presentation/verify_otp_screen.dart

// ============================================================
// QIBRA AI — PREMIUM OTP VERIFICATION (Phase 2)
// Version: 2.0.0
// Description: Apple-quality OTP with progress ring,
//              auto-submit, premium animations.
// ============================================================

import 'dart:async';
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
// PREMIUM OTP SCREEN
// ============================================================

class VerifyOtpScreen extends ConsumerStatefulWidget {
  final String? email;

  const VerifyOtpScreen({super.key, this.email});

  @override
  ConsumerState<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends ConsumerState<VerifyOtpScreen>
    with TickerProviderStateMixin {
  // ── OTP CONTROLLERS ──────────────────────────────────
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final List<bool> _isFocused = List.generate(6, (_) => false);

  // ── STATE ────────────────────────────────────────────
  bool _isLoading = false;
  bool _isVerified = false;
  String? _errorMessage;

  // ── TIMER STATE ──────────────────────────────────────
  Timer? _timer;
  int _remainingSeconds = 60;
  bool _canResend = false;

  // ── ANIMATION CONTROLLERS ────────────────────────────
  late AnimationController _particleController;

  late AnimationController _iconPulseController;
  late Animation<double> _iconPulse;

  late AnimationController _successController;
  late Animation<double> _successScale;
  late Animation<double> _successFade;

  late AnimationController _entranceController;
  late Animation<double> _entranceFade;
  late Animation<Offset> _entranceSlide;

  @override
  void initState() {
    super.initState();

    // Focus listeners for each OTP box
    for (int i = 0; i < 6; i++) {
      _focusNodes[i].addListener(() {
        setState(() => _isFocused[i] = _focusNodes[i].hasFocus);
        if (_focusNodes[i].hasFocus) {
          HapticFeedback.selectionClick();
        }
      });
    }

    // ── Particle animation (continuous) ──
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat();

    // ── Icon pulse animation (breathing) ──
    _iconPulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _iconPulse = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(
      CurvedAnimation(
        parent: _iconPulseController,
        curve: Curves.easeInOut,
      ),
    );

    // ── Success animation ──
    _successController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _successScale = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _successController,
        curve: Curves.elasticOut,
      ),
    );

    _successFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _successController,
        curve: Curves.easeIn,
      ),
    );

    // ── Entrance animation ──
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _entranceFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeIn,
      ),
    );

    _entranceSlide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutCubic,
      ),
    );

    // Start entrance animation
    _entranceController.forward();

    // Start countdown timer
    _startTimer();
  }

  @override
  void dispose() {
    // Dispose all OTP controllers
    for (final controller in _controllers) {
      controller.dispose();
    }
    // Dispose all focus nodes
    for (final focusNode in _focusNodes) {
      focusNode.dispose();
    }
    // Cancel timer
    _timer?.cancel();
    // Dispose animation controllers
    _particleController.dispose();
    _iconPulseController.dispose();
    _successController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  // ── START COUNTDOWN TIMER ────────────────────────────
  void _startTimer() {
    _remainingSeconds = 60;
    _canResend = false;

    _timer?.cancel();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (_remainingSeconds > 0) {
          setState(() => _remainingSeconds--);
        } else {
          timer.cancel();
          setState(() => _canResend = true);
        }
      },
    );
  }

  // ── GET CURRENT OTP STRING ───────────────────────────
  String get _currentOtp => _controllers.map((c) => c.text).join();

  // ── HANDLE DIGIT INPUT ───────────────────────────────
  void _onDigitChanged(int index, String value) {
    // Clear error on any input
    setState(() => _errorMessage = null);

    if (value.length == 1) {
      // Digit entered — haptic feedback
      HapticFeedback.selectionClick();

      if (index < 5) {
        // Move to next box
        _focusNodes[index + 1].requestFocus();
      } else {
        // Last box — unfocus keyboard
        _focusNodes[index].unfocus();

        // Auto-submit when all 6 digits entered
        if (_currentOtp.length == 6) {
          _handleVerify();
        }
      }
    } else if (value.isEmpty) {
      // Digit deleted — move to previous box
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  // ── VERIFY OTP HANDLER ───────────────────────────────
  Future<void> _handleVerify() async {
    // Validate OTP length
    if (_currentOtp.length != 6) {
      HapticFeedback.heavyImpact();
      setState(() => _errorMessage = 'Please enter all 6 digits');
      return;
    }

    HapticFeedback.mediumImpact();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Simulate API call (2 seconds)
      await Future.delayed(const Duration(seconds: 2));

      // Check OTP (test OTP is 123456)
      if (_currentOtp == '123456') {
        // Success!
        setState(() {
          _isLoading = false;
          _isVerified = true;
        });

        // Play success animation
        _successController.forward();
        HapticFeedback.heavyImpact();

        // Wait for animation then navigate
        await Future.delayed(const Duration(milliseconds: 1500));

        if (mounted) {
          // Navigate to Profile Setup (Phase 5 flow)
          context.go(AppRoutes.profileSetup);
        }
      } else {
        // Invalid OTP
        HapticFeedback.heavyImpact();

        setState(() {
          _isLoading = false;
          _errorMessage = 'Invalid OTP. Please try again.';

          // Clear all OTP boxes
          for (final controller in _controllers) {
            controller.clear();
          }

          // Focus first box
          _focusNodes[0].requestFocus();
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Verification failed. Please try again.';
      });
    }
  }

  // ── RESEND OTP HANDLER ───────────────────────────────
  Future<void> _handleResend() async {
    if (!_canResend) return;

    HapticFeedback.mediumImpact();

    setState(() {
      _isLoading = true;
      _errorMessage = null;

      // Clear all OTP boxes
      for (final controller in _controllers) {
        controller.clear();
      }
    });

    try {
      // Simulate resend API
      await Future.delayed(const Duration(seconds: 1));

      // Restart timer
      _startTimer();

      setState(() => _isLoading = false);

      // Show success snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: AppSpacing.sm),
                Text('OTP sent successfully!'),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.cardRadius,
            ),
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to resend OTP. Please try again.';
      });
    }
  }

  // ── FORMATTED TIME DISPLAY ───────────────────────────
  String get _formattedTime {
    final minutes = (_remainingSeconds ~/ 60).toString();
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // ── TIMER PROGRESS (for circular indicator) ──────────
  double get _timerProgress => _remainingSeconds / 60;

  // ══════════════════════════════════════════
  // BUILD METHOD
  // ══════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final displayEmail = widget.email ?? 'your email';

    return Scaffold(
      body: Stack(
        children: [
          // Layer 1: Animated background
          _buildBackground(),

          // Layer 2: Floating particles
          _buildParticles(size),

          // Layer 3: Main content
          SafeArea(
            child: FadeTransition(
              opacity: _entranceFade,
              child: SlideTransition(
                position: _entranceSlide,
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 500),
                    child: _isVerified
                        ? _buildSuccessState()
                        : _buildVerifyState(displayEmail),
                  ),
                ),
              ),
            ),
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
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 800),
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: _isVerified
                ? [
                    AppColors.success.withValues(alpha: 0.20),
                    const Color(0xFF0A1628),
                    AppColors.background,
                  ]
                : [
                    const Color(0xFF2D2410),
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
  // FLOATING PARTICLES
  // ══════════════════════════════════════════

  Widget _buildParticles(Size size) {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _particleController,
        builder: (context, child) {
          return CustomPaint(
            painter: _OtpParticlePainter(
              animationValue: _particleController.value,
              isSuccess: _isVerified,
            ),
            size: size,
          );
        },
      ),
    );
  }

  // ══════════════════════════════════════════
  // VERIFY STATE (Main form)
  // ══════════════════════════════════════════

  Widget _buildVerifyState(String displayEmail) {
    return Column(
      key: const ValueKey('verify'),
      children: [
        const SizedBox(height: AppSpacing.md),

        // Header with back button + step indicator
        _buildHeader(),

        const SizedBox(height: AppSpacing.xl2),

        // Pulsing timer icon with progress ring
        _buildTimerIcon(),

        const SizedBox(height: AppSpacing.xl2),

        // Title section
        _buildTitle(displayEmail),

        const SizedBox(height: AppSpacing.xl2),

        // Glass form card with OTP boxes
        _buildFormCard(),

        const SizedBox(height: AppSpacing.xl2),

        // Resend section (timer or button)
        _buildResendSection(),

        const SizedBox(height: AppSpacing.xl2),

        // Help info card
        _buildHelpInfoCard(),

        const SizedBox(height: AppSpacing.xl2),

        // Change email link
        _buildChangeEmailLink(),

        const SizedBox(height: AppSpacing.xl2),
      ],
    );
  }

  // ══════════════════════════════════════════
  // SUCCESS STATE (Verified)
  // ══════════════════════════════════════════

  Widget _buildSuccessState() {
    return Column(
      key: const ValueKey('success'),
      children: [
        const SizedBox(height: AppSpacing.xl6),

        // Bouncing success icon
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

        const SizedBox(height: AppSpacing.xl3),

        // Loading indicator
        FadeTransition(
          opacity: _successFade,
          child: _buildLoadingIndicator(),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════
  // HEADER (Back + Step Indicator)
  // ══════════════════════════════════════════

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Back button (glass)
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

        // Step indicator badge
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
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
              ShaderMask(
                shaderCallback: (bounds) =>
                    AppGradients.gold.createShader(bounds),
                child: Text(
                  '2',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                ' / 3 · Verify',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════
  // TIMER ICON (Pulsing + Progress Ring)
  // ══════════════════════════════════════════

  Widget _buildTimerIcon() {
    return ScaleTransition(
      scale: _iconPulse,
      child: SizedBox(
        width: 120,
        height: 120,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Circular progress ring
            SizedBox(
              width: 120,
              height: 120,
              child: CircularProgressIndicator(
                value: _timerProgress,
                strokeWidth: 3,
                backgroundColor: Colors.white.withValues(alpha: 0.10),
                valueColor: AlwaysStoppedAnimation<Color>(
                  _canResend ? AppColors.success : AppColors.accent,
                ),
              ),
            ),

            // Inner glowing circle
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.accent.withValues(alpha: 0.30),
                    AppColors.accent.withValues(alpha: 0.05),
                  ],
                ),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.50),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.40),
                    blurRadius: 30,
                    spreadRadius: 4,
                  ),
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.20),
                    blurRadius: 60,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: Center(
                child: ShaderMask(
                  shaderCallback: (bounds) =>
                      AppGradients.gold.createShader(bounds),
                  child: const Icon(
                    Icons.security_rounded,
                    color: Colors.white,
                    size: 48,
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
  // TITLE SECTION
  // ══════════════════════════════════════════

  Widget _buildTitle(String displayEmail) {
    return Column(
      children: [
        // VERIFICATION label
        ShaderMask(
          shaderCallback: (bounds) => AppGradients.gold.createShader(bounds),
          child: Text(
            'VERIFICATION',
            style: AppTextStyles.labelSmall.copyWith(
              color: Colors.white,
              letterSpacing: 3,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        // Enter Code heading
        Text(
          'Enter Code',
          style: AppTextStyles.headlineLarge.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // Description with email highlight
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
          ),
          child: RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.6,
              ),
              children: [
                const TextSpan(
                  text: 'We sent a 6-digit code to ',
                ),
                TextSpan(
                  text: displayEmail,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════
  // GLASS FORM CARD
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
              // Error banner (if any)
              if (_errorMessage != null) ...[
                _buildErrorBanner(_errorMessage!),
                const SizedBox(height: AppSpacing.md),
              ],

              // 6 OTP input boxes
              _buildOtpBoxes(),

              const SizedBox(height: AppSpacing.lg),

              // Verify button
              _buildVerifyButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // 6 OTP INPUT BOXES
  // ══════════════════════════════════════════

  Widget _buildOtpBoxes() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        return _buildSingleOtpBox(index);
      }),
    );
  }

  Widget _buildSingleOtpBox(int index) {
    final hasValue = _controllers[index].text.isNotEmpty;
    final isFocused = _isFocused[index];
    final hasError = _errorMessage != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 48,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: AppRadius.buttonRadius,
        // Filled state gradient
        gradient: hasValue
            ? LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.20),
                  AppColors.primary.withValues(alpha: 0.10),
                ],
              )
            : null,
        // Empty state color
        color: hasValue ? null : Colors.white.withValues(alpha: 0.05),
        // Border color based on state
        border: Border.all(
          color: hasError
              ? AppColors.error
              : isFocused
                  ? AppColors.primary
                  : hasValue
                      ? AppColors.primary.withValues(alpha: 0.50)
                      : Colors.white.withValues(alpha: 0.15),
          width: isFocused || hasValue ? 2 : 1,
        ),
        // Glow shadow based on state
        boxShadow: isFocused && !hasError
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.40),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ]
            : hasValue && !hasError
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.20),
                      blurRadius: 8,
                    ),
                  ]
                : null,
      ),
      child: TextField(
        controller: _controllers[index],
        focusNode: _focusNodes[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
        style: AppTextStyles.headlineSmall.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
        decoration: const InputDecoration(
          border: InputBorder.none,
          counterText: '',
          contentPadding: EdgeInsets.zero,
        ),
        onChanged: (value) => _onDigitChanged(index, value),
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
  // VERIFY BUTTON
  // ══════════════════════════════════════════

  Widget _buildVerifyButton() {
    return GestureDetector(
      onTap: _isLoading ? null : _handleVerify,
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
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'Verify Code',
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
  // RESEND SECTION
  // ══════════════════════════════════════════

  Widget _buildResendSection() {
    return Center(
      child: _canResend
          // Resend button (enabled)
          ? GestureDetector(
              onTap: _isLoading ? null : _handleResend,
              child: ClipRRect(
                borderRadius: AppRadius.pillRadius,
                child: BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: 15,
                    sigmaY: 15,
                  ),
                  child: Container(
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
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.refresh_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Resend Code',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          // Timer countdown
          : Column(
              children: [
                Text(
                  'Resend code in',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.15),
                    borderRadius: AppRadius.pillRadius,
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.30),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _formattedTime,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ══════════════════════════════════════════
  // HELP INFO CARD
  // ══════════════════════════════════════════

  Widget _buildHelpInfoCard() {
    return ClipRRect(
      borderRadius: AppRadius.cardRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.06),
                Colors.white.withValues(alpha: 0.02),
              ],
            ),
            borderRadius: AppRadius.cardRadius,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.15),
                  borderRadius: AppRadius.buttonRadius,
                ),
                child: const Icon(
                  Icons.lightbulb_outline,
                  color: AppColors.info,
                  size: AppIconSizes.sm,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Can\'t find the email?',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs2),
                    Text(
                      'Check your spam folder or make sure you entered the correct email address.',
                      style: AppTextStyles.labelSmall.copyWith(
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
    );
  }

  // ══════════════════════════════════════════
  // CHANGE EMAIL LINK
  // ══════════════════════════════════════════

  Widget _buildChangeEmailLink() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        context.go(AppRoutes.login);
      },
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
          children: [
            const TextSpan(text: 'Wrong email? '),
            TextSpan(
              text: 'Change it',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // SUCCESS ICON
  // ══════════════════════════════════════════

  Widget _buildSuccessIcon() {
    return Container(
      width: 140,
      height: 140,
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
            blurRadius: 50,
            spreadRadius: 10,
          ),
          BoxShadow(
            color: AppColors.success.withValues(alpha: 0.30),
            blurRadius: 100,
            spreadRadius: 20,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [
                AppColors.success,
                AppColors.success.withValues(alpha: 0.70),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.success.withValues(alpha: 0.60),
                blurRadius: 30,
              ),
            ],
          ),
          child: const Icon(
            Icons.check_rounded,
            color: Colors.white,
            size: 60,
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // SUCCESS TEXT
  // ══════════════════════════════════════════

  Widget _buildSuccessText() {
    return Column(
      children: [
        // Gradient "Verified!" text
        ShaderMask(
          shaderCallback: (bounds) => LinearGradient(
            colors: [
              AppColors.success,
              AppColors.success.withValues(alpha: 0.70),
            ],
          ).createShader(bounds),
          child: Text(
            'Verified!',
            style: AppTextStyles.displaySmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 40,
              letterSpacing: -1,
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // Description
        Text(
          'Your account has been\nsuccessfully verified',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ══════════════════════════════════════════
  // LOADING INDICATOR (Success state)
  // ══════════════════════════════════════════

  Widget _buildLoadingIndicator() {
    return Column(
      children: [
        Text(
          'Setting up your profile...',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColors.success,
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// FLOATING PARTICLE PAINTER
// ============================================================

class _OtpParticlePainter extends CustomPainter {
  final double animationValue;
  final bool isSuccess;

  _OtpParticlePainter({
    required this.animationValue,
    required this.isSuccess,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(33);

    // Draw 22 floating particles
    for (int i = 0; i < 22; i++) {
      final baseX = random.nextDouble() * size.width;
      final baseY = random.nextDouble() * size.height;

      // Smooth floating motion using sin wave
      final offset = math.sin(
        (animationValue * 2 * math.pi) + i,
      );

      final x = baseX + (offset * 25);
      final y = baseY + (offset * 35);

      // Particle size varies
      final particleSize = 1.5 + random.nextDouble() * 2;

      // Color: alternate between gold and emerald/success
      final isGold = i % 3 == 0;
      final color = isSuccess
          ? (isGold ? AppColors.accent : AppColors.success)
          : (isGold ? AppColors.accent : AppColors.primary);

      // Random opacity for depth
      final alpha = 0.15 + (random.nextDouble() * 0.25);

      // Draw solid particle
      final paint = Paint()
        ..color = color.withValues(alpha: alpha)
        ..style = PaintingStyle.fill;

      canvas.drawCircle(
        Offset(x, y),
        particleSize,
        paint,
      );

      // Draw glow around particle
      final glowPaint = Paint()
        ..color = color.withValues(alpha: alpha * 0.3)
        ..style = PaintingStyle.fill
        ..maskFilter = const MaskFilter.blur(
          BlurStyle.normal,
          10,
        );

      canvas.drawCircle(
        Offset(x, y),
        particleSize * 4,
        glowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(
    covariant _OtpParticlePainter oldDelegate,
  ) =>
      oldDelegate.animationValue != animationValue ||
      oldDelegate.isSuccess != isSuccess;
}
