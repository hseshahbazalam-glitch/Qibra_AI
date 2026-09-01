// Hand-written strings for en / ar / ur. Do not enable gen-l10n.

import 'package:flutter/widgets.dart';

class AppStringsScope extends InheritedWidget {
  const AppStringsScope({
    super.key,
    required this.locale,
    required super.child,
  });

  final Locale locale;

  static Locale localeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<AppStringsScope>()?.locale ??
        Localizations.maybeLocaleOf(context) ??
        const Locale('en');
  }

  @override
  bool updateShouldNotify(AppStringsScope oldWidget) =>
      locale != oldWidget.locale;
}

class AppStrings {
  const AppStrings._(this.locale);

  final Locale locale;

  static AppStrings of(BuildContext context) {
    return AppStrings._(AppStringsScope.localeOf(context));
  }

  static AppStrings forCode(String code) => AppStrings._(Locale(code));

  String get _code => locale.languageCode;

  String get loading => _t('Loading', 'جاري التحميل', 'لوڈ ہو رہا ہے');
  String get empty => _t('Nothing here yet', 'لا يوجد شيء بعد', 'ابھی کچھ نہیں');
  String get error => _t('Something went wrong', 'حدث خطأ', 'کچھ غلط ہو گیا');
  String get offline => _t('Offline', 'غير متصل', 'آف لائن');
  String get offlineHint => _t(
        'Network status is unknown or offline. Cached content still works.',
        'حالة الشبكة غير معروفة أو غير متصلة.',
        'نیٹ ورک کی حالت نامعلوم یا آف لائن ہے۔',
      );
  String get retry => _t('Retry', 'إعادة المحاولة', 'دوبارہ کوشش');
  String get unknown => _t('Unknown', 'غير معروف', 'نامعلوم');
  String get recitationNotBundled => _t(
        'Recitation is not bundled',
        'التلاوة غير مضمّنة',
        'تلاوت شامل نہیں',
      );
  String get continueAsGuest =>
      _t('Continue as guest', 'المتابعة كضيف', 'مہمان کے طور پر جاری رکھیں');
  String get settings => _t('Settings', 'الإعدادات', 'ترتیبات');
  String get language => _t('Language', 'اللغة', 'زبان');
  String get guest => _t('Guest', 'ضيف', 'مہمان');
  String get tafsirUnavailable => _t(
        'Verified tafsir is not bundled in this build.',
        'التفسير الموثّق غير مضمّن في هذا الإصدار.',
        'مستند تفسیر اس بلڈ میں شامل نہیں ہے۔',
      );
  String get translationUnavailable => _t(
        'Verified translation unavailable for this language.',
        'لا تتوفر ترجمة موثّقة لهذه اللغة.',
        'اس زبان کا تصدیق شدہ ترجمہ دستیاب نہیں۔',
      );
  String get quranTranslation => _t(
        'Quran translation',
        'ترجمة القرآن',
        'قرآن کا ترجمہ',
      );
  String get hadithLanguage => _t(
        'Hadith language',
        'لغة الحديث',
        'حدیث کی زبان',
      );

  String get navHome => _t('Home', 'الرئيسية', 'ہوم');
  String get navQuran => _t('Quran', 'القرآن', 'قرآن');
  String get navPrayer => _t('Prayer', 'الصلاة', 'نماز');
  String get navHadith => _t('Hadith', 'الحديث', 'حدیث');
  String get navAi => _t('AI', 'الذكاء', 'AI');
  String get navMore => _t('More', 'المزيد', 'مزید');
  String get goHome => _t('Go to Home', 'الذهاب إلى الرئيسية', 'ہوم پر جائیں');
  String get pageNotFound =>
      _t('Page not found', 'الصفحة غير موجودة', 'صفحہ نہیں ملا');

  String _t(String en, String ar, String ur) {
    switch (_code) {
      case 'ar':
        return ar;
      case 'ur':
        return ur;
      default:
        return en;
    }
  }
}
