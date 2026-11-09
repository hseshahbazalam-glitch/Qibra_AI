// lib/core/design_system/qibra_paper.dart
// ============================================================
// QIBRA PAPER — READING-SURFACE DUOTONE TOKENS (Pass D2)
// ============================================================
// The app's GLOBAL identity stays midnight navy — byte-identical,
// default Night everywhere, untouched. Paper is scoped to the
// READING surfaces only (mushaf reader, surah reader, word/ayah
// sheets, tafseer) and activates solely through the per-user
// Reading Theme preference (Settings → Reading Theme: Night |
// Paper; persisted in the reading-preferences store; default
// NIGHT). When the preference is night, QibraPaper.scope returns
// the child UNWRAPPED — the Night path gains literally nothing.
//
// This file is the SINGLE SOURCE OF TRUTH for every paper hex,
// exactly like qibra_navy.dart is for the dark theme. The contrasts
// below are computed with the WCAG relative-luminance math of
// core/design_system/contrast.dart and are pinned at runtime by
// test/features/quran/mushaf_pass_d2_test.dart:
//   ink on paper            12.22:1   (contract ≥ 12)
//   inkSoft on paper         8.85:1   (contract ≥ 8.8)
//   inkMuted on paper        5.62:1   (contract ≥ 5.5)
//   accentGoldDeep/paper     5.09:1   (contract ≥ 5.0 — the ONLY
//                                     gold allowed to carry text)
//   playingWash base #A8823F 2.9:1 against paper — wash/marker
//                                     ONLY (it rides at ~10% alpha
//                                     as a background tint); it is
//                                     NEVER body text.
// No other file may write these hexes.
// ============================================================

import 'package:flutter/material.dart';

import 'package:qibra_ai/core/design_system/qibra_colors.dart';

/// The reading-surface theme switch. Persisted by name in the
/// reading-preferences store; anything unrecognized loads [night].
enum QibraReadingTheme { night, paper }

/// Paper tokens + the scoping mechanics for reading surfaces.
abstract final class QibraPaper {
  // ── The tokens (brief-fixed; do not invent, do not inch) ──
  static const Color paper = Color(0xFFF2E8D5);
  static const Color paperDeep = Color(0xFFE9DCC3); // cards
  static const Color ink = Color(0xFF2E2620); // body — 12.22:1
  static const Color inkSoft = Color(0xFF4A3B2C); // translation — 8.85:1
  static const Color inkMuted = Color(0xFF6B5744); // meta — 5.62:1
  static const Color accentGoldDeep = Color(0xFF7A5C2E); // 5.09:1
  static const Color hairlinePaper = Color(0xFFD4C3A5);

  /// Playing-ayah wash: the brief's tint base #A8823F baked at the
  /// navy wash's ~10% alpha (0x1A). Background marker only — the
  /// body text on top of it stays full [ink].
  static const Color playingWash = Color(0x1AA8823F);

  /// Warm two-tone shadows replacing navy's cool drops on paper:
  /// ambient 0x2E (~18%) + contact 0x1A (~10%). Alphas are baked
  /// into the literals on purpose — no new withValues(alpha:) sites
  /// are born, the L2 alpha budget stays untouched (D2 discipline).
  static const Color shadowAmbient = Color(0x2E26202E);
  static const Color shadowContact = Color(0x1A2E2620);

  /// Gilding (ribbon trim, rosette, fore-edge) on paper = the one
  /// readable gold. Navy surfaces keep AppGold.
  static const Color gild = accentGoldDeep;

  // ── Typography quality (T1/T2 — paper surfaces only) ──────
  /// T2: the mushaf body moves one step of the size ladder up.
  static const double bodySizeStep = 2.0;
  /// T2: latin headings gain +0.2 tracking on paper.
  static const double headingLetterSpacing = 0.2;
  /// T1: the Arabic/Urdu body leading window on paper.
  static const double bodyLeadingMin = 1.75;
  static const double bodyLeadingMax = 1.85;

  /// T1 clamp: whatever the night leading is, paper sits inside
  /// the 1.75–1.85 window (2.2 airy navy mushaf tightens; anything
  /// already looser than 1.4 clamps up — one band, every surface).
  static double bodyLeadingOn(double current) =>
      current.clamp(bodyLeadingMin, bodyLeadingMax).toDouble();

