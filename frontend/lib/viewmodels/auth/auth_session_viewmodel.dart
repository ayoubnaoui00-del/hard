import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_model.dart';
import '../../repositories/auth_repository.dart';

enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
}

class AuthSessionState {
  final AuthStatus status;
  final UserModel? user;
  final String? errorMessage;

  const AuthSessionState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;
  bool get isLoading => status == AuthStatus.loading;

  AuthSessionState copyWith({
    AuthStatus? status,
    UserModel? user,
    String? errorMessage,
  }) {
    return AuthSessionState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }
}

class AuthSessionViewModel extends Notifier<AuthSessionState> {
  late final IAuthRepository _authRepository;

  @override
  AuthSessionState build() {
    _authRepository = ref.watch(authRepositoryProvider);
    return const AuthSessionState();
  }

  Future<void> initializeSession() async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      final isAuth = await _authRepository.isAuthenticated();
      if (!isAuth) {
        state = const AuthSessionState(status: AuthStatus.unauthenticated);
        return;
      }

      final user = await _authRepository.getCurrentUser();
      if (user != null) {
        state = AuthSessionState(
          status: AuthStatus.authenticated,
          user: user,
        );
      } else {
        state = const AuthSessionState(status: AuthStatus.unauthenticated);
      }
    } catch (e) {
      state = AuthSessionState(
        status: AuthStatus.unauthenticated,
        errorMessage: e.toString(),
      );
    }
  }

  void setAuthenticatedUser(UserModel user) {
    state = AuthSessionState(
      status: AuthStatus.authenticated,
      user: user,
    );
  }

  Future<void> logout() async {
    state = state.copyWith(status: AuthStatus.loading);
    await _authRepository.logout();
    state = const AuthSessionState(status: AuthStatus.unauthenticated);
  }
}

final authSessionViewModelProvider =
    NotifierProvider<AuthSessionViewModel, AuthSessionState>(() {
  return AuthSessionViewModel();
});
