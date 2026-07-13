// lib/core/design_system/app_typography.dart

// ============================================================
// QIBRA AI — PREMIUM TYPOGRAPHY SYSTEM
// Version: 1.0.0
// Description: Complete type scale for QIBRA AI.
//              English: Poppins (Google Fonts)
//              Arabic: Amiri (Google Fonts)
//              Every text style in the app comes from here.
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

// ============================================================
// SECTION 1: FONT FAMILIES
// ============================================================
// Font Family = ek specific typeface (design) ka naam
// Poppins = modern, geometric, clean — perfect for UI
// Amiri = classical Arabic calligraphy style — perfect for Quran
// ============================================================

abstract final class AppFontFamily {
  /// Poppins — Primary English font
  /// Modern, geometric, highly readable
  /// Weights available: 100-900
  static const String primary = 'Poppins';

  /// Amiri — Arabic font for Quran & Islamic text
  /// Classical Arabic calligraphy style
  /// Supports full Arabic Unicode
  static const String arabic = 'Amiri';

  /// Monospace — for code/technical text (system font)
  static const String mono = 'monospace';
}

// ============================================================
// SECTION 2: FONT WEIGHTS
// ============================================================
// Font Weight = text kitna bold/thin hoga
// 100 = Thin (sabse patla)
// 400 = Regular (normal)
// 700 = Bold (standard bold)
// 900 = Black (sabse mota)
// ============================================================

abstract final class AppFontWeight {
  /// 100 — Thin (very light, decorative use only)
  static const FontWeight thin = FontWeight.w100;

  /// 200 — Extra Light
  static const FontWeight extraLight = FontWeight.w200;

  /// 300 — Light (subtle headings, large display text)
  static const FontWeight light = FontWeight.w300;

  /// 400 — Regular (standard body text)
  static const FontWeight regular = FontWeight.w400;

  /// 500 — Medium (slightly emphasized text)
  static const FontWeight medium = FontWeight.w500;

  /// 600 — SemiBold (subheadings, labels)
  static const FontWeight semiBold = FontWeight.w600;

  /// 700 — Bold (headings, buttons)
  static const FontWeight bold = FontWeight.w700;

  /// 800 — ExtraBold (hero headings)
  static const FontWeight extraBold = FontWeight.w800;

  /// 900 — Black (display, splash text)
  static const FontWeight black = FontWeight.w900;
}

// ============================================================
// SECTION 3: FONT SIZES
// ============================================================
// Type scale — har cheez ka size defined hai.
// Hum Material Design 3 type scale follow karte hain
// thoda customized Islamic premium feel ke liye.
// ============================================================

abstract final class AppFontSize {
  // --- Display (Hero text, Splash screen) ---
  /// 57px — Display Large (splash logo text)
  static const double displayLarge = 57.0;

  /// 45px — Display Medium (hero numbers)
  static const double displayMedium = 45.0;

  /// 36px — Display Small (large feature titles)
  static const double displaySmall = 36.0;

  // --- Headline (Screen titles) ---
  /// 32px — Headline Large (main screen title)
  static const double headlineLarge = 32.0;

  /// 28px — Headline Medium (section title)
  static const double headlineMedium = 28.0;

  /// 24px — Headline Small (card headline)
  static const double headlineSmall = 24.0;

  // --- Title (Component titles) ---
  /// 22px — Title Large (dialog title, app bar)
  static const double titleLarge = 22.0;

  /// 18px — Title Medium (card title, list header)
  static const double titleMedium = 18.0;

  /// 16px — Title Small (subtitle, tab label)
  static const double titleSmall = 16.0;

  // --- Body (Content text) ---
  /// 16px — Body Large (primary reading text)
  static const double bodyLarge = 16.0;

  /// 14px — Body Medium (standard body text)
  static const double bodyMedium = 14.0;

  /// 12px — Body Small (secondary content)
  static const double bodySmall = 12.0;

  // --- Label (UI labels, badges) ---
  /// 14px — Label Large (button text)
  static const double labelLarge = 14.0;

  /// 12px — Label Medium (chip text, tag)
  static const double labelMedium = 12.0;

