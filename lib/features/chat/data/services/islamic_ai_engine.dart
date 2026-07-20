// lib/features/chat/data/services/islamic_ai_engine.dart
// QIBRA AI — Islamic Knowledge Engine v3.0
// Detailed answers from local data only

import 'package:flutter/foundation.dart';
import 'package:qibra_ai/features/hadith/data/services/hadith_database_service.dart';
import 'package:qibra_ai/features/tafseer/data/services/tafseer_service.dart';

import 'islamic_dictionary.dart';
import 'language_detector.dart';
import 'quran_search_service.dart';

// ============================================================
// ANSWER MODEL
// ============================================================

class IslamicAnswer {
  final String userQuestion;
  final QueryLanguage detectedLanguage;
  final List<QuranSearchResult> quranResults;
  final List<LocalSearchResult> hadithResults;
  final List<TafseerAyah> tafseerResults;
  final String formattedAnswer;
  final int totalSources;
  final IslamicTopic? matchedTopic;

  const IslamicAnswer({
    required this.userQuestion,
    required this.detectedLanguage,
    required this.quranResults,
    required this.hadithResults,
    required this.tafseerResults,
    required this.formattedAnswer,
    required this.totalSources,
    this.matchedTopic,
  });
}

// ============================================================
// MAIN ENGINE
// ============================================================

class IslamicAIEngine {
  IslamicAIEngine._();
  static final IslamicAIEngine instance = IslamicAIEngine._();

  final HadithDatabaseService _hadithDb = HadithDatabaseService();
  final TafseerService _tafseerService = TafseerService();
  final QuranSearchService _quranSearch = QuranSearchService.instance;

  bool _isInitialized = false;

  // ============================================================
  // INITIALIZE
  // ============================================================

  Future<void> initialize() async {
    if (_isInitialized) return;
    debugPrint('[ISLAMIC_AI] 🚀 Initializing...');
    await Future.wait([
      _hadithDb.initialize(),
      _quranSearch.initialize(),
    ]);
    _isInitialized = true;
    debugPrint('[ISLAMIC_AI] ✅ Ready');
  }

  // ============================================================
  // MAIN ANSWER FUNCTION
  // ============================================================

  Future<IslamicAnswer> answerQuestion(String question) async {
    if (!_isInitialized) await initialize();

    // 1. Detect language
    final detectedLang = LanguageDetector.detect(question);
    debugPrint(
        '[ISLAMIC_AI] Language: ${LanguageDetector.getName(detectedLang)}');

    // 2. Try dictionary topic match first
    final topic = IslamicDictionary.findTopic(question);

    List<QuranSearchResult> quranResults = [];
    List<LocalSearchResult> hadithResults = [];

    if (topic != null) {
      debugPrint('[ISLAMIC_AI] ✅ Topic: ${topic.nameEnglish}');

      // Get exact Quran verses
      quranResults = _getVersesFromRefs(topic.quranRefs);

      // Search hadith with topic keywords
      for (final kw in topic.hadithKeywords) {
        final results = _hadithDb.search(kw, maxResults: 3);
        for (final r in results) {
          if (!hadithResults.any((h) => h.hadith.id == r.hadith.id)) {
            hadithResults.add(r);
          }
        }
        if (hadithResults.length >= 5) break;
      }

      // If hadith still empty, try question words
      if (hadithResults.isEmpty) {
        hadithResults = _hadithDb.search(question, maxResults: 3);
      }
    } else {
      debugPrint('[ISLAMIC_AI] ⚠️ No topic — keyword search');
      quranResults = _quranSearch.search(question, maxResults: 5);
      hadithResults = _hadithDb.search(question, maxResults: 5);
    }

    // 3. Get tafseer for top Quran results
    final tafseerResults = <TafseerAyah>[];
    for (final verse in quranResults.take(2)) {
      final tafseer = await _tafseerService.getAyahTafseer(
        verse.surahNumber,
        verse.ayahNumber,
      );
      if (tafseer != null) {
        tafseerResults.add(tafseer);
      }
    }

    // 4. Format detailed answer
    final formatted = _formatDetailedAnswer(
      question: question,
      language: detectedLang,
      quran: quranResults,
      hadiths: hadithResults,
      tafseer: tafseerResults,
      matchedTopic: topic,
    );

    return IslamicAnswer(
      userQuestion: question,
      detectedLanguage: detectedLang,
      quranResults: quranResults,
      hadithResults: hadithResults,
      tafseerResults: tafseerResults,
      formattedAnswer: formatted,
      totalSources:
          quranResults.length + hadithResults.length + tafseerResults.length,
      matchedTopic: topic,
    );
  }

