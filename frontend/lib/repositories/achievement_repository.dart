import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/achievement_model.dart';
import '../services/api_service.dart';

abstract class IAchievementRepository {
  Future<List<AchievementModel>> getUserAchievements();
}

class AchievementRepository implements IAchievementRepository {
  final ApiService apiService;

  AchievementRepository({required this.apiService});

  @override
  Future<List<AchievementModel>> getUserAchievements() async {
    try {
      final response = await apiService.get('/achievements');
      final responseData = response.data as Map<String, dynamic>;
      final data = responseData['data'] as Map<String, dynamic>? ?? responseData;

      // Extract unlocked achievements first
      final unlockedRaw = data['unlocked'] as List<dynamic>? ?? [];
      final List<AchievementModel> list = unlockedRaw
          .map((item) => AchievementModel.fromJson(item as Map<String, dynamic>))
          .toList();

      if (list.isNotEmpty) {
        return list;
      }

      // If user has no unlocked yet, return sample achievement catalog
      final catalogRaw = data['catalog'] as List<dynamic>? ?? [];
      if (catalogRaw.isNotEmpty) {
        return catalogRaw
            .take(3)
            .map((item) => AchievementModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      return AchievementModel.sampleAchievements;
    } catch (_) {
      // Gracefully fall back to sample achievements if offline / mock
      return AchievementModel.sampleAchievements;
    }
  }
}

final achievementRepositoryProvider = Provider<IAchievementRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return AchievementRepository(apiService: apiService);
});