  /// 11px — Label Small (badge, timestamp)
  static const double labelSmall = 11.0;

  /// 10px — Label XSmall (super small captions)
  static const double labelXSmall = 10.0;

  // --- Arabic Specific Sizes ---
  /// 18px — Arabic body text (Quran ayah small)
  static const double arabicSmall = 18.0;

  /// 22px — Arabic medium (Quran ayah standard)
  static const double arabicMedium = 22.0;

  /// 28px — Arabic large (Quran ayah large)
  static const double arabicLarge = 28.0;

  /// 36px — Arabic display (Bismillah, surah names)
  static const double arabicDisplay = 36.0;

  /// 48px — Arabic hero (Splash bismillah)
  static const double arabicHero = 48.0;
}

// ============================================================
// SECTION 4: LINE HEIGHT
// ============================================================
// Line Height = lines ke beech ki vertical distance
// 1.0 = text height ke barabar (bahut tight)
// 1.5 = 50% extra space (comfortable reading)
// 2.0 = double space (very relaxed)
// Arabic text ko English se zyada line height chahiye
// kyunki Arabic characters upar-neeche zyada space lete hain
// ============================================================

abstract final class AppLineHeight {
  /// 1.0 — Tight (single line elements, buttons)
  static const double tight = 1.0;

  /// 1.2 — Snug (headings)
  static const double snug = 1.2;

  /// 1.3 — Compact (titles)
  static const double compact = 1.3;

  /// 1.4 — Normal (standard UI text)
  static const double normal = 1.4;

  /// 1.5 — Relaxed (body text — most readable)
  static const double relaxed = 1.5;

  /// 1.6 — Loose (long form reading)
  static const double loose = 1.6;

  /// 1.8 — Extra loose (accessibility mode)
  static const double extraLoose = 1.8;

  /// 2.0 — Double (maximum spacing)
  static const double double_ = 2.0;

  // --- Arabic specific ---
  /// 1.8 — Arabic normal (Arabic needs more space)
  static const double arabicNormal = 1.8;

  /// 2.2 — Arabic relaxed (comfortable Arabic reading)
  static const double arabicRelaxed = 2.2;

  /// 2.5 — Arabic loose (Quran text — maximum readability)
  static const double arabicLoose = 2.5;
}

// ============================================================
// SECTION 5: LETTER SPACING
// ============================================================
// Letter Spacing = characters ke beech horizontal space
// Positive = characters door honge (spaced out)
// Negative = characters paas honge (condensed)
// Islamic text mein tighter spacing better lagti hai
// ============================================================

abstract final class AppLetterSpacing {
  /// -0.5 — Tighter (large display text)
  static const double tighter = -0.5;

  /// -0.25 — Tight (headlines)
  static const double tight = -0.25;

  /// 0.0 — Normal (body text)
  static const double normal = 0.0;

  /// 0.15 — Slightly wide (UI labels)
  static const double wide = 0.15;

  /// 0.5 — Wider (subtitle text)
  static const double wider = 0.5;

  /// 1.0 — Widest (uppercase labels, tracking)
  static const double widest = 1.0;

  /// 2.0 — Ultra wide (decorative, logo text)
  static const double ultraWide = 2.0;

  /// 4.0 — Maximum (app name display)
  static const double max = 4.0;
}

// ============================================================
// SECTION 6: TEXT STYLES — ENGLISH (POPPINS)
// ============================================================
// Yahan ready-to-use TextStyle objects hain.
// Inhe directly widgets mein use karo:
//   Text('Hello', style: AppTextStyles.headlineLarge)
//
// Google Fonts ka use:
//   GoogleFonts.poppins() → Poppins font apply karta hai
//   textStyle: parameter → existing style ke upar apply hota hai
// ============================================================

abstract final class AppTextStyles {
  // ══════════════════════════════════════════
  // DISPLAY STYLES
  // Splash screen, hero sections ke liye
  // ══════════════════════════════════════════

  /// Display Large — 57px, Black weight
  /// Use: Splash screen big numbers, hero stats
  static TextStyle get displayLarge => GoogleFonts.poppins(
        fontSize: AppFontSize.displayLarge,
        fontWeight: AppFontWeight.black,
        color: AppColors.textPrimary,
        height: AppLineHeight.snug,
        letterSpacing: AppLetterSpacing.tighter,
      );

