// lib/features/more/presentation/more_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/qibra_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/widgets/qibra_ui.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = QibraColors.of(context);
    final name = ref.watch(userDisplayNameProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            QibraScreenHeader(
              title: 'More',
              subtitle: 'Tools, saved items, and account',
            ),
            QibraCard(
              onTap: () => context.go(AppRoutes.profile),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: colors.primary.withValues(alpha: 0.12),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : 'G',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: AppTextStyles.titleMedium.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email.isNotEmpty == true
                              ? user!.email
                              : 'Signed in as guest',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: colors.textTertiary),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const QibraSectionHeader(title: 'Worship'),
            _MoreGroup(
              items: [
                _MoreItem(
                  icon: Icons.explore_outlined,
                  title: 'Qibla',
                  subtitle: 'Compass and direction',
                  route: AppRoutes.qibla,
                ),
                _MoreItem(
                  icon: Icons.radio_button_checked,
                  title: 'Tasbih',
                  subtitle: 'Dhikr counter',
                  route: AppRoutes.tasbih,
                ),
                _MoreItem(
                  icon: Icons.volunteer_activism_outlined,
                  title: 'Duas',
                  subtitle: 'Supplications',
                  route: AppRoutes.dua,
                ),
                _MoreItem(
                  icon: Icons.calendar_month_outlined,
                  title: 'Islamic calendar',
                  subtitle: 'Hijri dates',
                  route: AppRoutes.islamicCalendar,
                ),
                _MoreItem(
                  icon: Icons.mosque_outlined,
                  title: 'Mosques',
                  subtitle: 'Find nearby mosques',
                  route: AppRoutes.mosques,
                ),
                _MoreItem(
                  icon: Icons.nights_stay_outlined,
                  title: 'Tahajjud',
                  subtitle: 'Night prayer window',
                  route: AppRoutes.tahajjud,
                ),
              ],
            ),
            const SizedBox(height: 24),
            const QibraSectionHeader(title: 'Library'),
            _MoreGroup(
              items: [
                _MoreItem(
                  icon: Icons.bookmark_border_rounded,
                  title: 'Bookmarks',
                  subtitle: 'Quran, Hadith, and Duas',
                  route: AppRoutes.bookmarks,
                ),
                _MoreItem(
                  icon: Icons.handyman_outlined,
                  title: 'Islamic tools',
                  subtitle: 'Zakat, Hajj, names, and more',
                  route: AppRoutes.tools,
                ),
              ],
            ),
            const SizedBox(height: 24),
            const QibraSectionHeader(title: 'Account'),
            _MoreGroup(
              items: [
                _MoreItem(
                  icon: Icons.family_restroom_outlined,
                  title: 'Family space',
                  subtitle: 'A shared space for your household',
                  route: AppRoutes.family,
                ),
                _MoreItem(
                  icon: Icons.person_outline_rounded,
                  title: 'Profile',
                  subtitle: 'Your account',
                  route: AppRoutes.profile,
                ),
                _MoreItem(
                  icon: Icons.settings_outlined,
                  title: 'Settings',
                  subtitle: 'Theme, prayer, and notifications',
                  route: AppRoutes.settings,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreItem {
  const _MoreItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
}

class _MoreGroup extends StatelessWidget {
  const _MoreGroup({required this.items});

  final List<_MoreItem> items;

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    return QibraCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            ListTile(
              leading: Icon(items[i].icon, color: colors.primary),
              title: Text(
                items[i].title,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                items[i].subtitle,
                style: AppTextStyles.bodySmall.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              trailing: Icon(
                Icons.chevron_right_rounded,
                color: colors.textTertiary,
              ),
              onTap: () => context.go(items[i].route),
            ),
            if (i < items.length - 1)
              Divider(height: 1, color: colors.border, indent: 72),
          ],
        ],
      ),
    );
  }
}