  // ============================================================
  // GET VERSES FROM DIRECT REFERENCES
  // ============================================================

  List<QuranSearchResult> _getVersesFromRefs(List<QuranReference> refs) {
    final results = <QuranSearchResult>[];
    for (final ref in refs) {
      final result = _quranSearch.getVerse(ref.surah, ref.ayah);
      if (result != null) results.add(result);
      if (results.length >= 5) break;
    }
    return results;
  }

  // ============================================================
  // FORMAT DETAILED ANSWER
  // ============================================================

  String _formatDetailedAnswer({
    required String question,
    required QueryLanguage language,
    required List<QuranSearchResult> quran,
    required List<LocalSearchResult> hadiths,
    required List<TafseerAyah> tafseer,
    IslamicTopic? matchedTopic,
  }) {
    final buf = StringBuffer();
    final lang = LanguageDetector.getResponseLanguage(language);
    final bool isUrdu = lang == QueryLanguage.urdu;
    final bool isRoman = lang == QueryLanguage.romanUrdu;
    final bool isArabic = lang == QueryLanguage.arabic;

    // ── Bismillah Header ──────────────────────────────────────
    if (isUrdu) {
      buf.writeln('✨ **بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ** ✨\n');
    } else if (isArabic) {
      buf.writeln('✨ **بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ** ✨\n');
    } else {
      buf.writeln('✨ **Bismillah ir-Rahman ir-Raheem** ✨\n');
    }

    buf.writeln('---\n');

    // ── No Results ────────────────────────────────────────────
    if (quran.isEmpty && hadiths.isEmpty && tafseer.isEmpty) {
      buf.writeln(_noResultsResponse(lang));
      return buf.toString();
    }

    // ── Topic Introduction ────────────────────────────────────
    if (matchedTopic != null) {
      if (isUrdu) {
        buf.writeln('## 📌 ${matchedTopic.nameUrdu}\n');
        buf.writeln(
            'اس موضوع کے بارے میں قرآن و حدیث سے مستند دلائل پیش ہیں:\n');
      } else if (isRoman) {
        buf.writeln('## 📌 ${matchedTopic.nameEnglish}\n');
        buf.writeln(
            'Is mauzu ke baare mein Quran aur Hadith se mustanad dalail:\n');
      } else {
        buf.writeln('## 📌 ${matchedTopic.nameEnglish}\n');
        buf.writeln(
            'Here are authentic evidences from Quran and Hadith on this topic:\n');
      }
      buf.writeln('---\n');
    }

    // ── QURAN SECTION ─────────────────────────────────────────
    if (quran.isNotEmpty) {
      if (isUrdu) {
        buf.writeln('## 📖 قرآنِ کریم کی روشنی میں\n');
      } else if (isRoman) {
        buf.writeln('## 📖 Quran Ki Roshni Mein\n');
      } else if (isArabic) {
        buf.writeln('## 📖 من القرآن الكريم\n');
      } else {
        buf.writeln('## 📖 Quranic Evidence\n');
      }

      for (int i = 0; i < quran.take(5).length; i++) {
        final v = quran[i];
        buf.writeln('### 🌿 آیت ${i + 1} — ${v.reference}\n');

        // Arabic text always shown
        if (v.arabic.isNotEmpty) {
          buf.writeln('**عربی:**\n');
          buf.writeln('> ${v.arabic}\n');
        }

        // Translation based on language
        if (isUrdu && v.urdu.isNotEmpty) {
          buf.writeln('**اردو ترجمہ:**\n');
          buf.writeln('> ${v.urdu}\n');
        } else if (isRoman && v.romanUrdu.isNotEmpty) {
          buf.writeln('**Roman Urdu:**\n');
          buf.writeln('> ${v.romanUrdu}\n');
          if (v.urdu.isNotEmpty) {
            buf.writeln('**اردو:**\n');
            buf.writeln('> ${v.urdu}\n');
          }
        } else if (isArabic && v.arabic.isNotEmpty) {
          // Arabic only
        } else {
          // English
          if (v.english.isNotEmpty) {
            buf.writeln('**English Translation:**\n');
            buf.writeln('> ${v.english}\n');
          }
          if (v.urdu.isNotEmpty) {
            buf.writeln('**اردو:**\n');
            buf.writeln('> ${v.urdu}\n');
          }
        }

        buf.writeln('📌 *${v.reference}*\n');
        buf.writeln('---\n');
      }
    }

    // ── HADITH SECTION ────────────────────────────────────────
    if (hadiths.isNotEmpty) {
      if (isUrdu) {
        buf.writeln('## 📚 احادیثِ نبویؐ سے رہنمائی\n');
      } else if (isRoman) {
        buf.writeln('## 📚 Ahadith Se Rehnumai\n');
      } else if (isArabic) {
        buf.writeln('## 📚 من السنة النبوية\n');
      } else {
        buf.writeln('## 📚 Hadith Evidence\n');
      }

      for (int i = 0; i < hadiths.take(5).length; i++) {
        final h = hadiths[i].hadith;

        buf.writeln('### ✅ حدیث ${i + 1} — ${h.displayReference}\n');

        // Grade badge
        if (h.grade.isNotEmpty) {
          buf.writeln('🏷️ **Grade:** ${h.grade}\n');
        }

        // Arabic text if available
        if (h.textArabic != null && h.textArabic!.isNotEmpty) {
          buf.writeln('**عربی متن:**\n');
          buf.writeln('> ${h.textArabic}\n');
        }

        // Hadith text based on language
        String hadithText = '';
        if (isUrdu || isRoman) {
          hadithText = h.textUrdu.isNotEmpty ? h.textUrdu : h.textEnglish;
        } else {
          hadithText = h.textEnglish.isNotEmpty ? h.textEnglish : h.textUrdu;
        }

        if (hadithText.isNotEmpty) {
          if (isUrdu) {
            buf.writeln('**اردو:**\n');
          } else if (isRoman) {
            buf.writeln('**متن:**\n');
          } else {
            buf.writeln('**Text:**\n');
          }
          buf.writeln('> $hadithText\n');
        }

        // English always shown if Urdu was primary
        if ((isUrdu || isRoman) && h.textEnglish.isNotEmpty) {
          buf.writeln('**English:**\n');
          buf.writeln('> ${h.textEnglish}\n');
        }

        buf.writeln('📌 *${h.displayReference}*\n');
        buf.writeln('---\n');
      }
    }

    // ── TAFSEER SECTION ───────────────────────────────────────
    if (tafseer.isNotEmpty) {
      if (isUrdu) {
        buf.writeln('## 💡 تفسیر (ابنِ کثیر)\n');
      } else if (isRoman) {
        buf.writeln('## 💡 Tafseer — Ibn Kathir\n');
      } else if (isArabic) {
        buf.writeln('## 💡 التفسير — ابن كثير\n');
      } else {
        buf.writeln('## 💡 Tafseer — Ibn Kathir\n');
      }

      for (final t in tafseer) {
        buf.writeln('### 📖 Surah ${t.surahNumber} : Ayah ${t.ayahNumber}\n');

        String text = t.text.trim();

        // Show full tafseer up to 800 chars
        if (text.length > 800) {
          text = '${text.substring(0, 800)}...';
        }

        buf.writeln('> $text\n');
        buf.writeln(
            '📌 *Tafseer Ibn Kathir — ${t.surahNumber}:${t.ayahNumber}*\n');
        buf.writeln('---\n');
      }
    }

    // ── SUMMARY ───────────────────────────────────────────────
    final totalRefs = quran.length + hadiths.length + tafseer.length;

    buf.writeln('## 📊 Summary\n');

    if (isUrdu) {
      buf.writeln('| ذریعہ | تعداد |');
      buf.writeln('|-------|-------|');
      if (quran.isNotEmpty) buf.writeln('| 📖 قرآنی آیات | ${quran.length} |');
      if (hadiths.isNotEmpty) buf.writeln('| 📚 احادیث | ${hadiths.length} |');
      if (tafseer.isNotEmpty) buf.writeln('| 💡 تفسیر | ${tafseer.length} |');
      buf.writeln('| **کل** | **$totalRefs** |');
    } else if (isRoman) {
      buf.writeln('| Source | Count |');
      buf.writeln('|--------|-------|');
      if (quran.isNotEmpty)
        buf.writeln('| 📖 Qurani Ayaat | ${quran.length} |');
      if (hadiths.isNotEmpty) buf.writeln('| 📚 Ahadith | ${hadiths.length} |');
      if (tafseer.isNotEmpty) buf.writeln('| 💡 Tafseer | ${tafseer.length} |');
      buf.writeln('| **Kul** | **$totalRefs** |');
    } else {
      buf.writeln('| Source | Count |');
      buf.writeln('|--------|-------|');
      if (quran.isNotEmpty)
        buf.writeln('| 📖 Quran Verses | ${quran.length} |');
      if (hadiths.isNotEmpty) buf.writeln('| 📚 Hadiths | ${hadiths.length} |');
      if (tafseer.isNotEmpty) buf.writeln('| 💡 Tafseer | ${tafseer.length} |');
      buf.writeln('| **Total** | **$totalRefs** |');
    }

    buf.writeln('');

    // ── Footer ────────────────────────────────────────────────
    if (isUrdu) {
      buf.writeln(
          '\n_🤲 یہ جواب مستند اسلامی ذرائع (قرآن، صحیح احادیث، تفسیر ابنِ کثیر) سے ہے۔ اللہ سب کو ہدایت دے۔ آمین۔_');
    } else if (isRoman) {
      buf.writeln(
          '\n_🤲 Yeh jawab authentic Islamic sources se hai — Quran, Sahih Ahadith, aur Tafseer Ibn Kathir. Allah aap ko hidayat de. Aameen._');
    } else if (isArabic) {
      buf.writeln(
          '\n_🤲 هذه الإجابة من المصادر الإسلامية الأصيلة. هدانا الله وإياكم. آمين._');
    } else {
      buf.writeln(
          '\n_🤲 This answer is from authentic Islamic sources (Quran, Sahih Hadiths, Tafseer Ibn Kathir). May Allah guide us all. Aameen._');
    }

    return buf.toString();
  }