  /// Display Medium — 45px, ExtraBold
  /// Use: Hero feature numbers, large counters
  static TextStyle get displayMedium => GoogleFonts.poppins(
        fontSize: AppFontSize.displayMedium,
        fontWeight: AppFontWeight.extraBold,
        color: AppColors.textPrimary,
        height: AppLineHeight.snug,
        letterSpacing: AppLetterSpacing.tighter,
      );

  /// Display Small — 36px, Bold
  /// Use: Section hero text
  static TextStyle get displaySmall => GoogleFonts.poppins(
        fontSize: AppFontSize.displaySmall,
        fontWeight: AppFontWeight.bold,
        color: AppColors.textPrimary,
        height: AppLineHeight.compact,
        letterSpacing: AppLetterSpacing.tight,
      );

  // ══════════════════════════════════════════
  // HEADLINE STYLES
  // Screen titles, major section headers
  // ══════════════════════════════════════════

  /// Headline Large — 32px, Bold
  /// Use: Main screen title (e.g., "Assalamu Alaikum")
  static TextStyle get headlineLarge => GoogleFonts.poppins(
        fontSize: AppFontSize.headlineLarge,
        fontWeight: AppFontWeight.bold,
        color: AppColors.textPrimary,
        height: AppLineHeight.snug,
        letterSpacing: AppLetterSpacing.tight,
      );

  /// Headline Medium — 28px, Bold
  /// Use: Section headlines on home screen
  static TextStyle get headlineMedium => GoogleFonts.poppins(
        fontSize: AppFontSize.headlineMedium,
        fontWeight: AppFontWeight.bold,
        color: AppColors.textPrimary,
        height: AppLineHeight.compact,
        letterSpacing: AppLetterSpacing.tight,
      );

  /// Headline Small — 24px, SemiBold
  /// Use: Card headlines, dialog titles
  static TextStyle get headlineSmall => GoogleFonts.poppins(
        fontSize: AppFontSize.headlineSmall,
        fontWeight: AppFontWeight.semiBold,
        color: AppColors.textPrimary,
        height: AppLineHeight.compact,
        letterSpacing: AppLetterSpacing.normal,
      );

  // ══════════════════════════════════════════
  // TITLE STYLES
  // Component titles, app bar, tabs
  // ══════════════════════════════════════════

  /// Title Large — 22px, SemiBold
  /// Use: App bar title, dialog heading
  static TextStyle get titleLarge => GoogleFonts.poppins(
        fontSize: AppFontSize.titleLarge,
        fontWeight: AppFontWeight.semiBold,
        color: AppColors.textPrimary,
        height: AppLineHeight.normal,
        letterSpacing: AppLetterSpacing.normal,
      );

  /// Title Medium — 18px, SemiBold
  /// Use: Card titles, list section headers
  static TextStyle get titleMedium => GoogleFonts.poppins(
        fontSize: AppFontSize.titleMedium,
        fontWeight: AppFontWeight.semiBold,
        color: AppColors.textPrimary,
        height: AppLineHeight.normal,
        letterSpacing: AppLetterSpacing.normal,
      );

  /// Title Small — 16px, Medium
  /// Use: Subtitle text, tab labels
  static TextStyle get titleSmall => GoogleFonts.poppins(
        fontSize: AppFontSize.titleSmall,
        fontWeight: AppFontWeight.medium,
        color: AppColors.textPrimary,
        height: AppLineHeight.normal,
        letterSpacing: AppLetterSpacing.wide,
      );

  // ══════════════════════════════════════════
  // BODY STYLES
  // Content reading text
  // ══════════════════════════════════════════

  /// Body Large — 16px, Regular
  /// Use: Primary reading content, descriptions
  static TextStyle get bodyLarge => GoogleFonts.poppins(
        fontSize: AppFontSize.bodyLarge,
        fontWeight: AppFontWeight.regular,
        color: AppColors.textBody,
        height: AppLineHeight.relaxed,
        letterSpacing: AppLetterSpacing.normal,
      );

