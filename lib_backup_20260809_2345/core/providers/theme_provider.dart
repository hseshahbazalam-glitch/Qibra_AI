// lib/core/providers/theme_provider.dart

// ============================================================
// QIBRA AI — THEME & LOCALE PROVIDER
// Version: 1.0.0
// Description: Theme mode and locale state management.
//              Automatic persistence to SharedPreferences.
//              Auto-restore on app restart.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qibra_ai/core/constants/app_constants.dart';
import 'package:qibra_ai/core/providers/app_providers.dart';

// ============================================================
// SECTION 1: THEME MODE ENUM
// ============================================================
// Theme ki 3 possible modes
// ============================================================

/// App theme mode options
enum AppThemeMode {
  /// System settings follow karo
  system,

  /// Force light mode
  light,

  /// Force dark mode
  dark;

  /// Enum ko String mein convert karo (storage ke liye)
  String toStorageString() => name;

  /// String se AppThemeMode banao
  static AppThemeMode fromStorageString(String? value) {
    if (value == null) return AppThemeMode.dark;
    return AppThemeMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => AppThemeMode.dark,
    );
  }

  /// Flutter ka ThemeMode return karo
  ThemeMode toFlutterThemeMode() {
    switch (this) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
    }
  }

  /// Display name for UI
  String get displayName {
    switch (this) {
      case AppThemeMode.system:
        return 'System Default';
      case AppThemeMode.light:
        return 'Light Mode';
      case AppThemeMode.dark:
        return 'Dark Mode';
    }
  }

  /// Icon for UI
  IconData get icon {
    switch (this) {
      case AppThemeMode.system:
        return Icons.brightness_auto;
      case AppThemeMode.light:
        return Icons.light_mode;
      case AppThemeMode.dark:
        return Icons.dark_mode;
    }
  }
}

// ============================================================
// SECTION 2: THEME NOTIFIER
// ============================================================
// Theme state manage karta hai
// SharedPreferences se automatically load/save karta hai
// ============================================================

class ThemeNotifier extends StateNotifier<AppThemeMode> {
  final SharedPreferences _prefs;

  ThemeNotifier(this._prefs) : super(AppThemeMode.dark) {
    // Constructor mein saved theme load karo
    _loadSavedTheme();
  }

  // ── LOAD SAVED THEME ─────────────────────────────────
  void _loadSavedTheme() {
    try {
      final savedMode = _prefs.getString(AppStorageKeys.appTheme);
      if (savedMode != null) {
        state = AppThemeMode.fromStorageString(savedMode);
      }
    } catch (e) {
      // Error hone par default dark mode
      state = AppThemeMode.dark;
    }
  }

  // ── SET THEME MODE ───────────────────────────────────
  /// Theme mode change karo aur save karo
  Future<void> setThemeMode(AppThemeMode mode) async {
    if (state == mode) return; // Same mode — kuch mat karo

    state = mode;

    // SharedPreferences mein save karo
    try {
      await _prefs.setString(
        AppStorageKeys.appTheme,
        mode.toStorageString(),
      );
    } catch (e) {
      // Save fail hone par bhi state update rehta hai
      debugPrint('Theme save failed: $e');
    }
  }

  // ── TOGGLE THEME ─────────────────────────────────────
  /// Dark aur Light ke beech toggle karo
  Future<void> toggleTheme() async {
    final newMode =
        state == AppThemeMode.dark ? AppThemeMode.light : AppThemeMode.dark;
    await setThemeMode(newMode);
  }

  // ── RESET TO DEFAULT ─────────────────────────────────
  /// Default dark mode pe wapas jaao
  Future<void> resetToDefault() async {
    await setThemeMode(AppThemeMode.dark);
  }
}

// ============================================================
// SECTION 3: LOCALE NOTIFIER
// ============================================================
// Language/Locale state manage karta hai
// ============================================================

class LocaleNotifier extends StateNotifier<Locale> {
  final SharedPreferences _prefs;

  LocaleNotifier(this._prefs) : super(const Locale(AppLanguages.english)) {
    _loadSavedLocale();
  }

