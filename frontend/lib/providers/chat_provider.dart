import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_model.dart';
import '../repositories/chat_repository.dart';
import '../viewmodels/chat/chat_viewmodel.dart';

export '../models/chat_model.dart';
export '../repositories/chat_repository.dart';
export '../viewmodels/chat/chat_viewmodel.dart';

/// Provider alias for chat/coach state management
final chatProvider = chatViewModelProvider;

/// FutureProvider to fetch all user conversations
final conversationsListProvider =
    FutureProvider.family<List<ConversationModel>, int>((ref, page) async {
  final repo = ref.watch(chatRepositoryProvider);
  return await repo.getConversations(page: page);
});

/// FutureProvider to fetch conversation history for a specific conversation ID
final chatHistoryProvider =
    FutureProvider.family<ConversationModel, int>((ref, conversationId) async {
  final repo = ref.watch(chatRepositoryProvider);
  return await repo.getConversation(conversationId);
});

/// StreamProvider to stream AI agent responses
final chatStreamProvider =
    StreamProvider.family<String, ({String message, int? conversationId})>((ref, args) {
  final repo = ref.watch(chatRepositoryProvider);
  return repo.streamChatMessage(args.message, conversationId: args.conversationId);
});
