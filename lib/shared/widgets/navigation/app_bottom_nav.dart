// lib/shared/widgets/navigation/app_bottom_nav.dart

// ============================================================
// QIBRA AI — PREMIUM BOTTOM NAVIGATION
// Version: 1.0.0
// Description: Custom bottom navigation with center FAB,
//              badges, animations, and Islamic design.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qibra_ai/core/design_system/app_colors.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';

// ============================================================
// NAV ITEM DATA MODEL
// ============================================================

class NavBarItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int? badgeCount;

  const NavBarItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badgeCount,
  });
}

// ============================================================
// APP BOTTOM NAV WIDGET
// ============================================================

class AppBottomNav extends StatelessWidget {
  /// Currently active tab index
  final int activeIndex;

  /// Tab press handler
  final ValueChanged<int> onTap;

  /// Center FAB press handler (Quran quick access)
  final VoidCallback? onCenterTap;

  /// Nav items list
  final List<NavBarItem> items;

  /// Show center FAB?
  final bool showCenterFab;

  const AppBottomNav({
    super.key,
    required this.activeIndex,
    required this.onTap,
    required this.items,
    this.onCenterTap,
    this.showCenterFab = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navBackground,
        // Top border
        border: const Border(
          top: BorderSide(
            color: AppColors.borderSubtle,
            width: 1,
          ),
        ),
        // Elevation shadow (upward)
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.30),
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 40,
            offset: const Offset(0, -12),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 70,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // ── NAV ITEMS ROW ──────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: _buildNavItems(),
                ),
              ),

              // ── CENTER FAB ─────────────────────────
              if (showCenterFab)
                Positioned(
                  top: -24,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: _CenterFab(onTap: onCenterTap),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── BUILD NAV ITEMS WITH CENTER SPACE ────────────────
  List<Widget> _buildNavItems() {
    final List<Widget> widgets = [];

    for (int i = 0; i < items.length; i++) {
      // Center FAB space add karo middle mein
      if (showCenterFab && i == items.length ~/ 2) {
        widgets.add(const SizedBox(width: 56));
      }

      widgets.add(
        _NavBarItemWidget(
          item: items[i],
          isActive: activeIndex == i,
          onTap: () {
            HapticFeedback.selectionClick();
            onTap(i);
          },
        ),
      );
    }

    return widgets;
  }
}

// ============================================================
// SINGLE NAV BAR ITEM WIDGET
// ============================================================

class _NavBarItemWidget extends StatelessWidget {
  final NavBarItem item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavBarItemWidget({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ── ICON WITH BADGE ────────────────────
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Animated icon
                AnimatedSwitcher(
                  duration: AppDurations.fast,
                  transitionBuilder: (child, animation) {
                    return ScaleTransition(
                      scale: animation,
                      child: child,
                    );
                  },
                  child: Icon(
                    isActive ? item.activeIcon : item.icon,
                    key: ValueKey(isActive),
                    color: isActive ? AppColors.primary : AppColors.navInactive,
                    size: AppIconSizes.lg,
                  ),
                ),

                // Badge (if count > 0)
                if (item.badgeCount != null && item.badgeCount! > 0)
                  Positioned(
                    top: -4,
                    right: -8,
                    child: _NavBadge(count: item.badgeCount!),
                  ),
              ],
            ),

            const SizedBox(height: 4),

            // ── LABEL ──────────────────────────────
            AnimatedDefaultTextStyle(
              duration: AppDurations.fast,
              style: isActive
                  ? AppTextStyles.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    )
                  : AppTextStyles.labelSmall.copyWith(
                      color: AppColors.navInactive,
                      fontWeight: FontWeight.w500,
                      fontSize: 11,
                    ),
              child: Text(item.label),
            ),

            const SizedBox(height: 2),

            // ── ACTIVE INDICATOR DOT ───────────────
            AnimatedContainer(
              duration: AppDurations.normal,
              curve: Curves.easeInOut,
              width: isActive ? 20 : 0,
              height: 3,
              decoration: BoxDecoration(
                gradient: isActive ? AppGradients.emerald : null,
                borderRadius: AppRadius.pillRadius,
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.50),
                          blurRadius: 6,
                          spreadRadius: 0,
                        ),
                      ]
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// NAV BADGE (Notification count)
// ============================================================

