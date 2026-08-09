import '../../models/dua_model.dart';

class DuaFood {
  DuaFood._();
  static const List<DuaModel> duas = [
    DuaModel(
      id: 'fd_001',
      category: 'food',
      titleEnglish: 'Dua Before Eating',
      titleUrdu: 'کھانا شروع کرنے کی دعا',
      titleArabic: 'دعاء قبل الطعام',
      arabic: 'بِسْمِ اللَّهِ',
      transliteration: 'Bismillah.',
      translationUrdu: 'اللہ کے نام سے۔',
      translationEnglish: 'In the name of Allah.',
      reference: 'Sahih al-Bukhari 5376',
      referenceBook: 'Sahih al-Bukhari',
      referenceNumber: '5376',
      grade: 'Sahih',
      whenToRecite: 'Khanay shuru karne se pehle.',
      howToRecite:
          'Agar bhool jao to yaad aane par: "Bismillahi awwalahu wa akhirahu" padho.',
      benefits: 'Shaytan khane mein shareek nahi hota.',
      tags: ['food', 'eating', 'bismillah'],
      sortOrder: 1,
    ),
    DuaModel(
      id: 'fd_002',
      category: 'food',
      titleEnglish: 'Dua After Eating',
      titleUrdu: 'کھانے کے بعد کی دعا',
      titleArabic: 'دعاء بعد الطعام',
      arabic:
          'الْحَمْدُ لِلَّهِ الَّذِي أَطْعَمَنِي هَذَا وَرَزَقَنِيهِ مِنْ غَيْرِ حَوْلٍ مِنِّي وَلَا قُوَّةٍ',
      transliteration:
          'Alhamdu lillahil-ladhi at\'amani hadha wa razaqanihi min ghayri hawlin minni wa la quwwah.',
      translationUrdu:
          'تمام تعریفیں اللہ کے لیے ہیں جس نے مجھے یہ کھلایا اور بغیر میری کوئی طاقت کے یہ رزق دیا۔',
      translationEnglish:
          'All praise is for Allah who fed me this and provided it for me without any might or power on my part.',
      reference: 'Sunan Abu Dawud 4023',
      referenceBook: 'Sunan Abu Dawud',
      referenceNumber: '4023',
      grade: 'Hasan',
      whenToRecite: 'Khana khatam hone ke baad.',
      howToRecite: 'Khana khatam karke ek baar padhein.',
      benefits: 'Agale aur pichhle gunah maaf ho jayenge.',
      tags: ['food', 'eating', 'gratitude', 'after meal'],
      sortOrder: 2,
    ),
    DuaModel(
      id: 'fd_003',
      category: 'food',
      titleEnglish: 'Dua When Forgetting Bismillah',
      titleUrdu: 'بھول کر Bismillah نہ پڑھنے کی دعا',
      titleArabic: 'دعاء نسيان البسملة',
      arabic: 'بِسْمِ اللَّهِ أَوَّلَهُ وَآخِرَهُ',
      transliteration: 'Bismillahi awwalahu wa akhirahu.',
      translationUrdu: 'اللہ کے نام سے اس کے شروع میں اور آخر میں۔',
      translationEnglish:
          'In the name of Allah at its beginning and at its end.',
      reference: 'Sunan Abu Dawud 3767',
      referenceBook: 'Sunan Abu Dawud',
      referenceNumber: '3767',
      grade: 'Sahih',
      whenToRecite: 'Jab khanay mein Bismillah padhna bhool jao.',
      howToRecite: 'Yaad aate hi padhein — chahe khanay ke dauraan ho.',
      benefits: 'Shaytan jo kha chuka hota hai usse wapas kar deta hai.',
      tags: ['food', 'bismillah', 'forgot'],
      sortOrder: 3,
    ),
    DuaModel(
      id: 'fd_004',
      category: 'food',
      titleEnglish: 'Dua for Breaking Fast (Iftar)',
      titleUrdu: 'افطار کی دعا',
      titleArabic: 'دعاء الإفطار',
      arabic: 'اللَّهُمَّ لَكَ صُمْتُ وَعَلَى رِزْقِكَ أَفْطَرْتُ',
      transliteration: 'Allahumma laka sumtu wa ala rizqika aftartu.',
      translationUrdu:
          'اے اللہ! میں نے تیرے لیے روزہ رکھا اور تیرے رزق سے افطار کیا۔',
      translationEnglish:
          'O Allah, I fasted for You and I break my fast with Your provision.',
      reference: 'Sunan Abu Dawud 2358',
      referenceBook: 'Sunan Abu Dawud',
      referenceNumber: '2358',
      grade: 'Mursal',
      whenToRecite: 'Iftar karte waqt.',
      howToRecite: 'Khajoor ya pani se iftar shuru karte waqt padhein.',
      benefits: 'Rozedar ki dua qabool hoti hai — aftar ke waqt.',
      tags: ['food', 'fasting', 'ramadan', 'iftar'],
      sortOrder: 4,
    ),
    DuaModel(
      id: 'fd_005',
      category: 'food',
      titleEnglish: 'Dua When Hosted by Someone',
      titleUrdu: 'کسی کے گھر کھانا کھانے کی دعا',
      titleArabic: 'دعاء الضيافة',
      arabic:
          'اللَّهُمَّ بَارِكْ لَهُمْ فِيمَا رَزَقْتَهُمْ، وَاغْفِرْ لَهُمْ وَارْحَمْهُمْ',
      transliteration:
          'Allahumma barik lahum fima razaqtahum, waghfir lahum warhamhum.',
      translationUrdu:
          'اے اللہ! جو تو نے انہیں رزق دیا ہے اس میں برکت دے، انہیں بخش دے اور ان پر رحم فرما۔',
      translationEnglish:
          'O Allah, bless for them what You have provided them, forgive them and have mercy upon them.',
      reference: 'Sahih Muslim 2042',
      referenceBook: 'Sahih Muslim',
      referenceNumber: '2042',
      grade: 'Sahih',
      whenToRecite: 'Kisi ke ghar khana khane ke baad — mezbaan ke liye dua.',
      howToRecite: 'Khana khatam hone ke baad mezbaan ke liye padhein.',
      benefits: 'Khane ka badla dua se ada hota hai — Nabi ﷺ ka tarika.',
      tags: ['food', 'guest', 'host', 'blessing'],
      sortOrder: 5,
    ),
    DuaModel(
      id: 'fd_006',
      category: 'food',
      titleEnglish: 'Dua for Drinking Water',
      titleUrdu: 'پانی پینے کی دعا',
      titleArabic: 'دعاء شرب الماء',
      arabic:
          'الْحَمْدُ لِلَّهِ الَّذِي سَقَانَا عَذْبًا فُرَاتًا بِرَحْمَتِهِ وَلَمْ يَجْعَلْهُ مِلْحًا أُجَاجًا بِذُنُوبِنَا',
      transliteration:
          'Alhamdu lillahil-ladhi saqana adhban furatan birahmatih wa lam yaj\'alhu milhan ujajan bidhunubina.',
      translationUrdu:
          'تمام تعریفیں اللہ کے لیے ہیں جس نے اپنی رحمت سے ہمیں میٹھا پانی پلایا اور ہمارے گناہوں کی وجہ سے اسے نمکین اور کڑوا نہیں بنایا۔',
      translationEnglish:
          'All praise is for Allah who, out of His mercy, gave us sweet and fresh water to drink and did not make it salty and bitter because of our sins.',
      reference: 'Sunan Ibn Majah 3500',
      referenceBook: 'Sunan Ibn Majah',
      referenceNumber: '3500',
      grade: 'Hasan',
      whenToRecite: 'Pani pine ke baad.',
      howToRecite: 'Pani pine ke baad padhein.',
      benefits: 'Allah ki is naimat par shukar ada hota hai.',
      tags: ['food', 'water', 'drinking', 'gratitude'],
      sortOrder: 6,
    ),
    DuaModel(
      id: 'fd_007',
      category: 'food',
      titleEnglish: 'Dua for Drinking Milk',
      titleUrdu: 'دودھ پینے کی دعا',
      titleArabic: 'دعاء شرب اللبن',
      arabic: 'اللَّهُمَّ بَارِكْ لَنَا فِيهِ وَزِدْنَا مِنْهُ',
      transliteration: 'Allahumma barik lana fihi wa zidna minhu.',
      translationUrdu:
          'اے اللہ! ہمارے لیے اس میں برکت دے اور ہمیں اس میں سے زیادہ دے۔',
      translationEnglish: 'O Allah, bless us in it and give us more of it.',
      reference: 'Jami at-Tirmidhi 3455',
      referenceBook: 'Jami at-Tirmidhi',
      referenceNumber: '3455',
      grade: 'Hasan',
      whenToRecite: 'Doodh pine ke baad.',
      howToRecite: 'Doodh pine ke baad padhein.',
      benefits:
          'Doodh mein barkat hoti hai — Nabi ﷺ ne sirf doodh ke liye yeh dua sikhayi.',
      tags: ['food', 'milk', 'drinking', 'blessing'],
      sortOrder: 7,
    ),
    DuaModel(
      id: 'fd_008',
      category: 'food',
      titleEnglish: 'Dua When Fasting (Sahri)',
      titleUrdu: 'سحری کی دعا',
      titleArabic: 'دعاء السحور',
      arabic:
          'نَوَيْتُ صَوْمَ غَدٍ مِنْ شَهْرِ رَمَضَانَ الْمُبَارَكِ فَرْضًا لَكَ يَا اللَّهُ فَتَقَبَّلْهُ مِنِّي',
      transliteration:
          'Nawaytu sawma ghadin min shahri Ramadanal-mubaraki fardan laka ya Allah fataqabbalhu minni.',
      translationUrdu:
          'میں نے مبارک ماہ رمضان کے کل کے روزے کی نیت کی، اے اللہ! یہ تیرے لیے فرض ہے، اسے مجھ سے قبول فرما۔',
      translationEnglish:
          'I intend to fast tomorrow in the blessed month of Ramadan as an obligation for You, O Allah, so accept it from me.',
      reference: 'General Islamic practice',
      referenceBook: 'Islamic Fiqh',
      referenceNumber: 'N/A',
      grade: 'Recommended',
      whenToRecite: 'Sahri karte waqt ya Fajr se pehle.',
      howToRecite: 'Dil mein niyyat kafi hai — yeh alfaz padhna mustahab hai.',
      benefits: 'Roze ki sahi niyyat se poora sawab milta hai.',
      tags: ['food', 'fasting', 'ramadan', 'sehri', 'niyyah'],
      sortOrder: 8,
    ),
  ];
}
