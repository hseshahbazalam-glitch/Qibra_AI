// lib/features/auth/presentation/verify_otp_screen.dart

// ============================================================
// QIBRA AI — PREMIUM OTP VERIFICATION (Phase 2)
// Version: 2.0.0
// Description: Apple-quality OTP with progress ring,
//              auto-submit, premium animations.
// ============================================================

import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qibra_ai/core/constants/app_constants.dart';
import 'package:qibra_ai/core/design_system/qibra_colors.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';
import 'package:qibra_ai/features/auth/presentation/widgets/auth_button.dart';
import 'package:qibra_ai/features/auth/presentation/widgets/auth_header.dart';

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
  // Phase 1 Security: OTP is backend-gated. When isBackendEnabled==false, OTP is not available; guide to Guest.
  Future<void> _handleVerify() async {
    final colors = QibraColors.of(context);
    // Validate OTP length
    if (_currentOtp.length != 6) {
      HapticFeedback.heavyImpact();
      setState(() => _errorMessage = 'Please enter all 6 digits');
      return;
    }

    // Backend gate — do not accept demo OTP in production without backend
    if (!AppApi.isBackendEnabled) {
      HapticFeedback.heavyImpact();
      setState(() => _errorMessage =
          'OTP verification not available in this build — please continue as Guest (backend not configured).');
      // Also show guest guidance: after short delay, allow navigation to home
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  'Guest mode: Your Quran, Prayer, and Duas work fully offline.'),
              backgroundColor: colors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: AppRadius.cardRadius),
            ),
          );
        }
      });
      return;
    }

    HapticFeedback.mediumImpact();

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Phase 4 P1: OTP verification via backend when enabled, no demo bypass in production.
      // When isBackendEnabled is true, this would be: POST AppApi.endpointVerifyOtp via ApiClient.
      // Since backend is currently unavailable (isBackendEnabled false), the guard above already returned.
      // For isBackendEnabled true builds, we attempt backend but never accept hard-coded 123456 in release.
      if (AppApi.isBackendEnabled) {
        // Backend path — would call ApiClient.instance.post(AppApi.endpointVerifyOtp, data: {email: widget.email, otp: _currentOtp})
        // For this build, backend is still proxied; simulate failure if no real backend response
        // To avoid fake success, we do not accept demo OTP in production code path.
        // For now, show not implemented and treat as failure (tests should mock backend)
        await Future.delayed(const Duration(milliseconds: 500));
        throw Exception('OTP backend not yet implemented in this build');
      }

      // Fallback: should not be reached when isBackendEnabled false (already returned above)
      // Keep demo OTP only for debug local testing when explicitly allowed via kDebugMode and test flag
      // In release, this branch will not execute due to earlier guard
      if (kDebugMode && _currentOtp == '123456') {
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
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Verification failed. Please try again.';
      });
    }
  }

  // ── RESEND OTP HANDLER ───────────────────────────────
  Future<void> _handleResend() async {
    final colors = QibraColors.of(context);
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

      if (!mounted) return;
      // Restart timer
      _startTimer();

      setState(() => _isLoading = false);

      // Show success snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: colors.textPrimary,
                size: 20,
              ),
              SizedBox(width: AppSpacing.sm),
              Text('OTP sent successfully!'),
            ],
          ),
          backgroundColor: colors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.cardRadius,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
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
    final displayEmail = widget.email ?? 'your email';

    return Scaffold(
      body: Stack(
        children: [
          // Layer 1: Animated background
          _buildBackground(),

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
    final colors = QibraColors.of(context);
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: _isVerified ? colors.cardMuted : colors.background,
        ),
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
    return AuthHeader(
      onBackTap: () => context.go(AppRoutes.login),
      stepNumber: 2,
      totalSteps: 3,
      stepLabel: 'Verify',
    );
  }

  // ══════════════════════════════════════════
  // TIMER ICON (Pulsing + Progress Ring)
  // ══════════════════════════════════════════

  Widget _buildTimerIcon() {
    final colors = QibraColors.of(context);
    return SizedBox(
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
              backgroundColor: colors.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                _canResend ? colors.success : colors.accent,
              ),
            ),
          ),

          // Inner icon circle
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.card,
              border: Border.all(
                color: colors.accent.withValues(alpha: 0.24),
                width: 2,
              ),
            ),
            child: Icon(
              Icons.security_rounded,
              color: colors.accent,
              size: 48,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // TITLE SECTION
  // ══════════════════════════════════════════

  Widget _buildTitle(String displayEmail) {
    final colors = QibraColors.of(context);
    return Column(
      children: [
        // VERIFICATION label
        Text(
          'VERIFICATION',
          style: AppTextStyles.labelSmall.copyWith(
            color: colors.goldText,
            letterSpacing: 3,
            fontWeight: FontWeight.w800,
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
                color: colors.textSecondary,
                height: 1.6,
              ),
              children: [
                const TextSpan(
                  text: 'We sent a 6-digit code to ',
                ),
                TextSpan(
                  text: displayEmail,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: colors.accent,
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
    final colors = QibraColors.of(context);
    return Container(
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: AppRadius.cardRadiusLarge,
            border: Border.all(
              color: colors.border,
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
    final colors = QibraColors.of(context);
    final hasValue = _controllers[index].text.isNotEmpty;
    final isFocused = _isFocused[index];
    final hasError = _errorMessage != null;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 48,
      height: 56,
      decoration: BoxDecoration(
        // Filled state wash
        color: hasValue
            ? colors.primary.withValues(alpha: 0.12)
            : colors.cardMuted,
        borderRadius: AppRadius.buttonRadius,
        // Border color based on state
        border: Border.all(
          color: hasError
              ? colors.error
              : isFocused || hasValue
                  ? colors.primary
                  : colors.border,
          width: isFocused || hasValue ? 2 : 1,
        ),
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
          color: colors.textPrimary,
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
    final colors = QibraColors.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.error.withValues(alpha: 0.12),
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color: colors.error.withValues(alpha: 0.24),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: colors.error.withValues(alpha: 0.16),
              borderRadius: AppRadius.pillRadius,
            ),
            child: Icon(
              Icons.error_outline_rounded,
              color: colors.error,
              size: 16,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: colors.error,
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
    return AuthButton(
      label: 'Verify Code',
      onTap: _handleVerify,
      isLoading: _isLoading,
      leadingIcon: Icons.check_circle_outline_rounded,
    );
  }

  // ══════════════════════════════════════════
  // RESEND SECTION
  // ══════════════════════════════════════════

  Widget _buildResendSection() {
    final colors = QibraColors.of(context);
    return Center(
      child: _canResend
          // Resend button (enabled)
          ? GestureDetector(
              onTap: _isLoading ? null : _handleResend,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.12),
                  borderRadius: AppRadius.pillRadius,
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.16),
                    width: 1.5,
                  ),
                ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.refresh_rounded,
                          color: colors.primary,
                          size: 18,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          'Resend Code',
                          style: AppTextStyles.labelLarge.copyWith(
                            color: colors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
          // Timer countdown
          : Column(
              children: [
                Text(
                  'Resend code in',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colors.accent.withValues(alpha: 0.15),
                    borderRadius: AppRadius.pillRadius,
                    border: Border.all(
                      color: colors.accent.withValues(alpha: 0.16),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _formattedTime,
                    style: AppTextStyles.titleMedium.copyWith(
                      color: colors.accent,
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
    final colors = QibraColors.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color: colors.border,
          width: 1,
        ),
      ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppSpacing.xs),
                decoration: BoxDecoration(
                  color: colors.info.withValues(alpha: 0.15),
                  borderRadius: AppRadius.buttonRadius,
                ),
                child: Icon(
                  Icons.lightbulb_outline,
                  color: colors.info,
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
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs2),
                    Text(
                      'Check your spam folder or make sure you entered the correct email address.',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: colors.textSecondary,
                        height: 1.4,
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
  // CHANGE EMAIL LINK
  // ══════════════════════════════════════════

  Widget _buildChangeEmailLink() {
    final colors = QibraColors.of(context);
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        context.go(AppRoutes.login);
      },
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: AppTextStyles.bodyMedium.copyWith(
            color: colors.textSecondary,
          ),
          children: [
            const TextSpan(text: 'Wrong email? '),
            TextSpan(
              text: 'Change it',
              style: AppTextStyles.bodyMedium.copyWith(
                color: colors.primary,
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
    final colors = QibraColors.of(context);
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.success.withValues(alpha: 0.12),
      ),
      child: Center(
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.success,
          ),
          child: Icon(
            Icons.check_rounded,
            color: colors.onPrimary,
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
    final colors = QibraColors.of(context);
    return Column(
      children: [
        // Verified! text
        Text(
          'Verified!',
          style: AppTextStyles.displaySmall.copyWith(
            color: colors.success,
            fontWeight: FontWeight.w900,
            fontSize: 40,
            letterSpacing: -1,
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // Description
        Text(
          'Your account has been\nsuccessfully verified',
          style: AppTextStyles.bodyLarge.copyWith(
            color: colors.textSecondary,
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
    final colors = QibraColors.of(context);
    return Column(
      children: [
        Text(
          'Setting up your profile...',
          style: AppTextStyles.bodySmall.copyWith(
            color: colors.textTertiary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 3,
            valueColor: AlwaysStoppedAnimation<Color>(
              colors.success,
            ),
          ),
        ),
      ],
    );
  }
}
