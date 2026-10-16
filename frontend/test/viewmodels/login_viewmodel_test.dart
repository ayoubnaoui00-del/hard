import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymtrack/models/user_model.dart';
import 'package:gymtrack/repositories/auth_repository.dart';
import 'package:gymtrack/services/api_service.dart';
import 'package:gymtrack/viewmodels/auth/login_viewmodel.dart';
import 'package:gymtrack/viewmodels/auth/auth_session_viewmodel.dart';

class FakeAuthRepository implements IAuthRepository {
  bool shouldFail = false;
  String errorMessage = 'Invalid credentials';
  UserModel? mockUser;

  @override
  Future<UserModel> login({required String email, required String password}) async {
    if (shouldFail) {
      throw ApiException(message: errorMessage, statusCode: 401);
    }
    return mockUser ??
        const UserModel(
          id: 1,
          username: 'testathlete',
          email: 'test@example.com',
          level: 2,
          streak: 5,
        );
  }

  @override
  Future<UserModel> register({
    required String username,
    required String email,
    required String password,
  }) async {
    return const UserModel(
      id: 1,
      username: 'testathlete',
      email: 'test@example.com',
    );
  }

  @override
  Future<UserModel?> getCurrentUser() async => mockUser;

  @override
  Future<void> logout() async {}

  @override
  Future<bool> isAuthenticated() async => mockUser != null;

  @override
  Future<String?> refreshToken() async => 'fake_token';
}

void main() {
  group('LoginViewModel MVVM Tests', () {
    late FakeAuthRepository fakeAuthRepository;
    late ProviderContainer container;

    setUp(() {
      fakeAuthRepository = FakeAuthRepository();
      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeAuthRepository),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial state is clean and valid is false', () {
      final state = container.read(loginViewModelProvider);
      expect(state.email, isEmpty);
      expect(state.password, isEmpty);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
      expect(state.isSuccess, isFalse);
      expect(state.isValid, isFalse);
    });

    test('setEmail and setPassword updates state and clears errors', () {
      final notifier = container.read(loginViewModelProvider.notifier);
      notifier.setEmail('athlete@test.com');
      notifier.setPassword('password123');

      final state = container.read(loginViewModelProvider);
      expect(state.email, 'athlete@test.com');
      expect(state.password, 'password123');
      expect(state.isValid, isTrue);
    });

    test('Validation failure when fields are empty', () async {
      final notifier = container.read(loginViewModelProvider.notifier);
      final success = await notifier.login();

      expect(success, isFalse);
      final state = container.read(loginViewModelProvider);
      expect(state.errorMessage, 'Please enter both email and password.');
      expect(state.isLoading, isFalse);
      expect(state.isSuccess, isFalse);
    });

    test('Successful login updates state and authSessionViewModel', () async {
      final notifier = container.read(loginViewModelProvider.notifier);
      notifier.setEmail('athlete@test.com');
      notifier.setPassword('password123');

      final success = await notifier.login();

      expect(success, isTrue);
      final loginState = container.read(loginViewModelProvider);
      expect(loginState.isSuccess, isTrue);
      expect(loginState.isLoading, isFalse);
      expect(loginState.errorMessage, isNull);
      expect(loginState.loggedInUser?.username, 'testathlete');

      // Verify global session was updated
      final sessionState = container.read(authSessionViewModelProvider);
      expect(sessionState.isAuthenticated, isTrue);
      expect(sessionState.user?.username, 'testathlete');
    });

    test('Failed login captures ApiException message in state', () async {
      fakeAuthRepository.shouldFail = true;
      fakeAuthRepository.errorMessage = 'Incorrect email or password.';

      final notifier = container.read(loginViewModelProvider.notifier);
      notifier.setEmail('athlete@test.com');
      notifier.setPassword('wrongpass');

      final success = await notifier.login();

      expect(success, isFalse);
      final loginState = container.read(loginViewModelProvider);
      expect(loginState.isSuccess, isFalse);
      expect(loginState.isLoading, isFalse);
      expect(loginState.errorMessage, 'Incorrect email or password.');
    });
  });
}
