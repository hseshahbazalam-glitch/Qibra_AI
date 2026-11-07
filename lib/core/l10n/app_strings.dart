// Hand-written strings for en / ar / ur. Do not enable gen-l10n.

import 'package:flutter/widgets.dart';

import 'package:qibra_ai/core/constants/app_constants.dart';

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
  String get romanUrduUnavailable => _t(
        'Roman Urdu text is not bundled for this ayah.',
        'النص الأوردوي اللاتيني غير مضمّن لهذه الآية.',
        'اس آیت کا رومن اردو متن بلڈ میں شامل نہیں۔',
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
  // Pass E (label truth): what the reader tab shows is the Maududi
  // Roman Urdu TRANSLATION (112:1 = "Kaho woh Allah hai, Yakta") —
  // roman-script Urdu, not a letter-for-letter transliteration. The
  // name now matches the data; the prefs key and field stay
  // show_transliteration for user-persistence continuity.
  String get showTransliteration => _t(
        'Show Roman Urdu',
        'إظهار الأوردو بالحروف اللاتينية',
        'رومن اردو دکھائیں',
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
  // Pass M (mushaf ribbon)
  String get mushafRibbonA11y => _t(
      'Ribbon bookmark. Tap to return to your last read page; drag down to mark this page.',
      '\u0634\u0631\u064A\u0637 \u0627\u0644\u0642\u0631\u0627\u0621\u0629. \u0627\u0646\u0642\u0631 \u0644\u0644\u0639\u0648\u062F\u0629 \u0625\u0644\u0649 \u0622\u062E\u0631 \u0635\u0641\u062D\u0629 \u0642\u0631\u0623\u062A\u0647\u0627\u061B \u0627\u0633\u062D\u0628\u0647 \u0644\u0623\u0633\u0641\u0644 \u0644\u062A\u0639\u0644\u064A\u0645 \u0647\u0630\u0647 \u0627\u0644\u0635\u0641\u062D\u0629.',
      '\u0631\u0628\u0646 \u0646\u0634\u0627\u0646\u06D4 \u0622\u062E\u0631 \u067E\u0691\u06BE\u06D2 \u06AF\u0626\u06D2 \u0635\u0641\u062D\u06D2 \u067E\u0631 \u0648\u0627\u067E\u0633 \u062C\u0627\u0646\u06D2 \u06A9\u06D2 \u0644\u06CC\u06D2 \u0679\u06CC\u067E \u06A9\u0631\u06CC\u06BA\u061B \u06CC\u06C1 \u0635\u0641\u062D\u06C1 \u0646\u0634\u0627\u0646\u062F\u06C1\u06CC \u06A9\u0631\u0646\u06D2 \u06A9\u06D2 \u0644\u06CC\u06D2 \u0646\u06CC\u0686\u06D2 \u06A9\u06BE\u06CC\u0646\u0686\u06CC\u06BA\u06D4');
  String get mushafRibbonDropHint => _t(
      'Release to mark this page as your progress',
      '\u062D\u0631\u0650\u0651\u0631 \u0644\u062A\u062D\u062F\u064A\u062F \u0647\u0630\u0647 \u0627\u0644\u0635\u0641\u062D\u0629 \u0643\u0622\u062E\u0631 \u0642\u0631\u0627\u0621\u0629',
      '\u0627\u0633 \u0635\u0641\u062D\u06D2 \u06A9\u0648 \u0627\u067E\u0646\u06CC \u067E\u06CC\u0634 \u0631\u0641\u062A \u06A9\u06D2 \u0637\u0648\u0631 \u067E\u0631 \u0645\u062D\u0641\u0648\u0638 \u06A9\u0631\u0646\u06D2 \u06A9\u06D2 \u0644\u06CC\u06D2 \u0631\u0628\u0646 \u0686\u06BE\u0648\u0691\u06CC\u06BA');
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

  // ════════════════════════════════════════════════════════════
  // ── Pass i18n A2: body-strings truth — HOME chrome ──
  // Section headers, status cards, hero copy. English values are
  // the byte-identical strings the screens shipped before this pass.
  // ════════════════════════════════════════════════════════════
  String get sectionToday => _t('Today', 'اليوم', 'آج');
  String get sectionYourProgress => _t('Your progress', 'تقدّمك', 'آپ کی پیش رفت');
  String get sectionQuickActions => _t('Quick actions', 'إجراءات سريعة', 'فوری اقدامات');
  String get actionDetails => _t('Details', 'التفاصيل', 'تفصیل');
  String get locationNotSet => _t('Location not set', 'لم يتم تحديد الموقع', 'مقام مقرر نہیں');
  String get prayerTimesUnavailable => _t(
      'Prayer times unavailable',
      'أوقات الصلاة غير متوفرة',
      'نماز کے اوقات دستیاب نہیں');
  String get timesAppearAfterLocation => _t(
      'Times appear after a location is set.',
      'تظهر الأوقات بعد تحديد الموقع.',
      'مقام مقرر کرنے کے بعد اوقات نظر آئیں گے۔');
  String get ayahUnavailable => _t('Ayah unavailable', 'الآية غير متوفرة', 'آیت دستیاب نہیں');
  String get dailyAyahLoadingNote => _t(
      'The daily ayah will appear when offline files finish loading.',
      'ستظهر آية اليوم عند اكتمال تحميل الملفات دون الاتصال.',
      'آف لائن فائلوں کا لوڈ مکمل ہونے پر روزانہ کی آیت نظر آئے گی۔');
  String get hadithUnavailable => _t('Hadith unavailable', 'الحديث غير متوفر', 'حدیث دستیاب نہیں');
  String get cachedCollectionsLoading => _t(
      'Cached collections will appear when they finish loading.',
      'ستظهر المجموعات المخزّنة عند اكتمال تحميلها.',
      'محفوظ شدہ مجموعے لوڈ مکمل ہونے پر نظر آئیں گے۔');
  String get toolQibla => _t('Qibla', 'القبلة', 'قبلہ');
  String get toolTasbih => _t('Tasbih', 'المسبحة', 'تسبیح');
  String get toolDuas => _t('Duas', 'الأدعية', 'دعائیں');
  String get toolCalendar => _t('Calendar', 'التقويم', 'کیلنڈر');
  String get greetingPeacefulNight => _t('Peaceful night', 'ليلة هانئة', 'پُرسک رات');
  String get greetingGoodMorning => _t('Good morning', 'صباح الخير', 'صبح بخیر');
  String get greetingGoodAfternoon => _t('Good afternoon', 'طاب يومك', 'دوپہر بخیر');
  String get greetingGoodEvening => _t('Good evening', 'مساء الخير', 'شام بخیر');
  String get assalamuAlaikum => _t('Assalamu Alaikum', 'السلام عليكم', 'السلام علیکم');
  String get adhanAlertsOn => _t('Adhan alerts on', 'تنبيهات الأذان مفعّلة', 'اذان کی اطلاعات آن');
  String get alertsOff => _t('Alerts off', 'التنبيهات متوقفة', 'اطلاعات بند');
  String get nextPrayer => _t('Next prayer', 'الصلاة القادمة', 'اگلی نماز');
  String get nextPrayerCaps => _t('NEXT PRAYER', 'الصلاة القادمة', 'اگلی نماز');
  String get prayerTimesUnavailableNow => _t(
      'Prayer times are unavailable right now.',
      'أوقات الصلاة غير متوفرة الآن.',
      'نماز کے اوقات فی الحال دستیاب نہیں۔');
  String get setLocationToSeeTimes => _t(
      'Set your location to see prayer times.',
      'حدّد موقعك لعرض أوقات الصلاة.',
      'نماز کے اوقات دیکھنے کے لیے اپنا مقام مقرر کریں۔');
  String get tapForFullSchedule => _t(
      'Tap for full prayer schedule',
      'انقر لعرض جدول الصلاة الكامل',
      'مکمل نماز شیڈول کے لیے ٹیپ کریں');
  String get countdownLeft => _t('left', 'متبقٍ', 'باقی');
  String nowWindow(String n) => _t('· now $n', '· الآن $n', '· ابھی $n');
  String get startReading => _t('Start reading', 'ابدأ القراءة', 'مطالعہ شروع کریں');
  String get continueQuran => _t(
      'Continue Quran',
      'متابعة قراءة القرآن',
      'قرآنِ کریم کی تلاوت جاری رکھیں');
  String get alFatihahOpening => _t('Al-Fatihah — the Opening', 'الفاتحة — الافتتاح', 'الفاتحہ — آغاز');
  String get everyAyahVerifiedSources => _t(
      'Every ayah with verified sources',
      'كل آية بمصادر موثّقة',
      'ہر آیت مستند ذرائع کے ساتھ');
  String juzPageAyah(int j, int p, int a) => _t(
      'Juz $j · Page $p · Ayah $a',
      'الجزء $j · صفحة $p · آية $a',
      'پارہ $j · صفحہ $p · آیت $a');
  String get surah1Juz1 => _t('Surah 1 · Juz 1', 'سورة 1 · جزء 1', 'سورۃ 1 · پارہ 1');
  String ofTheQuran(int pct) => _t('$pct% of the Quran', '$pct% من القرآن', 'قرآن کا $pct%');
  String get findASurah => _t('Find a surah', 'ابحث عن سورة', 'سورۃ تلاش کریں');
  String get askQibra => _t('Ask QIBRA', 'اسأل QIBRA', 'QIBRA سے پوچھیں');
  String get askQibraTagline => _t(
      'Quran & Hadith answers with sources.',
      'إجابات من القرآن والحديث مع المصادر.',
      'قرآن و حدیث کے جوابات ذرائع کے ساتھ۔');
  String get retrievalOnlyBadge => _t(
      'Retrieval only — not a fatwa',
      'استرجاع للمصادر فقط — ليست فتوى',
      'صرف حوالہ جات — فتویٰ نہیں');
  String get askLabel => _t('Ask', 'اسأل', 'پوچھیں');
  String get dailyAyahUnavailable => _t(
      'Daily ayah unavailable',
      'آية اليوم غير متوفرة',
      'روزانہ کی آیت دستیاب نہیں');
  String get offlineQuranLoading => _t(
      'Offline Quran files are still loading.',
      'لا تزال ملفات القرآن دون الاتصال تُحمَّل.',
      'قرآن کی آف لائن فائلیں ابھی لوڈ ہو رہی ہیں۔');
  String get ayahOfDayBadge => _t('AYAH OF THE DAY', 'آية اليوم', 'آیتِ روزانہ');
  String get dailyHadithUnavailable => _t(
      'Daily hadith unavailable',
      'حديث اليوم غير متوفر',
      'روزانہ کی حدیث دستیاب نہیں');
  String get hadithOfDayBadge => _t('HADITH OF THE DAY', 'حديث اليوم', 'حدیثِ روزانہ');
  String get aDuaForToday => _t('A DUA FOR TODAY', 'دعاء اليوم', 'دعا آج کے لیے');
  String gradeLabel(String g) => _t('Grade: $g', 'الدرجة: $g', 'درجہ: $g');
  String gradeLabelFull(String g, String d) => _t('Grade: $g · $d', 'الدرجة: $g · $d', 'درجہ: $g · $d');
  String get readingStreak => _t('Reading streak', 'سلسلة القراءة', 'مطالعے کا سلسلہ');
  String get readTodayStartStreak => _t(
      'Read today to start a streak',
      'اقرأ اليوم لبدء سلسلة',
      'سلسلہ شروع کرنے کے لیے آج پڑھیں');
  String get pagesToday => _t('pages today', 'صفحات اليوم', 'صفحے آج');
  String get prayerStreak => _t('Prayer streak', 'سلسلة الصلاة', 'نماز کا سلسلہ');
  String get trackPrayersInPrayer => _t(
      'Track prayers in Prayer',
      'تتبّع الصلوات في قسم الصلاة',
      'نمازیں نماز سیکشن میں درج کریں');
  String get dailyGoal => _t('Daily goal', 'الهدف اليومي', 'روزانہ ہدف');
  String get dailyGoalMet => _t('Daily goal met', 'تحقق الهدف اليومي', 'روزانہ ہدف پورا ہوا');
  String get unitDayLower => _t('day', 'يوم', 'دن');
  String get unitDaysLower => _t('days', 'أيام', 'دن');

  // ════════════════════════════════════════════════════════════
  // ── Pass i18n A2: body-strings truth — PRAYER family ──
  // Times screen incl. the full why-sheet, schedule, statistics,
  // tahajjud details. School/organization names stay Latin by the
  // pass decision (proper nouns), everything around them is native.
  // ════════════════════════════════════════════════════════════
  String get pillNextCaps => _t('NEXT', 'قادمة', 'اگلی');
  String get pillNext => _t('Next', 'قادمة', 'اگلی');
  String get pillNow => _t('Now', 'الآن', 'ابھی');
  String get todaysTimes => _t('Today\'s times', 'أوقات اليوم', 'آج کے اوقات');
  String get timesUnavailable => _t('Times unavailable', 'الأوقات غير متوفرة', 'اوقات دستیاب نہیں');
  String get prayerTimesAppearAfterLocation => _t(
      'Prayer times appear after a location is set.',
      'تظهر أوقات الصلاة بعد تحديد الموقع.',
      'مقام مقرر کرنے کے بعد نماز کے اوقات نظر آئیں گے۔');
  String get adhanNotificationsTitle => _t('Adhan notifications', 'تنبيهات الأذان', 'اذان کی اطلاعات');
  String get azanAlertsOn => _t(
      'Azan alerts are on',
      'تنبيهات الأذان مفعّلة',
      'اذان کی اطلاعات آن ہیں');
  String get azanAlertsOff => _t(
      'Azan alerts are off',
      'تنبيهات الأذان متوقفة',
      'اذان کی اطلاعات بند ہیں');
  String get whyTimeDifferent => _t('Why is my prayer time different?', 'لماذا يختلف وقت صلاتي؟',
          'میری نماز کا وقت کیوں مختلف ہے؟');
  String get whyTimeDifferentHint => _t(
      'Method, Asr, high latitude and adjustments — see exactly what this app used today.',
      'الطريقة، العصر، خطوط العرض العالية والتعديلات — انظر بالضبط ما اعتمده التطبيق اليوم.',
      'طریقہ، عصر، بلند خطوطِ عرض اور ایڈجسٹمنٹس — دیکھیں آج ایپ نے بالکل کیا اپنایا۔');
  String get alsoInPrayer => _t('Also in Prayer', 'أيضًا في الصلاة', 'نماز میں مزید');
  String get scheduleLabel => _t('Schedule', 'الجدول', 'شیڈول');
  String get statisticsLabel => _t('Statistics', 'الإحصائيات', 'شماریات');
  String get tahajjudLabel => _t('Tahajjud', 'التهجد', 'تہجد');
  String get mosquesLabel => _t('Mosques', 'المساجد', 'مسجدیں');
  String get calculationMethodLower => _t('Calculation method', 'طريقة الحساب', 'حساب کا طریقہ');
  String get laterAsrSubtitle => _t(
      'Later Asr time (shadow ratio 2 instead of 1)',
      'وقت متأخر للعصر (نسبة الظل 2 بدل 1)',
      'عصر کا دیر سے وقت (سائے کا تناسب 1 کے بجائے 2)');
  String get asrMadhabSetting => _t('Asr (madhab) setting', 'إعداد مذهب العصر', 'عصر کے مذہب کی ترتیب');
  String get whyAsrHanafi => _t(
      'Hanafi — shadow ratio 2, so Asr is later.',
      'الحنفي — نسبة الظل 2، لذا العصر متأخر.',
      'حنفی — سائے کا تناسب 2، لہذا عصر دیر سے ہوتی ہے۔');
  String get whyAsrStandard => _t(
      'Standard (Shafi\u2019i/Maliki/Hanbali) — shadow ratio 1.',
      'القياسي (الشافعي/المالكي/الحنبلي) — نسبة الظل 1.',
      'معیاری (شافعی/مالکی/حنبلی) — سائے کا تناسب 1۔');
  String get highLatitudeRule => _t(
      'High-latitude rule', 'قاعدة خطوط العرض العالية', 'بلند خطوطِ عرض کا اصول');
  String whyHighLatitudeBody(String ruleName) => _t(
      'Rule applied when the sun never reaches the Fajr/Isha angle: $ruleName (none means no correction is applied).',
      'تُطبَّق عندما لا تبلغ الشمس زاوية الفجر/العشاء: $ruleName (بلا يعني عدم تصحيح الأوقات).',
      'جب سورج فجر/عشاء کے زاویے تک نہ پہنچے تو یہ اصول: $ruleName (کوئی نہ ہونے کا مطلب کوئی اصلاح نہیں)۔');
  String get manualAdjustments => _t('Manual adjustments', 'تعديلات يدوية', 'دستی ایڈجسٹمنٹس');
  String get adjustmentsNone => _t(
      'None — times shown are pure calculated values.',
      'لا شيء — الأوقات المعروضة قيم محسوبة تمامًا.',
      'کوئی نہیں — دکھائے گئے اوقات محض حسابی اقدار ہیں۔');
  String get whyTimezoneTitle => _t('Timezone', 'المنطقة الزمنية', 'ٹائم زون');
  String timezoneResolvedBody(String tz) => _t(
      'Times use $tz resolved from your location (daylight-saving handled by the timezone database).',
      'الأوقات بحسب $tz من موقعك (يُدار التوقيت الصيفي عبر قاعدة بيانات المناطق الزمنية).',
      'اوقات آپ کے مقام سے طے شدہ $tz کے مطابق ہیں (گرمائی وقت کا انتظام ٹائم زون ڈیٹابیس کرتا ہے)۔');
  String get timezoneDeviceFallback => _t(
      'Device timezone (no city timezone resolved).',
      'منطقة الجهاز الزمنية (لم تُحدَّد منطقة مدينة).',
      'ڈیوائس کا ٹائم زون (شہر کا ٹائم زون طے نہیں ہوا)۔');
  String get whyMosqueNote => _t(
      'Mosque calendars round times and follow local ijtihad, so a minute or two of difference is normal. For your local jamaat schedule, ask your mosque.',
      'تقويمات المساجد تقرّب الأوقات وتعمل بالاجتهاد المحلي، فلذلك فرق دقيقة أو دقيقتين أمر طبيعي. لجدول الجماعات عندكم، اسألوا مسجدكم.',
      'مسجدیں اوقات کو گرداتی ہیں اور مقامی اجتہاد پر چلتی ہیں، لہذا ایک دو منٹ کا فرق معمول ہے۔ اپنے مقامی جماعت کے شیڈول کے لیے اپنے مسجد سے پوچھیں۔');
  String whyMethodBody(String methodName, String fajrAngle, String ishaPart) => _t(
      '$methodName — Fajr angle $fajrAngle°, Isha $ishaPart.',
      '$methodName — زاوية الفجر $fajrAngle°، العشاء $ishaPart.',
      '$methodName — فجر کا زاویہ $fajrAngle°، عشاء $ishaPart۔');
  String whyIshaInterval(int minutes) => _t('$minutes min after Maghrib', '$minutes دقيقة بعد المغرب',
          'مغرب کے $minutes منٹ بعد');
  String get timesWillAppearOnceCalculated => _t(
      'Times will appear once they can be calculated.',
      'ستظهر الأوقات متى أمكن حسابها.',
      'حساب ممکن ہوتے ہی اوقات نظر آئیں گے۔');
  String get enableLocationForTimes => _t(
      'Enable location to calculate prayer times.',
      'فعّل الموقع لحساب أوقات الصلاة.',
      'نماز کے اوقات کے لیے مقام فعال کریں۔');
  String atTime(String t) => _t('at $t', 'الساعة $t', '$t کو');
  String currentWindow(String name) => _t(
      'Current window: $name', 'الوقت الحالي: $name', 'موجودہ وقت: $name');
  String get standardAsr => _t('Standard Asr', 'العصر المعياري', 'معیاری عصر');
  String get sunriseName => _t('Sunrise', 'الشروق', 'طلوعِ آفتاب');
  String get dhuhrAfterSunrise => _t(
      'Dhuhr begins after sunrise ends',
      'يبدأ الظهر بعد انتهاء الشروق',
      'طلوعِ آفتاب کے ختم ہونے کے بعد ظہر شروع ہوتا ہے');
  String get countdownInPrefix => _t('in ', 'خلال ', 'میں ');
  String get prayerTimesEyebrow => _t('PRAYER TIMES', 'أوقات الصلاة', 'نماز کے اوقات');
  String get salahScheduleTitle => _t('Salah Schedule', 'جدول الصلوات', 'نماز کا شیڈول');
  String methodLine(String name) => _t('Method: $name', 'الطريقة: $name', 'طریقہ: $name');
  String get myLocation => _t('My Location', 'موقعي', 'میرا مقام');
  String get detectingLabel => _t('Detecting…', 'جارٍ الكشف…', 'تلاش ہو رہی ہے…');
  String get notAvailableTapToSet => _t(
      'Not available — tap to set',
      'غير متاح — انقر للتعيين',
      'دستیاب نہیں — مقرر کرنے کے لیے ٹیپ کریں');
  String get todaysSchedule => _t('Today\'s schedule', 'جدول اليوم', 'آج کا شیڈول');
  String get findingLocationForTimes => _t(
      'Finding your location for prayer times…',
      'جارٍ تحديد موقعك لأوقات الصلاة…',
      'نماز کے اوقات کے لیے آپ کا مقام معلوم کیا جا رہا ہے…');
  String get prayerNeedsLocation => _t(
      'Prayer times need a location — permission denied or GPS unavailable. Set one manually or retry.',
      'تحتاج أوقات الصلاة إلى موقع — الإذن مرفوض أو GPS غير متاح. حدّد موقعًا يدويًا أو أعد المحاولة.',
      'نماز کے اوقات کے لیے مقام چاہیے — اجازت رد ہوئی یا GPS دستیاب نہیں۔ خود مقرر کریں یا دوبارہ کوشش کریں۔');
  String get managePrayerNotifications => _t(
      'Manage Prayer Notifications',
      'إدارة تنبيهات الصلاة',
      'نماز کی اطلاعات کا انتظام');
  String get locationSettingsTitle => _t('Location Settings', 'إعدادات الموقع', 'مقام کی ترتیبات');
  String get autoDetectLocation => _t(
      'Auto-detect Location', 'الكشف التلقائي عن الموقع', 'مقام خودکار تلاش کریں');
  String get useGpsToDetect => _t(
      'Use GPS to detect your location',
      'استخدام GPS لتحديد موقعك',
      'مقام معلوم کرنے کے لیے GPS استعمال کریں');
  String get resetToMakkah => _t('Reset to Makkah', 'إعادة التعيين إلى مكة', 'مکہ پر ری سیٹ کریں');
  String get useMakkahDefault => _t(
      'Use Makkah as default location',
      'جعل مكة الموقع الافتراضي',
      'بطورِ معمول مکہ کو مقام بنائیں');
  String get prayerNotificationsTitle => _t('Prayer Notifications', 'تنبيهات الصلاة', 'نماز کی اطلاعات');
  String get toggleAzanPerPrayer => _t(
      'Toggle azan alerts for each prayer',
      'تبديل تنبيهات الأذان لكل صلاة',
      'ہر نماز کے لیے اذان کی اطلاعات بدلیں');
  String get prayerSettingsTitle => _t('Prayer Settings', 'إعدادات الصلاة', 'نماز کی ترتیبات');
  String get hour24FormatTitle => _t('24-Hour Format', 'تنسيق 24 ساعة', '24 گھنٹے کا فارمیٹ');
  String get prayerStatisticsTitle => _t('Prayer Statistics', 'إحصائيات الصلاة', 'نماز کی شماریات');
  String get loadingPrayerLog => _t(
      'Loading your prayer log…',
      'جارٍ تحميل سجل صلواتك…',
      'آپ کے نماز ریکارڈ کا لوڈ جاری ہے…');
  String get prayedLabel => _t('Prayed', 'أُديت', 'پڑھی گئی');
  String get inMosqueLabel => _t('In mosque', 'في المسجد', 'مسجد میں');
  String get periodThisWeek => _t('This Week', 'هذا الأسبوع', 'اس ہفتے');
  String get periodThisMonth => _t('This Month', 'هذا الشهر', 'اس مہینے');
  String get periodAllTime => _t('All Time', 'طوال الوقت', 'کل مدت');
  String get prayerCompletion => _t('Prayer Completion', 'إتمام الصلاة', 'نماز کی تکمیل');
  String get markPrayersHint => _t(
      'Mark prayers on the Prayer tab to see completion here.',
      'سجّل الصلوات في تبويب الصلاة لترى الإتمام هنا.',
      'یہاں تکمیل دیکھنے کے لیے نماز ٹیب میں نمازیں درج کریں۔');
  String recordedPrayedOf(int prayed, int total) => _t(
      '$prayed of $total recorded prayers were marked prayed.',
      'تم تسجيل $prayed من $total صلوات مؤداة.',
      '$total درج شدہ نمازوں میں سے $prayed کی ادائیگی درج ہوئی۔');
  String get prayerStreakCardTitle => _t('Prayer Streak', 'سلسلة الصلاة', 'نماز کا سلسلہ');
  String get unitDayUpper => _t('Day', 'يوم', 'دن');
  String get unitDaysUpper => _t('Days', 'أيام', 'دن');
  String get bestLabel => _t('Best', 'الأفضل', 'بہترین');
  String daysCount(int n) => _t('$n Days', '$n أيام', '$n دن');
  String get last7Days => _t('Last 7 days', 'آخر 7 أيام', 'پچھلے 7 دن');
  String get firstPrayerBadge => _t('First prayer', 'أول صلاة', 'پہلی نماز');
  String get milestonesTitle => _t('Milestones', 'الإنجازات', 'کارنامے');
  String get tahajjudDetailsTitle => _t('Tahajjud Details', 'تفاصيل التهجد', 'تہجد کی تفصیلات');
  String get tahajjudBestTimeNote => _t(
      'The best time for Tahajjud is in the last third of the night.',
      'أفضل وقت للتهجد في الثلث الأخير من الليل.',
      'تہجد کا بہترین وقت رات کا آخری تہائی ہے۔');
  String get recommendedTime => _t('Recommended Time', 'الوقت الموصى به', 'تجویز کردہ وقت');
  String get notAvailableLabel => _t('Not available', 'غير متاح', 'دستیاب نہیں');
  String get alarmLabel => _t('Alarm', 'منبه', 'الارم');
  String get wakeMeForTahajjud => _t('Wake me for Tahajjud', 'أيقظني للتهجد', 'تہجد کے لیے جگائیں');
  String get recommendedSurahs => _t('Recommended Surahs', 'السور الموصى بها', 'تجویز کردہ سورتیں');
  String get recommendedDuas => _t('Recommended Duas', 'الأدعية الموصى بها', 'تجویز کردہ دعائیں');
  String get tahajjudStreak => _t('Tahajjud Streak', 'سلسلة التهجد', 'تہجد کا سلسلہ');
  String get notTrackedLabel => _t('Not tracked', 'غير متتبَّع', 'درج نہیں ہوتا');
  String get setTahajjudAlarm => _t('Set Tahajjud Alarm', 'اضبط منبه التهجد', 'تہجد کا الارم مقرر کریں');
  String get bestTimesForTahajjud => _t('Best Times for Tahajjud', 'أفضل أوقات التهجد', 'تہجد کے بہترین اوقات');
  String get windowsAppearNote => _t(
      'Windows appear after Maghrib and Fajr can be calculated.',
      'تظهر الفترات بعد إمكان حساب المغرب والفجر.',
      'مغرب اور فجر کا حساب ممکن ہونے کے بعد دورے نظر آئیں گے۔');
  String get dividedMaghribToFajr => _t(
      'Divided from today\'s Maghrib to Fajr.',
      'مقسّمة من مغرب اليوم إلى الفجر.',
      'آج کی مغرب سے فجر تک تقسیم۔');
  String get lastThirdOfNight => _t('Last Third of Night', 'الثلث الأخير من الليل', 'رات کا آخری تہائی');
  String get usuallyPreferredWindow => _t(
      'Usually the preferred window',
      'الفترة المفضّلة عادةً',
      'عام طور پر پسندیدہ دور');
  String get middleOfNight => _t('Middle of Night', 'وسط الليل', 'رات کا وسط');
  String get optionalWindow => _t('Optional window', 'فترة اختيارية', 'اختیاری دور');
  String get firstThird => _t('First Third', 'الثلث الأول', 'پہلا تہائی');
  String get suggestedSurahsNote => _t(
      'Suggested surahs for Tahajjud prayer',
      'سور مقترحة لصلاة التهجد',
      'نمازِ تہجد کے لیے تجویز کردہ سورتیں');
  String get tahajjudDuasTitle => _t('Tahajjud Duas', 'أدعية التهجد', 'تہجد کی دعائیں');
  String get tahajjudNotTrackedBody => _t(
      'Tahajjud nights are not tracked in this build. Counts will appear here only after a real record exists.',
      'لا تُتتبَّع ليالي التهجد في هذا الإصدار. لن تظهر الأعداد هنا إلا بعد وجود سجل حقيقي.',
      'اس بلڈ میں تہجد کی راتیں درج نہیں ہوتیں۔ اصل ریکارڈ بننے ہی کے بعد یہاں گنتیاں نظر آئیں گی۔');
  String get currentStreakLabel => _t('Current streak', 'السلسلة الحالية', 'موجودہ سلسلہ');
  String get longestStreakLabel => _t('Longest streak', 'أطول سلسلة', 'طویل ترین سلسلہ');
  String get totalTahajjudLabel => _t('Total Tahajjud', 'إجمالي التهجد', 'کل تہجد');
  String get reminderDialogTitle => _t('Reminder', 'تذكير', 'یاد دہانی');
  String get reminderHonestNote => _t(
      'This toggle is only a reminder on this screen. No device alarm is scheduled.',
      'هذا المفتاح تذكير على هذه الشاشة فقط. لا يُجدول أي منبه على الجهاز.',
      'یہ سوئچ صرف اس اسکرین پر ایک یاد دہانی ہے۔ ڈیوائس پر کوئی الارم طے نہیں ہوتا۔');

  String pageBookmarkedToast(int p) =>
      _t('Page $p bookmarked', 'تمت إشارة صفحة $p', 'صفحہ $p بک مارک ہو گیا');
  String bookmarkRemovedToast(int p) => _t(
      'Bookmark removed from page $p',
      'أُزيلت الإشارة من صفحة $p',
      'صفحہ $p سے بک مارک ہٹا دیا گیا');
  String get tafsirAwaitDataToast => _t(
      'Tafsir is available once the Quran data is loaded',
      'التفسير متاح بعد تحميل بيانات القرآن',
      'تفسیر قرآنی ڈیٹا لوڈ ہونے کے بعد دستیاب ہوگی');
  String get textAwaitDataToast => _t(
      'The text is available once the Quran data is loaded',
      'النص متاح بعد تحميل بيانات القرآن',
      'متن قرآنی ڈیٹا لوڈ ہونے کے بعد دستیاب ہوگا');
  String get pageInfoCopiedToast =>
      _t('Page info copied', 'تم نسخ معلومات الصفحة', 'صفحے کی معلومات کاپی ہوئیں');
  String get pageInfoCopiedShareToast => _t(
      'Page info copied — paste it anywhere to share',
      'تم نسخ معلومات الصفحة — الصقها أينما شئت للمشاركة',
      'صفحے کی معلومات کاپی ہوئیں — شیئر کے لیے کہیں بھی پیسٹ کریں');
  String get goToPageTitle => _t('Go to page', 'الانتقال إلى صفحة', 'صفحے پر جائیں');
  String get enterPageNumberHint => _t(
      'Enter a page number (1 – 604)',
      'أدخل رقم الصفحة (1–604)',
      'صفحے کی نمبر درج کریں (1 – 604)');
  String get invalidPageToast => _t(
      'Enter a valid page (1–604)',
      'أدخل صفحة صحيحة (1–604)',
      'درست صفحہ درج کریں (1–604)');
  String onPageToast(int p) =>
      _t('On page $p', 'أنت في صفحة $p', 'صفحہ $p پر ہیں');
  String progressSavedToast(int p) => _t(
      'Progress saved on page $p',
      'حُفظ التقدم في صفحة $p',
      'پیش رفت صفحہ $p پر محفوظ ہوئی');
  String get noSavedPageToast => _t(
      'No saved page yet — turn a page first',
      'لا توجد صفحة محفوظة بعد — اقلب صفحة أولاً',
      'ابھی کوئی محفوظ صفحہ نہیں — پہلے کوئی صفحہ پلٹیں');
  String get quranTextUnavailableTitle =>
      _t('Quran text unavailable', 'نص القرآن غير متوفر', 'قرآنی متن دستیاب نہیں');
  String get quranTextUnavailableBody => _t(
      'The bundled Quran data could not be read.',
      'تعذّرت قراءة بيانات القرآن المضمّنة.',
      'بنڈل شدہ قرآنی ڈیٹا پڑھا نہیں جا سکا۔');
  String pageOptionsTitle(int p) =>
      _t('Page $p options', 'خيارات صفحة $p', 'صفحہ $p کے اختیارات');
  String get copyPageInfoLabel =>
      _t('Copy page info', 'نسخ معلومات الصفحة', 'صفحہ معلومات کاپی کریں');
  String get sharePageLabel => _t('Share page', 'مشاركة الصفحة', 'صفحہ شیئر کریں');
  String get viewAllBookmarksLabel => _t(
      'View all bookmarks', 'عرض كل الإشارات', 'تمام بک مارکس دیکھیں');
  String get noBookmarksToast => _t(
      'No bookmarks yet — long-press the bookmark to save one',
      'لا توجد إشارات بعد — اضغط طويلاً على الحفظ للتسجيل',
      'ابھی کوئی بک مارک نہیں — محفوظ کرنے کے لیے بک مارک دیر تک دبائیں');
  String get bookmarkedPagesTitle =>
      _t('Bookmarked pages', 'الصفحات المعلّمة', 'بک مارک شدہ صفحات');
  String bookmarkPageEntry(int p) => _t('Page $p', 'صفحة $p', 'صفحہ $p');
  String get toolTafsir => _t('Tafsir', 'التفسير', 'تفسیر');
  String get translateLabel => _t('Translate', 'الترجمة', 'ترجمہ');
  String get goToShort => _t('Go to', 'انتقال', 'جائیں');
  String pagesCountLabel(int n) =>
      _t('$n pages', '$n صفحة', '$n صفحات');
  String get missedLabel => _t('Missed', 'فائت', 'چھوٹی ہوئی');

  // ════════════════════════════════════════════════════════════
  // ── Pass i18n A2: body-strings truth — CALENDAR + MUSHAF ──
  // Event cards compose their hijri-date line from day + month
  // word via hijriMonthName; no hardcoded English month lists
  // survive in the screens.
  // ════════════════════════════════════════════════════════════
  String get islamicCalendarTitle => _t('Islamic Calendar', 'التقويم الإسلامي', 'اسلامی کیلنڈر');
  String get hijriCalendarEyebrow => _t('HIJRI CALENDAR', 'التقويم الهجري', 'ہجری کیلنڈر');
  String get islamicEventsEyebrow => _t('ISLAMIC EVENTS', 'المناسبات الإسلامية', 'اسلامی ایام');
  String get todayPill => _t('TODAY', 'اليوم', 'آج');
  String eventsCount(int n) => _t('$n events', '$n مناسبة', '$n تقریبیں');
  String get jummahMubarak => _t('Jummah Mubarak!', 'جمعة مباركة!', 'جمعہ مبارک!');
  String get blessedDay => _t('Blessed Day', 'يوم مبارك', 'مبارک دن');
  String get jummahDayInfo => _t(
      'Jummah Mubarak! Best day for Surah Al-Kahf & Salawat',
      'جمعة مباركة! أفضل يوم لسورة الكهف والصلاة على النبي',
      'جمعہ مبارک! سورۃ الکہف اور درود شریف کا بہترین دن');
  String get mondayFastInfo => _t(
      'Monday — Sunnah fasting day. Prophet ﷺ used to fast.',
      'الاثنين — يوم صيام سنة. كان النبي ﷺ يصوم.',
      'پیر — سنت روزے کا دن۔ نبی کریم ﷺ روزہ رکھتے تھے۔');
  String get thursdayFastInfo => _t(
      'Thursday — Sunnah fasting day. Deeds are presented to Allah.',
      'الخميس — يوم صيام سنة. تُعرض الأعمال على الله.',
      'جمعرات — سنت روزے کا دن۔ اعمال اللہ کے سامنے پیش کیے جاتے ہیں۔');
  String get makeMostOfDayInfo => _t(
      'Make the most of today with dhikr, Quran reading, and good deeds.',
      'اغتنم يومك بالذكر وتلاوة القرآن والعمل الصالح.',
      'آج کو ذکر، قرآنِ تلاوت اور نیک اعمال سے عبارت بنائیں۔');
  String get catHoliday => _t('Holiday', 'عطلة', 'تہوار');
  String get catFasting => _t('Fasting', 'الصيام', 'روزے');
  String get catSpecialNight => _t('Special Night', 'ليلة مميزة', 'خاص رات');
  String get catSunnah => _t('Sunnah', 'السنة', 'سنت');
  String get selectedLegendLabel => _t('Selected', 'المحدَّد', 'منتخب کردہ');
  String everyWeekday(String dayName) => _t('Every $dayName', 'كل $dayName', 'ہر $dayName');
  String get whiteDaysDateLabel => _t('13,14,15 Monthly', '١٣،١٤،١٥ من كل شهر', 'ہر مہینے 13، 14، 15');
  String get calNewYearName => _t('Islamic New Year', 'رأس السنة الهجرية', 'سالِ نو ہجری');
  String get calNewYearDesc => _t('Start of Islamic Hijri year', 'بداية السنة الهجرية', 'حجری سال کا آغاز');
  String get calAshuraName => _t('Day of Ashura', 'يوم عاشوراء', 'یومِ عاشورہ');
  String get calAshuraDesc => _t(
      'Day of fasting & remembrance. Prophet Musa was saved.',
      'يوم صيام وذكر. نَجَّى الله فيه موسى.',
      'روزے اور یادِ الٰہی کا دن۔ اللہ نے موسیٰ علیہ السلام کو نجات دی۔');
  String get calMawlidName => _t('Mawlid an-Nabi', 'المولد النبوي', 'عیدِ میلاد النبی ﷺ');
  String get calMawlidDesc => _t(
      'Birth of Prophet Muhammad ﷺ',
      'ميلاد النبي محمد ﷺ',
      'نبی کریم محمد ﷺ کی ولادت باسعادت');
  String get calIsraName => _t('Isra & Miraj', 'الإسراء والمعراج', 'اسراء و معراج');
  String get calIsraDesc => _t(
      'Night journey of Prophet ﷺ from Makkah to Jerusalem & heavens',
      'الرحلة الليلية للنبي ﷺ من مكة إلى القدس ثم السماوات',
      'نبی کریم ﷺ کا رات کا سفر مکہ سے بیت المقدس اور آسمانوں تک');
  String get calBaratName => _t('Shab-e-Barat', 'ليلة النصف من شعبان', 'شبِ برات');
  String get calBaratDesc => _t(
      'Night of forgiveness. Records are transferred.',
      'ليلة المغفرة. تُرفع فيها الأعمال.',
      'مغفرت کی رات۔ اعمال کے ریکارڈ منتقل کیے جاتے ہیں۔');
  String get calRamadanName => _t('Ramadan Begins', 'بداية رمضان', 'رمضان کا آغاز');
  String get calRamadanDesc => _t(
      'Start of the holy month of fasting',
      'بداية شهر الصيام المبارك',
      'مبارک روزوں کے مہینے کا آغاز');
  String get calQadrName => _t('Laylat al-Qadr', 'ليلة القدر', 'شبِ قدر');
  String get calQadrDesc => _t(
      'Night better than 1000 months. Quran was revealed.',
      'ليلة خير من ألف شهر. أُنزل فيها القرآن.',
      'ہزار مہینوں سے بہتر رات۔ اس میں قرآن نازل ہوا۔');
  String get calEidFitrName => _t('Eid al-Fitr', 'عيد الفطر', 'عید الفطر');
  String get calEidFitrDesc => _t(
      'Festival of Breaking the Fast. Celebrate with family!',
      'عيد الفطر من الصيام. احتفل مع أهلك!',
      'روزے کی عید۔ گھر والوں کے ساتھ منائیں!');
  String get calArafahName => _t('Day of Arafah', 'يوم عرفة', 'یومِ عرفہ');
  String get calArafahDesc => _t(
      'Best day for fasting. Sins of 2 years forgiven.',
      'أفضل يوم للصيام. تُكفَّر فيه ذنوب حولين.',
      'روزے کا بہترین دن۔ دو سال کے گناہ معاف۔');
  String get calEidAdhaName => _t('Eid al-Adha', 'عيد الأضحى', 'عید الاضحیٰ');
  String get calEidAdhaDesc => _t(
      'Festival of Sacrifice. Remember Ibrahim\'s devotion.',
      'عيد الأضحى. تذكر إخلاء إبراهيم.',
      'عیدِ قربانی۔ ابراہیم علیہ السلام کی اطاعت یاد کریں۔');
  String get calMondayFastingName => _t('Monday Fasting', 'صيام الإثنين', 'پیر کا روزہ');
  String get calMondayFastingDesc => _t(
      'Sunnah fasting on Mondays',
      'صيام سنة أيام الاثنين',
      'پیر کے روزے کی سنت');
  String get calThursdayFastingName => _t('Thursday Fasting', 'صيام الخميس', 'جمعرات کا روزہ');
  String get calThursdayFastingDesc => _t(
      'Sunnah fasting on Thursdays',
      'صيام سنة أيام الخميس',
      'جمعرات کے روزے کی سنت');
  String get calAyyamName => _t('Ayyam al-Beedh', 'أيام البيض', 'ایامِ بیض');
  String get calAyyamDesc => _t(
      'White days fasting (13th, 14th, 15th of each Hijri month)',
      'صيام الأيام البيض (13 و14 و15 من كل شهر هجري)',
      'ایامِ بیض کے روزے (ہر حجری مہینے کی 13، 14، 15 تاریخیں)');
  String get ramadanSunanTitle => _t('RAMADAN — SUNAN & ADAB', 'رمضان — السنن والآداب', 'رمضان — سنتیں اور آداب');
  String get suhoorIftarDuasNote => _t(
      'Suhoor & iftar duas: Duas section — Fast & Food category.',
      'أدعية السحور والإفطار: قسم الأدعية — فئة الصيام والطعام.',
      'سحری اور افطار کی دعائیں: دعائیں سیکشن — روزہ و طعام زمرہ۔');
  String get tipTaraweehTitle => _t('Pray Taraweeh', 'صلاة التراويح', 'تراویح پڑھیں');
  String get tipTaraweehNote => _t(
      'Special night prayer in Ramadan',
      'قيام ليالي رمضان',
      'رمضان کی راتوں کی خاص نماز');
  String get tipReadQuranTitle => _t('Read Quran Daily', 'اقرأ القرآن يوميًا', 'روزانہ قرآن پڑھیں');
  String get tipReadQuranNote => _t(
      'Try to complete it this month',
      'حاول إتمامه هذا الشهر',
      'اس مہینے مکمل کرنے کی کوشش کریں');
  String get tipCharityTitle => _t('Give Charity', 'أخرج الصدقة', 'صدقہ دیں');
  String get tipCharityNote => _t(
      'Rewards are multiplied in Ramadan',
      'الأجور تُضاعف في رمضان',
      'رمضان میں اجر کئی گنا بڑھایا جاتا ہے');
  String get tipDuaTitle => _t('Make Dua', 'ادعُ الله', 'دعا کریں');
  String get tipDuaNote => _t('Especially before Iftar', 'خاصة قبل الإفطار', 'خاص طور پر افطار سے پہلے');
  String get tipItikafTitle => _t('Itikaf', 'الاعتكاف', 'اعتکاف');
  String get tipItikafNote => _t(
      'Last 10 days seclusion in mosque',
      'اللزوم في المسجد في العشر الأواخر',
      'آخری دس دن مسجد میں گوشہ نشینی');
  String get tipSuhoorTitle => _t('Suhoor', 'السحور', 'سحری');
  String get tipSuhoorNote => _t(
      'Never skip — it is blessed',
      'لا تدعه — فيه بركة',
      'کبھی نہ چھوڑیں — اس میں برکت ہے');
  String mushafPageOfTotal(int page) => _t('Page $page of 604', 'صفحة $page من 604', 'صفحہ $page از 604');
  String mushafPageSlash604(int page) => _t('Page $page / 604', 'صفحة $page / 604', 'صفحہ $page / 604');
  String get mushafNoVersesNote => _t(
      'No verses recorded for this page in the bundled data.',
      'لا توجد آيات مسجَّلة لهذه الصفحة في البيانات المضمَّنة.',
      'بنڈل شدہ ڈیٹا میں اس صفحے کی کوئی آیت درج نہیں۔');
  String get mushafSajdahNote => _t(
      'Sajdah of recitation on this page',
      'سجدة تلاوة في هذه الصفحة',
      'اس صفحے پر سجدۂ تلاوت ہے');

  // ── A2 locale name tables (values ARE the translations; the
  // English columns are the exact words the screens already render,
  // so EN output stays byte-identical) ──
  static const List<String> _dayNamesEn = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday',
    'Sunday',
  ];
  static const List<String> _dayNamesAr = [
    'الاثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد',
  ];
  static const List<String> _dayNamesUr = [
    'پیر', 'منگل', 'بدھ', 'جمعرات', 'جمعہ', 'ہفتہ', 'اتوار',
  ];
  static const List<String> _monthsEn = [
    'January', 'February', 'March', 'April', 'May', 'June', 'July',
    'August', 'September', 'October', 'November', 'December',
  ];
  static const List<String> _monthsAr = [
    'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو', 'يوليو',
    'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر',
  ];
  static const List<String> _monthsUr = [
    'جنوری', 'فروری', 'مارچ', 'اپریل', 'مئی', 'جون', 'جولائی', 'اگست',
    'ستمبر', 'اکتوبر', 'نومبر', 'دسمبر',
  ];
  static const List<String> _hijriMonthsUr = [
    'محرم', 'صفر', 'ربیع الاول', 'ربیع الثانی', 'جمادی الاولیٰ',
    'جمادی الآخریٰ', 'رجب', 'شعبان', 'رمضان', 'شوال', 'ذوالقعدہ',
    'ذوالحجہ',
  ];

  /// weekday 1=Monday..7=Sunday (DateTime.weekday).
  String dayName(int weekday) {
    final i = (weekday - 1) % 7;
    switch (_code) {
      case 'ar':
        return _dayNamesAr[i];
      case 'ur':
        return _dayNamesUr[i];
      default:
        return _dayNamesEn[i];
    }
  }

  /// Gregorian month 1..12.
  String monthName(int month) {
    final i = (month - 1) % 12;
    switch (_code) {
      case 'ar':
        return _monthsAr[i];
      case 'ur':
        return _monthsUr[i];
      default:
        return _monthsEn[i];
    }
  }

  /// Hijri month 1..12. EN callers pass their own long month name
  /// (the package value), so the English render is untouched; Arabic
  /// borrows the canonical list, Urdu the standard Urdu month names.
  String hijriMonthName(int hijriMonth, String enFallback) {
    final i = (hijriMonth - 1) % 12;
    switch (_code) {
      case 'ar':
        return AppIslamicConstants.hijriMonthsArabic[i];
      case 'ur':
        return _hijriMonthsUr[i];
      default:
        return enFallback;
    }
  }

  /// Prayer names: EN keeps the current word; AR renders the model's
  /// arabicName; UR gets its own table (ar and ur can diverge — the
  /// pass decision). Unknown words pass through untouched.
  String prayerDisplayName(String en, String arabicName) {
    switch (_code) {
      case 'ar':
        return arabicName;
      case 'ur':
        switch (en) {
          case 'Fajr':
            return 'فجر';
          case 'Sunrise':
            return 'طلوعِ آفتاب';
          case 'Dhuhr':
            return 'ظہر';
          case 'Asr':
            return 'عصر';
          case 'Maghrib':
            return 'مغرب';
          case 'Isha':
            return 'عشاء';
          default:
            return en;
        }
      default:
        return en;
    }
  }

  /// The hero greeting, hour-routed exactly like the home widget did
  /// before this pass (night <4, morning <12, afternoon <17, else
  /// evening) — so EN output is byte-identical.
  String greetingForHour(int hour) {
    if (hour < 4) return greetingPeacefulNight;
    if (hour < 12) return greetingGoodMorning;
    if (hour < 17) return greetingGoodAfternoon;
    return greetingGoodEvening;
  }

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
