// lib/core/design_system/app_design_system.dart

// ============================================================
// QIBRA AI — PREMIUM DESIGN SYSTEM
// Version: 1.0.0
// Description: Single source of truth for all design tokens.
//              Every spacing, radius, shadow, animation, and
//              breakpoint is defined here. Nothing is hardcoded
//              anywhere else in the app.
// ============================================================

import 'package:flutter/material.dart';

// ============================================================
// SECTION 1: APP SPACING
// ============================================================
// Spacing matlab — elements ke beech ki distance.
// Jaise padding, margin, gap between widgets.
// Hum 4px grid system follow karte hain (4, 8, 12, 16...)
// Kyun? Kyunki yeh visually balanced aur professional lagta hai.
// ============================================================

abstract final class AppSpacing {
  // --- Micro Spacings ---
  /// 2px — Bahut choti jagah, jaise icon aur text ke beech
  static const double xs2 = 2.0;

  /// 4px — Choti spacing
  static const double xs = 4.0;

  /// 8px — Small spacing (chip ke andar, badge padding)
  static const double sm = 8.0;

  /// 12px — Medium-small (list tile vertical padding)
  static const double md = 12.0;

  /// 16px — Standard spacing (screen horizontal padding)
  static const double lg = 16.0;

  /// 20px — Medium-large
  static const double xl = 20.0;

  /// 24px — Large spacing (section gaps)
  static const double xl2 = 24.0;

  /// 32px — Extra large (between major sections)
  static const double xl3 = 32.0;

  /// 40px — 2x Extra large
  static const double xl4 = 40.0;

  /// 48px — Hero section padding
  static const double xl5 = 48.0;

  /// 56px — Major layout gaps
  static const double xl6 = 56.0;

  /// 64px — Max spacing (splash screen elements)
  static const double xl7 = 64.0;

  /// 80px — Onboarding vertical spacing
  static const double xl8 = 80.0;

  /// 96px — Full section height gap
  static const double xl9 = 96.0;

  // --- Screen Edge Padding ---
  /// 16px — Standard horizontal padding for all screens
  static const double screenHorizontal = 16.0;

  /// 24px — Horizontal padding for wide content
  static const double screenHorizontalWide = 24.0;

  /// 20px — Standard vertical padding for screens
  static const double screenVertical = 20.0;

  // --- Bottom Navigation ---
  /// 80px — Extra bottom padding for bottom nav bar
  static const double bottomNavHeight = 80.0;

  // --- Card Internal Padding ---
  /// Standard padding inside all cards
  static const EdgeInsets cardPadding = EdgeInsets.all(16.0);

  /// Compact card padding (for small info cards)
  static const EdgeInsets cardPaddingCompact = EdgeInsets.all(12.0);

  /// Large card padding (for featured/hero cards)
  static const EdgeInsets cardPaddingLarge = EdgeInsets.all(24.0);

  // --- Screen Safe Padding ---
  /// Standard screen padding (left, right, top)
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: screenHorizontal,
    vertical: screenVertical,
  );

  /// Only horizontal screen padding
  static const EdgeInsets screenPaddingHorizontal = EdgeInsets.symmetric(
    horizontal: screenHorizontal,
  );
}

// ============================================================
// SECTION 2: APP BORDER RADIUS
// ============================================================
// Border Radius matlab — corners kitne rounded honge.
// Sharp corners = formal, professional
// Round corners = friendly, modern
// QIBRA AI mein hum medium rounded corners use karte hain
// jo Islamic geometric patterns se inspire hain.
// ============================================================

abstract final class AppRadius {
  /// 2px — Almost square (tags, labels)
  static const double xs = 2.0;

  /// 4px — Slight rounding (chips, badges)
  static const double sm = 4.0;

  /// 8px — Small cards, buttons
  static const double md = 8.0;

  /// 12px — Standard card radius
  static const double lg = 12.0;

  /// 16px — Large cards, modals
  static const double xl = 16.0;

  /// 20px — Feature cards
  static const double xl2 = 20.0;

