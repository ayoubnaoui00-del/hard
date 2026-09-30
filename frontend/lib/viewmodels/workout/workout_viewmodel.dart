import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/workout_model.dart';
import '../../repositories/workout_repository.dart';

class WorkoutState {
  final List<WorkoutModel> workouts;
  final WorkoutModel? selectedWorkout;
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;

  const WorkoutState({
    this.workouts = const [],
    this.selectedWorkout,
    this.isLoading = false,
    this.isSubmitting = false,
    this.errorMessage,
  });

  WorkoutState copyWith({
    List<WorkoutModel>? workouts,
    WorkoutModel? selectedWorkout,
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
    bool clearSelected = false,
  }) {
    return WorkoutState(
      workouts: workouts ?? this.workouts,
      selectedWorkout: clearSelected
          ? null
          : (selectedWorkout ?? this.selectedWorkout),
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class WorkoutViewModel extends Notifier<WorkoutState> {
  late final IWorkoutRepository _workoutRepository;

  @override
  WorkoutState build() {
    _workoutRepository = ref.watch(workoutRepositoryProvider);
    return const WorkoutState();
  }

  Future<void> fetchWorkouts({int page = 1, int limit = 20}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final list = await _workoutRepository.getWorkouts(page: page, limit: limit);
      if (!ref.mounted) return;
      state = state.copyWith(workouts: list, isLoading: false);
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to fetch workouts: ${e.toString()}',
      );
    }
  }

  Future<void> selectWorkout(dynamic id) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final workout = await _workoutRepository.getWorkoutById(id);
      if (!ref.mounted) return;
      state = state.copyWith(selectedWorkout: workout, isLoading: false);
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load workout details: ${e.toString()}',
      );
    }
  }

  Future<WorkoutModel?> createWorkout({
    required String name,
    DateTime? date,
    int? duration,
    String? notes,
    required List<WorkoutExerciseModel> exercises,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final created = await _workoutRepository.createWorkout(
        name: name,
        date: date,
        duration: duration,
        notes: notes,
        exercises: exercises,
      );

      if (!ref.mounted) return created;
      final updatedList = [created, ...state.workouts];
      state = state.copyWith(
        workouts: updatedList,
        isSubmitting: false,
      );
      return created;
    } catch (e) {
      if (!ref.mounted) return null;
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Failed to save workout: ${e.toString()}',
      );
      return null;
    }
  }

  Future<bool> updateWorkout(
    dynamic id, {
    String? name,
    DateTime? date,
    int? duration,
    String? notes,
    List<WorkoutExerciseModel>? exercises,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final updated = await _workoutRepository.updateWorkout(
        id,
        name: name,
        date: date,
        duration: duration,
        notes: notes,
        exercises: exercises,
      );

      if (!ref.mounted) return true;
      final updatedList = state.workouts
          .map((w) => w.id == id ? updated : w)
          .toList();

      state = state.copyWith(
        workouts: updatedList,
        selectedWorkout: state.selectedWorkout?.id == id
            ? updated
            : state.selectedWorkout,
        isSubmitting: false,
      );
      return true;
    } catch (e) {
      if (!ref.mounted) return false;
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Failed to update workout: ${e.toString()}',
      );
      return false;
    }
  }

  Future<bool> deleteWorkout(dynamic id) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _workoutRepository.deleteWorkout(id);
      if (!ref.mounted) return true;
      final updatedList = state.workouts.where((w) => w.id != id).toList();
      state = state.copyWith(
        workouts: updatedList,
        selectedWorkout: state.selectedWorkout?.id == id ? null : state.selectedWorkout,
        clearSelected: state.selectedWorkout?.id == id,
        isSubmitting: false,
      );
      return true;
    } catch (e) {
      if (!ref.mounted) return false;
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Failed to delete workout: ${e.toString()}',
      );
      return false;
    }
  }

  double calculateVolume(List<WorkoutExerciseModel> exercises) {
    return _workoutRepository.calculateVolume(exercises);
  }
}

final workoutViewModelProvider =
    NotifierProvider<WorkoutViewModel, WorkoutState>(() {
  return WorkoutViewModel();
});
