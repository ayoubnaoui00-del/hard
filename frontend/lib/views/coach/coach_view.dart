import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/chat_provider.dart';

class CoachView extends ConsumerStatefulWidget {
  const CoachView({super.key});

  @override
  ConsumerState<CoachView> createState() => _CoachViewState();
}

class _CoachViewState extends ConsumerState<CoachView> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final DateFormat _timeFormat = DateFormat('h:mm a');

  final List<Map<String, String>> _quickPrompts = const [
    {
      'label': '💪 Recommend 4-day Routine',
      'prompt': 'Can you recommend a balanced 4-day upper/lower hypertrophy workout split?',
    },
    {
      'label': '🏋️ Form Check: Barbell Squat',
      'prompt': 'What are the top 3 cues for maintaining proper depth and bar path during a heavy back squat?',
    },
    {
      'label': '📈 Break Bench Plateau',
      'prompt': 'My bench press has been stuck at 90 kg for 4 weeks. How should I adjust volume or intensity?',
    },
    {
      'label': '🥗 Post-Workout Recovery',
      'prompt': 'What should my optimal post-workout protein and carb intake look like for recovery?',
    },
  ];

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
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => const _ConversationDrawerSheet(),
    );
  }

  void _createNewConversationModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => const _CreateConversationDialog(),
    );
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

    final currentTitle = chatState.currentConversation?.title ?? 'AI Fitness Coach';

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF14141B),
        elevation: 0,
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
                          isStreaming ? 'Streaming response...' : 'Online & Ready',
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
          // Error notification banner if any
          if (chatState.errorMessage != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFFB00020).withValues(alpha: 0.2),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFFF5252), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      chatState.errorMessage!,
                      style: const TextStyle(color: Color(0xFFFF7B7B), fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          // Messages List or Welcome Screen
          Expanded(
            child: chatState.messages.isEmpty && !isStreaming
                ? _buildWelcomeScreen()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount: chatState.messages.length + (isStreaming ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index < chatState.messages.length) {
                        final msg = chatState.messages[index];
                        final isUser = msg.role.toLowerCase() == 'user';
                        return _buildChatBubble(
                          isUser: isUser,
                          content: msg.content,
                          timestamp: msg.createdAt,
                        );
                      } else {
                        // Real-time Streaming message
                        return _buildStreamingBubble(chatState.currentStreamingResponse);
                      }
                    },
                  ),
          ),

          // Quick Prompts Chips Carousel
          if (!isStreaming) _buildQuickPromptsBar(),

          // Chat Input Field
          _buildInputBar(isStreaming),
        ],
      ),
    );
  }

  Widget _buildWelcomeScreen() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF2979FF).withValues(alpha: 0.2),
                    const Color(0xFF00E5FF).withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF2979FF).withValues(alpha: 0.4)),
              ),
              child: const Icon(
                Icons.smart_toy_rounded,
                size: 48,
                color: Color(0xFF2979FF),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your Personal AI Coach',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ask about workout routines, exercise form tips, 1RM calculations, progressive overload, or nutrition advice.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _quickPrompts.map((p) {
                return ActionChip(
                  label: Text(
                    p['label']!,
                    style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                  backgroundColor: const Color(0xFF1E1E2A),
                  side: const BorderSide(color: Color(0xFF2E2E40)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onPressed: () => _sendMessage(p['prompt']),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble({
    required bool isUser,
    required String content,
    required DateTime timestamp,
  }) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isUser) ...[
              Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.only(right: 8, bottom: 4),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF2979FF), Color(0xFF00E5FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.smart_toy_rounded, size: 16, color: Colors.white),
              ),
            ],
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isUser
                      ? const LinearGradient(
                          colors: [Color(0xFFFF5252), Color(0xFFFF3838)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isUser ? null : const Color(0xFF1E1E2A),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(16),
                    topRight: const Radius.circular(16),
                    bottomLeft: Radius.circular(isUser ? 16 : 4),
                    bottomRight: Radius.circular(isUser ? 4 : 16),
                  ),
                  border: isUser
                      ? null
                      : Border.all(color: const Color(0xFF2D2D3E), width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment:
                      isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Text(
                      content,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _timeFormat.format(timestamp),
                      style: TextStyle(
                        fontSize: 10,
                        color: isUser ? Colors.white70 : Colors.white38,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreamingBubble(String responseText) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 8, bottom: 4),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF2979FF), Color(0xFF00E5FF)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.smart_toy_rounded, size: 16, color: Colors.white),
            ),
            Flexible(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2A),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                    bottomLeft: Radius.circular(4),
                    bottomRight: Radius.circular(16),
                  ),
                  border: Border.all(
                    color: const Color(0xFF2979FF).withValues(alpha: 0.5),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2979FF).withValues(alpha: 0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (responseText.isEmpty)
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF00E5FF),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Thinking...',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.white60,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      )
                    else
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: responseText,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white,
                                height: 1.35,
                              ),
                            ),
                            const TextSpan(
                              text: ' ▋',
                              style: TextStyle(
                                color: Color(0xFF00E5FF),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickPromptsBar() {
    return Container(
      height: 38,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _quickPrompts.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final prompt = _quickPrompts[index];
          return ActionChip(
            label: Text(
              prompt['label']!,
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
            backgroundColor: const Color(0xFF1A1A24),
            side: const BorderSide(color: Color(0xFF282838)),
            padding: const EdgeInsets.symmetric(horizontal: 6),
            onPressed: () => _sendMessage(prompt['prompt']),
          );
        },
      ),
    );
  }

  Widget _buildInputBar(bool isStreaming) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: const BoxDecoration(
        color: Color(0xFF14141B),
        border: Border(
          top: BorderSide(color: Color(0xFF232330), width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E2A),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFF2E2E3E)),
                ),
                child: TextField(
                  controller: _textController,
                  maxLines: 4,
                  minLines: 1,
                  enabled: !isStreaming,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    hintText: 'Ask coach about workouts, sets, form...',
                    hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                  onSubmitted: isStreaming ? null : (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                gradient: isStreaming
                    ? null
                    : const LinearGradient(
                        colors: [Color(0xFFFF5252), Color(0xFFFF3838)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                color: isStreaming ? const Color(0xFF282836) : null,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: isStreaming ? null : () => _sendMessage(),
                icon: isStreaming
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white54,
                        ),
                      )
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Conversation Selector Drawer / Modal Sheet
class _ConversationDrawerSheet extends ConsumerWidget {
  const _ConversationDrawerSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatViewModelProvider);
    final viewModel = ref.read(chatViewModelProvider.notifier);

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF161622),
          borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Coaching Conversations',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  viewModel.resetToNewChat();
                },
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('New Chat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5252),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Expanded(
            child: chatState.conversations.isEmpty
                ? const Center(
                    child: Text(
                      'No previous conversations yet.',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  )
                : ListView.builder(
                    itemCount: chatState.conversations.length,
                    itemBuilder: (context, index) {
                      final conv = chatState.conversations[index];
                      final isSelected = chatState.currentConversation?.id == conv.id;

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: Material(
                          color: isSelected
                              ? const Color(0xFF2979FF).withValues(alpha: 0.15)
                              : const Color(0xFF1E1E2C),
                          borderRadius: BorderRadius.circular(12),
                          clipBehavior: Clip.antiAlias,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF2979FF)
                                    : const Color(0xFF2C2C3E),
                                width: isSelected ? 1.4 : 1.0,
                              ),
                            ),
                            child: ListTile(
                              leading: Icon(
                                Icons.chat_bubble_outline_rounded,
                                color: isSelected
                                    ? const Color(0xFF2979FF)
                                    : Colors.white54,
                                size: 20,
                              ),
                              title: Text(
                                conv.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                              subtitle: Text(
                                conv.topic ?? 'General Advice',
                                style: const TextStyle(color: Colors.white38, fontSize: 12),
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, color: Colors.white38, size: 18),
                                onPressed: () => viewModel.deleteConversation(conv.id),
                              ),
                              onTap: () {
                                viewModel.selectConversation(conv);
                                Navigator.of(context).pop();
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      ),
    );
  }
}

