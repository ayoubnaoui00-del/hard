import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_model.dart';
import '../../repositories/user_repository.dart';

class UserState {
  final UserModel? user;
  final bool isLoading;
  final String? errorMessage;

  const UserState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
  });

  UserState copyWith({
    UserModel? user,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return UserState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class UserViewModel extends Notifier<UserState> {
  late final IUserRepository _userRepository;

  @override
  UserState build() {
    _userRepository = ref.watch(userRepositoryProvider);
    return const UserState();
  }

  Future<void> fetchProfile() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _userRepository.getCurrentProfile();
      if (!ref.mounted) return;
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load user profile: ${e.toString()}',
      );
    }
  }

  Future<void> fetchUser(int userId) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _userRepository.getUser(userId);
      if (!ref.mounted) return;
      state = state.copyWith(user: user, isLoading: false);
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load user: ${e.toString()}',
      );
    }
  }

  Future<bool> updateProfile({
    String? username,
    String? email,
    String? avatarUrl,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updated = await _userRepository.updateProfile(
        username: username,
        email: email,
        avatarUrl: avatarUrl,
      );
      if (!ref.mounted) return true;
      state = state.copyWith(user: updated, isLoading: false);
      return true;
    } catch (e) {
      if (!ref.mounted) return false;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to update profile: ${e.toString()}',
      );
      return false;
    }
  }

  Future<void> invalidateUser() async {
    await _userRepository.clearUserCache();
    if (!ref.mounted) return;
    state = const UserState();
  }
}

final userViewModelProvider =
    NotifierProvider<UserViewModel, UserState>(() {
  return UserViewModel();
});
