// lib/features/auth/presentation/verify_otp_screen.dart

// ============================================================
// QIBRA AI — VERIFY OTP SCREEN
// Version: 1.0.0
// Description: 6-digit OTP verification with countdown timer,
//              auto-submit, and resend functionality.
// ============================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qibra_ai/core/constants/app_constants.dart';
import 'package:qibra_ai/core/design_system/app_colors.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';
import 'package:qibra_ai/shared/widgets/buttons/app_button.dart';
import 'package:qibra_ai/shared/widgets/inputs/app_text_field.dart';

// ============================================================
// VERIFY OTP SCREEN WIDGET
// ============================================================

class VerifyOtpScreen extends ConsumerStatefulWidget {
  /// Email address jahan OTP bheja gaya
  final String? email;

  const VerifyOtpScreen({
    super.key,
    this.email,
  });

  @override
  ConsumerState<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends ConsumerState<VerifyOtpScreen> {
  // ── STATE ────────────────────────────────────────────
  String _otp = '';
  bool _isLoading = false;
  bool _isVerified = false;
  String? _errorMessage;

  // ── TIMER STATE ──────────────────────────────────────
  Timer? _timer;
  int _remainingSeconds = 60;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  // ── START COUNTDOWN TIMER ────────────────────────────
  void _startTimer() {
    _remainingSeconds = 60;
    _canResend = false;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        // Timer complete — resend enable karo
        timer.cancel();
        setState(() => _canResend = true);
      }
    });
  }

  // ── OTP CHANGE HANDLER ───────────────────────────────
  void _onOtpChanged(String otp) {
    setState(() {
      _otp = otp;
      _errorMessage = null; // Clear error on change
    });
  }

  // ── OTP COMPLETED HANDLER (Auto-submit) ──────────────
  Future<void> _onOtpCompleted(String otp) async {
    setState(() => _otp = otp);
    // Auto-submit jab 6 digits complete ho
    await _handleVerify();
  }

  // ── VERIFY HANDLER ───────────────────────────────────
  Future<void> _handleVerify() async {
    // Validation
    if (_otp.length != AppValidation.otpLength) {
      setState(() {
        _errorMessage = 'Please enter all 6 digits';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Simulate API call
      // Real app mein: await ref.read(apiServiceProvider).verifyOtp(...)
      await Future.delayed(const Duration(seconds: 2));

      // Simulated validation — 123456 is valid
      if (_otp == '123456') {
        setState(() {
          _isLoading = false;
          _isVerified = true;
        });

        // Success animation dikhao 1.5 sec
        await Future.delayed(const Duration(milliseconds: 1500));

        // Navigate to home after success
        if (mounted) {
          context.go(AppRoutes.home);
        }
      } else {
        // Invalid OTP
        setState(() {
          _isLoading = false;
          _errorMessage = 'Invalid OTP. Please check and try again.';
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Verification failed. Please try again.';
      });
    }
  }

  // ── RESEND HANDLER ───────────────────────────────────
  Future<void> _handleResend() async {
    if (!_canResend) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
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
                Icon(Icons.check_circle, color: AppColors.white, size: 20),
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

  // ── TIMER DISPLAY FORMAT ─────────────────────────────
  String get _formattedTime {
    final minutes = (_remainingSeconds ~/ 60).toString();
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    // Use provided email or fallback
    final displayEmail = widget.email ?? 'your email';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.login),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: AnimatedSwitcher(
            duration: AppDurations.medium,
            child: _isVerified
                ? _buildSuccessState()
                : _buildVerifyState(displayEmail),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // VERIFY STATE — OTP Input
  // ══════════════════════════════════════════

  Widget _buildVerifyState(String displayEmail) {
    return Column(
      key: const ValueKey('verify'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: AppSpacing.md),

        // ── HEADER ─────────────────────────────────
        _buildHeader(displayEmail),

        const SizedBox(height: AppSpacing.xl4),

        // ── ERROR BANNER ───────────────────────────
        if (_errorMessage != null) ...[
          _buildErrorBanner(_errorMessage!),
          const SizedBox(height: AppSpacing.lg),
        ],

        // ── OTP INPUT ──────────────────────────────
        Center(
          child: AppOtpField(
            otpLength: AppValidation.otpLength,
            onChanged: _onOtpChanged,
            onCompleted: _onOtpCompleted,
            errorText: _errorMessage,
          ),
        ),

        const SizedBox(height: AppSpacing.xl2),

        // ── TIMER + RESEND ─────────────────────────
        _buildTimerAndResend(),

        const SizedBox(height: AppSpacing.xl3),

        // ── VERIFY BUTTON ──────────────────────────
        AppPrimaryButton(
          label: 'Verify OTP',
          prefixIcon: Icons.verified_outlined,
          isLoading: _isLoading,
          onPressed: _isLoading ? null : _handleVerify,
        ),

        const SizedBox(height: AppSpacing.xl2),

        // ── HELP INFO ──────────────────────────────
        _buildHelpInfo(),

        const SizedBox(height: AppSpacing.xl2),

        // ── CHANGE EMAIL LINK ──────────────────────
        _buildChangeEmailLink(),

        const SizedBox(height: AppSpacing.xl2),
      ],
    );
  }

  // ══════════════════════════════════════════
  // SUCCESS STATE — Verified confirmation
  // ══════════════════════════════════════════

  Widget _buildSuccessState() {
    return Column(
      key: const ValueKey('success'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xl6),

        // ── SUCCESS ICON ───────────────────────────
        Center(
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 600),
            tween: Tween(begin: 0.0, end: 1.0),
            curve: Curves.easeOutBack,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.success.withValues(alpha: 0.20),
                        AppColors.success.withValues(alpha: 0.05),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.success.withValues(alpha: 0.40),
                        blurRadius: 30,
                        spreadRadius: 6,
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
                            color: AppColors.success.withValues(alpha: 0.50),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: AppColors.white,
                        size: 56,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: AppSpacing.xl3),

        // ── SUCCESS HEADING ────────────────────────
        Text(
          'Verified!',
          style: AppTextStyles.displaySmall.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.success,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: AppSpacing.md),

        // ── SUCCESS MESSAGE ────────────────────────
        Text(
          'Your account has been successfully verified',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: AppSpacing.lg),

        // ── LOADING TEXT ───────────────────────────
        Text(
          'Redirecting to home...',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textTertiary,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: AppSpacing.xl3),

        // ── LOADING INDICATOR ──────────────────────
        const Center(
          child: SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.success,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════
  // HEADER
  // ══════════════════════════════════════════

  Widget _buildHeader(String displayEmail) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon container
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: AppGradients.gold,
            shape: BoxShape.circle,
            boxShadow: AppShadows.goldGlow,
          ),
          child: const Icon(
            Icons.security_outlined,
            color: AppColors.background,
            size: 32,
          ),
        ),

        const SizedBox(height: AppSpacing.xl2),

        // Small tag
        Text(
          'VERIFICATION',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.accent,
            letterSpacing: 2,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: AppSpacing.xs),

        // Heading
        Text(
          'Verify OTP',
          style: AppTextStyles.headlineLarge.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // Description with email
        RichText(
          text: TextSpan(
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
            children: [
              const TextSpan(
                text: 'We\'ve sent a 6-digit code to ',
              ),
              TextSpan(
                text: displayEmail,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const TextSpan(
                text: '. Please enter the code below to verify your account.',
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════
  // ERROR BANNER
  // ══════════════════════════════════════════

  Widget _buildErrorBanner(String message) {
    return Container(
      width: double.infinity,
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.10),
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.40),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            color: AppColors.error,
            size: AppIconSizes.md,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // TIMER + RESEND SECTION
  // ══════════════════════════════════════════

  Widget _buildTimerAndResend() {
    return Center(
      child: _canResend
          // Resend enabled state
          ? Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Didn\'t receive the code? ',
                  style: AppTextStyles.bodyMedium.secondary,
                ),
                GestureDetector(
                  onTap: _isLoading ? null : _handleResend,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.refresh,
                        color: AppColors.primary,
                        size: AppIconSizes.sm,
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Resend OTP',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          // Timer active state
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.access_time,
                  color: AppColors.textTertiary,
                  size: AppIconSizes.sm,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Resend OTP in ',
                  style: AppTextStyles.bodyMedium.secondary,
                ),
                // Time badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: AppRadius.pillRadius,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.30),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _formattedTime,
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
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

  Widget _buildHelpInfo() {
    return Container(
      padding: AppSpacing.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color: AppColors.borderSubtle,
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
    );
  }

  // ══════════════════════════════════════════
  // CHANGE EMAIL LINK
  // ══════════════════════════════════════════

  Widget _buildChangeEmailLink() {
    return Center(
      child: GestureDetector(
        onTap: () => context.go(AppRoutes.login),
        child: RichText(
          text: TextSpan(
            style: AppTextStyles.bodyMedium.secondary,
            children: const [
              TextSpan(text: 'Wrong email? '),
              TextSpan(
                text: 'Change it',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
