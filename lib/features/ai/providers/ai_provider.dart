// lib/features/ai/providers/ai_provider.dart

import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/api_client.dart';
import '../services/ai_action_service.dart';
import '../services/rag_service.dart';
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
// CHAT PROVIDER
// ============================================================

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  ChatNotifier() : super([]);

  final List<Map<String, String>> _conversationHistory = [];
  String _userName = 'User';

  /// Level 1 — streaming typewriter surface. The in-flight backend answer
  /// accumulates here (SSE deltas); the screen renders it into the typing
  /// bubble while it grows. Always reset to '' when an answer lands.
  final ValueNotifier<String> liveAnswer = ValueNotifier<String>('');
  // Phase 7: Last RAG passages for citation verification
  List<RetrievedPassage> _lastRetrieved = [];

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
    liveAnswer.value = '';
  }

  // Phase 1 — GROQ SECURITY: Production must NOT call Groq directly.
  // Backend: POST {AppApi.apiUrl}{AppApi.endpointAiAsk} via ApiClient —
  // today that is https://qibra-ai.onrender.com/ai/ask (docs/DEPLOY.md).
  // Groq secret lives ONLY on backend. No client-side Groq.
  Future<void> sendMessage(String userMessage, {String? context}) async {
    addUserMessage(userMessage);
    addTypingIndicator();

    try {
      var offline = false;
      try {
        final conn = await Connectivity().checkConnectivity();
        offline = conn.contains(ConnectivityResult.none) || conn.isEmpty;
      } catch (_) {}

      String finalMessage = userMessage;
      if (context != null) {
        finalMessage = 'Context: $context. Question: $userMessage';
      }

      // RAG — local keyword retrieve (works offline). Never invent passages.
      String ragContext = '';
      try {
        ragContext =
            await RagService.instance.buildContextForQuery(userMessage);
        _lastRetrieved =
            await RagService.instance.retrieve(userMessage, topK: 3);
      } catch (_) {
        _lastRetrieved = [];
      }

      final actionish = _isActionCommand(userMessage);
      if (!actionish &&
          (ragContext.startsWith('REFUSE:') || _lastRetrieved.isEmpty)) {
        removeTypingIndicator();
        addAIMessage(
          'I could not find a retrieved Quran or Hadith passage for that. I will not invent one.',
        );
        return;
      }

      // Offline / backend disabled: honest extractive passthrough of the
      // local retrieval — never a fabricated answer (phase-1 rule, kept).
      if (!actionish && (offline || !AppApi.isBackendEnabled)) {
        removeTypingIndicator();
        final buffer = StringBuffer(
          'Retrieved local passages (not independently verified):\n',
        );
        for (final passage in _lastRetrieved) {
          buffer.writeln('${passage.source}: ${passage.text}');
        }
        addAIMessage(buffer.toString().trim());
        return;
      }

      _conversationHistory.add({
        'role': 'user',
        'content': finalMessage,
      });

      if (_conversationHistory.length > 20) {
        _conversationHistory.removeRange(0, _conversationHistory.length - 20);
      }

      // Phase 1 GROQ SECURITY still holds: no client-side Groq call. The
      // grounded prompt + Groq key live on the backend (docs/DEPLOY.md);
      // this client sends {query, corpus, history, stream} only.
      if (!AppApi.isBackendEnabled) {
        removeTypingIndicator();
        addAIMessage(
          'AI service runs via the Qibra backend (https://qibra-ai.onrender.com) '
          'which is not enabled in this build. '
          'Your Quran, Prayer, and Duas work fully offline. Please try AI when backend is available.',
        );
        return;
      }

      if (offline) {
        removeTypingIndicator();
        addAIMessage('No internet connection. AI requires internet.');
        return;
      }

      final historyForServer = _conversationHistory.length > 1
          ? _conversationHistory
              .sublist(0, _conversationHistory.length - 1)
          : const <Map<String, String>>[];
      final corpus = [
        for (final psg in _lastRetrieved)
          {
            'text': psg.text,
            'source': psg.source,
            if (psg.reference != null) 'reference': psg.reference,
            'collection': psg.collection,
            'verification_status': psg.verificationStatus,
          }
      ];

      // STREAM FIRST (typewriter). Any stream failure retries once without
      // streaming — the /ai/ask JSON fallback is the level-0 shape.
      try {
        await _streamAsk(finalMessage, corpus, historyForServer,
            showLive: !actionish);
        return;
      } catch (_) {
        liveAnswer.value = '';
      }

      try {
        final resp = await ApiClient.instance
            .post(AppApi.endpointAiAsk, data: {
          'query': finalMessage,
          'corpus': corpus,
          'history': historyForServer,
          'stream': false,
        }).timeout(AppApi.receiveTimeout);
        await _finishBackendAnswer(resp.data);
        return;
      } on ApiException catch (e) {
        removeTypingIndicator();
        liveAnswer.value = '';
        if (e.type == ApiErrorType.offline) {
          addAIMessage('No internet connection. AI requires internet.');
        } else if (e.type == ApiErrorType.timeout) {
          addAIMessage(
              'AI request timed out. Please check your connection and try again.');
        } else {
          addAIMessage(
              'AI service unavailable (${e.statusCode ?? ''}). Please try later.');
        }
        return;
      }
    } on TimeoutException {
      removeTypingIndicator();
      addAIMessage(
          'AI request timed out. Please check your connection and try again.');
    } catch (e) {
      removeTypingIndicator();
      final msg = e.toString().toLowerCase();
      if (msg.contains('socket') ||
          msg.contains('failed host') ||
          msg.contains('network is unreachable')) {
        addAIMessage(
            'No internet connection. AI requires internet. Please try when online.');
      } else {
        addAIMessage('Something went wrong. Please try again.');
      }
    }
  }

  /// Navigation/alarm commands only. Questions that mention qibla/settings still refuse.
  static bool _isActionCommand(String message) {
    final text = message.trim().toLowerCase();
    if (text.isEmpty || text.length > 80) return false;
    final questionish = RegExp(
      r'\b(what|why|how|kaise|kya|matlab|meaning|ayat|ayah|verse|hadith|explain|who)\b',
    ).hasMatch(text);
    if (questionish) return false;
    return RegExp(
      r'\b(open|kholo|dikhao|alarm laga|set alarm|set reminder)\b',
    ).hasMatch(text);
  }

  // Phase 7: Whitelist + citation verification
  static const Set<String> _allowedActions = {
    'SET_TAHAJJUD_ALARM',
    'SET_MORNING_ADHKAR',
    'SET_EVENING_ADHKAR',
    'SET_JUMMAH_REMINDER',
    'CANCEL_ALL_NOTIFICATIONS',
    'TEST_NOTIFICATION',
    'OPEN_QURAN',
    'OPEN_PRAYER',
    'OPEN_QIBLA',
    'OPEN_HADITH',
    'OPEN_TASBIH',
    'OPEN_ZAKAT',
    'OPEN_INHERITANCE',
    'OPEN_HABITS',
    'OPEN_SETTINGS',
    'OPEN_HOME',
  };

  Future<void> _streamAsk(String query, List<Map<String, dynamic>> corpus,
      List<Map<String, String>> history, {bool showLive = true}) async {
    final resp = await ApiClient.instance.dio.post<dynamic>(
      AppApi.endpointAiAsk,
      data: {
        'query': query,
        'corpus': corpus,
        'history': history,
        'userName': _userName,
        'stream': true,
      },
      options: Options(
        responseType: ResponseType.stream,
        receiveTimeout: const Duration(seconds: 120),
        headers: const {'Accept': 'text/event-stream'},
      ),
    );
    final stream = (resp.data as ResponseBody).stream;
    final acc = StringBuffer();
    var pending = '';
    var fallbackAnswer = '';
    await for (final chunk in stream) {
      pending += utf8.decode(chunk, allowMalformed: true);
      while (pending.contains('\n')) {
        final idx = pending.indexOf('\n');
        final line = pending.substring(0, idx).trimRight();
        pending = pending.substring(idx + 1);
        if (!line.startsWith('data:')) continue;
        final dynamic ev;
        try {
          ev = jsonDecode(line.substring(5).trim());
        } catch (_) {
          continue;
        }
        if (ev is! Map) continue;
        switch (ev['type']) {
          case 'delta':
            acc.write(ev['text']);
            // Action payloads stream silently — the raw JSON would flash
            // in the bubble before _handleAIResponse consumes it.
            if (showLive) liveAnswer.value = acc.toString();
            break;
          case 'fallback':
            fallbackAnswer = (ev['answer'] as String?) ?? '';
            break;
          default:
            break; // 'done' carries citations; SOURCES stays _lastRetrieved-driven
        }
      }
    }
    removeTypingIndicator();
    final text = acc.isNotEmpty ? acc.toString() : fallbackAnswer;
    if (text.trim().isEmpty) {
      throw StateError('empty_stream'); // triggers the non-stream retry
    }
    liveAnswer.value = '';
    _conversationHistory.add({'role': 'assistant', 'content': text});
    await _handleAIResponse(text);
  }

  Future<void> _finishBackendAnswer(dynamic data) async {
    removeTypingIndicator();
    liveAnswer.value = '';
    if (data is Map) {
      if (data['refused'] == true) {
        addAIMessage(
            'I could not find a retrieved Quran or Hadith passage for that. I will not invent one.');
        return;
      }
      final aiResponse = (data['answer'] as String?) ?? '';
      if (aiResponse.trim().isEmpty) {
        addAIMessage('AI returned an empty response. Please try again.');
        return;
      }
      _conversationHistory.add({'role': 'assistant', 'content': aiResponse});
      await _handleAIResponse(aiResponse);
      return;
    }
    addAIMessage('AI returned an unexpected response. Please try again.');
  }

  Future<void> _handleAIResponse(String response) async {
    final jsonMatch = _extractJson(response);

    if (jsonMatch != null) {
      try {
        final actionData = jsonDecode(jsonMatch) as Map<String, dynamic>;
        final action = actionData['action'] as String?;
        final params = actionData['params'] as Map<String, dynamic>? ?? {};

        if (action != null) {
          // Whitelist validation — do NOT execute arbitrary JSON
          if (!_allowedActions.contains(action)) {
            addAIMessage(response);
            return;
          }
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
      } catch (_) {
        // Keep the original model text if JSON is not a valid action payload.
      }
    }

    // Islamic safety: verify citations if we had retrieved passages
    if (_lastRetrieved.isNotEmpty) {
      RagService.instance.verifyCitations(response, _lastRetrieved);
    }
    // If _lastRetrieved empty and answer is Islamic, system prompt already instructs to say "couldn't find verified source"
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