  /// Body Medium — 14px, Regular
  /// Use: Standard body text throughout app
  static TextStyle get bodyMedium => GoogleFonts.poppins(
        fontSize: AppFontSize.bodyMedium,
        fontWeight: AppFontWeight.regular,
        color: AppColors.textBody,
        height: AppLineHeight.relaxed,
        letterSpacing: AppLetterSpacing.normal,
      );

  /// Body Small — 12px, Regular
  /// Use: Secondary content, helper text
  static TextStyle get bodySmall => GoogleFonts.poppins(
        fontSize: AppFontSize.bodySmall,
        fontWeight: AppFontWeight.regular,
        color: AppColors.textSecondary,
        height: AppLineHeight.relaxed,
        letterSpacing: AppLetterSpacing.normal,
      );

  // ══════════════════════════════════════════
  // LABEL STYLES
  // Buttons, chips, badges, tags
  // ══════════════════════════════════════════

  /// Label Large — 14px, SemiBold
  /// Use: Button text, important labels
  static TextStyle get labelLarge => GoogleFonts.poppins(
        fontSize: AppFontSize.labelLarge,
        fontWeight: AppFontWeight.semiBold,
        color: AppColors.textPrimary,
        height: AppLineHeight.tight,
        letterSpacing: AppLetterSpacing.wide,
      );

  /// Label Medium — 12px, Medium
  /// Use: Chip text, tag text, nav labels
  static TextStyle get labelMedium => GoogleFonts.poppins(
        fontSize: AppFontSize.labelMedium,
        fontWeight: AppFontWeight.medium,
        color: AppColors.textSecondary,
        height: AppLineHeight.tight,
        letterSpacing: AppLetterSpacing.wide,
      );

  /// Label Small — 11px, Medium
  /// Use: Badge text, timestamp, small tags
  static TextStyle get labelSmall => GoogleFonts.poppins(
        fontSize: AppFontSize.labelSmall,
        fontWeight: AppFontWeight.medium,
        color: AppColors.textTertiary,
        height: AppLineHeight.tight,
        letterSpacing: AppLetterSpacing.wider,
      );

  /// Label XSmall — 10px, Regular
  /// Use: Super small captions, version numbers
  static TextStyle get labelXSmall => GoogleFonts.poppins(
        fontSize: AppFontSize.labelXSmall,
        fontWeight: AppFontWeight.regular,
        color: AppColors.textTertiary,
        height: AppLineHeight.tight,
        letterSpacing: AppLetterSpacing.wider,
      );

  // ══════════════════════════════════════════
  // SPECIAL PURPOSE STYLES
  // App-specific use cases
  // ══════════════════════════════════════════

  /// App Name Style — "QIBRA AI" logo text
  static TextStyle get appName => GoogleFonts.poppins(
        fontSize: 28.0,
        fontWeight: AppFontWeight.black,
        color: AppColors.accent, // Royal Gold
        height: AppLineHeight.tight,
        letterSpacing: AppLetterSpacing.max, // Very spaced out
      );

  /// App Tagline Style
  static TextStyle get appTagline => GoogleFonts.poppins(
        fontSize: AppFontSize.bodyMedium,
        fontWeight: AppFontWeight.light,
        color: AppColors.textSecondary,
        height: AppLineHeight.relaxed,
        letterSpacing: AppLetterSpacing.wider,
      );

  /// Gold Heading — Important premium headings
  static TextStyle get goldHeading => GoogleFonts.poppins(
        fontSize: AppFontSize.headlineSmall,
        fontWeight: AppFontWeight.bold,
        color: AppColors.accent, // Royal Gold
        height: AppLineHeight.compact,
        letterSpacing: AppLetterSpacing.tight,
      );

  /// Emerald Heading — Primary feature headings
  static TextStyle get emeraldHeading => GoogleFonts.poppins(
        fontSize: AppFontSize.headlineSmall,
        fontWeight: AppFontWeight.bold,
        color: AppColors.primary, // Emerald
        height: AppLineHeight.compact,
        letterSpacing: AppLetterSpacing.tight,
      );

