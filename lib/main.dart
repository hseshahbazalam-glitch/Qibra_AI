// lib/main.dart
// ============================================================
// QIBRA AI — Main Entry Point
// Version: 6.0.0 — Clean (No Audio, New AI System)
// ============================================================

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
    NotificationService.markTimeZonesInitialized();
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
  AppSystemUI.setDarkTheme();
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

  // ─── Boot Info ─────────────────────────
  _printBootInfo();

  // ─── Run App ─────────────────────────
  runApp(
    const ProviderScope(
      child: QibraApp(),
    ),
  );

  // Hadith corpus is large; screens call initialize() if still loading.
  unawaited(_loadHadithInBackground());
}

Future<void> _loadHadithInBackground() async {
  try {
    debugPrint('📚 Loading Hadith database...');
    final hadithDb = HadithDatabaseService();
    await hadithDb.initialize();
    debugPrint('✅ Hadith database loaded!');
    _globalHadithDb = hadithDb;
    try {
      RagService.instance.attachHadithDb(hadithDb);
    } catch (_) {}
  } catch (e) {
    debugPrint('⚠️ Hadith database loading failed: $e');
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
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: AppInfo.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      locale: locale,
      supportedLocales: AppLocales.supported,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      localeResolutionCallback: (requested, _) => AppLocales.resolve(requested),
      builder: (context, child) {
        return AppStringsScope(
          locale: locale,
          child: child ?? const SizedBox.shrink(),
        );
      },
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
  debugPrint('║  📚 Hadith DB loading after first frame');
  debugPrint('║  🤖 AI Engine ready');
  debugPrint('╚═══════════════════════════════════════╝');
}
