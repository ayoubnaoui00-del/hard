import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

abstract class IUserRepository {
  Future<UserModel> getCurrentProfile();
  Future<UserModel?> getUser(int userId);
  Future<UserModel> updateProfile({
    String? username,
    String? email,
    String? avatarUrl,
  });
  Future<void> cacheUser(UserModel user);
  Future<UserModel?> getCachedUser();
  Future<void> clearUserCache();
}

class UserRepository implements IUserRepository {
  final ApiService apiService;
  final StorageService storageService;

  UserModel? _inMemoryCache;

  UserRepository({
    required this.apiService,
    required this.storageService,
  });

  @override
  Future<UserModel> getCurrentProfile() async {
    final response = await apiService.get('/auth/me');
    final responseData = response.data as Map<String, dynamic>;
    final data = responseData['data'] as Map<String, dynamic>;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    
    await cacheUser(user);
    return user;
  }

  @override
  Future<UserModel?> getUser(int userId) async {
    try {
      final response = await apiService.get('/users/$userId/xp');
      final responseData = response.data as Map<String, dynamic>;
      final data = responseData['data'] as Map<String, dynamic>;
      return UserModel(
        id: userId,
        username: data['username'] as String? ?? 'Athlete',
        email: '',
        xp: data['currentXp'] as int? ?? 0,
        level: data['level'] as int? ?? 1,
        streak: data['streak'] as int? ?? 0,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<UserModel> updateProfile({
    String? username,
    String? email,
    String? avatarUrl,
  }) async {
    final updatePayload = <String, dynamic>{
      if (username != null) 'username': username.trim(),
      if (email != null) 'email': email.trim().toLowerCase(),
      'avatarUrl': ?avatarUrl,
    };

    final response = await apiService.put(
      '/users/profile',
      data: updatePayload,
    );

    final responseData = response.data as Map<String, dynamic>;
    final data = responseData['data'] as Map<String, dynamic>? ?? responseData;
    final user = UserModel.fromJson(
      (data['user'] as Map<String, dynamic>?) ?? data,
    );

    await cacheUser(user);
    return user;
  }

  @override
  Future<void> cacheUser(UserModel user) async {
    _inMemoryCache = user;
    await storageService.saveUserData(jsonEncode(user.toJson()));
  }

  @override
  Future<UserModel?> getCachedUser() async {
    if (_inMemoryCache != null) {
      return _inMemoryCache;
    }

    final raw = await storageService.getUserData();
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        _inMemoryCache = UserModel.fromJson(decoded);
        return _inMemoryCache;
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  @override
  Future<void> clearUserCache() async {
    _inMemoryCache = null;
    await storageService.saveUserData('');
  }
}

final userRepositoryProvider = Provider<IUserRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final storageService = ref.watch(storageServiceProvider);
  return UserRepository(
    apiService: apiService,
    storageService: storageService,
  );
});