  /// Section Label — Small uppercase section titles
  static TextStyle get sectionLabel => GoogleFonts.poppins(
        fontSize: AppFontSize.labelSmall,
        fontWeight: AppFontWeight.semiBold,
        color: AppColors.textTertiary,
        height: AppLineHeight.tight,
        letterSpacing: AppLetterSpacing.widest,
      );

  /// Button Text Large — Primary/large buttons
  static TextStyle get buttonLarge => GoogleFonts.poppins(
        fontSize: 16.0,
        fontWeight: AppFontWeight.semiBold,
        color: AppColors.textOnEmerald,
        height: AppLineHeight.tight,
        letterSpacing: AppLetterSpacing.wide,
      );

  /// Button Text Medium — Standard buttons
  static TextStyle get buttonMedium => GoogleFonts.poppins(
        fontSize: AppFontSize.labelLarge,
        fontWeight: AppFontWeight.semiBold,
        color: AppColors.textOnEmerald,
        height: AppLineHeight.tight,
        letterSpacing: AppLetterSpacing.wide,
      );

  /// Button Text Small — Compact buttons
  static TextStyle get buttonSmall => GoogleFonts.poppins(
        fontSize: AppFontSize.labelMedium,
        fontWeight: AppFontWeight.medium,
        color: AppColors.textOnEmerald,
        height: AppLineHeight.tight,
        letterSpacing: AppLetterSpacing.wide,
      );

  /// Input Field Text — What user types
  static TextStyle get inputText => GoogleFonts.poppins(
        fontSize: AppFontSize.bodyMedium,
        fontWeight: AppFontWeight.regular,
        color: AppColors.textPrimary,
        height: AppLineHeight.normal,
        letterSpacing: AppLetterSpacing.normal,
      );

  /// Input Hint Text — Placeholder text
  static TextStyle get inputHint => GoogleFonts.poppins(
        fontSize: AppFontSize.bodyMedium,
        fontWeight: AppFontWeight.regular,
        color: AppColors.textHint,
        height: AppLineHeight.normal,
        letterSpacing: AppLetterSpacing.normal,
      );

  /// Input Label Text — Floating label above field
  static TextStyle get inputLabel => GoogleFonts.poppins(
        fontSize: AppFontSize.bodySmall,
        fontWeight: AppFontWeight.medium,
        color: AppColors.textSecondary,
        height: AppLineHeight.tight,
        letterSpacing: AppLetterSpacing.wide,
      );

  /// Error Text — Validation error messages
  static TextStyle get errorText => GoogleFonts.poppins(
        fontSize: AppFontSize.labelMedium,
        fontWeight: AppFontWeight.regular,
        color: AppColors.error,
        height: AppLineHeight.normal,
        letterSpacing: AppLetterSpacing.normal,
      );

  /// Success Text — Success messages
  static TextStyle get successText => GoogleFonts.poppins(
        fontSize: AppFontSize.labelMedium,
        fontWeight: AppFontWeight.regular,
        color: AppColors.success,
        height: AppLineHeight.normal,
        letterSpacing: AppLetterSpacing.normal,
      );

  /// Link Text — Clickable text links
  static TextStyle get link => GoogleFonts.poppins(
        fontSize: AppFontSize.bodyMedium,
        fontWeight: AppFontWeight.medium,
        color: AppColors.textEmerald,
        height: AppLineHeight.relaxed,
        letterSpacing: AppLetterSpacing.normal,
        decoration: TextDecoration.underline,
        decorationColor: AppColors.textEmerald,
      );

  /// Nav Label Active — Bottom nav active item
  static TextStyle get navLabelActive => GoogleFonts.poppins(
        fontSize: AppFontSize.labelSmall,
        fontWeight: AppFontWeight.semiBold,
        color: AppColors.primary,
        height: AppLineHeight.tight,
        letterSpacing: AppLetterSpacing.wide,
      );

  /// Nav Label Inactive — Bottom nav inactive item
  static TextStyle get navLabelInactive => GoogleFonts.poppins(
        fontSize: AppFontSize.labelSmall,
        fontWeight: AppFontWeight.regular,
        color: AppColors.navInactive,
        height: AppLineHeight.tight,
        letterSpacing: AppLetterSpacing.wide,
      );