  /// 24px — Bottom sheets
  static const double xl3 = 24.0;

  /// 32px — Pill buttons
  static const double xl4 = 32.0;

  /// 50px — Circular (avatar, icons)
  static const double full = 50.0;

  // --- BorderRadius Objects (ready to use directly) ---

  /// Standard card border radius
  static final BorderRadius cardRadius = BorderRadius.circular(lg);

  /// Large card border radius
  static final BorderRadius cardRadiusLarge = BorderRadius.circular(xl);

  /// Feature card border radius
  static final BorderRadius featureCardRadius = BorderRadius.circular(xl2);

  /// Bottom sheet border radius (only top corners rounded)
  static const BorderRadius bottomSheetRadius = BorderRadius.only(
    topLeft: Radius.circular(xl3),
    topRight: Radius.circular(xl3),
  );

  /// Pill/Capsule shape (for buttons, tabs)
  static final BorderRadius pillRadius = BorderRadius.circular(xl4);

  /// Circular (for avatars, icons)
  static final BorderRadius circularRadius = BorderRadius.circular(full);

  /// Small button radius
  static final BorderRadius buttonRadius = BorderRadius.circular(md);

  /// Standard button radius
  static final BorderRadius buttonRadiusLg = BorderRadius.circular(lg);
}

// ============================================================
// SECTION 3: APP ELEVATION & SHADOWS
// ============================================================
// Shadow matlab — cards ko depth/3D effect dena.
// Zyada shadow = floating effect
// Kam shadow = subtle, flat look
// QIBRA AI ka Islamic dark theme pe shadows gold-tinted hain
// jo premium feel deta hai.
// ============================================================

abstract final class AppElevation {
  // --- Elevation Numbers (for Material widgets) ---
  static const double none = 0.0;
  static const double xs = 1.0;
  static const double sm = 2.0;
  static const double md = 4.0;
  static const double lg = 8.0;
  static const double xl = 12.0;
  static const double xl2 = 16.0;
  static const double xl3 = 24.0;
}

abstract final class AppShadows {
  // --- Subtle Shadow (light cards) ---
  static List<BoxShadow> get subtle => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 8,
          spreadRadius: 0,
          offset: const Offset(0, 2),
        ),
      ];

  // --- Small Shadow (standard cards) ---
  static List<BoxShadow> get small => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 12,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
      ];

  // --- Medium Shadow (floating cards) ---
  static List<BoxShadow> get medium => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.16),
          blurRadius: 20,
          spreadRadius: 0,
          offset: const Offset(0, 8),
        ),
      ];

  // --- Large Shadow (modals, bottom sheets) ---
  static List<BoxShadow> get large => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.24),
          blurRadius: 32,
          spreadRadius: 0,
          offset: const Offset(0, 12),
        ),
      ];

  // --- Gold Glow Shadow (premium elements, CTA buttons) ---
  // Yeh QIBRA AI ka signature shadow hai — gold glow
  static List<BoxShadow> get goldGlow => [
        BoxShadow(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.35),
          blurRadius: 20,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
          blurRadius: 40,
          spreadRadius: 0,
          offset: const Offset(0, 8),
        ),
      ];

  // --- Emerald Glow Shadow (primary action elements) ---
  static List<BoxShadow> get emeraldGlow => [
        BoxShadow(
          color: const Color(0xFF00A86B).withValues(alpha: 0.35),
          blurRadius: 20,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: const Color(0xFF00A86B).withValues(alpha: 0.15),
          blurRadius: 40,
          spreadRadius: 0,
          offset: const Offset(0, 8),
        ),
      ];

  // --- Dark Card Shadow (for dark theme cards) ---
  static List<BoxShadow> get darkCard => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.40),
          blurRadius: 24,
          spreadRadius: 0,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.20),
          blurRadius: 8,
          spreadRadius: 0,
          offset: const Offset(0, 2),
        ),
      ];

  // --- Inset Shadow (for pressed button state) ---
  static List<BoxShadow> get inset => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.20),
          blurRadius: 4,
          spreadRadius: 0,
          offset: const Offset(0, 2),
        ),
      ];
}

