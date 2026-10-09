import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymtrack/models/exercise_model.dart';
import 'package:gymtrack/repositories/exercise_repository.dart';
import 'package:gymtrack/views/workout/muscle_picker_view.dart';

class FakeExerciseRepository implements IExerciseRepository {
  final Map<String, List<ExerciseModel>> exercisesByMuscle = {
    'Chest': const [
      ExerciseModel(
        id: 'bench-001',
        name: 'Barbell Bench Press',
        muscleGroup: 'Chest',
        equipment: 'Barbell',
        category: 'Strength',
        instructions: 'Lower bar smoothly to mid-chest and press up.',
        formTips: 'Retract shoulder blades and plant feet firmly.',
        alternativeNames: ['Dumbbell Press', 'Push-Up'],
      ),
      ExerciseModel(
        id: 'fly-002',
        name: 'Incline Dumbbell Fly',
        muscleGroup: 'Chest',
        equipment: 'Dumbbell',
        category: 'Hypertrophy',
        instructions: 'Fly dumbbells out laterally with slight elbow bend.',
        formTips: 'Do not overstretch shoulders at bottom.',
        alternativeNames: ['Cable Fly'],
      ),
    ],
    'Back': const [
      ExerciseModel(
        id: 'deadlift-001',
        name: 'Conventional Deadlift',
        muscleGroup: 'Back',
        equipment: 'Barbell',
        category: 'Strength',
        instructions: 'Hinge hips and pull bar keeping contact with shins.',
        formTips: 'Keep back flat and engage lats.',
        alternativeNames: ['Romanian Deadlift'],
      ),
      ExerciseModel(
        id: 'pullup-002',
        name: 'Pull-Up',
        muscleGroup: 'Back',
        equipment: 'Bodyweight',
        category: 'Strength',
        instructions: 'Pull chest toward bar until chin clears.',
        formTips: 'Drive elbows down into pockets.',
        alternativeNames: ['Lat Pulldown'],
      ),
    ],
    'Shoulders': const [
      ExerciseModel(
        id: 'ohp-001',
        name: 'Overhead Press',
        muscleGroup: 'Shoulders',
        equipment: 'Barbell',
        category: 'Strength',
        instructions: 'Press bar straight overhead while squeezing glutes.',
        formTips: 'Keep core braced.',
        alternativeNames: ['Dumbbell Shoulder Press'],
      ),
    ],
    'Arms': const [
      ExerciseModel(
        id: 'curl-001',
        name: 'Biceps Curl',
        muscleGroup: 'Arms',
        equipment: 'Dumbbell',
        category: 'Hypertrophy',
        instructions: 'Curl dumbbell upward without swinging.',
        formTips: 'Keep elbows tucked.',
        alternativeNames: ['Hammer Curl'],
      ),
    ],
    'Legs': const [
      ExerciseModel(
        id: 'squat-001',
        name: 'Barbell Back Squat',
        muscleGroup: 'Legs',
        equipment: 'Barbell',
        category: 'Strength',
        instructions: 'Squat until hips pass parallel and drive up.',
        formTips: 'Keep knees tracking over toes.',
        alternativeNames: ['Front Squat', 'Leg Press'],
      ),
    ],
    'Core': const [
      ExerciseModel(
        id: 'plank-001',
        name: 'Plank',
        muscleGroup: 'Core',
        equipment: 'Bodyweight',
        category: 'Endurance',
        instructions: 'Hold static plank on forearms and toes.',
        formTips: 'Do not let hips sag.',
        alternativeNames: ['Ab Wheel'],
      ),
    ],
  };

  @override
  Future<List<ExerciseModel>> getExercises({
    String? muscle,
    String? search,
    int page = 1,
    int limit = 50,
  }) async {
    final list = exercisesByMuscle[muscle ?? 'Chest'] ?? [];
    if (search != null && search.isNotEmpty) {
      return list
          .where((e) =>
              e.name.toLowerCase().contains(search.toLowerCase()) ||
              (e.equipment?.toLowerCase().contains(search.toLowerCase()) ?? false))
          .toList();
    }
    return list;
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
    for (final list in exercisesByMuscle.values) {
      for (final ex in list) {
        if (ex.id == id) return ex;
      }
    }
    return null;
  }
}

