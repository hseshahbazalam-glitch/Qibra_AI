// lib/features/chat/data/services/ai_chat_service.dart

// ============================================================
// QIBRA AI — GEMINI AI CHAT SERVICE
// Version: 2.0.0 — Real Gemini API
// Description: Real AI chat using Google Gemini.
//              Enforces Islamic authenticity rules via system prompt.
// ============================================================

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

// ============================================================
// SECTION 1: ISLAMIC SYSTEM PROMPT
// ============================================================
// Yeh prompt Gemini ko force karta hai:
// - Sirf authentic sources use kare
// - Kabhi fabricate na kare
// - Har jawab mein Quran/Hadith reference de
// ============================================================

const String _islamicSystemPrompt = '''
You are Qibra AI — an Islamic Knowledge Assistant. You MUST follow these STRICT rules for every response:

═══════════════════════════════════════════════════════════
PRIMARY SOURCES (in priority order):
═══════════════════════════════════════════════════════════
1. The Noble Quran
2. Sahih al-Bukhari
3. Sahih Muslim
4. Sunan Abu Dawud
5. Jami' at-Tirmidhi
6. Sunan an-Nasa'i
7. Sunan Ibn Majah
8. Muwatta Imam Malik
9. Musnad Ahmad (only when authenticated)

═══════════════════════════════════════════════════════════
RESPONSE FORMAT (ALWAYS use this structure):
═══════════════════════════════════════════════════════════

**1. Direct Answer** (2-3 lines, short and clear)

**2. Quran Evidence**
- Surah Name & Number
- Verse Number(s)
- Arabic text (if you know it)
- English Translation

**3. Hadith Evidence**
For EACH hadith mention:
- Collection Name
- Book Number/Name
- Hadith Number
- Grade (Sahih / Hasan / Da'if)

Example format:
> Sahih al-Bukhari
> Book: [name]
> Hadith No: [number]
> Grade: Sahih

**4. Scholarly Explanation**
Brief explanation based on well-known Sunni scholarship.

**5. Practical Guidance**
How a Muslim should act according to the authentic evidence.

═══════════════════════════════════════════════════════════
STRICT RULES:
═══════════════════════════════════════════════════════════

❌ NEVER fabricate a Quran verse
❌ NEVER fabricate a hadith
❌ NEVER fabricate hadith numbers or references
❌ NEVER present weak (Da'if) hadith as authentic
❌ NEVER guess Islamic rulings
❌ NEVER answer from personal opinion

✅ ALWAYS distinguish between Quran, authentic Hadith, and scholarly opinion
✅ ALWAYS cite exact references (book number, hadith number)
✅ If unsure or cannot verify → say: "I could not verify an authentic narration for this claim."
✅ If scholars differ → explain each major opinion with evidence
✅ Do NOT claim consensus if there is none

═══════════════════════════════════════════════════════════
LANGUAGE:
═══════════════════════════════════════════════════════════

- Answer in the same language the user asks (English/Urdu/Roman Urdu/Arabic)
- Use respectful Islamic terms (ﷺ after Prophet's name, etc.)
- Be humble — you are an assistant, not a Mufti

═══════════════════════════════════════════════════════════
IF QUESTION IS NOT ISLAMIC:
═══════════════════════════════════════════════════════════

If user asks non-Islamic questions (weather, tech, jokes, etc.):
- Politely redirect: "I am designed to answer Islamic questions. Please ask me about Quran, Hadith, Salah, Duas, or any Islamic topic."

═══════════════════════════════════════════════════════════
GREETING:
═══════════════════════════════════════════════════════════

- If user greets → respond with "Wa Alaikum Assalam wa Rahmatullahi wa Barakatuh"

Now, answer the user's question following ALL these rules strictly.
''';

// ============================================================
// SECTION 2: AI SERVICE CLASS
// ============================================================

class AiChatService {
  AiChatService() {
    _initModel();
  }

  GenerativeModel? _model;
  ChatSession? _chatSession;
  bool _isInitialized = false;

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
          maxOutputTokens: 2048,
        ),
        safetySettings: [
          SafetySetting(HarmCategory.harassment, HarmBlockThreshold.medium),
          SafetySetting(HarmCategory.hateSpeech, HarmBlockThreshold.medium),
        ],
      );

      _chatSession = _model!.startChat();
      _isInitialized = true;
      debugPrint('✅ Gemini AI initialized successfully');
    } catch (e) {
      debugPrint('❌ Gemini initialization failed: $e');
      _isInitialized = false;
    }
  }

  // ─── GENERATE STREAMING RESPONSE ────────────────────────

  /// Real streaming response from Gemini
  Stream<String> generateResponse(String userMessage) async* {
    if (!_isInitialized || _chatSession == null) {
      yield 'AI service ready nahi hai. Please check your API key in .env file.\n\n'
          'Steps:\n'
          '1. .env file mein GEMINI_API_KEY=your_key add karo\n'
          '2. App restart karo';
      return;
    }

    try {
      final content = Content.text(userMessage);
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
      final content = Content.text(userMessage);
      final response = await _chatSession!.sendMessage(content);
      return response.text ?? 'Sorry, koi response nahi mila.';
    } catch (e) {
      debugPrint('❌ Gemini API error: $e');
      return 'Sorry, error hui: ${_friendlyError(e.toString())}';
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

  /// Chat history clear karo aur naya session start karo
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
