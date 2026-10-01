import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymtrack/models/user_model.dart';
import 'package:gymtrack/providers/auth_provider.dart';
import 'package:gymtrack/providers/leaderboard_provider.dart';
import 'package:gymtrack/views/leaderboard/leaderboard_view.dart';

class MockLeaderboardRepository implements ILeaderboardRepository {
  List<LeaderboardEntryModel> globalList = [
    const LeaderboardEntryModel(
      userId: 1,
      username: 'IronChad',
      rank: 1,
      level: 15,
      streak: 21,
      totalVolume: 45000,
      weeklyVolume: 12000,
    ),
    const LeaderboardEntryModel(
      userId: 2,
      username: 'SarahGains',
      rank: 2,
      level: 12,
      streak: 14,
      totalVolume: 38000,
      weeklyVolume: 9500,
    ),
    const LeaderboardEntryModel(
      userId: 3,
      username: 'PowerBeast',
      rank: 3,
      level: 10,
      streak: 7,
      totalVolume: 32000,
      weeklyVolume: 8200,
    ),
    const LeaderboardEntryModel(
      userId: 4,
      username: 'AlexMiller',
      rank: 4,
      level: 8,
      streak: 5,
      totalVolume: 24000,
      weeklyVolume: 5100,
      isCurrentUser: true,
    ),
    const LeaderboardEntryModel(
      userId: 5,
      username: 'ElenaRostova',
      rank: 5,
      level: 6,
      streak: 3,
      totalVolume: 18000,
      weeklyVolume: 4200,
    ),
  ];

  List<LeaderboardEntryModel> weeklyList = [
    const LeaderboardEntryModel(
      userId: 1,
      username: 'IronChad',
      rank: 1,
      level: 15,
      streak: 21,
      weeklyVolume: 12000,
    ),
    const LeaderboardEntryModel(
      userId: 2,
      username: 'SarahGains',
      rank: 2,
      level: 12,
      streak: 14,
      weeklyVolume: 9500,
    ),
    const LeaderboardEntryModel(
      userId: 4,
      username: 'AlexMiller',
      rank: 3,
      level: 8,
      streak: 5,
      weeklyVolume: 8200,
      isCurrentUser: true,
    ),
  ];

  List<LeaderboardEntryModel> friendsList = [
    const LeaderboardEntryModel(
      userId: 4,
      username: 'AlexMiller',
      rank: 1,
      level: 8,
      streak: 5,
      totalVolume: 24000,
      isCurrentUser: true,
    ),
    const LeaderboardEntryModel(
      userId: 2,
      username: 'SarahGains',
      rank: 2,
      level: 12,
      streak: 14,
      totalVolume: 22000,
    ),
  ];

  @override
  Future<List<LeaderboardEntryModel>> getGlobalLeaderboard({int limit = 50}) async {
    return globalList.take(limit).toList();
  }

  @override
  Future<List<LeaderboardEntryModel>> getWeeklyLeaderboard({int limit = 50}) async {
    return weeklyList.take(limit).toList();
  }

  @override
  Future<List<LeaderboardEntryModel>> getFriendsLeaderboard({int limit = 50}) async {
    return friendsList.take(limit).toList();
  }
}

void main() {
  const testUser = UserModel(
    id: 4,
    username: 'AlexMiller',
    email: 'alex@example.com',
    level: 8,
    streak: 5,
    totalXp: 24000,
  );

  Widget createWidgetUnderTest({MockLeaderboardRepository? mockRepo}) {
    final repo = mockRepo ?? MockLeaderboardRepository();
    return ProviderScope(
      overrides: [
        leaderboardRepositoryProvider.overrideWithValue(repo),
        currentUserProvider.overrideWithValue(testUser),
      ],
      child: const MaterialApp(
        home: LeaderboardView(),
      ),
    );
  }

  group('LeaderboardView Widget Tests (HRD-33)', () {
    testWidgets('Renders Leaderboard title, 3 tabs, and search bar', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Leaderboard'), findsOneWidget);
      expect(find.text('Global'), findsOneWidget);
      expect(find.text('Weekly'), findsOneWidget);
      expect(find.text('Friends'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('Renders top 3 podium pillars with Gold, Silver, Bronze badges', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Top 3 athletes on the podium
      expect(find.text('IronChad'), findsOneWidget);
      expect(find.text('SarahGains'), findsOneWidget);
      expect(find.text('PowerBeast'), findsOneWidget);

      expect(find.text('1st'), findsOneWidget);
      expect(find.text('2nd'), findsOneWidget);
      expect(find.text('3rd'), findsOneWidget);
      expect(find.text('#1'), findsOneWidget);
      expect(find.text('#2'), findsOneWidget);
      expect(find.text('#3'), findsOneWidget);
    });

    testWidgets('Renders remaining ranks list and highlights current user with YOU badge', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Rank 4 is AlexMiller (the current user)
      expect(find.text('AlexMiller'), findsWidgets);
      expect(find.text('YOU'), findsWidgets);
      expect(find.text('#4'), findsWidgets);

      // Rank 5 ElenaRostova
      expect(find.text('ElenaRostova'), findsOneWidget);
      expect(find.text('#5'), findsOneWidget);

      // Pinned bottom standing bar
      expect(find.text('Your Standing'), findsOneWidget);
    });

    testWidgets('Switches to Weekly tab on tap and updates rankings', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Weekly'));
      await tester.pumpAndSettle();

      // In Weekly tab, AlexMiller is 3rd place!
      expect(find.text('Weekly Volume (kg)'), findsOneWidget);
      expect(find.text('3rd'), findsOneWidget);
    });

    testWidgets('Switches to Friends tab on tap', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Friends'));
      await tester.pumpAndSettle();

      // In Friends tab, AlexMiller is #1
      expect(find.text('AlexMiller'), findsWidgets);
    });

    testWidgets('Tapping user opens User Profile Preview bottom sheet', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap on IronChad on podium
      await tester.tap(find.text('IronChad'));
      await tester.pumpAndSettle();

      // Profile preview bottom sheet is shown
      expect(find.text('Elite Podium Athlete'), findsOneWidget);
      expect(find.text('LEVEL'), findsOneWidget);
      expect(find.text('STREAK'), findsOneWidget);
      expect(find.text('VOLUME'), findsOneWidget);
      expect(find.text('Cheer 👊'), findsOneWidget);
      expect(find.text('Challenge ⚔️'), findsOneWidget);

      // Tap Cheer button
      await tester.tap(find.text('Cheer 👊'));
      await tester.pumpAndSettle();

      expect(find.text('Sent cheer to IronChad! 👊'), findsOneWidget);
    });

    testWidgets('Filtering via search bar dynamically filters athletes', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Enter search term
      await tester.enterText(find.byType(TextField), 'Elena');
      await tester.pumpAndSettle();

      expect(find.text('ElenaRostova'), findsOneWidget);
      expect(find.text('IronChad'), findsNothing);
    });
  });
}
