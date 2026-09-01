// lib/core/constants/app_assets_check.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design_system/app_design_system.dart';

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
    debugPrint('╔══════════════════════════════════════╗');
    debugPrint('║   QIBRA AI — Assets Verification     ║');
    debugPrint('╠══════════════════════════════════════╣');

    int found = 0;
    int missing = 0;

    for (final asset in registeredAssets) {
      try {
        await rootBundle.load(asset);
        found++;
        debugPrint('║  OK $asset');
      } catch (e) {
        missing++;
        debugPrint('║  MISSING: $asset');
      }
    }

    debugPrint('╠══════════════════════════════════════╣');
    debugPrint('║  Found  : $found/${registeredAssets.length}');
    debugPrint('║  Missing: $missing/${registeredAssets.length}');
    debugPrint('╚══════════════════════════════════════╝');
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
