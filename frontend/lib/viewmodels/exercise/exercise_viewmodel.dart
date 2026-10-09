import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/exercise_model.dart';
import '../../repositories/exercise_repository.dart';

class ExerciseListState {
  final List<ExerciseModel> exercises;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int page;
  final int total;
  final String searchQuery;
  final String selectedMuscle;
  final String selectedEquipment;
  final String selectedCategory;
  final String? errorMessage;

  const ExerciseListState({
    this.exercises = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.page = 1,
    this.total = 0,
    this.searchQuery = '',
    this.selectedMuscle = 'All',
    this.selectedEquipment = 'All',
    this.selectedCategory = 'All',
    this.errorMessage,
  });

  bool get hasActiveFilters =>
      searchQuery.isNotEmpty ||
      selectedMuscle != 'All' ||
      selectedEquipment != 'All' ||
      selectedCategory != 'All';

  List<ExerciseModel> get filteredExercises {
    return exercises.where((e) {
      if (selectedEquipment != 'All' &&
          (e.equipment == null ||
              !e.equipment!
                  .toLowerCase()
                  .contains(selectedEquipment.toLowerCase()))) {
        return false;
      }
      if (selectedCategory != 'All' &&
          (e.category == null ||
              !e.category!
                  .toLowerCase()
                  .contains(selectedCategory.toLowerCase()))) {
        return false;
      }
      return true;
    }).toList();
  }

  ExerciseListState copyWith({
    List<ExerciseModel>? exercises,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
    int? total,
    String? searchQuery,
    String? selectedMuscle,
    String? selectedEquipment,
    String? selectedCategory,
    String? errorMessage,
  }) {
    return ExerciseListState(
      exercises: exercises ?? this.exercises,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      total: total ?? this.total,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedMuscle: selectedMuscle ?? this.selectedMuscle,
      selectedEquipment: selectedEquipment ?? this.selectedEquipment,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      errorMessage: errorMessage,
    );
  }
}

class ExerciseListViewModel extends Notifier<ExerciseListState> {
  late final IExerciseRepository _repository;
  Timer? _debounceTimer;

  static const int _pageSize = 20;

  @override
  ExerciseListState build() {
    _repository = ref.watch(exerciseRepositoryProvider);
    ref.onDispose(() {
      _debounceTimer?.cancel();
    });
    Future.microtask(() => loadInitial());
    return const ExerciseListState(isLoading: true);
  }

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, page: 1, errorMessage: null);

    try {
      final res = await _repository.getExercisesPaginated(
        muscle: state.selectedMuscle == 'All' ? null : state.selectedMuscle,
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
        page: 1,
        limit: _pageSize,
      );

      state = state.copyWith(
        exercises: res.exercises,
        isLoading: false,
        hasMore: res.hasMore,
        total: res.total,
        page: 1,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load exercises: $e',
        exercises: ExerciseModel.defaultExercises,
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    final nextPage = state.page + 1;

    try {
      final res = await _repository.getExercisesPaginated(
        muscle: state.selectedMuscle == 'All' ? null : state.selectedMuscle,
        search: state.searchQuery.isEmpty ? null : state.searchQuery,
        page: nextPage,
        limit: _pageSize,
      );

      final existingIds = state.exercises.map((e) => e.id.toString()).toSet();
      final newItems =
          res.exercises.where((e) => !existingIds.contains(e.id.toString()));

      state = state.copyWith(
        exercises: [...state.exercises, ...newItems],
        isLoadingMore: false,
        hasMore: res.hasMore && res.exercises.isNotEmpty,
        page: nextPage,
        total: res.total,
      );
    } catch (_) {
      state = state.copyWith(isLoadingMore: false);
    }
  }

  void setSearchQuery(String query) {
    final trimmed = query.trim();
    if (trimmed == state.searchQuery) return;

    state = state.copyWith(searchQuery: trimmed);
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      loadInitial();
    });
  }

  void setMuscle(String muscle) {
    if (muscle == state.selectedMuscle) return;
    state = state.copyWith(selectedMuscle: muscle);
    loadInitial();
  }

  void setEquipment(String equip) {
    state = state.copyWith(selectedEquipment: equip);
  }

  void setCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }

  void setAdvancedFilters({
    required String muscle,
    required String equipment,
    required String category,
  }) {
    final muscleChanged = muscle != state.selectedMuscle;
    state = state.copyWith(
      selectedMuscle: muscle,
      selectedEquipment: equipment,
      selectedCategory: category,
    );
    if (muscleChanged) {
      loadInitial();
    }
  }

  void clearFilters() {
    state = state.copyWith(
      searchQuery: '',
      selectedMuscle: 'All',
      selectedEquipment: 'All',
      selectedCategory: 'All',
    );
    loadInitial();
  }

  Future<void> refresh() async {
    await loadInitial();
  }
}

final exerciseListViewModelProvider =
    NotifierProvider<ExerciseListViewModel, ExerciseListState>(
  () => ExerciseListViewModel(),
);
