// lib/features/chat/presentation/screens/ai_chat_screen.dart

// ============================================================
// QIBRA AI — AI CHAT SCREEN
// Version: 1.0.0
// Description: Premium AI chat interface with message bubbles,
//              typing indicator, and smart suggestions.
// ============================================================
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qibra_ai/core/design_system/app_colors.dart';
import 'package:qibra_ai/core/design_system/app_design_system.dart';
import 'package:qibra_ai/core/design_system/app_typography.dart';

import '../../domain/models/chat_models.dart';
import '../providers/chat_provider.dart';

// ============================================================
// MAIN SCREEN
// ============================================================

class AiChatScreen extends ConsumerStatefulWidget {
  const AiChatScreen({super.key});

  @override
  ConsumerState<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends ConsumerState<AiChatScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ─── SCROLL TO BOTTOM ────────────────────────────────────

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ─── SEND MESSAGE ────────────────────────────────────────

  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    ref.read(chatProvider.notifier).sendMessage(text);
    _inputController.clear();
    _focusNode.requestFocus();
    _scrollToBottom();
  }

  // ─── SEND SUGGESTED PROMPT ───────────────────────────────

  void _sendSuggestion(String prompt) {
    _inputController.text = prompt;
    _sendMessage();
  }

  // ─── CLEAR CHAT ──────────────────────────────────────────

  void _confirmClearChat() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Clear Chat', style: AppTextStyles.titleLarge),
        content: Text(
          'Are you sure you want to clear all messages?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: AppTextStyles.labelLarge),
          ),
          TextButton(
            onPressed: () {
              ref.read(chatProvider.notifier).clearChat();
              Navigator.pop(context);
            },
            child: Text(
              'Clear',
              style: AppTextStyles.labelLarge.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  // ─── BUILD ───────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final messages = chatState.messages;

    // Auto-scroll on new message
    ref.listen<ChatState>(chatProvider, (previous, next) {
      if (previous?.messages.length != next.messages.length) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(chatState),
            Expanded(
              child: messages.isEmpty
                  ? _buildEmptyState()
                  : _buildMessagesList(messages),
            ),
            _buildSuggestions(chatState),
            _buildInputBar(chatState),
          ],
        ),
      ),
    );
  }

  // ─── HEADER ──────────────────────────────────────────────

  Widget _buildHeader(ChatState state) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          bottom: BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.35),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Icon(
              Icons.smart_toy,
              color: AppColors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'QIBRA AI',
                  style: AppTextStyles.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: state.isGenerating
                            ? AppColors.warning
                            : AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      state.isGenerating ? 'Thinking...' : 'Online',
                      style: AppTextStyles.labelSmall.secondary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            color: AppColors.iconSecondary,
            onPressed: _confirmClearChat,
            tooltip: 'Clear chat',
          ),
        ],
      ),
    );
  }

  // ─── EMPTY STATE ─────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: AppColors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Islamic AI Assistant',
              style: AppTextStyles.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Ask me anything about Islam, Quran, Hadith, or Duas',
              style: AppTextStyles.bodyMedium.secondary,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ─── MESSAGES LIST ───────────────────────────────────────

  Widget _buildMessagesList(List<ChatMessage> messages) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.lg,
      ),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return _MessageBubble(message: message);
      },
    );
  }

  // ─── SUGGESTIONS ─────────────────────────────────────────

  Widget _buildSuggestions(ChatState state) {
    // Show suggestions only when chat has just welcome message
    if (state.messages.length != 1) return const SizedBox.shrink();
    if (state.isGenerating) return const SizedBox.shrink();

    final suggestions = SuggestedPrompts.random(count: 4);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.sm,
              bottom: AppSpacing.sm,
            ),
            child: Text(
              'Suggested Questions',
              style: AppTextStyles.labelMedium.secondary,
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: suggestions.length,
              separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                final suggestion = suggestions[index];
                return _SuggestionChip(
                  text: suggestion,
                  onTap: () => _sendSuggestion(suggestion),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ─── INPUT BAR ───────────────────────────────────────────

  Widget _buildInputBar(ChatState state) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(
          top: BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: TextField(
                  controller: _inputController,
                  focusNode: _focusNode,
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  style: AppTextStyles.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Ask an Islamic question...',
                    hintStyle: AppTextStyles.bodyMedium.secondary,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _buildSendButton(state),
          ],
        ),
      ),
    );
  }

  Widget _buildSendButton(ChatState state) {
    if (state.isGenerating) {
      return Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: AppColors.error,
          shape: BoxShape.circle,
        ),
        child: IconButton(
          icon: const Icon(Icons.stop, color: AppColors.white),
          onPressed: () {
            ref.read(chatProvider.notifier).stopGeneration();
          },
        ),
      );
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
            blurRadius: 12,
            spreadRadius: 1,
          ),
        ],
      ),
      child: IconButton(
        icon: const Icon(Icons.send, color: AppColors.white, size: 20),
        onPressed: _sendMessage,
      ),
    );
  }
}

