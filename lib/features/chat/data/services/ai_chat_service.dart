// lib/features/chat/data/services/ai_chat_service.dart

// ============================================================
// QIBRA AI — GEMINI AI CHAT SERVICE WITH RAG
// Version: 3.0.0 — RAG Integration (AI + Local Hadith DB)
// Description: Real AI chat using Google Gemini + Local Hadith Search.
//              Uses Retrieval Augmented Generation (RAG) for authentic answers.
// ============================================================

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import '../../../hadith/data/services/hadith_database_service.dart';

// ============================================================
// SECTION 1: ISLAMIC SYSTEM PROMPT WITH RAG
// ============================================================

const String _islamicSystemPrompt = '''
You are Qibra AI — an Islamic Knowledge Assistant with access to a VERIFIED HADITH DATABASE containing 34,532 authentic hadiths from all 6 Kutub al-Sittah.

═══════════════════════════════════════════════════════════
MOST IMPORTANT RULE — LANGUAGE DETECTION:
═══════════════════════════════════════════════════════════

DETECT the user's language and REPLY IN THE SAME LANGUAGE ONLY.

Rules:
- If user writes in Roman Urdu (like "namaz ki fazilat batao") → Reply ENTIRELY in Roman Urdu
- If user writes in English (like "What is Salah?") → Reply ENTIRELY in English
- If user writes in Urdu script (like "نماز کی فضیلت بتاؤ") → Reply ENTIRELY in Urdu script
- If user writes in Arabic → Reply ENTIRELY in Arabic
- If user mixes languages → Use the DOMINANT language

DO NOT mix languages in your response.
DO NOT add Arabic/Urdu translations if user asked in Roman Urdu or English.
ONLY include Arabic text when quoting Quran verses or Hadith Arabic text.

═══════════════════════════════════════════════════════════
ROMAN URDU EXAMPLE RESPONSE:
═══════════════════════════════════════════════════════════

Agar user Roman Urdu mein puchhe, toh aisa jawab do:

"Namaz Islam ka doosra aur sabse ahem rukn hai.

📖 Qurani Saboot:
Surah Al-Baqarah (2:143)
Ayat: وَمَا كَانَ اللَّهُ لِيُضِيعَ إِيمَانَكُمْ
Tarjuma: Allah tumhare iman (namazein) ko zaya nahi karega.

📚 Hadith:
Kitab: Sahih al-Bukhari
Hadith Number: 40
Baab: Iman
Rawi: Hazrat Bara bin Azib (RA)
Matn: Jab Nabi ﷺ Madina tashreef laye..."

═══════════════════════════════════════════════════════════
ENGLISH EXAMPLE RESPONSE:
═══════════════════════════════════════════════════════════

If user asks in English, reply like this:

"Prayer (Salah) is the second and most important pillar of Islam.

📖 Quran Evidence:
Surah Al-Baqarah (2:143)
Verse: وَمَا كَانَ اللَّهُ لِيُضِيعَ إِيمَانَكُمْ
Translation: Allah would never let your faith (prayers) go to waste.

📚 Hadith:
Book: Sahih al-Bukhari
Hadith Number: 40
Chapter: Belief
Narrator: Al-Bara (RA)
Text: When the Prophet ﷺ came to Medina..."

═══════════════════════════════════════════════════════════
HADITH DATABASE RULES:
═══════════════════════════════════════════════════════════

When hadiths are provided as "VERIFIED HADITHS FROM DATABASE:", you MUST:
1. USE ONLY those hadiths in your response
2. Quote exact text as given
3. Use exact book name and hadith number
4. NEVER invent or fabricate hadith numbers
5. NEVER make up hadith text
6. Include hadith Arabic text ONLY as quotation (not as translation)

If NO hadiths found in database:
- Answer from Quran knowledge
- Mention scholarly opinions
- Say "Is topic par humari database mein specific hadith nahi mili" (in user's language)

═══════════════════════════════════════════════════════════
RESPONSE FORMAT (ALL LANGUAGES):
═══════════════════════════════════════════════════════════

1. Seedha Jawab (2-3 lines)

2. Qurani Saboot (if applicable)
   - Surah ka naam aur number
   - Ayat number
   - Arabic text (quotation only)
   - Translation in USER'S language

3. Hadith ke Saboot (from database ONLY)
   For each hadith:
   - Kitab / Book name
   - Hadith Number
   - Baab / Chapter
   - Rawi / Narrator
   - Hadith ka matn in USER'S language
   - Arabic text (as quotation)

4. Ulama ki Tashreeh (brief)

5. Amali Hidayat (practical guidance)

═══════════════════════════════════════════════════════════
STRICT RULES:
═══════════════════════════════════════════════════════════

- NEVER fabricate hadith numbers or text
- NEVER present Da'if hadith as authentic
- NEVER guess Islamic rulings
- If unsure → say so honestly in user's language
- Use ﷺ after Prophet's name
- Be humble — you are assistant, not Mufti

═══════════════════════════════════════════════════════════
NON-ISLAMIC QUESTIONS:
═══════════════════════════════════════════════════════════

Reply in user's language:
Roman Urdu: "Main sirf Islamic sawalat ka jawab de sakta hoon."
English: "I am designed to answer Islamic questions only."
Urdu: "میں صرف اسلامی سوالات کا جواب دے سکتا ہوں۔"

═══════════════════════════════════════════════════════════
GREETINGS:
═══════════════════════════════════════════════════════════

Any salam → "Wa Alaikum Assalam wa Rahmatullahi wa Barakatuh"
Then continue in user's language.

Now answer the user's question strictly following ALL these rules.
''';

