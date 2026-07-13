// lib/core/design_system/app_colors.dart

// ============================================================
// QIBRA AI — PREMIUM COLOR SYSTEM
// Version: 1.2.0
// Fix: Added surfaceHighest color token
// Description: Complete color palette for QIBRA AI.
//              Dark Emerald + Royal Gold Islamic theme.
//              Every color used in the app comes from here.
// ============================================================

import 'package:flutter/material.dart';

// ============================================================
// SECTION 1: EMERALD COLOR PALETTE
// ============================================================
// Emerald = QIBRA AI ka primary brand color
// Islam mein green ka bohot important place hai —
// Quran mein Jannah (paradise) ko green describe kiya gaya hai.
// 50 se 900 tak shades — 50 = sabse light, 900 = sabse dark
// ============================================================

abstract final class AppEmerald {
  /// #E8FFF5 — Almost white green (subtle backgrounds)
  static const Color s50 = Color(0xFFE8FFF5);

  /// #C2F5E0 — Very light emerald (hover states)
  static const Color s100 = Color(0xFFC2F5E0);

  /// #85EBBC — Light emerald (disabled states)
  static const Color s200 = Color(0xFF85EBBC);

  /// #3DDEA0 — Soft emerald (secondary actions)
  static const Color s300 = Color(0xFF3DDEA0);

  /// #00CF82 — Medium emerald (active states)
  static const Color s400 = Color(0xFF00CF82);

  /// #00A86B — Standard emerald ← PRIMARY BRAND COLOR
  static const Color s500 = Color(0xFF00A86B);

  /// #008A58 — Medium dark emerald (pressed states)
  static const Color s600 = Color(0xFF008A58);

  /// #006B45 — Dark emerald (deep accents)
  static const Color s700 = Color(0xFF006B45);

  /// #004D32 — Very dark emerald (borders on light bg)
  static const Color s800 = Color(0xFF004D32);

  /// #002E1E — Deepest emerald (almost black-green)
  static const Color s900 = Color(0xFF002E1E);

  // --- Convenience getters ---

  /// Primary brand emerald (#00A86B)
  static const Color primary = s500;

  /// Light variant (for subtle backgrounds)
  static const Color light = s200;

  /// Dark variant (for pressed/active states)
  static const Color dark = s700;

  /// Deepest variant (for borders, dark surfaces)
  static const Color deepest = s900;

  // withValues(alpha:) — Flutter 3.27+ compatible
  // alpha: 0.0 = fully transparent, 1.0 = fully opaque

  /// Emerald with 10% opacity (subtle tint backgrounds)
  static Color get tint10 => s500.withValues(alpha: 0.10);

  /// Emerald with 20% opacity (card overlays)
  static Color get tint20 => s500.withValues(alpha: 0.20);

  /// Emerald with 30% opacity (hover states)
  static Color get tint30 => s500.withValues(alpha: 0.30);

  /// Emerald with 50% opacity (disabled emerald elements)
  static Color get tint50 => s500.withValues(alpha: 0.50);
}

// ============================================================
// SECTION 2: GOLD COLOR PALETTE
// ============================================================
// Gold = QIBRA AI ka accent/royal color
// Islamic architecture, Quran calligraphy, mosque domes
// sab mein gold use hota hai — royalty aur divine
// connection ko represent karta hai.
// ============================================================

abstract final class AppGold {
  /// #FFFDE8 — Almost white gold (subtle bg)
  static const Color s50 = Color(0xFFFFFDE8);

  /// #FFF8C2 — Very light gold
  static const Color s100 = Color(0xFFFFF8C2);

  /// #FFF085 — Light gold
  static const Color s200 = Color(0xFFFFF085);

  /// #FFE53D — Bright yellow-gold
  static const Color s300 = Color(0xFFFFE53D);

  /// #FFD700 — Pure gold ← CLASSIC GOLD
  static const Color s400 = Color(0xFFFFD700);

  /// #D4AF37 — Royal gold ← PRIMARY ACCENT COLOR
  static const Color s500 = Color(0xFFD4AF37);

  /// #B8960C — Dark gold (pressed states)
  static const Color s600 = Color(0xFFB8960C);

  /// #996515 — Deep gold (dark goldenrod)
  static const Color s700 = Color(0xFF996515);

  /// #7A4F0D — Very dark gold (borders)
  static const Color s800 = Color(0xFF7A4F0D);

  /// #5C3A08 — Darkest gold (almost brown-gold)
  static const Color s900 = Color(0xFF5C3A08);

  // --- Convenience getters ---

