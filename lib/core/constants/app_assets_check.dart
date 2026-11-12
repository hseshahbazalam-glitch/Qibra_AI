// lib/core/constants/app_assets_check.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/observability/qibra_log.dart';

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
    QibraLog.log(() => '╔══════════════════════════════════════╗');
    QibraLog.log(() => '║   QIBRA AI — Assets Verification     ║');
    QibraLog.log(() => '╠══════════════════════════════════════╣');

    int found = 0;
    int missing = 0;

    for (final asset in registeredAssets) {
      try {
        await rootBundle.load(asset);
        found++;
        // PASS X2 (print diet): the per-asset '║  OK …' line used to print one
        // row per registered asset INSIDE this boot loop — 16 lines, 16 asset
        // reads, and a table nobody acts on while everything is fine. Success
        // is now the summary count below; only a MISSING asset still gets its
        // own row, because that is the only row a device log is read for.
      } catch (e) {
        missing++;
        QibraLog.log(() => '║  MISSING: $asset');
      }
    }

    QibraLog.log(() => '╠══════════════════════════════════════╣');
    QibraLog.log(() => '║  Found  : $found/${registeredAssets.length}');
    QibraLog.log(() => '║  Missing: $missing/${registeredAssets.length}');
    QibraLog.log(() => '╚══════════════════════════════════════╝');
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