// ============================================================
// SECTION 4: APP ANIMATION DURATIONS & CURVES
// ============================================================
// Animation Duration matlab — animation kitni der chalegi.
// Curve matlab — animation ka speed pattern (slow start,
// fast end, bounce, etc.)
// Sahi animation = app "alive" aur "premium" lagti hai.
// Galat animation = app lagti hai heavy aur cheap.
// ============================================================

abstract final class AppDurations {
  // --- Ultra Fast (micro interactions) ---
  /// 50ms — Ripple effects, instant feedback
  static const Duration ultraFast = Duration(milliseconds: 50);

  // --- Fast (button press, toggle) ---
  /// 150ms — Button press, small state changes
  static const Duration fast = Duration(milliseconds: 150);

  // --- Normal (standard transitions) ---
  /// 250ms — Standard widget animations
  static const Duration normal = Duration(milliseconds: 250);

  // --- Medium (page transitions) ---
  /// 350ms — Page/screen transitions
  static const Duration medium = Duration(milliseconds: 350);

  // --- Slow (complex animations) ---
  /// 500ms — Modal appearances, complex transitions
  static const Duration slow = Duration(milliseconds: 500);

  // --- Extra Slow (hero animations, splash) ---
  /// 800ms — Hero animations, splash screen
  static const Duration extraSlow = Duration(milliseconds: 800);

  // --- Ultra Slow (onboarding, loaders) ---
  /// 1200ms — Onboarding transitions, loading animations
  static const Duration ultraSlow = Duration(milliseconds: 1200);

  // --- Splash Duration ---
  /// 3000ms — Total splash screen display time
  static const Duration splash = Duration(milliseconds: 3000);

  // --- Shimmer Duration ---
  /// 1500ms — Skeleton/shimmer loading animation
  static const Duration shimmer = Duration(milliseconds: 1500);
}

abstract final class AppCurves {
  // --- Standard Ease ---
  /// Smooth standard ease (most common)
  static const Curve standard = Curves.easeInOut;

  // --- Ease Out (entering elements) ---
  /// Elements jo screen pe aate hain — fast start, slow end
  static const Curve enter = Curves.easeOut;

  // --- Ease In (leaving elements) ---
  /// Elements jo screen se jaate hain — slow start, fast end
  static const Curve exit = Curves.easeIn;

  // --- Decelerate (material standard) ---
  static const Curve decelerate = Curves.decelerate;

  // --- Bounce (playful elements) ---
  static const Curve bounce = Curves.bounceOut;

  // --- Elastic (spring animations) ---
  static const Curve elastic = Curves.elasticOut;

  // --- Fast Out Slow In (material design) ---
  static const Curve fastOutSlowIn = Curves.fastOutSlowIn;

  // --- Linear (loaders, progress) ---
  static const Curve linear = Curves.linear;

  // --- Overshoot (premium feel buttons) ---
  static const Curve overshoot = Curves.easeOutBack;
}

// ============================================================
// SECTION 5: APP ICON SIZES
// ============================================================
// Icon sizes consistent rakhna bahut zaroori hai.
// Random sizes use karne se app cluttered lagti hai.
// ============================================================

abstract final class AppIconSizes {
  /// 12px — Micro icons (inline with small text)
  static const double xs = 12.0;

  /// 16px — Small icons (inside buttons, chips)
  static const double sm = 16.0;

  /// 20px — Medium-small icons
  static const double md = 20.0;

  /// 24px — Standard icon size (nav bar, list items)
  static const double lg = 24.0;

  /// 28px — Medium-large icons
  static const double xl = 28.0;

  /// 32px — Large icons (section headers)
  static const double xl2 = 32.0;

  /// 40px — Extra large (feature icons)
  static const double xl3 = 40.0;

  /// 48px — Hero icons
  static const double xl4 = 48.0;

  /// 56px — Display icons
  static const double xl5 = 56.0;

  /// 64px — Splash/logo icons
  static const double xl6 = 64.0;

