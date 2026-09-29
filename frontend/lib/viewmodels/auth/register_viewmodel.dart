import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_model.dart';
import '../../repositories/auth_repository.dart';
import '../../services/api_service.dart';
import 'auth_session_viewmodel.dart';

class RegisterState {
  final String username;
  final String email;
  final String password;
  final String confirmPassword;
  final bool acceptTerms;
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;
  final UserModel? registeredUser;

  const RegisterState({
    this.username = '',
    this.email = '',
    this.password = '',
    this.confirmPassword = '',
    this.acceptTerms = false,
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
    this.registeredUser,
  });

  bool get isValid =>
      username.trim().length >= 3 &&
      email.trim().contains('@') &&
      email.trim().contains('.') &&
      password.length >= 6 &&
      password == confirmPassword &&
      acceptTerms;

  RegisterState copyWith({
    String? username,
    String? email,
    String? password,
    String? confirmPassword,
    bool? acceptTerms,
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
    UserModel? registeredUser,
    bool clearError = false,
  }) {
    return RegisterState(
      username: username ?? this.username,
      email: email ?? this.email,
      password: password ?? this.password,
      confirmPassword: confirmPassword ?? this.confirmPassword,
      acceptTerms: acceptTerms ?? this.acceptTerms,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isSuccess: isSuccess ?? this.isSuccess,
      registeredUser: registeredUser ?? this.registeredUser,
    );
  }
}

class RegisterViewModel extends Notifier<RegisterState> {
  late final IAuthRepository _authRepository;

  @override
  RegisterState build() {
    _authRepository = ref.watch(authRepositoryProvider);
    return const RegisterState();
  }

  void setUsername(String username) {
    state = state.copyWith(username: username, clearError: true);
  }

  void setEmail(String email) {
    state = state.copyWith(email: email, clearError: true);
  }

  void setPassword(String password) {
    state = state.copyWith(password: password, clearError: true);
  }

  void setConfirmPassword(String confirmPassword) {
    state = state.copyWith(confirmPassword: confirmPassword, clearError: true);
  }

  void setAcceptTerms(bool? accept) {
    state = state.copyWith(acceptTerms: accept ?? false, clearError: true);
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<bool> register() async {
    final username = state.username.trim();
    final email = state.email.trim();
    final password = state.password;
    final confirmPassword = state.confirmPassword;
    final acceptTerms = state.acceptTerms;

    if (username.length < 3) {
      state = state.copyWith(
        errorMessage: 'Username must be at least 3 characters long.',
      );
      return false;
    }

    if (!email.contains('@') || !email.contains('.')) {
      state = state.copyWith(
        errorMessage: 'Please enter a valid email address.',
      );
      return false;
    }

    if (password.length < 6) {
      state = state.copyWith(
        errorMessage: 'Password must be at least 6 characters long.',
      );
      return false;
    }

    if (password != confirmPassword) {
      state = state.copyWith(
        errorMessage: 'Passwords do not match.',
      );
      return false;
    }

    if (!acceptTerms) {
      state = state.copyWith(
        errorMessage: 'You must accept the Terms & Conditions.',
      );
      return false;
    }

    state = state.copyWith(isLoading: true, clearError: true, isSuccess: false);

    try {
      final user = await _authRepository.register(
        username: username,
        email: email,
        password: password,
      );

      if (!ref.mounted) return true;

      // Update global auth session
      ref.read(authSessionViewModelProvider.notifier).setAuthenticatedUser(user);

      state = state.copyWith(
        isLoading: false,
        isSuccess: true,
        registeredUser: user,
      );
      return true;
    } on ApiException catch (e) {
      if (!ref.mounted) return false;
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      if (!ref.mounted) return false;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Registration failed: ${e.toString()}',
      );
      return false;
    }
  }

  void reset() {
    state = const RegisterState();
  }
}

final registerViewModelProvider =
    NotifierProvider.autoDispose<RegisterViewModel, RegisterState>(() {
  return RegisterViewModel();
});