class _NavBadge extends StatelessWidget {
  final int count;

  const _NavBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 5,
        vertical: 2,
      ),
      constraints: const BoxConstraints(
        minWidth: 18,
        minHeight: 18,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.error,
            AppColors.error.withValues(alpha: 0.80),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.navBackground,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.error.withValues(alpha: 0.50),
            blurRadius: 6,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Center(
        child: Text(
          count > 99 ? '99+' : '$count',
          style: TextStyle(
            color: AppColors.white,
            fontSize: count > 9 ? 8 : 10,
            fontWeight: FontWeight.w800,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}

// ============================================================
// CENTER FAB (Quran Quick Access)
// ============================================================

class _CenterFab extends StatefulWidget {
  final VoidCallback? onTap;

  const _CenterFab({this.onTap});

  @override
  State<_CenterFab> createState() => _CenterFabState();
}

class _CenterFabState extends State<_CenterFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.90,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (widget.onTap != null) _controller.forward();
      },
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: () {
        HapticFeedback.mediumImpact();
        widget.onTap?.call();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppGradients.gold,
            // Multiple shadows for premium glow
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.50),
                blurRadius: 20,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.30),
                blurRadius: 40,
                spreadRadius: 4,
              ),
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.40),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Inner ring
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.white.withValues(alpha: 0.30),
                    width: 1.5,
                  ),
                ),
              ),

              // Icon
              const Icon(
                Icons.mosque_rounded,
                color: AppColors.background,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// APP SHELL SCAFFOLD — Complete Bottom Nav Container
// ============================================================
// Yeh main widget hai jo router mein use hoga
// Screens + Bottom Nav dono handle karta hai
// ============================================================

class AppShellScaffold extends StatelessWidget {
  /// Current screen content
  final Widget child;

  /// Current location/path
  final String location;

  /// Home route pe click hone par
  final VoidCallback onHomeTap;

  /// Quran route pe click hone par
  final VoidCallback onQuranTap;

  /// Prayer route pe click hone par
  final VoidCallback onPrayerTap;

  /// Hadith route pe click hone par
  final VoidCallback onHadithTap;

  /// AI route pe click hone par
  final VoidCallback onAiTap;

  /// Center FAB press (Quick Quran)
  final VoidCallback onCenterFabTap;

  /// Notification count (for future)
  final int? notificationCount;

  const AppShellScaffold({
    super.key,
    required this.child,
    required this.location,
    required this.onHomeTap,
    required this.onQuranTap,
    required this.onPrayerTap,
    required this.onHadithTap,
    required this.onAiTap,
    required this.onCenterFabTap,
    this.notificationCount,
  });

  // Active tab index calculate karo current location se
  int _getActiveIndex() {
    if (location.startsWith('/quran')) return 1;
    if (location.startsWith('/prayer')) return 2;
    if (location.startsWith('/hadith')) return 3;
    if (location.startsWith('/ai-chat')) return 4;
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // Extend body behind bottom nav (for FAB overlap)
      extendBody: true,
      body: child,
      bottomNavigationBar: AppBottomNav(
        activeIndex: _getActiveIndex(),
        onTap: _handleTap,
        onCenterTap: onCenterFabTap,
        items: [
          // Home
          const NavBarItem(
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            label: 'Home',
          ),
          // Quran
          const NavBarItem(
            icon: Icons.menu_book_outlined,
            activeIcon: Icons.menu_book_rounded,
            label: 'Quran',
          ),
          // Prayer (with notification badge example)
          NavBarItem(
            icon: Icons.access_time_outlined,
            activeIcon: Icons.access_time_filled_rounded,
            label: 'Prayer',
            badgeCount: notificationCount,
          ),
          // Hadith
          const NavBarItem(
            icon: Icons.library_books_outlined,
            activeIcon: Icons.library_books_rounded,
            label: 'Hadith',
          ),
          // AI Chat
          const NavBarItem(
            icon: Icons.smart_toy_outlined,
            activeIcon: Icons.smart_toy_rounded,
            label: 'AI',
          ),
        ],
      ),
    );
  }
}
