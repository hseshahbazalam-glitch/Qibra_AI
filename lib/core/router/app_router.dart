// lib/core/router/app_router.dart

// ============================================================
// QIBRA AI — APP ROUTER (Riverpod Integrated)
// Version: 2.2.0
// Description: Router with SplashScreen + OnboardingScreen.
//              Auth state managed via Riverpod.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:qibra_ai/core/constants/app_constants.dart';
import 'package:qibra_ai/core/design_system/app_colors.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';
import 'package:qibra_ai/core/providers/auth_provider.dart';
import 'package:qibra_ai/core/providers/theme_provider.dart';
import 'package:qibra_ai/features/onboarding/presentation/onboarding_screen.dart';
import 'package:qibra_ai/features/splash/presentation/splash_screen.dart';

// ============================================================
// PLACEHOLDER SCREENS — Real screens baad mein aayenge
// ============================================================

// ── LOGIN PLACEHOLDER ──────────────────────────────────
class _LoginPlaceholder extends ConsumerWidget {
  const _LoginPlaceholder();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Login'),
        backgroundColor: AppColors.background,
      ),
      body: Center(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Login Screen', style: AppTextStyles.headlineLarge),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Step 15 mein real screen aayegi',
                style: AppTextStyles.bodyMedium.secondary,
              ),
              const SizedBox(height: AppSpacing.xl3),
              if (authState.errorMessage != null) ...[
                Container(
                  padding: AppSpacing.cardPadding,
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    borderRadius: AppRadius.cardRadius,
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Text(
                    authState.errorMessage!,
                    style: AppTextStyles.errorText,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              ElevatedButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        await ref.read(authProvider.notifier).login(
                              email: 'test@qibra.ai',
                              password: 'password123',
                            );
                      },
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Test Login'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextButton(
                onPressed: () => context.go(AppRoutes.register),
                child: const Text('Go to Register'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── REGISTER PLACEHOLDER ───────────────────────────────
class _RegisterPlaceholder extends ConsumerWidget {
  const _RegisterPlaceholder();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Register'),
        backgroundColor: AppColors.background,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Register Screen', style: AppTextStyles.headlineLarge),
            const SizedBox(height: AppSpacing.xl3),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.login),
              child: const Text('Back to Login'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── HOME PLACEHOLDER ───────────────────────────────────
class _HomePlaceholder extends ConsumerWidget {
  const _HomePlaceholder();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final userName = ref.watch(userDisplayNameProvider);
    final isDark = ref.watch(isDarkModeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Home'),
        backgroundColor: AppColors.background,
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              ref.read(themeProvider.notifier).toggleTheme();
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle,
              color: AppColors.primary,
              size: 64,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Welcome, $userName!',
              style: AppTextStyles.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            if (user != null)
              Text(
                user.email,
                style: AppTextStyles.bodyMedium.secondary,
              ),
            const SizedBox(height: AppSpacing.xl3),
            Container(
              padding: AppSpacing.cardPadding,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.cardRadius,
                border: Border.all(color: AppColors.borderSubtle),
              ),
              child: Column(
                children: [
                  Text(
                    '✅ Riverpod Integrated',
                    style: AppTextStyles.titleMedium.emerald,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Auth state managed by Riverpod\n'
                    'Router redirects automatic\n'
                    'Theme toggle works instantly',
                    style: AppTextStyles.bodySmall.secondary,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── FEATURE PLACEHOLDERS ───────────────────────────────

class _QuranPlaceholder extends StatelessWidget {
  const _QuranPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text('Quran Screen', style: AppTextStyles.headlineLarge),
      ),
    );
  }
}

class _PrayerPlaceholder extends StatelessWidget {
  const _PrayerPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text('Prayer Screen', style: AppTextStyles.headlineLarge),
      ),
    );
  }
}

class _HadithPlaceholder extends StatelessWidget {
  const _HadithPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text('Hadith Screen', style: AppTextStyles.headlineLarge),
      ),
    );
  }
}

class _AiChatPlaceholder extends StatelessWidget {
  const _AiChatPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text('AI Chat Screen', style: AppTextStyles.headlineLarge),
      ),
    );
  }
}

class _ProfilePlaceholder extends StatelessWidget {
  const _ProfilePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text('Profile Screen', style: AppTextStyles.headlineLarge),
      ),
    );
  }
}

class _SettingsPlaceholder extends StatelessWidget {
  const _SettingsPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Text('Settings Screen', style: AppTextStyles.headlineLarge),
      ),
    );
  }
}

// ── ERROR SCREEN ───────────────────────────────────────
class _ErrorScreen extends StatelessWidget {
  final String? message;
  const _ErrorScreen({this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: AppColors.error,
              size: 64,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text('Page Not Found', style: AppTextStyles.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message ?? 'The requested page does not exist.',
              style: AppTextStyles.bodyMedium.secondary,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl3),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.splash),
              child: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SHELL SCAFFOLD — Bottom Navigation
// ============================================================

class _ShellScaffold extends StatelessWidget {
  final Widget child;
  final String location;

  const _ShellScaffold({
    required this.child,
    required this.location,
  });

  int _getActiveIndex() {
    if (location.startsWith(AppRoutes.quran)) return 1;
    if (location.startsWith(AppRoutes.prayer)) return 2;
    if (location.startsWith(AppRoutes.hadith)) return 3;
    if (location.startsWith(AppRoutes.aiChat)) return 4;
    return 0;
  }

  void _onTabTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
        break;
      case 1:
        context.go(AppRoutes.quran);
        break;
      case 2:
        context.go(AppRoutes.prayer);
        break;
      case 3:
        context.go(AppRoutes.hadith);
        break;
      case 4:
        context.go(AppRoutes.aiChat);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final int activeIndex = _getActiveIndex();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: child,
      bottomNavigationBar: _AppBottomNavBar(
        activeIndex: activeIndex,
        onTap: (index) => _onTabTapped(context, index),
      ),
    );
  }
}

