import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/chat_model.dart';
import '../../repositories/chat_repository.dart';

class ChatState {
  final List<ConversationModel> conversations;
  final ConversationModel? currentConversation;
  final List<ChatMessageModel> messages;
  final bool isLoading;
  final bool isStreaming;
  final String? errorMessage;
  final String currentStreamingResponse;

  const ChatState({
    this.conversations = const [],
    this.currentConversation,
    this.messages = const [],
    this.isLoading = false,
    this.isStreaming = false,
    this.errorMessage,
    this.currentStreamingResponse = '',
  });

  ChatState copyWith({
    List<ConversationModel>? conversations,
    ConversationModel? currentConversation,
    List<ChatMessageModel>? messages,
    bool? isLoading,
    bool? isStreaming,
    String? errorMessage,
    String? currentStreamingResponse,
    bool clearError = false,
  }) {
    return ChatState(
      conversations: conversations ?? this.conversations,
      currentConversation: currentConversation ?? this.currentConversation,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isStreaming: isStreaming ?? this.isStreaming,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      currentStreamingResponse:
          currentStreamingResponse ?? this.currentStreamingResponse,
    );
  }
}

class ChatViewModel extends Notifier<ChatState> {
  late final IChatRepository _chatRepository;

  @override
  ChatState build() {
    _chatRepository = ref.watch(chatRepositoryProvider);
    return const ChatState();
  }

  Future<void> fetchConversations({int page = 1, int limit = 20}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final convs = await _chatRepository.getConversations(page: page, limit: limit);
      if (!ref.mounted) return;
      state = state.copyWith(conversations: convs, isLoading: false);
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to fetch conversations: ${e.toString()}',
      );
    }
  }

  Future<ConversationModel?> createConversation({String? title, String? topic}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final newConv = await _chatRepository.createConversation(
        title: title,
        topic: topic,
      );
      if (!ref.mounted) return newConv;
      state = state.copyWith(
        conversations: [newConv, ...state.conversations],
        currentConversation: newConv,
        messages: [],
        isLoading: false,
      );
      return newConv;
    } catch (e) {
      if (!ref.mounted) return null;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to create conversation: ${e.toString()}',
      );
      return null;
    }
  }

  Future<void> fetchChatHistory(int conversationId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final conv = await _chatRepository.getConversation(conversationId);
      if (!ref.mounted) return;
      state = state.copyWith(
        currentConversation: conv,
        messages: conv.messages,
        isLoading: false,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to fetch messages: ${e.toString()}',
      );
    }
  }

  Future<void> streamChatMessage(String message) async {
    if (message.trim().isEmpty) return;

    final userMessage = ChatMessageModel(
      conversationId: state.currentConversation?.id,
      role: 'user',
      content: message.trim(),
      createdAt: DateTime.now(),
    );

    // Append user message immediately
    state = state.copyWith(
      messages: [...state.messages, userMessage],
      isStreaming: true,
      currentStreamingResponse: '',
      clearError: true,
    );

    try {
      final stream = _chatRepository.streamChatMessage(
        message,
        conversationId: state.currentConversation?.id,
      );

      String accumulatedResponse = '';

      await for (final chunk in stream) {
        if (!ref.mounted) return;
        accumulatedResponse += chunk;
        state = state.copyWith(
          currentStreamingResponse: accumulatedResponse,
        );
      }

      if (!ref.mounted) return;

      // Finalize assistant message into history
      final assistantMessage = ChatMessageModel(
        conversationId: state.currentConversation?.id,
        role: 'assistant',
        content: accumulatedResponse,
        createdAt: DateTime.now(),
      );

      state = state.copyWith(
        messages: [...state.messages, assistantMessage],
        isStreaming: false,
        currentStreamingResponse: '',
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isStreaming: false,
        errorMessage: 'Chat response interrupted: ${e.toString()}',
      );
    }
  }
}

final chatViewModelProvider =
    NotifierProvider<ChatViewModel, ChatState>(() {
  return ChatViewModel();
});
