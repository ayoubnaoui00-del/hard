import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymtrack/models/achievement_model.dart';
import 'package:gymtrack/models/leaderboard_model.dart';
import 'package:gymtrack/models/user_model.dart';
import 'package:gymtrack/models/workout_model.dart';
import 'package:gymtrack/providers/auth_provider.dart';
import 'package:gymtrack/repositories/achievement_repository.dart';
import 'package:gymtrack/repositories/leaderboard_repository.dart';
import 'package:gymtrack/repositories/user_repository.dart';
import 'package:gymtrack/repositories/workout_repository.dart';
import 'package:gymtrack/views/profile/profile_view.dart';

class MockUserRepository implements IUserRepository {
  UserModel user = const UserModel(
    id: 1,
    username: 'MarcusTitan',
    email: 'marcus@ironhard.com',
    level: 12,
    streak: 18,
    totalXp: 5400,
  );

  @override
  Future<UserModel> getCurrentProfile() async => user;

  @override
  Future<UserModel?> getUser(int userId) async => user;

  @override
  Future<UserModel> updateProfile({String? username, String? email, String? avatarUrl}) async {
    user = user.copyWith(
      username: username ?? user.username,
      email: email ?? user.email,
      avatarUrl: avatarUrl ?? user.avatarUrl,
    );
    return user;
  }

  @override
  Future<void> cacheUser(UserModel user) async {}

  @override
  Future<UserModel?> getCachedUser() async => user;

  @override
  Future<void> clearUserCache() async {}
}

class MockWorkoutRepository implements IWorkoutRepository {
  List<WorkoutModel> sampleWorkouts = [
    WorkoutModel(
      id: 1,
      userId: 1,
      name: 'Heavy Leg Destruction',
      duration: 65,
      totalVolume: 8400,
      date: DateTime(2026, 10, 1, 9, 30),
      workoutExercises: const [
        WorkoutExerciseModel(
          exerciseId: 'squat-1',
          exerciseName: 'Barbell Back Squat',
          order: 1,
          sets: 5,
          reps: 5,
          weight: 140,
        ),
      ],
    ),
  ];

  @override
  Future<List<WorkoutModel>> getWorkouts({int page = 1, int limit = 20}) async => sampleWorkouts;

  @override
  Future<WorkoutModel> getWorkoutById(dynamic id) async => sampleWorkouts.first;

  @override
  Future<WorkoutModel> createWorkout({
    required String name,
    DateTime? date,
    int? duration,
    String? notes,
    required List<WorkoutExerciseModel> exercises,
  }) async =>
      sampleWorkouts.first;

  @override
  Future<WorkoutModel> updateWorkout(dynamic id, {String? name, DateTime? date, int? duration, String? notes, List<WorkoutExerciseModel>? exercises}) async =>
      sampleWorkouts.first;

  @override
  Future<void> deleteWorkout(dynamic id) async {}

  @override
  double calculateVolume(List<WorkoutExerciseModel> exercises) => 8400.0;
}

class MockAchievementRepository implements IAchievementRepository {
  @override
  Future<List<AchievementModel>> getUserAchievements() async {
    return [
      AchievementModel(
        code: 'WORKOUT_1',
        name: 'First Step',
        description: 'Completed your very first logged workout session.',
        badgeIcon: 'footsteps',
        isUnlocked: true,
      ),
      AchievementModel(
        code: 'STREAK_10',
        name: 'Iron Habit',
        description: 'Maintained a 10-day active workout streak.',
        badgeIcon: 'lightning',
        isUnlocked: true,
      ),
      AchievementModel(
        code: 'VOLUME_100K',
        name: 'Century Lifter',
        description: 'Accumulate over 100,000 kg total lifetime volume.',
        badgeIcon: 'trophy',
        isUnlocked: false,
      ),
    ];
  }
}

class MockLeaderboardRepository implements ILeaderboardRepository {
  @override
  Future<List<LeaderboardEntryModel>> getGlobalLeaderboard({int limit = 50}) async {
    return [
      LeaderboardEntryModel(
        userId: 1,
        username: 'MarcusTitan',
        rank: 3,
        level: 12,
        totalVolume: 58000,
      ),
    ];
  }

  @override
  Future<List<LeaderboardEntryModel>> getWeeklyLeaderboard({int limit = 50}) async => [];

  @override
  Future<List<LeaderboardEntryModel>> getFriendsLeaderboard({int limit = 50}) async => [];
}

void main() {
  const testUser = UserModel(
    id: 1,
    username: 'MarcusTitan',
    email: 'marcus@ironhard.com',
    level: 12,
    streak: 18,
    totalXp: 5400,
  );

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        currentUserProvider.overrideWithValue(testUser),
        userRepositoryProvider.overrideWithValue(MockUserRepository()),
        workoutRepositoryProvider.overrideWithValue(MockWorkoutRepository()),
        achievementRepositoryProvider.overrideWithValue(MockAchievementRepository()),
        leaderboardRepositoryProvider.overrideWithValue(MockLeaderboardRepository()),
      ],
      child: const MaterialApp(
        home: ProfileView(),
      ),
    );
  }

  group('ProfileView Widget Tests (HRD-35)', () {
    testWidgets('Renders all 6 core profile sections', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // 1. Header Section
      expect(find.text('MarcusTitan'), findsOneWidget);
      expect(find.text('marcus@ironhard.com'), findsOneWidget);
      expect(find.text('Edit Profile'), findsOneWidget);

      // 2. Level & XP Section
      expect(find.text('LVL 12'), findsOneWidget);
      expect(find.text('Level Progression'), findsOneWidget);

      // 3. Statistics Section
      expect(find.text('ATHLETE STATISTICS'), findsOneWidget);
      expect(find.text('Workouts'), findsOneWidget);
      expect(find.text('Current Streak'), findsOneWidget);
      expect(find.text('18 Days'), findsOneWidget);
      expect(find.text('Rank'), findsOneWidget);
      expect(find.text('#3'), findsOneWidget);

      // 4. Achievements Section
      expect(find.text('ACHIEVEMENTS & BADGES'), findsOneWidget);
      expect(find.text('First Step'), findsOneWidget);
      expect(find.text('Iron Habit'), findsOneWidget);

      // 5. Recent Workouts Section
      expect(find.text('RECENT WORKOUTS (LAST 5)'), findsOneWidget);
      expect(find.text('Heavy Leg Destruction'), findsOneWidget);

      // 6. Settings Section
      expect(find.text('Change Password'), findsOneWidget);
      expect(find.text('Log Out'), findsOneWidget);
      expect(find.text('Delete Account'), findsOneWidget);
    });

    testWidgets('Toggling volume unit switches between kg and lbs', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Unit: kg'), findsOneWidget);

      // Tap toggle
      await tester.tap(find.text('Unit: kg'));
      await tester.pumpAndSettle();

      expect(find.text('Unit: lbs'), findsOneWidget);
    });

    testWidgets('Tapping achievement card opens Achievement Details modal sheet', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap on 'Iron Habit'
      await tester.tap(find.text('Iron Habit'));
      await tester.pumpAndSettle();

      expect(find.text('Iron Habit'), findsWidgets);
      expect(find.text('UNLOCKED'), findsOneWidget);
      expect(find.text('Maintained a 10-day active workout streak.'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
    });

    testWidgets('Tapping Edit Profile opens edit modal and saves updates', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap Edit Profile button
      await tester.tap(find.text('Edit Profile'));
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Save'), findsOneWidget);

      // Tap Save
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Profile updated successfully!'), findsOneWidget);
    });
  });
}
