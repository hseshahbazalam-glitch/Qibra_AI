// lib/features/duas/data/database/duas/dua_protection.dart
import '../../models/dua_model.dart';

class DuaProtection {
  DuaProtection._();
  static const List<DuaModel> duas = [
    DuaModel(
      id: 'pt_001',
      category: 'protection',
      titleEnglish: 'Ayatul Kursi — Greatest Protection',
      titleUrdu: 'آیت الکرسی',
      titleArabic: 'آية الكرسي',
      arabic:
          'اللَّهُ لَا إِلَٰهَ إِلَّا هُوَ الْحَيُّ الْقَيُّومُ ۚ لَا تَأْخُذُهُ سِنَةٌ وَلَا نَوْمٌ',
      transliteration:
          'Allahu la ilaha illa huwal-Hayyul-Qayyum. La ta\'khudhuhu sinatun wa la nawm.',
      translationUrdu:
          'اللہ وہ ہے جس کے سوا کوئی معبود نہیں، زندہ ہے، سب کو تھامنے والا۔ اسے نہ اونگھ آتی نہ نیند۔',
      translationEnglish:
          'Allah - there is no deity except Him, the Ever-Living, the Sustainer. Neither drowsiness overtakes Him nor sleep.',
      reference: 'Sahih al-Bukhari 2311',
      referenceBook: 'Sahih al-Bukhari',
      referenceNumber: '2311',
      grade: 'Sahih',
      whenToRecite: 'Subah o shaam, sone se pehle, har farz ke baad.',
      howToRecite: 'Puri ayah (2:255) padhein.',
      benefits:
          'Har farz ke baad parhne se sirf maut jannat se rok sakti hai — Nasai.',
      tags: ['protection', 'quran', 'morning', 'evening', 'powerful'],
      sortOrder: 1,
    ),
    DuaModel(
      id: 'pt_002',
      category: 'protection',
      titleEnglish: 'Protection from Evil Eye',
      titleUrdu: 'نظر بد سے حفاظت',
      titleArabic: 'الحماية من العين',
      arabic: 'أَعُوذُ بِكَلِمَاتِ اللَّهِ التَّامَّاتِ مِنْ شَرِّ مَا خَلَقَ',
      transliteration:
          'A\'udhu bi-kalimatillahit-tammati min sharri ma khalaq.',
      translationUrdu:
          'میں اللہ کے کامل کلمات کی پناہ لیتا ہوں ہر اس چیز کی برائی سے جو اس نے پیدا کی۔',
      translationEnglish:
          'I seek refuge in the perfect words of Allah from the evil of what He has created.',
      reference: 'Sahih Muslim 2708',
      referenceBook: 'Sahih Muslim',
      referenceNumber: '2708',
      grade: 'Sahih',
      whenToRecite: 'Shaam ko, kisi jagah rukne par.',
      howToRecite: 'Teen baar padhein.',
      benefits:
          'Teen baar padhne se koi zahar ya nazar nuqsan nahi pahuncha sakti — Muslim.',
      tags: ['protection', 'evil eye', 'nazar', '3x'],
      sortOrder: 2,
    ),
    DuaModel(
      id: 'pt_003',
      category: 'protection',
      titleEnglish: 'Protection from Shaytan',
      titleUrdu: 'شیطان سے حفاظت',
      titleArabic: 'الحماية من الشيطان',
      arabic: 'أَعُوذُ بِاللَّهِ مِنَ الشَّيْطَانِ الرَّجِيمِ',
      transliteration: 'A\'udhu billahi minash-shaytanir-rajim.',
      translationUrdu: 'میں شیطان مردود سے اللہ کی پناہ مانگتا ہوں۔',
      translationEnglish: 'I seek refuge in Allah from the accursed Shaytan.',
      reference: 'Quran 16:98',
      referenceBook: 'Quran',
      referenceNumber: '16:98',
      grade: 'Quran',
      whenToRecite:
          'Quran padhne se pehle, gusse mein, aur kisi bhi mushkil waqt.',
      howToRecite: 'Ek baar padhein.',
      benefits:
          'Quran ki tilawat se pehle Allah ka hukm — shaytan door ho jata hai.',
      tags: ['protection', 'shaytan', 'quran', 'anger'],
      sortOrder: 3,
    ),
  ];
}
