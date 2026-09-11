// lib/features/auth/presentation/register_screen.dart

// ============================================================
// QIBRA AI — PREMIUM REGISTER SCREEN (Phase 2)
// Version: 2.0.0
// Description: Apple-quality register with glassmorphism,
//              password strength, and premium UX.
// ============================================================


import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qibra_ai/core/constants/app_constants.dart';
import 'package:qibra_ai/core/design_system/qibra_colors.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';
import 'package:qibra_ai/core/providers/auth_provider.dart';
import 'package:qibra_ai/features/auth/presentation/widgets/auth_button.dart';
import 'package:qibra_ai/features/auth/presentation/widgets/auth_header.dart';
import 'package:qibra_ai/features/auth/presentation/widgets/auth_text_field.dart';

// ============================================================
// PASSWORD STRENGTH
// ============================================================

enum _PasswordStrength {
  none,
  weak,
  fair,
  good,
  strong;

  Color get color {
    final colors = QibraColors.light;
    switch (this) {
      case _PasswordStrength.none:
        return colors.border;
      case _PasswordStrength.weak:
        return colors.error;
      case _PasswordStrength.fair:
        return colors.accent;
      case _PasswordStrength.good:
        return colors.info;
      case _PasswordStrength.strong:
        return colors.success;
    }
  }

