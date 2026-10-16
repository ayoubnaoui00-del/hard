import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import '../services/api_service.dart';
import '../services/storage_service.dart';

abstract class IAuthRepository {
  Future<UserModel> login({required String email, required String password});
  Future<UserModel> register({
    required String username,
    required String email,
    required String password,
  });
  Future<UserModel?> getCurrentUser();
  Future<void> logout();
  Future<bool> isAuthenticated();
  Future<String?> refreshToken();
}

class AuthRepository implements IAuthRepository {
  final ApiService apiService;
  final StorageService storageService;

  AuthRepository({
    required this.apiService,
    required this.storageService,
  });

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await apiService.post(
      '/auth/login',
      data: {
        'email': email.trim().toLowerCase(),
        'password': password,
      },
    );

    final responseData = response.data as Map<String, dynamic>;
    final data = responseData['data'] as Map<String, dynamic>;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    final accessToken = data['accessToken'] as String;
    final refreshToken = data['refreshToken'] as String;

    await storageService.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );

    return user;
  }

  @override
  Future<UserModel> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final response = await apiService.post(
      '/auth/register',
      data: {
        'username': username.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
      },
    );

    final responseData = response.data as Map<String, dynamic>;
    final data = responseData['data'] as Map<String, dynamic>;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    final accessToken = data['accessToken'] as String;
    final refreshToken = data['refreshToken'] as String;

    await storageService.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
    );

    return user;
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    final token = await storageService.getToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    try {
      final response = await apiService.get('/auth/me');
      final responseData = response.data as Map<String, dynamic>;
      final data = responseData['data'] as Map<String, dynamic>;
      return UserModel.fromJson(data['user'] as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> logout() async {
    try {
      final refreshToken = await storageService.getRefreshToken();
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await apiService.post(
          '/auth/logout',
          data: {'refreshToken': refreshToken},
        );
      }
    } catch (_) {
      // Ignore network failure on logout to guarantee local wipe
    } finally {
      await storageService.clearAll();
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    final token = await storageService.getToken();
    return token != null && token.isNotEmpty;
  }

  @override
  Future<String?> refreshToken() async {
    final currentRefreshToken = await storageService.getRefreshToken();
    if (currentRefreshToken == null || currentRefreshToken.isEmpty) {
      return null;
    }

    try {
      final response = await apiService.post(
        '/auth/refresh',
        data: {'refreshToken': currentRefreshToken},
      );
      final responseData = response.data as Map<String, dynamic>;
      final data = responseData['data'] as Map<String, dynamic>;
      final newAccessToken = data['accessToken'] as String;
      final newRefreshToken = data['refreshToken'] as String;

      await storageService.saveTokens(
        accessToken: newAccessToken,
        refreshToken: newRefreshToken,
      );
      return newAccessToken;
    } catch (_) {
      return null;
    }
  }
}

final authRepositoryProvider = Provider<IAuthRepository>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final storageService = ref.watch(storageServiceProvider);
  return AuthRepository(
    apiService: apiService,
    storageService: storageService,
  );
});