/// Create New Conversation Dialog
class _CreateConversationDialog extends ConsumerStatefulWidget {
  const _CreateConversationDialog();

  @override
  ConsumerState<_CreateConversationDialog> createState() =>
      _CreateConversationDialogState();
}

class _CreateConversationDialogState extends ConsumerState<_CreateConversationDialog> {
  final TextEditingController _titleController = TextEditingController();
  String _selectedTopic = 'Workout Plan';

  final List<String> _topics = [
    'Workout Plan',
    'Form Tips',
    'Nutrition & Recovery',
    'Progression & 1RM',
    'General Fitness',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Start New Conversation',
        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Topic', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _topics.map((topic) {
                final isSelected = _selectedTopic == topic;
                return ChoiceChip(
                  label: Text(topic, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : Colors.white70)),
                  selected: isSelected,
                  selectedColor: const Color(0xFFFF5252),
                  backgroundColor: const Color(0xFF282838),
                  side: BorderSide.none,
                  onSelected: (val) {
                    if (val) setState(() => _selectedTopic = topic);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 14),
            const Text('Custom Title (Optional)', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'e.g. Chest Hypertrophy Focus',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF282838),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF5252),
            foregroundColor: Colors.white,
          ),
          onPressed: () {
            final title = _titleController.text.trim().isNotEmpty
                ? _titleController.text.trim()
                : _selectedTopic;
            ref.read(chatViewModelProvider.notifier).createConversation(
                  title: title,
                  topic: _selectedTopic,
                );
            Navigator.of(context).pop();
          },
          child: const Text('Create'),
        ),
      ],
    );
  }
}
