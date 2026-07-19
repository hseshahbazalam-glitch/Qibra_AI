// lib/main.dart

// ============================================================
// QIBRA AI — Main Entry Point
// Version: 5.0.0 — With Gemini AI + Hadith Database
// ============================================================
import 'package:flutter/foundation.dart';
import 'package:qibra_ai/features/prayer/data/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qibra_ai/core/constants/app_constants.dart';
import 'package:qibra_ai/core/constants/app_assets_check.dart';
import 'package:qibra_ai/core/design_system/app_theme.dart';
import 'package:qibra_ai/core/di/service_locator.dart';
import 'package:qibra_ai/core/providers/theme_provider.dart';
import 'package:qibra_ai/core/router/app_router.dart';
import 'package:qibra_ai/features/hadith/data/services/hadith_database_service.dart';
import 'package:qibra_ai/features/quran/data/repository/quran_repository.dart';
import 'package:qibra_ai/features/quran/providers/audio_provider.dart';

// ============================================================
// GLOBAL HADITH DATABASE INSTANCE
// Accessible by AI service for RAG (Retrieval Augmented Generation)
// ============================================================

HadithDatabaseService? _globalHadithDb;
HadithDatabaseService? get globalHadithDb => _globalHadithDb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env file (Gemini API key)
  try {
    await dotenv.load(fileName: '.env');
    debugPrint('✅ .env loaded successfully');
  } catch (e) {
    debugPrint('⚠️ .env not loaded: $e');
  }

  // System UI setup
  AppSystemUI.setDarkTheme();
  await AppSystemUI.setPortraitOnly();

  // Assets check (debug only)
  assert(() {
    AppAssetsCheck.verifyAllAssets();
    return true;
  }());

  // Initialize Service Locator

  // Initialize Notification Service
  try {
    debugPrint('🔔 Initializing Notification Service...');
    await NotificationService.instance.initialize();
    debugPrint('✅ Notification Service ready');
  } catch (e) {
    debugPrint('⚠️ Notification Service failed: $e');
  }

  // Quran data load karo
  try {
    debugPrint('📖 Loading Quran data...');
    final quranRepo = QuranRepository();
    await quranRepo.initialize();
    debugPrint('✅ Quran data loaded successfully!');
    debugPrint('   📊 Stats: ${quranRepo.statistics}');
  } catch (e) {
    debugPrint('⚠️ Quran data loading failed: $e');
  }

  // Hadith database load karo (34,395 hadiths)
  try {
    debugPrint('📚 Loading Hadith database...');
    final hadithDb = HadithDatabaseService();
    await hadithDb.initialize();
    debugPrint('✅ Hadith database loaded!');
    debugPrint('   📊 Total: ${hadithDb.totalHadiths} hadiths');
    // Store globally for AI RAG access
    _globalHadithDb = hadithDb;
  } catch (e) {
    debugPrint('⚠️ Hadith database loading failed: $e');
  }

  // Boot info
  _printBootInfo();

  // Run app
  runApp(
    const ProviderScope(
      child: _AppWithAudio(),
    ),
  );
}

// ============================================================
// AUDIO PRE-WARMER
// ============================================================

class _AppWithAudio extends ConsumerWidget {
  const _AppWithAudio();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(quranAudioServiceProvider);
    return const QibraApp();
  }
}

// ============================================================
// ROOT APP WIDGET
// ============================================================

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

// ============================================================
// BOOT INFO LOGGER
// ============================================================

void _printBootInfo() {
  debugPrint('╔═══════════════════════════════════════╗');
  debugPrint('║       QIBRA AI — System Boot          ║');
  debugPrint('╠═══════════════════════════════════════╣');
  debugPrint('║  Name    : ${AppInfo.appName}');
  debugPrint('║  Version : ${AppInfo.version}');
  debugPrint('║  ✅ .env loaded');
  debugPrint('║  ✅ ServiceLocator ready');
  debugPrint('║  ✅ Riverpod initialized');
  debugPrint('║  ✅ Router ready');
  debugPrint('║  🤖 Gemini AI ready');
  debugPrint('║  📚 Hadith DB ready');
  debugPrint('╚═══════════════════════════════════════╝');
}