class _AppBottomNavBar extends StatelessWidget {
  final int activeIndex;
  final ValueChanged<int> onTap;

  const _AppBottomNavBar({
    required this.activeIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.navBackground,
        border: const Border(
          top: BorderSide(
            color: AppColors.borderSubtle,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.30),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Home',
                isActive: activeIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.menu_book_outlined,
                activeIcon: Icons.menu_book,
                label: 'Quran',
                isActive: activeIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.access_time_outlined,
                activeIcon: Icons.access_time_filled,
                label: 'Prayer',
                isActive: activeIndex == 2,
                onTap: () => onTap(2),
              ),
              _NavItem(
                icon: Icons.library_books_outlined,
                activeIcon: Icons.library_books,
                label: 'Hadith',
                isActive: activeIndex == 3,
                onTap: () => onTap(3),
              ),
              _NavItem(
                icon: Icons.smart_toy_outlined,
                activeIcon: Icons.smart_toy,
                label: 'AI',
                isActive: activeIndex == 4,
                onTap: () => onTap(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: AppDurations.fast,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: AppRadius.cardRadius,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: AppDurations.fast,
              child: Icon(
                isActive ? activeIcon : icon,
                key: ValueKey(isActive),
                color: isActive ? AppColors.primary : AppColors.navInactive,
                size: AppIconSizes.lg,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: AppDurations.fast,
              style: isActive
                  ? AppTextStyles.navLabelActive
                  : AppTextStyles.navLabelInactive,
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// ROUTER PROVIDER — Main Router
// ============================================================

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _RouterRefreshNotifier(ref);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    refreshListenable: refreshNotifier,

    errorBuilder: (context, state) => _ErrorScreen(
      message: state.error?.message,
    ),

    // ── REDIRECT LOGIC ─────────────────────────────────
    redirect: (context, state) {
      final String currentPath = state.matchedLocation;
      final authState = ref.read(authProvider);
      final hasSeenOnboarding = ref.read(onboardingProvider);

      // Loading state — splash pe rehne do
      if (authState.status == AuthStatus.initial ||
          authState.status == AuthStatus.loading) {
        if (currentPath != AppRoutes.splash) {
          return AppRoutes.splash;
        }
        return null;
      }

      // Splash screen pe hai — splash khud navigate karega
      if (currentPath == AppRoutes.splash) {
        return null;
      }

      // Onboarding screen — no redirect
      if (currentPath == AppRoutes.onboarding) return null;

      // Auth screens check
      final bool isAuthScreen = currentPath == AppRoutes.login ||
          currentPath == AppRoutes.register ||
          currentPath == AppRoutes.forgotPassword ||
          currentPath == AppRoutes.verifyOtp;

      if (!hasSeenOnboarding) return AppRoutes.onboarding;

      if (!authState.isAuthenticated && !isAuthScreen) {
        return AppRoutes.login;
      }

      if (authState.isAuthenticated && isAuthScreen) {
        return AppRoutes.home;
      }

      return null;
    },

    // ── ROUTES ─────────────────────────────────────────
    routes: [
      // Splash — REAL SplashScreen
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Onboarding — REAL OnboardingScreen
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Auth Routes
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const _LoginPlaceholder(),
        routes: [
          GoRoute(
            path: 'register',
            name: 'register',
            builder: (context, state) => const _RegisterPlaceholder(),
          ),
          GoRoute(
            path: 'forgot-password',
            name: 'forgot-password',
            builder: (context, state) => const _ErrorScreen(
              message: 'Forgot Password — Step 15 mein aayega',
            ),
          ),
          GoRoute(
            path: 'verify-otp',
            name: 'verify-otp',
            builder: (context, state) => const _ErrorScreen(
              message: 'OTP Verification — Step 15 mein aayega',
            ),
          ),
        ],
      ),

      // Main App with Bottom Nav
      ShellRoute(
        builder: (context, state, child) => _ShellScaffold(
          location: state.matchedLocation,
          child: child,
        ),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            builder: (context, state) => const _HomePlaceholder(),
          ),
          GoRoute(
            path: AppRoutes.quran,
            name: 'quran',
            builder: (context, state) => const _QuranPlaceholder(),
            routes: [
              GoRoute(
                path: 'surah',
                name: 'quran-surah',
                builder: (context, state) => const _QuranPlaceholder(),
              ),
              GoRoute(
                path: 'search',
                name: 'quran-search',
                builder: (context, state) => const _QuranPlaceholder(),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.prayer,
            name: 'prayer',
            builder: (context, state) => const _PrayerPlaceholder(),
            routes: [
              GoRoute(
                path: 'qibla',
                name: 'qibla',
                builder: (context, state) => const _PrayerPlaceholder(),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.hadith,
            name: 'hadith',
            builder: (context, state) => const _HadithPlaceholder(),
          ),
          GoRoute(
            path: AppRoutes.aiChat,
            name: 'ai-chat',
            builder: (context, state) => const _AiChatPlaceholder(),
          ),
          GoRoute(
            path: AppRoutes.profile,
            name: 'profile',
            builder: (context, state) => const _ProfilePlaceholder(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            name: 'settings',
            builder: (context, state) => const _SettingsPlaceholder(),
          ),
        ],
      ),
    ],
  );
});

// ============================================================
// ROUTER REFRESH NOTIFIER
// ============================================================

class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen<AuthState>(authProvider, (_, __) {
      notifyListeners();
    });
    ref.listen<bool>(onboardingProvider, (_, __) {
      notifyListeners();
    });
  }
}
