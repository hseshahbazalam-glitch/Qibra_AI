// lib/features/duas/data/database/duas/dua_quran.dart
import '../../models/dua_model.dart';

class DuaQuran {
  DuaQuran._();
  static const List<DuaModel> duas = [
    DuaModel(
      id: 'qr_001',
      category: 'quran',
      titleEnglish: 'Dua for Guidance — Surah Fatiha',
      titleUrdu: 'ہدایت کی دعا',
      titleArabic: 'دعاء الهداية',
      arabic: 'اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ',
      transliteration: 'Ihdinas-siratal-mustaqim.',
      translationUrdu: 'ہمیں سیدھی راہ دکھا۔',
      translationEnglish: 'Guide us to the straight path.',
      reference: 'Quran 1:6',
      referenceBook: 'Quran',
      referenceNumber: '1:6',
      grade: 'Quran',
      whenToRecite: 'Har namaz mein — aur kisi bhi waqt.',
      howToRecite: 'Har rakat mein Surah Fatiha padhein.',
      benefits: 'Sabse bari dua — hidayat maangna.',
      tags: ['quran', 'guidance', 'fatiha', 'prayer'],
      sortOrder: 1,
    ),
    DuaModel(
      id: 'qr_002',
      category: 'quran',
      titleEnglish: 'Dua for Increase in Knowledge',
      titleUrdu: 'علم میں اضافے کی دعا',
      titleArabic: 'دعاء زيادة العلم',
      arabic: 'رَّبِّ زِدْنِي عِلْمًا',
      transliteration: 'Rabbi zidni ilma.',
      translationUrdu: 'اے میرے رب! مجھے علم میں اضافہ عطا فرما۔',
      translationEnglish: 'My Lord, increase me in knowledge.',
      reference: 'Quran 20:114',
      referenceBook: 'Quran',
      referenceNumber: '20:114',
      grade: 'Quran',
      whenToRecite: 'Subah, padhai shuru karte waqt.',
      howToRecite: 'Roz padhein.',
      benefits:
          'Sabse mukhtasar powerful dua — Allah ne khud Nabi ﷺ ko sikhaya.',
      tags: ['quran', 'knowledge', 'learning'],
      sortOrder: 2,
    ),
    DuaModel(
      id: 'qr_003',
      category: 'quran',
      titleEnglish: 'Dua of Prophet Ibrahim for Parents',
      titleUrdu: 'والدین کے لیے ابراہیم کی دعا',
      titleArabic: 'دعاء إبراهيم للوالدين',
      arabic:
          'رَّبَّنَا اغْفِرْ لِي وَلِوَالِدَيَّ وَلِلْمُؤْمِنِينَ يَوْمَ يَقُومُ الْحِسَابُ',
      transliteration:
          'Rabbana-ghfir li wa li-walidayya wa lil-mu\'minina yawma yaqumul-hisab.',
      translationUrdu:
          'اے ہمارے رب! مجھے، میرے والدین کو اور تمام مومنوں کو حساب کے دن بخش دے۔',
      translationEnglish:
          'Our Lord, forgive me and my parents and the believers the Day the account is established.',
      reference: 'Quran 14:41',
      referenceBook: 'Quran',
      referenceNumber: '14:41',
      grade: 'Quran',
      whenToRecite: 'Roz walden ke liye.',
      howToRecite: 'Namaz ke baad padhein.',
      benefits: 'Walden ke liye dua — sadaqah-e-jariya.',
      tags: ['quran', 'parents', 'forgiveness', 'ibrahim'],
      sortOrder: 3,
    ),
  ];
}
