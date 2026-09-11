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


  // ── I18N PHASE A — migrated UI literals (device session 3) ───────
  // English values are BYTE-IDENTICAL to the pre-migration literals.

  // ── Common chrome ──
  String get cancel => _t('Cancel', 'إلغاء', 'منسوخ');
  String get clear => _t('Clear', 'مسح', 'صاف کریں');
  String get close => _t('Close', 'إغلاق', 'بند کریں');
  String get copied => _t('Copied', 'تم النسخ', 'کاپی ہو گیا');
  String get copy => _t('Copy', 'نسخ', 'کاپی');
  String get delete => _t('Delete', 'حذف', 'حذف کریں');
  String get goLabel => _t('Go', 'انتقال', 'جائیں');
  String get next => _t('Next', 'التالي', 'اگلا');
  String get note => _t('Note', 'ملاحظة', 'نوٹ');
  String get okLabel => _t('OK', 'حسنًا', 'ٹھیک ہے');
  String get open => _t('Open', 'فتح', 'کھولیں');
  String get previous => _t('Previous', 'السابق', 'پچھلا');
  String get save => _t('Save', 'حفظ', 'محفوظ کریں');

  // ── Bookmarks ──
  String get bookmarksTitle => _t('Bookmarks', 'الإشارات المرجعية', 'بک مارکس');
  String get thatHadithNotBundled => _t(
        'That hadith is not in the bundled data on this device.',
        'هذا الحديث ليس ضمن البيانات المضمّنة في هذا الجهاز.',
        'یہ حدیث اس ڈیوائس پر شامل ڈیٹا میں موجود نہیں ہے۔',
      );

  // ── Hadith ──
  String get arabicTextSection => _t('Arabic Text (عربي)', 'النص العربي', 'عربی متن');
  String get collectionStillLoading => _t(
        'This collection is still loading — try again in a moment.',
        'هذه المجموعة ما زالت قيد التحميل — أعد المحاولة بعد قليل.',
        'یہ مجموعہ ابھی لوڈ ہو رہا ہے — کچھ دیر بعد دوبارہ کوشش کریں۔',
      );
  String get hadithCopied => _t('Hadith copied', 'تم نسخ الحديث', 'حدیث کاپی ہو گئی');
  String get hadithCopiedToClipboard => _t(
        'Hadith copied to clipboard',
        'تم نسخ الحديث إلى الحافظة',
        'حدیث کلپ بورڈ پر کاپی کر دی گئی',
      );
  String openBook(String name) => _t('Open $name', 'افتح $name', '$name کھولیں');
  String get readingHistoryCleared => _t(
        'Reading history cleared',
        'تم مسح سجل القراءة',
        'مطالعے کی تاریخ صاف کر دی گئی',
      );
  String get thatBookmarkNotBundled => _t(
        'That bookmark is not in the bundled data on this device.',
        'هذه الإشارة المرجعية ليست ضمن البيانات المضمّنة في هذا الجهاز.',
        'یہ بک مارک اس ڈیوائس پر شامل ڈیٹا میں موجود نہیں ہے۔',
      );
  String viewAllSavedHadith(int count) => _t(
        'View all $count saved hadith',
        'عرض جميع الأحاديث المحفوظة ($count)',
        'تمام محفوظ احادیث دیکھیں ($count)',
      );

  // ── Prayer ──
  String get displaySunriseInSchedule => _t(
        'Display sunrise in schedule',
        'عرض الشروق في الجدول',
        'طلوعِ آفتاب شیڈول میں دکھائیں',
      );
  String get enableAdhan => _t('Enable Adhan', 'تفعيل الأذان', 'اذان فعال کریں');
  String get hanafiAsr => _t('Hanafi Asr', 'عصر بمذهب الحنفي', 'حنفی عصر');
  String get playAdhanSound => _t(
        'Play adhan sound',
        'تشغيل صوت الأذان',
        'اذان کی آواز چلائیں',
      );
  String get showSunrise => _t('Show Sunrise', 'إظهار الشروق', 'طلوعِ آفتاب دکھائیں');
  String get use24HourTime => _t(
        'Use 24-hour time',
        'استخدام الوقت بنظام 24 ساعة',
        '24 گھنٹے کا وقت استعمال کریں',
      );

  // ── Quran ──
  String get enterPageRange => _t(
        'Enter a page between 1 and 604',
        'أدخل رقم صفحة بين 1 و604',
        '1 سے 604 کے درمیان صفحہ درج کریں',
      );
  String get showTranslation => _t('Show translation', 'إظهار الترجمة', 'ترجمہ دکھائیں');
  String get showTransliteration => _t(
        'Show transliteration',
        'إظهار الكتابة الصوتية',
        'نقلِ حرفی دکھائیں',
      );
  String get verseCopiedWithSource => _t(
        'Verse copied with source',
        'تم نسخ الآية مع المصدر',
        'آیت متن کے ساتھ کاپی کر لی گئی',
      );
  String get viewAllSurahs => _t(
        'View all surahs',
        'عرض جميع السور',
        'تمام سورتیں دیکھیں',
      );

  // ── Notifications ──
  String get alertBeforePrayer => _t(
        'Alert before prayer:',
        'تنبيه قبل الصلاة:',
        'نماز سے پہلے انتباہ:',
      );
  String get enableNotifications => _t(
        'Enable Notifications',
        'تفعيل الإشعارات',
        'اطلاعات فعال کریں',
      );
  String get notificationSettings => _t(
        'Notification Settings',
        'إعدادات الإشعارات',
        'اطلاعات کی ترتیبات',
      );
  String get prayerAlertsAndReminders => _t(
        'Prayer alerts & reminders',
        'تنبيهات الصلاة والتذكيرات',
        'نمازی انتباہات اور یاد دہانیاں',
      );
  String get saveSettings => _t('Save Settings', 'حفظ الإعدادات', 'ترتیبات محفوظ کریں');
  String get settingsSaved => _t(
        'Settings saved',
        'تم حفظ الإعدادات',
        'ترتیبات محفوظ کر دی گئیں',
      );
  String get tapToGrantNotificationPermission => _t(
        'Tap to grant notification permission',
        'اضغط لمنح إذن الإشعارات',
        'اجازتِ اطلاعات دینے کے لیے ٹیپ کریں',
      );
  String get testAdanAndNotification => _t(
        'Test Azan + Notification',
        'اختبار الأذان والإشعار',
        'اذان اور اطلاع کا تجربہ کریں',
      );

  // ── Settings ──
  String get copyUrl => _t('Copy URL', 'نسخ الرابط', 'لنک کاپی کریں');
  String get deleteLocalData => _t(
        'Delete local data',
        'حذف البيانات المحلية',
        'مقامی ڈیٹا حذف کریں',
      );
  String get logout => _t('Logout', 'تسجيل الخروج', 'لاگ آؤٹ');

  // ── Profile ──
  String avatarNotChanged(String error) => _t(
        'Avatar not changed — $error',
        'لم يتم تغيير الصورة — $error',
        'تصویر تبدیل نہیں ہو سکی — $error',
      );
  String photoDeleteFailed(String error) => _t(
        'Photo still stored — delete failed: $error',
        'الصورة ما زالت محفوظة — فشل الحذف: $error',
        'تصویر ابھی محفوظ ہے — حذف ناکام: $error',
      );
  String get profileSetupComplete => _t(
        'Profile setup complete!',
        'اكتمل إعداد الملف الشخصي!',
        'پروفائل کی تشکیل مکمل ہو گئی!',
      );

  // ── Tafseer ──
  String get ayahNotFound => _t(
        'Ayah not found',
        'لم يتم العثور على الآية',
        'آیت نہیں ملی',
      );
  String get copiedToClipboard => _t(
        'Copied to clipboard',
        'تم النسخ إلى الحافظة',
        'کلپ بورڈ پر کاپی کر دیا گیا',
      );
  String get goBack => _t('Go Back', 'العودة للخلف', 'واپس جائیں');

  // ── Auth ──
  String get acceptTermsAndConditions => _t(
        'Please accept the Terms & Conditions',
        'يرجى قبول الشروط والأحكام',
        'براہ کرم شرائط و ضوابط قبول کریں',
      );
  String get openingEmailApp => _t(
        'Opening email app...',
        'جارٍ فتح تطبيق البريد...',
        'ای میل ایپ کھولا جا رہا ہے...',
      );
  String get otpSentSuccessfully => _t(
        'OTP sent successfully!',
        'تم إرسال رمز التحقق بنجاح!',
        'او ٹی پی کامیابی سے بھیج دیا گیا!',
      );

  // ── Tools: Hajj ──
  String get completeStepByStep => _t(
        'Complete Step-by-Step',
        'بالخطوات الكاملة',
        'مکمل مرحلہ بہ مرحلہ',
      );
  String get hajjGuide => _t('Hajj Guide', 'دليل الحج', 'حج گائیڈ');
  String get ofIslam => _t('of Islam', 'في الإسلام', 'اسلام کا');
  String get theFifthPillar => _t('The Fifth Pillar', 'الركن الخامس', 'پانچواں رکن');

  // ── Tools: Umrah ──
  String get hadithLabel => _t('Hadith', 'الحديث', 'حدیث');
  String get stepByStep => _t('Step-by-Step', 'خطوة بخطوة', 'مرحلہ بہ مرحلہ');
  String stepNumber(int n) => _t('Step $n', 'الخطوة $n', 'مرحلہ $n');
  String get sunnahMuakkadah => _t('Sunnah Mu\'akkadah', 'سنة مؤكدة', 'سنتِ مؤکدہ');
  String get theMinorPilgrimage => _t('The Minor Pilgrimage', 'الحج الأصغر', 'حجِ اصغر');
  String get umrahGuide => _t('Umrah Guide', 'دليل العمرة', 'عمرہ گائیڈ');

  // ── Tools: Halal ──
  String get analyzingProduct => _t(
        'Analyzing Product...',
        'جارٍ تحليل المنتج...',
        'پروڈکٹ کا تجزیہ ہو رہا ہے...',
      );
  String get checkingIngredientsAndEcodes => _t(
        'Checking 100+ ingredients & E-codes',
        'نفحص أكثر من 100 مكوّن ورموز E',
        '100 سے زائد اجزاء اور ای کوڈز کی جانچ ہو رہی ہے',
      );
  String get clearAll => _t('Clear All', 'مسح الكل', 'سب صاف کریں');
  String get detectedText => _t('DETECTED TEXT', 'النص المكتشف', 'شناخت ہونے والا متن');
  String get halalScannerV2 => _t('Halal Scanner V2', 'ماسح الحلال V2', 'حلال اسکینر V2');
  String get ingredientsAnalysis => _t(
        'INGREDIENTS ANALYSIS',
        'تحليل المكونات',
        'اجزاء کا تجزیہ',
      );
  String get noScanHistory => _t(
        'No Scan History',
        'لا يوجد سجل مسح',
        'کوئی اسکین ہسٹری نہیں',
      );
  String get pointAtBarcode => _t(
        'Point at barcode',
        'وجّه الكاميرا نحو الباركود',
        'بارکوڈ کی طرف کیمرا رکھیں',
      );
  String get proBadge => _t('PRO', 'احترافي', 'پروفیشنل');
  String get productDetails => _t(
        'PRODUCT DETAILS',
        'تفاصيل المنتج',
        'پروڈکٹ کی تفصیلات',
      );
  String get recommendations => _t('RECOMMENDATIONS', 'التوصيات', 'تجاویز');
  String get scanAgain => _t('Scan Again', 'امسح مرة أخرى', 'دوبارہ اسکین کریں');
  String get scanIngredientsLabel => _t(
        'Scan Ingredients Label',
        'امسح ملصق المكونات',
        'اجزاء کا لیبل اسکین کریں',
      );
  String get scannedProductsAppearHere => _t(
        'Your scanned products will appear here',
        'ستظهر منتجاتك الممسوحة هنا',
        'آپ کے اسکین کردہ پروڈکٹس یہاں ظاہر ہوں گے',
      );
  String get warnings => _t('WARNINGS', 'تحذيرات', 'احتیاطیں');

  // ── Tools: Inheritance ──
  String get calculateShares => _t(
        'Calculate Shares',
        'احسب الأنصبة',
        'حصص کا حساب لگائیں',
      );
  String get calculationMethod => _t(
        'Calculation Method',
        'طريقة الحساب',
        'حساب کا طریقہ',
      );
  String get childrenAndGrandchildren => _t(
        'Children & Grandchildren',
        'الأبناء والأحفاد',
        'اولاد اور پوتے پوتیاں',
      );
  String get deceasedLabel => _t('Deceased:', 'المتوفى:', 'متوفی:');
  String get distributionSummary => _t(
        'DISTRIBUTION SUMMARY',
        'ملخص التوزيع',
        'تقسیم کا خلاصہ',
      );
  String get fullSiblings => _t(
        'Full Siblings',
        'الإخوة والأخوات الأشقاء',
        'سگے بھائی بہن',
      );
  String get halfSiblings => _t(
        'Half Siblings',
        'الإخوة والأخوات غير الأشقاء',
        'غیر شقیق بھائی بہن',
      );
  String get howItWorks => _t('How It Works', 'كيف تعمل', 'یہ کیسے کام کرتا ہے');
  String get inheritanceCalculator => _t(
        'Inheritance Calculator',
        'حاسبة الميراث',
        'وراثت کیلکولیٹر',
      );
  String get islamicLawOfSuccession => _t(
        'Islamic Law of Succession',
        'أحكام الميراث الشرعية',
        'اسلامی قانونِ وراثت',
      );
  String get maternalSameMother => _t(
        'Maternal (same mother)',
        'للأم (أم واحدة)',
        'مادری (ایک ماں)',
      );
  String get otherRelatives => _t('Other Relatives', 'أقارب آخرون', 'دیگر رشتہ دار');
  String get parentsAndGrandparents => _t(
        'Parents & Grandparents',
        'الوالدان والأجداد',
        'والدین اور آبا و اجداد',
      );
  String get paternalSameFather => _t(
        'Paternal (same father)',
        'للأب (أب واحد)',
        'والدی (ایک باپ)',
      );
  String get quranReference => _t('Quran Reference', 'مرجع من القرآن', 'قرآنی حوالہ');
  String get resetAll => _t('Reset All', 'إعادة تعيين الكل', 'سب ری سیٹ کریں');
  String get spouse => _t('Spouse', 'الزوج/الزوجة', 'شریکِ حیات');
  String get sunniHanafiReference => _t(
        'Sunni / Hanafi (reference)',
        'سني / حنفي (مرجع)',
        'سنی / حنفی (حوالہ)',
      );
  String get sunniHanbali => _t('Sunni / Hanbali', 'سني / حنبلي', 'سنی / حنبلی');
  String get sunniMaliki => _t('Sunni / Maliki', 'سني / مالكي', 'سنی / مالکی');
  String get sunniShafi => _t('Sunni / Shafi\'i', 'سني / شافعي', 'سنی / شافعی');
  String get visualBreakdown => _t('VISUAL BREAKDOWN', 'التوزيع المرئي', 'بصری تجزیہ');

  // ── Tools: Zakat ──
  String get editPrice => _t('Edit price', 'تعديل السعر', 'قیمت میں تبدیلی');
  String editSilverPrice(String unit) => _t(
        'Edit Silver Price ($unit/g)',
        'تعديل سعر الفضة ($unit/غرام)',
        'چاندی کی قیمت تبدیل کریں ($unit/گرام)',
      );
  String get enterValidPrice => _t(
        'Enter valid price',
        'أدخل سعرًا صحيحًا',
        'درست قیمت درج کریں',
      );
  String silverPriceUpdated(String amount) => _t(
        'Silver price updated to $amount/g',
        'تم تحديث سعر الفضة إلى $amount/غرام',
        'چاندی کی قیمت $amount/گرام کر دی گئی',
      );

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
