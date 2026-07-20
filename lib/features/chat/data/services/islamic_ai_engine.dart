// lib/features/chat/data/services/islamic_ai_engine.dart

// ============================================================
// QIBRA AI — ISLAMIC KNOWLEDGE ENGINE (v2.0 with Dictionary)
// Custom AI that searches ONLY authentic sources:
// - Quran (Arabic + Urdu + English + Roman Urdu)
// - 34,532 Hadiths (6 Sahih Books)
// - Tafseer Ibn Kathir (Urdu)
// ============================================================

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
  // Priority: Dictionary → Keyword Search
  // ============================================================

  Future<IslamicAnswer> answerQuestion(String question) async {
    if (!_isInitialized) await initialize();

    // 1. Detect language
    final detectedLang = LanguageDetector.detect(question);
    debugPrint(
        '[ISLAMIC_AI] Language: ${LanguageDetector.getName(detectedLang)}');

    // 2. Try Dictionary first (smart topic detection)
    final topic = IslamicDictionary.findTopic(question);

    List<QuranSearchResult> quranResults = [];
    List<LocalSearchResult> hadithResults = [];

    if (topic != null) {
      debugPrint('[ISLAMIC_AI] ✅ Topic matched: ${topic.nameEnglish}');

      // Get exact Quran verses for this topic
      quranResults = _getVersesFromRefs(topic.quranRefs);

      // Search hadith with topic-specific English keywords
      for (final kw in topic.hadithKeywords) {
        final results = _hadithDb.search(kw, maxResults: 2);
        for (final r in results) {
          if (!hadithResults.any((h) => h.hadith.id == r.hadith.id)) {
            hadithResults.add(r);
          }
        }
        if (hadithResults.length >= 3) break;
      }
    } else {
      debugPrint(
          '[ISLAMIC_AI] ⚠️ No topic matched — falling back to keyword search');

      // Fallback: basic keyword search
      quranResults = _quranSearch.search(question, maxResults: 3);
      hadithResults = _hadithDb.search(question, maxResults: 3);
    }

    // 3. Get tafseer for top Quran result
    final tafseerResults = <TafseerAyah>[];
    if (quranResults.isNotEmpty) {
      final top = quranResults.first;
      final tafseer = await _tafseerService.getAyahTafseer(
        top.surahNumber,
        top.ayahNumber,
      );
      if (tafseer != null) tafseerResults.add(tafseer);
    }

    // 4. Format answer
    final formatted = _formatAnswer(
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
      if (result != null) {
        results.add(result);
      }
      if (results.length >= 3) break;
    }

    return results;
  }

  // ============================================================
  // FORMAT ANSWER
  // ============================================================

  String _formatAnswer({
    required String question,
    required QueryLanguage language,
    required List<QuranSearchResult> quran,
    required List<LocalSearchResult> hadiths,
    required List<TafseerAyah> tafseer,
    IslamicTopic? matchedTopic,
  }) {
    final buffer = StringBuffer();
    final responseLang = LanguageDetector.getResponseLanguage(language);

    // ═══════════════════════════════════════════════
    // HEADER
    // ═══════════════════════════════════════════════
    if (responseLang == QueryLanguage.urdu) {
      buffer.writeln('✨ بسم اللہ الرحمٰن الرحیم ✨\n');
    } else if (responseLang == QueryLanguage.arabic) {
      buffer.writeln('✨ بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ ✨\n');
    } else {
      buffer.writeln('✨ **Bismillah ir-Rahman ir-Raheem** ✨\n');
    }

    buffer.writeln('---\n');

    // ═══════════════════════════════════════════════
    // TOPIC BADGE (if matched)
    // ═══════════════════════════════════════════════
    if (matchedTopic != null) {
      if (responseLang == QueryLanguage.romanUrdu ||
          responseLang == QueryLanguage.urdu) {
        buffer.writeln(
            '### 📌 Topic: **${matchedTopic.nameEnglish}** _(${matchedTopic.nameUrdu})_\n');
      } else {
        buffer.writeln('### 📌 Topic: **${matchedTopic.nameEnglish}**\n');
      }
    }

    // Check if any results found
    if (quran.isEmpty && hadiths.isEmpty) {
      return _noResultsResponse(responseLang);
    }

    // ═══════════════════════════════════════════════
    // QURAN SECTION
    // ═══════════════════════════════════════════════
    if (quran.isNotEmpty) {
      if (responseLang == QueryLanguage.urdu) {
        buffer.writeln('## 📖 قرآن کی روشنی میں\n');
      } else if (responseLang == QueryLanguage.romanUrdu) {
        buffer.writeln('## 📖 Quran Ki Roshni Mein\n');
      } else {
        buffer.writeln('## 📖 From the Quran\n');
      }

      for (final ayah in quran.take(3)) {
        buffer.writeln(
            '### 🕌 Surah ${ayah.surahNumber}, Ayah ${ayah.ayahNumber}\n');

        // Arabic
        if (ayah.arabic.isNotEmpty) {
          buffer.writeln('${ayah.arabic}\n');
        }

        // Translation
        buffer.writeln('**Translation:**\n');

        if (responseLang == QueryLanguage.romanUrdu &&
            ayah.romanUrdu.isNotEmpty) {
          buffer.writeln('> ${ayah.romanUrdu}\n');
        } else if (responseLang == QueryLanguage.english &&
            ayah.english.isNotEmpty) {
          buffer.writeln('> ${ayah.english}\n');
        } else if (ayah.urdu.isNotEmpty) {
          buffer.writeln('> ${ayah.urdu}\n');
        } else if (ayah.english.isNotEmpty) {
          buffer.writeln('> ${ayah.english}\n');
        }

        buffer.writeln(
            '📌 *Reference: Quran ${ayah.surahNumber}:${ayah.ayahNumber}*\n');
        buffer.writeln('---\n');
      }
    }

    // ═══════════════════════════════════════════════
    // HADITH SECTION
    // ═══════════════════════════════════════════════
    if (hadiths.isNotEmpty) {
      if (responseLang == QueryLanguage.urdu) {
        buffer.writeln('## 📚 احادیث سے رہنمائی\n');
      } else if (responseLang == QueryLanguage.romanUrdu) {
        buffer.writeln('## 📚 Ahadith Se Rehnumai\n');
      } else {
        buffer.writeln('## 📚 From the Hadith\n');
      }

      for (final result in hadiths.take(3)) {
        final h = result.hadith;

        buffer.writeln('### ✅ ${h.displayReference}\n');
        buffer.writeln('🏷️ *Grade: ${h.grade}*\n');

        String hadithText = '';
        if (responseLang == QueryLanguage.urdu ||
            responseLang == QueryLanguage.romanUrdu) {
          hadithText = h.textUrdu.isNotEmpty ? h.textUrdu : h.textEnglish;
        } else {
          hadithText = h.textEnglish.isNotEmpty ? h.textEnglish : h.textUrdu;
        }

        if (hadithText.isNotEmpty) {
          buffer.writeln('> $hadithText\n');
        }

        buffer.writeln('---\n');
      }
    }

    // ═══════════════════════════════════════════════
    // TAFSEER SECTION
    // ═══════════════════════════════════════════════
    if (tafseer.isNotEmpty) {
      if (responseLang == QueryLanguage.urdu) {
        buffer.writeln('## 💡 تفسیر (ابن کثیر)\n');
      } else {
        buffer.writeln('## 💡 Tafseer (Ibn Kathir)\n');
      }

      for (final t in tafseer) {
        String text = t.text;
        if (text.length > 500) {
          text = '${text.substring(0, 500)}...';
        }
        buffer.writeln('> $text\n');
        buffer.writeln('📌 *Surah ${t.surahNumber}:${t.ayahNumber}*\n');
      }
      buffer.writeln('---\n');
    }

    // ═══════════════════════════════════════════════
    // FOOTER
    // ═══════════════════════════════════════════════
    if (responseLang == QueryLanguage.urdu) {
      buffer.writeln(
          '\n_🤲 یہ جواب مستند اسلامی ذرائع سے ہے۔ اللہ سب کو ہدایت دے۔ آمین۔_');
    } else if (responseLang == QueryLanguage.romanUrdu) {
      buffer.writeln(
          '\n_🤲 Yeh jawab authentic Islamic sources se hai — Quran, Sahih Ahadith, aur Tafseer Ibn Kathir. Allah aap ko hidayat de. Aameen._');
    } else {
      buffer.writeln(
          '\n_🤲 This answer is from authentic Islamic sources (Quran, Sahih Hadiths, Tafseer Ibn Kathir). May Allah guide us all. Aameen._');
    }

    return buffer.toString();
  }

  // ============================================================
  // NO RESULTS FALLBACK
  // ============================================================

  String _noResultsResponse(QueryLanguage lang) {
    if (lang == QueryLanguage.urdu) {
      return '''معاف کیجیے، میں آپ کے سوال کا جواب اپنے authentic database میں نہیں ڈھونڈ سکا۔

براہ کرم:
- سوال دوبارہ الفاظ بدل کر پوچھیں
- زیادہ مخصوص سوال کریں
- کوئی مستند عالم دین سے رجوع کریں

*"جو نہیں جانتا وہ اہل علم سے پوچھے" — Quran 16:43*''';
    }

    if (lang == QueryLanguage.romanUrdu) {
      return '''Maaf kijiye, main aap ke sawal ka jawab apne authentic database mein nahi dhoondh saka.

Please:
- Sawal dobara alfaz badal kar puchein
- Zyada specific sawal karein
- Kisi mustanad Aalim-e-Deen se rujoo karein

*"Jo nahi jaante woh ahl-e-ilm se poochein" — Quran 16:43*''';
    }

    return '''I could not find an answer in my authentic database.

Please:
- Rephrase your question
- Ask a more specific question
- Consult a qualified Islamic scholar

*"Ask the people of knowledge if you do not know" — Quran 16:43*''';
  }

  bool get isReady => _isInitialized;
}
