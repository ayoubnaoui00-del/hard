import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/exercise_model.dart';
import '../services/api_service.dart';

class ExercisePageResponse {
  final List<ExerciseModel> exercises;
  final int total;
  final int page;
  final int totalPages;
  final bool hasMore;

  const ExercisePageResponse({
    required this.exercises,
    required this.total,
    required this.page,
    required this.totalPages,
    required this.hasMore,
  });
}

abstract class IExerciseRepository {
  Future<List<ExerciseModel>> getExercises({
    String? muscle,
    String? search,
    int page = 1,
    int limit = 50,
  });
  Future<ExercisePageResponse> getExercisesPaginated({
    String? muscle,
    String? search,
    int page = 1,
    int limit = 20,
  });
  Future<ExerciseModel?> getExerciseById(String id);
}

class ExerciseRepository implements IExerciseRepository {
  final ApiService apiService;

  ExerciseRepository({required this.apiService});

  @override
  Future<List<ExerciseModel>> getExercises({
    String? muscle,
    String? search,
    int page = 1,
    int limit = 50,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (muscle != null && muscle.isNotEmpty && muscle != 'All')
          'muscle': muscle,
        if (search != null && search.trim().isNotEmpty)
          'search': search.trim(),
      };

      final response = await apiService.get(
        '/exercises',
        queryParameters: queryParams,
      );

      final responseData = response.data as Map<String, dynamic>;
      final data = responseData['data'] as Map<String, dynamic>? ?? responseData;
      final rawList = data['exercises'] as List<dynamic>? ?? [];

      final list = rawList
          .map((e) => ExerciseModel.fromJson(e as Map<String, dynamic>))
          .toList();

      if (list.isNotEmpty) {
        return list;
      }
      return ExerciseModel.defaultExercises;
    } catch (_) {
      // Graceful fallback to default exercise catalog
      return ExerciseModel.defaultExercises;
    }
  }

  @override
  Future<ExercisePageResponse> getExercisesPaginated({
    String? muscle,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (muscle != null && muscle.isNotEmpty && muscle != 'All')
          'muscle': muscle,
        if (search != null && search.trim().isNotEmpty)
          'search': search.trim(),
      };

      final response = await apiService.get(
        '/exercises',
        queryParameters: queryParams,
      );

      final responseData = response.data as Map<String, dynamic>;
      final data =
          responseData['data'] as Map<String, dynamic>? ?? responseData;
      final rawList = data['exercises'] as List<dynamic>? ?? [];
      final total = (data['total'] as num?)?.toInt() ?? rawList.length;
      final totalPages = (data['totalPages'] as num?)?.toInt() ?? 1;

      final list = rawList
          .map((e) => ExerciseModel.fromJson(e as Map<String, dynamic>))
          .toList();

      final exercises = list.isNotEmpty
          ? list
          : (page == 1 ? ExerciseModel.defaultExercises : <ExerciseModel>[]);
      final hasMore = page < totalPages && list.isNotEmpty;

      return ExercisePageResponse(
        exercises: exercises,
        total: total,
        page: page,
        totalPages: totalPages,
        hasMore: hasMore,
      );
    } catch (_) {
      return ExercisePageResponse(
        exercises: page == 1 ? ExerciseModel.defaultExercises : [],
        total: ExerciseModel.defaultExercises.length,
        page: 1,
        totalPages: 1,
        hasMore: false,
      );
    }
  }

  @override
  Future<ExerciseModel?> getExerciseById(String id) async {
    try {
      final response = await apiService.get('/exercises/$id');
      final responseData = response.data as Map<String, dynamic>;
      final data = responseData['data'] as Map<String, dynamic>? ?? responseData;
      final exerciseData = data['exercise'] as Map<String, dynamic>? ?? data;

      return ExerciseModel.fromJson(exerciseData);
    } catch (_) {
      return null;
    }
  }
}

final exerciseRepositoryProvider = Provider<IExerciseRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ExerciseRepository(apiService: apiService);
});

final exercisesListProvider = FutureProvider.family<List<ExerciseModel>, String?>((ref, muscleFilter) async {
  final repo = ref.watch(exerciseRepositoryProvider);
  return await repo.getExercises(muscle: muscleFilter);
});
