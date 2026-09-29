import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/workout_model.dart';
import '../repositories/workout_repository.dart';
import '../viewmodels/workout/workout_viewmodel.dart';

export '../models/workout_model.dart';
export '../repositories/workout_repository.dart';
export '../viewmodels/workout/workout_viewmodel.dart';

/// Provider alias for workout state management
final workoutProvider = workoutViewModelProvider;

/// FutureProvider to fetch paginated workouts list asynchronously
final workoutsListProvider =
    FutureProvider.family<List<WorkoutModel>, int>((ref, page) async {
  final repo = ref.watch(workoutRepositoryProvider);
  return await repo.getWorkouts(page: page);
});

/// FutureProvider to fetch single workout details
final workoutDetailProvider =
    FutureProvider.family<WorkoutModel, int>((ref, workoutId) async {
  final repo = ref.watch(workoutRepositoryProvider);
  return await repo.getWorkoutById(workoutId);
});

/// Direct volume calculation helper function provider
final workoutVolumeCalculatorProvider = Provider<double Function(List<WorkoutExerciseModel>)>((ref) {
  final repo = ref.watch(workoutRepositoryProvider);
  return repo.calculateVolume;
});
