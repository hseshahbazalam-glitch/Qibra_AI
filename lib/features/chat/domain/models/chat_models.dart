// lib/features/chat/domain/models/chat_models.dart

// ============================================================
// QIBRA AI — CHAT MODELS
// Version: 1.0.0
// Description: Data models for AI chat feature.
//              Message, ChatSession, Sender enum, etc.
// ============================================================

import 'package:flutter/foundation.dart';

// ============================================================
// SECTION 1: SENDER ENUM
// ============================================================

/// Who sent the message
enum MessageSender {
  /// User ne bheja hai
  user,

  /// AI ne bheja hai
  ai,

  /// System message (welcome, error, etc.)
  system,
}

// ============================================================
// SECTION 2: MESSAGE STATUS
// ============================================================

/// Message ki current status
enum MessageStatus {
  /// Send ho raha hai
  sending,

  /// AI reply generate ho raha hai
  thinking,

  /// AI reply stream ho raha hai
  streaming,

  /// Successfully sent/received
  sent,

  /// Error hui
  error,
}

// ============================================================
// SECTION 3: CHAT MESSAGE MODEL
// ============================================================

/// Single chat message
@immutable
class ChatMessage {
  /// Unique message ID
  final String id;

  /// Message ka content
  final String content;

  /// Kisne bheja
  final MessageSender sender;

  /// Message ki status
  final MessageStatus status;

  /// Kab bheja gaya
  final DateTime timestamp;

  /// Error message (agar status == error)
  final String? errorMessage;

  /// Related Ayah/Hadith reference (optional)
  final String? reference;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.sender,
    this.status = MessageStatus.sent,
    required this.timestamp,
    this.errorMessage,
    this.reference,
  });

  /// User message factory
  factory ChatMessage.user({
    required String content,
  }) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      sender: MessageSender.user,
      status: MessageStatus.sent,
      timestamp: DateTime.now(),
    );
  }

  /// AI message factory
  factory ChatMessage.ai({
    required String content,
    MessageStatus status = MessageStatus.sent,
    String? reference,
  }) {
    return ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      sender: MessageSender.ai,
      status: status,
      timestamp: DateTime.now(),
      reference: reference,
    );
  }

  /// AI thinking placeholder
  factory ChatMessage.thinking() {
    return ChatMessage(
      id: 'thinking_${DateTime.now().millisecondsSinceEpoch}',
      content: '',
      sender: MessageSender.ai,
      status: MessageStatus.thinking,
      timestamp: DateTime.now(),
    );
  }

  /// System message factory
  factory ChatMessage.system({
    required String content,
  }) {
    return ChatMessage(
      id: 'system_${DateTime.now().millisecondsSinceEpoch}',
      content: content,
      sender: MessageSender.system,
      status: MessageStatus.sent,
      timestamp: DateTime.now(),
    );
  }

  /// Error message factory
  factory ChatMessage.error({
    required String errorMessage,
  }) {
    return ChatMessage(
      id: 'error_${DateTime.now().millisecondsSinceEpoch}',
      content: 'Sorry, kuch problem hui. Try again karo.',
      sender: MessageSender.ai,
      status: MessageStatus.error,
      timestamp: DateTime.now(),
      errorMessage: errorMessage,
    );
  }

  /// Copy with new values
  ChatMessage copyWith({
    String? id,
    String? content,
    MessageSender? sender,
    MessageStatus? status,
    DateTime? timestamp,
    String? errorMessage,
    String? reference,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      sender: sender ?? this.sender,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      errorMessage: errorMessage ?? this.errorMessage,
      reference: reference ?? this.reference,
    );
  }

  /// Convert to JSON (for persistence)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'sender': sender.name,
      'status': status.name,
      'timestamp': timestamp.toIso8601String(),
      'errorMessage': errorMessage,
      'reference': reference,
    };
  }

  /// From JSON
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      sender: MessageSender.values.firstWhere(
        (s) => s.name == json['sender'],
        orElse: () => MessageSender.system,
      ),
      status: MessageStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => MessageStatus.sent,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      errorMessage: json['errorMessage'] as String?,
      reference: json['reference'] as String?,
    );
  }

  // Helpers
  bool get isUser => sender == MessageSender.user;
  bool get isAi => sender == MessageSender.ai;
  bool get isSystem => sender == MessageSender.system;
  bool get isThinking => status == MessageStatus.thinking;
  bool get isError => status == MessageStatus.error;
  bool get isEmpty => content.trim().isEmpty && !isThinking;
}

// ============================================================
// SECTION 4: CHAT STATE
// ============================================================

/// Complete chat state
@immutable
class ChatState {
  /// All messages
  final List<ChatMessage> messages;

  /// Is AI currently generating reply?
  final bool isGenerating;

  /// Current error message
  final String? error;

  const ChatState({
    this.messages = const [],
    this.isGenerating = false,
    this.error,
  });

  /// Initial empty state
  factory ChatState.initial() {
    return const ChatState();
  }

  /// Copy with new values
  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isGenerating,
    String? error,
    bool clearError = false,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isGenerating: isGenerating ?? this.isGenerating,
      error: clearError ? null : (error ?? this.error),
    );
  }

  // Helpers
  bool get isEmpty => messages.isEmpty;
  bool get isNotEmpty => messages.isNotEmpty;
  int get messageCount => messages.length;
  ChatMessage? get lastMessage => messages.isEmpty ? null : messages.last;
}

// ============================================================
// SECTION 5: SUGGESTED PROMPTS
// ============================================================

/// Pre-defined suggested questions
class SuggestedPrompts {
  static const List<String> islamic = [
    'What is the importance of Salah?',
    'Explain the pillars of Islam',
    'Tell me about the meaning of Bismillah',
    'What are the etiquettes of reading Quran?',
    'How to perform Wudu correctly?',
    'What is Zakat and who should pay it?',
    'Tell me a Hadith about kindness',
    'What is the significance of Ramadan?',
  ];

  static const List<String> quran = [
    'Explain Surah Al-Fatiha',
    'What is Ayat-ul-Kursi about?',
    'Tell me about Surah Yaseen',
    'Meaning of Bismillah-hir-Rahman-nir-Raheem',
  ];

  static const List<String> daily = [
    'Give me a daily Islamic reminder',
    'What dua should I recite in the morning?',
    'Share a beautiful Hadith',
    'Explain today\'s prayer significance',
  ];

  /// Get random suggestions
  static List<String> random({int count = 4}) {
    final all = [...islamic, ...quran, ...daily];
    all.shuffle();
    return all.take(count).toList();
  }
}
