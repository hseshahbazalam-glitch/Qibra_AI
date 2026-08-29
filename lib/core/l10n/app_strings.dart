// Hand-written strings for en / ar / ur. Do not enable gen-l10n.

import 'package:flutter/widgets.dart';

class AppStrings {
  const AppStrings._(this.locale);

  final Locale locale;

  static AppStrings of(BuildContext context) {
    final locale = Localizations.maybeLocaleOf(context) ?? const Locale('en');
    return AppStrings._(locale);
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