void main() {
  late FakeExerciseRepository fakeExerciseRepo;

  setUp(() {
    fakeExerciseRepo = FakeExerciseRepository();
  });

  Widget createWidgetUnderTest({
    MuscleGroupType initialMuscle = MuscleGroupType.chest,
    ValueChanged<ExerciseModel>? onExerciseSelected,
  }) {
    return ProviderScope(
      overrides: [
        exerciseRepositoryProvider.overrideWithValue(fakeExerciseRepo),
      ],
      child: MaterialApp(
        home: MusclePickerView(
          initialMuscle: initialMuscle,
          onExerciseSelected: onExerciseSelected,
        ),
      ),
    );
  }

  group('MusclePickerView Tests (Task 5.7 / HRD-32)', () {
    testWidgets('Renders Body Map, rotate view action, and all muscle chips', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Title
      expect(find.text('Interactive Body Map'), findsOneWidget);

      // Rotate view button
      expect(find.byIcon(Icons.sync_rounded), findsWidgets);

      // All 6 muscle group chips
      expect(find.text('Chest'), findsWidgets);
      expect(find.text('Back'), findsWidgets);
      expect(find.text('Shoulders'), findsWidgets);
      expect(find.text('Arms'), findsWidgets);
      expect(find.text('Legs'), findsWidgets);
      expect(find.text('Core'), findsWidgets);

      // Default Chest exercises are displayed
      expect(find.text('Barbell Bench Press'), findsOneWidget);
      expect(find.text('Incline Dumbbell Fly'), findsOneWidget);
    });

    testWidgets('Tapping view toggle rotates between Front and Back View', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap rotate view button
      await tester.tap(find.byIcon(Icons.sync_rounded).first);
      await tester.pumpAndSettle();

      // Auto selects Back when rotated to Back View
      expect(find.text('Conventional Deadlift'), findsOneWidget);
    });

    testWidgets('Selecting muscle chip filters exercise list with form tips and alternatives', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap Legs muscle chip
      final legsChip = find.widgetWithText(InkWell, 'Legs');
      await tester.tap(legsChip);
      await tester.pumpAndSettle();

      // Legs exercise is displayed
      expect(find.text('Barbell Back Squat'), findsOneWidget);

      // Alternative exercises are shown
      expect(find.text('Front Squat'), findsOneWidget);
      expect(find.text('Leg Press'), findsOneWidget);

      // Form tips are shown on-demand when tapping exercise details
      await tester.tap(find.text('Barbell Back Squat'));
      await tester.pumpAndSettle();
      expect(find.text('Keep knees tracking over toes.'), findsOneWidget);
    });

    testWidgets('Search query filters exercises within selected muscle', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Initially both Chest exercises are visible
      expect(find.text('Barbell Bench Press'), findsOneWidget);
      expect(find.text('Incline Dumbbell Fly'), findsOneWidget);

      // Enter search term "fly"
      await tester.enterText(find.byType(TextField), 'fly');
      await tester.pumpAndSettle();

      expect(find.text('Incline Dumbbell Fly'), findsOneWidget);
      expect(find.text('Barbell Bench Press'), findsNothing);
    });

    testWidgets('Tapping "Select This Exercise" invokes callback with selected exercise', (tester) async {
      tester.view.physicalSize = const Size(1080, 1920);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      ExerciseModel? chosenExercise;

      await tester.pumpWidget(createWidgetUnderTest(
        onExerciseSelected: (ex) {
          chosenExercise = ex;
        },
      ));
      await tester.pumpAndSettle();

      // Tap "Select This Exercise" on the first card
      final selectBtn = find.text('Select This Exercise').first;
      await tester.tap(selectBtn);
      await tester.pumpAndSettle();

      expect(chosenExercise, isNotNull);
      expect(chosenExercise!.name, 'Barbell Bench Press');
      expect(chosenExercise!.muscleGroup, 'Chest');
    });
  });
}