  /// 80px — Full feature icon
  static const double xl7 = 80.0;

  /// 96px — Maximum icon size
  static const double xl8 = 96.0;
}

// ============================================================
// SECTION 6: APP BREAKPOINTS
// ============================================================
// Breakpoints matlab — screen size ke hisab se layout change.
// Phone → Tablet → Desktop pe alag layout dikhana.
// Flutter web aur tablet support ke liye zaroori hai.
// ============================================================

abstract final class AppBreakpoints {
  /// 360px — Small phones (older Android)
  static const double mobile = 360.0;

  /// 480px — Large phones
  static const double mobileLarge = 480.0;

  /// 600px — Small tablets / large phones (landscape)
  static const double tabletSmall = 600.0;

  /// 768px — Standard tablets (iPad mini)
  static const double tablet = 768.0;

  /// 1024px — Large tablets (iPad Pro, landscape)
  static const double tabletLarge = 1024.0;

  /// 1280px — Desktop / laptop
  static const double desktop = 1280.0;

  /// 1440px — Large desktop
  static const double desktopLarge = 1440.0;

  // --- Helper Methods ---

  /// Check if screen is mobile size
  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < tabletSmall;

  /// Check if screen is tablet size
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= tabletSmall && width < desktop;
  }

  /// Check if screen is desktop size
  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktop;

  /// Get current screen width
  static double screenWidth(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  /// Get current screen height
  static double screenHeight(BuildContext context) =>
      MediaQuery.sizeOf(context).height;
}

// ============================================================
// SECTION 7: APP GRADIENTS
// ============================================================
// Gradients = do ya zyada colors ka smooth transition.
// QIBRA AI Islamic theme mein hum use karte hain:
// - Dark Emerald → Black (primary backgrounds)
// - Royal Gold → Amber (premium elements)
// - Emerald → Teal (feature accents)
// ============================================================

abstract final class AppGradients {
  // --- Primary Background Gradient ---
  // Main app background — dark emerald se deep black tak
  static const LinearGradient primaryBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0A1628), // Deep Navy (Islamic night sky)
      Color(0xFF0D1F2D), // Dark Teal-Black
      Color(0xFF050D14), // Almost Black
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // --- Emerald Gradient (primary brand color) ---
  static const LinearGradient emerald = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF00C87A), // Bright Emerald
      Color(0xFF00A86B), // Standard Emerald
      Color(0xFF007A4D), // Deep Emerald
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // --- Gold Gradient (premium/royal accent) ---
  static const LinearGradient gold = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFD700), // Pure Gold
      Color(0xFFD4AF37), // Royal Gold
      Color(0xFFB8860B), // Dark Goldenrod
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // --- Gold Shimmer Gradient (for shimmer animations) ---
  static const LinearGradient goldShimmer = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFFB8860B), // Dark Gold
      Color(0xFFFFD700), // Bright Gold
      Color(0xFFFFEA70), // Light Gold
      Color(0xFFFFD700), // Bright Gold
      Color(0xFFB8860B), // Dark Gold
    ],
    stops: [0.0, 0.25, 0.5, 0.75, 1.0],
  );

  // --- Premium Card Gradient ---
  // Cards ke liye — dark surface with subtle emerald tint
  static const LinearGradient premiumCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1A2940), // Dark navy with blue tint
      Color(0xFF162234), // Deeper navy
    ],
    stops: [0.0, 1.0],
  );

  // --- Emerald Card Gradient ---
  static const LinearGradient emeraldCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF00A86B), // Emerald
      Color(0xFF006B45), // Deep Emerald
    ],
    stops: [0.0, 1.0],
  );

  // --- Gold Card Gradient ---
  static const LinearGradient goldCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFD4AF37), // Royal Gold
      Color(0xFF996515), // Dark Gold
    ],
    stops: [0.0, 1.0],
  );

  // --- Splash Screen Gradient ---
  static const RadialGradient splashGradient = RadialGradient(
    center: Alignment.center,
    radius: 1.5,
    colors: [
      Color(0xFF0D3320), // Dark Emerald center
      Color(0xFF071A14), // Deeper emerald
      Color(0xFF020A08), // Almost black edge
    ],
    stops: [0.0, 0.5, 1.0],
  );

  // --- Onboarding Gradient ---
  static const LinearGradient onboarding = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0A1A12), // Dark green-black top
      Color(0xFF040D09), // Near black bottom
    ],
    stops: [0.0, 1.0],
  );

  // --- Transparent to Black (for image overlays) ---
  static const LinearGradient imageOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.transparent,
      Color(0xCC000000), // 80% black
    ],
    stops: [0.3, 1.0],
  );

  // --- Shimmer Loading Gradient ---
  static const LinearGradient shimmerLoading = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF1A2940), // Dark base
      Color(0xFF243552), // Slightly lighter
      Color(0xFF1A2940), // Dark base again
    ],
    stops: [0.0, 0.5, 1.0],
  );
}

