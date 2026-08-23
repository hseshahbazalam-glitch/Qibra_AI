// lib/shared/widgets/navigation/app_bottom_nav.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/design_system/app_typography.dart';
import '../../../core/design_system/qibra_colors.dart';

class NavBarItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const NavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class AppBottomNav extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onTap;
  final List<NavBarItem> items;

  const AppBottomNav({
    super.key,
    required this.activeIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    return Material(
      color: colors.navBackground,
      elevation: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: colors.border)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 68,
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: _NavItem(
                      item: items[i],
                      isActive: activeIndex == i,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        onTap(i);
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.item,
    required this.isActive,
    required this.onTap,
    this.compact = false,
  });

  final NavBarItem item;
  final bool isActive;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    final color = isActive ? colors.primary : colors.textTertiary;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isActive ? item.activeIcon : item.icon,
              color: color,
              size: compact ? 18 : 22,
            ),
            SizedBox(height: compact ? 2 : 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                item.label,
                maxLines: 1,
                softWrap: false,
                style: AppTextStyles.labelSmall.copyWith(
                  color: color,
                  fontSize: compact ? 9 : 11,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppShellScaffold extends StatelessWidget {
  final Widget child;
  final String location;
  final VoidCallback onHomeTap;
  final VoidCallback onQuranTap;
  final VoidCallback onPrayerTap;
  final VoidCallback onHadithTap;
  final VoidCallback onAiTap;
  final VoidCallback onMoreTap;

  const AppShellScaffold({
    super.key,
    required this.child,
    required this.location,
    required this.onHomeTap,
    required this.onQuranTap,
    required this.onPrayerTap,
    required this.onHadithTap,
    required this.onAiTap,
    required this.onMoreTap,
  });

  int _getActiveIndex() {
    if (location.startsWith('/quran')) return 1;
    if (location.startsWith('/prayer/qibla') ||
        location.startsWith('/prayer/mosques')) {
      return 5;
    }
    if (location.startsWith('/prayer')) return 2;
    if (location.startsWith('/hadith')) return 3;
    if (location.startsWith('/ai-chat')) return 4;
    if (location.startsWith('/more') ||
        location.startsWith('/settings') ||
        location.startsWith('/profile') ||
        location.startsWith('/tools') ||
        location.startsWith('/bookmarks') ||
        location.startsWith('/dua') ||
        location.startsWith('/calendar') ||
        location.startsWith('/tasbih')) {
      return 5;
    }
    return 0;
  }

  void _handleTap(int index) {
    switch (index) {
      case 0:
        onHomeTap();
        break;
      case 1:
        onQuranTap();
        break;
      case 2:
        onPrayerTap();
        break;
      case 3:
        onHadithTap();
        break;
      case 4:
        onAiTap();
        break;
      case 5:
        onMoreTap();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    return Scaffold(
      backgroundColor: colors.background,
      body: child,
      bottomNavigationBar: AppBottomNav(
        activeIndex: _getActiveIndex(),
        onTap: _handleTap,
        items: const [
          NavBarItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: 'Home',
          ),
          NavBarItem(
            icon: Icons.menu_book_outlined,
            activeIcon: Icons.menu_book_rounded,
            label: 'Quran',
          ),
          NavBarItem(
            icon: Icons.access_time_outlined,
            activeIcon: Icons.access_time_filled_rounded,
            label: 'Prayer',
          ),
          NavBarItem(
            icon: Icons.library_books_outlined,
            activeIcon: Icons.library_books_rounded,
            label: 'Hadith',
          ),
          NavBarItem(
            icon: Icons.auto_awesome_outlined,
            activeIcon: Icons.auto_awesome_rounded,
            label: 'AI',
          ),
          NavBarItem(
            icon: Icons.grid_view_outlined,
            activeIcon: Icons.grid_view_rounded,
            label: 'More',
          ),
        ],
      ),
    );
  }
}
