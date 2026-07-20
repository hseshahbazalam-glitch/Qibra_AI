// lib/features/chat/data/services/islamic_dictionary.dart

// ============================================================
// QIBRA AI — ISLAMIC KNOWLEDGE DICTIONARY
// Maps Roman Urdu / Urdu / English keywords to Islamic topics
// ============================================================

class IslamicTopic {
  final String id;
  final String nameEnglish;
  final String nameUrdu;
  final List<String> keywords;
  final List<QuranReference> quranRefs;
  final List<String> hadithKeywords; // English keywords for hadith search

  const IslamicTopic({
    required this.id,
    required this.nameEnglish,
    required this.nameUrdu,
    required this.keywords,
    required this.quranRefs,
    required this.hadithKeywords,
  });
}

class QuranReference {
  final int surah;
  final int ayah;
  const QuranReference(this.surah, this.ayah);
}

class IslamicDictionary {
  IslamicDictionary._();

  // ============================================================
  // TOPICS DATABASE
  // Each topic contains keywords in multiple languages
  // ============================================================

  static const List<IslamicTopic> topics = [
    // ═══════════════════════════════════════════════════════
    // PRAYER (Salah / Namaz)
    // ═══════════════════════════════════════════════════════
    IslamicTopic(
      id: 'prayer',
      nameEnglish: 'Prayer (Salah)',
      nameUrdu: 'نماز',
      keywords: [
        'namaz',
        'namaaz',
        'namaj',
        'salat',
        'salah',
        'salaat',
        'prayer',
        'pray',
        'praying',
        'worship',
        'نماز',
        'صلاة',
        'صلوة',
        'fazilat',
        'ahmiyat',
        'importance',
        'benefit',
      ],
      quranRefs: [
        QuranReference(2, 43), // Aqimus Salah
        QuranReference(2, 45), // Seek help through patience & prayer
        QuranReference(2, 238), // Guard your prayers
        QuranReference(20, 14), // Establish prayer for My remembrance
        QuranReference(29, 45), // Prayer forbids evil
        QuranReference(4, 103), // Prayer at fixed times
      ],
      hadithKeywords: ['prayer', 'salat', 'salah', 'namaz'],
    ),

    // ═══════════════════════════════════════════════════════
    // SLEEP (Sona / Neend)
    // ═══════════════════════════════════════════════════════
    IslamicTopic(
      id: 'sleep',
      nameEnglish: 'Sleep',
      nameUrdu: 'سونا / نیند',
      keywords: [
        'sona',
        'sone',
        'sote',
        'sote waqt',
        'sote hue',
        'sleep',
        'sleeping',
        'asleep',
        'bed',
        'bedtime',
        'neend',
        'neendein',
        'نیند',
        'سونا',
        'خواب',
        'dua sone',
        'sleeping dua',
        'sone ki dua',
      ],
      quranRefs: [
        QuranReference(39, 42), // Allah takes souls at death and during sleep
        QuranReference(78, 9), // We made sleep a rest
        QuranReference(30, 23), // Sleep is a sign
      ],
      hadithKeywords: ['sleep', 'sleeping', 'bed', 'night'],
    ),

    // ═══════════════════════════════════════════════════════
    // ZINA (Adultery / Fornication)
    // ═══════════════════════════════════════════════════════
    IslamicTopic(
      id: 'zina',
      nameEnglish: 'Adultery / Fornication',
      nameUrdu: 'زنا',
      keywords: [
        'zina',
        'zena',
        'adultery',
        'fornication',
        'unlawful sex',
        'illegal relationship',
        'haram relationship',
        'زنا',
        'بدکاری',
        'zina kya hai',
        'zina ki saza',
        'zina ka gunah',
      ],
      quranRefs: [
        QuranReference(17, 32), // Do not come near zina
        QuranReference(24, 2), // Punishment for zina
        QuranReference(25, 68), // Attributes of servants of Rahman
        QuranReference(24, 30), // Lower gaze
        QuranReference(24, 31), // Women lower gaze
      ],
      hadithKeywords: ['adultery', 'fornication', 'zina', 'unlawful'],
    ),

    // ═══════════════════════════════════════════════════════
    // FASTING (Roza / Sawm)
    // ═══════════════════════════════════════════════════════
    IslamicTopic(
      id: 'fasting',
      nameEnglish: 'Fasting',
      nameUrdu: 'روزہ',
      keywords: [
        'roza',
        'rozey',
        'roze',
        'saum',
        'sawm',
        'siyam',
        'fasting',
        'fast',
        'ramadan',
        'ramzan',
        'روزہ',
        'صوم',
      ],
      quranRefs: [
        QuranReference(2, 183), // Fasting prescribed
        QuranReference(2, 185), // Ramadan
        QuranReference(2, 187), // Fasting rules
      ],
      hadithKeywords: ['fasting', 'ramadan', 'sawm', 'fast'],
    ),

    // ═══════════════════════════════════════════════════════
    // CHARITY (Zakat / Sadaqah)
    // ═══════════════════════════════════════════════════════
    IslamicTopic(
      id: 'zakat',
      nameEnglish: 'Charity',
      nameUrdu: 'زکوٰۃ / صدقہ',
      keywords: [
        'zakat',
        'zakah',
        'zakaat',
        'sadaqa',
        'sadaqah',
        'charity',
        'khairat',
        'donation',
        'khums',
        'زکاۃ',
        'صدقہ',
        'خیرات',
      ],
      quranRefs: [
        QuranReference(2, 43),
        QuranReference(2, 267),
        QuranReference(9, 60), // Recipients of zakat
        QuranReference(9, 103), // Take from wealth
      ],
      hadithKeywords: ['zakat', 'charity', 'sadaqah', 'wealth'],
    ),

    // ═══════════════════════════════════════════════════════
    // PARENTS (Walden)
    // ═══════════════════════════════════════════════════════
    IslamicTopic(
      id: 'parents',
      nameEnglish: 'Parents',
      nameUrdu: 'والدین',
      keywords: [
        'walden',
        'walidain',
        'ammi abbu',
        'maa baap',
        'ma baap',
        'parents',
        'mother',
        'father',
        'mom',
        'dad',
        'mummy',
        'papa',
        'walida',
        'walid',
        'والدین',
        'ماں',
        'باپ',
      ],
      quranRefs: [
        QuranReference(17, 23), // Be good to parents
        QuranReference(17, 24), // Lower wings of humility
        QuranReference(31, 14), // We enjoined parents
        QuranReference(46, 15), // Best treatment to parents
      ],
      hadithKeywords: ['parents', 'mother', 'father'],
    ),

    // ═══════════════════════════════════════════════════════
    // DEATH (Maut)
    // ═══════════════════════════════════════════════════════
    IslamicTopic(
      id: 'death',
      nameEnglish: 'Death',
      nameUrdu: 'موت',
      keywords: [
        'maut',
        'mout',
        'death',
        'die',
        'dying',
        'wafat',
        'قبر',
        'موت',
        'وفات',
        'grave',
        'qabr',
        'akhirat',
      ],
      quranRefs: [
        QuranReference(3, 185), // Every soul will taste death
        QuranReference(29, 57),
        QuranReference(21, 35),
        QuranReference(31, 34), // No soul knows where it will die
      ],
      hadithKeywords: ['death', 'grave', 'die'],
    ),

    // ═══════════════════════════════════════════════════════
    // FORGIVENESS (Maafi)
    // ═══════════════════════════════════════════════════════
    IslamicTopic(
      id: 'forgiveness',
      nameEnglish: 'Forgiveness',
      nameUrdu: 'مغفرت',
      keywords: [
        'maafi',
        'maghfirat',
        'istighfar',
        'tawba',
        'tauba',
        'toba',
        'forgiveness',
        'forgive',
        'repentance',
        'repent',
        'مغفرت',
        'استغفار',
        'توبہ',
      ],
      quranRefs: [
        QuranReference(39, 53), // Do not despair of Allah's mercy
        QuranReference(4, 110), // Whoever seeks forgiveness
        QuranReference(66, 8), // Sincere repentance
        QuranReference(3, 135),
      ],
      hadithKeywords: ['forgiveness', 'repentance', 'istighfar', 'tawba'],
    ),

    // ═══════════════════════════════════════════════════════
    // PATIENCE (Sabr)
    // ═══════════════════════════════════════════════════════
    IslamicTopic(
      id: 'patience',
      nameEnglish: 'Patience',
      nameUrdu: 'صبر',
      keywords: [
        'sabar',
        'sabr',
        'patience',
        'patient',
        'endurance',
        'صبر',
      ],
      quranRefs: [
        QuranReference(2, 153), // Allah is with the patient
        QuranReference(2, 155), // Test with fear and hunger
        QuranReference(3, 200),
        QuranReference(103, 3),
      ],
      hadithKeywords: ['patience', 'patient', 'sabr'],
    ),

    // ═══════════════════════════════════════════════════════
    // GRATITUDE (Shukr)
    // ═══════════════════════════════════════════════════════
    IslamicTopic(
      id: 'gratitude',
      nameEnglish: 'Gratitude',
      nameUrdu: 'شکر',
      keywords: [
        'shukar',
        'shukr',
        'gratitude',
        'thankful',
        'thanks',
        'ihsan',
        'ehsaan',
        'شکر',
      ],
      quranRefs: [
        QuranReference(14, 7), // If grateful, I will increase
        QuranReference(31, 12),
        QuranReference(2, 152),
      ],
      hadithKeywords: ['gratitude', 'thankful', 'shukr'],
    ),

    // ═══════════════════════════════════════════════════════
    // LYING (Jhoot)
    // ═══════════════════════════════════════════════════════
    IslamicTopic(
      id: 'lying',
      nameEnglish: 'Lying',
      nameUrdu: 'جھوٹ',
      keywords: [
        'jhoot',
        'jhut',
        'jhooth',
        'jhoota',
        'jhooti',
        'lie',
        'lying',
        'liar',
        'falsehood',
        'dishonest',
        'جھوٹ',
        'کذب',
      ],
      quranRefs: [
        QuranReference(16, 105), // Only those who don't believe fabricate
        QuranReference(22, 30),
        QuranReference(40, 28),
      ],
      hadithKeywords: ['lie', 'lying', 'truth', 'honesty'],
    ),

    // ═══════════════════════════════════════════════════════
    // HAJJ / PILGRIMAGE
    // ═══════════════════════════════════════════════════════
    IslamicTopic(
      id: 'hajj',
      nameEnglish: 'Hajj / Pilgrimage',
      nameUrdu: 'حج',
      keywords: [
        'hajj',
        'haj',
        'pilgrimage',
        'umrah',
        'umra',
        'kaaba',
        'kaba',
        'makkah',
        'mecca',
        'madinah',
        'medina',
        'حج',
        'عمرہ',
        'کعبہ',
      ],
      quranRefs: [
        QuranReference(2, 196),
        QuranReference(3, 97), // Hajj obligation
        QuranReference(22, 27),
      ],
      hadithKeywords: ['hajj', 'pilgrimage', 'umrah', 'kaaba'],
    ),

    // ═══════════════════════════════════════════════════════
    // MARRIAGE (Nikah)
    // ═══════════════════════════════════════════════════════
    IslamicTopic(
      id: 'marriage',
      nameEnglish: 'Marriage',
      nameUrdu: 'نکاح / شادی',
      keywords: [
        'nikah',
        'nikkah',
        'shadi',
        'shaadi',
        'marriage',
        'marry',
        'wife',
        'husband',
        'biwi',
        'shohar',
        'نکاح',
        'شادی',
      ],
      quranRefs: [
        QuranReference(30, 21), // Created spouses for tranquility
        QuranReference(24, 32), // Marry the single
        QuranReference(4, 3),
      ],
      hadithKeywords: ['marriage', 'wife', 'husband', 'nikah'],
    ),

    // ═══════════════════════════════════════════════════════
    // ANGER (Ghussa)
    // ═══════════════════════════════════════════════════════
    IslamicTopic(
      id: 'anger',
      nameEnglish: 'Anger',
      nameUrdu: 'غصہ',
      keywords: [
        'gussa',
        'ghussa',
        'anger',
        'angry',
        'rage',
        'furious',
        'غصہ',
      ],
      quranRefs: [
        QuranReference(3, 134), // Those who suppress anger
        QuranReference(42, 37),
      ],
      hadithKeywords: ['anger', 'angry'],
    ),

    // ═══════════════════════════════════════════════════════
    // PARADISE (Jannat)
    // ═══════════════════════════════════════════════════════
    IslamicTopic(
      id: 'jannat',
      nameEnglish: 'Paradise',
      nameUrdu: 'جنت',
      keywords: [
        'jannat',
        'jannah',
        'paradise',
        'heaven',
        'firdaus',
        'جنت',
        'فردوس',
      ],
      quranRefs: [
        QuranReference(2, 25), // Gardens beneath which rivers flow
        QuranReference(3, 133), // Hasten to forgiveness and Paradise
        QuranReference(9, 72),
        QuranReference(47, 15),
      ],
      hadithKeywords: ['paradise', 'jannah', 'heaven'],
    ),

    // ═══════════════════════════════════════════════════════
    // HELL (Jahannam)
    // ═══════════════════════════════════════════════════════
    IslamicTopic(
      id: 'hell',
      nameEnglish: 'Hell',
      nameUrdu: 'جہنم',
      keywords: [
        'jahannam',
        'jahannum',
        'dozakh',
        'hell',
        'hellfire',
        'جہنم',
        'دوزخ',
      ],
      quranRefs: [
        QuranReference(2, 24),
        QuranReference(3, 131),
        QuranReference(66, 6),
      ],
      hadithKeywords: ['hell', 'hellfire', 'jahannam'],
    ),

    // ═══════════════════════════════════════════════════════
    // KNOWLEDGE (Ilm)
    // ═══════════════════════════════════════════════════════
    IslamicTopic(
      id: 'knowledge',
      nameEnglish: 'Knowledge',
      nameUrdu: 'علم',
      keywords: [
        'ilm',
        'ilam',
        'knowledge',
        'learning',
        'study',
        'education',
        'taleem',
        'talim',
        'علم',
        'تعلیم',
      ],
      quranRefs: [
        QuranReference(20, 114), // Increase me in knowledge
        QuranReference(58, 11),
        QuranReference(96, 1), // Read
      ],
      hadithKeywords: ['knowledge', 'learning', 'ilm'],
    ),

    // ═══════════════════════════════════════════════════════
    // TRUST IN ALLAH (Tawakkul)
    // ═══════════════════════════════════════════════════════
    IslamicTopic(
      id: 'tawakkul',
      nameEnglish: 'Trust in Allah',
      nameUrdu: 'توکل',
      keywords: [
        'tawakkul',
        'tawakul',
        'bharosa',
        'trust in allah',
        'reliance',
        'tawakkal',
        'توکل',
      ],
      quranRefs: [
        QuranReference(65, 3), // Whoever relies on Allah, He is enough
        QuranReference(3, 159),
        QuranReference(11, 88),
      ],
      hadithKeywords: ['trust', 'reliance', 'tawakkul'],
    ),

    // ═══════════════════════════════════════════════════════
    // LOVE (Muhabbat)
    // ═══════════════════════════════════════════════════════
    IslamicTopic(
      id: 'love',
      nameEnglish: 'Love',
      nameUrdu: 'محبت',
      keywords: [
        'muhabbat',
        'mohabbat',
        'love',
        'pyaar',
        'pyar',
        'محبت',
      ],
      quranRefs: [
        QuranReference(3, 31), // Follow me, Allah will love you
        QuranReference(5, 54),
        QuranReference(30, 21),
      ],
      hadithKeywords: ['love', 'muhabbat'],
    ),

    // ═══════════════════════════════════════════════════════
    // QURAN
    // ═══════════════════════════════════════════════════════
    IslamicTopic(
      id: 'quran',
      nameEnglish: 'Quran',
      nameUrdu: 'قرآن',
      keywords: [
        'quran',
        'quraan',
        'kalam',
        'kitab',
        'قرآن',
        'کتاب',
      ],
      quranRefs: [
        QuranReference(2, 2), // No doubt in this book
        QuranReference(17, 88),
        QuranReference(54, 17), // Made Quran easy for remembrance
      ],
      hadithKeywords: ['quran', 'recitation'],
    ),

    // ═══════════════════════════════════════════════════════
    // PROPHET MUHAMMAD ﷺ
    // ═══════════════════════════════════════════════════════
    IslamicTopic(
      id: 'prophet',
      nameEnglish: 'Prophet Muhammad ﷺ',
      nameUrdu: 'نبی کریم ﷺ',
      keywords: [
        'nabi',
        'rasool',
        'rasul',
        'muhammad',
        'muhammed',
        'prophet',
        'messenger',
        'huzoor',
        'sallallahu',
        'نبی',
        'رسول',
        'محمد',
      ],
      quranRefs: [
        QuranReference(33, 40), // Muhammad is the seal of prophets
        QuranReference(33, 56), // Send blessings on Prophet
        QuranReference(48, 29),
        QuranReference(21, 107), // Mercy to worlds
      ],
      hadithKeywords: ['prophet', 'muhammad', 'messenger'],
    ),

    // ═══════════════════════════════════════════════════════
    // ALLAH
    // ═══════════════════════════════════════════════════════
    IslamicTopic(
      id: 'allah',
      nameEnglish: 'Allah',
      nameUrdu: 'اللہ',
      keywords: [
        'allah',
        'god',
        'rabb',
        'rab',
        'khuda',
        'اللہ',
        'رب',
      ],
      quranRefs: [
        QuranReference(2, 255), // Ayatul Kursi
        QuranReference(112, 1), // Say He is One
        QuranReference(59, 22), // Beautiful Names
      ],
      hadithKeywords: ['allah', 'god'],
    ),

    // ═══════════════════════════════════════════════════════
    // TAWHEED (Oneness)
    // ═══════════════════════════════════════════════════════
    IslamicTopic(
      id: 'tawheed',
      nameEnglish: 'Tawheed (Oneness of Allah)',
      nameUrdu: 'توحید',
      keywords: [
        'tawheed',
        'tawhid',
        'toheed',
        'oneness',
        'shirk',
        'توحید',
        'شرک',
      ],
      quranRefs: [
        QuranReference(112, 1),
        QuranReference(112, 2),
        QuranReference(112, 3),
        QuranReference(112, 4),
        QuranReference(4, 48), // Shirk unforgivable
      ],
      hadithKeywords: ['tawheed', 'oneness', 'shirk'],
    ),

    // ═══════════════════════════════════════════════════════
    // HALAL / HARAM
    // ═══════════════════════════════════════════════════════
    IslamicTopic(
      id: 'halal_haram',
      nameEnglish: 'Halal and Haram',
      nameUrdu: 'حلال و حرام',
      keywords: [
        'halal',
        'haram',
        'harram',
        'permitted',
        'forbidden',
        'حلال',
        'حرام',
      ],
      quranRefs: [
        QuranReference(2, 168),
        QuranReference(2, 173),
        QuranReference(5, 3),
      ],
      hadithKeywords: ['halal', 'haram', 'forbidden'],
    ),

    // ═══════════════════════════════════════════════════════
    // DUA (Supplication)
    // ═══════════════════════════════════════════════════════
    IslamicTopic(
      id: 'dua',
      nameEnglish: 'Dua / Supplication',
      nameUrdu: 'دعا',
      keywords: [
        'dua',
        'duaa',
        'dua kaise',
        'supplication',
        'invocation',
        'دعا',
      ],
      quranRefs: [
        QuranReference(2, 186), // I am near, respond to callers
        QuranReference(40, 60), // Call upon me, I respond
        QuranReference(7, 55),
      ],
      hadithKeywords: ['dua', 'supplication', 'prayer'],
    ),

    // ═══════════════════════════════════════════════════════
    // MERCY (Rahmat)
    // ═══════════════════════════════════════════════════════
    IslamicTopic(
      id: 'mercy',
      nameEnglish: 'Mercy',
      nameUrdu: 'رحمت',
      keywords: [
        'rahmat',
        'rehmat',
        'mercy',
        'merciful',
        'rehmani',
        'رحمت',
      ],
      quranRefs: [
        QuranReference(7, 156),
        QuranReference(21, 107),
        QuranReference(39, 53),
      ],
      hadithKeywords: ['mercy', 'merciful'],
    ),

    // ═══════════════════════════════════════════════════════
    // GIVING UP HOPE / DEPRESSION
    // ═══════════════════════════════════════════════════════
    IslamicTopic(
      id: 'depression',
      nameEnglish: 'Depression / Sadness',
      nameUrdu: 'غم / پریشانی',
      keywords: [
        'gham',
        'ghum',
        'pareshani',
        'udaas',
        'udas',
        'depression',
        'sad',
        'sadness',
        'anxiety',
        'worried',
        'stress',
        'tension',
        'fikar',
        'fikr',
        'غم',
        'پریشانی',
        'دکھ',
      ],
      quranRefs: [
        QuranReference(94, 5), // With hardship comes ease
        QuranReference(94, 6),
        QuranReference(2, 286), // Allah doesn't burden beyond capacity
        QuranReference(13, 28), // Hearts find peace in remembrance
        QuranReference(65, 7),
      ],
      hadithKeywords: ['worry', 'anxiety', 'stress', 'sadness'],
    ),
  ];

