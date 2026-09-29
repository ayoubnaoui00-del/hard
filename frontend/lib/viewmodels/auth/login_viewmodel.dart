import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_model.dart';
import '../../repositories/auth_repository.dart';
import '../../services/api_service.dart';
import 'auth_session_viewmodel.dart';

class LoginState {
  final String email;
  final String password;
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;
  final UserModel? loggedInUser;

  const LoginState({
    this.email = '',
    this.password = '',
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
    this.loggedInUser,
  });

  bool get isValid => email.trim().isNotEmpty && password.trim().isNotEmpty;

  LoginState copyWith({
    String? email,
    String? password,
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
    UserModel? loggedInUser,
    bool clearError = false,
  }) {
    return LoginState(
      email: email ?? this.email,
      password: password ?? this.password,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isSuccess: isSuccess ?? this.isSuccess,
      loggedInUser: loggedInUser ?? this.loggedInUser,
    );
  }
}

class LoginViewModel extends Notifier<LoginState> {
  late final IAuthRepository _authRepository;

  @override
  LoginState build() {
    _authRepository = ref.watch(authRepositoryProvider);
    return const LoginState();
  }

  void setEmail(String email) {
    state = state.copyWith(email: email, clearError: true);
  }

  void setPassword(String password) {
    state = state.copyWith(password: password, clearError: true);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<bool> login() async {
    final email = state.email.trim();
    final password = state.password;

    if (email.isEmpty || password.isEmpty) {
      state = state.copyWith(
        errorMessage: 'Please enter both email and password.',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true, isSuccess: false);

    try {
      final user = await _authRepository.login(
        email: email,
        password: password,
      );

      // Update global auth session
      ref.read(authSessionViewModelProvider.notifier).setAuthenticatedUser(user);

      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        loggedInUser: user,
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Login failed: ${e.toString()}',
      );
      return false;
    }
  }

  void reset() {
    state = const LoginState();
  }
}

final loginViewModelProvider =
    NotifierProvider.autoDispose<LoginViewModel, LoginState>(() {
  return LoginViewModel();
});
