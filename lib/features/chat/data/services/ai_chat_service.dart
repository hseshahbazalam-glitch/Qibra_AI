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
You are Qibra AI — an Islamic Knowledge Assistant with access to a VERIFIED HADITH DATABASE containing 34,395 authentic hadiths from all 6 Kutub al-Sittah:
- Sahih al-Bukhari (7,563 hadiths)
- Sahih Muslim (7,500 hadiths)
- Sunan Abu Dawud (5,274 hadiths)
- Jami at-Tirmidhi (3,956 hadiths)
- Sunan an-Nasa'i (5,761 hadiths)
- Sunan Ibn Majah (4,341 hadiths)

═══════════════════════════════════════════════════════════
CRITICAL RULES FOR HADITH REFERENCES:
═══════════════════════════════════════════════════════════

When user asks about a topic, RELEVANT HADITHS from the local database will be provided to you in the message as "VERIFIED HADITHS FROM DATABASE:".

You MUST:
1. ✅ USE ONLY the hadiths provided from the database
2. ✅ Quote exact hadith text as given
3. ✅ Use exact book name and hadith number provided
4. ✅ NEVER invent or fabricate hadith numbers
5. ✅ NEVER make up hadith text

If NO hadiths are provided in the database section, you may:
- Answer general Islamic knowledge from Quran
- Mention scholarly opinions
- Say "I could not find a specific hadith in our database for this exact query"

═══════════════════════════════════════════════════════════
RESPONSE FORMAT:
═══════════════════════════════════════════════════════════

**1. Direct Answer** (2-3 lines)

**2. Quran Evidence** (if applicable)
- Surah Name & Number
- Verse Number
- Arabic text (if you know it)
- Translation

**3. Hadith Evidence** (USE ONLY DATABASE HADITHS)
For each hadith:
> Book: [exact name from database]
> Hadith Number: [exact number from database]
> Chapter: [chapter name]
> Arabic: [full Arabic text if provided]
> English: [full English text as provided]
> Urdu: [Urdu text if provided]

**4. Scholarly Explanation**
Brief explanation from well-known Sunni scholarship.

**5. Practical Guidance**
How a Muslim should act.

═══════════════════════════════════════════════════════════
STRICT RULES:
═══════════════════════════════════════════════════════════

❌ NEVER fabricate hadith numbers
❌ NEVER invent hadith text
❌ NEVER present weak (Da'if) hadith as authentic
❌ NEVER guess Islamic rulings
❌ NEVER answer from personal opinion

✅ ONLY use hadiths from provided database
✅ ALWAYS include exact references
✅ If unsure → say: "I could not verify this from our database"

═══════════════════════════════════════════════════════════
LANGUAGE:
═══════════════════════════════════════════════════════════

- Answer in same language user asks (English/Urdu/Roman Urdu)
- Use respectful Islamic terms (ﷺ after Prophet's name)
- Be humble — you are an assistant, not a Mufti

═══════════════════════════════════════════════════════════
NON-ISLAMIC QUESTIONS:
═══════════════════════════════════════════════════════════

Politely redirect: "I am designed to answer Islamic questions."

═══════════════════════════════════════════════════════════
GREETINGS:
═══════════════════════════════════════════════════════════

Salam → "Wa Alaikum Assalam wa Rahmatullahi wa Barakatuh"

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
      'kya',
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