  /// Prayer Time Style — Large prayer time display
  static TextStyle get prayerTime => GoogleFonts.poppins(
        fontSize: 42.0,
        fontWeight: AppFontWeight.light,
        color: AppColors.textPrimary,
        height: AppLineHeight.tight,
        letterSpacing: AppLetterSpacing.wider,
      );

  /// Prayer Name Style
  static TextStyle get prayerName => GoogleFonts.poppins(
        fontSize: AppFontSize.titleSmall,
        fontWeight: AppFontWeight.medium,
        color: AppColors.textSecondary,
        height: AppLineHeight.tight,
        letterSpacing: AppLetterSpacing.widest,
      );

  /// Onboarding Title
  static TextStyle get onboardingTitle => GoogleFonts.poppins(
        fontSize: AppFontSize.headlineMedium,
        fontWeight: AppFontWeight.bold,
        color: AppColors.textPrimary,
        height: AppLineHeight.snug,
        letterSpacing: AppLetterSpacing.tight,
      );

  /// Onboarding Body
  static TextStyle get onboardingBody => GoogleFonts.poppins(
        fontSize: AppFontSize.bodyLarge,
        fontWeight: AppFontWeight.regular,
        color: AppColors.textSecondary,
        height: AppLineHeight.loose,
        letterSpacing: AppLetterSpacing.normal,
      );

  /// Greeting Text (e.g., "Assalamu Alaikum")
  static TextStyle get greeting => GoogleFonts.poppins(
        fontSize: AppFontSize.headlineSmall,
        fontWeight: AppFontWeight.semiBold,
        color: AppColors.textPrimary,
        height: AppLineHeight.compact,
        letterSpacing: AppLetterSpacing.normal,
      );

  /// Card Title
  static TextStyle get cardTitle => GoogleFonts.poppins(
        fontSize: AppFontSize.titleSmall,
        fontWeight: AppFontWeight.semiBold,
        color: AppColors.textPrimary,
        height: AppLineHeight.compact,
        letterSpacing: AppLetterSpacing.normal,
      );

  /// Card Subtitle
  static TextStyle get cardSubtitle => GoogleFonts.poppins(
        fontSize: AppFontSize.bodySmall,
        fontWeight: AppFontWeight.regular,
        color: AppColors.textSecondary,
        height: AppLineHeight.relaxed,
        letterSpacing: AppLetterSpacing.normal,
      );

  /// Badge Text
  static TextStyle get badge => GoogleFonts.poppins(
        fontSize: AppFontSize.labelXSmall,
        fontWeight: AppFontWeight.bold,
        color: AppColors.white,
        height: AppLineHeight.tight,
        letterSpacing: AppLetterSpacing.normal,
      );

  /// Chip Text
  static TextStyle get chip => GoogleFonts.poppins(
        fontSize: AppFontSize.labelMedium,
        fontWeight: AppFontWeight.medium,
        color: AppColors.textSecondary,
        height: AppLineHeight.tight,
        letterSpacing: AppLetterSpacing.normal,
      );
}

// ============================================================
// SECTION 7: ARABIC TEXT STYLES (AMIRI FONT)
// ============================================================
// Arabic text ke liye alag styles —
// Arabic RTL (Right-to-Left) hoti hai
// Amiri font classical Islamic calligraphy style hai
// Quran text ke liye perfect
// ============================================================

abstract final class AppArabicStyles {
  // ══════════════════════════════════════════
  // QURAN TEXT STYLES
  // ══════════════════════════════════════════

  /// Quran Ayah Small — Small Quran text (search results)
  static TextStyle get quranSmall => GoogleFonts.amiri(
        fontSize: AppFontSize.arabicSmall,
        fontWeight: AppFontWeight.regular,
        color: AppColors.textPrimary,
        height: AppLineHeight.arabicNormal,
        // Arabic text direction handled by parent widget
      );

  /// Quran Ayah Medium — Standard Quran reading
  static TextStyle get quranMedium => GoogleFonts.amiri(
        fontSize: AppFontSize.arabicMedium,
        fontWeight: AppFontWeight.regular,
        color: AppColors.textPrimary,
        height: AppLineHeight.arabicRelaxed,
      );

