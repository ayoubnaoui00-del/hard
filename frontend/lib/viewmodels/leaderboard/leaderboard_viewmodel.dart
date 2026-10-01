import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/leaderboard_model.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/leaderboard_repository.dart';

enum LeaderboardType { global, weekly, friends }

class LeaderboardState {
  final LeaderboardType currentType;
  final List<LeaderboardEntryModel> entries;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentLimit;
  final String? errorMessage;
  final String searchQuery;
  final LeaderboardEntryModel? selectedUserForPreview;

  const LeaderboardState({
    this.currentType = LeaderboardType.global,
    this.entries = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentLimit = 50,
    this.errorMessage,
    this.searchQuery = '',
    this.selectedUserForPreview,
  });

  List<LeaderboardEntryModel> get filteredEntries {
    if (searchQuery.trim().isEmpty) return entries;
    final query = searchQuery.trim().toLowerCase();
    return entries
        .where((e) =>
            e.username.toLowerCase().contains(query) ||
            e.rank.toString() == query)
        .toList();
  }

  List<LeaderboardEntryModel> get top3 => entries.take(3).toList();
  List<LeaderboardEntryModel> get remainingEntries =>
      entries.length > 3 ? entries.skip(3).toList() : [];

  LeaderboardEntryModel? get currentUserEntry {
    try {
      return entries.firstWhere((e) => e.isCurrentUser);
    } catch (_) {
      return null;
    }
  }

  LeaderboardState copyWith({
    LeaderboardType? currentType,
    List<LeaderboardEntryModel>? entries,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentLimit,
    String? errorMessage,
    bool clearError = false,
    String? searchQuery,
    LeaderboardEntryModel? selectedUserForPreview,
    bool clearSelectedUser = false,
  }) {
    return LeaderboardState(
      currentType: currentType ?? this.currentType,
      entries: entries ?? this.entries,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentLimit: currentLimit ?? this.currentLimit,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      searchQuery: searchQuery ?? this.searchQuery,
      selectedUserForPreview: clearSelectedUser
          ? null
          : (selectedUserForPreview ?? this.selectedUserForPreview),
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

  List<LeaderboardEntryModel> _tagCurrentUser(List<LeaderboardEntryModel> list) {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return list;

    final currentUserIdStr = currentUser.id.toString();
    final currentUsername = currentUser.username.toLowerCase();

    return list.map((entry) {
      final isMatch = entry.isCurrentUser ||
          entry.userId.toString() == currentUserIdStr ||
          entry.username.toLowerCase() == currentUsername;
      return entry.copyWith(isCurrentUser: isMatch);
    }).toList();
  }

  Future<void> fetchGlobalLeaderboard({int limit = 50}) async {
    state = state.copyWith(
      currentType: LeaderboardType.global,
      isLoading: true,
      currentLimit: limit,
      hasMore: true,
      clearError: true,
    );
    try {
      final list = await _leaderboardRepository.getGlobalLeaderboard(limit: limit);
      if (!ref.mounted) return;
      final tagged = _tagCurrentUser(list);
      state = state.copyWith(
        entries: tagged,
        isLoading: false,
        hasMore: list.length >= limit,
      );
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
      currentLimit: limit,
      hasMore: true,
      clearError: true,
    );
    try {
      final list = await _leaderboardRepository.getWeeklyLeaderboard(limit: limit);
      if (!ref.mounted) return;
      final tagged = _tagCurrentUser(list);
      state = state.copyWith(
        entries: tagged,
        isLoading: false,
        hasMore: list.length >= limit,
      );
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
      currentLimit: limit,
      hasMore: true,
      clearError: true,
    );
    try {
      final list = await _leaderboardRepository.getFriendsLeaderboard(limit: limit);
      if (!ref.mounted) return;
      final tagged = _tagCurrentUser(list);
      state = state.copyWith(
        entries: tagged,
        isLoading: false,
        hasMore: list.length >= limit,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load friends leaderboard: ${e.toString()}',
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    final nextLimit = state.currentLimit + 25;
    state = state.copyWith(isLoadingMore: true);

    try {
      List<LeaderboardEntryModel> updatedList;
      switch (state.currentType) {
        case LeaderboardType.global:
          updatedList = await _leaderboardRepository.getGlobalLeaderboard(limit: nextLimit);
          break;
        case LeaderboardType.weekly:
          updatedList = await _leaderboardRepository.getWeeklyLeaderboard(limit: nextLimit);
          break;
        case LeaderboardType.friends:
          updatedList = await _leaderboardRepository.getFriendsLeaderboard(limit: nextLimit);
          break;
      }

      if (!ref.mounted) return;
      final tagged = _tagCurrentUser(updatedList);
      final hasMoreItems = updatedList.length >= nextLimit;

      state = state.copyWith(
        entries: tagged,
        currentLimit: nextLimit,
        hasMore: hasMoreItems,
        isLoadingMore: false,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(isLoadingMore: false);
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void selectUserForPreview(LeaderboardEntryModel? entry) {
    if (entry == null) {
      state = state.copyWith(clearSelectedUser: true);
    } else {
      state = state.copyWith(selectedUserForPreview: entry);
    }
  }
}

final leaderboardViewModelProvider =
    NotifierProvider<LeaderboardViewModel, LeaderboardState>(() {
  return LeaderboardViewModel();
});