  // ============================================================
  // NO RESULTS RESPONSE
  // ============================================================

  String _noResultsResponse(QueryLanguage lang) {
    if (lang == QueryLanguage.urdu) {
      return '''## ⚠️ کوئی نتیجہ نہیں ملا

معاف کیجیے، میں آپ کے سوال کا جواب اپنے مستند ڈیٹابیس میں نہیں ڈھونڈ سکا۔

**براہ کرم:**
- سوال دوبارہ الفاظ بدل کر پوچھیں
- زیادہ مخصوص سوال کریں
- کسی مستند عالمِ دین سے رجوع کریں

*"جو نہیں جانتا وہ اہلِ علم سے پوچھے"* — قرآن 16:43''';
    }

    if (lang == QueryLanguage.romanUrdu) {
      return '''## ⚠️ Koi Nateeja Nahi Mila

Maaf kijiye, main aap ke sawal ka jawab apne authentic database mein nahi dhoondh saka.

**Please:**
- Sawal dobara alfaz badal kar puchein
- Zyada specific sawal karein  
- Kisi mustanad Aalim-e-Deen se rujoo karein

*"Jo nahi jaanta woh ahl-e-ilm se pooche"* — Quran 16:43''';
    }

    if (lang == QueryLanguage.arabic) {
      return '''## ⚠️ لم يتم العثور على نتيجة

عذراً، لم أتمكن من العثور على إجابة في قاعدة البيانات الإسلامية.

**يرجى:**
- إعادة صياغة السؤال
- طرح سؤال أكثر تحديداً
- الرجوع إلى عالم دين متخصص

*"فَاسْأَلُوا أَهْلَ الذِّكْرِ إِن كُنتُمْ لَا تَعْلَمُونَ"* — القرآن 16:43''';
    }

    return '''## ⚠️ No Results Found

I could not find an answer in my authentic Islamic database.

**Please:**
- Rephrase your question
- Ask a more specific question
- Consult a qualified Islamic scholar

*"Ask the people of knowledge if you do not know"* — Quran 16:43''';
  }

  bool get isReady => _isInitialized;
}
