// lib/features/auth/presentation/forgot_password_screen.dart

// ============================================================
// QIBRA AI — FORGOT PASSWORD SCREEN
// Version: 1.0.0
// Description: Password reset flow with email verification.
//              Simple, focused UI with success state.
// ============================================================

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
// FORGOT PASSWORD SCREEN WIDGET
// ============================================================

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  // ── FORM KEY ─────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();

  // ── CONTROLLERS ──────────────────────────────────────
  final _emailController = TextEditingController();
  final _emailFocus = FocusNode();

  // ── STATE ────────────────────────────────────────────
  bool _isLoading = false;
  bool _emailSent = false;
  String? _errorMessage;
  String? _sentEmail;

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocus.dispose();
    super.dispose();
  }

  // ── EMAIL VALIDATOR ──────────────────────────────────
  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return AppValidation.errorRequired;
    }
    if (!AppValidation.emailRegex.hasMatch(value)) {
      return AppValidation.errorEmail;
    }
    return null;
  }

  // ── SEND RESET LINK HANDLER ──────────────────────────
  Future<void> _handleSendResetLink() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Simulate API call
      // Real app mein: await ref.read(apiServiceProvider).forgotPassword(...)
      await Future.delayed(const Duration(seconds: 2));

      final email = _emailController.text.trim();

      setState(() {
        _isLoading = false;
        _emailSent = true;
        _sentEmail = email;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to send reset link. Please try again.';
      });
    }
  }

  // ── RESEND HANDLER ───────────────────────────────────
  Future<void> _handleResend() async {
    setState(() {
      _emailSent = false;
      _errorMessage = null;
    });
    await _handleSendResetLink();
  }

  // ── OPEN EMAIL APP HANDLER ───────────────────────────
  void _handleOpenEmail() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Opening email app...'),
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
            child: _emailSent ? _buildSuccessState() : _buildFormState(),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // FORM STATE — Email input
  // ══════════════════════════════════════════

  Widget _buildFormState() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.md),

          // ── HEADER ─────────────────────────────────
          _buildHeader(),

          const SizedBox(height: AppSpacing.xl4),

          // ── ERROR BANNER ───────────────────────────
          if (_errorMessage != null) ...[
            _buildErrorBanner(_errorMessage!),
            const SizedBox(height: AppSpacing.lg),
          ],

          // ── EMAIL FIELD ────────────────────────────
          AppTextField(
            controller: _emailController,
            focusNode: _emailFocus,
            label: 'Email Address',
            hint: 'you@example.com',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            validator: _validateEmail,
            enabled: !_isLoading,
            helperText: 'We\'ll send a password reset link to this email',
            onSubmitted: (_) => _handleSendResetLink(),
          ),

          const SizedBox(height: AppSpacing.xl2),

          // ── SEND BUTTON ────────────────────────────
          AppPrimaryButton(
            label: 'Send Reset Link',
            prefixIcon: Icons.send_outlined,
            isLoading: _isLoading,
            onPressed: _isLoading ? null : _handleSendResetLink,
          ),

          const SizedBox(height: AppSpacing.xl3),

          // ── BACK TO LOGIN LINK ─────────────────────
          _buildBackToLoginLink(),

          const SizedBox(height: AppSpacing.xl2),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // SUCCESS STATE — Email sent confirmation
  // ══════════════════════════════════════════

  Widget _buildSuccessState() {
    return Column(
      key: const ValueKey('success'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: AppSpacing.xl3),

        // ── SUCCESS ICON ───────────────────────────
        Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.success.withValues(alpha: 0.15),
              border: Border.all(
                color: AppColors.success,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.success.withValues(alpha: 0.30),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(
              Icons.mark_email_read_outlined,
              color: AppColors.success,
              size: 48,
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.xl3),

        // ── SUCCESS HEADING ────────────────────────
        Text(
          'Check Your Email',
          style: AppTextStyles.headlineLarge.copyWith(
            fontWeight: FontWeight.w800,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: AppSpacing.md),

        // ── SUCCESS MESSAGE ────────────────────────
        Text(
          'We\'ve sent a password reset link to',
          style: AppTextStyles.bodyMedium.secondary,
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: AppSpacing.xs),

        // ── EMAIL ADDRESS ──────────────────────────
        Text(
          _sentEmail ?? '',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: AppSpacing.xl2),

        // ── INFO CARD ──────────────────────────────
        _buildInfoCard(),

        const SizedBox(height: AppSpacing.xl2),

        // ── OPEN EMAIL BUTTON ──────────────────────
        AppPrimaryButton(
          label: 'Open Email App',
          prefixIcon: Icons.email_outlined,
          onPressed: _handleOpenEmail,
        ),

        const SizedBox(height: AppSpacing.md),

        // ── RESEND BUTTON ──────────────────────────
        AppSecondaryButton(
          label: 'Resend Link',
          prefixIcon: Icons.refresh,
          isLoading: _isLoading,
          onPressed: _isLoading ? null : _handleResend,
        ),

        const SizedBox(height: AppSpacing.xl3),

        // ── BACK TO LOGIN ──────────────────────────
        _buildBackToLoginLink(),

        const SizedBox(height: AppSpacing.xl2),
      ],
    );
  }

  // ══════════════════════════════════════════
  // HEADER — Icon + Title + Subtitle
  // ══════════════════════════════════════════

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon container
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: AppGradients.emerald,
            shape: BoxShape.circle,
            boxShadow: AppShadows.emeraldGlow,
          ),
          child: const Icon(
            Icons.lock_reset,
            color: AppColors.white,
            size: 32,
          ),
        ),

        const SizedBox(height: AppSpacing.xl2),

        // Small tag
        Text(
          'PASSWORD RECOVERY',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.primary,
            letterSpacing: 2,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: AppSpacing.xs),

        // Heading
        Text(
          'Forgot Password?',
          style: AppTextStyles.headlineLarge.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        // Description
        Text(
          'No worries! Enter your email address and we\'ll send you instructions to reset your password.',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
            height: 1.6,
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
  // INFO CARD — Instructions
  // ══════════════════════════════════════════

  Widget _buildInfoCard() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: AppColors.accent,
                size: AppIconSizes.md,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'What\'s Next?',
                style: AppTextStyles.labelLarge.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Instructions
          _buildInstructionItem(
            number: '1',
            text: 'Check your email inbox (and spam folder)',
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildInstructionItem(
            number: '2',
            text: 'Click the reset link in the email',
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildInstructionItem(
            number: '3',
            text: 'Create your new password',
          ),

          const SizedBox(height: AppSpacing.md),

          // Note
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.10),
              borderRadius: AppRadius.buttonRadius,
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.30),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.access_time,
                  color: AppColors.warning,
                  size: AppIconSizes.sm,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Link expires in 15 minutes',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── SINGLE INSTRUCTION ITEM ──────────────────────────

  Widget _buildInstructionItem({
    required String number,
    required String text,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Number badge
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.30),
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        // Text
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
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
    return Center(
      child: GestureDetector(
        onTap: () => context.go(AppRoutes.login),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.arrow_back,
              color: AppColors.primary,
              size: AppIconSizes.sm,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Back to Login',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
