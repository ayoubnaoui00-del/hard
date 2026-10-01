import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymtrack/models/chat_model.dart';
import 'package:gymtrack/repositories/chat_repository.dart';
import 'package:gymtrack/views/coach/coach_view.dart';

class MockChatRepository implements IChatRepository {
  List<ConversationModel> conversations = [
    ConversationModel(
      id: 1,
      userId: 1,
      title: 'Hypertrophy Advice',
      topic: 'Workout Plan',
      messages: [
        ChatMessageModel(
          id: 1,
          conversationId: 1,
          role: 'user',
          content: 'How many sets per week for chest?',
          createdAt: DateTime(2026, 10, 1, 10, 0),
        ),
        ChatMessageModel(
          id: 2,
          conversationId: 1,
          role: 'assistant',
          content: 'Aim for 12 to 16 direct weekly working sets for optimal hypertrophy.',
          createdAt: DateTime(2026, 10, 1, 10, 1),
        ),
      ],
      createdAt: DateTime(2026, 10, 1, 10, 0),
      updatedAt: DateTime(2026, 10, 1, 10, 1),
    ),
  ];

  @override
  Future<List<ConversationModel>> getConversations({int page = 1, int limit = 20}) async {
    return conversations;
  }

  @override
  Future<ConversationModel> getConversation(int id) async {
    return conversations.firstWhere((c) => c.id == id);
  }

  @override
  Future<ConversationModel> createConversation({String? title, String? topic}) async {
    final newConv = ConversationModel(
      id: conversations.length + 1,
      userId: 1,
      title: title ?? topic ?? 'New Routine',
      topic: topic ?? 'General Coaching',
      messages: [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    conversations.insert(0, newConv);
    return newConv;
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
    yield 'Great question! ';
    yield 'Focus on progressive overload ';
    yield 'and consistent recovery.';
  }
}

void main() {
  Widget createWidgetUnderTest({MockChatRepository? mockRepo}) {
    final repo = mockRepo ?? MockChatRepository();
    return ProviderScope(
      overrides: [
        chatRepositoryProvider.overrideWithValue(repo),
      ],
      child: const MaterialApp(
        home: CoachView(),
      ),
    );
  }

  group('CoachView / ChatScreen Widget Tests (HRD-34)', () {
    testWidgets('Renders header with status indicator and existing messages', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Title & Online status
      expect(find.text('Hypertrophy Advice'), findsOneWidget);
      expect(find.text('Online & Ready'), findsOneWidget);

      // Existing messages
      expect(find.text('How many sets per week for chest?'), findsOneWidget);
      expect(
        find.text('Aim for 12 to 16 direct weekly working sets for optimal hypertrophy.'),
        findsOneWidget,
      );

      // Input field
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Submitting a message streams response into chat bubbles', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Enter message and submit
      await tester.enterText(find.byType(TextField), 'What about deadlifts?');
      await tester.pumpAndSettle();

      // Tap send button
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      // Verify user message appeared immediately
      expect(find.text('What about deadlifts?'), findsOneWidget);

      // Let stream complete
      await tester.pumpAndSettle();

      // Verify streamed assistant message
      expect(
        find.text('Great question! Focus on progressive overload and consistent recovery.'),
        findsOneWidget,
      );
    });

    testWidgets('Tapping quick prompt sends message directly', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap first quick prompt chip
      expect(find.text('💪 Recommend 4-day Routine'), findsOneWidget);
      await tester.tap(find.text('💪 Recommend 4-day Routine'));
      await tester.pump();

      // User message sent
      expect(
        find.text('Can you recommend a balanced 4-day upper/lower hypertrophy workout split?'),
        findsOneWidget,
      );

      await tester.pumpAndSettle();
    });

    testWidgets('Conversation selector modal shows chat history and new chat button', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap history icon
      await tester.tap(find.byIcon(Icons.history_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Coaching Conversations'), findsOneWidget);
      expect(find.text('New Chat'), findsOneWidget);
      expect(find.text('Hypertrophy Advice'), findsWidgets);
    });

    testWidgets('Create new conversation dialog creates topic conversation', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap Add conversation icon
      await tester.tap(find.byIcon(Icons.add_comment_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Start New Conversation'), findsOneWidget);
      expect(find.text('Form Tips'), findsOneWidget);

      // Select Form Tips chip
      await tester.tap(find.text('Form Tips'));
      await tester.pumpAndSettle();

      // Tap Create
      await tester.tap(find.text('Create'));
      await tester.pumpAndSettle();

      expect(find.text('Form Tips'), findsOneWidget);
    });
  });
}
