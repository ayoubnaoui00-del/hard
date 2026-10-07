import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../viewmodels/auth/auth_session_viewmodel.dart';
import '../../viewmodels/home/home_viewmodel.dart';
import '../../widgets/velocity_logo.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeViewModelProvider);
    final homeViewModel = ref.read(homeViewModelProvider.notifier);
    final authSession = ref.read(authSessionViewModelProvider.notifier);

    final todayFormatted = DateFormat('EEEE, MMM d').format(DateTime.now());

    return Scaffold(
      backgroundColor: AppTheme.velocityBackground,
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
              // 1. Header Component (Avatar, Level, XP Progress Bar) — Jira Task 5.5 (HRD-30)
              _buildHeader(context, homeState),
              const SizedBox(height: 20),

              // 2. Quick Actions ("Log Workout", "Exercises", "AI Coach") — Jira Task 5.5
              _buildSectionTitle('Quick Actions'),
              const SizedBox(height: 12),
              _buildQuickActions(context),
              const SizedBox(height: 24),

              // 3. Today's Summary (Date, Workouts Logged, Total Volume) — Jira Task 5.5
              _buildTodaysSummary(context, homeState, todayFormatted),
              const SizedBox(height: 24),

              // 4. Performance Snapshot / Quick Stats (Streak, Weekly Volume, This Month) — Jira Task 5.5
              _buildSectionTitle('Performance Snapshot'),
              const SizedBox(height: 12),
              _buildPerformanceSnapshot(context, homeState),
              const SizedBox(height: 24),

              // 5. Recent Achievements (Last 3 Badges) — Jira Task 5.5
              _buildAchievementsSection(context, homeState),

              // Bottom padding for the floating navigation bar
              const SizedBox(height: 110),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Top App Bar
  // ---------------------------------------------------------------------------
  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    AuthSessionViewModel authSession,
  ) {
    return AppBar(
      backgroundColor: AppTheme.velocityBackground,
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

  // ---------------------------------------------------------------------------
  // 1. Header Component (Avatar, Username, Level & XP Progress)
  // ---------------------------------------------------------------------------
  Widget _buildHeader(BuildContext context, HomeState state) {
    final initials = state.displayName.isNotEmpty
        ? state.displayName[0].toUpperCase()
        : 'A';
    final xpPercent = (state.xpProgress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.velocityDarkSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.velocityDarkBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.velocityDark.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // User Avatar
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.velocityLime, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.velocityLime.withValues(alpha: 0.25),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/user_avatar.jpg',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppTheme.velocityLime,
                      child: Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.velocityDark,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome back,',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF9DA8B9),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      state.displayName,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Level Pill Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.velocityLime,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.velocityLime.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  'Lvl ${state.level}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.velocityDark,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // XP Progress Details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Level Progress',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF9DA8B9),
                ),
              ),
              Text(
                '${state.currentXp} / ${state.nextLevelThreshold} XP ($xpPercent%)',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.velocityLime,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: state.xpProgress.clamp(0.0, 1.0),
              minHeight: 10,
              backgroundColor: AppTheme.velocityDarkBorder,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.velocityLime),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Quick Actions
  // ---------------------------------------------------------------------------
  Widget _buildQuickActions(BuildContext context) {
    return Row(
      children: [
        // Log Workout (Primary Accent)
        Expanded(
          child: _buildQuickActionCard(
            title: 'Log Workout',
            subtitle: 'Start session',
            icon: Icons.fitness_center_rounded,
            iconColor: AppTheme.velocityDark,
            bgColor: AppTheme.velocityLime,
            titleColor: AppTheme.velocityDark,
            subtitleColor: const Color(0xFF384435),
            onTap: () => context.go('/workouts/log'),
          ),
        ),
        const SizedBox(width: 10),
        // Exercises (Browse library)
        Expanded(
          child: _buildQuickActionCard(
            title: 'Exercises',
            subtitle: 'Browse library',
            icon: Icons.search_rounded,
            iconColor: AppTheme.velocityDark,
            bgColor: AppTheme.velocitySurface,
            titleColor: AppTheme.velocityTextPrimary,
            subtitleColor: AppTheme.velocityTextSecondary,
            onTap: () => context.go('/explore'),
          ),
        ),
        const SizedBox(width: 10),
        // AI Coach
        Expanded(
          child: _buildQuickActionCard(
            title: 'AI Coach',
            subtitle: 'Ask coach',
            icon: Icons.auto_awesome,
            iconColor: AppTheme.velocityDark,
            bgColor: AppTheme.velocitySurface,
            titleColor: AppTheme.velocityTextPrimary,
            subtitleColor: AppTheme.velocityTextSecondary,
            onTap: () => context.go('/coach'),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required Color titleColor,
    required Color subtitleColor,
    required VoidCallback onTap,
  }) {
    final isPrimary = bgColor == AppTheme.velocityLime;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isPrimary ? Colors.transparent : AppTheme.velocityBorder,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: isPrimary
                  ? AppTheme.velocityLime.withValues(alpha: 0.25)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isPrimary
                    ? AppTheme.velocityDark
                    : AppTheme.velocityLime.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isPrimary
                    ? AppTheme.velocityLime
                    : iconColor,
                size: 20,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: titleColor,
                letterSpacing: -0.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: subtitleColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Today's Summary Component
  // ---------------------------------------------------------------------------
  Widget _buildTodaysSummary(
    BuildContext context,
    HomeState state,
    String todayFormatted,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle("Today's Summary"),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.velocitySurface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.velocityBorder),
              ),
              child: Text(
                todayFormatted,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.velocityTextSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            // Workouts Logged Today Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.velocitySurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.velocityBorder, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.velocityLime.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.check_circle_outline_rounded,
                            color: AppTheme.velocityDark,
                            size: 20,
                          ),
                        ),
                        Text(
                          '${state.workoutsToday}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.velocityTextPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Workouts Logged',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.velocityTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      state.workoutsToday > 0
                          ? 'Sessions completed'
                          : 'No workouts yet',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.velocityTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Total Volume Today Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.velocitySurface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.velocityBorder, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.velocityAmber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.line_weight_rounded,
                            color: AppTheme.velocityAmber,
                            size: 20,
                          ),
                        ),
                        Text(
                          NumberFormat('#,##0').format(state.todayVolume),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.velocityTextPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Total Volume',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.velocityTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'kg lifted today',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.velocityTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Performance Snapshot / Quick Stats
  // ---------------------------------------------------------------------------
  Widget _buildPerformanceSnapshot(BuildContext context, HomeState state) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.velocitySurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.velocityBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // 1. Streak
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      color: Color(0xFFFF5722),
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${state.streakDays}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.velocityTextPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Streak',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.velocityTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 36, color: AppTheme.velocityBorder),
          // 2. Weekly Vol
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.trending_up_rounded,
                      color: Color(0xFF689F38),
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${NumberFormat.compact().format(state.weeklyVolume)} kg',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.velocityTextPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Weekly Vol',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.velocityTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 36, color: AppTheme.velocityBorder),
          // 3. This Month
          Expanded(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.calendar_today_rounded,
                      color: Color(0xFF0288D1),
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${state.workoutsThisMonth}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppTheme.velocityTextPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'This Month',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.velocityTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 5. Recent Achievements
  // ---------------------------------------------------------------------------
  Widget _buildAchievementsSection(BuildContext context, HomeState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('Recent Achievements'),
            Text(
              '${state.recentAchievements.length} Unlocked',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppTheme.velocityDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (state.recentAchievements.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.velocitySurface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.velocityBorder),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.emoji_events_outlined,
                  color: AppTheme.velocityTextMuted,
                  size: 32,
                ),
                SizedBox(height: 8),
                Text(
                  'Complete workouts to unlock achievement badges!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.velocityTextSecondary,
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 94,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: state.recentAchievements.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final badge = state.recentAchievements[index];
                return Container(
                  width: 220,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.velocitySurface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppTheme.velocityBorder,
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppTheme.velocityLime.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getAchievementIcon(badge.badgeIcon),
                          color: AppTheme.velocityDark,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              badge.name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.velocityTextPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              badge.description,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTheme.velocityTextSecondary,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w900,
        letterSpacing: -0.2,
        color: AppTheme.velocityTextPrimary,
      ),
    );
  }

  IconData _getAchievementIcon(String iconKey) {
    switch (iconKey.toLowerCase()) {
      case 'footsteps':
        return Icons.directions_walk_rounded;
      case 'calendar-check':
        return Icons.event_available_rounded;
      case 'dumbbell':
        return Icons.fitness_center_rounded;
      case 'trophy':
        return Icons.emoji_events_rounded;
      case 'crown':
        return Icons.workspace_premium_rounded;
      case 'weight':
      case 'anvil':
        return Icons.line_weight_rounded;
      case 'fire':
      case 'flame':
        return Icons.local_fire_department_rounded;
      case 'meteor':
      case 'lightning':
        return Icons.bolt_rounded;
      case 'shield':
        return Icons.shield_rounded;
      case 'medal':
        return Icons.military_tech_rounded;
      default:
        return Icons.emoji_events_rounded;
    }
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
