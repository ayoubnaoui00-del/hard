import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/achievement_model.dart';
import '../../models/friend_activity_model.dart';
import '../../viewmodels/auth/auth_session_viewmodel.dart';
import '../../viewmodels/home/home_viewmodel.dart';

class HomeView extends ConsumerWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeViewModelProvider);
    final homeViewModel = ref.read(homeViewModelProvider.notifier);
    final authSession = ref.read(authSessionViewModelProvider.notifier);

    final todayFormatted = DateFormat('EEEE, MMM d').format(DateTime.now());

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5252).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.fitness_center_rounded,
                color: Color(0xFFFF5252),
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'GymTrack',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded),
            tooltip: 'Notifications',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No new notifications'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
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
        onRefresh: homeViewModel.refresh,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          children: [
            // 1. Header Component (Avatar, Level, XP Progress Bar)
            _buildHeader(context, homeState),
            const SizedBox(height: 18),

            // 2. Quick Actions ("Log Workout", "View Leaderboard", "Chat with Coach")
            _buildSectionTitle('Quick Actions'),
            const SizedBox(height: 10),
            _buildQuickActions(context),
            const SizedBox(height: 20),

            // 3. Today's Summary (Date, Workouts Logged, Total Volume)
            _buildTodaysSummary(context, homeState, todayFormatted),
            const SizedBox(height: 20),

            // 4. Quick Stats (Streak, Weekly Volume, Rank)
            _buildSectionTitle('Performance Snapshot'),
            const SizedBox(height: 10),
            _buildQuickStats(context, homeState),
            const SizedBox(height: 20),

            // 5. Recent Achievements (Last 3 Badges)
            _buildRecentAchievements(context, homeState),
            const SizedBox(height: 20),

            // 6. Friends Activity Feed (Top 5 Recent Activities)
            _buildFriendsFeed(context, homeState, homeViewModel),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Header Component
  // ---------------------------------------------------------------------------
  Widget _buildHeader(BuildContext context, HomeState state) {
    final initials = state.displayName.isNotEmpty
        ? state.displayName[0].toUpperCase()
        : 'A';
    final xpPercent = (state.xpProgress * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E24),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF33333F)),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E1E24),
            const Color(0xFF282832).withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar with online/level indicator
              Stack(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFFF5252),
                    child: Text(
                      initials,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00E676),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF1E1E24), width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome back,',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade400,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${state.displayName} 💪',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Level Badge Chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFB300).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFFFB300).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFFFB300), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      'Lvl ${state.level}',
                      style: const TextStyle(
                        color: Color(0xFFFFB300),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // XP Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Level ${state.level} Progress',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${state.currentXp} / ${state.nextLevelThreshold} XP ($xpPercent%)',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF2979FF),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: state.xpProgress,
              minHeight: 8,
              backgroundColor: const Color(0xFF282832),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF2979FF)),
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
        Expanded(
          child: _buildActionTile(
            context,
            title: 'Log Workout',
            subtitle: 'Start session',
            icon: Icons.fitness_center_rounded,
            color: const Color(0xFFFF5252),
            onTap: () => context.go('/workouts'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildActionTile(
            context,
            title: 'Leaderboard',
            subtitle: 'Check ranks',
            icon: Icons.emoji_events_rounded,
            color: const Color(0xFFFFB300),
            onTap: () => context.go('/leaderboard'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildActionTile(
            context,
            title: 'AI Coach',
            subtitle: 'Ask advisor',
            icon: Icons.smart_toy_rounded,
            color: const Color(0xFF2979FF),
            onTap: () => context.go('/coach'),
          ),
        ),
      ],
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E24),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF33333F)),
        ),
        child: Column(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: color.withValues(alpha: 0.15),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Today's Summary
  // ---------------------------------------------------------------------------
  Widget _buildTodaysSummary(
    BuildContext context,
    HomeState state,
    String todayFormatted,
  ) {
    final hasLoggedToday = state.workoutsToday > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E24),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasLoggedToday
              ? const Color(0xFF00E676).withValues(alpha: 0.4)
              : const Color(0xFF33333F),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_rounded,
                    size: 16,
                    color: Color(0xFFFF5252),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Today's Summary",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF282832),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  todayFormatted,
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF282832),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Workouts Logged',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${state.workoutsToday} ${state.workoutsToday == 1 ? "Session" : "Sessions"}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF282832),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Volume',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${NumberFormat('#,##0').format(state.todayVolume)} kg',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00E676),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Quick Stats Component
  // ---------------------------------------------------------------------------
  Widget _buildQuickStats(BuildContext context, HomeState state) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF33333F)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildQuickStatItem(
            label: 'Streak',
            value: '${state.streakDays} Days',
            emoji: '🔥',
            color: const Color(0xFFFF5252),
          ),
          Container(width: 1, height: 36, color: const Color(0xFF33333F)),
          _buildQuickStatItem(
            label: 'Weekly Vol',
            value: '${NumberFormat.compact().format(state.weeklyVolume)} kg',
            emoji: '🏋️',
            color: const Color(0xFF2979FF),
          ),
          Container(width: 1, height: 36, color: const Color(0xFF33333F)),
          _buildQuickStatItem(
            label: 'Global Rank',
            value: '#${state.userRank}',
            emoji: '🏆',
            color: const Color(0xFFFFB300),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatItem({
    required String label,
    required String value,
    required String emoji,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          '$emoji $value',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 5. Recent Achievements Component
  // ---------------------------------------------------------------------------
  Widget _buildRecentAchievements(BuildContext context, HomeState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('Recent Achievements'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFFB300).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '${state.recentAchievements.length} Badges',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFFFB300),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 116,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: state.recentAchievements.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final badge = state.recentAchievements[index];
              return _buildAchievementCard(badge);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAchievementCard(AchievementModel badge) {
    return Container(
      width: 190,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFB300).withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFFFB300).withValues(alpha: 0.15),
                child: Icon(
                  _getAchievementIcon(badge.badgeIcon),
                  color: const Color(0xFFFFB300),
                  size: 18,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF00E676),
                size: 16,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            badge.name,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            badge.description,
            style: TextStyle(fontSize: 10, color: Colors.grey.shade400),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 6. Friends Activity Feed Component
  // ---------------------------------------------------------------------------
  Widget _buildFriendsFeed(
    BuildContext context,
    HomeState state,
    HomeViewModel viewModel,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionTitle('Friends Activity Feed'),
            const Text(
              'Top 5 Recent',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.friendsActivities.length,
          separatorBuilder: (context, index) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final activity = state.friendsActivities[index];
            return _buildFeedItem(activity, () {
              viewModel.toggleLikeActivity(activity.id);
            });
          },
        ),
      ],
    );
  }

  Widget _buildFeedItem(FriendActivityModel activity, VoidCallback onLike) {
    final initials = activity.username.isNotEmpty
        ? activity.username[0].toUpperCase()
        : 'F';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E24),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF33333F)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFF282832),
            child: Text(
              initials,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      activity.username,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      activity.timeAgo,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  activity.title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFFFF5252),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activity.description,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade300,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onLike,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                children: [
                  Icon(
                    activity.isLiked
                        ? Icons.local_fire_department_rounded
                        : Icons.local_fire_department_outlined,
                    color: activity.isLiked
                        ? const Color(0xFFFF5252)
                        : Colors.grey,
                    size: 18,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    '${activity.likesCount}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: activity.isLiked
                          ? const Color(0xFFFF5252)
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.bold,
        color: Colors.white,
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
      case 'gem':
      case 'star':
        return Icons.star_rounded;
      default:
        return Icons.emoji_events_rounded;
    }
  }
}
