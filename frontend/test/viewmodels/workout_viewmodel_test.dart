import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymtrack/models/workout_model.dart';
import 'package:gymtrack/repositories/workout_repository.dart';
import 'package:gymtrack/viewmodels/workout/workout_viewmodel.dart';

class FakeWorkoutRepository implements IWorkoutRepository {
  List<WorkoutModel> mockWorkouts = [];

  @override
  Future<List<WorkoutModel>> getWorkouts({int page = 1, int limit = 20}) async {
    return List.from(mockWorkouts);
  }

  @override
  Future<WorkoutModel> getWorkoutById(dynamic id) async {
    return mockWorkouts.firstWhere(
      (w) => w.id == id,
      orElse: () => WorkoutModel(
        id: id,
        userId: 1,
        name: 'Mock Workout',
        date: DateTime.now(),
      ),
    );
  }

  @override
  Future<WorkoutModel> createWorkout({
    required String name,
    DateTime? date,
    int? duration,
    String? notes,
    required List<WorkoutExerciseModel> exercises,
  }) async {
    final created = WorkoutModel(
      id: mockWorkouts.length + 1,
      userId: 1,
      name: name,
      date: date ?? DateTime.now(),
      duration: duration ?? 45,
      totalVolume: calculateVolume(exercises),
      notes: notes,
      workoutExercises: exercises,
    );
    mockWorkouts.insert(0, created);
    return created;
  }

  @override
  Future<WorkoutModel> updateWorkout(
    dynamic id, {
    String? name,
    DateTime? date,
    int? duration,
    String? notes,
    List<WorkoutExerciseModel>? exercises,
  }) async {
    final index = mockWorkouts.indexWhere((w) => w.id == id);
    final existing = mockWorkouts[index];
    final updated = existing.copyWith(
      name: name ?? existing.name,
      date: date ?? existing.date,
      duration: duration ?? existing.duration,
      notes: notes ?? existing.notes,
      workoutExercises: exercises ?? existing.workoutExercises,
    );
    mockWorkouts[index] = updated;
    return updated;
  }

  @override
  Future<void> deleteWorkout(dynamic id) async {
    mockWorkouts.removeWhere((w) => w.id == id);
  }

  @override
  double calculateVolume(List<WorkoutExerciseModel> exercises) {
    return WorkoutModel.calculateVolume(exercises);
  }
}

void main() {
  group('WorkoutViewModel & Volume Calculation Tests', () {
    late FakeWorkoutRepository fakeRepo;
    late ProviderContainer container;

    setUp(() {
      fakeRepo = FakeWorkoutRepository();
      fakeRepo.mockWorkouts = [
        WorkoutModel(
          id: 1,
          userId: 1,
          name: 'Chest Day',
          date: DateTime.now(),
          duration: 60,
          workoutExercises: [
            const WorkoutExerciseModel(
              exerciseId: 10,
              exerciseName: 'Bench Press',
              sets: 4,
              reps: 10,
              weight: 80.0,
            ),
          ],
        ),
      ];

      container = ProviderContainer(
        overrides: [
          workoutRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Volume calculation accurately aggregates sets * reps * weight', () {
      final exercises = [
        const WorkoutExerciseModel(
          exerciseId: 1,
          sets: 3,
          reps: 10,
          weight: 100.0, // 3000
        ),
        const WorkoutExerciseModel(
          exerciseId: 2,
          sets: 4,
          reps: 8,
          weight: 50.0, // 1600
        ),
      ];

      final totalVolume = WorkoutModel.calculateVolume(exercises);
      expect(totalVolume, 4600.0);
    });

    test('Fetch workouts populates state', () async {
      final notifier = container.read(workoutViewModelProvider.notifier);
      await notifier.fetchWorkouts();

      final state = container.read(workoutViewModelProvider);
      expect(state.isLoading, isFalse);
      expect(state.workouts.length, 1);
      expect(state.workouts.first.name, 'Chest Day');
    });

    test('Create workout prepends to list and updates total volume', () async {
      final notifier = container.read(workoutViewModelProvider.notifier);
      await notifier.fetchWorkouts();

      final newExercises = [
        const WorkoutExerciseModel(
          exerciseId: 2,
          exerciseName: 'Squat',
          sets: 5,
          reps: 5,
          weight: 120.0,
        ),
      ];

      final created = await notifier.createWorkout(
        name: 'Leg Day',
        duration: 50,
        exercises: newExercises,
      );

      expect(created, isNotNull);
      expect(created!.name, 'Leg Day');
      expect(created.totalVolume, 3000.0);

      final state = container.read(workoutViewModelProvider);
      expect(state.workouts.length, 2);
      expect(state.workouts.first.name, 'Leg Day');
    });

    test('Delete workout removes it from state list', () async {
      final notifier = container.read(workoutViewModelProvider.notifier);
      await notifier.fetchWorkouts();

      final success = await notifier.deleteWorkout(1);
      expect(success, isTrue);

      final state = container.read(workoutViewModelProvider);
      expect(state.workouts, isEmpty);
    });
  });
}