// ============================================================
// SECTION 8: APP BORDER STYLES
// ============================================================
// Borders cards aur containers ko define karte hain.
// QIBRA AI mein subtle gold borders use hote hain
// jo Islamic geometric patterns se inspired hain.
// ============================================================

abstract final class AppBorders {
  // --- Standard Border (subtle) ---
  static Border get subtle => Border.all(
        color: const Color(0xFF1E3A5F).withValues(alpha: 0.5),
        width: 1.0,
      );

  // --- Gold Border (premium) ---
  static Border get gold => Border.all(
        color: const Color(0xFFD4AF37).withValues(alpha: 0.6),
        width: 1.0,
      );

  // --- Gold Border Bold ---
  static Border get goldBold =>
      Border.all(color: const Color(0xFFD4AF37), width: 1.5);

  // --- Emerald Border ---
  static Border get emerald => Border.all(
        color: const Color(0xFF00A86B).withValues(alpha: 0.6),
        width: 1.0,
      );

  // --- Emerald Border Bold ---
  static Border get emeraldBold =>
      Border.all(color: const Color(0xFF00A86B), width: 1.5);

  // --- Error Border ---
  static Border get error =>
      Border.all(color: const Color(0xFFE53E3E), width: 1.0);

  // --- Focus Border (text fields) ---
  static Border get focus =>
      Border.all(color: const Color(0xFF00A86B), width: 2.0);

  // --- None ---
  static Border get none => Border.all(color: Colors.transparent, width: 0);
}

// ============================================================
// SECTION 9: APP OPACITY CONSTANTS
// ============================================================
// Opacity = transparency level (0.0 = invisible, 1.0 = solid)
// Consistent opacity use karne se visual hierarchy maintain hoti hai.
// ============================================================

abstract final class AppOpacity {
  /// Disabled state — 38% visible
  static const double disabled = 0.38;

  /// Hint text — 50% visible
  static const double hint = 0.50;

  /// Secondary text — 60% visible
  static const double secondary = 0.60;

  /// Subdued elements — 70% visible
  static const double subdued = 0.70;

  /// Muted elements — 80% visible
  static const double muted = 0.80;

  /// Nearly visible — 90% visible
  static const double high = 0.90;

  /// Fully visible
  static const double full = 1.0;

  /// Overlay backgrounds — 40% black
  static const double overlay = 0.40;

  /// Modal backgrounds — 70% black
  static const double modalOverlay = 0.70;

  /// Shimmer base — 12% white
  static const double shimmerBase = 0.12;

  /// Shimmer highlight — 25% white
  static const double shimmerHighlight = 0.25;
}

// ============================================================
// SECTION 10: APP ASSET PATHS
// ============================================================
// Saare asset paths ek jagah define — koi bhi galat path
// likhne ka chance nahi. Type-safe asset access.
// ============================================================

abstract final class AppAssets {
  // --- Base Paths ---
  static const String _images = 'assets/images';
  static const String _icons = 'assets/icons';
  static const String _animations = 'assets/animations';
  // --- Logo ---
  static const String logo = '$_images/logo.png';
  static const String logoWhite = '$_images/logo_white.png';
  static const String logoIcon = '$_images/logo_icon.png';

