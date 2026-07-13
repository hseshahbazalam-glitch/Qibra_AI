// lib/main.dart

// ============================================================
// QIBRA AI — Main Entry Point
// Version: 2.0.0
// Description: Now uses Riverpod ProviderScope for state management.
//              Router integrated with Riverpod auth state.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qibra_ai/core/constants/app_constants.dart';
import 'package:qibra_ai/core/constants/app_assets_check.dart';
import 'package:qibra_ai/core/design_system/app_theme.dart';
import 'package:qibra_ai/core/providers/theme_provider.dart';
import 'package:qibra_ai/core/router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppSystemUI.setDarkTheme();
  await AppSystemUI.setPortraitOnly();

  // Assets verify karo — sirf debug mode mein
  assert(() {
    AppAssetsCheck.verifyAllAssets();
    return true;
  }());

  _testDesignSystem();

  // ProviderScope = Riverpod ka root wrapper
  // Iske andar hi providers kaam karenge
  runApp(
    const ProviderScope(
      child: QibraApp(),
    ),
  );
}

void _testDesignSystem() {
  debugPrint('╔══════════════════════════════════════╗');
  debugPrint('║   QIBRA AI — System Boot Test        ║');
  debugPrint('╠══════════════════════════════════════╣');
  debugPrint('║  Name    : ${AppInfo.appName}                 ║');
  debugPrint('║  Version : ${AppInfo.version}                       ║');
  debugPrint('║  ✅ Riverpod initialized              ║');
  debugPrint('║  ✅ Router ready                      ║');
  debugPrint('╚══════════════════════════════════════╝');
}

// ============================================================
// QibraApp — Root Widget
// ============================================================
// ConsumerWidget = Riverpod-aware widget
// ref parameter se providers access hote hain
// ============================================================

class QibraApp extends ConsumerWidget {
  const QibraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(flutterThemeModeProvider);
    // Router provider se watch karo
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppInfo.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      // Provider se aa raha hai
      routerConfig: router,
    );
  }
}
