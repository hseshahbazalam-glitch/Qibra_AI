// lib/features/ai/providers/ai_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';

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

  ChatMessage({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
    this.isTyping = false,
  });

  bool get isUser => role == MessageRole.user;
  bool get isAI => role == MessageRole.ai;
}

// ============================================================
// CHAT PROVIDER
// ============================================================

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  ChatNotifier() : super([]);

  void addUserMessage(String content) {
    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );
    state = [...state, message];
  }

  void addAIMessage(String content) {
    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      role: MessageRole.ai,
      timestamp: DateTime.now(),
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
  }

  // Simulate AI response (Replace with real API later)
  Future<void> sendMessage(String userMessage, {String? context}) async {
    addUserMessage(userMessage);
    addTypingIndicator();

    // Simulate delay
    await Future.delayed(const Duration(seconds: 2));

    removeTypingIndicator();

    // Placeholder response (replace with Gemini/OpenAI API)
    final response = _generateResponse(userMessage, context: context);
    addAIMessage(response);
  }

  String _generateResponse(String message, {String? context}) {
    final lower = message.toLowerCase();

    if (context != null) {
      return 'This ayah teaches us about $context. It reminds us of Allah\'s '
          'infinite wisdom and guidance. May Allah help us understand and '
          'implement these teachings in our daily lives. Ameen. 🤲';
    }

    if (lower.contains('salah') ||
        lower.contains('namaz') ||
        lower.contains('prayer')) {
      return 'Salah is one of the five pillars of Islam. It is performed five '
          'times a day: Fajr (dawn), Dhuhr (noon), Asr (afternoon), Maghrib '
          '(sunset), and Isha (night). Prayer is a direct connection with '
          'Allah SWT. 🕌';
    }

    if (lower.contains('quran')) {
      return 'The Holy Quran is the final revelation from Allah SWT to '
          'Prophet Muhammad ﷺ. It contains 114 Surahs and 6,236 Ayahs, '
          'divided into 30 Juz. Reading Quran daily brings barakah in life. 📖';
    }

    if (lower.contains('zakat')) {
      return 'Zakat is the third pillar of Islam. It is 2.5% of one\'s '
          'wealth given annually to the poor and needy. It purifies wealth '
          'and helps the less fortunate. 💚';
    }

    if (lower.contains('hajj')) {
      return 'Hajj is the pilgrimage to Makkah, performed once in a lifetime '
          'by those who are able. It is the fifth pillar of Islam and takes '
          'place in the month of Dhul Hijjah. 🕋';
    }

    if (lower.contains('fasting') ||
        lower.contains('roza') ||
        lower.contains('ramadan')) {
      return 'Fasting during Ramadan is the fourth pillar of Islam. Muslims '
          'abstain from food, drink, and sinful behavior from dawn to sunset. '
          'It teaches self-discipline and empathy. 🌙';
    }

    return 'Alhamdulillah! Great question. Islam teaches us to seek knowledge '
        'and understand our deen. Let me help you learn more about this topic. '
        'Feel free to ask me anything about Quran, Hadith, or Islamic practices. 🤲';
  }
}

final chatProvider =
    StateNotifierProvider<ChatNotifier, List<ChatMessage>>((ref) {
  return ChatNotifier();
});