  /// Primary accent gold (#D4AF37 — Royal Gold)
  static const Color primary = s500;

  /// Bright gold (#FFD700 — Pure Gold)
  static const Color bright = s400;

  /// Dark gold (for pressed states)
  static const Color dark = s700;

  // withValues(alpha:) — Flutter 3.27+ compatible

  /// Gold with 10% opacity
  static Color get tint10 => s500.withValues(alpha: 0.10);

  /// Gold with 20% opacity (card overlays)
  static Color get tint20 => s500.withValues(alpha: 0.20);

  /// Gold with 30% opacity
  static Color get tint30 => s500.withValues(alpha: 0.30);

  /// Gold with 50% opacity (disabled gold elements)
  static Color get tint50 => s500.withValues(alpha: 0.50);
}

// ============================================================
// SECTION 3: NEUTRAL / GRAY PALETTE
// ============================================================
// Neutrals = app ka backbone — text, borders, backgrounds
// Cool-tinted grays (blue-gray) jo dark Islamic theme
// ke saath perfectly match karte hain.
// ============================================================

abstract final class AppNeutral {
  /// #FFFFFF — Pure white
  static const Color s0 = Color(0xFFFFFFFF);

  /// #F8FAFC — Off white (lightest background)
  static const Color s50 = Color(0xFFF8FAFC);

  /// #F1F5F9 — Very light gray
  static const Color s100 = Color(0xFFF1F5F9);

  /// #E2E8F0 — Light gray (dividers on light bg)
  static const Color s200 = Color(0xFFE2E8F0);

  /// #CBD5E1 — Soft gray (placeholder text)
  static const Color s300 = Color(0xFFCBD5E1);

  /// #94A3B8 — Medium gray (hint text)
  static const Color s400 = Color(0xFF94A3B8);

  /// #64748B — Standard gray (secondary text)
  static const Color s500 = Color(0xFF64748B);

  /// #475569 — Dark gray (body text on light bg)
  static const Color s600 = Color(0xFF475569);

  /// #334155 — Darker gray
  static const Color s700 = Color(0xFF334155);

  /// #1E293B — Very dark (surface on dark bg)
  static const Color s800 = Color(0xFF1E293B);

  /// #0F172A — Almost black (dark card surface)
  static const Color s900 = Color(0xFF0F172A);

  /// #000000 — Pure black
  static const Color s1000 = Color(0xFF000000);
}

// ============================================================
// SECTION 4: SEMANTIC COLORS
// ============================================================
// Semantic = meaning ke hisab se colors
// Success = green, Error = red, Warning = amber, Info = blue
// Standard UX convention — users immediately samajh jaate hain
// ============================================================

abstract final class AppSemanticColors {
  // --- SUCCESS ---
  /// Success background (light)
  static const Color successLight = Color(0xFFD1FAE5);

  /// Success standard
  static const Color success = Color(0xFF10B981);

  /// Success dark
  static const Color successDark = Color(0xFF065F46);

  // --- ERROR ---
  /// Error background (light)
  static const Color errorLight = Color(0xFFFEE2E2);

  /// Error standard
  static const Color error = Color(0xFFEF4444);

  /// Error dark
  static const Color errorDark = Color(0xFF7F1D1D);

  // --- WARNING ---
  /// Warning background (light)
  static const Color warningLight = Color(0xFFFEF3C7);

  /// Warning standard
  static const Color warning = Color(0xFFF59E0B);

  /// Warning dark
  static const Color warningDark = Color(0xFF78350F);

  // --- INFO ---
  /// Info background (light)
  static const Color infoLight = Color(0xFFDBEAFE);

  /// Info standard
  static const Color info = Color(0xFF3B82F6);

  /// Info dark
  static const Color infoDark = Color(0xFF1E3A8A);
}

// ============================================================
// SECTION 5: APP SURFACE COLORS (Dark Theme)
// ============================================================
// Surface colors = different levels ki dark backgrounds
// Background → Surface → Surface Variant → Elevated Surface
// Jitna upar (elevation), utna thoda lighter
// ============================================================

abstract final class AppSurface {
  // --- Primary Backgrounds ---

  /// #020A08 — Deepest background (almost pure black with green tint)
  static const Color background = Color(0xFF020A08);

  /// #050D14 — Main app background (deep navy-black)
  static const Color backgroundPrimary = Color(0xFF050D14);

  /// #0A1628 — Secondary background (dark navy)
  static const Color backgroundSecondary = Color(0xFF0A1628);

