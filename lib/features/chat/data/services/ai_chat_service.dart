// lib/features/chat/data/services/ai_chat_service.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';

import 'islamic_ai_engine.dart';
import 'language_detector.dart';

const String _rephraseSystemPrompt = '''
You are a helpful assistant that ONLY reformats and beautifies Islamic answers.

STRICT RULES:
1. NEVER add new information, verses, or hadiths
2. NEVER remove any Quran reference, hadith reference, or grade
3. NEVER change the meaning of any content
4. Keep ALL Arabic text exactly as provided
5. Keep ALL Urdu/Roman Urdu text exactly as provided
6. Only improve flow, add nice line breaks, and make it easier to read
7. If input contains "Quran X:Y" or "Sahih al-Bukhari NNNN" — KEEP THESE EXACTLY
8. Respond in the SAME language as the input answer
9. Do NOT add opinions or interpretations
10. Do NOT add any new hadiths or verses

Your job: Take the answer and present it more beautifully. That's it.
''';

class AiChatService {
  AiChatService() {
    _initModel();
  }

  final IslamicAIEngine _islamicEngine = IslamicAIEngine.instance;
  GenerativeModel? _model;
  bool _geminiReady = false;
  bool _enhanceWithGemini = false;

  void _initModel() {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'] ?? '';

      if (apiKey.isEmpty) {
        debugPrint('[AI] No Gemini API key - using local only');
        _geminiReady = false;
        return;
      }

      _model = GenerativeModel(
        model: 'gemini-flash-latest',
        apiKey: apiKey,
        systemInstruction: Content.system(_rephraseSystemPrompt),
        generationConfig: GenerationConfig(
          temperature: 0.3,
          maxOutputTokens: 2000,
        ),
      );

      _geminiReady = true;
      debugPrint('[AI] Gemini ready (rephrase mode)');
    } catch (e) {
      debugPrint('[AI] Gemini init failed: $e');
      _geminiReady = false;
    }
  }

  Stream<String> generateResponse(String userMessage) async* {
    try {
      if (!_islamicEngine.isReady) {
        await _islamicEngine.initialize();
      }

      debugPrint('[AI] Searching local sources...');
      final islamicAnswer = await _islamicEngine.answerQuestion(userMessage);

      debugPrint('[AI] Found: ${islamicAnswer.quranResults.length} Quran, '
          '${islamicAnswer.hadithResults.length} Hadith, '
          '${islamicAnswer.tafseerResults.length} Tafseer');

      if (islamicAnswer.totalSources == 0) {
        yield islamicAnswer.formattedAnswer;
        return;
      }

      if (!_geminiReady || !_enhanceWithGemini || _model == null) {
        yield* _simulateStream(islamicAnswer.formattedAnswer);
        return;
      }

      final languageName =
          LanguageDetector.getName(islamicAnswer.detectedLanguage);
      final rephrasePrompt = '''
Original user question: "$userMessage"
User language: $languageName

Islamic answer to beautify (KEEP all references, verses, hadiths, and grades EXACTLY):

${islamicAnswer.formattedAnswer}

Now present this more beautifully. Keep everything. Just improve readability.
''';

      debugPrint('[AI] Enhancing with Gemini...');

      try {
        final content = Content.text(rephrasePrompt);
        final stream = _model!.generateContentStream([content]);

        String accumulated = '';
        await for (final chunk in stream) {
          if (chunk.text != null && chunk.text!.isNotEmpty) {
            accumulated += chunk.text!;
            yield accumulated;
          }
        }

        if (accumulated.trim().isEmpty) {
          yield* _simulateStream(islamicAnswer.formattedAnswer);
        }
      } catch (e) {
        debugPrint('[AI] Gemini enhancement failed: $e');
        yield* _simulateStream(islamicAnswer.formattedAnswer);
      }
    } catch (e) {
      debugPrint('[AI] Error: $e');
      yield 'Sorry, an error occurred. Please try again.';
    }
  }

  Future<String> getResponse(String userMessage) async {
    try {
      if (!_islamicEngine.isReady) {
        await _islamicEngine.initialize();
      }

      final islamicAnswer = await _islamicEngine.answerQuestion(userMessage);
      return islamicAnswer.formattedAnswer;
    } catch (e) {
      debugPrint('[AI] Error: $e');
      return 'An error occurred. Please try again.';
    }
  }

  Stream<String> _simulateStream(String text) async* {
    final words = text.split(' ');
    String accumulated = '';

    for (int i = 0; i < words.length; i++) {
      accumulated += (i == 0 ? '' : ' ') + words[i];

      if (i % 3 == 0 || i == words.length - 1) {
        yield accumulated;
        await Future.delayed(const Duration(milliseconds: 20));
      }
    }
  }

  void setGeminiEnhancement(bool enabled) {
    _enhanceWithGemini = enabled;
  }

  bool get isReady => _islamicEngine.isReady;

  Map<String, dynamic> get stats => {
        'localEngineReady': _islamicEngine.isReady,
        'geminiReady': _geminiReady,
        'enhancementEnabled': _enhanceWithGemini,
      };

  void dispose() {
    // Cleanup if needed
  }
}
