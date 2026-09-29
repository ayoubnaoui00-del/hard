import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/leaderboard_model.dart';
import '../../repositories/leaderboard_repository.dart';

enum LeaderboardType { global, weekly, friends }

class LeaderboardState {
  final LeaderboardType currentType;
  final List<LeaderboardEntryModel> entries;
  final bool isLoading;
  final String? errorMessage;

  const LeaderboardState({
    this.currentType = LeaderboardType.global,
    this.entries = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  LeaderboardState copyWith({
    LeaderboardType? currentType,
    List<LeaderboardEntryModel>? entries,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return LeaderboardState(
      currentType: currentType ?? this.currentType,
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class LeaderboardViewModel extends Notifier<LeaderboardState> {
  late final ILeaderboardRepository _leaderboardRepository;

  @override
  LeaderboardState build() {
    _leaderboardRepository = ref.watch(leaderboardRepositoryProvider);
    return const LeaderboardState();
  }

  Future<void> fetchGlobalLeaderboard({int limit = 50}) async {
    state = state.copyWith(
      currentType: LeaderboardType.global,
      isLoading: true,
      clearError: true,
    );
    try {
      final list = await _leaderboardRepository.getGlobalLeaderboard(limit: limit);
      if (!ref.mounted) return;
      state = state.copyWith(entries: list, isLoading: false);
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load global leaderboard: ${e.toString()}',
      );
    }
  }

  Future<void> fetchWeeklyLeaderboard({int limit = 50}) async {
    state = state.copyWith(
      currentType: LeaderboardType.weekly,
      isLoading: true,
      clearError: true,
    );
    try {
      final list = await _leaderboardRepository.getWeeklyLeaderboard(limit: limit);
      if (!ref.mounted) return;
      state = state.copyWith(entries: list, isLoading: false);
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load weekly leaderboard: ${e.toString()}',
      );
    }
  }

  Future<void> fetchFriendsLeaderboard({int limit = 50}) async {
    state = state.copyWith(
      currentType: LeaderboardType.friends,
      isLoading: true,
      clearError: true,
    );
    try {
      final list = await _leaderboardRepository.getFriendsLeaderboard(limit: limit);
      if (!ref.mounted) return;
      state = state.copyWith(entries: list, isLoading: false);
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load friends leaderboard: ${e.toString()}',
      );
    }
  }
}

final leaderboardViewModelProvider =
    NotifierProvider<LeaderboardViewModel, LeaderboardState>(() {
  return LeaderboardViewModel();
});
