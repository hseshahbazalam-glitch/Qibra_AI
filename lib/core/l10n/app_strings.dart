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
  String get navAi => _t('AI', 'الذكاء', 'اے آئی');
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

  // Pass H1 — hadith depth & disclosure. Real translations in all three
  // shipped languages (no machine-literal filler; census-safe: features
  // render these through getters, never as Text('Capital…') literals).
  String get hadithGradeNotRecorded => _t(
        'Grade not recorded',
        'لم تُسجَّل درجة لهذا الحديث',
        'اس حدیث کا درجہ ریکارڈ نہیں ہے',
      );
  String hadithKitabLabel(int number) => _t(
        'Book $number',
        'كتاب $number',
        'کتاب $number',
      );
  String hadithCoverageOfBook(int percent) => _t(
        '$percent% of this book',
        '$percent٪ من هذا الكتاب',
        'اس کتاب کا $percent٪',
      );
  String get hadithNotAvailableForBook => _t(
        'not available for this book',
        'غير متوفر لهذا الكتاب',
        'اس کتاب کے لیے دستیاب نہیں',
      );
  String hadithThinCoverage(String lang, String book, int percent) => _t(
        '$lang: $percent% of $book',
        '$lang: $percent٪ من $book',
        '$lang: $book کا $percent٪',
      );
  String hadithNoEditionFor(String lang, String book) => _t(
        '$lang is not available for $book',
        'ترجمة $lang غير متوفرة لـ$book',
        '$book کے لیے $lang ترجمہ دستیاب نہیں',
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

  // ── Quran audio world-class (Pass Q1) — reciter / downloads / storage / hifz ──
  String get reciter => _t('Reciter', 'القارئ', 'قاری');
  String get downloadable =>
      _t('Downloadable', 'متاح للتنزيل', 'ڈاؤن لوڈ دستیاب');
  String get downloadedLabel => _t('Downloaded', 'تم التنزيل', 'ڈاؤن لوڈ شدہ');
  String get downloadAll => _t(
        'Download full Quran',
        'تنزيل المصحف كاملًا',
        'پورا مصحف ڈاؤن لوڈ کریں',
      );
  String downloadAllProgress(int done, int total) => _t(
        'Downloaded $done of $total surahs',
        'نُزِّل $done من $total سورة',
        '$total سورتوں میں سے $done ڈاؤن لوڈ ہوئیں',
      );
  String get storage => _t('Storage', 'التخزين', 'اسٹوریج');
  String get tilawatCache =>
      _t('Tilawat cache', 'ذاكرة التلاوات', 'تلاوتوں کا کیش');
  String get deleteAllRecitations => _t(
        'Delete all recitations',
        'حذف جميع التلاوات',
        'تمام تلاوتیں حذف کریں',
      );
  String get confirmDeleteAllBody => _t(
        'This removes every downloaded tilawat file on this device. '
        'Recitation falls back to streaming.',
        'تُزيل هذه العملية جميع ملفات التلاوات المنزّلة على هذا الجهاز، '
        'وتعود التلاوة إلى البث المباشر.',
        'اس ڈیوائس پر ڈاؤن لوڈ شدہ تمام فائلیں ہٹ جائیں گی؛ تلاوت براہِ راست '
        'اسٹریمنگ پر واپس آ جائے گی۔',
      );
  String get repeat => _t('Repeat', 'التكرار', 'دہرائی');
  String get repeatOff => _t('No repeat', 'بدون تكرار', 'بغیر دہرائے');
  String get repeatAyah => _t('Repeat ayah', 'تكرار الآية', 'آیت دہرائیں');
  String get repeatRange => _t('Repeat range', 'تكرار المدى', 'رینج دہرائیں');
  String get speed => _t('Speed', 'السرعة', 'رفتار');
  String get pickStartAyah => _t(
        'Tap the ayah that starts the range',
        'المس الآية التي يبدأ عندها المدى',
        'وہ آیت چنیں جہاں سے رینج شروع ہو',
      );
  String get pickEndAyah => _t(
        'Tap the ayah that ends the range',
        'المس الآية التي ينتهي عندها المدى',
        'وہ آیت چنیں جہاں رینج ختم ہو',
      );
  String get rangeNotSet =>
      _t('Range not set', 'لم يُحدَّد المدى', 'رینج مقرر نہیں');

  // ── Quran reading & tracking (Pass Q2) — khatm / streak / compare / search scope ──
  String get khatmCoverage => _t('Khatm coverage', 'تغطية الختم', 'ختم کا احاطہ');
  String khatmSummary(
          int opened, int totalSurahs, int ayahs, int pct, int totalAyahs) => _t(
        '$opened of $totalSurahs surahs reached its last ayah · $ayahs ayahs high-water (~$pct% of $totalAyahs)',
        'بلغت $opened من $totalSurahs سورةً آيتها الأخير · أعلى تسلسل مقروء: $ayahs آية (~$pct٪ من $totalAyahs)',
        '$totalSurahs سورتوں میں سے $opened نے اپنی آخری آیت پائی · بلندیِ تسلسل $ayahs آیات (~$totalAyahs میں سے $pct٪)',
      );
  String get khatmHonestCaption => _t(
        'High-water coverage only — never a completion claim.',
        'تغطية أعلى تسلسل مقروء فقط — ليست دعوى إتمام.',
        'بلندیِ تسلسل کا احاطہ — مکمل ہونے کا دعوٰی ہرگز نہیں۔',
      );
  String get noStreakYet => _t('No streak yet', 'لا توجد سلسلة بعد', 'ابھی کوئی سلسلہ نہیں');
  String get compareTranslations => _t('Compare translations', 'مقارنة التراجم', 'تراجم کا موازنہ');
  String get compareTranslationsHint => _t(
        'Show the English and Urdu columns under every ayah on the Translation tab.',
        'اعرض العمودين الإنجليزي والأردوي تحت كل آية في تبويب الترجمة.',
        'ترجمہ ٹیب پر ہر آیت کے نیچے انگریزی اور اردو کالم دکھائیں۔',
      );
  String bundledTranslationsForAyah(int n) => _t(
        'Bundled translations — ayah $n',
        'الترجمتان المضمَّنتان — الآية $n',
        'مضمون ترجمے — آیت $n',
      );
  String get searchScope => _t('Scope', 'نطاق البحث', 'تلاش کا دائرہ');
  String get playFromHere => _t('Play from here', 'التشغيل من هنا', 'یہاں سے چلائیں');

  // ── Pass A (a11y): tooltips & word hints — every tappable icon says what it does ──
  String get tooltipBack => _t('Back', '\u0631\u062C\u0648\u0639', '\u0648\u0627\u067E\u0633');
  String get tooltipProfile => _t('Profile', '\u0627\u0644\u0645\u0644\u0641 \u0627\u0644\u0634\u062E\u0635\u064A', '\u067E\u0631\u0648\u0641\u0627\u0626\u0644');
  String get tooltipNotifications => _t('Notifications', '\u0627\u0644\u0625\u0634\u0639\u0627\u0631\u0627\u062A', '\u0627\u0637\u0644\u0627\u0639\u0627\u062A');
  String get tooltipQibla => _t('Qibla', '\u0627\u0644\u0642\u0628\u0644\u0629', '\u0642\u0628\u0644\u06C1');
  String get tooltipGpsUpdate => _t('Tap to update location from GPS', '\u0627\u0646\u0642\u0631 \u0644\u062A\u062D\u062F\u064A\u062B \u0627\u0644\u0645\u0648\u0642\u0639 \u0639\u0628\u0631 GPS', '\u0645\u0642\u0627\u0645 GPS \u0633\u06D2 \u062A\u0627\u0632\u06C1 \u06A9\u0631\u0646\u06D2 \u06A9\u06D2 \u0644\u06CC\u06D2 \u062F\u0628\u0627\u0626\u06CC\u06BA');
  String get tooltipSearch => _t('Search', '\u0628\u062D\u062B', '\u062A\u0644\u0627\u0634');
  String get tooltipSort => _t('Sort', '\u062A\u0631\u062A\u064A\u0628', '\u062A\u0631\u062A\u06CC\u0628');
  String get tooltipClearQuranBookmarks => _t('Clear Quran bookmarks', '\u0645\u0633\u062D \u0625\u0634\u0627\u0631\u0627\u062A \u0627\u0644\u0642\u0631\u0622\u0646', '\u0642\u0631\u0622\u0646 \u06A9\u06D2 \u0628\u06A9 \u0645\u0627\u0631\u06A9 \u0635\u0627\u0641 \u06A9\u0631\u06CC\u06BA');
  String get tooltipRemoveBookmark => _t('Remove bookmark', '\u0625\u0632\u0627\u0644\u0629 \u0627\u0644\u0625\u0634\u0627\u0631\u0629', '\u0628\u06A9 \u0645\u0627\u0631\u06A9 \u06C1\u0679\u0627\u0626\u06CC\u06BA');
  String get tooltipBookmark => _t('Bookmark', '\u0625\u0636\u0627\u0641\u0629 \u0625\u0634\u0627\u0631\u0629', '\u0628\u06A9 \u0645\u0627\u0631\u06A9 \u0628\u0646\u0627\u0626\u06CC\u06BA');
  String get tooltipBookmarkAyah => _t('Bookmark ayah', '\u0625\u0634\u0627\u0631\u0629 \u0639\u0644\u0649 \u0627\u0644\u0622\u064A\u0629', '\u0622\u06CC\u062A \u06A9\u0627 \u0628\u06A9 \u0645\u0627\u0631\u06A9 \u0628\u0646\u0627\u0626\u06CC\u06BA');
  String get tooltipBookmarkPage => _t('Bookmark page', '\u0625\u0634\u0627\u0631\u0629 \u0639\u0644\u0649 \u0627\u0644\u0635\u0641\u062D\u0629', '\u0635\u0641\u062D\u06D2 \u06A9\u0627 \u0628\u06A9 \u0645\u0627\u0631\u06A9 \u0628\u0646\u0627\u0626\u06CC\u06BA');
  String get tooltipExplainAI => _t('Explain with AI', '\u0627\u0634\u0631\u062D \u0628\u0627\u0644\u0630\u0643\u0627\u0621 \u0627\u0644\u0627\u0635\u0637\u0646\u0627\u0639\u064A', 'AI \u0633\u06D2 \u0648\u0636\u0627\u062D\u062A \u06A9\u0631\u06CC\u06BA');
  String get tooltipCopyToShare => _t('Copy to share', '\u0627\u0646\u0633\u062E \u0644\u0644\u0645\u0634\u0627\u0631\u0643\u0629', '\u0634\u06CC\u0626\u0631 \u06A9\u06D2 \u0644\u06CC\u06D2 \u0646\u0642\u0644 \u06A9\u0631\u06CC\u06BA');
  String get tooltipShare => _t('Share', '\u0645\u0634\u0627\u0631\u0643\u0629', '\u0634\u06CC\u0626\u0631 \u06A9\u0631\u06CC\u06BA');
  String get tooltipClearSearch => _t('Clear search', '\u0645\u0633\u062D \u0627\u0644\u0628\u062D\u062B', '\u062A\u0644\u0627\u0634 \u0635\u0627\u0641 \u06A9\u0631\u06CC\u06BA');
  String get tooltipDeleteConversation => _t('Delete conversation', '\u062D\u0630\u0641 \u0627\u0644\u0645\u062D\u0627\u062F\u062B\u0629', '\u06AF\u0641\u062A\u06AF\u0648 \u062D\u0630\u0641 \u06A9\u0631\u06CC\u06BA');
  String get tooltipReadingSettings => _t('Reading settings', '\u0625\u0639\u062F\u0627\u062F\u0627\u062A \u0627\u0644\u0642\u0631\u0627\u0621\u0629', '\u0645\u0637\u0627\u0644\u0639\u06D2 \u06A9\u06CC \u062A\u0631\u062A\u06CC\u0628\u0627\u062A');
  String get tooltipPrevHadith => _t('Previous hadith', '\u0627\u0644\u062D\u062F\u064A\u062B \u0627\u0644\u0633\u0627\u0628\u0642', '\u067E\u0686\u06BE\u0644\u06CC \u062D\u062F\u06CC\u062B');
  String get tooltipNextHadith => _t('Next hadith', '\u0627\u0644\u062D\u062F\u064A\u062B \u0627\u0644\u062A\u0627\u0644\u064A', '\u0627\u06AF\u0644\u06CC \u062D\u062F\u06CC\u062B');
  String get tooltipTextSizeLanguage => _t('Text size & language', '\u062D\u062C\u0645 \u0627\u0644\u0646\u0635 \u0648\u0627\u0644\u0644\u063A\u0629', '\u0645\u062A\u0646 \u06A9\u0627 \u062D\u062C\u0645 \u0627\u0648\u0631 \u0632\u0628\u0627\u0646');
  String get tooltipCopyQiblaInfo => _t('Copy qibla info', '\u0627\u0646\u0633\u062E \u0645\u0639\u0644\u0648\u0645\u0627\u062A \u0627\u0644\u0642\u0628\u0644\u0629', '\u0642\u0628\u0644\u06C1 \u0645\u0639\u0644\u0648\u0645\u0627\u062A \u0646\u0642\u0644 \u06A9\u0631\u06CC\u06BA');
  String get tooltipRefreshLocation => _t('Refresh location', '\u062A\u062D\u062F\u064A\u062B \u0627\u0644\u0645\u0648\u0642\u0639', '\u0645\u0642\u0627\u0645 \u062A\u0627\u0632\u06C1 \u06A9\u0631\u06CC\u06BA');
  String get tooltipCopyCoordinates => _t('Copy coordinates', '\u0627\u0646\u0633\u062E \u0627\u0644\u0625\u062D\u062F\u0627\u062B\u064A\u0627\u062A', '\u06A9\u0648\u0622\u0631\u0688\u06CC\u0646\u06CC\u0679\u0633 \u0646\u0642\u0644 \u06A9\u0631\u06CC\u06BA');
  String get tooltipNextPage => _t('Next page (right-to-left)', '\u0627\u0644\u0635\u0641\u062D\u0629 \u0627\u0644\u062A\u0627\u0644\u064A\u0629 (\u0645\u0646 \u0627\u0644\u064A\u0645\u064A\u0646 \u0625\u0644\u0649 \u0627\u0644\u064A\u0633\u0627\u0631)', '\u0627\u06AF\u0644\u0627 \u0635\u0641\u062D\u06C1 (\u062F\u0627\u0626\u06CC\u06BA \u0633\u06D2 \u0628\u0627\u0626\u06CC\u06BA)');
  String get tooltipPrevPage => _t('Previous page (right-to-left)', '\u0627\u0644\u0635\u0641\u062D\u0629 \u0627\u0644\u0633\u0627\u0628\u0642\u0629 (\u0645\u0646 \u0627\u0644\u064A\u0645\u064A\u0646 \u0625\u0644\u0649 \u0627\u0644\u064A\u0633\u0627\u0631)', '\u067E\u0686\u06BE\u0644\u0627 \u0635\u0641\u062D\u06C1 (\u062F\u0627\u0626\u06CC\u06BA \u0633\u06D2 \u0628\u0627\u0626\u06CC\u06BA)');
  String get tooltipSearchQuran => _t('Search the Quran', '\u0627\u0628\u062D\u062B \u0641\u064A \u0627\u0644\u0642\u0631\u0622\u0646', '\u0642\u0631\u0622\u0646 \u0645\u06CC\u06BA \u062A\u0644\u0627\u0634 \u06A9\u0631\u06CC\u06BA');
  String get tooltipPrevAyah => _t('Previous ayah', '\u0627\u0644\u0622\u064A\u0629 \u0627\u0644\u0633\u0627\u0628\u0642\u0629', '\u067E\u0686\u06BE\u0644\u06CC \u0622\u06CC\u062A');
  String get tooltipNextAyah => _t('Next ayah', '\u0627\u0644\u0622\u064A\u0629 \u0627\u0644\u062A\u0627\u0644\u064A\u0629', '\u0627\u06AF\u0644\u06CC \u0622\u06CC\u062A');
  String get tooltipPlay => _t('Play', '\u062A\u0634\u063A\u064A\u0644', '\u0686\u0644\u0627\u0626\u06CC\u06BA');
  String get tooltipPause => _t('Pause', '\u0625\u064A\u0642\u0627\u0641 \u0645\u0624\u0642\u062A', '\u0631\u0645\u0632\u0627\u064B \u0631\u0648\u06A9\u06CC\u06BA');
  String get tooltipStop => _t('Stop', '\u0625\u064A\u0642\u0627\u0641', '\u0631\u0648\u06A9\u06CC\u06BA');
  String get tooltipPauseRecitation => _t('Pause recitation', '\u0625\u064A\u0642\u0627\u0641 \u0627\u0644\u062A\u0644\u0627\u0648\u0629 \u0645\u0624\u0642\u062A\u064B\u0627', '\u062A\u0644\u0627\u0648\u062A \u0631\u0645\u0632\u0627\u064B \u0631\u0648\u06A9\u06CC\u06BA');
  String get tooltipResumeRecitation => _t('Resume / retry recitation', '\u0627\u0633\u062A\u0626\u0646\u0627\u0641 \u0627\u0644\u062A\u0644\u0627\u0648\u0629 \u0623\u0648 \u0625\u0639\u0627\u062F\u0629 \u0627\u0644\u0645\u062D\u0627\u0648\u0644\u0629', '\u062A\u0644\u0627\u0648\u062A \u062C\u0627\u0631\u06CC \u0631\u06A9\u06BE\u06CC\u06BA \u06CC\u0627 \u062F\u0648\u0628\u0627\u0631\u06C1 \u06A9\u0648\u0634\u0634');
  String get tooltipPlaySurah => _t('Play surah (auto-advances through the ayahs)', '\u062A\u0634\u063A\u064A\u0644 \u0627\u0644\u0633\u0648\u0631\u0629 (\u062A\u0642\u062F\u0645 \u062A\u0644\u0642\u0627\u0626\u064A \u0628\u064A\u0646 \u0627\u0644\u0622\u064A\u0627\u062A)', '\u0633\u0648\u0631\u06C3 \u0686\u0644\u0627\u0626\u06CC\u06BA (\u0622\u06CC\u0627\u062A \u06A9\u06D2 \u062F\u0631\u0645\u06CC\u0627\u0646 \u062E\u0648\u062F\u06A9\u0627\u0631 \u067E\u06CC\u0634 \u0631\u0641\u062A)');
  String get tooltipBuffering => _t('Buffering\u2026', '\u062C\u0627\u0631\u064D \u0627\u0644\u062A\u062D\u0645\u064A\u0644\u2026', '\u0628\u0641\u0631\u0646\u06AF \u06C1\u0648 \u0631\u06C1\u0627 \u06C1\u06D2\u2026');
  String get tooltipResume => _t('Resume', '\u0627\u0633\u062A\u0626\u0646\u0627\u0641', '\u062F\u0648\u0628\u0627\u0631\u06C1 \u0634\u0631\u0648\u0639');
  String get tooltipAutoSpeakOn => _t('Auto speak on', '\u0627\u0644\u0646\u0637\u0642 \u0627\u0644\u062A\u0644\u0642\u0627\u0626\u064A \u0645\u0641\u0639\u0651\u0644', '\u062E\u0648\u062F\u06A9\u0627\u0631 \u0628\u0648\u0644\u0646\u0627 \u0622\u0646');
  String get tooltipAutoSpeakOff => _t('Auto speak off', '\u0627\u0644\u0646\u0637\u0642 \u0627\u0644\u062A\u0644\u0642\u0627\u0626\u064A \u0645\u0639\u0637\u0651\u0644', '\u062E\u0648\u062F\u06A9\u0627\u0631 \u0628\u0648\u0644\u0646\u0627 \u0622\u0641');
  String get tooltipOpenInReader => _t('Open in the reader', '\u0641\u062A\u062D \u0641\u064A \u0627\u0644\u0642\u0627\u0631\u0626', '\u0642\u0627\u0631\u06CC \u0645\u06CC\u06BA \u06A9\u06BE\u0648\u0644\u06CC\u06BA');
  String get tooltipShowPassword => _t('Show password', '\u0625\u0638\u0647\u0627\u0631 \u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631', '\u067E\u0627\u0633 \u0648\u0631\u0688 \u062F\u06A9\u06BE\u0627\u0626\u06CC\u06BA');
  String get tooltipHidePassword => _t('Hide password', '\u0625\u062E\u0641\u0627\u0621 \u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631', '\u067E\u0627\u0633 \u0648\u0631\u0688 \u0686\u06BE\u067E\u0627\u0626\u06CC\u06BA');
  String get tooltipFavorite => _t('Add to favorites', '\u0625\u0636\u0627\u0641\u0629 \u0625\u0644\u0649 \u0627\u0644\u0645\u0641\u0636\u0644\u0629', '\u067E\u0633\u0646\u062F\u06CC\u062F\u06C1 \u0645\u06CC\u06BA \u0634\u0627\u0645\u0644 \u06A9\u0631\u06CC\u06BA');
  String get tooltipUnfavorite => _t('Remove from favorites', '\u0625\u0632\u0627\u0644\u0629 \u0645\u0646 \u0627\u0644\u0645\u0641\u0636\u0644\u0629', '\u067E\u0633\u0646\u062F\u06CC\u062F\u06C1 \u0633\u06D2 \u0646\u06A9\u0627\u0644\u06CC\u06BA');
  String get tooltipPrevMonth => _t('Previous month', '\u0627\u0644\u0634\u0647\u0631 \u0627\u0644\u0633\u0627\u0628\u0642', '\u067E\u0686\u06BE\u0644\u0627 \u0645\u06C1\u06CC\u0646\u06C1');
  String get tooltipNextMonth => _t('Next month', '\u0627\u0644\u0634\u0647\u0631 \u0627\u0644\u062A\u0627\u0644\u064A', '\u0627\u06AF\u0644\u0627 \u0645\u06C1\u06CC\u0646\u06C1');
  String get tooltipStatistics => _t('Statistics', '\u0627\u0644\u0625\u062D\u0635\u0627\u0626\u064A\u0627\u062A', '\u0634\u0645\u0627\u0631\u06CC\u0627\u062A');
  String get tooltipRefreshMosques => _t('Refresh nearby mosques', '\u062A\u062D\u062F\u064A\u062B \u0627\u0644\u0645\u0633\u0627\u062C\u062F \u0627\u0644\u0642\u0631\u064A\u0628\u0629', '\u0642\u0631\u06CC\u0628\u06CC \u0645\u0633\u062C\u062F\u06CC\u06BA \u062A\u0627\u0632\u06C1 \u06A9\u0631\u06CC\u06BA');
  String get a11yWordPlayHint => _t('double-tap to play from this word', '\u0627\u0646\u0642\u0631 \u0645\u0631\u062A\u064A\u0646 \u0644\u0644\u062A\u0634\u063A\u064A\u0644 \u0645\u0646 \u0647\u0630\u0647 \u0627\u0644\u0643\u0644\u0645\u0629', '\u0627\u0633 \u0644\u0641\u0638 \u0633\u06D2 \u0686\u0644\u0627\u0646\u06D2 \u06A9\u06D2 \u0644\u06CC\u06D2 \u0688\u0628\u0644 \u0679\u06CC\u067E \u06A9\u0631\u06CC\u06BA');
  String get a11yWordMeaningHint => _t('long-press for word meaning', '\u0627\u0636\u063A\u0637 \u0637\u0648\u064A\u0644\u0627\u064B \u0644\u0645\u0639\u0646\u0649 \u0627\u0644\u0643\u0644\u0645\u0629', '\u0644\u0641\u0638 \u06A9\u06D2 \u0645\u0639\u0646\u06CC \u06A9\u06D2 \u0644\u06CC\u06D2 \u062F\u06CC\u0631 \u062A\u06A9 \u062F\u0628\u0627\u0626\u06CC\u06BA');
  // Pass P3 (TQ-217 gap disclosure)
  String get quranTqGapNote => _t(
      'Surah 7 & 100 are not in the upstream edition.',
      '\u0633\u0648\u0631\u062A\u0627 \u0667 \u0648\u0661\u0660\u0660 \u0644\u064A\u0633\u062A\u0627 \u0636\u0645\u0646 \u0627\u0644\u0646\u0633\u062E\u0629 \u0627\u0644\u0623\u0635\u0644\u064A\u0629 \u0627\u0644\u0645\u0639\u062A\u0645\u062F\u0629 \u0644\u0647\u0630\u0647 \u0627\u0644\u062A\u0631\u062C\u0645\u0629.',
      '\u0627\u0633 \u062A\u0631\u062C\u0645\u06C1 \u06A9\u06CC \u0627\u0635\u0644 \u062C\u0644\u062F \u0645\u06CC\u06BA \u0633\u0648\u0631\u06C3 \u0667 \u0627\u0648\u0631 \u0661\u0660 \u062F\u0633\u062A\u06CC\u0627\u0628 \u0646\u06C1\u06CC\u06BA\u06D4');
  String get scopeTranslations => _t('Translations', 'الترجمات', 'تراجم');
  String get scopeArabic => _t('Arabic', 'العربية', 'عربی');
  String get scopeAll => _t('All', 'الكل', 'سب کچھ');

  // ── Pass Q3: word-touch & explain ──
  String get listenWordByWord => _t(
        'Listen word-by-word',
        'الاستماع كلمة بكلمة',
        'لفظ بہ لفظ سنیں');
  String get listenWordByWordHint => _t(
        'When on, tapping a word plays the recitation from that word.',
        'عند التشغيل، تؤدي اللمسة على أي كلمة إلى تشغيل التلاوة من تلك الكلمة.',
        'آن ہونے پر کسی لفظ کو چھونے سے تلاوت اُسی لفظ سے شروع ہو جاتی ہے۔');
  String get wordTimingsNotAvailable => _t(
        'word timings not available for this reciter — playing from '
        'ayah start',
        'توقيتات الكلمات غير متوفرة لهذا القارئ — تُشغَّل التلاوة من '
        'بداية الآية',
        'اس قاری کے لیے الفاظ کا وقت دستیاب نہیں — تلاوت آیہ کے آغاز '
        'سے شروع ہو رہی ہے');
  String get playFromThisWord => _t(
        'Play from this word',
        'شغّل من هذه الكلمة',
        'اس لفظ سے سنیں');
  String wordAppearsNTimes(int n) => _t(
        'Appears $n times in the Quran',
        'يتكرر $n مرة في القرآن',
        'قرآن میں $n بار آیا');
  String get wordGlossUnavailable => _t(
        'No gloss bundled for this word',
        'لا يتوفر شرح هذه الكلمة في النسخة المضمّنة',
        'اس لفظ کا ترجمہ بنڈل میں شامل نہیں');
  String get wordRootDataNotBundled => _t(
        'Root morphology is not bundled in this build',
        'تحليل الجذور غير مضمّن في هذا الإصدار',
        'روٹ کا تجزیہ اس بلڈ میں شامل نہیں');
  String get openTafseer => _t(
        'Open Tafseer',
        'افتح التفسير',
        'تفسیر کھولیں');
  String get askAiAboutWord => _t(
        'Ask AI about this word',
        'اسأل الذكاء الاصطناعي عن هذه الكلمة',
        'اس لفظ کے بارے میں AI سے پوچھیں');

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
