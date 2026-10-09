import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymtrack/models/exercise_model.dart';
import 'package:gymtrack/repositories/exercise_repository.dart';
import 'package:gymtrack/views/exercise/exercise_view.dart';

class _FakeExerciseRepository implements IExerciseRepository {
  final List<ExerciseModel> exercises = const [
    ExerciseModel(
      id: 'ex-001',
      name: 'Barbell Bench Press',
      muscleGroup: 'Chest',
      equipment: 'Barbell',
      category: 'Strength',
      instructions: 'Lower bar smoothly to mid-chest and press up explosively.',
      formTips: 'Retract shoulder blades and drive through heels.',
      alternativeNames: ['Dumbbell Press', 'Push-Up'],
    ),
    ExerciseModel(
      id: 'ex-002',
      name: 'Incline Dumbbell Fly',
      muscleGroup: 'Chest',
      equipment: 'Dumbbell',
      category: 'Hypertrophy',
      instructions: 'Fly dumbbells out laterally with slight elbow bend.',
      formTips: 'Do not overstretch shoulders.',
      alternativeNames: ['Cable Fly'],
    ),
    ExerciseModel(
      id: 'ex-003',
      name: 'Conventional Deadlift',
      muscleGroup: 'Back',
      equipment: 'Barbell',
      category: 'Strength',
      instructions: 'Hinge hips and pull bar keeping contact with shins.',
      formTips: 'Keep back flat and engage lats.',
      alternativeNames: ['Romanian Deadlift'],
    ),
  ];

  @override
  Future<List<ExerciseModel>> getExercises({
    String? muscle,
    String? search,
    int page = 1,
    int limit = 50,
  }) async {
    return exercises.where((e) {
      if (muscle != null && muscle.isNotEmpty && muscle != 'All') {
        if (!e.muscleGroup.toLowerCase().contains(muscle.toLowerCase())) {
          return false;
        }
      }
      if (search != null && search.isNotEmpty) {
        if (!e.name.toLowerCase().contains(search.toLowerCase())) {
          return false;
        }
      }
      return true;
    }).toList();
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
    try {
      return exercises.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }
}

void main() {
  late _FakeExerciseRepository fakeRepo;

  setUp(() {
    fakeRepo = _FakeExerciseRepository();
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        exerciseRepositoryProvider.overrideWithValue(fakeRepo),
      ],
      child: const MaterialApp(
        home: ExerciseView(),
      ),
    );
  }

  group('ExerciseView & 3D Body Model Integration Tests', () {
    testWidgets('Renders AppBar, segmented tabs, and search bar cleanly', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Exercises Library'), findsOneWidget);
      expect(find.text('All Exercises'), findsOneWidget);
      expect(find.text('3D Body Model'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Barbell Bench Press'), findsOneWidget);
      // Hero banner is removed to keep only one clean, professional 3D entry point
      expect(find.text('Interactive 3D Body Model'), findsNothing);
    });

    testWidgets('Tapping 3D Body Model tab switches to Interactive Body Map', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap the 3D Body Model tab
      final tab3d = find.text('3D Body Model');
      expect(tab3d, findsOneWidget);
      await tester.tap(tab3d);
      await tester.pumpAndSettle();

      // Verify Body Map Canvas rendered
      expect(find.text('Interactive Body Map'), findsWidgets);
      expect(find.byIcon(Icons.sync_rounded), findsOneWidget);

      // Tap back to All Exercises
      await tester.tap(find.text('All Exercises'));
      await tester.pumpAndSettle();

      expect(find.text('Barbell Bench Press'), findsOneWidget);
    });

    testWidgets('Ensures segmented tab is the single dedicated 3D switch without redundant buttons', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Only 1 "3D Body Model" widget in the entire UI (the segmented tab)
      expect(find.text('3D Body Model'), findsOneWidget);
      expect(find.text('Open 3D'), findsNothing);
    });

    testWidgets('Search query filters exercise catalog live', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Barbell Bench Press'), findsOneWidget);

      // Search for "Fly"
      await tester.enterText(find.byType(TextField), 'Fly');
      await tester.pumpAndSettle();

      expect(find.text('Incline Dumbbell Fly'), findsOneWidget);
      expect(find.text('Barbell Bench Press'), findsNothing);
    });

    testWidgets('Tapping muscle filter chip filters exercise list', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap "Chest" chip (first occurrence is in the filter chips row)
      final chestChip = find.text('Chest').first;
      expect(chestChip, findsOneWidget);
      await tester.tap(chestChip);
      await tester.pumpAndSettle();

      expect(find.text('Barbell Bench Press'), findsOneWidget);
    });

    testWidgets('Tapping exercise card opens Exercise Details bottom sheet', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Tap "Barbell Bench Press"
      await tester.tap(find.text('Barbell Bench Press'));
      await tester.pumpAndSettle();

      // Verify bottom sheet contents
      expect(find.text('Instructions'), findsOneWidget);
      expect(find.text('Form Tip & Coaching Cue'), findsOneWidget);
      expect(find.text('Log This Exercise'), findsOneWidget);
    });

    testWidgets('Scrolling down triggers smooth collapse of filter buttons and scrolling up restores them', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Initially filter buttons are visible (sizeFactor == 1.0)
      expect(find.text('Chest'), findsWidgets);
      final sizeTransitionFinder = find.byType(SizeTransition);
      expect(sizeTransitionFinder, findsOneWidget);
      final sizeTransitionInitial = tester.widget<SizeTransition>(sizeTransitionFinder);
      expect(sizeTransitionInitial.sizeFactor.value, 1.0);

      // Scroll down list
      await tester.drag(find.byType(ListView).last, const Offset(0, -200));
      await tester.pumpAndSettle();

      // Size factor has smoothly collapsed to 0.0
      final sizeTransitionCollapsed = tester.widget<SizeTransition>(sizeTransitionFinder);
      expect(sizeTransitionCollapsed.sizeFactor.value, 0.0);

      // Scroll back up
      await tester.drag(find.byType(ListView).last, const Offset(0, 200));
      await tester.pumpAndSettle();

      // Size factor is restored to 1.0
      final sizeTransitionRestored = tester.widget<SizeTransition>(sizeTransitionFinder);
      expect(sizeTransitionRestored.sizeFactor.value, 1.0);
      expect(find.text('Chest'), findsWidgets);
    });
  });
}
