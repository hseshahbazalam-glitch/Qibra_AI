// lib/features/settings/presentation/settings_screen.dart
// ============================================================
// QIBRA AI — Premium Settings Screen (FIXED)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:qibra_ai/core/constants/app_constants.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';
import 'package:qibra_ai/core/design_system/qibra_colors.dart';
import 'package:qibra_ai/core/l10n/app_strings.dart';
import 'package:qibra_ai/core/providers/auth_provider.dart';
import 'package:qibra_ai/core/providers/theme_provider.dart';
import 'package:qibra_ai/shared/widgets/qibra_ui.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = QibraColors.of(context);
    final user = ref.watch(currentUserProvider);
    final userName = ref.watch(userDisplayNameProvider);
    final isDark = ref.watch(isDarkModeProvider);
    final strings = AppStrings.of(context);

    return QibraPage(
      title: strings.settings,
      child: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                120,
              ),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // PROFILE CARD
                  _buildProfileCard(context, userName, user?.email ?? ''),
                  const SizedBox(height: AppSpacing.xl2),

                  _buildSectionTitle(context, 'App preferences'),
                  const SizedBox(height: AppSpacing.md),
                  _buildSettingsGroup(context, [
                    _SettingsTile(
                      icon: isDark ? Icons.dark_mode : Icons.light_mode,
                      iconColor: colors.accent,
                      title: 'Dark Mode',
                      subtitle: isDark ? 'Enabled' : 'Disabled',
                      trailing: Switch(
                        value: isDark,
                        activeThumbColor: colors.primary,
                        onChanged: (_) {
                          HapticFeedback.lightImpact();
                          ref.read(themeProvider.notifier).toggleTheme();
                        },
                      ),
                    ),
                    _SettingsTile(
                      icon: Icons.language_rounded,
                      iconColor: colors.primarySoft,
                      title: strings.language,
                      subtitle: 'English',
                      onTap: () => _showLanguageSheet(context),
                    ),
                    _SettingsTile(
                      icon: Icons.text_fields_rounded,
                      iconColor: colors.goldText,
                      title: 'Font Size',
                      subtitle: 'Medium',
                      onTap: () => _showComingSoon(context, 'Font size'),
                    ),
                  ]),

                  const SizedBox(height: AppSpacing.xl2),

                  // ISLAMIC SETTINGS
                  _buildSectionTitle(context, 'Islamic preferences'),
                  const SizedBox(height: AppSpacing.md),
                  _buildSettingsGroup(context, [
                    _SettingsTile(
                      icon: Icons.access_time_filled_rounded,
                      iconColor: colors.primary,
                      title: 'Prayer Times',
                      subtitle: 'Calculation method',
                      onTap: () => context.go(AppRoutes.prayer),
                    ),
                    _SettingsTile(
                      icon: Icons.headphones_rounded,
                      iconColor: colors.accent,
                      title: 'Quran Reciter',
                      subtitle: 'Recitation not bundled',
                      onTap: () =>
                          _showComingSoon(context, 'Reciter selection'),
                    ),
                    _SettingsTile(
                      icon: Icons.translate_rounded,
                      iconColor: colors.primarySoft,
                      title: 'Translation',
                      subtitle: 'English',
                      onTap: () => _showComingSoon(context, 'Translation'),
                    ),
                    _SettingsTile(
                      icon: Icons.explore_rounded,
                      iconColor: colors.accent,
                      title: 'Qibla Direction',
                      subtitle: 'Auto-detect',
                      onTap: () => context.go(AppRoutes.qibla),
                    ),
                  ]),

                  const SizedBox(height: AppSpacing.xl2),

                  // NOTIFICATIONS
                  _buildSectionTitle(context, 'Notifications'),
                  const SizedBox(height: AppSpacing.md),
                  _buildSettingsGroup(context, [
                    _SettingsTile(
                      icon: Icons.notifications_active_rounded,
                      iconColor: const Color(0xFFEF4444),
                      title: 'Prayer Notifications',
                      subtitle: 'Azan alerts & reminders',
                      onTap: () => context.push('/settings/notifications'),
                    ),
                    _SettingsTile(
                      icon: Icons.notification_add_rounded,
                      iconColor: colors.accent,
                      title: 'Daily Reminders',
                      subtitle: 'Adhkar, Quran & Jummah',
                      onTap: () => context.push('/settings/notifications'),
                    ),
                  ]),

                  const SizedBox(height: AppSpacing.xl2),

                  // SUPPORT
                  _buildSectionTitle(context, 'Support'),
                  const SizedBox(height: AppSpacing.md),
                  _buildSettingsGroup(context, [
                    _SettingsTile(
                      icon: Icons.help_outline_rounded,
                      iconColor: colors.primarySoft,
                      title: 'Help & FAQ',
                      subtitle: 'Get help',
                      onTap: () => _showComingSoon(context, 'Help center'),
                    ),
                    _SettingsTile(
                      icon: Icons.star_rounded,
                      iconColor: colors.accent,
                      title: 'Rate App',
                      subtitle: 'Share your feedback',
                      onTap: () => _showComingSoon(context, 'App rating'),
                    ),
                    _SettingsTile(
                      icon: Icons.share_rounded,
                      iconColor: colors.primarySoft,
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

                  // ABOUT
                  _buildAboutCard(context),

                  const SizedBox(height: AppSpacing.xl2),

                  // LOGOUT
                  _buildLogoutButton(context, ref),

                  const SizedBox(height: AppSpacing.xl3),

                  // FOOTER
                  _buildFooter(context),
                ]),
              ),
            ),
          ],
        ),
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
    final colors = QibraColors.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.primary,
        borderRadius: AppRadius.cardRadiusLarge,
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.30),
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
                color: colors.onPrimary.withValues(alpha: 0.30),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.accent.withValues(alpha: 0.40),
                  blurRadius: 12,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Center(
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                style: AppTextStyles.headlineMedium.copyWith(
                  color: colors.background,
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
                    color: colors.onPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  email.isNotEmpty ? email : 'Not signed in',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: colors.onPrimary.withValues(alpha: 0.85),
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
                    color: colors.onPrimary.withValues(alpha: 0.20),
                    borderRadius: AppRadius.pillRadius,
                    border: Border.all(
                      color: colors.onPrimary.withValues(alpha: 0.30),
                    ),
                  ),
                  child: Text(
                    AppStrings.of(context).guest,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: colors.onPrimary,
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
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors.onPrimary.withValues(alpha: 0.20),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.edit_rounded,
                color: colors.onPrimary,
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

  Widget _buildSectionTitle(BuildContext context, String title) {
    final colors = QibraColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: AppSpacing.sm),
      child: Text(
        title,
        style: AppTextStyles.labelSmall.copyWith(
          color: colors.goldText,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }

  // ============================================================
  // SETTINGS GROUP
  // ============================================================

  Widget _buildSettingsGroup(BuildContext context, List<_SettingsTile> tiles) {
    final colors = QibraColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.cardRadiusLarge,
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: List.generate(tiles.length, (index) {
          return Column(
            children: [
              tiles[index],
              if (index < tiles.length - 1)
                Divider(
                  height: 1,
                  color: colors.border.withValues(alpha: 0.5),
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
    final colors = QibraColors.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.accent.withValues(alpha: 0.10),
            colors.primary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: AppRadius.cardRadiusLarge,
        border: Border.all(
          color: colors.accent.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                      color: colors.accent.withValues(alpha: 0.40),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.mosque_rounded,
                  color: colors.background,
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
                        color: colors.accent,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Your Islamic Companion',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: colors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'QIBRA AI is an Islamic Super App designed to help Muslims with the Quran, Hadith, Prayer Times, Qibla, and AI-powered Islamic knowledge.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: colors.textSecondary,
              height: 1.6,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.15),
                  borderRadius: AppRadius.pillRadius,
                  border: Border.all(
                    color: colors.primary.withValues(alpha: 0.30),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      color: colors.primary,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'v1.0.0',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: colors.primary,
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
                  children: [
                    Icon(
                      Icons.science_rounded,
                      color: colors.onPrimary,
                      size: 12,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'BETA',
                      style: TextStyle(
                        color: colors.onPrimary,
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
          Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  colors.accent.withValues(alpha: 0.30),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.code_rounded,
                  color: colors.accent,
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
                        color: colors.textTertiary,
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Shahbaz Alam',
                      style: AppTextStyles.titleSmall.copyWith(
                        color: colors.textPrimary,
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
    final colors = QibraColors.of(context);
    return GestureDetector(
      onTap: () => _showLogoutDialog(context, ref),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.error.withValues(alpha: 0.10),
          borderRadius: AppRadius.cardRadius,
          border: Border.all(
            color: colors.error.withValues(alpha: 0.30),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.logout_rounded,
              color: colors.error,
              size: 18,
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Logout',
              style: AppTextStyles.labelLarge.copyWith(
                color: colors.error,
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

  Widget _buildFooter(BuildContext context) {
    final colors = QibraColors.of(context);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      colors.accent.withValues(alpha: 0.30),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Icon(
                Icons.star_rounded,
                color: colors.accent.withValues(alpha: 0.60),
                size: 14,
              ),
            ),
            Expanded(
              child: Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors.accent.withValues(alpha: 0.30),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [
              Color(0xFFC6A15B),
              Color(0xFFB8960C),
            ],
          ).createShader(bounds),
          child: const Text(
            'بَارَكَ اللَّهُ فِيك',
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 20,
              color: const Color(0xFF19312C),
              fontWeight: FontWeight.w700,
            ),
            textDirection: TextDirection.rtl,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'May Allah bless you',
          style: AppTextStyles.labelSmall.copyWith(
            color: colors.accent.withValues(alpha: 0.70),
            fontStyle: FontStyle.italic,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          '© 2026 Shahbaz Alam',
          style: AppTextStyles.labelSmall.copyWith(
            color: colors.textTertiary,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'All Rights Reserved',
          style: AppTextStyles.labelSmall.copyWith(
            color: colors.textTertiary,
            fontSize: 9,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          'QIBRA AI',
          style: AppTextStyles.labelSmall.copyWith(
            color: colors.textTertiary,
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

  void _showLanguageSheet(BuildContext context) {
    final colors = QibraColors.of(context);
    final strings = AppStrings.of(context);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final sheetColors = QibraColors.of(ctx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.language,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: sheetColors.goldText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                for (final entry in const [
                  ('en', 'English'),
                  ('ar', 'العربية'),
                  ('ur', 'اردو'),
                ])
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      entry.$2,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: sheetColors.textPrimary,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${entry.$2}',
                            style: TextStyle(color: sheetColors.onPrimary),
                          ),
                          backgroundColor: sheetColors.primary,
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    final colors = QibraColors.of(context);
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.hourglass_empty_rounded,
              color: colors.onPrimary,
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              '$feature coming soon',
              style: TextStyle(color: colors.onPrimary),
            ),
          ],
        ),
        backgroundColor: colors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.buttonRadius,
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    final colors = QibraColors.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.cardRadiusLarge,
        ),
        title: Row(
          children: [
            Icon(
              Icons.logout_rounded,
              color: colors.error,
            ),
            const SizedBox(width: 8),
            Text(
              'Logout?',
              style: AppTextStyles.titleMedium.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to logout from QIBRA AI?',
          style: AppTextStyles.bodyMedium.copyWith(
            color: colors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: TextStyle(
                color: colors.textSecondary,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: colors.error,
              foregroundColor: colors.onPrimary,
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
    final colors = QibraColors.of(context);
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
                width: 48,
                height: 48,
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
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: colors.textTertiary,
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
                  color: colors.textTertiary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
