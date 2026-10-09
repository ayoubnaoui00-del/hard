import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/chat_provider.dart';
import '../../widgets/gradient_background.dart';
import 'widgets/coach_bubble.dart';
import 'widgets/coach_conversation_drawer.dart';
import 'widgets/coach_create_dialog.dart';
import 'widgets/coach_input_bar.dart';
import 'widgets/coach_quick_prompts_bar.dart';
import 'widgets/coach_welcome_view.dart';

class CoachView extends ConsumerStatefulWidget {
  const CoachView({super.key});

  @override
  ConsumerState<CoachView> createState() => _CoachViewState();
}

class _CoachViewState extends ConsumerState<CoachView> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(chatViewModelProvider.notifier).fetchConversations();
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage([String? textToSend]) {
    final text = (textToSend ?? _textController.text).trim();
    if (text.isEmpty) return;

    _textController.clear();
    ref.read(chatViewModelProvider.notifier).streamChatMessage(text);
    _scrollToBottom();
  }

  void _openConversationSelector(BuildContext context) {
    CoachConversationDrawerSheet.show(context);
  }

  void _createNewConversationModal(BuildContext context) {
    CoachCreateConversationDialog.show(context);
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatViewModelProvider);
    final isStreaming = chatState.isStreaming;

    ref.listen(chatViewModelProvider, (prev, next) {
      if (prev?.messages.length != next.messages.length ||
          prev?.currentStreamingResponse != next.currentStreamingResponse) {
        _scrollToBottom();
      }
    });

    final currentTitle =
        chatState.currentConversation?.title ?? 'AI Fitness Coach';

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: GestureDetector(
          onTap: () => _openConversationSelector(context),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2979FF), Color(0xFF00E5FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.smart_toy_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            currentTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white54,
                          size: 18,
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: isStreaming
                                ? const Color(0xFFFFB300)
                                : const Color(0xFF00E676),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          isStreaming
                              ? 'Streaming response...'
                              : 'Online & Ready',
                          style: TextStyle(
                            fontSize: 11,
                            color: isStreaming
                                ? const Color(0xFFFFB300)
                                : Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'New Chat',
            icon: const Icon(Icons.add_comment_rounded, color: Colors.white70),
            onPressed: () => _createNewConversationModal(context),
          ),
          IconButton(
            tooltip: 'Chat History',
            icon: const Icon(Icons.history_rounded, color: Colors.white70),
            onPressed: () => _openConversationSelector(context),
          ),
        ],
      ),
      body: Column(
        children: [
          if (chatState.errorMessage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFFB00020).withValues(alpha: 0.2),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Color(0xFFFF5252), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      chatState.errorMessage!,
                      style: const TextStyle(
                          color: Color(0xFFFF7B7B), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          Expanded(
            child: chatState.messages.isEmpty && !isStreaming
                ? CoachWelcomeView(onSelectPrompt: _sendMessage)
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount:
                        chatState.messages.length + (isStreaming ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < chatState.messages.length) {
                        final msg = chatState.messages[index];
                        final isUser = msg.role.toLowerCase() == 'user';
                        return CoachChatBubble(
                          isUser: isUser,
                          content: msg.content,
                          timestamp: msg.createdAt,
                        );
                      } else {
                        return CoachStreamingBubble(
                          responseText: chatState.currentStreamingResponse,
                        );
                      }
                    },
                  ),
          ),
          if (!isStreaming)
            CoachQuickPromptsBar(onSelectPrompt: _sendMessage),
          CoachInputBar(
            controller: _textController,
            isStreaming: isStreaming,
            onSend: () => _sendMessage(),
          ),
        ],
      ),
    ),
  );
  }
}
