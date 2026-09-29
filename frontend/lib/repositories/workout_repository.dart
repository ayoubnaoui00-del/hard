import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/workout_model.dart';
import '../services/api_service.dart';

abstract class IWorkoutRepository {
  Future<List<WorkoutModel>> getWorkouts({int page = 1, int limit = 20});
  Future<WorkoutModel> getWorkoutById(int id);
  Future<WorkoutModel> createWorkout({
    required String name,
    DateTime? date,
    int? duration,
    String? notes,
    required List<WorkoutExerciseModel> exercises,
  });
  Future<WorkoutModel> updateWorkout(
    int id, {
    String? name,
    DateTime? date,
    int? duration,
    String? notes,
    List<WorkoutExerciseModel>? exercises,
  });
  Future<void> deleteWorkout(int id);
  double calculateVolume(List<WorkoutExerciseModel> exercises);
}

class WorkoutRepository implements IWorkoutRepository {
  final ApiService apiService;

  WorkoutRepository({required this.apiService});

  @override
  Future<List<WorkoutModel>> getWorkouts({int page = 1, int limit = 20}) async {
    final response = await apiService.get(
      '/workouts',
      queryParameters: {
        'page': page,
        'limit': limit,
      },
    );

    final responseData = response.data as Map<String, dynamic>;
    final data = responseData['data'] as Map<String, dynamic>? ?? responseData;
    final workoutsList = data['workouts'] as List<dynamic>? ?? [];

    return workoutsList
        .map((w) => WorkoutModel.fromJson(w as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<WorkoutModel> getWorkoutById(int id) async {
    final response = await apiService.get('/workouts/$id');
    final responseData = response.data as Map<String, dynamic>;
    final data = responseData['data'] as Map<String, dynamic>? ?? responseData;
    final workoutData = data['workout'] as Map<String, dynamic>? ?? data;

    return WorkoutModel.fromJson(workoutData);
  }

  @override
  Future<WorkoutModel> createWorkout({
    required String name,
    DateTime? date,
    int? duration,
    String? notes,
    required List<WorkoutExerciseModel> exercises,
  }) async {
    final payload = {
      'name': name.trim(),
      'date': (date ?? DateTime.now()).toIso8601String(),
      'duration': duration ?? 0,
      'notes': ?notes,
      'exercises': exercises.map((e) => e.toJson()).toList(),
    };

    final response = await apiService.post(
      '/workouts',
      data: payload,
    );

    final responseData = response.data as Map<String, dynamic>;
    final data = responseData['data'] as Map<String, dynamic>? ?? responseData;
    final workoutData = data['workout'] as Map<String, dynamic>? ?? data;

    return WorkoutModel.fromJson(workoutData);
  }

  @override
  Future<WorkoutModel> updateWorkout(
    int id, {
    String? name,
    DateTime? date,
    int? duration,
    String? notes,
    List<WorkoutExerciseModel>? exercises,
  }) async {
    final payload = <String, dynamic>{
      if (name != null) 'name': name.trim(),
      if (date != null) 'date': date.toIso8601String(),
      'duration': ?duration,
      'notes': ?notes,
      if (exercises != null)
        'exercises': exercises.map((e) => e.toJson()).toList(),
    };

    final response = await apiService.put(
      '/workouts/$id',
      data: payload,
    );

    final responseData = response.data as Map<String, dynamic>;
    final data = responseData['data'] as Map<String, dynamic>? ?? responseData;
    final workoutData = data['workout'] as Map<String, dynamic>? ?? data;

    return WorkoutModel.fromJson(workoutData);
  }

  @override
  Future<void> deleteWorkout(int id) async {
    await apiService.delete('/workouts/$id');
  }

  @override
  double calculateVolume(List<WorkoutExerciseModel> exercises) {
    return WorkoutModel.calculateVolume(exercises);
  }
}

final workoutRepositoryProvider = Provider<IWorkoutRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return WorkoutRepository(apiService: apiService);
});
