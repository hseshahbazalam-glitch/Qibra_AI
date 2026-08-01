// lib/features/ai/providers/ai_provider.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../services/ai_action_service.dart';
// ============================================================
// MESSAGE MODEL
// ============================================================

enum MessageRole { user, ai, system }

class ChatMessage {
  final String id;
  final String content;
  final MessageRole role;
  final DateTime timestamp;
  final bool isTyping;
  final bool isActionResult;
  final bool actionSuccess;

  ChatMessage({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
    this.isTyping = false,
    this.isActionResult = false,
    this.actionSuccess = true,
  });

  bool get isUser => role == MessageRole.user;
  bool get isAI => role == MessageRole.ai;
}

// ============================================================
// SYSTEM PROMPT
// ============================================================

String _buildSystemPrompt(String userName) {
  return '''
You are Qibra AI — an advanced Islamic assistant AND app controller.

USER NAME: $userName
Address them by name naturally when appropriate.

LANGUAGE RULES:
- Detect user's language automatically
- Reply in the SAME language they wrote in
- Roman Urdu, English, Urdu, Arabic, Hindi — all supported

YOU CAN DO TWO THINGS:
1. Answer Islamic questions (Quran, Hadith, prayers)
2. Control the app (execute actions via JSON)

AVAILABLE ACTIONS:

NOTIFICATION ACTIONS:
- SET_TAHAJJUD_ALARM (params: time in HH:MM format)
- SET_MORNING_ADHKAR (no params)
- SET_EVENING_ADHKAR (no params)
- SET_JUMMAH_REMINDER (no params)
- CANCEL_ALL_NOTIFICATIONS (no params)
- TEST_NOTIFICATION (no params)

NAVIGATION ACTIONS:
- OPEN_QURAN
- OPEN_PRAYER
- OPEN_QIBLA
- OPEN_HADITH
- OPEN_TASBIH
- OPEN_ZAKAT
- OPEN_INHERITANCE
- OPEN_HABITS
- OPEN_SETTINGS
- OPEN_HOME

HOW TO RESPOND:

For Islamic Questions: Answer normally with Quran/Hadith references.

For Action Commands: Return ONLY this JSON format:
{
  "action": "ACTION_NAME",
  "params": {"key": "value"},
  "reply": "Short confirmation with user name"
}

EXAMPLES:

User: "Tahajjud 2 baje ka alarm laga do"
Response: {"action": "SET_TAHAJJUD_ALARM", "params": {"time": "02:00"}, "reply": "$userName, Tahajjud alarm 2:00 AM ke liye set kar diya"}

User: "Quran kholo"
Response: {"action": "OPEN_QURAN", "params": {}, "reply": "$userName, Quran open kar raha hoon"}

User: "namaz kaise padhein"
Response: Assalamu Alaikum $userName! Namaz ka tareeqa:
1. Wudu karein
2. Qibla ki taraf mun karein
3. Niyyat karein
Reference: Sahih Bukhari 631

TIME PARSING:
- "2 baje" means "02:00"
- "5 AM" means "05:00"
- "subah 6 baje" means "06:00"
- "3 baje raat" means "03:00"

CRITICAL RULES:
1. For ACTIONS: Return ONLY JSON, no extra text
2. For QUESTIONS: Answer normally with references
3. NEVER fabricate Quran/Hadith
4. Cite sources properly
5. Use user's name naturally
6. Match user's language exactly

ISLAMIC ETIQUETTE:
- Use symbol after Prophet Muhammad's name
- Use (RA) after Sahaba names
- Use (AS) after Prophets
- Use SubhanAllah, Alhamdulillah, InshaAllah naturally
''';
}

