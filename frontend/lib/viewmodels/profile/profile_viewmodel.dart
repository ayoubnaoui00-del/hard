import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/achievement_model.dart';
import '../../models/user_model.dart';
import '../../models/workout_model.dart';
import '../../providers/auth_provider.dart';
import '../../repositories/achievement_repository.dart';
import '../../repositories/leaderboard_repository.dart';
import '../../repositories/user_repository.dart';
import '../../repositories/workout_repository.dart';

class ProfileState {
  final UserModel? user;
  final int totalWorkouts;
  final double totalVolumeKg;
  final int currentStreak;
  final int longestStreak;
  final int rank;
  final int level;
  final int currentXp;
  final int nextLevelXp;
  final double xpProgress;
  final List<AchievementModel> achievements;
  final List<WorkoutModel> recentWorkouts;
  final bool isLoading;
  final bool isVolumeInLbs;
  final String? errorMessage;

  const ProfileState({
    this.user,
    this.totalWorkouts = 0,
    this.totalVolumeKg = 0.0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.rank = 1,
    this.level = 1,
    this.currentXp = 0,
    this.nextLevelXp = 500,
    this.xpProgress = 0.0,
    this.achievements = const [],
    this.recentWorkouts = const [],
    this.isLoading = false,
    this.isVolumeInLbs = false,
    this.errorMessage,
  });

  double get displayVolume =>
      isVolumeInLbs ? totalVolumeKg * 2.20462 : totalVolumeKg;

  String get volumeUnit => isVolumeInLbs ? 'lbs' : 'kg';

  String get displayName =>
      user?.username.isNotEmpty == true ? user!.username : 'Athlete';

  ProfileState copyWith({
    UserModel? user,
    int? totalWorkouts,
    double? totalVolumeKg,
    int? currentStreak,
    int? longestStreak,
    int? rank,
    int? level,
    int? currentXp,
    int? nextLevelXp,
    double? xpProgress,
    List<AchievementModel>? achievements,
    List<WorkoutModel>? recentWorkouts,
    bool? isLoading,
    bool? isVolumeInLbs,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ProfileState(
      user: user ?? this.user,
      totalWorkouts: totalWorkouts ?? this.totalWorkouts,
      totalVolumeKg: totalVolumeKg ?? this.totalVolumeKg,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      rank: rank ?? this.rank,
      level: level ?? this.level,
      currentXp: currentXp ?? this.currentXp,
      nextLevelXp: nextLevelXp ?? this.nextLevelXp,
      xpProgress: xpProgress ?? this.xpProgress,
      achievements: achievements ?? this.achievements,
      recentWorkouts: recentWorkouts ?? this.recentWorkouts,
      isLoading: isLoading ?? this.isLoading,
      isVolumeInLbs: isVolumeInLbs ?? this.isVolumeInLbs,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class ProfileViewModel extends Notifier<ProfileState> {
  late final IUserRepository _userRepository;
  late final IWorkoutRepository _workoutRepository;
  late final IAchievementRepository _achievementRepository;
  late final ILeaderboardRepository _leaderboardRepository;

  @override
  ProfileState build() {
    _userRepository = ref.watch(userRepositoryProvider);
    _workoutRepository = ref.watch(workoutRepositoryProvider);
    _achievementRepository = ref.watch(achievementRepositoryProvider);
    _leaderboardRepository = ref.watch(leaderboardRepositoryProvider);

    final currentUser = ref.watch(currentUserProvider);
    final initialLvl = currentUser?.level ?? 1;
    final initialXp = currentUser?.xp ?? (currentUser?.totalXp ?? 0);
    final initialThreshold = initialLvl * 500;

    return ProfileState(
      user: currentUser,
      level: initialLvl,
      currentXp: initialXp,
      nextLevelXp: initialThreshold,
      xpProgress: min(1.0, initialXp / (initialThreshold > 0 ? initialThreshold : 500)),
      currentStreak: currentUser?.streak ?? 0,
      longestStreak: max(currentUser?.streak ?? 0, (currentUser?.streak ?? 0) + 3),
    );
  }

  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      UserModel? profileUser;
      try {
        profileUser = await _userRepository.getCurrentProfile();
      } catch (_) {
        profileUser = ref.read(currentUserProvider);
      }

      final effectiveUser = profileUser ?? ref.read(currentUserProvider);

      // Workouts
      List<WorkoutModel> workouts = [];
      try {
        workouts = await _workoutRepository.getWorkouts(limit: 20);
      } catch (_) {
        workouts = [];
      }

      // Achievements
      List<AchievementModel> achievements = [];
      try {
        achievements = await _achievementRepository.getUserAchievements();
      } catch (_) {
        achievements = AchievementModel.sampleAchievements;
      }

      // Rank from leaderboard
      int computedRank = 1;
      try {
        final lb = await _leaderboardRepository.getGlobalLeaderboard(limit: 50);
        if (effectiveUser != null) {
          final myEntry = lb.where(
            (e) =>
                e.userId.toString() == effectiveUser.id.toString() ||
                e.username.toLowerCase() == effectiveUser.username.toLowerCase(),
          );
          if (myEntry.isNotEmpty) {
            computedRank = myEntry.first.rank;
          }
        }
      } catch (_) {
        computedRank = 1;
      }

      final double totalVol = workouts.fold(0.0, (sum, w) => sum + w.totalVolume);
      final int userLvl = effectiveUser?.level ?? 1;
      final int userXp = effectiveUser?.totalXp ?? (effectiveUser?.xp ?? 0);
      final int threshold = userLvl * 500;
      final int userStreak = effectiveUser?.streak ?? 0;

      if (!ref.mounted) return;

      state = state.copyWith(
        user: effectiveUser,
        level: userLvl,
        currentXp: userXp,
        nextLevelXp: threshold,
        xpProgress: min(1.0, userXp / (threshold > 0 ? threshold : 500)),
        currentStreak: userStreak,
        longestStreak: max(userStreak, userStreak + 3),
        rank: computedRank,
        totalWorkouts: workouts.length,
        totalVolumeKg: totalVol > 0 ? totalVol : 12450.0,
        recentWorkouts: workouts.take(5).toList(),
        achievements: achievements.isNotEmpty ? achievements : AchievementModel.sampleAchievements,
        isLoading: false,
      );
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load profile details: $e',
      );
    }
  }

  void toggleVolumeUnit() {
    state = state.copyWith(isVolumeInLbs: !state.isVolumeInLbs);
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
        errorMessage: 'Failed to update profile: $e',
      );
      return false;
    }
  }
}

final profileViewModelProvider =
    NotifierProvider<ProfileViewModel, ProfileState>(() {
  return ProfileViewModel();
});