  /// Paper body-Arabic: +1 ladder step (T2) and the T1 leading
  /// window in one call. Applied ONLY under [isActive].
  static TextStyle paperArabicBody(TextStyle base) => base.copyWith(
        fontSize: (base.fontSize ?? 22.0) + bodySizeStep,
        height: bodyLeadingOn(base.height ?? 1.8),
      );

  /// T2: latin heading tracking on paper. No-op-safe (adds once).
  static TextStyle paperHeading(TextStyle base) => base.copyWith(
        letterSpacing: (base.letterSpacing ?? 0.0) + headingLetterSpacing,
      );

  /// T3 padding rhythm on paper: inner blocks sit on 16, page
  /// margins on 24. Night values pass through untouched.
  static double pad(BuildContext context, double night) =>
      isActive(context) ? (night < 20 ? 16.0 : 24.0) : night;

  /// The paper palette installed by the reading scopes. Const, and
  /// lerp-pinned to itself — toggling is INSTANT (no theme-
  /// animation smear through a half-paper frame; the brief asks
  /// for 'instant switch, koi restart nahi').
  static const QibraColors palette = QibraPaperColors.palette;

  /// True when the nearest [QibraColors] is the paper palette.
  /// Deep components (ribbon, chrome, turn) probe context instead
  /// of threading a flag.
  static bool isActive(BuildContext context) =>
      QibraColors.of(context) is QibraPaperColors;

  /// Wrap a reading surface. [active] is the persisted preference
  /// (paper mode). FALSE RETURNS THE CHILD INSTANCE UNTOUCHED —
  /// identical widget identity is what makes the Night path
  /// provably byte-identical (pinned by the D2 test with same()).
  static Widget scope({required bool active, required Widget child}) {
    if (!active) return child;
    return Builder(
      builder: (context) {
        final base = Theme.of(context);
        return Theme(
          // brightness light: paper is the light family — Material
          // internals (splashes, scrollbars, dialogs built below
          // this node) must resolve light defaults. The app bar too:
          // a copied dark appBarTheme would paint navy chrome with
          // light-on-dark text on a cream page.
          data: base.copyWith(
            brightness: Brightness.light,
            appBarTheme: base.appBarTheme.copyWith(
              backgroundColor: paper,
              foregroundColor: ink,
              titleTextStyle:
                  base.appBarTheme.titleTextStyle?.copyWith(color: ink),
              iconTheme: const IconThemeData(color: ink),
            ),
            extensions: const <ThemeExtension<dynamic>>[palette],
          ),
          child: child,
        );
      },
    );
  }
}

/// The paper palette as a [QibraColors] subclass — subclass (not a
/// field swap) because the extension's gold/role getters are
/// computed: on paper, gold text must resolve to the ONE readable
/// gold (#7A5C2E), never the legacy ivory-mode or bright navy gold.
class QibraPaperColors extends QibraColors {
  const QibraPaperColors._()
      : super(
          // Page = the canvas itself (the viral readers' seam-free
          // cream); cards/chips sink to paperDeep.
          background: QibraPaper.paper,
          backgroundSecondary: QibraPaper.paperDeep,
          card: QibraPaper.paper,
          cardMuted: QibraPaper.paperDeep,
          // Primary fills (medallion, ribbon) become the deep
          // antique gold with INK text on top — the brief's
          // 'goldDeep fill + ink text', at 5.09:1.
          primary: QibraPaper.accentGoldDeep,
          primarySoft: QibraPaper.paperDeep,
          secondary: QibraPaper.inkSoft,
          accent: QibraPaper.accentGoldDeep,
          textPrimary: QibraPaper.ink,
          textSecondary: QibraPaper.inkSoft,
          textTertiary: QibraPaper.inkMuted,
          border: QibraPaper.hairlinePaper,
          navBackground: QibraPaper.paper,
          onPrimary: QibraPaper.ink,
        );

  static const QibraPaperColors palette = QibraPaperColors._();

  @override
  bool get isDark => false; // paper is light family, always

  @override
  Color get goldText => QibraPaper.accentGoldDeep;

  /// Instant + idempotent: any lerp aimed at paper lands on paper
  /// (never a raw QibraColors frame that would resurrect the
  /// navy-side gold getters).
  @override
  QibraColors lerp(ThemeExtension<QibraColors>? other, double t) => this;
}