  // --- Splash ---
  static const String splashBackground = '$_images/splash_bg.png';
  static const String splashLogo = '$_images/splash_logo.png';

  // --- Onboarding ---
  static const String onboarding1 = '$_images/onboarding_1.png';
  static const String onboarding2 = '$_images/onboarding_2.png';
  static const String onboarding3 = '$_images/onboarding_3.png';
  static const String onboarding4 = '$_images/onboarding_4.png';

  // --- Quran ---
  static const String quranBg = '$_images/quran_bg.png';
  static const String quranCover = '$_images/quran_cover.png';

  // --- Prayer ---
  static const String mosqueIllustration = '$_images/mosque.png';
  static const String compassBg = '$_images/compass_bg.png';

  // --- Patterns (Islamic geometric) ---
  static const String islamicPattern1 = '$_images/islamic_pattern_1.png';
  static const String islamicPattern2 = '$_images/islamic_pattern_2.png';
  static const String islamicPatternOverlay = '$_images/pattern_overlay.png';

  // --- Lottie Animations ---
  static const String loadingAnimation = '$_animations/loading.json';
  static const String successAnimation = '$_animations/success.json';
  static const String errorAnimation = '$_animations/error.json';
  static const String prayerAnimation = '$_animations/prayer.json';
  static const String quranAnimation = '$_animations/quran.json';
  static const String aiAnimation = '$_animations/ai_thinking.json';

  // --- Icons (SVG) ---
  static const String iconQuran = '$_icons/quran.svg';
  static const String iconPrayer = '$_icons/prayer.svg';
  static const String iconQibla = '$_icons/qibla.svg';
  static const String iconHadith = '$_icons/hadith.svg';
  static const String iconAI = '$_icons/ai.svg';
  static const String iconCalendar = '$_icons/calendar.svg';
  static const String iconTasbih = '$_icons/tasbih.svg';
  static const String iconDua = '$_icons/dua.svg';
}

// ============================================================
// SECTION 11: APP Z-INDEX (Stack Order)
// ============================================================
// Z-index = konsa element upar dikhega (layering).
// Flutter mein Stack widget mein order matters.
// Yeh constants use karke layering clear rahti hai.
// ============================================================

abstract final class AppZIndex {
  static const int background = 0;
  static const int content = 1;
  static const int card = 2;
  static const int overlay = 3;
  static const int modal = 4;
  static const int toast = 5;
  static const int tooltip = 6;
  static const int navigation = 7;
  static const int topmost = 99;
}

// ============================================================
// SECTION 12: DESIGN SYSTEM EXPORT CLASS
// ============================================================
// Yeh class optional hai — iske through sab ek jagah access
// ho sakta hai: AppDesignSystem.spacing.lg etc.
// Lekin direct class access better practice hai.
// ============================================================

/// QIBRA AI Premium Design System
///
/// Usage:
/// ```dart
/// // Spacing
/// SizedBox(height: AppSpacing.lg)
/// Padding(padding: AppSpacing.screenPadding)
///
/// // Border Radius
/// BorderRadius.circular(AppRadius.lg)
/// decoration: BoxDecoration(borderRadius: AppRadius.cardRadius)
///
/// // Shadows
/// boxShadow: AppShadows.goldGlow
/// boxShadow: AppShadows.darkCard
///
/// // Gradients
/// gradient: AppGradients.emerald
/// gradient: AppGradients.gold
///
/// // Animation
/// duration: AppDurations.medium
/// curve: AppCurves.enter
///
/// // Borders
/// border: AppBorders.gold
/// border: AppBorders.emeraldBold
/// ```
abstract final class AppDesignSystem {
  // This class acts as documentation and namespace.
  // All design tokens are accessible via their own classes:
  // AppSpacing, AppRadius, AppElevation, AppShadows,
  // AppDurations, AppCurves, AppIconSizes, AppBreakpoints,
  // AppGradients, AppBorders, AppOpacity, AppAssets
}
