import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/user_model.dart';
import '../repositories/user_repository.dart';
import '../viewmodels/user/user_viewmodel.dart';

export '../repositories/user_repository.dart';
export '../viewmodels/user/user_viewmodel.dart';

/// Provider alias for user state notifier
final userProvider = userViewModelProvider;

/// FutureProvider to fetch current user profile asynchronously
final userProfileProvider = FutureProvider<UserModel>((ref) async {
  final repo = ref.watch(userRepositoryProvider);
  return await repo.getCurrentProfile();
});

/// Family FutureProvider to fetch a specific user by ID
final userByIdProvider = FutureProvider.family<UserModel?, int>((ref, userId) async {
  final repo = ref.watch(userRepositoryProvider);
  return await repo.getUser(userId);
});