// ============================================================
// CHAT PROVIDER
// ============================================================

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  ChatNotifier() : super([]);

  final List<Map<String, String>> _conversationHistory = [];
  String _userName = 'User';

  void setUserName(String name) {
    _userName = name;
  }

  void addUserMessage(String content) {
    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );
    state = [...state, message];
  }

  void addAIMessage(String content,
      {bool isActionResult = false, bool actionSuccess = true}) {
    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      role: MessageRole.ai,
      timestamp: DateTime.now(),
      isActionResult: isActionResult,
      actionSuccess: actionSuccess,
    );
    state = [...state, message];
  }

  void addTypingIndicator() {
    final message = ChatMessage(
      id: 'typing',
      content: '...',
      role: MessageRole.ai,
      timestamp: DateTime.now(),
      isTyping: true,
    );
    state = [...state, message];
  }

  void removeTypingIndicator() {
    state = state.where((m) => m.id != 'typing').toList();
  }

  void clearChat() {
    state = [];
    _conversationHistory.clear();
  }

  Future<void> sendMessage(String userMessage, {String? context}) async {
    addUserMessage(userMessage);
    addTypingIndicator();

    try {
      final apiKey = dotenv.env['GROQ_API_KEY'] ?? '';

      if (apiKey.isEmpty) {
        removeTypingIndicator();
        addAIMessage('AI service not configured.');
        return;
      }

      String finalMessage = userMessage;
      if (context != null) {
        finalMessage = 'Context: $context. Question: $userMessage';
      }

      _conversationHistory.add({
        'role': 'user',
        'content': finalMessage,
      });

      if (_conversationHistory.length > 20) {
        _conversationHistory.removeRange(0, _conversationHistory.length - 20);
      }

      final messages = [
        {'role': 'system', 'content': _buildSystemPrompt(_userName)},
        ..._conversationHistory,
      ];

      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': messages,
          'temperature': 0.5,
          'max_tokens': 1500,
          'top_p': 0.9,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final aiResponse = data['choices'][0]['message']['content'] as String;

        _conversationHistory.add({
          'role': 'assistant',
          'content': aiResponse,
        });

        removeTypingIndicator();
        await _handleAIResponse(aiResponse);
      } else {
        removeTypingIndicator();
        addAIMessage('Something went wrong. Please try again.');
        debugPrint('AI Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      removeTypingIndicator();
      addAIMessage('Something went wrong. Please try again.');
      debugPrint('AI Error: $e');
    }
  }

  Future<void> _handleAIResponse(String response) async {
    final jsonMatch = _extractJson(response);

    if (jsonMatch != null) {
      try {
        final actionData = jsonDecode(jsonMatch) as Map<String, dynamic>;
        final action = actionData['action'] as String?;
        final params = actionData['params'] as Map<String, dynamic>? ?? {};

        if (action != null) {
          final result = await AIActionService().executeAction({
            'action': action,
            'params': params,
          });

          if (result.success) {
            addAIMessage(
              result.message,
              isActionResult: true,
              actionSuccess: true,
            );
          } else {
            addAIMessage(
              result.message,
              isActionResult: true,
              actionSuccess: false,
            );
          }
          return;
        }
      } catch (e) {
        debugPrint('JSON parse error: $e');
      }
    }

    addAIMessage(response);
  }

  String? _extractJson(String text) {
    // Try to find JSON in code block first
    final codeBlockRegex = RegExp(r'```(?:json)?\s*(\{[\s\S]*?\})\s*```');
    final codeMatch = codeBlockRegex.firstMatch(text);
    if (codeMatch != null) {
      return codeMatch.group(1);
    }

    // Better: Find complete JSON by counting braces
    final startIndex = text.indexOf('{');
    if (startIndex == -1) return null;

    int braceCount = 0;
    int endIndex = -1;

    for (int i = startIndex; i < text.length; i++) {
      if (text[i] == '{') braceCount++;
      if (text[i] == '}') {
        braceCount--;
        if (braceCount == 0) {
          endIndex = i;
          break;
        }
      }
    }

    if (endIndex == -1) return null;

    final jsonStr = text.substring(startIndex, endIndex + 1);

    // Verify it has "action" field
    if (jsonStr.contains('"action"')) {
      return jsonStr;
    }

    return null;
  }
}

final chatProvider =
    StateNotifierProvider<ChatNotifier, List<ChatMessage>>((ref) {
  return ChatNotifier();
});
