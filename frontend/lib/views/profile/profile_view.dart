import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/achievement_model.dart';
import '../../viewmodels/auth/auth_session_viewmodel.dart';
import '../../viewmodels/profile/profile_viewmodel.dart';

class ProfileView extends ConsumerStatefulWidget {
  const ProfileView({super.key});

  @override
  ConsumerState<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends ConsumerState<ProfileView> {
  final NumberFormat _numberFormat = NumberFormat('#,###');
  final DateFormat _dateFormat = DateFormat('MMM d, yyyy • h:mm a');

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(profileViewModelProvider.notifier).loadProfile();
    });
  }

  void _showAchievementDetails(BuildContext context, AchievementModel achievement) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AchievementDetailsSheet(achievement: achievement),
    );
  }

  void _showEditProfileDialog(BuildContext context) {
    final state = ref.read(profileViewModelProvider);
    final user = state.user;
    final nameCtrl = TextEditingController(text: user?.username ?? '');
    final emailCtrl = TextEditingController(text: user?.email ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Profile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Username',
                labelStyle: TextStyle(color: Colors.white60),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailCtrl,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Email Address',
                labelStyle: TextStyle(color: Colors.white60),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5252),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final ok = await ref.read(profileViewModelProvider.notifier).updateProfile(
                    username: nameCtrl.text.trim(),
                    email: emailCtrl.text.trim(),
                  );
              if (ctx.mounted) Navigator.of(ctx).pop();
              messenger.showSnackBar(
                SnackBar(
                  content: Text(ok ? 'Profile updated successfully!' : 'Failed to update profile.'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final oldPassCtrl = TextEditingController();
    final newPassCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Change Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPassCtrl,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Current Password',
                labelStyle: TextStyle(color: Colors.white60),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPassCtrl,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'New Password',
                labelStyle: TextStyle(color: Colors.white60),
                enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.white24)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF5252),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Password changed successfully!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFFF5252)),
            SizedBox(width: 8),
            Text('Delete Account?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'This action is irreversible. All workout logs, XP, and unlocked achievements will be permanently deleted.',
          style: TextStyle(color: Colors.white70, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB00020),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(authSessionViewModelProvider.notifier).logout();
              if (context.mounted) {
                context.go('/login');
              }
            },
            child: const Text('Delete Account'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileViewModelProvider);
    final viewModel = ref.read(profileViewModelProvider.notifier);
    final authSession = ref.read(authSessionViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF14141B),
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.person_rounded, color: Color(0xFFFF5252), size: 22),
            SizedBox(width: 10),
            Text(
              'Athlete Profile',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20, color: Colors.white),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
            tooltip: 'Refresh',
            onPressed: () => viewModel.loadProfile(),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Color(0xFFFF5252)),
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
        color: const Color(0xFFFF5252),
        backgroundColor: const Color(0xFF1E1E2A),
        onRefresh: () => viewModel.loadProfile(),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          children: [
            // 1. Header Card (Avatar, Username, Email, Edit Button)
            _buildHeaderCard(context, state),

            const SizedBox(height: 16),

            // 2. Level & XP Section (Large Level Display, XP Progress Bar)
            _buildLevelAndXpSection(state),

            const SizedBox(height: 16),

            // 3. Statistics (Workouts, Volume with Unit Toggle, Streak, Longest Streak, Rank)
            _buildStatisticsSection(state, viewModel),

            const SizedBox(height: 16),

            // 4. Achievements Section (Grid of unlocked badges)
            _buildAchievementsSection(context, state),

            const SizedBox(height: 16),

            // 5. Recent Workouts (Last 5 with Date, Exercises, Duration, Volume)
            _buildRecentWorkoutsSection(state),

            const SizedBox(height: 16),

            // 6. Settings & Danger Zone
            _buildSettingsSection(context, authSession),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context, ProfileState state) {
    final displayName = state.displayName;
    final email = state.user?.email ?? '';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1E2C), Color(0xFF14141E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2C2C3E)),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFFFFB300), Color(0xFFFF5252)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 42,
                  backgroundColor: const Color(0xFF242436),
                  child: Text(
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : 'A',
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => _showEditProfileDialog(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF5252),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            displayName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          if (email.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              email,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
          ],
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: () => _showEditProfileDialog(context),
            icon: const Icon(Icons.mode_edit_outline_rounded, size: 16),
            label: const Text('Edit Profile'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFF38384E)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLevelAndXpSection(ProfileState state) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF181824),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2A2A3C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFB300), Color(0xFFFF8F00)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'LVL ${state.level}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Level Progression',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                '${_numberFormat.format(state.currentXp)} / ${_numberFormat.format(state.nextLevelXp)} XP',
                style: const TextStyle(
                  color: Color(0xFFFFB300),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: state.xpProgress,
              minHeight: 10,
              backgroundColor: const Color(0xFF28283A),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFB300)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(state.xpProgress * 100).toInt()}% completed to Level ${state.level + 1}',
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildStatisticsSection(ProfileState state, ProfileViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF181824),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2A2A3C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ATHLETE STATISTICS',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              GestureDetector(
                onTap: () => viewModel.toggleVolumeUnit(),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF252536),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF38384E)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        state.isVolumeInLbs ? 'Unit: lbs' : 'Unit: kg',
                        style: const TextStyle(
                          color: Color(0xFFFF5252),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.swap_horiz_rounded, size: 14, color: Color(0xFFFF5252)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildStatTile(
                title: 'Workouts',
                value: '${state.totalWorkouts}',
                icon: Icons.fitness_center_rounded,
                color: const Color(0xFF60A5FA),
              ),
              const SizedBox(width: 10),
              _buildStatTile(
                title: 'Total Volume',
                value: '${_numberFormat.format(state.displayVolume.toInt())} ${state.volumeUnit}',
                icon: Icons.scale_rounded,
                color: const Color(0xFFFFB300),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildStatTile(
                title: 'Current Streak',
                value: '${state.currentStreak} Days',
                icon: Icons.local_fire_department_rounded,
                color: const Color(0xFFFF5252),
              ),
              const SizedBox(width: 10),
              _buildStatTile(
                title: 'Longest Streak',
                value: '${state.longestStreak} Days',
                icon: Icons.bolt_rounded,
                color: const Color(0xFF34D399),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E2C),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF282838)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 6),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementsSection(BuildContext context, ProfileState state) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF181824),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2A2A3C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ACHIEVEMENTS & BADGES',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                ),
              ),
              Text(
                '${state.achievements.where((a) => a.isUnlocked).length} Unlocked',
                style: const TextStyle(
                  color: Color(0xFFFFB300),
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: state.achievements.map((ach) {
              final isUnlocked = ach.isUnlocked;
              return GestureDetector(
                onTap: () => _showAchievementDetails(context, ach),
                child: Container(
                  width: (MediaQuery.of(context).size.width - 80) / 3,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  decoration: BoxDecoration(
                    color: isUnlocked
                        ? const Color(0xFFFFB300).withValues(alpha: 0.1)
                        : const Color(0xFF1C1C28),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isUnlocked
                          ? const Color(0xFFFFB300).withValues(alpha: 0.5)
                          : const Color(0xFF282836),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        isUnlocked ? Icons.workspace_premium_rounded : Icons.lock_outline_rounded,
                        color: isUnlocked ? const Color(0xFFFFB300) : Colors.white30,
                        size: 28,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        ach.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isUnlocked ? Colors.white : Colors.white38,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentWorkoutsSection(ProfileState state) {
    final recent = state.recentWorkouts;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF181824),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF2A2A3C)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RECENT WORKOUTS (LAST 5)',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          if (recent.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                child: Text(
                  'No logged workouts yet. Log your first workout!',
                  style: TextStyle(color: Colors.white38, fontSize: 13),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recent.length,
              separatorBuilder: (context, index) => const Divider(color: Color(0xFF282838), height: 16),
              itemBuilder: (context, index) {
                final w = recent[index];
                final exerciseSummary = w.exercises.map((e) => e.exerciseName).take(2).join(', ');
                final extra = w.exercises.length > 2 ? ' +${w.exercises.length - 2} more' : '';

                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF5252).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.fitness_center_rounded,
                        color: Color(0xFFFF5252),
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            w.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            exerciseSummary.isNotEmpty ? '$exerciseSummary$extra' : 'Workout Session',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white54, fontSize: 12),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _dateFormat.format(w.date),
                            style: const TextStyle(color: Colors.white38, fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${_numberFormat.format(w.totalVolume.toInt())} kg',
                          style: const TextStyle(
                            color: Color(0xFFFFB300),
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        if (w.duration > 0)
                          Text(
                            '${w.duration} min',
                            style: const TextStyle(color: Colors.white38, fontSize: 11),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context, AuthSessionViewModel authSession) {
    return Material(
      color: const Color(0xFF181824),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF2A2A3C)),
        ),
        child: Column(
          children: [
            ListTile(
              leading: const Icon(Icons.lock_reset_rounded, color: Colors.white70),
              title: const Text('Change Password', style: TextStyle(color: Colors.white, fontSize: 14)),
              trailing: const Icon(Icons.chevron_right_rounded, color: Colors.white38),
              onTap: () => _showChangePasswordDialog(context),
            ),
            const Divider(color: Color(0xFF282838), height: 1),
            ListTile(
              leading: const Icon(Icons.logout_rounded, color: Color(0xFFFF5252)),
              title: const Text('Log Out', style: TextStyle(color: Color(0xFFFF5252), fontSize: 14, fontWeight: FontWeight.bold)),
              onTap: () async {
                await authSession.logout();
                if (context.mounted) {
                  context.go('/login');
                }
              },
            ),
            const Divider(color: Color(0xFF282838), height: 1),
            ListTile(
              leading: const Icon(Icons.delete_forever_rounded, color: Color(0xFFB00020)),
              title: const Text('Delete Account', style: TextStyle(color: Color(0xFFB00020), fontSize: 14)),
              onTap: () => _showDeleteAccountDialog(context),
            ),
          ],
        ),
      ),
    );
  }
}

/// Modal bottom sheet showing achievement badge details
class _AchievementDetailsSheet extends StatelessWidget {
  final AchievementModel achievement;

  const _AchievementDetailsSheet({required this.achievement});

  @override
  Widget build(BuildContext context) {
    final isUnlocked = achievement.isUnlocked;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF181824),
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUnlocked
                    ? const Color(0xFFFFB300).withValues(alpha: 0.15)
                    : const Color(0xFF222230),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isUnlocked ? const Color(0xFFFFB300) : const Color(0xFF333348),
                ),
              ),
              child: Icon(
                isUnlocked ? Icons.workspace_premium_rounded : Icons.lock_outline_rounded,
                color: isUnlocked ? const Color(0xFFFFB300) : Colors.white38,
                size: 44,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              achievement.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: isUnlocked
                    ? const Color(0xFF10B981).withValues(alpha: 0.2)
                    : const Color(0xFF6B7280).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                isUnlocked ? 'UNLOCKED' : 'LOCKED',
                style: TextStyle(
                  color: isUnlocked ? const Color(0xFF34D399) : Colors.white54,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              achievement.description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF28283A),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
