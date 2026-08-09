import '../../models/dua_model.dart';

class DuaPrayer {
  DuaPrayer._();
  static const List<DuaModel> duas = [
    DuaModel(
      id: 'pr_001',
      category: 'prayer',
      titleEnglish: 'Dua for Going to Mosque',
      titleUrdu: 'مسجد جانے کی دعا',
      titleArabic: 'دعاء الذهاب إلى المسجد',
      arabic:
          'اللَّهُمَّ اجْعَلْ فِي قَلْبِي نُورًا، وَفِي لِسَانِي نُورًا، وَفِي سَمْعِي نُورًا، وَفِي بَصَرِي نُورًا',
      transliteration:
          'Allahumma-j\'al fi qalbi nuran, wa fi lisani nuran, wa fi sam\'i nuran, wa fi basari nuran.',
      translationUrdu:
          'اے اللہ! میرے دل میں نور رکھ، میری زبان میں نور، کانوں میں نور، آنکھوں میں نور۔',
      translationEnglish:
          'O Allah, place light in my heart, light in my tongue, light in my hearing, light in my sight.',
      reference: 'Sahih al-Bukhari 6316',
      referenceBook: 'Sahih al-Bukhari',
      referenceNumber: '6316',
      grade: 'Sahih',
      whenToRecite: 'Masjid ki taraf chalte waqt.',
      howToRecite: 'Ghar se nikalne ke baad padhein.',
      benefits: 'Allah se noor maangna — ruhani aur jismani dono tarah ka.',
      tags: ['prayer', 'mosque', 'light', 'noor'],
      sortOrder: 1,
    ),
    DuaModel(
      id: 'pr_002',
      category: 'prayer',
      titleEnglish: 'Dua Entering Mosque',
      titleUrdu: 'مسجد میں داخل ہونے کی دعا',
      titleArabic: 'دعاء دخول المسجد',
      arabic: 'اللَّهُمَّ افْتَحْ لِي أَبْوَابَ رَحْمَتِكَ',
      transliteration: 'Allahumma-ftah li abwaba rahmatik.',
      translationUrdu: 'اے اللہ! میرے لیے اپنی رحمت کے دروازے کھول دے۔',
      translationEnglish: 'O Allah, open for me the gates of Your mercy.',
      reference: 'Sahih Muslim 713',
      referenceBook: 'Sahih Muslim',
      referenceNumber: '713',
      grade: 'Sahih',
      whenToRecite: 'Masjid mein dakhil hote waqt.',
      howToRecite: 'Dahna pair pehle rakh kar padhein.',
      benefits: 'Allah ki rahmat ke darwaze khulte hain.',
      tags: ['prayer', 'mosque', 'entering', 'mercy'],
      sortOrder: 2,
    ),
    DuaModel(
      id: 'pr_003',
      category: 'prayer',
      titleEnglish: 'Dua Leaving Mosque',
      titleUrdu: 'مسجد سے نکلنے کی دعا',
      titleArabic: 'دعاء الخروج من المسجد',
      arabic: 'اللَّهُمَّ إِنِّي أَسْأَلُكَ مِنْ فَضْلِكَ',
      transliteration: 'Allahumma inni as\'aluka min fadlik.',
      translationUrdu: 'اے اللہ! میں تجھ سے تیرا فضل مانگتا ہوں۔',
      translationEnglish: 'O Allah, I ask You for Your bounty.',
      reference: 'Sahih Muslim 713',
      referenceBook: 'Sahih Muslim',
      referenceNumber: '713',
      grade: 'Sahih',
      whenToRecite: 'Masjid se bahar nikalne ke waqt.',
      howToRecite: 'Baen pair pehle rakh kar padhein.',
      benefits: 'Allah ka fazl aur rizq milta hai.',
      tags: ['prayer', 'mosque', 'leaving'],
      sortOrder: 3,
    ),
    DuaModel(
      id: 'pr_004',
      category: 'prayer',
      titleEnglish: 'Dua After Adhan',
      titleUrdu: 'اذان کے بعد کی دعا',
      titleArabic: 'دعاء بعد الأذان',
      arabic:
          'اللَّهُمَّ رَبَّ هَذِهِ الدَّعْوَةِ التَّامَّةِ وَالصَّلَاةِ الْقَائِمَةِ، آتِ مُحَمَّدًا الْوَسِيلَةَ وَالْفَضِيلَةَ، وَابْعَثْهُ مَقَامًا مَحْمُودًا الَّذِي وَعَدْتَهُ',
      transliteration:
          'Allahumma Rabba hadhihid-da\'watit-tammati was-salatil-qa\'imah, ati Muhammadanil-wasilata wal-fadilah, wab\'athhu maqaman mahmudanil-ladhi wa\'adtah.',
      translationUrdu:
          'اے اللہ! اس کامل دعوت اور قائم ہونے والی نماز کے رب! محمد ﷺ کو وسیلہ اور فضیلت عطا فرما اور انہیں اس مقام محمود پر فائز فرما جس کا تو نے وعدہ کیا ہے۔',
      translationEnglish:
          'O Allah, Lord of this perfect call and the prayer to be established, grant Muhammad the intercession and the favor, and raise him to the praised station which You have promised him.',
      reference: 'Sahih al-Bukhari 614',
      referenceBook: 'Sahih al-Bukhari',
      referenceNumber: '614',
      grade: 'Sahih',
      whenToRecite: 'Azan khatam hone ke baad.',
      howToRecite: 'Azan ke jawab ke baad yeh dua padhein.',
      benefits:
          'Nabi ﷺ ne farmaya: Jo azan ke baad yeh padhe — qayamat ke din meri shafaat uske liye halal ho jayegi.',
      tags: ['prayer', 'adhan', 'shafaat', 'powerful'],
      sortOrder: 4,
    ),
    DuaModel(
      id: 'pr_005',
      category: 'prayer',
      titleEnglish: 'Opening Dua of Salah (Istiftah)',
      titleUrdu: 'نماز شروع کرنے کی دعا',
      titleArabic: 'دعاء الاستفتاح',
      arabic:
          'سُبْحَانَكَ اللَّهُمَّ وَبِحَمْدِكَ، وَتَبَارَكَ اسْمُكَ، وَتَعَالَى جَدُّكَ، وَلَا إِلَهَ غَيْرُكَ',
      transliteration:
          'SubhanakaLlahumma wa bihamdika, wa tabarakasmuka, wa ta\'ala jadduka, wa la ilaha ghayruk.',
      translationUrdu:
          'اے اللہ! تو پاک ہے اور تیری تعریف ہے، تیرا نام بابرکت ہے، تیری شان بلند ہے اور تیرے سوا کوئی معبود نہیں۔',
      translationEnglish:
          'Glory and praise be to You, O Allah. Blessed be Your name, exalted be Your majesty, and there is none worthy of worship except You.',
      reference: 'Sunan Abu Dawud 775',
      referenceBook: 'Sunan Abu Dawud',
      referenceNumber: '775',
      grade: 'Sahih',
      whenToRecite: 'Takbeer-e-Tahreema ke baad, Fatiha se pehle.',
      howToRecite: 'Dil mein padhein ya aahistah.',
      benefits: 'Namaz ki shuruat Allah ki tasbih o tahmid se hoti hai.',
      tags: ['prayer', 'salah', 'opening', 'istiftah'],
      sortOrder: 5,
    ),
  ];
}
