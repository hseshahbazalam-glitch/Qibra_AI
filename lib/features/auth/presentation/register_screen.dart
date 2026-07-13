// lib/features/auth/presentation/register_screen.dart

// ============================================================
// QIBRA AI — REGISTER SCREEN
// Version: 1.0.0
// Description: New user registration with validation,
//              password strength, and terms acceptance.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qibra_ai/core/constants/app_constants.dart';
import 'package:qibra_ai/core/design_system/app_colors.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';
import 'package:qibra_ai/core/providers/auth_provider.dart';
import 'package:qibra_ai/shared/widgets/buttons/app_button.dart';
import 'package:qibra_ai/shared/widgets/inputs/app_text_field.dart';

// ============================================================
// PASSWORD STRENGTH ENUM
// ============================================================

enum _PasswordStrength {
  none,
  weak,
  fair,
  good,
  strong;

  Color get color {
    switch (this) {
      case _PasswordStrength.none:
        return AppColors.borderStandard;
      case _PasswordStrength.weak:
        return AppColors.error;
      case _PasswordStrength.fair:
        return AppColors.warning;
      case _PasswordStrength.good:
        return AppColors.info;
      case _PasswordStrength.strong:
        return AppColors.success;
    }
  }

  String get label {
    switch (this) {
      case _PasswordStrength.none:
        return '';
      case _PasswordStrength.weak:
        return 'Weak';
      case _PasswordStrength.fair:
        return 'Fair';
      case _PasswordStrength.good:
        return 'Good';
      case _PasswordStrength.strong:
        return 'Strong';
    }
  }

  double get percentage {
    switch (this) {
      case _PasswordStrength.none:
        return 0.0;
      case _PasswordStrength.weak:
        return 0.25;
      case _PasswordStrength.fair:
        return 0.50;
      case _PasswordStrength.good:
        return 0.75;
      case _PasswordStrength.strong:
        return 1.0;
    }
  }
}

