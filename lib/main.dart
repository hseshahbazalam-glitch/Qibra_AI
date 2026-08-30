// lib/main.dart
// ============================================================
// QIBRA AI — Main Entry Point
// Version: 6.0.0 — Clean (No Audio, New AI System)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qibra_ai/core/services/notification_service.dart';
import 'package:qibra_ai/core/constants/app_constants.dart';
import 'package:qibra_ai/core/constants/app_assets_check.dart';
import 'package:qibra_ai/core/design_system/app_theme.dart';
import 'package:qibra_ai/core/l10n/app_locales.dart';
import 'package:qibra_ai/core/l10n/app_strings.dart';
import 'package:qibra_ai/core/providers/theme_provider.dart';
import 'package:qibra_ai/core/router/app_router.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:qibra_ai/features/hadith/data/services/hadith_database_service.dart';
import 'package:qibra_ai/features/quran/data/repository/quran_repository.dart';
import 'package:qibra_ai/features/ai/services/rag_service.dart';

// ============================================================
// GLOBAL HADITH DATABASE INSTANCE
// ============================================================

HadithDatabaseService? _globalHadithDb;
HadithDatabaseService? get globalHadithDb => _globalHadithDb;

// ============================================================
// MAIN ENTRY POINT
// ============================================================

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ─── Timezone DB (Phase 2: IANA for exact prayer timezone) ─────
  try {
    tz_data.initializeTimeZones();
    debugPrint('✅ Timezone DB initialized');
  } catch (e) {
    debugPrint('⚠️ Timezone DB failed: $e');
  }

  // ─── Load .env (debug only, not bundled in release) ────────────
  try {
    await dotenv.load(fileName: '.env');
    debugPrint('✅ .env loaded successfully');
  } catch (e) {
    debugPrint('⚠️ .env not loaded: $e');
  }

  // ─── System UI Setup ─────────────────────────
  AppSystemUI.setLightTheme();
  await AppSystemUI.setPortraitOnly();

  // ─── Assets Check (Debug Only) ─────────────────────────
  assert(() {
    AppAssetsCheck.verifyAllAssets();
    return true;
  }());

  // ─── Notification Service ─────────────────────────
  try {
    debugPrint('🔔 Initializing Notification Service...');
    await NotificationService().initialize();
    debugPrint('✅ Notification Service ready');
  } catch (e) {
    debugPrint('⚠️ Notification Service failed: $e');
  }

  // ─── Quran Data ─────────────────────────
  try {
    debugPrint('📖 Loading Quran data...');
    final quranRepo = QuranRepository();
    await quranRepo.initialize();
    debugPrint('✅ Quran data loaded successfully!');
  } catch (e) {
    debugPrint('⚠️ Quran data loading failed: $e');
  }

  // ─── Hadith Database ─────────────────────────
  try {
    debugPrint('📚 Loading Hadith database...');
    final hadithDb = HadithDatabaseService();
    await hadithDb.initialize();
    debugPrint('✅ Hadith database loaded!');
    debugPrint('   📊 Total: ${hadithDb.totalHadiths} hadiths');
    _globalHadithDb = hadithDb;
    // Attach to RAG for offline retrieval
    try {
      RagService.instance.attachHadithDb(hadithDb);
      debugPrint('✅ RAG attached to Hadith DB');
    } catch (_) {}
  } catch (e) {
    debugPrint('⚠️ Hadith database loading failed: $e');
  }

  // ─── Boot Info ─────────────────────────
  _printBootInfo();

  // ─── Run App ─────────────────────────
  runApp(
    const ProviderScope(
      child: QibraApp(),
    ),
  );
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
      theme: AppTheme.light,
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
  debugPrint('║  ✅ Riverpod initialized');
  debugPrint('║  ✅ Router ready');
  debugPrint('║  📖 Quran data ready');
  debugPrint('║  📚 Hadith DB ready');
  debugPrint('║  🤖 AI Engine ready');
  debugPrint('╚═══════════════════════════════════════╝');
}
