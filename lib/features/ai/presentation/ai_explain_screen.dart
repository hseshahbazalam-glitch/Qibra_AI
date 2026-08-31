// lib/features/ai/presentation/ai_explain_screen.dart

// ============================================================
// QIBRA AI — AI EXPLAIN SCREEN (v3.0 — WITH VOICE)
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:avatar_glow/avatar_glow.dart';

import '../../../core/design_system/qibra_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/widgets/qibra_ui.dart';
import '../providers/ai_provider.dart';
import '../services/ai_action_service.dart';
import '../services/voice_service.dart';

class AIExplainScreen extends ConsumerStatefulWidget {
  const AIExplainScreen({
    super.key,
    this.ayahText,
    this.surahName,
    this.ayahNumber,
    this.surahNumber,
  });

  final String? ayahText;
  final String? surahName;
  final int? ayahNumber;
  final int? surahNumber;

  @override
  ConsumerState<AIExplainScreen> createState() => _AIExplainScreenState();
}

class _AIExplainScreenState extends ConsumerState<AIExplainScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  final VoiceService _voice = VoiceService();

  bool _isListening = false;
  bool _isSpeaking = false;

  bool _autoSpeak = true;
  String _partialText = '';

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // User name pass karo AI ko
      final userName = ref.read(userDisplayNameProvider);
      ref.read(chatProvider.notifier).setUserName(userName);

      // Context set karo action service ko
      AIActionService().setContext(context);

      // Voice service initialize
      await _initVoice();

      // Initial ayah message
      if (widget.ayahText != null) {
        _sendInitialMessage();
      }
    });
  }

  Future<void> _initVoice() async {
    _voice.onResult = (text) {
      if (text.isNotEmpty) {
        _controller.text = text;
        _sendMessage();
      }
      setState(() {
        _isListening = false;
        _partialText = '';
      });
    };

    _voice.onPartialResult = (text) {
      setState(() {
        _partialText = text;
      });
    };

    _voice.onListeningStart = () {
      setState(() => _isListening = true);
    };

    _voice.onListeningStop = () {
      setState(() {
        _isListening = false;
        _partialText = '';
      });
    };

    _voice.onSpeakingStart = () {
      setState(() => _isSpeaking = true);
    };

    _voice.onSpeakingStop = () {
      setState(() => _isSpeaking = false);
    };

    _voice.onError = (error) {
      setState(() {
        _isListening = false;
        _partialText = '';
      });
      _showSnackbar('Voice error: $error');
    };

    await _voice.initialize();
  }

  @override
  void dispose() {
    _voice.dispose();
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _sendInitialMessage() async {
    final question =
        'Please explain this ayah: "${widget.ayahText}" from ${widget.surahName} (${widget.surahNumber}:${widget.ayahNumber})';
    await ref.read(chatProvider.notifier).sendMessage(
          question,
          context: 'Surah ${widget.surahName}, Ayah ${widget.ayahNumber}',
        );
    _scrollToBottom();
    _autoSpeakLastMessage();
  }

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.mediumImpact();
    _controller.clear();

    await ref.read(chatProvider.notifier).sendMessage(text);
    _scrollToBottom();
    _autoSpeakLastMessage();
  }

  void _autoSpeakLastMessage() {
    if (!_autoSpeak) return;

    Future.delayed(const Duration(milliseconds: 500), () {
      // Widget disposed check
      if (!mounted) return;

      final messages = ref.read(chatProvider);
      if (messages.isNotEmpty) {
        final last = messages.last;
        if (last.isAI && !last.isTyping) {
          _voice.speak(last.content);
        }
      }
    });
  }

  void _toggleVoice() async {
    HapticFeedback.mediumImpact();

    if (_isSpeaking) {
      await _voice.stopSpeaking();
      return;
    }

    if (_isListening) {
      await _voice.stopListening();
    } else {
      await _voice.startListening();
    }
  }

  void _toggleAutoSpeak() {
    HapticFeedback.selectionClick();
    setState(() => _autoSpeak = !_autoSpeak);
    if (!_autoSpeak && _isSpeaking) {
      _voice.stopSpeaking();
    }
    _showSnackbar(_autoSpeak ? 'Auto speak ON' : 'Auto speak OFF');
  }

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

  void _showSnackbar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = QibraColors.of(context);
    final messages = ref.watch(chatProvider);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return QibraPage(
      title: 'Qibra AI',
      subtitle: _isSpeaking
          ? 'Speaking...'
          : (_isListening ? 'Listening...' : 'Retrieval only — not a fatwa'),
      actions: [
        IconButton(
          tooltip: _autoSpeak ? 'Auto speak on' : 'Auto speak off',
          onPressed: _toggleAutoSpeak,
          icon: Icon(
            _autoSpeak ? Icons.volume_up_rounded : Icons.volume_off_rounded,
            color: colors.violetAi,
          ),
        ),
        SizedBox(
          width: 48,
          height: 48,
          child: IconButton(
            tooltip: 'Delete conversation',
            onPressed: () {
              HapticFeedback.mediumImpact();
              _showClearDialog();
            },
            icon: Icon(Icons.delete_outline_rounded, color: colors.textPrimary),
          ),
        ),
      ],
      child: Column(
        children: [
          if (widget.ayahText != null) _buildAyahContext(),
          Expanded(
            child: _isListening
                ? _buildListeningView()
                : (messages.isEmpty
                    ? _buildEmptyState()
                    : _buildMessagesList(messages)),
          ),
          if (messages.isEmpty && widget.ayahText == null && !_isListening)
            _buildSuggestedQuestions(),
          Container(
            padding: EdgeInsets.only(bottom: bottomPadding),
            color: colors.card,
            child: _buildInputBar(),
          ),
        ],
      ),
    );
  }

  // ─── APP BAR ─────────────────────────

  Widget _buildAppBar() {
    final colors = QibraColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors.surfaceElevated,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: colors.textPrimary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [colors.primarySoft, colors.accent],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colors.primarySoft.withValues(alpha: 0.4),
                  blurRadius: 12,
                ),
              ],
            ),
            child:
                Icon(Icons.auto_awesome, color: colors.textPrimary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Qibra AI',
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _isSpeaking
                            ? colors.accent
                            : (_isListening
                                ? colors.error
                                : colors.primarySoft),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isSpeaking
                          ? 'Speaking...'
                          : (_isListening
                              ? 'Listening...'
                              : 'Retrieval only — not a fatwa'),
                      style: TextStyle(
                        color: colors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Auto speak toggle
          GestureDetector(
            onTap: _toggleAutoSpeak,
            child: Container(
              width: 48,
              height: 48,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: _autoSpeak
                    ? colors.primarySoft.withValues(alpha: 0.2)
                    : colors.surfaceElevated,
                shape: BoxShape.circle,
              ),
              child: Icon(
                _autoSpeak ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                color: _autoSpeak
                    ? colors.primarySoft
                    : colors.textPrimary,
                size: 18,
              ),
            ),
          ),
          // Clear chat
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              _showClearDialog();
            },
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colors.surfaceElevated,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.delete_outline_rounded,
                color: colors.textPrimary,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── LISTENING VIEW ─────────────────────────

  Widget _buildListeningView() {
    final colors = QibraColors.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AvatarGlow(
            glowColor: colors.primarySoft,
            duration: const Duration(milliseconds: 2000),
            repeat: true,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colors.primarySoft, colors.accent],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colors.primarySoft.withValues(alpha: 0.6),
                    blurRadius: 30,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Icon(
                Icons.mic_rounded,
                color: colors.textPrimary,
                size: 60,
              ),
            ),
          ),
          const SizedBox(height: 30),
          Text(
            'Listening...',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Speak now',
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 14,
            ),
          ),
          if (_partialText.isNotEmpty) ...[
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 32),
              decoration: BoxDecoration(
                color: colors.surfaceElevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border),
              ),
              child: Text(
                _partialText,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
          const SizedBox(height: 40),
          GestureDetector(
            onTap: _toggleVoice,
            child: Container(
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: colors.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: colors.error.withValues(alpha: 0.4)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.stop_rounded, color: colors.error, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Stop',
                    style: TextStyle(
                      color: colors.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── AYAH CONTEXT ─────────────────────────

  Widget _buildAyahContext() {
    final colors = QibraColors.of(context);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary.withValues(alpha: 0.2),
            colors.accent.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.accent.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'AYAH ${widget.ayahNumber}',
                  style: TextStyle(
                    color: colors.goldText,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                widget.surahName ?? '',
                style: TextStyle(
                  color: colors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            widget.ayahText ?? '',
            textAlign: TextAlign.right,
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 20,
              color: colors.textPrimary,
              height: 1.8,
            ),
          ),
        ],
      ),
    );
  }

  // ─── EMPTY STATE ─────────────────────────

  Widget _buildEmptyState() {
    final colors = QibraColors.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: colors.violetAi,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: colors.violetAi.withValues(alpha: 0.4),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child:
                Icon(Icons.auto_awesome, color: colors.textPrimary, size: 48),
          ),
          const SizedBox(height: 20),
          Text(
            'Qibra AI Assistant',
            style: TextStyle(
              color: colors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Type or speak to ask\nabout Islam or control the app',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Icon(Icons.mic_rounded, color: colors.violetAi, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tap mic to speak — All languages supported',
                    style: TextStyle(
                      color: colors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── MESSAGES LIST ─────────────────────────

  Widget _buildMessagesList(List<ChatMessage> messages) {
    final colors = QibraColors.of(context);
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final colors = QibraColors.of(context);
    if (message.isTyping) return _buildTypingBubble();

    final isUser = message.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colors.violetAi,
                shape: BoxShape.circle,
              ),
              child:
                  Icon(Icons.auto_awesome, color: colors.textPrimary, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () {
                HapticFeedback.mediumImpact();
                Clipboard.setData(ClipboardData(text: message.content));
                _showSnackbar('Message copied');
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isUser
                      ? LinearGradient(
                          colors: [colors.primarySoft, colors.primary],
                        )
                      : null,
                  color: isUser ? null : colors.surfaceElevated,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isUser ? 16 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 16),
                  ),
                  border: !isUser
                      ? Border.all(color: colors.border)
                      : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFormattedText(message.content, isUser),
                    if (!isUser) ..._sourceChips(message.content),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(message.timestamp),
                          style: TextStyle(
                            color: isUser
                                ? colors.onPrimary.withValues(alpha: 0.7)
                                : colors.textTertiary,
                            fontSize: 10,
                          ),
                        ),
                        if (!isUser) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              _voice.speak(message.content);
                            },
                            child: Icon(
                              Icons.volume_up_outlined,
                              color: colors.textTertiary,
                              size: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colors.primarySoft, colors.primary],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person_rounded,
                  color: colors.textPrimary, size: 18),
            ),
          ],
        ],
      ),
    );
  }

  List<Widget> _sourceChips(String content) {
    final colors = QibraColors.of(context);
    final tags = <String>{};
    for (final match in RegExp(r'Quran\s+\d+:\d+', caseSensitive: false)
        .allMatches(content)) {
      tags.add(match.group(0)!);
    }
    for (final match in RegExp(r'\[(\d+)\]\s+([^:\n]+):').allMatches(content)) {
      final label = match.group(2)?.trim();
      if (label != null && label.isNotEmpty) tags.add(label);
    }
    if (tags.isEmpty) return const [];
    return [
      const SizedBox(height: 8),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final tag in tags)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colors.violetAi.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: colors.violetAi.withValues(alpha: 0.4)),
              ),
              child: Text(
                tag,
                style: TextStyle(
                  color: colors.violetAi,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    ];
  }

  Widget _buildFormattedText(String text, bool isUser) {
    final colors = QibraColors.of(context);
    final color = isUser ? colors.onPrimary : colors.textPrimary;
    final List<TextSpan> spans = [];
    final parts = text.split(RegExp(r'(\*\*[^*]+\*\*)'));

    for (final part in parts) {
      if (part.startsWith('**') && part.endsWith('**')) {
        spans.add(TextSpan(
          text: part.substring(2, part.length - 2),
          style: TextStyle(
            color: color,
            fontSize: 14,
            height: 1.6,
            fontWeight: FontWeight.w800,
          ),
        ));
      } else {
        spans.add(TextSpan(
          text: part,
          style: TextStyle(color: color, fontSize: 14, height: 1.6),
        ));
      }
    }

    return SelectableText.rich(
      TextSpan(children: spans),
      style: TextStyle(color: color, fontSize: 14, height: 1.6),
    );
  }

  Widget _buildTypingBubble() {
    final colors = QibraColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colors.violetAi,
              shape: BoxShape.circle,
            ),
            child:
                Icon(Icons.auto_awesome, color: colors.textPrimary, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colors.surfaceElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: colors.border),
            ),
            child: const _TypingDots(),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  // ─── SUGGESTED QUESTIONS ─────────────────────────

  Widget _buildSuggestedQuestions() {
    final colors = QibraColors.of(context);
    final suggestions = [
      '🎤 Tap mic to speak',
      '🕌 Tahajjud alarm 2 baje',
      '📖 Quran kholo',
      '🕋 Qibla dikhao',
      '🤲 Namaz kaise padhein',
      '💚 Zakat calculator kholo',
    ];

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              if (index == 0) {
                _toggleVoice();
              } else {
                _controller.text = suggestions[index].substring(3);
                _sendMessage();
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: colors.surfaceElevated,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: colors.border),
              ),
              child: Center(
                child: Text(
                  suggestions[index],
                  style: TextStyle(
                    color: colors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── INPUT BAR ─────────────────────────

  Widget _buildInputBar() {
    final colors = QibraColors.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          // Mic Button
          GestureDetector(
            onTap: _toggleVoice,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isListening
                      ? [colors.error, colors.error]
                      : (_isSpeaking
                          ? [colors.accent, colors.accent]
                          : [colors.violetAi, colors.violetAi]),
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: (_isListening ? colors.error : colors.violetAi)
                        .withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                _isListening
                    ? Icons.mic_rounded
                    : (_isSpeaking
                        ? Icons.stop_rounded
                        : Icons.mic_none_rounded),
                color: colors.textPrimary,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 14,
              ),
              decoration: InputDecoration(
                hintText: 'Type or tap mic to speak...',
                hintStyle: TextStyle(
                  color: colors.textTertiary,
                  fontSize: 14,
                ),
                filled: true,
                fillColor: colors.surfaceElevated,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: colors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: colors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(
                    color: colors.violetAi,
                    width: 1.5,
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Send Button
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [colors.primarySoft, colors.primary],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: colors.primarySoft.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.send_rounded,
                color: colors.textPrimary,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── CLEAR DIALOG ─────────────────────────

  void _showClearDialog() {
    final colors = QibraColors.of(context);
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      builder: (dialogContext) => AlertDialog(
        backgroundColor: colors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Clear Chat?',
          style: TextStyle(
            color: colors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: Text(
          'This will delete all messages in this conversation.',
          style: TextStyle(color: colors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(
              'Cancel',
              style: TextStyle(color: colors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(chatProvider.notifier).clearChat();
              Navigator.of(dialogContext).pop();
              HapticFeedback.mediumImpact();
            },
            child: Text(
              'Clear',
              style: TextStyle(
                color: colors.error,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// TYPING DOTS ANIMATION
// ============================================================

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
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
    final colors = QibraColors.of(context);
    return SizedBox(
      width: 40,
      height: 16,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(3, (index) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final delay = index * 0.2;
              final value = ((_controller.value - delay) % 1.0).clamp(0.0, 1.0);
              final scale = 0.5 + (0.5 * (1 - (value * 2 - 1).abs()));
              return Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  color: colors.textPrimary.withValues(alpha: scale),
                  shape: BoxShape.circle,
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
