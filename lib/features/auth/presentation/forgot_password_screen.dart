// lib/features/auth/presentation/forgot_password_screen.dart

// ============================================================
// QIBRA AI — PREMIUM FORGOT PASSWORD SCREEN (Phase 2)
// Version: 2.0.0
// Description: Apple-quality forgot password with glassmorphism,
//              animated illustrations, and premium success state.
// ============================================================


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
import 'package:qibra_ai/features/auth/presentation/widgets/auth_text_field.dart';

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
  late AnimationController _entranceController;
  late Animation<double> _entranceFade;


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
    _entranceController.dispose();
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

      if (!mounted) return;
      final email = _emailController.text.trim();

      setState(() {
        _isLoading = false;
        _emailSent = true;
        _sentEmail = email;
      });

      HapticFeedback.heavyImpact();
      _successController.forward();
    } catch (e) {
      if (!mounted) return;
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
    final colors = QibraColors.of(context);
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.mail_rounded,
              color: colors.textPrimary,
              size: 20,
            ),
            SizedBox(width: AppSpacing.sm),
            Text('Opening email app...'),
          ],
        ),
        backgroundColor: colors.primary,
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
      body: Stack(
        children: [
          // ── LAYER 1: Background ──
          _buildBackground(),

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
    final colors = QibraColors.of(context);
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: _emailSent ? colors.cardMuted : colors.background,
        ),
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
    return AuthHeader(
      onBackTap: () => context.go(AppRoutes.login),
    );
  }

  // ══════════════════════════════════════════
  // ANIMATED ICON (Form state)
  // ══════════════════════════════════════════

  Widget _buildAnimatedIcon() {
    final colors = QibraColors.of(context);
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.card,
        border: Border.all(
          color: colors.primary.withValues(alpha: 0.24),
          width: 2,
        ),
      ),
      child: Icon(
        Icons.lock_reset_rounded,
        color: colors.primary,
        size: 48,
      ),
    );
  }

  // ══════════════════════════════════════════
  // SUCCESS ICON
  // ══════════════════════════════════════════

  Widget _buildSuccessIcon() {
    final colors = QibraColors.of(context);
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.success.withValues(alpha: 0.12),
      ),
      child: Center(
        child: Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colors.success,
          ),
          child: Icon(
            Icons.mark_email_read_rounded,
            color: colors.onPrimary,
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
    final colors = QibraColors.of(context);
    return Column(
      children: [
        Text(
          'PASSWORD RECOVERY',
          style: AppTextStyles.labelSmall.copyWith(
            color: colors.goldText,
            letterSpacing: 3,
            fontWeight: FontWeight.w800,
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
              color: colors.textSecondary,
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
    final colors = QibraColors.of(context);
    return Column(
      children: [
        Text(
          'Check Your Email',
          style: AppTextStyles.displaySmall.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 32,
            color: colors.success,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'We\'ve sent a password reset link to',
          style: AppTextStyles.bodyMedium.copyWith(
            color: colors.textSecondary,
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
            color: colors.primary.withValues(alpha: 0.12),
            borderRadius: AppRadius.pillRadius,
            border: Border.all(
              color: colors.primary.withValues(alpha: 0.16),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.mail_outline_rounded,
                color: colors.primary,
                size: 16,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                _sentEmail ?? '',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: colors.primary,
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
                  Icon(
                    Icons.info_outline_rounded,
                    color: colors.textTertiary,
                    size: 14,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      'We\'ll send a password reset link to this email',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: colors.textTertiary,
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
  // PREMIUM TEXT FIELD
  // ══════════════════════════════════════════

  Widget _buildPremiumTextField() {
    return AuthTextField(
      controller: _emailController,
      focusNode: _emailFocus,
      label: 'Email Address',
      hint: 'you@example.com',
      validator: _validateEmail,
      isFocused: _isEmailFocused,
      enabled: !_isLoading,
      prefixIcon: Icons.mail_outline_rounded,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _handleSendResetLink(),
    );
  }

  // ══════════════════════════════════════════
  // SEND BUTTON
  // ══════════════════════════════════════════

  Widget _buildSendButton() {
    return AuthButton(
      label: 'Send Reset Link',
      onTap: _handleSendResetLink,
      isLoading: _isLoading,
      leadingIcon: Icons.send_rounded,
    );
  }

  // ══════════════════════════════════════════
  // INFO CARD (Success state)
  // ══════════════════════════════════════════

  Widget _buildInfoCard() {
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.accent.withValues(alpha: 0.12),
                      border: Border.all(
                        color: colors.accent.withValues(alpha: 0.16),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      Icons.checklist_rounded,
                      color: colors.accent,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'NEXT STEPS',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: colors.accent,
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
                  color: colors.accent.withValues(alpha: 0.12),
                  borderRadius: AppRadius.buttonRadius,
                  border: Border.all(
                    color: colors.accent.withValues(alpha: 0.16),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      color: colors.accent,
                      size: 16,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Link expires in 15 minutes',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: colors.accent,
                          fontWeight: FontWeight.w700,
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

  // ══════════════════════════════════════════
  // STEP ITEM
  // ══════════════════════════════════════════

  Widget _buildStepItem(int number, String text) {
    final colors = QibraColors.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: colors.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(
              color: colors.primary.withValues(alpha: 0.24),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              '$number',
              style: AppTextStyles.labelSmall.copyWith(
                color: colors.primary,
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
                color: colors.textSecondary,
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
    final colors = QibraColors.of(context);
    return Column(
      children: [
        // Open Email button
        GestureDetector(
          onTap: _handleOpenEmail,
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: colors.primary,
              borderRadius: AppRadius.buttonRadiusLg,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.mail_rounded,
                  color: colors.onPrimary,
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Open Email App',
                  style: AppTextStyles.buttonLarge.copyWith(
                    color: colors.onPrimary,
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
          child: Container(
            width: double.infinity,
            height: 56,
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: AppRadius.buttonRadiusLg,
              border: Border.all(
                color: colors.accent.withValues(alpha: 0.16),
                width: 1.5,
              ),
            ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (_isLoading)
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colors.accent,
                          ),
                        ),
                      )
                    else
                      Icon(
                        Icons.refresh_rounded,
                        color: colors.accent,
                        size: 20,
                      ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      _isLoading ? 'Sending...' : 'Resend Link',
                      style: AppTextStyles.buttonMedium.copyWith(
                        color: colors.accent,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
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
  // BACK TO LOGIN LINK
  // ══════════════════════════════════════════

  Widget _buildBackToLoginLink() {
    final colors = QibraColors.of(context);
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        context.go(AppRoutes.login);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.arrow_back_rounded,
            color: colors.primary,
            size: 16,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'Back to Login',
            style: AppTextStyles.bodyMedium.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