  /// Quran Ayah Large — Large Quran reading mode
  static TextStyle get quranLarge => GoogleFonts.amiri(
        fontSize: AppFontSize.arabicLarge,
        fontWeight: AppFontWeight.regular,
        color: AppColors.textPrimary,
        height: AppLineHeight.arabicLoose,
      );

  /// Quran Ayah Bold — Highlighted/memorization mode
  static TextStyle get quranBold => GoogleFonts.amiri(
        fontSize: AppFontSize.arabicMedium,
        fontWeight: AppFontWeight.bold,
        color: AppColors.textPrimary,
        height: AppLineHeight.arabicRelaxed,
      );

  // ══════════════════════════════════════════
  // SURAH & AYAH IDENTIFIERS
  // ══════════════════════════════════════════

  /// Surah Name Arabic — Large surah name display
  static TextStyle get surahName => GoogleFonts.amiri(
        fontSize: AppFontSize.arabicDisplay,
        fontWeight: AppFontWeight.bold,
        color: AppColors.accent, // Gold for surah names
        height: AppLineHeight.arabicNormal,
      );

  /// Bismillah — Special style for Bismillahir rahmanir rahim
  static TextStyle get bismillah => GoogleFonts.amiri(
        fontSize: AppFontSize.arabicDisplay,
        fontWeight: AppFontWeight.bold,
        color: AppColors.accent, // Royal Gold
        height: AppLineHeight.arabicRelaxed,
      );

  /// Bismillah Hero — Splash screen / large display
  static TextStyle get bismillahHero => GoogleFonts.amiri(
        fontSize: AppFontSize.arabicHero,
        fontWeight: AppFontWeight.bold,
        color: AppColors.accent,
        height: AppLineHeight.arabicRelaxed,
      );

  // ══════════════════════════════════════════
  // HADITH & DUA TEXT
  // ══════════════════════════════════════════

  /// Hadith Arabic Text
  static TextStyle get hadithArabic => GoogleFonts.amiri(
        fontSize: AppFontSize.arabicMedium,
        fontWeight: AppFontWeight.regular,
        color: AppColors.textPrimary,
        height: AppLineHeight.arabicRelaxed,
      );

  /// Dua Arabic Text
  static TextStyle get duaArabic => GoogleFonts.amiri(
        fontSize: AppFontSize.arabicLarge,
        fontWeight: AppFontWeight.regular,
        color: AppColors.textEmerald, // Emerald for duas
        height: AppLineHeight.arabicLoose,
      );

  /// Ayah Number — Small number inside circle
  static TextStyle get ayahNumber => GoogleFonts.poppins(
        fontSize: AppFontSize.labelSmall,
        fontWeight: AppFontWeight.semiBold,
        color: AppColors.accent,
        height: AppLineHeight.tight,
      );

  /// Translation Text — English/Urdu translation
  static TextStyle get translation => GoogleFonts.poppins(
        fontSize: AppFontSize.bodyMedium,
        fontWeight: AppFontWeight.regular,
        color: AppColors.textSecondary,
        height: AppLineHeight.loose,
        letterSpacing: AppLetterSpacing.normal,
      );

  /// Transliteration Text — Roman Arabic pronunciation
  static TextStyle get transliteration => GoogleFonts.poppins(
        fontSize: AppFontSize.bodySmall,
        fontWeight: AppFontWeight.light,
        color: AppColors.textTertiary,
        height: AppLineHeight.relaxed,
        letterSpacing: AppLetterSpacing.wide,
        fontStyle: FontStyle.italic,
      );
}

// ============================================================
// SECTION 8: TEXT STYLE EXTENSIONS
// ============================================================
// Extension methods — existing TextStyle ko modify karne ke liye
// Jaise: AppTextStyles.bodyLarge.gold → gold color mein body text
//        AppTextStyles.titleMedium.bold → bold title
// Yeh chaining pattern bahut clean code deta hai
// ============================================================

extension TextStyleExtension on TextStyle {
  // --- Color variants ---

  /// Apply primary white color
  TextStyle get white => copyWith(color: AppColors.textPrimary);

