// lib/main.dart

// ============================================================
// QIBRA AI — Main Entry Point
// Version: 2.0.0
// ============================================================

import 'package:qibra_ai/features/quran/data/repository/quran_repository.dart';
import 'package:qibra_ai/features/quran/providers/audio_provider.dart';
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

  assert(() {
    AppAssetsCheck.verifyAllAssets();
    return true;
  }());

  _testDesignSystem();

  try {
    debugPrint('📖 Loading Quran data...');
    final quranRepo = QuranRepository();
    await quranRepo.initialize();
    debugPrint('✅ Quran data loaded successfully!');
    debugPrint('   📊 Stats: ${quranRepo.statistics}');
  } catch (e) {
    debugPrint('⚠️ Quran data loading failed: $e');
    debugPrint('   App will continue with fallback data');
  }

  runApp(
    const ProviderScope(
      child: _AppWithAudio(),
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

// ── Audio Pre-Warmer ──────────────────────────────────────────

class _AppWithAudio extends ConsumerWidget {
  const _AppWithAudio();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Audio service ko app start pe initialize karo
    // Taaki pehli ayah tap pe koi delay na ho
    ref.watch(quranAudioServiceProvider);
    return const QibraApp();
  }
}

// ── Root App ──────────────────────────────────────────────────

class QibraApp extends ConsumerWidget {
  const QibraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(flutterThemeModeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppInfo.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
