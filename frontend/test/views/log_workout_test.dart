import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymtrack/models/exercise_model.dart';
import 'package:gymtrack/models/workout_model.dart';
import 'package:gymtrack/repositories/exercise_repository.dart';
import 'package:gymtrack/repositories/workout_repository.dart';
import 'package:gymtrack/views/workout/log_workout_view.dart';
import 'package:gymtrack/viewmodels/home/home_viewmodel.dart';

class FakeWorkoutRepository implements IWorkoutRepository {
  List<WorkoutModel> createdWorkouts = [];

  @override
  Future<List<WorkoutModel>> getWorkouts({int page = 1, int limit = 20}) async => [];

  @override
  Future<WorkoutModel> getWorkoutById(dynamic id) async {
    return createdWorkouts.first;
  }

  @override
  Future<WorkoutModel> createWorkout({
    required String name,
    DateTime? date,
    int? duration,
    String? notes,
    required List<WorkoutExerciseModel> exercises,
  }) async {
    final workout = WorkoutModel(
      id: 'mock-${createdWorkouts.length + 1}',
      userId: 1,
      name: name,
      date: date ?? DateTime.now(),
      duration: duration ?? 45,
      totalVolume: calculateVolume(exercises),
      notes: notes,
      workoutExercises: exercises,
    );
    createdWorkouts.add(workout);
    return workout;
  }

  @override
  Future<WorkoutModel> updateWorkout(
    dynamic id, {
    String? name,
    DateTime? date,
    int? duration,
    String? notes,
    List<WorkoutExerciseModel>? exercises,
  }) async =>
      createdWorkouts.first;

  @override
  Future<void> deleteWorkout(dynamic id) async {}

  @override
  double calculateVolume(List<WorkoutExerciseModel> exercises) =>
      WorkoutModel.calculateVolume(exercises);
}

class FakeExerciseRepository implements IExerciseRepository {
  @override
  Future<List<ExerciseModel>> getExercises({
    String? muscle,
    String? search,
    int page = 1,
    int limit = 50,
  }) async {
    return const [
      ExerciseModel(
        id: 'bench-001',
        name: 'Barbell Bench Press',
        muscleGroup: 'Chest',
      ),
      ExerciseModel(
        id: 'squat-001',
        name: 'Barbell Squat',
        muscleGroup: 'Legs',
      ),
    ];
  }

  @override
  Future<ExercisePageResponse> getExercisesPaginated({
    String? muscle,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    final list = await getExercises(
      muscle: muscle,
      search: search,
      page: page,
      limit: limit,
    );
    return ExercisePageResponse(
      exercises: list,
      total: list.length,
      page: page,
      totalPages: 1,
      hasMore: false,
    );
  }

  @override
  Future<ExerciseModel?> getExerciseById(String id) async {
    return const ExerciseModel(
      id: 'bench-001',
      name: 'Barbell Bench Press',
      muscleGroup: 'Chest',
    );
  }
}

class MockHomeViewModel extends HomeViewModel {
  @override
  HomeState build() => const HomeState();

  @override
  Future<void> refresh() async {}
}

void main() {
  late FakeWorkoutRepository fakeWorkoutRepo;
  late FakeExerciseRepository fakeExerciseRepo;

  setUp(() {
    fakeWorkoutRepo = FakeWorkoutRepository();
    fakeExerciseRepo = FakeExerciseRepository();
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        workoutRepositoryProvider.overrideWithValue(fakeWorkoutRepo),
        exerciseRepositoryProvider.overrideWithValue(fakeExerciseRepo),
        homeViewModelProvider.overrideWith(() => MockHomeViewModel()),
      ],
      child: const MaterialApp(
        home: LogWorkoutView(),
      ),
    );
  }

  group('LogWorkoutView Widget Tests (HRD-31)', () {
    testWidgets('Renders all logging sections and initial exercise row', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Header title
      expect(find.text('Log Workout'), findsWidgets);

      // Workout Name text field
      expect(find.byType(TextFormField), findsWidgets);
      expect(find.text('Workout Session'), findsOneWidget);

      // Duration selector chips: 30m, 45m, 60m, 90m
      expect(find.text('30m'), findsOneWidget);
      expect(find.text('45m'), findsOneWidget);
      expect(find.text('60m'), findsOneWidget);
      expect(find.text('90m'), findsOneWidget);

      // Initial default exercise row
      expect(find.text('Barbell Bench Press'), findsOneWidget);
      expect(find.text('Chest'), findsOneWidget);

      // Summary bar exists (Total Sets, Total Volume)
      expect(find.text('Total Sets'), findsOneWidget);
      expect(find.text('Total Volume'), findsOneWidget);

      // Add Exercise and Body Map buttons
      expect(find.text('Add Exercise'), findsOneWidget);
      expect(find.text('Body Map'), findsOneWidget);

      // Submit button
      expect(find.widgetWithText(ElevatedButton, 'Log Workout'), findsOneWidget);
    });

    testWidgets('Tapping duration chip updates selected duration', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap 60m chip
      await tester.tap(find.text('60m'));
      await tester.pumpAndSettle();

      // Verify TextFormField with duration controller has '60'
      final textFields = tester.widgetList<TextFormField>(find.byType(TextFormField));
      final durationField = textFields.firstWhere((f) => f.controller?.text == '60');
      expect(durationField.controller?.text, '60');
    });

    testWidgets('Calculates session volume dynamically and responds to steppers', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Default: 3 sets * 10 reps * 60 kg = 1,800 kg
      expect(find.text('1,800 kg'), findsOneWidget);

      // Tap '+' on the first stepper (Sets: from 3 to 4)
      final addIcons = find.byIcon(Icons.add_rounded);
      await tester.tap(addIcons.first);
      await tester.pumpAndSettle();

      // Now: 4 sets * 10 reps * 60 kg = 2,400 kg
      expect(find.text('2,400 kg'), findsOneWidget);
    });

    testWidgets('Shows validation error if all exercises removed and submit is tapped', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Remove the initial exercise
      final removeBtn = find.byIcon(Icons.delete_outline_rounded);
      expect(removeBtn, findsOneWidget);
      await tester.tap(removeBtn);
      await tester.pumpAndSettle();

      // Empty state prompt is shown
      expect(find.text('No exercises added yet'), findsOneWidget);

      // Tap Submit button
      await tester.tap(find.widgetWithText(ElevatedButton, 'Log Workout'));
      await tester.pumpAndSettle();

      // Error message is displayed in error banner
      expect(find.text('At least 1 exercise is required.'), findsOneWidget);
      expect(fakeWorkoutRepo.createdWorkouts, isEmpty);
    });

    testWidgets('Submitting creates workout successfully via repository', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap Submit button
      final saveBtn = find.widgetWithText(ElevatedButton, 'Log Workout');
      expect(saveBtn, findsOneWidget);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      // Verify FakeWorkoutRepository received workout
      expect(fakeWorkoutRepo.createdWorkouts.length, 1);
      final saved = fakeWorkoutRepo.createdWorkouts.first;
      expect(saved.name, 'Workout Session');
      expect(saved.duration, 45);
      expect(saved.workoutExercises.length, 1);
      expect(saved.workoutExercises.first.exerciseName, 'Barbell Bench Press');
      expect(saved.totalVolume, 1800.0);
    });
  });
}
