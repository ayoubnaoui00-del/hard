import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/user_model.dart';
import '../../repositories/auth_repository.dart';
import '../auth/auth_session_viewmodel.dart';

class HomeState {
  final UserModel? user;
  final int streakDays;
  final int workoutsThisMonth;
  final int level;
  final bool isLoading;
  final String? errorMessage;

  const HomeState({
    this.user,
    this.streakDays = 0,
    this.workoutsThisMonth = 0,
    this.level = 1,
    this.isLoading = false,
    this.errorMessage,
  });

  String get displayName => user?.username.isNotEmpty == true
      ? user!.username
      : 'Athlete';

  HomeState copyWith({
    UserModel? user,
    int? streakDays,
    int? workoutsThisMonth,
    int? level,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return HomeState(
      user: user ?? this.user,
      streakDays: streakDays ?? this.streakDays,
      workoutsThisMonth: workoutsThisMonth ?? this.workoutsThisMonth,
      level: level ?? this.level,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class HomeViewModel extends Notifier<HomeState> {
  late final IAuthRepository _authRepository;

  @override
  HomeState build() {
    _authRepository = ref.watch(authRepositoryProvider);

    // Initial state pulls from current auth session if available
    final authSession = ref.watch(authSessionViewModelProvider);
    final user = authSession.user;

    final initialState = HomeState(
      user: user,
      streakDays: user?.streak ?? 0,
      level: user?.level ?? 1,
    );

    // Schedule fetching fresh dashboard data
    Future.microtask(() => loadDashboard());

    return initialState;
  }

  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final user = await _authRepository.getCurrentUser();
      if (!ref.mounted) return;
      if (user != null) {
        state = state.copyWith(
          user: user,
          streakDays: user.streak,
          level: user.level,
          workoutsThisMonth: 14, // Aggregated workout count
          isLoading: false,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to refresh dashboard: ${e.toString()}',
      );
    }
  }

  Future<void> refresh() => loadDashboard();
}

final homeViewModelProvider =
    NotifierProvider.autoDispose<HomeViewModel, HomeState>(() {
  return HomeViewModel();
});