// ============================================================
// SECTION 2: AI SERVICE CLASS
// ============================================================

class AiChatService {
  AiChatService({HadithDatabaseService? hadithDb}) : _hadithDb = hadithDb {
    _initModel();
  }

  GenerativeModel? _model;
  ChatSession? _chatSession;
  bool _isInitialized = false;

  // RAG: Local hadith database
  final HadithDatabaseService? _hadithDb;

  // ─── INITIALIZE MODEL ───────────────────────────────────

  void _initModel() {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];

      if (apiKey == null || apiKey.isEmpty) {
        debugPrint('❌ GEMINI_API_KEY not found in .env');
        _isInitialized = false;
        return;
      }

      _model = GenerativeModel(
        model: 'gemini-flash-latest',
        apiKey: apiKey,
        systemInstruction: Content.system(_islamicSystemPrompt),
        generationConfig: GenerationConfig(
          temperature: 0.7,
          topK: 40,
          topP: 0.95,
          maxOutputTokens: 8192,
        ),
        safetySettings: [
          SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
        ],
      );

      _chatSession = _model!.startChat();
      _isInitialized = true;
      debugPrint('✅ Gemini AI + RAG initialized');
    } catch (e) {
      debugPrint('❌ Gemini initialization failed: $e');
      _isInitialized = false;
    }
  }

  // ─── SEARCH RELEVANT HADITHS (RAG) ──────────────────────

  /// Extract keywords from user query and search hadith database
  /// Returns formatted context for AI
  String _retrieveRelevantHadiths(String userMessage) {
    if (_hadithDb == null || !_hadithDb.isInitialized) {
      debugPrint('[RAG] Database not ready');
      return '';
    }

    // Extract key Islamic terms from message
    final searchQueries = _extractSearchQueries(userMessage);

    if (searchQueries.isEmpty) return '';

    debugPrint('[RAG] Searching for: $searchQueries');

    final allResults = <String>{};
    final relevantHadiths = <LocalSearchResult>[];

    for (final query in searchQueries) {
      final results = _hadithDb.search(query, maxResults: 3);
      for (final result in results) {
        if (allResults.add(result.hadith.id)) {
          relevantHadiths.add(result);
          if (relevantHadiths.length >= 3) break;
        }
      }
      if (relevantHadiths.length >= 3) break;
    }

    if (relevantHadiths.isEmpty) {
      debugPrint('[RAG] No hadiths found');
      return '';
    }

    debugPrint('[RAG] Found ${relevantHadiths.length} relevant hadiths');

    // Format for AI
    final buffer = StringBuffer();
    buffer.writeln('\n\n═══════════════════════════════════════');
    buffer.writeln('VERIFIED HADITHS FROM DATABASE:');
    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln('');

    for (int i = 0; i < relevantHadiths.length; i++) {
      final h = relevantHadiths[i].hadith;
      buffer.writeln('--- Hadith ${i + 1} ---');
      buffer.writeln('Book: ${h.bookName}');
      buffer.writeln('Hadith Number: ${h.hadithNumber}');
      buffer.writeln('Chapter: ${h.chapterName}');
      if (h.grade.isNotEmpty) buffer.writeln('Grade: ${h.grade}');
      if (h.hasArabic) buffer.writeln('Arabic: ${h.textArabic}');
      buffer.writeln('English: ${h.textEnglish}');
      if (h.hasUrdu) buffer.writeln('Urdu: ${h.textUrdu}');
      buffer.writeln('');
    }

    buffer.writeln('═══════════════════════════════════════');
    buffer.writeln(
      'USE ONLY THESE VERIFIED HADITHS above in your response.',
    );
    buffer.writeln('Do not invent or add other hadith numbers.');
    buffer.writeln('═══════════════════════════════════════\n');

    return buffer.toString();
  }

  /// Extract meaningful search queries from user message
  List<String> _extractSearchQueries(String message) {
    final queries = <String>[];
    final lower = message.toLowerCase();

    // Islamic topic keywords mapping
    final topics = {
      'salah': ['prayer', 'salah', 'namaz'],
      'prayer': ['prayer', 'salah'],
      'namaz': ['prayer', 'salah'],
      'zakat': ['zakat', 'charity'],
      'charity': ['charity', 'zakat', 'sadaqah'],
      'sadaqah': ['charity', 'sadaqah'],
      'ramadan': ['ramadan', 'fasting'],
      'fasting': ['fasting', 'ramadan', 'sawm'],
      'roza': ['fasting', 'ramadan'],
      'hajj': ['hajj', 'pilgrimage'],
      'pilgrimage': ['pilgrimage', 'hajj'],
      'quran': ['quran', 'recitation'],
      'dua': ['supplication', 'dua'],
      'supplication': ['supplication', 'dua'],
      'wudu': ['ablution', 'wudu'],
      'ablution': ['ablution', 'wudu'],
      'faith': ['faith', 'iman', 'belief'],
      'iman': ['faith', 'iman'],
      'jannah': ['paradise', 'jannah'],
      'paradise': ['paradise', 'jannah'],
      'jahannam': ['hellfire', 'hell'],
      'hellfire': ['hellfire', 'hell'],
      'prophet': ['prophet', 'messenger'],
      'muhammad': ['muhammad', 'prophet'],
      'knowledge': ['knowledge', 'learning'],
      'patience': ['patience', 'sabr'],
      'sabr': ['patience', 'sabr'],
      'kindness': ['kindness', 'mercy'],
      'mercy': ['mercy', 'compassion'],
      'anger': ['anger'],
      'ghussa': ['anger'],
      'silence': ['silence'],
      'khamosh': ['silence'],
      'good word': ['good word', 'speak good'],
      'achi baat': ['good word'],
    };

    // Check for topic matches
    for (final entry in topics.entries) {
      if (lower.contains(entry.key)) {
        queries.addAll(entry.value);
      }
    }

    // Also add original message keywords (3+ chars)
    final words = message
        .split(RegExp(r'\s+'))
        .where((w) => w.length >= 4)
        .map((w) => w.toLowerCase().replaceAll(RegExp(r'[^\w]'), ''))
        .toList();

    // Filter common words
    final stopWords = {
      'what',
      'how',
      'when',
      'where',
      'why',
      'the',
      'is',
      'are',
      'was',
      'were',
      'kya',
      'kaise',
      'kaisi',
      'kaisa',
      'kab',
      'kahan',
      'kyun',
      'kar',
      'mein',
      'hai',
      'ho',
      'aap',
      'tell',
      'about',
      'give',
      'please',
      'thank',
      'islam'
    };

    for (final word in words) {
      if (word.length >= 4 && !stopWords.contains(word)) {
        queries.add(word);
      }
    }

    // Deduplicate and limit
    return queries.toSet().take(5).toList();
  }

  // ─── GENERATE STREAMING RESPONSE ────────────────────────

  /// Real streaming response with RAG
  Stream<String> generateResponse(String userMessage) async* {
    if (!_isInitialized || _chatSession == null) {
      yield 'AI service ready nahi hai. Please check your API key in .env file.';
      return;
    }

    try {
      // 🔍 RAG: Retrieve relevant hadiths from local DB
      final hadithContext = _retrieveRelevantHadiths(userMessage);

      // 📝 Combine user message + hadith context
      final augmentedMessage = userMessage + hadithContext;

      // 🤖 Send to Gemini
      final content = Content.text(augmentedMessage);
      final responseStream = _chatSession!.sendMessageStream(content);

      final buffer = StringBuffer();
      await for (final chunk in responseStream) {
        final text = chunk.text ?? '';
        buffer.write(text);
        yield buffer.toString();
      }
    } catch (e) {
      debugPrint('❌ Gemini API error: $e');
      yield 'Sorry, kuch problem hui.\n\n'
          'Error: ${_friendlyError(e.toString())}\n\n'
          'Please try again.';
    }
  }

  // ─── GET FULL RESPONSE (non-streaming) ──────────────────

  Future<String> getResponse(String userMessage) async {
    if (!_isInitialized || _chatSession == null) {
      return 'AI service ready nahi hai. Check .env file.';
    }

    try {
      final hadithContext = _retrieveRelevantHadiths(userMessage);
      final augmentedMessage = userMessage + hadithContext;

      final content = Content.text(augmentedMessage);
      final response = await _chatSession!.sendMessage(content);
      return response.text ?? 'Sorry, koi response nahi mila.';
    } catch (e) {
      debugPrint('❌ Gemini API error: $e');
      return 'Sorry, error: ${_friendlyError(e.toString())}';
    }
  }

  // ─── ERROR FORMATTING ───────────────────────────────────

  String _friendlyError(String error) {
    if (error.contains('API_KEY_INVALID') ||
        error.contains('API key not valid')) {
      return 'API key invalid hai. .env file mein sahi key daalein.';
    }
    if (error.contains('quota') || error.contains('QUOTA')) {
      return 'Daily quota khatam ho gayi. Kal try karein.';
    }
    if (error.contains('network') || error.contains('SocketException')) {
      return 'Internet connection check karein.';
    }
    if (error.contains('timeout')) {
      return 'Request timeout hui. Try again.';
    }
    return 'Unknown error. Please try again.';
  }

  // ─── RESET SESSION ──────────────────────────────────────

  void reset() {
    if (_model != null) {
      _chatSession = _model!.startChat();
      debugPrint('🔄 Chat session reset');
    }
  }

  // ─── DISPOSE ────────────────────────────────────────────

  void dispose() {
    _chatSession = null;
    _model = null;
    _isInitialized = false;
  }
}
