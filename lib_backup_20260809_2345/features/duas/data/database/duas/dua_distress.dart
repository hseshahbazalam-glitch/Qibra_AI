// lib/features/duas/data/database/duas/dua_distress.dart
import '../../models/dua_model.dart';

class DuaDistress {
  DuaDistress._();
  static const List<DuaModel> duas = [
    DuaModel(
      id: 'ds_001',
      category: 'distress',
      titleEnglish: 'Dua in Times of Distress',
      titleUrdu: 'تکلیف کی دعا',
      titleArabic: 'دعاء الكرب',
      arabic:
          'لَا إِلَهَ إِلَّا اللَّهُ الْعَظِيمُ الْحَلِيمُ، لَا إِلَهَ إِلَّا اللَّهُ رَبُّ الْعَرْشِ الْعَظِيمِ',
      transliteration:
          'La ilaha illallahul-Azimul-Halim, la ilaha illallahu Rabbul-Arshil-Azim.',
      translationUrdu:
          'اللہ کے سوا کوئی معبود نہیں جو بڑا اور بردبار ہے۔ اللہ کے سوا کوئی معبود نہیں جو عظیم عرش کا رب ہے۔',
      translationEnglish:
          'None has the right to be worshipped except Allah, the Mighty, the Forbearing. None has the right to be worshipped except Allah, Lord of the Magnificent Throne.',
      reference: 'Sahih al-Bukhari 6346',
      referenceBook: 'Sahih al-Bukhari',
      referenceNumber: '6346',
      grade: 'Sahih',
      whenToRecite: 'Jab sakht ghabrahat ya musibat aaye.',
      howToRecite: 'Pareshani mein baar baar padhein.',
      benefits: 'Nabi ﷺ ghabrahat ke waqt yeh padhte the.',
      tags: ['distress', 'anxiety', 'hardship'],
      sortOrder: 1,
    ),
    DuaModel(
      id: 'ds_002',
      category: 'distress',
      titleEnglish: 'Dua of Prophet Yunus (AS)',
      titleUrdu: 'حضرت یونس کی دعا',
      titleArabic: 'دعاء يونس عليه السلام',
      arabic:
          'لَّا إِلَٰهَ إِلَّا أَنتَ سُبْحَانَكَ إِنِّي كُنتُ مِنَ الظَّالِمِينَ',
      transliteration: 'La ilaha illa anta subhanaka inni kuntu minaz-zalimin.',
      translationUrdu:
          'تیرے سوا کوئی معبود نہیں۔ تو پاک ہے۔ بے شک میں ظالموں میں سے تھا۔',
      translationEnglish:
          'There is none worthy of worship except You. Glory be to You. Indeed I have been of the wrongdoers.',
      reference: 'Quran 21:87',
      referenceBook: 'Quran & Jami at-Tirmidhi',
      referenceNumber: '3505',
      grade: 'Sahih',
      whenToRecite: 'Kisi bhi mushkil mein.',
      howToRecite: 'Baar baar padhein.',
      benefits:
          'Jo Muslim yeh padhe Allah uski dua qabool karta hai — Tirmidhi.',
      tags: ['distress', 'yunus', 'quran', 'powerful'],
      sortOrder: 2,
    ),
    DuaModel(
      id: 'ds_003',
      category: 'distress',
      titleEnglish: 'Dua for Anxiety and Sorrow',
      titleUrdu: 'غم اور فکر کی دعا',
      titleArabic: 'دعاء الهم والحزن',
      arabic:
          'اللَّهُمَّ إِنِّي عَبْدُكَ، ابْنُ عَبْدِكَ، ابْنُ أَمَتِكَ، نَاصِيَتِي بِيَدِكَ، مَاضٍ فِيَّ حُكْمُكَ، عَدْلٌ فِيَّ قَضَاؤُكَ',
      transliteration:
          'Allahumma inni abduka, ibnu abdika, ibnu amatika, nasiyati biyadika, madin fiyya hukmuka, adlun fiyya qada\'uk.',
      translationUrdu:
          'اے اللہ! میں تیرا بندہ ہوں، تیرے بندے کا بیٹا، تیری بندی کا بیٹا۔ میری پیشانی تیرے ہاتھ میں ہے۔',
      translationEnglish:
          'O Allah, I am Your servant, son of Your servant, son of Your maidservant, my forelock is in Your hand, Your command over me is forever executed.',
      reference: 'Musnad Ahmad 3704',
      referenceBook: 'Musnad Ahmad',
      referenceNumber: '3704',
      grade: 'Sahih',
      whenToRecite: 'Jab dil udaas ho ya andar se rona aaye.',
      howToRecite: 'Yaqeen ke saath padhein.',
      benefits: 'Allah ghabrahat ko khushi se badal deta hai — Musnad Ahmad.',
      tags: ['distress', 'anxiety', 'sorrow', 'heart'],
      sortOrder: 3,
    ),
  ];
}
