// lib/core/constants/app_assets_check.dart

// ============================================================
// QIBRA AI — Assets Verification Helper
// Version: 1.0.0
// Description: Development tool — verify all assets exist.
//              Sirf debug mode mein use karo.
//              Production mein is file ko call mat karo.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

abstract final class AppAssetsCheck {
  /// Verify karo ki saare registered assets exist karte hain
  /// main() mein debug mode mein call karo
  static Future<void> verifyAllAssets() async {
    debugPrint('╔══════════════════════════════════════╗');
    debugPrint('║   QIBRA AI — Assets Verification     ║');
    debugPrint('╠══════════════════════════════════════╣');

    final allAssets = [
      // Images
      'assets/images/logo.png',
      'assets/images/logo_white.png',
      'assets/images/logo_icon.png',
      'assets/images/splash_bg.png',
      'assets/images/splash_logo.png',
      'assets/images/onboarding_1.png',
      'assets/images/onboarding_2.png',
      'assets/images/onboarding_3.png',
      'assets/images/onboarding_4.png',
      'assets/images/quran_bg.png',
      'assets/images/quran_cover.png',
      'assets/images/mosque.png',
      'assets/images/compass_bg.png',
      'assets/images/islamic_pattern_1.png',
      'assets/images/islamic_pattern_2.png',
      'assets/images/pattern_overlay.png',

      // Icons
      'assets/icons/quran.svg',
      'assets/icons/prayer.svg',
      'assets/icons/qibla.svg',
      'assets/icons/hadith.svg',
      'assets/icons/ai.svg',
      'assets/icons/calendar.svg',
      'assets/icons/tasbih.svg',
      'assets/icons/dua.svg',

      // Animations
      'assets/animations/loading.json',
      'assets/animations/success.json',
      'assets/animations/error.json',
      'assets/animations/prayer.json',
      'assets/animations/quran.json',
      'assets/animations/ai_thinking.json',
    ];

    int found = 0;
    int missing = 0;

    for (final asset in allAssets) {
      try {
        // rootBundle.load = Flutter asset loading
        // Agar file exist nahi karti to exception aata hai
        await rootBundle.load(asset);
        found++;
        debugPrint('║  ✅ $asset');
      } catch (e) {
        missing++;
        debugPrint('║  ❌ MISSING: $asset');
      }
    }

    debugPrint('╠══════════════════════════════════════╣');
    debugPrint('║  Found  : $found/${allAssets.length}');
    debugPrint('║  Missing: $missing/${allAssets.length}');

    if (missing == 0) {
      debugPrint('║  ✅ All assets verified successfully  ║');
    } else {
      debugPrint('║  ⚠️  $missing assets missing!          ║');
      debugPrint('║  Run placeholder script to fix.       ║');
    }

    debugPrint('╚══════════════════════════════════════╝');
  }

  /// Ek specific asset exist karta hai ya nahi check karo
  static Future<bool> assetExists(String path) async {
    try {
      await rootBundle.load(path);
      return true;
    } catch (_) {
      return false;
    }
  }
}
