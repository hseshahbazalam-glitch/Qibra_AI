// lib/features/duas/data/database/duas/dua_health.dart
import '../../models/dua_model.dart';

class DuaHealth {
  DuaHealth._();
  static const List<DuaModel> duas = [
    DuaModel(
      id: 'hl_001',
      category: 'health',
      titleEnglish: 'Dua for Healing (Ruqyah)',
      titleUrdu: 'شفا کی دعا',
      titleArabic: 'دعاء الشفاء',
      arabic:
          'اللَّهُمَّ رَبَّ النَّاسِ، أَذْهِبِ الْبَأْسَ، اشْفِهِ وَأَنْتَ الشَّافِي، لَا شِفَاءَ إِلَّا شِفَاؤُكَ',
      transliteration:
          'Allahumma Rabban-nas, adhhibil-ba\'s, ishfi wa antash-Shafi, la shifa\'a illa shifa\'uk.',
      translationUrdu:
          'اے اللہ! لوگوں کے رب! تکلیف دور کر۔ اسے شفا دے اور تو شفا دینے والا ہے۔ تیری شفا کے سوا کوئی شفا نہیں۔',
      translationEnglish:
          'O Allah, Lord of the people, remove the harm and heal, for You are the Healer. There is no healing except Your healing.',
      reference: 'Sahih al-Bukhari 5742',
      referenceBook: 'Sahih al-Bukhari',
      referenceNumber: '5742',
      grade: 'Sahih',
      whenToRecite: 'Kisi beemar ke liye.',
      howToRecite: 'Beemar par haath rakh kar teen baar padhein.',
      benefits: 'Nabi ﷺ khud beemar sahaba par yeh padhte the.',
      tags: ['health', 'healing', 'sick', 'ruqyah'],
      sortOrder: 1,
    ),
    DuaModel(
      id: 'hl_002',
      category: 'health',
      titleEnglish: 'Self-Ruqyah (7x)',
      titleUrdu: 'اپنے لیے دم',
      titleArabic: 'الرقية على النفس',
      arabic:
          'بِسْمِ اللَّهِ أَرْقِيكَ، مِنْ كُلِّ شَيْءٍ يُؤْذِيكَ، مِنْ شَرِّ كُلِّ نَفْسٍ أَوْ عَيْنِ حَاسِدٍ، اللَّهُ يَشْفِيكَ',
      transliteration:
          'Bismillahi arqik, min kulli shay\'in yuthik, min sharri kulli nafsin aw ayni hasidin, Allahu yashfik.',
      translationUrdu:
          'اللہ کے نام سے تجھ پر دم کرتا ہوں، ہر اس چیز سے جو تجھے تکلیف دے، ہر نفس یا حاسد کی آنکھ کی برائی سے، اللہ تجھے شفا دے۔',
      translationEnglish:
          'In the name of Allah I perform ruqyah for you, from everything that harms you, from the evil of every soul or envious eye, may Allah heal you.',
      reference: 'Sahih Muslim 2186',
      referenceBook: 'Sahih Muslim',
      referenceNumber: '2186',
      grade: 'Sahih',
      whenToRecite: 'Beemar hone par khud par ya doosron par.',
      howToRecite: 'Teen baar padhein.',
      benefits: 'Jibreel ﷺ ne Nabi ﷺ par yeh dam kiya tha.',
      tags: ['health', 'ruqyah', 'evil eye', 'healing'],
      sortOrder: 2,
    ),
    DuaModel(
      id: 'hl_003',
      category: 'health',
      titleEnglish: 'Dua When in Pain',
      titleUrdu: 'درد میں دعا',
      titleArabic: 'دعاء الألم',
      arabic: 'بِسْمِ اللَّهِ',
      transliteration:
          'Bismillah (3x), then: A\'udhu billahi wa qudratihi min sharri ma ajidu wa uhaziru (7x).',
      translationUrdu:
          'اللہ کے نام سے (3 بار)، پھر: اللہ کی اور اس کی قدرت کی پناہ لیتا ہوں اس چیز کی برائی سے جو میں پا رہا ہوں اور جس سے مجھے خدشہ ہے (7 بار)۔',
      translationEnglish:
          'Bismillah (3x), then: I seek refuge in Allah and His power from the evil of what I feel and what I fear (7x).',
      reference: 'Sahih Muslim 2202',
      referenceBook: 'Sahih Muslim',
      referenceNumber: '2202',
      grade: 'Sahih',
      whenToRecite: 'Jab jism mein dard ho.',
      howToRecite: 'Dard wali jagah haath rakh kar padhein.',
      benefits: 'Nabi ﷺ ne yeh tarika sikhaya — dard mein fori rahat.',
      tags: ['health', 'pain', 'illness'],
      sortOrder: 3,
    ),
  ];
}