// ============================================================
// MESSAGE BUBBLE
// ============================================================

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    if (message.isThinking) return const _ThinkingBubble();

    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatar(),
          if (!isUser) const SizedBox(width: AppSpacing.sm),
          Flexible(
            child: GestureDetector(
              onLongPress: () => _copyMessage(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.md,
                ),
                decoration: BoxDecoration(
                  color: isUser ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isUser ? 16 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 16),
                  ),
                  border: !isUser
                      ? Border.all(color: AppColors.borderSubtle)
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── User = plain text | AI = Markdown ──
                    isUser
                        ? SelectableText(
                            message.content,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.background,
                              height: 1.5,
                            ),
                          )
                        : MarkdownBody(
                            data: message.content,
                            selectable: true,
                            styleSheet: MarkdownStyleSheet(
                              // Body text
                              p: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                                height: 1.7,
                              ),
                              // Headings
                              h1: AppTextStyles.titleLarge.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                              h2: AppTextStyles.titleMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                              h3: AppTextStyles.titleSmall.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                              h4: AppTextStyles.bodyLarge.copyWith(
                                color: const Color(0xFFFBBF24),
                                fontWeight: FontWeight.w700,
                              ),
                              // Bold text
                              strong: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                                height: 1.7,
                              ),
                              // Italic
                              em: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                                fontStyle: FontStyle.italic,
                                height: 1.7,
                              ),
                              // Blockquote (verse translations)
                              blockquote: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textSecondary,
                                fontStyle: FontStyle.italic,
                                height: 1.8,
                              ),
                              blockquoteDecoration: BoxDecoration(
                                color:
                                    AppColors.primary.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: const Border(
                                  left: BorderSide(
                                    color: AppColors.primary,
                                    width: 3,
                                  ),
                                ),
                              ),
                              blockquotePadding: const EdgeInsets.all(12),
                              // Horizontal divider
                              horizontalRuleDecoration: const BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: AppColors.borderSubtle,
                                    width: 1,
                                  ),
                                ),
                              ),
                              // List
                              listBullet: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.primary,
                                height: 1.6,
                              ),
                              // Code
                              code: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.accent,
                                backgroundColor: AppColors.surfaceElevated,
                                fontFamily: 'monospace',
                              ),
                              codeblockDecoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                    const SizedBox(height: 4),
                    Text(
                      _formatTime(message.timestamp),
                      style: AppTextStyles.labelSmall.copyWith(
                        color: isUser
                            ? AppColors.background.withValues(alpha: 0.7)
                            : AppColors.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: AppSpacing.sm),
          if (isUser) _buildUserAvatar(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
        ),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.auto_awesome,
        color: AppColors.white,
        size: 16,
      ),
    );
  }

  Widget _buildUserAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.person,
        color: AppColors.background,
        size: 18,
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _copyMessage(BuildContext context) {
    Clipboard.setData(ClipboardData(text: message.content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message copied'),
        duration: Duration(seconds: 1),
        backgroundColor: AppColors.success,
      ),
    );
  }
}

// ============================================================
// THINKING BUBBLE (3 dots animation)
// ============================================================

class _ThinkingBubble extends StatefulWidget {
  const _ThinkingBubble();

  @override
  State<_ThinkingBubble> createState() => _ThinkingBubbleState();
}

class _ThinkingBubbleState extends State<_ThinkingBubble>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF6D28D9)],
              ),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: AppColors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                return AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    final delay = index * 0.2;
                    final progress =
                        (_controller.value - delay).clamp(0.0, 1.0);
                    final scale = 0.5 + (0.5 * (1 - (progress * 2 - 1).abs()));

                    return Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: index == 1 ? 4 : 2,
                      ),
                      child: Transform.scale(
                        scale: scale,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.textSecondary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SUGGESTION CHIP
// ============================================================

class _SuggestionChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _SuggestionChip({
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderSubtle),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.auto_awesome,
              size: 14,
              color: AppColors.primary,
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: AppTextStyles.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}
