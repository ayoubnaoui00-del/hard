import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../viewmodels/auth/auth_session_viewmodel.dart';
import '../../viewmodels/home/home_viewmodel.dart';
import '../../widgets/gradient_background.dart';
import '../../widgets/velocity_logo.dart';
import 'widgets/home_header_card.dart';
import 'widgets/home_performance_snapshot.dart';
import 'widgets/home_quick_actions.dart';
import 'widgets/home_recent_achievements.dart';
import 'widgets/home_today_summary_card.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeViewModelProvider);
    final homeViewModel = ref.read(homeViewModelProvider.notifier);
    final authSession = ref.read(authSessionViewModelProvider.notifier);

    final todayFormatted = DateFormat('EEEE, MMM d').format(DateTime.now());

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildAppBar(context, authSession),
      body: RefreshIndicator(
        color: AppTheme.velocityDark,
        backgroundColor: AppTheme.velocityLime,
        onRefresh: homeViewModel.refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Compact User & Level Indicator
              HomeHeaderCard(state: homeState),
              const SizedBox(height: 16),

              // 2. Quick Actions ("Log Workout", "Exercises", "AI Coach")
              const HomeQuickActions(),
              const SizedBox(height: 24),

              // 3. Today's Summary (Date, Workouts Logged, Total Volume)
              HomeTodaySummaryCard(
                state: homeState,
                todayFormatted: todayFormatted,
              ),
              const SizedBox(height: 24),

              // 4. Performance Snapshot / Quick Stats (Streak, Weekly Volume, This Month)
              HomePerformanceSnapshotCard(state: homeState),
              const SizedBox(height: 24),

              // 5. Recent Achievements (Last 3 Badges)
              HomeRecentAchievementsSection(state: homeState),

              // Bottom padding for the floating navigation bar
              const SizedBox(height: 110),
            ],
          ),
        ),
      ),
    ),
  );
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    AuthSessionViewModel authSession,
  ) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      title: const VelocityLogo(
        size: 28,
        showText: true,
        title: 'HARD',
      ),
      actions: [
        IconButton(
          icon: const Icon(
            Icons.notifications_none_rounded,
            color: AppTheme.velocityTextPrimary,
            size: 22,
          ),
          tooltip: 'Notifications',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: AppTheme.velocityDarkSurface,
                content: Text(
                  'No new notifications',
                  style: TextStyle(color: Colors.white),
                ),
                duration: Duration(seconds: 2),
              ),
            );
          },
        ),
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: IconButton(
            icon: const Icon(
              Icons.logout_rounded,
              color: AppTheme.velocityTextSecondary,
              size: 22,
            ),
            tooltip: 'Log Out',
            onPressed: () => _confirmLogout(context, authSession),
          ),
        ),
      ],
    );
  }

  void _confirmLogout(BuildContext context, AuthSessionViewModel authSession) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.velocitySurface,
        title: const Text(
          'Log Out',
          style: TextStyle(
            color: AppTheme.velocityTextPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: const Text(
          'Are you sure you want to log out of Hard?',
          style: TextStyle(color: AppTheme.velocityTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await authSession.logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}
