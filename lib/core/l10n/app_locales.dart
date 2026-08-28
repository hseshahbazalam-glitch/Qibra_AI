// Partial locales: English, Arabic, Urdu. gen-l10n is NOT enabled.

import 'package:flutter/widgets.dart';

abstract final class AppLocales {
  static const Locale en = Locale('en');
  static const Locale ar = Locale('ar');
  static const Locale ur = Locale('ur');

  static const List<Locale> supported = [en, ar, ur];

  static const Locale fallback = en;

  static bool isRtl(Locale locale) =>
      locale.languageCode == 'ar' || locale.languageCode == 'ur';

  static Locale resolve(Locale? requested) {
    if (requested == null) return fallback;
    for (final locale in supported) {
      if (locale.languageCode == requested.languageCode) return locale;
    }
    return fallback;
  }
}
