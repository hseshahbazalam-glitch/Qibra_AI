// lib/core/providers/theme_provider.dart

// ============================================================
// QIBRA AI — THEME & LOCALE PROVIDER (P1-1 Fix: No DummyPrefs)
// Version: 2.0 — Real async SharedPreferences, no race
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qibra_ai/core/constants/app_constants.dart';
import 'package:qibra_ai/core/providers/app_providers.dart';

// ============================================================
// SECTION 1: THEME MODE ENUM
// ============================================================

/// App theme mode options
enum AppThemeMode {
  system,
  light,
  dark;

  String toStorageString() => name;

  static AppThemeMode fromStorageString(String? value) {
    if (value == null) return AppThemeMode.dark;
    return AppThemeMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => AppThemeMode.dark,
    );
  }

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
// SECTION 2: THEME NOTIFIER (Real async, no DummyPrefs)
// ============================================================

class ThemeNotifier extends StateNotifier<AppThemeMode> {
  final Ref _ref;
  SharedPreferences? _prefs;
  bool _initialized = false;

  ThemeNotifier(this._ref) : super(AppThemeMode.dark) {
    _init();
  }

  Future<void> _init() async {
    try {
      _prefs = await _ref.read(sharedPreferencesProvider.future);
      final savedMode = _prefs!.getString(AppStorageKeys.appTheme);
      if (savedMode != null) {
        state = AppThemeMode.fromStorageString(savedMode);
      }
      _initialized = true;
    } catch (_) {}
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    if (state == mode) return;
    state = mode;
    try {
      final prefs = _prefs ?? await _ref.read(sharedPreferencesProvider.future);
      _prefs = prefs;
      await prefs.setString(AppStorageKeys.appTheme, mode.toStorageString());
    } catch (e) {
      debugPrint('Theme save failed: $e');
    }
  }

  Future<void> toggleTheme() async {
    final newMode =
        state == AppThemeMode.dark ? AppThemeMode.light : AppThemeMode.dark;
    await setThemeMode(newMode);
  }

  Future<void> resetToDefault() async {
    await setThemeMode(AppThemeMode.dark);
  }
}

// ============================================================
// SECTION 3: LOCALE NOTIFIER (Real async)
// ============================================================

class LocaleNotifier extends StateNotifier<Locale> {
  final Ref _ref;
  SharedPreferences? _prefs;

  LocaleNotifier(this._ref) : super(const Locale(AppLanguages.english)) {
    _init();
  }

  Future<void> _init() async {
    try {
      _prefs = await _ref.read(sharedPreferencesProvider.future);
      final savedLang = _prefs!.getString(AppStorageKeys.appLanguage);
      if (savedLang != null && AppLanguages.supported.contains(savedLang)) {
        state = Locale(savedLang);
      }
    } catch (_) {}
  }

  Future<void> setLocale(String languageCode) async {
    if (!AppLanguages.supported.contains(languageCode)) {
      debugPrint('Unsupported language: $languageCode');
      return;
    }
    if (state.languageCode == languageCode) return;
    state = Locale(languageCode);
    try {
      final prefs = _prefs ?? await _ref.read(sharedPreferencesProvider.future);
      _prefs = prefs;
      await prefs.setString(AppStorageKeys.appLanguage, languageCode);
    } catch (e) {
      debugPrint('Locale save failed: $e');
    }
  }

  Future<void> setEnglish() => setLocale(AppLanguages.english);
  Future<void> setArabic() => setLocale(AppLanguages.arabic);
  Future<void> setUrdu() => setLocale(AppLanguages.urdu);

  bool get isRTL {
    return state.languageCode == AppLanguages.arabic ||
        state.languageCode == AppLanguages.urdu;
  }

  String get displayName {
    return AppLanguages.displayNames[state.languageCode] ?? 'English';
  }
}

// ============================================================
// SECTION 4: ONBOARDING NOTIFIER (Real async)
// ============================================================

class OnboardingNotifier extends StateNotifier<bool> {
  final Ref _ref;
  SharedPreferences? _prefs;

  OnboardingNotifier(this._ref) : super(false) {
    _init();
  }

  Future<void> _init() async {
    try {
      _prefs = await _ref.read(sharedPreferencesProvider.future);
      state = _prefs!.getBool(AppStorageKeys.hasSeenOnboarding) ?? false;
    } catch (_) {
      state = false;
    }
  }

  Future<void> markComplete() async {
    state = true;
    try {
      final prefs = _prefs ?? await _ref.read(sharedPreferencesProvider.future);
      _prefs = prefs;
      await prefs.setBool(AppStorageKeys.hasSeenOnboarding, true);
      await prefs.setString(
          AppStorageKeys.onboardingDate, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Onboarding save failed: $e');
    }
  }

  Future<void> reset() async {
    state = false;
    try {
      final prefs = _prefs ?? await _ref.read(sharedPreferencesProvider.future);
      _prefs = prefs;
      await prefs.remove(AppStorageKeys.hasSeenOnboarding);
      await prefs.remove(AppStorageKeys.onboardingDate);
    } catch (e) {
      debugPrint('Onboarding reset failed: $e');
    }
  }
}

// ============================================================
// SECTION 5: PROVIDERS (No DummyPrefs)
// ============================================================

final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeMode>((ref) {
  return ThemeNotifier(ref);
});

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier(ref);
});

final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, bool>((ref) {
  return OnboardingNotifier(ref);
});

// ============================================================
// SECTION 6: CONVENIENCE PROVIDERS
// ============================================================

final flutterThemeModeProvider = Provider<ThemeMode>((ref) {
  return ref.watch(themeProvider).toFlutterThemeMode();
});

final isDarkModeProvider = Provider<bool>((ref) {
  return ref.watch(themeProvider) == AppThemeMode.dark;
});

final currentLanguageProvider = Provider<String>((ref) {
  return ref.watch(localeProvider).languageCode;
});

final isRTLProvider = Provider<bool>((ref) {
  final lang = ref.watch(localeProvider).languageCode;
  return lang == AppLanguages.arabic || lang == AppLanguages.urdu;
});