  // ============================================================
  // SMART SEARCH — Find matching topic
  // ============================================================

  /// Find the best matching topic for a user query
  static IslamicTopic? findTopic(String query) {
    if (query.isEmpty) return null;

    final lowerQuery = query.toLowerCase().trim();
    final queryWords =
        lowerQuery.split(RegExp(r'\s+')).where((w) => w.length > 2).toList();

    IslamicTopic? bestMatch;
    int bestScore = 0;

    for (final topic in topics) {
      int score = 0;

      for (final keyword in topic.keywords) {
        final lowerKw = keyword.toLowerCase();

        // Exact phrase match — highest priority
        if (lowerQuery.contains(lowerKw)) {
          score += 10;
        }

        // Word by word match
        for (final word in queryWords) {
          if (lowerKw.contains(word) || word.contains(lowerKw)) {
            score += 3;
          }
        }
      }

      if (score > bestScore) {
        bestScore = score;
        bestMatch = topic;
      }
    }

    // Minimum threshold — reject weak matches
    if (bestScore < 5) return null;

    return bestMatch;
  }

  /// Get all Quran refs for a topic
  static List<QuranReference> getQuranRefs(String topicId) {
    final topic = topics.firstWhere(
      (t) => t.id == topicId,
      orElse: () => topics.first,
    );
    return topic.quranRefs;
  }
}
