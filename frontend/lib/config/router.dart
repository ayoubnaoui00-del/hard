import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../viewmodels/auth/auth_session_viewmodel.dart';
import '../views/auth/login_view.dart';
import '../views/auth/register_view.dart';
import '../views/main_shell_view.dart';
import '../views/home/home_view.dart';
import '../views/workout/workout_view.dart';
import '../views/workout/log_workout_view.dart';
import '../views/leaderboard/leaderboard_view.dart';
import '../views/profile/profile_view.dart';
import '../views/exercise/exercise_view.dart';
import '../views/coach/coach_view.dart';
import '../views/social/social_view.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen<AuthSessionState>(
      authSessionViewModelProvider,
      (previous, next) => notifyListeners(),
    );
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authSession = _ref.read(authSessionViewModelProvider);
    final isAuthenticated = authSession.isAuthenticated;
    final isAuthRoute = state.matchedLocation == '/login' ||
        state.matchedLocation == '/register';

    // If unauthenticated and trying to access protected routes, redirect to login
    if (!isAuthenticated && !isAuthRoute) {
      return '/login';
    }

    // If authenticated and trying to access auth screens, redirect to home
    if (isAuthenticated && isAuthRoute) {
      return '/home';
    }

    return null;
  }
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/login',
    refreshListenable: notifier,
    redirect: notifier.redirect,
    routes: [
      // Auth Routes
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginView(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterView(),
      ),

      // App Shell with 4 Bottom Navigation Tabs (HRD-30)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShellView(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeView(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/workouts',
                builder: (context, state) => const WorkoutView(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/leaderboard',
                builder: (context, state) => const LeaderboardView(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileView(),
              ),
            ],
          ),
        ],
      ),

      // Dedicated routes accessible from actions and deep links
      GoRoute(
        path: '/workouts/log',
        builder: (context, state) => const LogWorkoutView(),
      ),
      GoRoute(
        path: '/coach',
        builder: (context, state) => const CoachView(),
      ),
      GoRoute(
        path: '/exercises',
        builder: (context, state) => const ExerciseView(),
      ),
      GoRoute(
        path: '/social',
        builder: (context, state) => const SocialView(),
      ),
    ],
  );
});

// Fallback constant router if accessed without provider (backwards compatibility)
final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginView(),
    ),
    GoRoute(
      path: '/register',
      builder: (context, state) => const RegisterView(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeView(),
    ),
  ],
);
