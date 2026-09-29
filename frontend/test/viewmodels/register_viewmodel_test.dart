import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymtrack/models/user_model.dart';
import 'package:gymtrack/repositories/auth_repository.dart';
import 'package:gymtrack/services/api_service.dart';
import 'package:gymtrack/viewmodels/auth/register_viewmodel.dart';
import 'package:gymtrack/viewmodels/auth/auth_session_viewmodel.dart';

class FakeAuthRepository implements IAuthRepository {
  bool shouldFail = false;
  String errorMessage = 'Username already taken';

  @override
  Future<UserModel> login({required String email, required String password}) async {
    return const UserModel(
      id: 1,
      username: 'testathlete',
      email: 'test@example.com',
    );
  }

  @override
  Future<UserModel> register({
    required String username,
    required String email,
    required String password,
  }) async {
    if (shouldFail) {
      throw ApiException(message: errorMessage, statusCode: 409);
    }
    return UserModel(
      id: 2,
      username: username,
      email: email,
      level: 1,
      streak: 0,
    );
  }

  @override
  Future<UserModel?> getCurrentUser() async => null;

  @override
  Future<void> logout() async {}

  @override
  Future<bool> isAuthenticated() async => false;

  @override
  Future<String?> refreshToken() async => 'mock_token';
}

void main() {
  group('RegisterViewModel MVVM Tests', () {
    late FakeAuthRepository fakeRepo;
    late ProviderContainer container;

    setUp(() {
      fakeRepo = FakeAuthRepository();
      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial state is unsubmitted and invalid', () {
      final state = container.read(registerViewModelProvider);
      expect(state.username, isEmpty);
      expect(state.email, isEmpty);
      expect(state.password, isEmpty);
      expect(state.confirmPassword, isEmpty);
      expect(state.acceptTerms, isFalse);
      expect(state.isLoading, isFalse);
      expect(state.isSuccess, isFalse);
      expect(state.isValid, isFalse);
    });

    test('Validates short username', () async {
      final notifier = container.read(registerViewModelProvider.notifier);
      notifier.setUsername('ab');
      notifier.setEmail('valid@example.com');
      notifier.setPassword('password123');
      notifier.setConfirmPassword('password123');
      notifier.setAcceptTerms(true);

      final success = await notifier.register();
      expect(success, isFalse);

      final state = container.read(registerViewModelProvider);
      expect(state.errorMessage, 'Username must be at least 3 characters long.');
    });

    test('Validates password mismatch', () async {
      final notifier = container.read(registerViewModelProvider.notifier);
      notifier.setUsername('athlete');
      notifier.setEmail('athlete@example.com');
      notifier.setPassword('password123');
      notifier.setConfirmPassword('different_password');
      notifier.setAcceptTerms(true);

      final success = await notifier.register();
      expect(success, isFalse);

      final state = container.read(registerViewModelProvider);
      expect(state.errorMessage, 'Passwords do not match.');
    });

    test('Validates terms and conditions acceptance', () async {
      final notifier = container.read(registerViewModelProvider.notifier);
      notifier.setUsername('athlete');
      notifier.setEmail('athlete@example.com');
      notifier.setPassword('password123');
      notifier.setConfirmPassword('password123');
      notifier.setAcceptTerms(false);

      final success = await notifier.register();
      expect(success, isFalse);

      final state = container.read(registerViewModelProvider);
      expect(state.errorMessage, 'You must accept the Terms & Conditions.');
    });

    test('Successful registration updates state and session', () async {
      final notifier = container.read(registerViewModelProvider.notifier);
      notifier.setUsername('athlete_hero');
      notifier.setEmail('hero@example.com');
      notifier.setPassword('secret123');
      notifier.setConfirmPassword('secret123');
      notifier.setAcceptTerms(true);

      final success = await notifier.register();
      expect(success, isTrue);

      final state = container.read(registerViewModelProvider);
      expect(state.isSuccess, isTrue);
      expect(state.isLoading, isFalse);
      expect(state.registeredUser?.username, 'athlete_hero');

      final session = container.read(authSessionViewModelProvider);
      expect(session.isAuthenticated, isTrue);
      expect(session.user?.username, 'athlete_hero');
    });

    test('Propagates API exception message on conflict', () async {
      fakeRepo.shouldFail = true;

      final notifier = container.read(registerViewModelProvider.notifier);
      notifier.setUsername('athlete_hero');
      notifier.setEmail('hero@example.com');
      notifier.setPassword('secret123');
      notifier.setConfirmPassword('secret123');
      notifier.setAcceptTerms(true);

      final success = await notifier.register();
      expect(success, isFalse);

      final state = container.read(registerViewModelProvider);
      expect(state.isSuccess, isFalse);
      expect(state.errorMessage, 'Username already taken');
    });
  });
}
