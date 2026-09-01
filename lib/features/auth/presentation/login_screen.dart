// lib/features/auth/presentation/login_screen.dart

// ============================================================
// QIBRA AI — PREMIUM LOGIN SCREEN (Phase 2)
// Version: 2.0.0
// Description: Apple-quality login with glassmorphism,
//              biometric option, and premium animations.
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
import 'package:qibra_ai/shared/widgets/qibra_ui.dart';
import 'package:qibra_ai/features/auth/presentation/widgets/auth_button.dart';
import 'package:qibra_ai/features/auth/presentation/widgets/auth_social_buttons.dart';
import 'package:qibra_ai/features/auth/presentation/widgets/auth_text_field.dart';

// ============================================================
// PREMIUM LOGIN SCREEN
// ============================================================

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with TickerProviderStateMixin {
  // ── FORM ─────────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _rememberMe = true;
  bool _obscurePassword = true;
  bool _isEmailFocused = false;
  bool _isPasswordFocused = false;

  // ── ANIMATION CONTROLLERS ────────────────────────────
  late AnimationController _logoController;
  late Animation<double> _logoScale;
  late Animation<double> _logoFade;

  late AnimationController _formController;
  late Animation<double> _formFade;
  late Animation<Offset> _formSlide;


  @override
  void initState() {
    super.initState();

    // Logo animation
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _logoScale = Tween<double>(
      begin: 0.5,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    _logoFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    ));

    // Form animation
    _formController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _formFade = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _formController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
    ));

    _formSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _formController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutCubic),
    ));

    // Focus listeners
    _emailFocus.addListener(() {
      setState(() => _isEmailFocused = _emailFocus.hasFocus);
      if (_emailFocus.hasFocus) HapticFeedback.selectionClick();
    });

    _passwordFocus.addListener(() {
      setState(() => _isPasswordFocused = _passwordFocus.hasFocus);
      if (_passwordFocus.hasFocus) HapticFeedback.selectionClick();
    });

    // Start animations
    _logoController.forward();
    _formController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _logoController.dispose();
    _formController.dispose();
    super.dispose();
  }

  // ── VALIDATORS ───────────────────────────────────────

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

  // ── LOGIN HANDLER ────────────────────────────────────
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }

    HapticFeedback.mediumImpact();
    ref.read(authProvider.notifier).clearError();

    final success = await ref.read(authProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (success && mounted) {
      HapticFeedback.heavyImpact();
      context.go(AppRoutes.home);
    } else if (mounted) {
      HapticFeedback.heavyImpact();
    }
  }

  // Biometric, Google, and Apple authentication are not implemented in this
  // build. Their controls remain visible but explicitly disabled so no button
  // appears to sign a user in when it cannot do so.

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

    return QibraPage(
      useAppBar: false,
      child: Stack(
        children: [
          // ── LAYER 1: Background gradient ──
          _buildBackground(),

          // ── LAYER 3: Content ──
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
              ),
              child: Column(
                children: [
                  const SizedBox(height: AppSpacing.xl2),

                  // Logo section
                  FadeTransition(
                    opacity: _logoFade,
                    child: ScaleTransition(
                      scale: _logoScale,
                      child: _buildLogo(),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl2),

                  // Welcome text
                  FadeTransition(
                    opacity: _logoFade,
                    child: _buildWelcomeText(),
                  ),

                  const SizedBox(height: AppSpacing.xl3),

                  // Login form card
                  SlideTransition(
                    position: _formSlide,
                    child: FadeTransition(
                      opacity: _formFade,
                      child: Form(
                        key: _formKey,
                        child: _buildFormCard(
                          authState,
                          isLoading,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl2),

                  // Social divider
                  FadeTransition(
                    opacity: _formFade,
                    child: _buildDivider(),
                  ),

                  const SizedBox(height: AppSpacing.xl2),

                  // Social buttons
                  FadeTransition(
                    opacity: _formFade,
                    child: _buildSocialButtons(isLoading),
                  ),

                  const SizedBox(height: AppSpacing.xl3),

                  // Register link
                  FadeTransition(
                    opacity: _formFade,
                    child: _buildRegisterLink(),
                  ),

                  const SizedBox(height: AppSpacing.xl2),
                ],
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
  // LOGO
  // ══════════════════════════════════════════

  Widget _buildLogo() {
    final colors = QibraColors.of(context);
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.card,
        border: Border.all(
          color: colors.accent.withValues(alpha: 0.24),
          width: 2,
        ),
      ),
      child: Icon(
        Icons.mosque_rounded,
        size: 44,
        color: colors.goldText,
      ),
    );
  }

  // ══════════════════════════════════════════
  // WELCOME TEXT
  // ══════════════════════════════════════════

  Widget _buildWelcomeText() {
    final colors = QibraColors.of(context);
    return Column(
      children: [
        // Arabic greeting
        Text(
          'السَّلامُ عَلَيْكُم',
          style: AppArabicStyles.quranBold.copyWith(
            color: colors.goldText,
            height: 1.0,
          ),
          textDirection: TextDirection.rtl,
        ),

        const SizedBox(height: AppSpacing.sm),

        // English welcome
        Text(
          'Welcome Back',
          style: AppTextStyles.headlineMedium.copyWith(
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),

        const SizedBox(height: AppSpacing.xs),

        // Subtitle
        Text(
          'Continue your spiritual journey',
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
            color: colors.surface,
            borderRadius: AppRadius.cardRadiusLarge,
            border: Border.all(
              color: colors.border,
              width: 1,
            ),
            boxShadow: AppShadows.subtle,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Error banner
              if (authState.errorMessage != null) ...[
                _buildErrorBanner(authState.errorMessage!),
                const SizedBox(height: AppSpacing.md),
              ],

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
              _buildPremiumPasswordField(isLoading),

              const SizedBox(height: AppSpacing.md),

              // Remember me + Forgot password
              _buildRememberForgotRow(),

              const SizedBox(height: AppSpacing.lg),

              // Login button
              _buildLoginButton(isLoading),

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

              const SizedBox(height: AppSpacing.md),

              // Biometric button
              _buildBiometricButton(isLoading),
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
  // PREMIUM PASSWORD FIELD
  // ══════════════════════════════════════════

  Widget _buildPremiumPasswordField(bool isLoading) {
    return AuthTextField(
      controller: _passwordController,
      focusNode: _passwordFocus,
      label: 'Password',
      hint: 'Enter your password',
      validator: _validatePassword,
      isFocused: _isPasswordFocused,
      enabled: !isLoading,
      prefixIcon: Icons.lock_outline_rounded,
      textInputAction: TextInputAction.done,
      onSubmitted: (_) => _handleLogin(),
      obscureText: _obscurePassword,
      suffixIcon: _obscurePassword
          ? Icons.visibility_off_rounded
          : Icons.visibility_rounded,
      onSuffixPressed: () {
        HapticFeedback.selectionClick();
        setState(() => _obscurePassword = !_obscurePassword);
      },
    );
  }

  // ══════════════════════════════════════════
  // REMEMBER + FORGOT ROW
  // ══════════════════════════════════════════

  Widget _buildRememberForgotRow() {
    final colors = QibraColors.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Remember me
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _rememberMe = !_rememberMe);
          },
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: _rememberMe
                      ? colors.primary
                      : colors.cardMuted,
                  border: Border.all(
                    color: _rememberMe ? colors.primary : colors.border,
                    width: 1.5,
                  ),
                ),
                child: _rememberMe
                    ? Icon(
                        Icons.check_rounded,
                        color: colors.onPrimary,
                        size: 14,
                      )
                    : null,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Remember me',
                style: AppTextStyles.labelMedium.copyWith(
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),

        // Forgot password
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            context.go(AppRoutes.forgotPassword);
          },
          child: Text(
            'Forgot Password?',
            style: AppTextStyles.labelMedium.copyWith(
              color: colors.goldText,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════
  // LOGIN BUTTON (Premium with pulse)
  // ══════════════════════════════════════════

  Widget _buildLoginButton(bool isLoading) {
    return AuthButton(
      label: 'Sign In',
      onTap: _handleLogin,
      isLoading: isLoading,
      trailingIcon: Icons.arrow_forward_rounded,
    );
  }

  // ══════════════════════════════════════════
  // BIOMETRIC BUTTON
  // ══════════════════════════════════════════

  Widget _buildBiometricButton(bool isLoading) {
    final colors = QibraColors.of(context);
    return AuthButton(
      label: 'Biometric (coming soon)',
      onTap: null,
      isLoading: isLoading,
      height: 48,
      backgroundColor: colors.cardMuted,
      borderColor: colors.border,
      leadingIcon: Icons.fingerprint_rounded,
      textColor: colors.textTertiary,
      enabled: false,
    );
  }

  // ══════════════════════════════════════════
  // DIVIDER
  // ══════════════════════════════════════════

  Widget _buildDivider() {
    final colors = QibraColors.of(context);
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              color: colors.border,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
          ),
          child: Text(
            'OR CONTINUE WITH',
            style: AppTextStyles.labelSmall.copyWith(
              color: colors.textTertiary,
              letterSpacing: 2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              color: colors.border,
            ),
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════
  // SOCIAL BUTTONS
  // ══════════════════════════════════════════

  Widget _buildSocialButtons(bool isLoading) {
    return AuthSocialButtons(
      onGoogleTap: null,
      onAppleTap: null,
      googleAvailable: false,
      appleAvailable: false,
      isLoading: isLoading,
    );
  }

  // ══════════════════════════════════════════
  // REGISTER LINK
  // ══════════════════════════════════════════

  Widget _buildRegisterLink() {
    final colors = QibraColors.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: AppTextStyles.bodyMedium.copyWith(
            color: colors.textSecondary,
          ),
        ),
        GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            context.go(AppRoutes.register);
          },
          child: Text(
            'Sign Up',
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
