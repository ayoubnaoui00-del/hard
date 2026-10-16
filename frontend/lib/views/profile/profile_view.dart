import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../viewmodels/auth/auth_session_viewmodel.dart';
import '../../viewmodels/profile/profile_viewmodel.dart';
import '../../widgets/gradient_background.dart';
import 'widgets/profile_achievements_card.dart';
import 'widgets/profile_dialogs.dart';
import 'widgets/profile_header_card.dart';
import 'widgets/profile_level_xp_card.dart';
import 'widgets/profile_recent_workouts_card.dart';
import 'widgets/profile_settings_card.dart';
import 'widgets/profile_statistics_card.dart';

class ProfileView extends ConsumerStatefulWidget {
  const ProfileView({super.key});

  @override
  ConsumerState<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<ProfileView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(profileViewModelProvider.notifier).loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileViewModelProvider);
    final viewModel = ref.read(profileViewModelProvider.notifier);
    final authSession = ref.read(authSessionViewModelProvider.notifier);

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Row(
          children: [
            Icon(Icons.person_rounded, color: AppTheme.velocityLime, size: 22),
            SizedBox(width: 10),
            Text(
              'Athlete Profile',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 20,
                letterSpacing: -0.3,
                color: AppTheme.velocityTextPrimary,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppTheme.velocityTextSecondary),
            tooltip: 'Refresh',
            onPressed: () => viewModel.loadProfile(),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppTheme.velocityTextSecondary),
            tooltip: 'Log out',
            onPressed: () async {
              await authSession.logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.velocityDark,
        backgroundColor: AppTheme.velocityLime,
        onRefresh: () => viewModel.loadProfile(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            // 1. Header Card (Avatar, Username, Email, Edit Button)
            ProfileHeaderCard(
              displayName: state.displayName,
              email: state.user?.email ?? '',
              onEdit: () => ProfileDialogs.showEditProfileDialog(context, ref),
            ),

            const SizedBox(height: 16),

            // 2. Level & XP Section
            ProfileLevelXpCard(
              level: state.level,
              currentXp: state.currentXp,
              nextLevelXp: state.nextLevelXp,
              xpProgress: state.xpProgress,
            ),

            const SizedBox(height: 16),

            // 3. Statistics
            ProfileStatisticsCard(
              state: state,
              onToggleUnit: () => viewModel.toggleVolumeUnit(),
            ),

            const SizedBox(height: 16),

            // 4. Achievements Section
            ProfileAchievementsCard(
              state: state,
              onShowDetails: (ach) =>
                  AchievementDetailsSheet.show(context, ach),
            ),

            const SizedBox(height: 16),

            // 5. Recent Workouts
            ProfileRecentWorkoutsCard(
              recentWorkouts: state.recentWorkouts,
            ),

            const SizedBox(height: 16),

            // 6. Settings & Danger Zone
            ProfileSettingsCard(
              onChangePassword: () =>
                  ProfileDialogs.showChangePasswordDialog(context),
              onLogout: () async {
                await authSession.logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
              onDeleteAccount: () =>
                  ProfileDialogs.showDeleteAccountDialog(context, authSession),
            ),
          ],
        ),
      ),
    ),
  );
  }
}