  // ── LOAD SAVED LOCALE ────────────────────────────────
  void _loadSavedLocale() {
    try {
      final savedLang = _prefs.getString(AppStorageKeys.appLanguage);
      if (savedLang != null && AppLanguages.supported.contains(savedLang)) {
        state = Locale(savedLang);
      }
    } catch (e) {
      // Default English pe fallback
      state = const Locale(AppLanguages.english);
    }
  }

  // ── SET LOCALE ───────────────────────────────────────
  /// Language change karo
  Future<void> setLocale(String languageCode) async {
    // Validate language code
    if (!AppLanguages.supported.contains(languageCode)) {
      debugPrint('Unsupported language: $languageCode');
      return;
    }

    if (state.languageCode == languageCode) return;

    state = Locale(languageCode);

    try {
      await _prefs.setString(
        AppStorageKeys.appLanguage,
        languageCode,
      );
    } catch (e) {
      debugPrint('Locale save failed: $e');
    }
  }

  // ── QUICK SETTERS ────────────────────────────────────
  Future<void> setEnglish() => setLocale(AppLanguages.english);
  Future<void> setArabic() => setLocale(AppLanguages.arabic);
  Future<void> setUrdu() => setLocale(AppLanguages.urdu);

  // ── HELPERS ──────────────────────────────────────────
  /// Kya current language RTL hai? (Arabic, Urdu)
  bool get isRTL {
    return state.languageCode == AppLanguages.arabic ||
        state.languageCode == AppLanguages.urdu;
  }

  /// Language ka display name
  String get displayName {
    return AppLanguages.displayNames[state.languageCode] ?? 'English';
  }
}

// ============================================================
// SECTION 4: ONBOARDING NOTIFIER
// ============================================================
// Onboarding completion status manage karta hai
// Router auth guard mein use hoga
// ============================================================

class OnboardingNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;

  OnboardingNotifier(this._prefs) : super(false) {
    _loadState();
  }

  // ── LOAD SAVED STATE ─────────────────────────────────
  void _loadState() {
    try {
      final hasSeenOnboarding =
          _prefs.getBool(AppStorageKeys.hasSeenOnboarding) ?? false;
      state = hasSeenOnboarding;
    } catch (e) {
      state = false;
    }
  }

  // ── MARK COMPLETE ────────────────────────────────────
  /// Onboarding complete mark karo
  Future<void> markComplete() async {
    state = true;
    try {
      await _prefs.setBool(
        AppStorageKeys.hasSeenOnboarding,
        true,
      );
      // Completion date bhi save karo
      await _prefs.setString(
        AppStorageKeys.onboardingDate,
        DateTime.now().toIso8601String(),
      );
    } catch (e) {
      debugPrint('Onboarding save failed: $e');
    }
  }

  // ── RESET ────────────────────────────────────────────
  /// Testing ke liye — onboarding reset karo
  Future<void> reset() async {
    state = false;
    try {
      await _prefs.remove(AppStorageKeys.hasSeenOnboarding);
      await _prefs.remove(AppStorageKeys.onboardingDate);
    } catch (e) {
      debugPrint('Onboarding reset failed: $e');
    }
  }
}

// ============================================================
// SECTION 5: THEME PROVIDER
// ============================================================
// Main theme state provider
// SharedPreferences ready hone ke baad hi kaam karega
// ============================================================

/// Theme mode provider
/// Dark/Light/System selection
///
/// Usage:
///   final themeMode = ref.watch(themeProvider);
///   final theme = ref.read(themeProvider.notifier);
///
///   // Toggle theme
///   await theme.toggleTheme();
///
///   // Set specific mode
///   await theme.setThemeMode(AppThemeMode.dark);
final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeMode>((ref) {
  final prefsAsync = ref.watch(sharedPreferencesProvider);

  return prefsAsync.when(
    data: (prefs) => ThemeNotifier(prefs),
    // Loading state — temporary dummy notifier
    loading: () => ThemeNotifier(_DummyPrefs()),
    error: (_, __) => ThemeNotifier(_DummyPrefs()),
  );
});

// ============================================================
// SECTION 6: LOCALE PROVIDER
// ============================================================

