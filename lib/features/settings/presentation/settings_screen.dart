// lib/features/settings/presentation/settings_screen.dart
// ============================================================
// QIBRA AI — Premium Settings Screen
// Complete settings with Profile, Preferences, About
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:qibra_ai/core/constants/app_constants.dart';
import 'package:qibra_ai/core/design_system/app_colors.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';
import 'package:qibra_ai/core/providers/auth_provider.dart';
import 'package:qibra_ai/core/providers/theme_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final userName = ref.watch(userDisplayNameProvider);
    final isDark = ref.watch(isDarkModeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── APP BAR ──────────────────────────────────
          SliverAppBar(
            expandedHeight: 100,
            pinned: true,
            backgroundColor: AppColors.background,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              title: Text(
                'Settings',
                style: AppTextStyles.titleLarge.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              120,
            ),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── PROFILE CARD ─────────────────────
                _buildProfileCard(context, userName, user?.email ?? ''),
                const SizedBox(height: AppSpacing.xl2),

                // ── APP PREFERENCES ──────────────────
                _buildSectionTitle('APP PREFERENCES'),
                const SizedBox(height: AppSpacing.md),
                _buildSettingsGroup([
                  _SettingsTile(
                    icon: isDark ? Icons.dark_mode : Icons.light_mode,
                    iconColor: const Color(0xFF7C3AED),
                    title: 'Dark Mode',
                    subtitle: isDark ? 'Enabled' : 'Disabled',
                    trailing: Switch(
                      value: isDark,
                      activeThumbColor: AppColors.primary,
                      onChanged: (_) {
                        HapticFeedback.lightImpact();
                        ref.read(themeProvider.notifier).toggleTheme();
                      },
                    ),
                  ),
                  _SettingsTile(
                    icon: Icons.language_rounded,
                    iconColor: const Color(0xFF0891B2),
                    title: 'Language',
                    subtitle: 'English',
                    onTap: () => _showComingSoon(context, 'Language selection'),
                  ),
                  _SettingsTile(
                    icon: Icons.text_fields_rounded,
                    iconColor: const Color(0xFFB45309),
                    title: 'Font Size',
                    subtitle: 'Medium',
                    onTap: () => _showComingSoon(context, 'Font size'),
                  ),
                ]),

                const SizedBox(height: AppSpacing.xl2),

                // ── ISLAMIC SETTINGS ─────────────────
                _buildSectionTitle('ISLAMIC PREFERENCES'),
                const SizedBox(height: AppSpacing.md),
                _buildSettingsGroup([
                  _SettingsTile(
                    icon: Icons.access_time_filled_rounded,
                    iconColor: AppColors.primary,
                    title: 'Prayer Times',
                    subtitle: 'Calculation method',
                    onTap: () => context.go(AppRoutes.prayer),
                  ),
                  _SettingsTile(
                    icon: Icons.headphones_rounded,
                    iconColor: AppColors.accent,
                    title: 'Quran Reciter',
                    subtitle: 'Mishary Rashid',
                    onTap: () => _showComingSoon(context, 'Reciter selection'),
                  ),
                  _SettingsTile(
                    icon: Icons.translate_rounded,
                    iconColor: const Color(0xFF10B981),
                    title: 'Translation',
                    subtitle: 'English',
                    onTap: () => _showComingSoon(context, 'Translation'),
                  ),
                  _SettingsTile(
                    icon: Icons.explore_rounded,
                    iconColor: const Color(0xFF7C3AED),
                    title: 'Qibla Direction',
                    subtitle: 'Auto-detect',
                    onTap: () => context.go(AppRoutes.qibla),
                  ),
                ]),

                const SizedBox(height: AppSpacing.xl2),

                // ── NOTIFICATIONS ────────────────────
                _buildSectionTitle('NOTIFICATIONS'),
                const SizedBox(height: AppSpacing.md),
                _buildSettingsGroup([
                  _SettingsTile(
                    icon: Icons.notifications_active_rounded,
                    iconColor: const Color(0xFFEF4444),
                    title: 'Adhan Notifications',
                    subtitle: 'Enabled',
                    trailing: Switch(
                      value: true,
                      activeThumbColor: AppColors.primary,
                      onChanged: (_) {
                        HapticFeedback.lightImpact();
                        _showComingSoon(context, 'Adhan settings');
                      },
                    ),
                  ),
                  _SettingsTile(
                    icon: Icons.notification_add_rounded,
                    iconColor: const Color(0xFFF59E0B),
                    title: 'Daily Reminders',
                    subtitle: 'Quran & Duas',
                    trailing: Switch(
                      value: true,
                      activeThumbColor: AppColors.primary,
                      onChanged: (_) {
                        HapticFeedback.lightImpact();
                        _showComingSoon(context, 'Reminder settings');
                      },
                    ),
                  ),
                ]),

                const SizedBox(height: AppSpacing.xl2),

                // ── SUPPORT ──────────────────────────
                _buildSectionTitle('SUPPORT'),
                const SizedBox(height: AppSpacing.md),
                _buildSettingsGroup([
                  _SettingsTile(
                    icon: Icons.help_outline_rounded,
                    iconColor: const Color(0xFF0891B2),
                    title: 'Help & FAQ',
                    subtitle: 'Get help',
                    onTap: () => _showComingSoon(context, 'Help center'),
                  ),
                  _SettingsTile(
                    icon: Icons.star_rounded,
                    iconColor: const Color(0xFFFBBF24),
                    title: 'Rate App',
                    subtitle: 'Share your feedback',
                    onTap: () => _showComingSoon(context, 'App rating'),
                  ),
                  _SettingsTile(
                    icon: Icons.share_rounded,
                    iconColor: const Color(0xFF10B981),
                    title: 'Share App',
                    subtitle: 'Invite friends',
                    onTap: () => _showComingSoon(context, 'Share app'),
                  ),
                  _SettingsTile(
                    icon: Icons.privacy_tip_outlined,
                    iconColor: const Color(0xFF6B7280),
                    title: 'Privacy Policy',
                    onTap: () => _showComingSoon(context, 'Privacy policy'),
                  ),
                  _SettingsTile(
                    icon: Icons.description_outlined,
                    iconColor: const Color(0xFF6B7280),
                    title: 'Terms of Service',
                    onTap: () => _showComingSoon(context, 'Terms'),
                  ),
                ]),

                const SizedBox(height: AppSpacing.xl2),

                // ── ABOUT ─────────────────────────────
                _buildAboutCard(context),

                const SizedBox(height: AppSpacing.xl2),

                // ── LOGOUT ────────────────────────────
                _buildLogoutButton(context, ref),

                const SizedBox(height: AppSpacing.xl3),

                // ── FOOTER ────────────────────────────
                _buildFooter(),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PROFILE CARD
  // ============================================================

  Widget _buildProfileCard(
    BuildContext context,
    String userName,
    String email,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF00A86B),
            Color(0xFF007A4D),
          ],
        ),
        borderRadius: AppRadius.cardRadiusLarge,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.30),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              gradient: AppGradients.gold,
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.white.withValues(alpha: 0.30),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.40),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Center(
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                style: AppTextStyles.headlineMedium.copyWith(
                  color: AppColors.background,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName.isNotEmpty ? userName : 'Guest User',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  email.isNotEmpty ? email : 'Not signed in',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.white.withValues(alpha: 0.85),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.20),
                    borderRadius: AppRadius.pillRadius,
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.30),
                    ),
                  ),
                  child: Text(
                    'PREMIUM MEMBER',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 9,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Edit button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              _showComingSoon(context, 'Profile edit');
            },
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.20),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.edit_rounded,
                color: AppColors.white,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              gradient: AppGradients.gold,
              borderRadius: AppRadius.pillRadius,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            title,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.accent,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.0,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SETTINGS GROUP
  // ============================================================

  Widget _buildSettingsGroup(List<_SettingsTile> tiles) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.cardRadiusLarge,
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: Column(
        children: List.generate(tiles.length, (index) {
          return Column(
            children: [
              tiles[index],
              if (index < tiles.length - 1)
                Divider(
                  height: 1,
                  color: AppColors.borderSubtle.withValues(alpha: 0.5),
                  indent: 60,
                ),
            ],
          );
        }),
      ),
    );
  }

  // ============================================================
  // ABOUT CARD
  // ============================================================

  Widget _buildAboutCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.accent.withValues(alpha: 0.10),
            AppColors.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: AppRadius.cardRadiusLarge,
        border: Border.all(
          color: AppColors.accent.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: AppGradients.gold,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.40),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.mosque_rounded,
                  color: AppColors.background,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'About QIBRA AI',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your Islamic Companion',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.md),

          // Description
          Text(
            'QIBRA AI is an Islamic Super App designed to help Muslims with the Quran, Hadith, Prayer Times, Qibla, and AI-powered Islamic knowledge.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Version + Beta badge
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: AppRadius.pillRadius,
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.30),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.primary,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'v1.0.0',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFEF4444),
                      Color(0xFFDC2626),
                    ],
                  ),
                  borderRadius: AppRadius.pillRadius,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.40),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.science_rounded,
                      color: AppColors.white,
                      size: 12,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'BETA',
                      style: TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: AppSpacing.lg),

          // Divider
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  AppColors.accent.withValues(alpha: 0.30),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Developer info
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.code_rounded,
                  color: AppColors.accent,
                  size: 14,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Designed & Developed by',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textTertiary,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Shahbaz Alam',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOGOUT BUTTON
  // ============================================================

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => _showLogoutDialog(context, ref),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.10),
          borderRadius: AppRadius.cardRadius,
          border: Border.all(
            color: AppColors.error.withValues(alpha: 0.30),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.logout_rounded,
              color: AppColors.error,
              size: 18,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Logout',
              style: AppTextStyles.labelLarge.copyWith(
                color: AppColors.error,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // FOOTER
  // ============================================================

  Widget _buildFooter() {
    return Column(
      children: [
        // Gold divider with star
        Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppColors.accent.withValues(alpha: 0.30),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Icon(
                Icons.star_rounded,
                color: AppColors.accent.withValues(alpha: 0.60),
                size: 14,
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.accent.withValues(alpha: 0.30),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppSpacing.md),

        // Arabic phrase
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFFFFD700),
              Color(0xFFB8960C),
            ],
          ).createShader(bounds),
          child: const Text(
            'بَارَكَ اللَّهُ فِيك',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 20,
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
            textDirection: TextDirection.rtl,
          ),
        ),

        const SizedBox(height: 4),

        Text(
          'May Allah bless you',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.accent.withValues(alpha: 0.70),
            fontStyle: FontStyle.italic,
            fontSize: 10,
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // Copyright
        Text(
          '© 2026 Shahbaz Alam',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textTertiary,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'All Rights Reserved',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textTertiary,
            fontSize: 9,
          ),
        ),

        const SizedBox(height: AppSpacing.sm),

        Text(
          'QIBRA AI',
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textTertiary,
            fontWeight: FontWeight.w900,
            letterSpacing: 3.0,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  void _showComingSoon(BuildContext context, String feature) {
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.hourglass_empty_rounded,
              color: AppColors.white,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              '$feature coming soon',
              style: const TextStyle(color: AppColors.white),
            ),
          ],
        ),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.buttonRadius,
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardRadiusLarge,
        ),
        title: Row(
          children: [
            const Icon(
              Icons.logout_rounded,
              color: AppColors.error,
            ),
            const SizedBox(width: 8),
            Text(
              'Logout?',
              style: AppTextStyles.titleMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to logout from QIBRA AI?',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(authProvider.notifier).logout();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SETTINGS TILE WIDGET
// ============================================================

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.cardRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: AppRadius.buttonRadius,
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textTertiary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              // Trailing
              if (trailing != null)
                trailing!
              else if (onTap != null)
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textTertiary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
