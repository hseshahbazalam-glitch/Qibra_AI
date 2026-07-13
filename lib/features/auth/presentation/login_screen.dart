// lib/features/auth/presentation/login_screen.dart

// ============================================================
// QIBRA AI — LOGIN SCREEN
// Version: 1.0.0
// Description: Premium login screen with email/password,
//              social auth, and remember me option.
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
// LOGIN SCREEN WIDGET
// ============================================================

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // ── FORM KEY ─────────────────────────────────────────
  final _formKey = GlobalKey<FormState>();

  // ── CONTROLLERS ──────────────────────────────────────
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // ── FOCUS NODES ──────────────────────────────────────
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  // ── STATE ────────────────────────────────────────────
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
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

  // ── PASSWORD VALIDATOR ───────────────────────────────
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
    // Validate form
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Clear previous error
    ref.read(authProvider.notifier).clearError();

    // Call login
    final success = await ref.read(authProvider.notifier).login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    // Login success — router automatic redirect karega
    if (success && mounted) {
      // Router refresh trigger karega auto redirect
      context.go(AppRoutes.home);
    }
  }

  // ── GOOGLE AUTH ──────────────────────────────────────
  Future<void> _handleGoogleAuth() async {
    // Real implementation Step 15+ mein aayega
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Google Sign-In — coming soon'),
      ),
    );
  }

  // ── APPLE AUTH ───────────────────────────────────────
  Future<void> _handleAppleAuth() async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Apple Sign-In — coming soon'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Auth state watch karo
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppSpacing.xl2),

                // ── HEADER ─────────────────────────────
                _buildHeader(),

                const SizedBox(height: AppSpacing.xl4),

                // ── ERROR MESSAGE ──────────────────────
                if (authState.errorMessage != null) ...[
                  _buildErrorBanner(authState.errorMessage!),
                  const SizedBox(height: AppSpacing.lg),
                ],

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
                  hint: 'Enter your password',
                  validator: _validatePassword,
                  enabled: !isLoading,
                  onSubmitted: (_) => _handleLogin(),
                ),

                const SizedBox(height: AppSpacing.md),

                // ── REMEMBER ME + FORGOT PASSWORD ─────
                _buildRememberAndForgot(),

                const SizedBox(height: AppSpacing.xl2),

                // ── LOGIN BUTTON ───────────────────────
                AppPrimaryButton(
                  label: 'Login',
                  isLoading: isLoading,
                  onPressed: isLoading ? null : _handleLogin,
                ),

                const SizedBox(height: AppSpacing.xl2),

                // ── DIVIDER ────────────────────────────
                _buildDivider(),

                const SizedBox(height: AppSpacing.xl2),

                // ── SOCIAL BUTTONS ─────────────────────
                if (AppFeatureFlags.googleAuthEnabled) ...[
                  AppSocialButton(
                    label: 'Continue with Google',
                    type: SocialButtonType.google,
                    onPressed: isLoading ? null : _handleGoogleAuth,
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],

                if (AppFeatureFlags.appleAuthEnabled)
                  AppSocialButton(
                    label: 'Continue with Apple',
                    type: SocialButtonType.apple,
                    onPressed: isLoading ? null : _handleAppleAuth,
                  ),

                const SizedBox(height: AppSpacing.xl3),

                // ── REGISTER LINK ──────────────────────
                _buildRegisterLink(),

                const SizedBox(height: AppSpacing.xl2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════
  // HEADER — Logo + Welcome Text
  // ══════════════════════════════════════════

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Logo circle
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: AppGradients.gold,
            shape: BoxShape.circle,
            boxShadow: AppShadows.goldGlow,
          ),
          child: const Icon(
            Icons.mosque,
            color: AppColors.background,
            size: 32,
          ),
        ),

        const SizedBox(height: AppSpacing.xl2),

        // Welcome text
        Text(
          'Assalamu Alaikum',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.accent,
            letterSpacing: 2,
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: AppSpacing.xs),

        // Main heading
        Text(
          'Welcome Back!',
          style: AppTextStyles.headlineLarge.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        // Subtitle
        Text(
          'Login to continue your Islamic journey',
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
          // Close button
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
  // REMEMBER ME + FORGOT PASSWORD
  // ══════════════════════════════════════════

  Widget _buildRememberAndForgot() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Remember me checkbox
        Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: Checkbox(
                value: _rememberMe,
                onChanged: (value) {
                  setState(() {
                    _rememberMe = value ?? false;
                  });
                },
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Remember me',
              style: AppTextStyles.labelMedium.secondary,
            ),
          ],
        ),

        // Forgot password link
        AppTextBtn(
          label: 'Forgot Password?',
          onPressed: () => context.go(AppRoutes.forgotPassword),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════
  // OR DIVIDER
  // ══════════════════════════════════════════

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.divider,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
          ),
          child: Text(
            'OR CONTINUE WITH',
            style: AppTextStyles.labelXSmall.copyWith(
              color: AppColors.textTertiary,
              letterSpacing: 2,
            ),
          ),
        ),
        Expanded(
          child: Container(
            height: 1,
            color: AppColors.divider,
          ),
        ),
      ],
    );
  }

  // ══════════════════════════════════════════
  // REGISTER LINK
  // ══════════════════════════════════════════

  Widget _buildRegisterLink() {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Don't have an account? ",
            style: AppTextStyles.bodyMedium.secondary,
          ),
          GestureDetector(
            onTap: () => context.go(AppRoutes.register),
            child: Text(
              'Register',
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
