// lib/features/settings/presentation/user_profile_screen.dart
// ===========================================================
// QIBRA AI — USER PROFILE SCREEN (placeholder, previously missing)
// ===========================================================
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/design_system/app_colors.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/qibra_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/widgets/media/safe_image.dart';
import '../../../shared/widgets/qibra_ui.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({super.key});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return QibraPage(
      title: 'My Profile',
      onBack: () {
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          context.go(AppRoutes.settings);
        }
      },
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 12),
              // Avatar
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.accent],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.6),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.35),
                        blurRadius: 24,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const SafeImage(
                    assetPath: 'assets/images/logo.png',
                    width: 100,
                    height: 100,
                    fallback: SafeImageFallback.logo,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'QIBRA User',
                style: AppTextStyles.headlineSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'May Allah accept your worship 🤲',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 28),
              _buildTile(
                icon: Icons.edit_rounded,
                title: 'Edit Profile',
                subtitle: 'Name, email, photo',
                accent: AppColors.primary,
              ),
              _buildTile(
                icon: Icons.notifications_active_rounded,
                title: 'Notifications',
                subtitle: 'Adhan, reminders, alerts',
                accent: AppColors.accent,
                onTap: () => context.push('/settings/notifications'),
              ),
              _buildTile(
                icon: Icons.translate_rounded,
                title: 'Language',
                subtitle: 'English / العربية / اردو',
                accent: AppColors.primaryLight,
              ),
              _buildTile(
                icon: Icons.palette_rounded,
                title: 'Appearance',
                subtitle: 'Theme, font size',
                accent: AppColors.accent,
              ),
              _buildTile(
                icon: Icons.shield_rounded,
                title: 'Privacy & Security',
                subtitle: 'Data, permissions',
                accent: AppColors.success,
              ),
              _buildTile(
                icon: Icons.help_outline_rounded,
                title: 'Help & Support',
                subtitle: 'FAQ, contact us',
                accent: AppColors.info,
              ),
              _buildTile(
                icon: Icons.logout_rounded,
                title: 'Sign Out',
                subtitle: 'Log out of your account',
                accent: AppColors.error,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color accent,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: accent.withValues(alpha: 0.3)),
                  ),
                  child: Icon(icon, color: accent, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: AppTextStyles.titleSmall.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                          )),
                      const SizedBox(height: 2),
                      Text(subtitle,
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          )),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textDisabled, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
