import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/chat_model.dart';
import '../services/api_service.dart';

abstract class IChatRepository {
  Future<List<ConversationModel>> getConversations({int page = 1, int limit = 20});
  Future<ConversationModel> getConversation(int id);
  Future<ConversationModel> createConversation({String? title, String? topic});
  Future<ChatMessageModel> addMessage(
    int conversationId, {
    required String content,
    required String role,
  });
  Future<void> deleteConversation(int id);
  Stream<String> streamChatMessage(String message, {int? conversationId});
}

class ChatRepository implements IChatRepository {
  final ApiService apiService;

  ChatRepository({required this.apiService});

  @override
  Future<List<ConversationModel>> getConversations({
    int page = 1,
    int limit = 20,
  }) async {
    final response = await apiService.get(
      '/conversations',
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );

    final responseData = response.data as Map<String, dynamic>;
    final data = responseData['data'] as Map<String, dynamic>? ?? responseData;
    final list = data['conversations'] as List<dynamic>? ?? [];

    return list
        .map((c) => ConversationModel.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ConversationModel> getConversation(int id) async {
    final response = await apiService.get('/conversations/$id');
    final responseData = response.data as Map<String, dynamic>;
    final data = responseData['data'] as Map<String, dynamic>? ?? responseData;
    final convData = data['conversation'] as Map<String, dynamic>? ?? data;

    return ConversationModel.fromJson(convData);
  }

  @override
  Future<ConversationModel> createConversation({
    String? title,
    String? topic,
  }) async {
    final response = await apiService.post(
      '/conversations',
      data: {
        if (title != null) 'title': title.trim(),
        if (topic != null) 'topic': topic.trim(),
      },
    );

    final responseData = response.data as Map<String, dynamic>;
    final data = responseData['data'] as Map<String, dynamic>? ?? responseData;

    return ConversationModel.fromJson(data);
  }

  @override
  Future<ChatMessageModel> addMessage(
    int conversationId, {
    required String content,
    required String role,
  }) async {
    final response = await apiService.post(
      '/conversations/$conversationId/messages',
      data: {
        'content': content,
        'role': role,
      },
    );

    final responseData = response.data as Map<String, dynamic>;
    final data = responseData['data'] as Map<String, dynamic>? ?? responseData;
    final msgData = data['message'] as Map<String, dynamic>? ?? data;

    return ChatMessageModel.fromJson(msgData);
  }

  @override
  Future<void> deleteConversation(int id) async {
    await apiService.delete('/conversations/$id');
  }

  @override
  Stream<String> streamChatMessage(String message, {int? conversationId}) {
    return apiService.streamChat(
      '/agent/chat',
      {
        'message': message,
        'conversationId': ?conversationId,
      },
    );
  }
}

final chatRepositoryProvider = Provider<IChatRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ChatRepository(apiService: apiService);
});
