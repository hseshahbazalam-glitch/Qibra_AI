// lib/core/constants/app_assets_check.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:qibra_ai/core/design_system/app_design_system.dart';

abstract final class AppAssetsCheck {
  static const List<String> registeredAssets = [
    AppAssets.logo,
    AppAssets.splashBackground,
    AppAssets.homeHeroBg,
    AppAssets.patternTile,
    AppAssets.hadithArt,
    AppAssets.aiArt,
    AppAssets.onboarding1,
    AppAssets.onboarding2,
    AppAssets.iconQuran,
    AppAssets.iconPrayer,
    AppAssets.iconQibla,
    AppAssets.iconHadith,
    AppAssets.iconAI,
    AppAssets.iconCalendar,
    AppAssets.iconTasbih,
    AppAssets.iconDua,
  ];

  static Future<void> verifyAllAssets() async {
    if (kDebugMode) debugPrint('╔══════════════════════════════════════╗');
    if (kDebugMode) debugPrint('║   QIBRA AI — Assets Verification     ║');
    if (kDebugMode) debugPrint('╠══════════════════════════════════════╣');

    int found = 0;
    int missing = 0;

    for (final asset in registeredAssets) {
      try {
        await rootBundle.load(asset);
        found++;
        // PASS X2 (print diet): the per-asset '║  OK …' row printed one line per
        // registered asset INSIDE this boot loop (16 reads, 16 rows, a table nobody
        // acts on while everything is fine). Success is the summary count below;
        // only a MISSING asset still gets its own row.
      } catch (e) {
        missing++;
        if (kDebugMode) debugPrint('║  MISSING: $asset');
      }
    }

    if (kDebugMode) debugPrint('╠══════════════════════════════════════╣');
    if (kDebugMode) debugPrint('║  Found  : $found/${registeredAssets.length}');
    if (kDebugMode) debugPrint('║  Missing: $missing/${registeredAssets.length}');
    if (kDebugMode) debugPrint('╚══════════════════════════════════════╝');
  }

  static Future<bool> assetExists(String path) async {
    try {
      await rootBundle.load(path);
      return true;
    } catch (_) {
      return false;
    }
  }
}
