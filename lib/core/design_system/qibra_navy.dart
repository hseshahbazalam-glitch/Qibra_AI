// lib/core/design_system/qibra_navy.dart
// ============================================================
// QIBRA AI — MIDNIGHT NAVY GLOBAL BRAND TOKENS
// ============================================================
// Product-owner override (approved): midnight navy identity is the
// global brand language. These tokens are the SINGLE SOURCE OF TRUTH
// for the dark theme. QibraColors.dark, QibraColorsNext.dark,
// AppColorsDark and AppTheme.dark all derive from this file so the
// hex values can never drift apart.
//
// Ratio target: 60–70% navy surfaces, 15–20% emerald, 8–12% violet,
// 5–8% gold, small amounts blue/cyan/orange/red.
// Color communicates meaning — never decoration alone.
// ============================================================

import 'package:flutter/material.dart';

abstract final class QibraNavy {
  // ─── Base surfaces ──────────────────────────────────────────────
  /// Deepest midnight navy — application canvas.
  static const Color canvas = Color(0xFF020B14);
  /// Deep ink for vector silhouettes painted over the hero night sky.
  static const Color nightInk = Color(0xFF010A12);

  /// Secondary navy — nav bar, sheets, app bars.
  static const Color surface = Color(0xFF04111C);

  /// Elevated card surface.
  static const Color card = Color(0xFF071B28);

  /// Important cards, pressed states, modals.
  static const Color cardElevated = Color(0xFF0A2536);

  /// Hairline borders on dark surfaces (thin, low contrast).
  static const Color hairline = Color(0xFF143045);

  /// Stronger hairline (focus rings, selected outlines).
  static const Color hairlineStrong = Color(0xFF1D3E5B);

  // ─── Emerald — action / success / prayer ───────────────────────
  static const Color emerald = Color(0xFF2ED39A);
  static const Color emeraldDeep = Color(0xFF0E9F6E);

  /// Soft emerald wash for fills behind icons/badges on navy.
  static const Color emeraldWash = Color(0x1F2ED39A); // 12% alpha

  // ─── Violet — AI / spiritual intelligence ──────────────────────
  static const Color violet = Color(0xFF9B6CFF);
  static const Color violetDeep = Color(0xFF6C3CE6);
  static const Color violetWash = Color(0x249B6CFF); // ~14% alpha

  // ─── Gold — sacred / premium accent (use sparingly) ────────────
  static const Color gold = Color(0xFFD9B26A);

  /// Gold TEXT on navy (brighter for contrast; never for body copy).
  static const Color goldBright = Color(0xFFF2D98F);
  static const Color goldWash = Color(0x1AD9B26A); // ~10% alpha

  // ─── Blue / cyan — information, search, hadith states ──────────
  static const Color blue = Color(0xFF5EA2FF);
  static const Color cyan = Color(0xFF43D6E8);

  // ─── Orange — streaks / special reminders (rare) ───────────────
  static const Color orange = Color(0xFFFF9C4F);

  // ─── Red — errors / destructive only ───────────────────────────
  static const Color red = Color(0xFFE5484D);

  // ─── Text ───────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFECF3FA);
  static const Color textSecondary = Color(0xFFA6BACD);
  static const Color textMuted = Color(0xFF71869B);

  /// On emerald fills (dark text on bright green).
  static const Color textOnEmerald = Color(0xFF02150F);

  /// On gold fills.
  static const Color textOnGold = Color(0xFF08131C);

  // ─── Atmospheric gradients (hero / cards) ──────────────────────
  /// Midnight sky — Home hero & prayer hero base.
  static const LinearGradient heroNight = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF08202E),
      surface,
      canvas,
    ],
    stops: [0.0, 0.55, 1.0],
  );

  /// Violet dawn — Ask QIBRA card.
  static const LinearGradient aiViolet = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2A1E4F),
      Color(0xFF131B33),
    ],
  );

  /// Emerald action fill (primary buttons / active states).
  static const LinearGradient emeraldAction = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      emerald,
      emeraldDeep,
    ],
  );

  /// Subtle card top-highlight (premium sheen, used once per card).
  static const LinearGradient cardSheen = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0x14FFFFFF),
      Color(0x00FFFFFF),
    ],
    stops: [0.0, 0.35],
  );

  // ─── Elevation helpers ─────────────────────────────────────────
  static List<BoxShadow> get nightGlow => [
        BoxShadow(
          color: emerald.withValues(alpha: 0.18),
          blurRadius: 22,
          spreadRadius: 0,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get aiGlow => [
        BoxShadow(
          color: violet.withValues(alpha: 0.22),
          blurRadius: 26,
          spreadRadius: 0,
          offset: const Offset(0, 8),
        ),
      ];

  static List<BoxShadow> get navyCard => [
        BoxShadow(
          color: const Color(0xFF01070D).withValues(alpha: 0.55),
          blurRadius: 24,
          spreadRadius: 0,
          offset: const Offset(0, 10),
        ),
      ];
}
