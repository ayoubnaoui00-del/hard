import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymtrack/models/chat_model.dart';
import 'package:gymtrack/models/leaderboard_model.dart';
import 'package:gymtrack/repositories/chat_repository.dart';
import 'package:gymtrack/repositories/leaderboard_repository.dart';
import 'package:gymtrack/viewmodels/chat/chat_viewmodel.dart';
import 'package:gymtrack/viewmodels/leaderboard/leaderboard_viewmodel.dart';

class FakeLeaderboardRepository implements ILeaderboardRepository {
  @override
  Future<List<LeaderboardEntryModel>> getGlobalLeaderboard({int limit = 50}) async {
    return [
      const LeaderboardEntryModel(
        userId: 1,
        username: 'top_lifter',
        rank: 1,
        totalXp: 12000,
      ),
      const LeaderboardEntryModel(
        userId: 2,
        username: 'runner_pro',
        rank: 2,
        totalXp: 9500,
      ),
    ];
  }

  @override
  Future<List<LeaderboardEntryModel>> getWeeklyLeaderboard({int limit = 50}) async {
    return [
      const LeaderboardEntryModel(
        userId: 2,
        username: 'runner_pro',
        rank: 1,
        weeklyXp: 1500,
      ),
    ];
  }

  @override
  Future<List<LeaderboardEntryModel>> getFriendsLeaderboard({int limit = 50}) async {
    return [
      const LeaderboardEntryModel(
        userId: 3,
        username: 'gym_buddy',
        rank: 1,
        totalXp: 3000,
      ),
    ];
  }
}

class FakeChatRepository implements IChatRepository {
  List<ConversationModel> conversations = [];

  @override
  Future<List<ConversationModel>> getConversations({int page = 1, int limit = 20}) async {
    return conversations;
  }

  @override
  Future<ConversationModel> getConversation(int id) async {
    return ConversationModel(
      id: id,
      userId: 1,
      title: 'Workout Advice',
      messages: [
        ChatMessageModel(
          id: 1,
          conversationId: id,
          role: 'assistant',
          content: 'How can I assist your workout today?',
          createdAt: DateTime.now(),
        ),
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<ConversationModel> createConversation({String? title, String? topic}) async {
    final conv = ConversationModel(
      id: conversations.length + 1,
      userId: 1,
      title: title ?? topic ?? 'New Routine',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    conversations.add(conv);
    return conv;
  }

  @override
  Future<ChatMessageModel> addMessage(
    int conversationId, {
    required String content,
    required String role,
  }) async {
    return ChatMessageModel(
      conversationId: conversationId,
      role: role,
      content: content,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> deleteConversation(int id) async {
    conversations.removeWhere((c) => c.id == id);
  }

  @override
  Stream<String> streamChatMessage(String message, {int? conversationId}) async* {
    yield 'Great job ';
    yield 'on your bench press! ';
    yield 'Keep it up!';
  }
}

void main() {
  group('LeaderboardViewModel Tests', () {
    test('Switches between global, weekly, and friends leaderboards', () async {
      final container = ProviderContainer(
        overrides: [
          leaderboardRepositoryProvider.overrideWithValue(FakeLeaderboardRepository()),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(leaderboardViewModelProvider.notifier);
      await notifier.fetchGlobalLeaderboard();

      var state = container.read(leaderboardViewModelProvider);
      expect(state.currentType, LeaderboardType.global);
      expect(state.entries.length, 2);
      expect(state.entries.first.username, 'top_lifter');

      await notifier.fetchWeeklyLeaderboard();
      state = container.read(leaderboardViewModelProvider);
      expect(state.currentType, LeaderboardType.weekly);
      expect(state.entries.length, 1);
      expect(state.entries.first.username, 'runner_pro');

      await notifier.fetchFriendsLeaderboard();
      state = container.read(leaderboardViewModelProvider);
      expect(state.currentType, LeaderboardType.friends);
      expect(state.entries.first.username, 'gym_buddy');
    });
  });

  group('ChatViewModel Streaming Tests', () {
    test('Creates conversation, streams chunks, and accumulates final assistant message', () async {
      final container = ProviderContainer(
        overrides: [
          chatRepositoryProvider.overrideWithValue(FakeChatRepository()),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(chatViewModelProvider.notifier);
      final conv = await notifier.createConversation(title: 'Bench Form Check');

      expect(conv, isNotNull);
      expect(conv!.title, 'Bench Form Check');

      await notifier.streamChatMessage('How is my arch?');

      final state = container.read(chatViewModelProvider);
      expect(state.isStreaming, isFalse);
      expect(state.messages.length, 2);
      expect(state.messages[0].role, 'user');
      expect(state.messages[0].content, 'How is my arch?');
      expect(state.messages[1].role, 'assistant');
      expect(state.messages[1].content, 'Great job on your bench press! Keep it up!');
    });
  });
}