  /// #0D1F2D — Tertiary background (dark teal-navy)
  static const Color backgroundTertiary = Color(0xFF0D1F2D);

  // --- Card Surfaces ---

  /// #0F1E2E — Base card surface (just above background)
  static const Color card = Color(0xFF0F1E2E);

  /// #162234 — Standard card (main content cards)
  static const Color cardElevated = Color(0xFF162234);

  /// #1A2940 — Higher card (modal cards, dropdowns)
  static const Color cardHigh = Color(0xFF1A2940);

  /// #1E3352 — Highest card (tooltips, popovers)
  static const Color cardHighest = Color(0xFF1E3352);

  // --- Overlay Surfaces ---

  /// Bottom sheet, dialog background
  static const Color sheet = Color(0xFF132030);

  /// Modal overlay background
  static const Color modal = Color(0xFF0E1C2C);

  // --- Input Field Surfaces ---

  /// Text field background (unfocused)
  static const Color inputBackground = Color(0xFF0F1E2E);

  /// Text field background (focused)
  static const Color inputFocused = Color(0xFF162234);

  // --- Navigation ---

  /// Bottom navigation bar background
  static const Color bottomNav = Color(0xFF0A1628);

  /// Top app bar background
  static const Color appBar = Color(0xFF050D14);

  // --- Divider ---

  /// Subtle divider line
  static const Color divider = Color(0xFF1A2940);

  /// Strong divider line
  static const Color dividerStrong = Color(0xFF243552);
}

// ============================================================
// SECTION 6: TEXT COLORS (Dark Theme)
// ============================================================
// Text hierarchy:
// Primary → Secondary → Tertiary → Disabled → Hint
// Har level pe opacity/brightness kam hoti jaati hai
// ============================================================

abstract final class AppTextColors {
  // --- Primary Text ---
  /// #FFFFFF — Main headings, important content (100% white)
  static const Color primary = Color(0xFFFFFFFF);

  /// #F1F5F9 — Standard body text (slightly off-white)
  static const Color body = Color(0xFFF1F5F9);

  // --- Secondary Text ---
  /// #94A3B8 — Secondary/supporting text
  static const Color secondary = Color(0xFF94A3B8);

  /// #64748B — Tertiary text (muted, less important)
  static const Color tertiary = Color(0xFF64748B);

  // --- Disabled & Hint ---
  /// #475569 — Disabled text
  static const Color disabled = Color(0xFF475569);

  /// #334155 — Hint text in input fields
  static const Color hint = Color(0xFF334155);

  // --- Brand Colors in Text ---
  /// Emerald text (links, active states, success messages)
  static const Color emerald = Color(0xFF00A86B);

  /// Gold text (premium labels, highlights, prices)
  static const Color gold = Color(0xFFD4AF37);

  /// Bright gold text (most prominent gold text)
  static const Color goldBright = Color(0xFFFFD700);

  // --- Semantic Text Colors ---
  /// Error message text
  static const Color error = Color(0xFFEF4444);

  /// Success message text
  static const Color success = Color(0xFF10B981);

  /// Warning message text
  static const Color warning = Color(0xFFF59E0B);

  /// Info message text
  static const Color info = Color(0xFF3B82F6);

  // --- Inverse (for light backgrounds) ---
  /// Dark text for light-colored buttons/surfaces
  static const Color inverse = Color(0xFF0A1628);

  /// Dark text for gold buttons
  static const Color onGold = Color(0xFF1A0A00);

  /// Light text for emerald buttons
  static const Color onEmerald = Color(0xFFFFFFFF);
}

// ============================================================
// SECTION 7: ICON COLORS
// ============================================================

abstract final class AppIconColors {
  /// Primary icons (active nav, primary actions)
  static const Color primary = Color(0xFFFFFFFF);

  /// Secondary icons (inactive nav, secondary)
  static const Color secondary = Color(0xFF64748B);

  /// Emerald icons (feature icons, active states)
  static const Color emerald = Color(0xFF00A86B);

  /// Gold icons (premium features, highlights)
  static const Color gold = Color(0xFFD4AF37);

  /// Disabled icons
  static const Color disabled = Color(0xFF334155);

  /// Error icons
  static const Color error = Color(0xFFEF4444);

  /// Warning icons
  static const Color warning = Color(0xFFF59E0B);
}

// ============================================================
// SECTION 8: BORDER COLORS
// ============================================================

abstract final class AppBorderColors {
  /// Subtle border (most cards, dividers)
  static const Color subtle = Color(0xFF1A2940);

  /// Standard border (input fields unfocused)
  static const Color standard = Color(0xFF243552);

