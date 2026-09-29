import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/leaderboard_model.dart';
import '../repositories/leaderboard_repository.dart';
import '../viewmodels/leaderboard/leaderboard_viewmodel.dart';

export '../models/leaderboard_model.dart';
export '../repositories/leaderboard_repository.dart';
export '../viewmodels/leaderboard/leaderboard_viewmodel.dart';

/// Provider alias for leaderboard state management
final leaderboardProvider = leaderboardViewModelProvider;

/// FutureProvider for global rankings
final globalLeaderboardProvider =
    FutureProvider.family<List<LeaderboardEntryModel>, int>((ref, limit) async {
  final repo = ref.watch(leaderboardRepositoryProvider);
  return await repo.getGlobalLeaderboard(limit: limit);
});

/// FutureProvider for weekly rankings
final weeklyLeaderboardProvider =
    FutureProvider.family<List<LeaderboardEntryModel>, int>((ref, limit) async {
  final repo = ref.watch(leaderboardRepositoryProvider);
  return await repo.getWeeklyLeaderboard(limit: limit);
});

/// FutureProvider for friends rankings
final friendsLeaderboardProvider =
    FutureProvider.family<List<LeaderboardEntryModel>, int>((ref, limit) async {
  final repo = ref.watch(leaderboardRepositoryProvider);
  return await repo.getFriendsLeaderboard(limit: limit);
});
