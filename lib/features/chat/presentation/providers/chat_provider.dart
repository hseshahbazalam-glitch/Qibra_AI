// lib/features/chat/presentation/providers/chat_provider.dart

// ============================================================
// QIBRA AI — CHAT PROVIDER
// Version: 2.0.0 — RAG Integration with global Hadith DB
// ============================================================

import 'dart:async';
import 'package:qibra_ai/main.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qibra_ai/main.dart' show globalHadithDb;

import '../../data/services/ai_chat_service.dart';
import '../../domain/models/chat_models.dart';

// ============================================================
// SECTION 1: AI SERVICE PROVIDER
// ============================================================

/// AI Chat Service singleton
/// Uses global Hadith DB from main.dart for RAG
final aiChatServiceProvider = Provider<AiChatService>((ref) {
  final service = AiChatService();

  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

// ============================================================
// SECTION 2: CHAT NOTIFIER
// ============================================================

class ChatNotifier extends StateNotifier<ChatState> {
  ChatNotifier(this._service) : super(ChatState.initial()) {
    _addWelcomeMessage();
  }

  final AiChatService _service;
  StreamSubscription<String>? _currentStream;

  // ─── WELCOME MESSAGE ────────────────────────────────────

  void _addWelcomeMessage() {
    final welcome = ChatMessage.ai(
      content: 'Assalamu Alaikum wa Rahmatullahi wa Barakatuh! 🌙\n\n'
          'Main **QIBRA AI** hoon — aapka Islamic assistant.\n\n'
          'Aap mujhse yeh sab pooch sakte hain:\n'
          '• Quran ke baare mein\n'
          '• Hadith ka matlab\n'
          '• Namaz ka tareeqa\n'
          '• Duain aur ibadat\n'
          '• Islamic history\n\n'
          'Kya aap kuch poochna chahenge? 🤲',
    );

    state = state.copyWith(messages: [welcome]);
  }

  // ─── SEND MESSAGE ───────────────────────────────────────

  Future<void> sendMessage(String content) async {
    if (content.trim().isEmpty) return;
    if (state.isGenerating) return;

    // 1. User message add karo
    final userMessage = ChatMessage.user(content: content.trim());
    final updatedMessages = [...state.messages, userMessage];

    // 2. Thinking indicator add karo
    final thinkingMessage = ChatMessage.thinking();
    state = state.copyWith(
      messages: [...updatedMessages, thinkingMessage],
      isGenerating: true,
      clearError: true,
    );

    try {
      // 3. AI response stream karo
      final aiMessageId = DateTime.now().millisecondsSinceEpoch.toString();
      String accumulatedContent = '';

      _currentStream = _service.generateResponse(content).listen(
        (partialResponse) {
          accumulatedContent = partialResponse;

          final aiMessage = ChatMessage(
            id: aiMessageId,
            content: accumulatedContent,
            sender: MessageSender.ai,
            status: MessageStatus.streaming,
            timestamp: DateTime.now(),
          );

          final messages = [...state.messages];
          messages.removeLast();
          messages.add(aiMessage);

          state = state.copyWith(messages: messages);
        },
        onDone: () {
          final messages = [...state.messages];
          if (messages.isNotEmpty) {
            final lastMessage = messages.last;
            messages[messages.length - 1] = lastMessage.copyWith(
              status: MessageStatus.sent,
            );
          }

          state = state.copyWith(
            messages: messages,
            isGenerating: false,
          );
        },
        onError: (error) {
          _handleError(error.toString());
        },
      );
    } catch (e) {
      _handleError(e.toString());
    }
  }

  // ─── ERROR HANDLING ─────────────────────────────────────

  void _handleError(String error) {
    debugPrint('[CHAT] Error: $error');

    final messages = [...state.messages];
    if (messages.isNotEmpty && messages.last.isThinking) {
      messages.removeLast();
    }

    final errorMessage = ChatMessage.error(errorMessage: error);
    messages.add(errorMessage);

    state = state.copyWith(
      messages: messages,
      isGenerating: false,
      error: error,
    );
  }

  // ─── STOP GENERATION ────────────────────────────────────

  void stopGeneration() {
    _currentStream?.cancel();
    _currentStream = null;

    final messages = [...state.messages];
    if (messages.isNotEmpty && messages.last.isThinking) {
      messages.removeLast();
    }

    state = state.copyWith(
      messages: messages,
      isGenerating: false,
    );
  }

  // ─── CLEAR CHAT ─────────────────────────────────────────

  void clearChat() {
    _currentStream?.cancel();
    state = ChatState.initial();
    _addWelcomeMessage();
  }

  // ─── DELETE MESSAGE ─────────────────────────────────────

  void deleteMessage(String messageId) {
    final messages = state.messages.where((m) => m.id != messageId).toList();
    state = state.copyWith(messages: messages);
  }

  // ─── DISPOSE ────────────────────────────────────────────

  @override
  void dispose() {
    _currentStream?.cancel();
    super.dispose();
  }
}

// ============================================================
// SECTION 3: MAIN CHAT PROVIDER
// ============================================================

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final service = ref.watch(aiChatServiceProvider);
  return ChatNotifier(service);
});

// ============================================================
// SECTION 4: CONVENIENCE PROVIDERS
// ============================================================

final chatMessagesProvider = Provider<List<ChatMessage>>((ref) {
  return ref.watch(chatProvider).messages;
});

final isGeneratingProvider = Provider<bool>((ref) {
  return ref.watch(chatProvider).isGenerating;
});

final chatMessageCountProvider = Provider<int>((ref) {
  return ref.watch(chatProvider).messageCount;
});

final lastMessageProvider = Provider<ChatMessage?>((ref) {
  return ref.watch(chatProvider).lastMessage;
});

final chatErrorProvider = Provider<String?>((ref) {
  return ref.watch(chatProvider).error;
});
