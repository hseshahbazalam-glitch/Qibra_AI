// lib/features/auth/presentation/forgot_password_screen.dart

// ============================================================
// QIBRA AI — FORGOT PASSWORD SCREEN (QB-006, G2-D)
// Version: 3.0.0 — the honest rebuild
//
// This screen used to run a fake: an email field, `await Future.delayed(2s)`
// under a comment claiming to simulate one, a success animation with a
// heavy haptic, and an "Open Email App" button that opened nothing. There is no
// reset endpoint in the backend (`forgot`/`reset` do not appear in
// backend/app/api/ at all) and no email system in the product, so every one of
// those affordances promised a thing this build cannot do.
//
// What ships instead: the truth, and only the exits that exist.
//   • sign in with the current password (AppRoutes.login)
//   • create a new account (AppRoutes.register)
// No field, no loading state, no success state, no haptics, no animation
// controller — so nothing here can imply work that is not happening. Every
// string is an AppStrings getter, real in en/ar/ur, and the two actions ride the
// shared AuthButton (56dp, above the repo's 48dp floor).
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:qibra_ai/core/design_system/qibra_colors.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';
import 'package:qibra_ai/core/l10n/app_strings.dart';
import 'package:qibra_ai/features/auth/presentation/widgets/auth_button.dart';
import 'package:qibra_ai/features/auth/presentation/widgets/auth_header.dart';

class ForgotPasswordScreen extends StatelessWidget {
  const ForgotPasswordScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    final s = AppStrings.of(context);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.md),
              AuthHeader(onBackTap: () => context.go(AppRoutes.login)),
              const SizedBox(height: AppSpacing.xl2),
              _Badge(icon: Icons.lock_reset_rounded, color: colors.accent),
              const SizedBox(height: AppSpacing.lg),
              Text(
                s.forgotEyebrow,
                textAlign: TextAlign.center,
                style: AppTextStyles.labelSmall.copyWith(
                  color: colors.goldText,
                  letterSpacing: 3,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                s.forgotUnavailableHeadline,
                textAlign: TextAlign.center,
                style: AppTextStyles.headlineLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  s.forgotUnavailableBody,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: colors.textSecondary,
                    height: 1.6,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl2),
              _NoteCard(
                icon: Icons.info_outline_rounded,
                label: s.forgotNothingSentLabel,
                body: s.forgotNothingSentBody,
              ),
              const SizedBox(height: AppSpacing.lg),
              _OptionsCard(options: [
                _Option(
                  icon: Icons.arrow_back_rounded,
                  body: s.forgotOptionSignInHint,
                ),
                _Option(
                  icon: Icons.person_add_alt_1_rounded,
                  body: s.forgotOptionRegisterHint,
                ),
              ], label: s.forgotOptionsLabel),
              const SizedBox(height: AppSpacing.xl2),
              AuthButton(
                label: s.forgotBackToSignIn,
                leadingIcon: Icons.arrow_back_rounded,
                onTap: () => context.go(AppRoutes.login),
              ),
              const SizedBox(height: AppSpacing.md),
              AuthButton(
                label: s.forgotCreateAccount,
                leadingIcon: Icons.person_add_alt_1_rounded,
                backgroundColor: colors.card,
                borderColor: colors.border,
                textColor: colors.textPrimary,
                onTap: () => context.go(AppRoutes.register),
              ),
              const SizedBox(height: AppSpacing.xl2),
            ],
          ),
        ),
      ),
    );
  }
}

// ── The icon badge that replaces the animated one ─────────────────────────
// Static on purpose: an animation on this screen would be dressing up the
// absence of a feature.

class _Badge extends StatelessWidget {
  const _Badge({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    return Center(
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.12),
          border: Border.all(color: colors.border, width: 1),
        ),
        child: Icon(icon, color: color, size: 30),
      ),
    );
  }
}

// ── One card: a label, a body, nothing claimed beyond them ─────────────────

class _NoteCard extends StatelessWidget {
  const _NoteCard({
    required this.icon,
    required this.label,
    required this.body,
  });

  final IconData icon;
  final String label;
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.cardMuted,
        borderRadius: AppRadius.cardRadius,
        border: Border.all(color: colors.border, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: colors.textSecondary, size: 16),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  body,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: colors.textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Option {
  const _Option({required this.icon, required this.body});

  final IconData icon;
  final String body;
}

class _OptionsCard extends StatelessWidget {
  const _OptionsCard({required this.label, required this.options});

  final String label;
  final List<_Option> options;

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: AppRadius.cardRadiusLarge,
        border: Border.all(color: colors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: colors.accent,
              letterSpacing: 2,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final o in options)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(o.icon, color: colors.accent, size: 16),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      o.body,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: colors.textSecondary,
                        height: 1.5,
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
}