  /// Strong border (highlighted sections)
  static const Color strong = Color(0xFF2D4A6E);

  /// Emerald border (focused inputs, active)
  static const Color emerald = Color(0xFF00A86B);

  // withValues(alpha:) — Flutter 3.27+ compatible

  /// Emerald subtle border (35% opacity)
  static Color get emeraldSubtle =>
      const Color(0xFF00A86B).withValues(alpha: 0.35);

  /// Gold border (premium cards, highlights)
  static const Color gold = Color(0xFFD4AF37);

  /// Gold subtle border (35% opacity)
  static Color get goldSubtle =>
      const Color(0xFFD4AF37).withValues(alpha: 0.35);

  /// Error border (invalid inputs)
  static const Color error = Color(0xFFEF4444);

  /// Focus border (active input fields)
  static const Color focus = Color(0xFF00A86B);

  /// Transparent
  static const Color transparent = Colors.transparent;
}

// ============================================================
// SECTION 9: MAIN AppColors CLASS
// ============================================================
// Yeh MAIN class hai jo poori app mein use hogi.
// Sab colors yahan se access honge ek jagah se.
//
// Usage examples:
//   AppColors.primary          → Emerald Green
//   AppColors.accent           → Royal Gold
//   AppColors.background       → Deep dark background
//   AppColors.textPrimary      → White text
//   AppColors.surface          → Card background
//   AppColors.surfaceHighest   → Tooltip background
// ============================================================

abstract final class AppColors {
  // ══════════════════════════════════════════
  // PRIMARY & ACCENT
  // ══════════════════════════════════════════

  /// Primary brand color — Emerald Green (#00A86B)
  static const Color primary = AppEmerald.s500;

  /// Primary light variant
  static const Color primaryLight = AppEmerald.s300;

  /// Primary dark variant
  static const Color primaryDark = AppEmerald.s700;

  /// Accent color — Royal Gold (#D4AF37)
  static const Color accent = AppGold.s500;

  /// Accent light variant
  static const Color accentLight = AppGold.s300;

  /// Accent dark variant
  static const Color accentDark = AppGold.s700;

  /// Bright gold (most vibrant — #FFD700)
  static const Color accentBright = AppGold.s400;

  // ══════════════════════════════════════════
  // BACKGROUNDS
  // ══════════════════════════════════════════

  /// Main app background (deepest dark — #050D14)
  static const Color background = AppSurface.backgroundPrimary;

  /// Secondary background (#0A1628)
  static const Color backgroundSecondary = AppSurface.backgroundSecondary;

  /// Tertiary background (#0D1F2D)
  static const Color backgroundTertiary = AppSurface.backgroundTertiary;

  // ══════════════════════════════════════════
  // SURFACES (Cards, Sheets, Modals)
  // ══════════════════════════════════════════

  /// Standard card background (#0F1E2E)
  static const Color surface = AppSurface.card;

  /// Elevated card background (#162234)
  static const Color surfaceElevated = AppSurface.cardElevated;

  /// High elevation surface (#1A2940)
  static const Color surfaceHigh = AppSurface.cardHigh;

  /// Highest elevation surface (#1E3352) — tooltips, popovers
  static const Color surfaceHighest = AppSurface.cardHighest;

  /// Bottom sheet / dialog background (#132030)
  static const Color surfaceSheet = AppSurface.sheet;

  /// Modal overlay (#0E1C2C)
  static const Color surfaceModal = AppSurface.modal;

  // ══════════════════════════════════════════
  // TEXT
  // ══════════════════════════════════════════

  /// Primary text — #FFFFFF (headings, important content)
  static const Color textPrimary = AppTextColors.primary;

  /// Body text — #F1F5F9
  static const Color textBody = AppTextColors.body;

  /// Secondary text — #94A3B8 (subtitles, descriptions)
  static const Color textSecondary = AppTextColors.secondary;

  /// Tertiary text — #64748B (captions, less important)
  static const Color textTertiary = AppTextColors.tertiary;

  /// Disabled text — #475569
  static const Color textDisabled = AppTextColors.disabled;

  /// Hint text — #334155 (placeholder in input fields)
  static const Color textHint = AppTextColors.hint;

  /// Emerald colored text — #00A86B (links, active states)
  static const Color textEmerald = AppTextColors.emerald;

  /// Gold colored text — #D4AF37 (premium, highlights)
  static const Color textGold = AppTextColors.gold;

  /// Text on gold buttons — #1A0A00 (dark, readable)
  static const Color textOnGold = AppTextColors.onGold;