  String get label {
    switch (this) {
      case _PasswordStrength.none:
        return 'Enter a password';
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
// PREMIUM REGISTER SCREEN
// ============================================================

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen>
    with TickerProviderStateMixin {
  // ── FORM ─────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;
  _PasswordStrength _passwordStrength = _PasswordStrength.none;

  // Password requirements
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;

  bool _isNameFocused = false;
  bool _isEmailFocused = false;
  bool _isPasswordFocused = false;
  bool _isConfirmFocused = false;

  // ── ANIMATIONS ───────────────────────────────────────
  late AnimationController _entranceController;
  late Animation<double> _entranceFade;
  late Animation<Offset> _entranceSlide;

  @override
  void initState() {
    super.initState();

    // Password listener for real-time validation
    _passwordController.addListener(_updatePasswordStrength);

    // Focus listeners
    _nameFocus.addListener(() {
      setState(() => _isNameFocused = _nameFocus.hasFocus);
      if (_nameFocus.hasFocus) HapticFeedback.selectionClick();
    });
    _emailFocus.addListener(() {
      setState(() => _isEmailFocused = _emailFocus.hasFocus);
      if (_emailFocus.hasFocus) HapticFeedback.selectionClick();
    });
    _passwordFocus.addListener(() {
      setState(() => _isPasswordFocused = _passwordFocus.hasFocus);
      if (_passwordFocus.hasFocus) HapticFeedback.selectionClick();
    });
    _confirmPasswordFocus.addListener(() {
      setState(() => _isConfirmFocused = _confirmPasswordFocus.hasFocus);
      if (_confirmPasswordFocus.hasFocus) {
        HapticFeedback.selectionClick();
      }
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

    _entranceSlide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOutCubic,
    ));

    _entranceController.forward();
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
    _entranceController.dispose();
    super.dispose();
  }

  // ── PASSWORD STRENGTH CALCULATOR ─────────────────────
  void _updatePasswordStrength() {
    final password = _passwordController.text;

    setState(() {
      _hasMinLength = password.length >= 8;
      _hasUppercase = RegExp(r'[A-Z]').hasMatch(password);
      _hasLowercase = RegExp(r'[a-z]').hasMatch(password);
      _hasNumber = RegExp(r'\d').hasMatch(password);
      _hasSpecialChar = RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(password);

      if (password.isEmpty) {
        _passwordStrength = _PasswordStrength.none;
        return;
      }

      int score = 0;
      if (_hasMinLength) score++;
      if (password.length >= 12) score++;
      if (_hasUppercase) score++;
      if (_hasLowercase) score++;
      if (_hasNumber) score++;
      if (_hasSpecialChar) score++;

      if (score <= 2) {
        _passwordStrength = _PasswordStrength.weak;
      } else if (score <= 3) {
        _passwordStrength = _PasswordStrength.fair;
      } else if (score <= 4) {
        _passwordStrength = _PasswordStrength.good;
      } else {
        _passwordStrength = _PasswordStrength.strong;
      }
    });
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
    final colors = QibraColors.of(context);
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }

    if (!_acceptedTerms) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.error_outline,
                color: colors.textPrimary,
                size: 20,
              ),
              SizedBox(width: AppSpacing.sm),
              Text('Please accept the Terms & Conditions'),
            ],
          ),
          backgroundColor: colors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.cardRadius,
          ),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    ref.read(authProvider.notifier).clearError();

    final success = await ref.read(authProvider.notifier).register(
          name: _nameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (success && mounted) {
      HapticFeedback.heavyImpact();
      context.go(AppRoutes.verifyOtp);
    } else if (mounted) {
      HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      body: Stack(
        children: [
          // ── LAYER 1: Background ──
          _buildBackground(),

          // ── LAYER 3: Content ──
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
                  child: Column(
                    children: [
                      const SizedBox(height: AppSpacing.md),

                      // Header
                      _buildHeader(),

                      const SizedBox(height: AppSpacing.xl2),

                      // Title
                      _buildTitle(),

                      const SizedBox(height: AppSpacing.xl2),

                      // Form card
                      Form(
                        key: _formKey,
                        child: _buildFormCard(authState, isLoading),
                      ),

                      const SizedBox(height: AppSpacing.xl2),

                      // Login link
                      _buildLoginLink(),

                      const SizedBox(height: AppSpacing.xl2),
                    ],
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
  // BACKGROUND
  // ══════════════════════════════════════════

  Widget _buildBackground() {
    final colors = QibraColors.of(context);
    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          color: colors.background,
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // HEADER (back + step)
  // ══════════════════════════════════════════

  Widget _buildHeader() {
    return AuthHeader(
      onBackTap: () => context.go(AppRoutes.login),
      stepNumber: 1,
      totalSteps: 3,
      stepLabel: 'Sign Up',
    );
  }

  // ══════════════════════════════════════════
  // TITLE
  // ══════════════════════════════════════════

  Widget _buildTitle() {
    final colors = QibraColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Small tag
        Text(
          'JOIN QIBRA AI',
          style: AppTextStyles.labelSmall.copyWith(
            color: colors.primary,
            letterSpacing: 3,
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        // Main heading
        Text(
          'Create Account',
          style: AppTextStyles.headlineLarge.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),

        const SizedBox(height: AppSpacing.xs),

        // Subtitle
        Text(
          'Start your spiritual journey today',
          style: AppTextStyles.bodyMedium.copyWith(
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════
  // FORM CARD (Glassmorphism)
  // ══════════════════════════════════════════

  Widget _buildFormCard(AuthState authState, bool isLoading) {
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Error banner
              if (authState.errorMessage != null) ...[
                _buildErrorBanner(authState.errorMessage!),
                const SizedBox(height: AppSpacing.md),
              ],

              // Name field
              _buildPremiumTextField(
                controller: _nameController,
                focusNode: _nameFocus,
                isFocused: _isNameFocused,
                label: 'Full Name',
                hint: 'John Doe',
                icon: Icons.person_outline_rounded,
                keyboardType: TextInputType.name,
                textInputAction: TextInputAction.next,
                validator: _validateName,
                enabled: !isLoading,
                onSubmitted: (_) => _emailFocus.requestFocus(),
              ),

              const SizedBox(height: AppSpacing.md),

              // Email field
              _buildPremiumTextField(
                controller: _emailController,
                focusNode: _emailFocus,
                isFocused: _isEmailFocused,
                label: 'Email Address',
                hint: 'you@example.com',
                icon: Icons.mail_outline_rounded,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: _validateEmail,
                enabled: !isLoading,
                onSubmitted: (_) => _passwordFocus.requestFocus(),
              ),

              const SizedBox(height: AppSpacing.md),

              // Password field
              _buildPasswordField(
                controller: _passwordController,
                focusNode: _passwordFocus,
                isFocused: _isPasswordFocused,
                label: 'Password',
                hint: 'Create strong password',
                obscure: _obscurePassword,
                onToggle: () {
                  HapticFeedback.selectionClick();
                  setState(() => _obscurePassword = !_obscurePassword);
                },
                validator: _validatePassword,
                enabled: !isLoading,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _confirmPasswordFocus.requestFocus(),
              ),

              // Password strength meter
              if (_passwordController.text.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                _buildPasswordStrength(),
                const SizedBox(height: AppSpacing.md),
                _buildPasswordRequirements(),
              ],

              const SizedBox(height: AppSpacing.md),

              // Confirm password field
              _buildPasswordField(
                controller: _confirmPasswordController,
                focusNode: _confirmPasswordFocus,
                isFocused: _isConfirmFocused,
                label: 'Confirm Password',
                hint: 'Re-enter password',
                obscure: _obscureConfirmPassword,
                onToggle: () {
                  HapticFeedback.selectionClick();
                  setState(
                      () => _obscureConfirmPassword = !_obscureConfirmPassword);
                },
                validator: _validateConfirmPassword,
                enabled: !isLoading,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _handleRegister(),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Terms checkbox
              _buildTermsCheckbox(),

              const SizedBox(height: AppSpacing.lg),

              // Register button
              _buildRegisterButton(isLoading),

              const SizedBox(height: AppSpacing.md),

              // Continue as Guest button (PREMIUM OFF-LINE BYPASS)
              AuthButton(
                label: 'Continue as Guest',
                onTap: () {
                  HapticFeedback.mediumImpact();
                  ref.read(authProvider.notifier).continueAsGuest();
                  context.go(AppRoutes.home);
                },
                isLoading: false,
                height: 48,
              ),
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
          GestureDetector(
            onTap: () {
              ref.read(authProvider.notifier).clearError();
            },
            child: Icon(
              Icons.close_rounded,
              color: colors.error,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // PREMIUM TEXT FIELD
  // ══════════════════════════════════════════

  Widget _buildPremiumTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool isFocused,
    required String label,
    required String hint,
    required IconData icon,
    required TextInputType keyboardType,
    required TextInputAction textInputAction,
    required String? Function(String?) validator,
    required bool enabled,
    required void Function(String)? onSubmitted,
  }) {
    return AuthTextField(
      controller: controller,
      focusNode: focusNode,
      label: label,
      hint: hint,
      validator: validator,
      isFocused: isFocused,
      enabled: enabled,
      prefixIcon: icon,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
    );
  }

  // ══════════════════════════════════════════
  // PASSWORD FIELD
  // ══════════════════════════════════════════

  Widget _buildPasswordField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool isFocused,
    required String label,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
    required bool enabled,
    required TextInputAction textInputAction,
    required void Function(String)? onSubmitted,
  }) {
    return AuthTextField(
      controller: controller,
      focusNode: focusNode,
      label: label,
      hint: hint,
      validator: validator,
      isFocused: isFocused,
      enabled: enabled,
      prefixIcon: Icons.lock_outline_rounded,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      obscureText: obscure,
      suffixIcon:
          obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
      onSuffixPressed: onToggle,
    );
  }

  // ══════════════════════════════════════════
  // PASSWORD STRENGTH METER
  // ══════════════════════════════════════════

  Widget _buildPasswordStrength() {
    final colors = QibraColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Progress bar
            Expanded(
              child: ClipRRect(
                borderRadius: AppRadius.pillRadius,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 6,
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.pillRadius,
                    color: colors.cardMuted,
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: _passwordStrength.percentage,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: _passwordStrength.color,
                        borderRadius: AppRadius.pillRadius,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Label
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Container(
                key: ValueKey(_passwordStrength.label),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: _passwordStrength.color.withValues(alpha: 0.15),
                  borderRadius: AppRadius.pillRadius,
                  border: Border.all(
                    color: _passwordStrength.color.withValues(alpha: 0.16),
                    width: 1,
                  ),
                ),
                child: Text(
                  _passwordStrength.label,
                  style: AppTextStyles.labelSmall.copyWith(
                    color: _passwordStrength.color,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ══════════════════════════════════════════
  // PASSWORD REQUIREMENTS
  // ══════════════════════════════════════════

  Widget _buildPasswordRequirements() {
    final colors = QibraColors.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.textPrimary.withValues(alpha: 0.03),
        borderRadius: AppRadius.cardRadius,
        border: Border.all(
          color: colors.textPrimary.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shield_outlined,
                color: colors.accent,
                size: 14,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'PASSWORD REQUIREMENTS',
                style: AppTextStyles.labelSmall.copyWith(
                  color: colors.accent,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildRequirementItem('At least 8 characters', _hasMinLength),
          _buildRequirementItem('Uppercase letter (A-Z)', _hasUppercase),
          _buildRequirementItem('Lowercase letter (a-z)', _hasLowercase),
          _buildRequirementItem('Number (0-9)', _hasNumber),
          _buildRequirementItem(
              'Special character (!@#\$...)', _hasSpecialChar),
        ],
      ),
    );
  }

  Widget _buildRequirementItem(String text, bool met) {
    final colors = QibraColors.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: met ? colors.primary : colors.cardMuted,
              border: Border.all(
                color: met ? colors.primary : colors.border,
                width: 1,
              ),
            ),
            child: met
                ? Icon(
                    Icons.check_rounded,
                    color: colors.onPrimary,
                    size: 10,
                  )
                : null,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            text,
            style: AppTextStyles.labelSmall.copyWith(
              color: met ? colors.primary : colors.textSecondary,
              fontWeight: met ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════
  // TERMS CHECKBOX
  // ══════════════════════════════════════════

  Widget _buildTermsCheckbox() {
    final colors = QibraColors.of(context);
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _acceptedTerms = !_acceptedTerms);
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              color: _acceptedTerms
                  ? colors.primary
                  : colors.cardMuted,
              border: Border.all(
                color: _acceptedTerms ? colors.primary : colors.border,
                width: 1.5,
              ),
            ),
            child: _acceptedTerms
                ? Icon(
                    Icons.check_rounded,
                    color: colors.onPrimary,
                    size: 14,
                  )
                : null,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.labelMedium.copyWith(
                  color: colors.textSecondary,
                  height: 1.5,
                ),
                children: [
                  const TextSpan(text: 'I agree to the '),
                  TextSpan(
                    text: 'Terms of Service',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: colors.accent,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                      decorationColor: colors.accent,
                    ),
                  ),
                  const TextSpan(text: ' and '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: colors.accent,
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                      decorationColor: colors.accent,
                    ),
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
  // REGISTER BUTTON
  // ══════════════════════════════════════════

  Widget _buildRegisterButton(bool isLoading) {
    return AuthButton(
      label: 'Create Account',
      onTap: _handleRegister,
      isLoading: isLoading,
      trailingIcon: Icons.arrow_forward_rounded,
    );
  }

  // ══════════════════════════════════════════
  // LOGIN LINK
  // ══════════════════════════════════════════

  Widget _buildLoginLink() {
    final colors = QibraColors.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: AppTextStyles.bodyMedium.copyWith(
            color: colors.textSecondary,
          ),
        ),
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            context.go(AppRoutes.login);
          },
          child: Text(
            'Sign In',
            style: AppTextStyles.bodyMedium.copyWith(
              color: colors.goldText,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
