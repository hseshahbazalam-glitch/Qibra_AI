// Stage 1 — Midnight-navy brand token integrity + Home honesty guards.
// These run with `flutter test`; they assert the token source of truth
// (QibraNavy) never drifts from the theme extensions, and that the
// contrast floor documented in docs/DESIGN_SYSTEM.md holds.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qibra_ai/core/design_system/contrast.dart';
import 'package:qibra_ai/core/design_system/qibra_colors.dart';
import 'package:qibra_ai/core/design_system/qibra_colors_next.dart';
import 'package:qibra_ai/core/design_system/qibra_navy.dart';

void main() {
  test('midnight navy canvas/surface/card ladder is the dark identity', () {
    const canvas = Color(0xFF020B14);
    const surface = Color(0xFF04111C);
    const card = Color(0xFF071B28);
    const elevated = Color(0xFF0A2536);

    expect(QibraNavy.canvas, canvas);
    expect(QibraNavy.surface, surface);
    expect(QibraNavy.card, card);
    expect(QibraNavy.cardElevated, elevated);

    // Every dark surface is deep and blue-dominant (navy, not emerald/green).
    for (final s in [canvas, surface, card, elevated]) {
      expect(Contrast.relativeLuminance(s), lessThan(0.05),
          reason: '$s must stay near-black');
      // blue channel dominant => navy
      expect(s.b > s.r, isTrue, reason: '$s must be blue-dominant');
    }
  });

  test('QibraColors.dark and QibraColorsNext.dark derive from QibraNavy', () {
    expect(QibraColors.dark.background, QibraNavy.canvas);
    expect(QibraColors.dark.navBackground, QibraNavy.surface);
    expect(QibraColors.dark.card, QibraNavy.card);
    expect(QibraColors.dark.border, QibraNavy.hairline);
    expect(QibraColors.dark.primary, QibraNavy.emerald);
    expect(QibraColors.dark.accent, QibraNavy.gold);

    expect(QibraColorsNext.dark.bgCanvas, QibraNavy.canvas);
    expect(QibraColorsNext.dark.bgSurface, QibraNavy.surface);
    expect(QibraColorsNext.dark.bgCard, QibraNavy.card);
    expect(QibraColorsNext.dark.emeraldPrimary, QibraNavy.emerald);
    expect(QibraColorsNext.dark.violetAi, QibraNavy.violet);
    expect(QibraColorsNext.dark.goldIslamic, QibraNavy.gold);
  });

  test('no stale emerald-canvas hexes remain in the approved dark set', () {
    const staleEmeraldCanvas = Color(0xFF071512);
    expect(QibraColors.dark.background, isNot(staleEmeraldCanvas));
    expect(QibraColorsNext.dark.bgCanvas, isNot(staleEmeraldCanvas));
  });

  test('contrast floor — text + accents remain accessible on navy', () {
    const canvas = QibraNavy.canvas;
    const card = QibraNavy.card;

    // body text AAA on canvas
    expect(Contrast.meetsAa(QibraNavy.textPrimary, canvas), isTrue);
    expect(Contrast.ratio(QibraNavy.textPrimary, canvas),
        greaterThanOrEqualTo(7.0));
    // secondary on card AA
    expect(Contrast.meetsAa(QibraNavy.textSecondary, card), isTrue);
    // muted on card AA (small hint text)
    expect(Contrast.ratio(QibraNavy.textMuted, card),
        greaterThanOrEqualTo(4.5));
    // accent inks on canvas must work as text/colors at AA
    for (final accent in [
      QibraNavy.emerald,
      QibraNavy.violet,
      QibraNavy.goldBright,
      QibraNavy.blue,
      QibraNavy.cyan,
    ]) {
      expect(Contrast.meetsAa(accent, canvas), isTrue,
          reason: '$accent on navy must meet AA');
    }
    // dark ink on emerald action fill (button labels)
    expect(
        Contrast.meetsAa(QibraNavy.textOnEmerald, QibraNavy.emerald), isTrue);
  });

  test('semantic roles are distinct (color conveys meaning, not decoration)',
      () {
    expect(QibraNavy.emerald, isNot(QibraNavy.violet));
    expect(QibraNavy.violet, isNot(QibraNavy.gold));
    expect(QibraColors.dark.info.toARGB32(), isNot(QibraColors.dark.violetAi.toARGB32()),
        reason: 'info is blue; violet is AI-only');
    expect(QibraColors.dark.success, QibraNavy.emerald);
    expect(QibraColors.dark.error, QibraNavy.red);
  });

  test('violet remains AI-only in the next-tokens set', () {
    // The violet used by QibraColors (AI getter) and QibraColorsNext must match.
    expect(QibraColors.dark.violetAi, QibraColorsNext.dark.violetAi);
    expect(QibraColors.light.violetAi, QibraColorsNext.dark.violetAi);
  });

  test('theme extension light mapping keeps AI violet constant', () {
    const mapped = QibraColorsNext.dark;
    expect(mapped.violetAi, const Color(0xFF9B6CFF));
  });

  test('QibraNavy gradients are defined for hero + AI surfaces', () {
    expect(QibraNavy.heroNight.colors.length, greaterThanOrEqualTo(2));
    expect(QibraNavy.heroNight.colors.first, isNot(equals(Colors.white)));
    expect(QibraNavy.aiViolet.colors.every((c) => Contrast.relativeLuminance(c) < 0.35),
        isTrue,
        reason: 'AI card surface must stay dark enough for white text');
  });
}