// ============================================================
// REGISTER SCREEN WIDGET
// ============================================================

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  // ── FORM KEY ─────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();

  // ── CONTROLLERS ──────────────────────────────────────
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // ── FOCUS NODES ──────────────────────────────────────
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  // ── STATE ────────────────────────────────────────────
  bool _acceptedTerms = false;
  _PasswordStrength _passwordStrength = _PasswordStrength.none;

  @override
  void initState() {
    super.initState();
    // Password change hone par strength calculate karo
    _passwordController.addListener(_updatePasswordStrength);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  // ── PASSWORD STRENGTH CALCULATOR ─────────────────────
  void _updatePasswordStrength() {
    final password = _passwordController.text;

    if (password.isEmpty) {
      setState(() => _passwordStrength = _PasswordStrength.none);
      return;
    }

    int score = 0;

    // Length check
    if (password.length >= 8) score++;
    if (password.length >= 12) score++;

    // Character type checks
    if (RegExp(r'[a-z]').hasMatch(password)) score++;
    if (RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'\d').hasMatch(password)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password)) {
      score++;
    }

    // Strength decide karo score se
    _PasswordStrength strength;
    if (score <= 2) {
      strength = _PasswordStrength.weak;
    } else if (score <= 3) {
      strength = _PasswordStrength.fair;
    } else if (score <= 4) {
      strength = _PasswordStrength.good;
    } else {
      strength = _PasswordStrength.strong;
    }

    setState(() => _passwordStrength = strength);
  }

  // ── VALIDATORS ───────────────────────────────────────

  String? _validateName(String? value) {
    if (value == null || value.isEmpty) {
      return AppValidation.errorRequired;
    }
    if (value.trim().length < AppValidation.nameMinLength) {
      return AppValidation.errorNameShort;
    }
    if (!AppValidation.nameRegex.hasMatch(value)) {
      return AppValidation.errorName;
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return AppValidation.errorRequired;
    }
    if (!AppValidation.emailRegex.hasMatch(value)) {
      return AppValidation.errorEmail;
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppValidation.errorRequired;
    }
    if (value.length < AppValidation.passwordMinLength) {
      return AppValidation.errorPasswordShort;
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return AppValidation.errorRequired;
    }
    if (value != _passwordController.text) {
      return AppValidation.errorPasswordMatch;
    }
    return null;
  }

  // ── REGISTER HANDLER ─────────────────────────────────
  Future<void> _handleRegister() async {
    // Form validation
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Terms check
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Please accept the Terms & Conditions',
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.cardRadius,
          ),
        ),
      );
      return;
    }

    // Clear error
    ref.read(authProvider.notifier).clearError();

    // Register call
    final success = await ref.read(authProvider.notifier).register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (success && mounted) {
      // OTP verification screen pe bhejo
      context.go(AppRoutes.verifyOtp);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

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
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.md),

                // ── HEADER ─────────────────────────────
                _buildHeader(),

                const SizedBox(height: AppSpacing.xl3),

                // ── ERROR BANNER ───────────────────────
                if (authState.errorMessage != null) ...[
                  _buildErrorBanner(authState.errorMessage!),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // ── NAME FIELD ─────────────────────────
                AppTextField(
                  controller: _nameController,
                  focusNode: _nameFocus,
                  label: 'Full Name',
                  hint: 'Enter your full name',
                  prefixIcon: Icons.person_outline,
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  validator: _validateName,
                  enabled: !isLoading,
                  onSubmitted: (_) => _emailFocus.requestFocus(),
                ),

                const SizedBox(height: AppSpacing.lg),

                // ── EMAIL FIELD ────────────────────────
                AppTextField(
                  controller: _emailController,
                  focusNode: _emailFocus,
                  label: 'Email Address',
                  hint: 'you@example.com',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: _validateEmail,
                  enabled: !isLoading,
                  onSubmitted: (_) => _passwordFocus.requestFocus(),
                ),

                const SizedBox(height: AppSpacing.lg),

                // ── PASSWORD FIELD ─────────────────────
                AppPasswordField(
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  label: 'Password',
                  hint: 'Create a strong password',
                  validator: _validatePassword,
                  enabled: !isLoading,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => _confirmPasswordFocus.requestFocus(),
                ),

                // ── PASSWORD STRENGTH INDICATOR ────────
                if (_passwordController.text.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _buildPasswordStrength(),
                ],

                const SizedBox(height: AppSpacing.lg),

                // ── CONFIRM PASSWORD FIELD ─────────────
                AppPasswordField(
                  controller: _confirmPasswordController,
                  focusNode: _confirmPasswordFocus,
                  label: 'Confirm Password',
                  hint: 'Re-enter your password',
                  validator: _validateConfirmPassword,
                  enabled: !isLoading,
                  onSubmitted: (_) => _handleRegister(),
                ),

                const SizedBox(height: AppSpacing.xl2),

                // ── TERMS & CONDITIONS ─────────────────
                _buildTermsCheckbox(),

                const SizedBox(height: AppSpacing.xl2),

                // ── REGISTER BUTTON ────────────────────
                AppPrimaryButton(
                  label: 'Create Account',
                  isLoading: isLoading,
                  onPressed: isLoading ? null : _handleRegister,
                ),

                const SizedBox(height: AppSpacing.xl3),

                // ── LOGIN LINK ─────────────────────────
                _buildLoginLink(),

                const SizedBox(height: AppSpacing.xl2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // HEADER
  // ══════════════════════════════════════════

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo circle
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: AppGradients.emerald,
            shape: BoxShape.circle,
            boxShadow: AppShadows.emeraldGlow,
          ),
          child: const Icon(
            Icons.person_add_outlined,
            color: AppColors.white,
            size: 28,
          ),
        ),

        const SizedBox(height: AppSpacing.xl2),

        // Small tag
        Text(
          'JOIN QIBRA AI',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.primary,
            letterSpacing: 2,
            fontWeight: FontWeight.w700,
          ),
        ),

        const SizedBox(height: AppSpacing.xs),

        // Heading
        Text(
          'Create Account',
          style: AppTextStyles.headlineLarge.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        // Subtitle
        Text(
          'Start your Islamic journey with us',
          style: AppTextStyles.bodyMedium.secondary,
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
          GestureDetector(
            onTap: () {
              ref.read(authProvider.notifier).clearError();
            },
            child: const Icon(
              Icons.close,
              color: AppColors.error,
              size: AppIconSizes.sm,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // PASSWORD STRENGTH INDICATOR
  // ══════════════════════════════════════════

  Widget _buildPasswordStrength() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress bar
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: AppRadius.pillRadius,
                child: LinearProgressIndicator(
                  value: _passwordStrength.percentage,
                  minHeight: 4,
                  backgroundColor: AppColors.borderSubtle,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _passwordStrength.color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              _passwordStrength.label,
              style: AppTextStyles.labelSmall.copyWith(
                color: _passwordStrength.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.xs),

        // Helper text
        Text(
          'Use 8+ characters with uppercase, number & symbol',
          style: AppTextStyles.labelXSmall.copyWith(
            color: AppColors.textTertiary,
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════
  // TERMS & CONDITIONS CHECKBOX
  // ══════════════════════════════════════════

  Widget _buildTermsCheckbox() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: Checkbox(
            value: _acceptedTerms,
            onChanged: (value) {
              setState(() => _acceptedTerms = value ?? false);
            },
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: GestureDetector(
            onTap: () {
              setState(() => _acceptedTerms = !_acceptedTerms);
            },
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.bodySmall.secondary,
                children: const [
                  TextSpan(text: 'I agree to the '),
                  TextSpan(
                    text: 'Terms & Conditions',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════
  // LOGIN LINK
  // ══════════════════════════════════════════

  Widget _buildLoginLink() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Already have an account? ',
            style: AppTextStyles.bodyMedium.secondary,
          ),
          GestureDetector(
            onTap: () => context.go(AppRoutes.login),
            child: Text(
              'Login',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