  /// Text on emerald buttons — #FFFFFF
  static const Color textOnEmerald = AppTextColors.onEmerald;

  // ══════════════════════════════════════════
  // ICONS
  // ══════════════════════════════════════════

  /// Primary icon color — #FFFFFF
  static const Color iconPrimary = AppIconColors.primary;

  /// Secondary icon color (inactive) — #64748B
  static const Color iconSecondary = AppIconColors.secondary;

  /// Emerald icon color — #00A86B
  static const Color iconEmerald = AppIconColors.emerald;

  /// Gold icon color — #D4AF37
  static const Color iconGold = AppIconColors.gold;

  // ══════════════════════════════════════════
  // BORDERS
  // ══════════════════════════════════════════

  /// Subtle border — #1A2940
  static const Color borderSubtle = AppBorderColors.subtle;

  /// Standard border — #243552
  static const Color borderStandard = AppBorderColors.standard;

  /// Strong border — #2D4A6E
  static const Color borderStrong = AppBorderColors.strong;

  /// Emerald border — #00A86B
  static const Color borderEmerald = AppBorderColors.emerald;

  /// Gold border — #D4AF37
  static const Color borderGold = AppBorderColors.gold;

  /// Error border — #EF4444
  static const Color borderError = AppBorderColors.error;

  /// Focus border — #00A86B
  static const Color borderFocus = AppBorderColors.focus;

  // ══════════════════════════════════════════
  // SEMANTIC
  // ══════════════════════════════════════════

  /// Success — #10B981
  static const Color success = AppSemanticColors.success;

  /// Success Light — #D1FAE5
  static const Color successLight = AppSemanticColors.successLight;

  /// Success Dark — #065F46
  static const Color successDark = AppSemanticColors.successDark;

  /// Error — #EF4444
  static const Color error = AppSemanticColors.error;

  /// Error Light — #FEE2E2
  static const Color errorLight = AppSemanticColors.errorLight;

  /// Error Dark — #7F1D1D
  static const Color errorDark = AppSemanticColors.errorDark;

  /// Warning — #F59E0B
  static const Color warning = AppSemanticColors.warning;

  /// Warning Light — #FEF3C7
  static const Color warningLight = AppSemanticColors.warningLight;

  /// Warning Dark — #78350F
  static const Color warningDark = AppSemanticColors.warningDark;

  /// Info — #3B82F6
  static const Color info = AppSemanticColors.info;

  /// Info Light — #DBEAFE
  static const Color infoLight = AppSemanticColors.infoLight;

  /// Info Dark — #1E3A8A
  static const Color infoDark = AppSemanticColors.infoDark;

  // ══════════════════════════════════════════
  // NAVIGATION
  // ══════════════════════════════════════════

  /// Bottom navigation background — #0A1628
  static const Color navBackground = AppSurface.bottomNav;

  /// Active navigation item — #00A86B (Emerald)
  static const Color navActive = AppEmerald.s500;

  /// Inactive navigation item — #64748B (Gray)
  static const Color navInactive = AppNeutral.s500;

  // ══════════════════════════════════════════
  // INPUT FIELDS
  // ══════════════════════════════════════════

  /// Input field background — #0F1E2E
  static const Color inputBackground = AppSurface.inputBackground;

  /// Input field focused background — #162234
  static const Color inputFocused = AppSurface.inputFocused;

  // ══════════════════════════════════════════
  // DIVIDERS
  // ══════════════════════════════════════════

  /// Standard divider — #1A2940
  static const Color divider = AppSurface.divider;

  /// Strong divider — #243552
  static const Color dividerStrong = AppSurface.dividerStrong;

  // ══════════════════════════════════════════
  // SPECIAL / MISC
  // ══════════════════════════════════════════

  /// Pure transparent
  static const Color transparent = Colors.transparent;

  /// Pure white — #FFFFFF
  static const Color white = Color(0xFFFFFFFF);

  /// Pure black — #000000
  static const Color black = Color(0xFF000000);

  // withValues(alpha:) — Flutter 3.27+ compatible

  /// Overlay color (60% black — for image overlays)
  static Color get overlay => const Color(0xFF000000).withValues(alpha: 0.60);

  /// Modal scrim (75% black — behind dialogs)
  static Color get scrim => const Color(0xFF000000).withValues(alpha: 0.75);

  /// Shimmer base color (solid dark navy)
  static const Color shimmerBase = Color(0xFF1A2940);

  /// Shimmer highlight color (slightly lighter navy)
  static const Color shimmerHighlight = Color(0xFF243552);
}
