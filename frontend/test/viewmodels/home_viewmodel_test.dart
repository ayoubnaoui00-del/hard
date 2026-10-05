import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymtrack/models/achievement_model.dart';
import 'package:gymtrack/models/user_model.dart';
import 'package:gymtrack/models/workout_model.dart';
import 'package:gymtrack/repositories/achievement_repository.dart';
import 'package:gymtrack/repositories/auth_repository.dart';
import 'package:gymtrack/repositories/workout_repository.dart';
import 'package:gymtrack/viewmodels/home/home_viewmodel.dart';
import 'package:gymtrack/views/home/home_view.dart';

class FakeAuthRepository implements IAuthRepository {
  UserModel? mockUser;

  @override
  Future<UserModel> register({
    required String username,
    required String email,
    required String password,
  }) async =>
      mockUser!;

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async =>
      mockUser!;

  @override
  Future<void> logout() async {}

  @override
  Future<String?> refreshToken() async => 'fake_refresh_token';

  @override
  Future<UserModel?> getCurrentUser() async => mockUser;

  @override
  Future<bool> isAuthenticated() async => mockUser != null;
}

class FakeWorkoutRepository implements IWorkoutRepository {
  List<WorkoutModel> mockWorkouts = [];

  @override
  Future<List<WorkoutModel>> getWorkouts({int page = 1, int limit = 20}) async =>
      List.from(mockWorkouts);

  @override
  Future<WorkoutModel> getWorkoutById(dynamic id) async => mockWorkouts.first;

  @override
  Future<WorkoutModel> createWorkout({
    required String name,
    DateTime? date,
    int? duration,
    String? notes,
    required List<WorkoutExerciseModel> exercises,
  }) async =>
      mockWorkouts.first;

  @override
  Future<WorkoutModel> updateWorkout(
    dynamic id, {
    String? name,
    DateTime? date,
    int? duration,
    String? notes,
    List<WorkoutExerciseModel>? exercises,
  }) async =>
      mockWorkouts.first;

  @override
  Future<void> deleteWorkout(dynamic id) async {}

  @override
  double calculateVolume(List<WorkoutExerciseModel> exercises) =>
      WorkoutModel.calculateVolume(exercises);
}

class FakeAchievementRepository implements IAchievementRepository {
  List<AchievementModel> mockAchievements = [];

  @override
  Future<List<AchievementModel>> getUserAchievements() async =>
      mockAchievements;
}

void main() {
  group('HomeViewModel & Dashboard Tests', () {
    late FakeAuthRepository fakeAuth;
    late FakeWorkoutRepository fakeWorkout;
    late FakeAchievementRepository fakeAchievement;
    late ProviderContainer container;

    setUp(() {
      fakeAuth = FakeAuthRepository()
        ..mockUser = const UserModel(
          id: 42,
          username: 'Ayoub',
          email: 'ayoub@example.com',
          level: 3,
          xp: 750,
          totalXp: 1750,
          streak: 5,
        );

      final now = DateTime.now();
      fakeWorkout = FakeWorkoutRepository()
        ..mockWorkouts = [
          WorkoutModel(
            id: 1,
            userId: 42,
            name: 'Chest Pump',
            date: now,
            duration: 45,
            totalVolume: 3200.0,
          ),
          WorkoutModel(
            id: 2,
            userId: 42,
            name: 'Leg Day',
            date: now.subtract(const Duration(days: 2)),
            duration: 60,
            totalVolume: 5800.0,
          ),
        ];

      fakeAchievement = FakeAchievementRepository()
        ..mockAchievements = AchievementModel.sampleAchievements;

      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeAuth),
          workoutRepositoryProvider.overrideWithValue(fakeWorkout),
          achievementRepositoryProvider.overrideWithValue(fakeAchievement),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial build computes level progress and loads defaults', () {
      final state = container.read(homeViewModelProvider);
      expect(state.level, greaterThanOrEqualTo(1));
      expect(state.recentAchievements.isNotEmpty, isTrue);
    });

    test('loadDashboard populates user, workouts, and volume', () async {
      final notifier = container.read(homeViewModelProvider.notifier);
      await notifier.loadDashboard();

      final state = container.read(homeViewModelProvider);
      expect(state.displayName, 'Ayoub');
      expect(state.level, 3);
      expect(state.streakDays, 5);
      expect(state.workoutsToday, 1);
      expect(state.todayVolume, 3200.0);
      expect(state.weeklyVolume, 9000.0); // 3200 + 5800
      expect(state.recentAchievements.length, 3);
      expect(state.isLoading, isFalse);
    });

    testWidgets('HomeView renders dashboard sections properly', (tester) async {
      tester.view.physicalSize = const Size(800, 1800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: HomeView(),
          ),
        ),
      );

      // Wait for microtask / initial load
      await tester.pumpAndSettle();

      // Check Header & Velocity Branding
      expect(find.text('VELOCITY'), findsOneWidget);

      // Check Program & Check-In Cards
      expect(find.text('Your Program'), findsOneWidget);
      expect(find.text('Check-In'), findsOneWidget);

      // Check Line-Up Section
      expect(find.text("How's Your Workout Line-Up !"), findsOneWidget);
      expect(find.text('Conditioning: Body Movement'), findsOneWidget);
      expect(find.text('Sonic Meditation'), findsOneWidget);

      // Check Workout Cards
      expect(find.text('Ultimate'), findsOneWidget);
      expect(find.text('Dumbbell'), findsOneWidget);
      expect(find.text('Lower'), findsOneWidget);

      // Check Performance Metrics
      expect(find.text('Performance Metrics'), findsOneWidget);
      expect(find.text('Streak'), findsOneWidget);
      expect(find.text('Weekly Vol'), findsOneWidget);
      expect(find.text('This Month'), findsOneWidget);

      // Check Recent Achievements
      expect(find.text('Recent Achievements'), findsOneWidget);
    });
  });
}