/// Locale provider
/// Language/region selection
///
/// Usage:
///   final locale = ref.watch(localeProvider);
///   final localeNotifier = ref.read(localeProvider.notifier);
///
///   // Set language
///   await localeNotifier.setArabic();
///
///   // Check RTL
///   final isRTL = localeNotifier.isRTL;
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final prefsAsync = ref.watch(sharedPreferencesProvider);

  return prefsAsync.when(
    data: (prefs) => LocaleNotifier(prefs),
    loading: () => LocaleNotifier(_DummyPrefs()),
    error: (_, __) => LocaleNotifier(_DummyPrefs()),
  );
});

// ============================================================
// SECTION 7: ONBOARDING PROVIDER
// ============================================================

/// Onboarding completion provider
/// Router redirect mein use hota hai
///
/// Usage:
///   final hasSeenOnboarding = ref.watch(onboardingProvider);
///   final onboarding = ref.read(onboardingProvider.notifier);
///
///   // Mark complete
///   await onboarding.markComplete();
final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, bool>((ref) {
  final prefsAsync = ref.watch(sharedPreferencesProvider);

  return prefsAsync.when(
    data: (prefs) => OnboardingNotifier(prefs),
    loading: () => OnboardingNotifier(_DummyPrefs()),
    error: (_, __) => OnboardingNotifier(_DummyPrefs()),
  );
});

// ============================================================
// SECTION 8: CONVENIENCE PROVIDERS
// ============================================================

/// Flutter ka ThemeMode direct access
/// MaterialApp mein directly use hoga
///
/// Usage:
///   MaterialApp(
///     themeMode: ref.watch(flutterThemeModeProvider),
///     ...
///   );
final flutterThemeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(themeProvider).toFlutterThemeMode();
});

/// Is dark mode currently active?
///
/// Usage:
///   final isDark = ref.watch(isDarkModeProvider);
final isDarkModeProvider = Provider<bool>((ref) {
  return ref.watch(themeProvider) == AppThemeMode.dark;
});

/// Current language code (en, ar, ur)
///
/// Usage:
///   final lang = ref.watch(currentLanguageProvider);
final currentLanguageProvider = Provider<String>((ref) {
  return ref.watch(localeProvider).languageCode;
});

/// Is current language RTL (Arabic/Urdu)?
///
/// Usage:
///   final isRTL = ref.watch(isRTLProvider);
///   Directionality(
///     textDirection: isRTL ? TextDirection.rtl : TextDirection.ltr,
///     child: ...,
///   );
final isRTLProvider = Provider<bool>((ref) {
  final lang = ref.watch(localeProvider).languageCode;
  return lang == AppLanguages.arabic || lang == AppLanguages.urdu;
});

// ============================================================
// SECTION 9: DUMMY SHARED PREFERENCES
// ============================================================
// Fallback jab SharedPreferences load ho rahi hai
// In-memory only — persist nahi karta
// Sirf temporary use ke liye
// ============================================================

class _DummyPrefs implements SharedPreferences {
  final Map<String, Object> _data = {};

  @override
  Future<bool> setString(String key, String value) async {
    _data[key] = value;
    return true;
  }

  @override
  Future<bool> setBool(String key, bool value) async {
    _data[key] = value;
    return true;
  }

  @override
  Future<bool> setInt(String key, int value) async {
    _data[key] = value;
    return true;
  }

  @override
  Future<bool> setDouble(String key, double value) async {
    _data[key] = value;
    return true;
  }

  @override
  Future<bool> setStringList(String key, List<String> value) async {
    _data[key] = value;
    return true;
  }

  @override
  String? getString(String key) => _data[key] as String?;

  @override
  bool? getBool(String key) => _data[key] as bool?;

  @override
  int? getInt(String key) => _data[key] as int?;

  @override
  double? getDouble(String key) => _data[key] as double?;

  @override
  List<String>? getStringList(String key) => _data[key] as List<String>?;

  @override
  Object? get(String key) => _data[key];

  @override
  bool containsKey(String key) => _data.containsKey(key);

  @override
  Set<String> getKeys() => _data.keys.toSet();

  @override
  Future<bool> remove(String key) async {
    _data.remove(key);
    return true;
  }

  @override
  Future<bool> clear() async {
    _data.clear();
    return true;
  }

  @override
  Future<bool> commit() async => true;

  @override
  Future<void> reload() async {}
}
