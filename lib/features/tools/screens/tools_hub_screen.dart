import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/qibra_colors.dart';
import '../../../shared/widgets/qibra_ui.dart';

class ToolsHubScreen extends StatelessWidget {
  const ToolsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    return QibraPage(
      title: 'Islamic tools',
      onBack: () {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(AppRoutes.more);
        }
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            'Calculators and guides already in the app.',
            style: AppTextStyles.bodyMedium.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          for (final tool in _tools)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: QibraCard(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                onTap: () => context.push(tool.route),
                child: ListTile(
                  leading: Icon(tool.icon, color: colors.primary),
                  title: Text(
                    tool.title,
                    style: AppTextStyles.titleSmall.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    tool.subtitle,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: colors.textTertiary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Tool {
  const _Tool({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String route;
}

const _tools = [
  _Tool(
    title: 'Zakat calculator',
    subtitle: 'Estimate zakat due',
    icon: Icons.calculate_outlined,
    route: '/tools/zakat',
  ),
  _Tool(
    title: 'Hajj guide',
    subtitle: 'Rituals and steps',
    icon: Icons.mosque_outlined,
    route: '/tools/hajj',
  ),
  _Tool(
    title: 'Umrah guide',
    subtitle: 'Umrah sequence',
    icon: Icons.account_balance_outlined,
    route: '/tools/umrah',
  ),
  _Tool(
    title: 'Nikah guide',
    subtitle: 'Marriage in Islam',
    icon: Icons.favorite_border_rounded,
    route: '/tools/nikah',
  ),
  _Tool(
    title: 'Habit tracker',
    subtitle: 'Daily worship habits',
    icon: Icons.check_circle_outline,
    route: '/tools/habits',
  ),
  _Tool(
    title: 'Ramadan timer',
    subtitle: 'Suhoor and iftar',
    icon: Icons.nightlight_outlined,
    route: '/tools/ramadan',
  ),
  _Tool(
    title: 'Sadaqah tracker',
    subtitle: 'Log charity',
    icon: Icons.volunteer_activism_outlined,
    route: '/tools/sadaqah',
  ),
  _Tool(
    title: 'Tasbih',
    subtitle: 'Digital dhikr counter',
    icon: Icons.radio_button_checked,
    route: AppRoutes.tasbih,
  ),
  _Tool(
    title: 'Halal scanner',
    subtitle: 'Check products',
    icon: Icons.qr_code_scanner_rounded,
    route: '/tools/halal',
  ),
  _Tool(
    title: 'Asma ul Husna',
    subtitle: '99 names of Allah',
    icon: Icons.auto_awesome_outlined,
    route: '/tools/asma',
  ),
  _Tool(
    title: 'Islamic names',
    subtitle: 'Find a name',
    icon: Icons.badge_outlined,
    route: '/tools/names',
  ),
  _Tool(
    title: 'Inheritance',
    subtitle: 'Faraid calculator',
    icon: Icons.balance_outlined,
    route: '/tools/inheritance',
  ),
];
