// lib/features/chat/data/services/language_detector.dart

// ============================================================
// QIBRA AI — LANGUAGE DETECTOR
// Detects: Arabic, Urdu, Roman Urdu, English
// ============================================================

enum QueryLanguage {
  arabic,
  urdu,
  romanUrdu,
  english,
  mixed,
}

class LanguageDetector {
  LanguageDetector._();

  // Arabic Unicode range
  static final _arabicRegex = RegExp(r'[\u0600-\u06FF]');

  // Urdu-specific characters (subset of Arabic range)
  static final _urduSpecificRegex = RegExp(r'[ٹڈڑںھۓےہپچژگی]');

  // English letters
  static final _englishRegex = RegExp(r'[a-zA-Z]');

  // Common Roman Urdu words
  static const _romanUrduWords = {
    'kya',
    'hai',
    'hain',
    'ka',
    'ki',
    'ke',
    'ko',
    'se',
    'mein',
    'aur',
    'ya',
    'nahi',
    'nhi',
    'bhi',
    'to',
    'toh',
    'phir',
    'fir',
    'namaz',
    'roza',
    'quran',
    'hadith',
    'allah',
    'nabi',
    'rasool',
    'sallam',
    'wasallam',
    'salam',
    'assalamu',
    'alaikum',
    'wa',
    'islamic',
    'islam',
    'musalman',
    'muslim',
    'dua',
    'sawab',
    'jannat',
    'jahannum',
    'akhirat',
    'dunya',
    'ibadat',
    'zakat',
    'hajj',
    'umrah',
    'sadqa',
    'sadaqah',
    'fardh',
    'fard',
    'sunnah',
    'sunnat',
    'wajib',
    'nafil',
    'kaisi',
    'kaise',
    'kaunsa',
    'kon',
    'kaun',
    'kese',
    'kesa',
    'kesi',
    'kabhi',
    'hamesha',
    'hamesa',
    'batayen',
    'batao',
    'batayi',
    'samjhao',
    'samjhaye',
    'mujhe',
    'mera',
    'meri',
    'mere',
    'hum',
    'tum',
    'wo',
    'yeh',
    'kaha',
    'kahani',
    'waqia',
    'ajr',
    'gunah',
    'gunnah',
    'sabab',
    'fazilat',
    'ahmiyat',
    'importance',
    'benefit',
    'faida',
    'sahih',
    'sahi',
    'ghalat',
    'bidat',
    'bidah',
    'wazu',
    'wudu',
    'ghusl',
    'tayammum',
    'imam',
    'jamaat',
    'fajr',
    'zohar',
    'zuhr',
    'asr',
    'maghrib',
    'isha',
    'ramadan',
    'ramzan',
    'eid',
    'juma',
    'jumma',
    'friday',
    'agar',
    'lekin',
    'magar',
    'kyunki',
    'kyun',
    'kyu',
  };

  /// Detect language of the query
  static QueryLanguage detect(String query) {
    if (query.isEmpty) return QueryLanguage.english;

    final trimmed = query.trim();
    final arabicCount = _arabicRegex.allMatches(trimmed).length;
    final englishCount = _englishRegex.allMatches(trimmed).length;
    final urduSpecificCount = _urduSpecificRegex.allMatches(trimmed).length;

    // Pure Arabic (no Urdu-specific chars)
    if (arabicCount > 0 && urduSpecificCount == 0 && englishCount == 0) {
      return QueryLanguage.arabic;
    }

    // Pure Urdu (has Urdu-specific chars)
    if (urduSpecificCount > 0 && englishCount == 0) {
      return QueryLanguage.urdu;
    }

    // Mixed Arabic + English
    if (arabicCount > 0 && englishCount > 0) {
      return QueryLanguage.mixed;
    }

    // English or Roman Urdu
    if (englishCount > 0) {
      return _isRomanUrdu(trimmed)
          ? QueryLanguage.romanUrdu
          : QueryLanguage.english;
    }

    return QueryLanguage.english;
  }

  /// Check if English text is actually Roman Urdu
  static bool _isRomanUrdu(String text) {
    final words = text.toLowerCase().split(RegExp(r'\s+'));
    if (words.isEmpty) return false;

    int romanUrduHits = 0;
    for (final word in words) {
      final clean = word.replaceAll(RegExp(r'[^\w]'), '');
      if (_romanUrduWords.contains(clean)) {
        romanUrduHits++;
      }
    }

    // If 25%+ words match Roman Urdu vocabulary → Roman Urdu
    return (romanUrduHits / words.length) >= 0.25;
  }

  /// Get language name for display
  static String getName(QueryLanguage lang) {
    switch (lang) {
      case QueryLanguage.arabic:
        return 'Arabic';
      case QueryLanguage.urdu:
        return 'Urdu';
      case QueryLanguage.romanUrdu:
        return 'Roman Urdu';
      case QueryLanguage.english:
        return 'English';
      case QueryLanguage.mixed:
        return 'Mixed';
    }
  }

  /// Get response language preference
  /// Returns which language user prefers for response
  static QueryLanguage getResponseLanguage(QueryLanguage detected) {
    // Arabic + Mixed → Urdu response (most Muslims prefer Urdu)
    if (detected == QueryLanguage.arabic || detected == QueryLanguage.mixed) {
      return QueryLanguage.urdu;
    }
    return detected;
  }
}
