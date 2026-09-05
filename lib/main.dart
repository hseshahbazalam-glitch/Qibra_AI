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
import 'package:go_router/go_router.dart';
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

  // Inter (Latin) and Amiri (Arabic) are bundled in assets/fonts and
  // registered under fonts: in pubspec.yaml — the runtime CDN font package
  // is no longer a dependency, so no text style can depend on a fetch.

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
  AppSystemUI.setDarkTheme();
  await AppSystemUI.setPortraitOnly();

  // ─── Assets Check (Debug Only) ─────────────────────────
  assert(() {
    AppAssetsCheck.verifyAllAssets();
    return true;
  }());

  // ─── Notification Service + Quran Data ─────────────────
  // (Perf pass item 2) Both heavy awaits moved OUT of the pre-runApp
  // path: they now run in dataBootstrapProvider
  // (lib/core/providers/app_providers.dart), started by the splash's
  // first frame — runApp is no longer gated on corpus decode. The
  // timezone DB above STAYS pre-runApp on purpose: it is a synchronous,
  // in-memory IANA table registration, and prayer math reads it from
  // its own first frame (documented per owner instruction; no screen
  // blocks on it).

  // ─── Notification tap routing (P1 · Item 1) ─────────────────
  // 'dua:<id>' payloads open that dua's detail through the router.
  // All other payloads keep existing behavior (tap foregrounds the
  // app; the prayer/adhkar channels never navigated and still don't).
  NotificationService.onNotificationTap = (payload) {
    if (!payload.startsWith('dua:')) return;
    final id = Uri.encodeComponent(payload.substring('dua:'.length));
    if (id.isEmpty) return;
    void navigate(int attemptsLeft) {
      final ctx = rootNavigatorKey.currentContext;
      if (ctx == null) {
        // Cold start: the router's navigator may not exist yet for a
        // frame or two — retry on post-frame, then give up quietly.
        if (attemptsLeft > 0) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) => navigate(attemptsLeft - 1));
        }
        return;
      }
      GoRouter.of(ctx).push('${AppRoutes.duaDetail}?id=$id');
    }

    navigate(30);
  };

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
