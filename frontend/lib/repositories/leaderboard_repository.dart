import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/leaderboard_model.dart';
import '../services/api_service.dart';

abstract class ILeaderboardRepository {
  Future<List<LeaderboardEntryModel>> getGlobalLeaderboard({int limit = 50});
  Future<List<LeaderboardEntryModel>> getWeeklyLeaderboard({int limit = 50});
  Future<List<LeaderboardEntryModel>> getFriendsLeaderboard({int limit = 50});
}

class LeaderboardRepository implements ILeaderboardRepository {
  final ApiService apiService;

  LeaderboardRepository({required this.apiService});

  @override
  Future<List<LeaderboardEntryModel>> getGlobalLeaderboard({
    int limit = 50,
  }) async {
    final response = await apiService.get(
      '/leaderboard/global',
      queryParameters: {'limit': limit},
    );

    final responseData = response.data as Map<String, dynamic>;
    final data = responseData['data'] as Map<String, dynamic>? ?? responseData;
    final list = data['leaderboard'] as List<dynamic>? ?? [];

    return list
        .map((e) => LeaderboardEntryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<LeaderboardEntryModel>> getWeeklyLeaderboard({
    int limit = 50,
  }) async {
    final response = await apiService.get(
      '/leaderboard/weekly',
      queryParameters: {'limit': limit},
    );

    final responseData = response.data as Map<String, dynamic>;
    final data = responseData['data'] as Map<String, dynamic>? ?? responseData;
    final list = data['leaderboard'] as List<dynamic>? ?? [];

    return list
        .map((e) => LeaderboardEntryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<LeaderboardEntryModel>> getFriendsLeaderboard({
    int limit = 50,
  }) async {
    final response = await apiService.get(
      '/leaderboard/friends',
      queryParameters: {'limit': limit},
    );

    final responseData = response.data as Map<String, dynamic>;
    final data = responseData['data'] as Map<String, dynamic>? ?? responseData;
    final list = data['leaderboard'] as List<dynamic>? ?? [];

    return list
        .map((e) => LeaderboardEntryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final leaderboardRepositoryProvider = Provider<ILeaderboardRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return LeaderboardRepository(apiService: apiService);
});
