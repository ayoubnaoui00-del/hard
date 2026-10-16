import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gymtrack/models/user_model.dart';
import 'package:gymtrack/repositories/user_repository.dart';
import 'package:gymtrack/viewmodels/user/user_viewmodel.dart';

class FakeUserRepository implements IUserRepository {
  UserModel? cachedUser;
  UserModel profileUser = const UserModel(
    id: 1,
    username: 'testathlete',
    email: 'athlete@example.com',
    level: 3,
    xp: 500,
    streak: 7,
  );

  @override
  Future<UserModel> getCurrentProfile() async => profileUser;

  @override
  Future<UserModel?> getUser(int userId) async => profileUser;

  @override
  Future<UserModel> updateProfile({
    String? username,
    String? email,
    String? avatarUrl,
  }) async {
    profileUser = profileUser.copyWith(
      username: username,
      email: email,
      avatarUrl: avatarUrl,
    );
    cachedUser = profileUser;
    return profileUser;
  }

  @override
  Future<void> cacheUser(UserModel user) async {
    cachedUser = user;
  }

  @override
  Future<UserModel?> getCachedUser() async => cachedUser;

  @override
  Future<void> clearUserCache() async {
    cachedUser = null;
  }
}

void main() {
  group('UserViewModel MVVM Tests', () {
    late FakeUserRepository fakeRepo;
    late ProviderContainer container;

    setUp(() {
      fakeRepo = FakeUserRepository();
      container = ProviderContainer(
        overrides: [
          userRepositoryProvider.overrideWithValue(fakeRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('Fetch profile updates user in state', () async {
      final notifier = container.read(userViewModelProvider.notifier);
      await notifier.fetchProfile();

      final state = container.read(userViewModelProvider);
      expect(state.isLoading, isFalse);
      expect(state.user?.username, 'testathlete');
      expect(state.user?.level, 3);
    });

    test('Update profile alters user information and updates cache', () async {
      final notifier = container.read(userViewModelProvider.notifier);
      final success = await notifier.updateProfile(username: 'champion_athlete');

      expect(success, isTrue);
      final state = container.read(userViewModelProvider);
      expect(state.user?.username, 'champion_athlete');
      expect(fakeRepo.cachedUser?.username, 'champion_athlete');
    });

    test('Invalidate user clears state and repository cache', () async {
      final notifier = container.read(userViewModelProvider.notifier);
      await notifier.fetchProfile();

      await notifier.invalidateUser();

      final state = container.read(userViewModelProvider);
      expect(state.user, isNull);
      expect(fakeRepo.cachedUser, isNull);
    });
  });
}