  /// Apply secondary gray color
  TextStyle get secondary => copyWith(color: AppColors.textSecondary);

  /// Apply tertiary muted color
  TextStyle get tertiary => copyWith(color: AppColors.textTertiary);

  /// Apply gold accent color
  TextStyle get gold => copyWith(color: AppColors.accent);

  /// Apply bright gold color
  TextStyle get goldBright => copyWith(color: AppColors.accentBright);

  /// Apply emerald primary color
  TextStyle get emerald => copyWith(color: AppColors.primary);

  /// Apply error red color
  TextStyle get error => copyWith(color: AppColors.error);

  /// Apply success green color
  TextStyle get success => copyWith(color: AppColors.success);

  /// Apply warning amber color
  TextStyle get warning => copyWith(color: AppColors.warning);

  /// Apply disabled color
  TextStyle get disabled => copyWith(color: AppColors.textDisabled);

  // --- Weight variants ---

  /// Apply thin weight (100)
  TextStyle get thin => copyWith(fontWeight: AppFontWeight.thin);

  /// Apply light weight (300)
  TextStyle get light => copyWith(fontWeight: AppFontWeight.light);

  /// Apply regular weight (400)
  TextStyle get regular => copyWith(fontWeight: AppFontWeight.regular);

  /// Apply medium weight (500)
  TextStyle get medium => copyWith(fontWeight: AppFontWeight.medium);

  /// Apply semiBold weight (600)
  TextStyle get semiBold => copyWith(fontWeight: AppFontWeight.semiBold);

  /// Apply bold weight (700)
  TextStyle get bold => copyWith(fontWeight: AppFontWeight.bold);

  /// Apply extraBold weight (800)
  TextStyle get extraBold => copyWith(fontWeight: AppFontWeight.extraBold);

  /// Apply black weight (900)
  TextStyle get black => copyWith(fontWeight: AppFontWeight.black);

  // --- Style variants ---

  /// Apply italic style
  TextStyle get italic => copyWith(fontStyle: FontStyle.italic);

  /// Apply underline decoration
  TextStyle get underline => copyWith(decoration: TextDecoration.underline);

  /// Apply line-through decoration
  TextStyle get lineThrough => copyWith(decoration: TextDecoration.lineThrough);

  // --- Size shortcuts ---

  /// Make text 2px larger
  TextStyle get larger => copyWith(fontSize: (fontSize ?? 14) + 2);

  /// Make text 2px smaller
  TextStyle get smaller => copyWith(fontSize: (fontSize ?? 14) - 2);

  // --- Opacity ---

  /// 70% opacity
  TextStyle get muted => copyWith(color: color?.withValues(alpha: 0.70));

  /// 50% opacity
  TextStyle get faded => copyWith(color: color?.withValues(alpha: 0.50));
}

// ============================================================
// SECTION 9: MATERIAL TEXT THEME
// ============================================================
// MaterialApp ka TextTheme — poori app mein default
// text styles set karne ke liye.
// Step 4 (Theme System) mein use hoga.
// Yahan define karke ready rakhte hain.
// ============================================================

abstract final class AppTextTheme {
  /// Complete Material TextTheme using Poppins
  /// Step 4 mein ThemeData mein pass hoga:
  ///   ThemeData(textTheme: AppTextTheme.textTheme)
  static TextTheme get textTheme => TextTheme(
        // Display
        displayLarge: AppTextStyles.displayLarge,
        displayMedium: AppTextStyles.displayMedium,
        displaySmall: AppTextStyles.displaySmall,

        // Headline
        headlineLarge: AppTextStyles.headlineLarge,
        headlineMedium: AppTextStyles.headlineMedium,
        headlineSmall: AppTextStyles.headlineSmall,

        // Title
        titleLarge: AppTextStyles.titleLarge,
        titleMedium: AppTextStyles.titleMedium,
        titleSmall: AppTextStyles.titleSmall,

        // Body
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,

        // Label
        labelLarge: AppTextStyles.labelLarge,
        labelMedium: AppTextStyles.labelMedium,
        labelSmall: AppTextStyles.labelSmall,
      );
}
