import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../viewmodels/auth/auth_session_viewmodel.dart';
import '../../viewmodels/user/user_viewmodel.dart';

class ProfileView extends ConsumerWidget {
  const ProfileView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userViewModelProvider);
    final authSession = ref.read(authSessionViewModelProvider.notifier);
    final user = userState.user;

    final displayName = user?.username.isNotEmpty == true ? user!.username : 'Athlete';
    final email = user?.email ?? '';
    final level = user?.level ?? 1;
    final streak = user?.streak ?? 0;
    final totalXp = user?.totalXp ?? (user?.xp ?? 0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Athlete Profile'),
        actions: [
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profile Header Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: const Color(0xFFFF5252),
                    child: Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : 'A',
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    displayName,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(email, style: TextStyle(color: Colors.grey.shade400)),
                  ],
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF282832),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF33333F)),
                    ),
                    child: Text(
                      '⭐ Level $level Competitor',
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFFFB300)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Overview Stats
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  title: 'Streak',
                  value: '$streak Days',
                  icon: Icons.local_fire_department_rounded,
                  color: const Color(0xFFFF5252),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildMetricCard(
                  title: 'Total XP',
                  value: '$totalXp',
                  icon: Icons.star_rounded,
                  color: const Color(0xFFFFB300),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Actions List
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.edit_outlined, color: Colors.white70),
                  title: const Text('Edit Profile'),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  onTap: () {},
                ),
                const Divider(height: 1, color: Color(0xFF33333F)),
                ListTile(
                  leading: const Icon(Icons.notifications_outlined, color: Colors.white70),
                  title: const Text('Workout Reminders'),
                  trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
                  onTap: () {},
                ),
                const Divider(height: 1, color: Color(0xFF33333F)),
                ListTile(
                  leading: const Icon(Icons.logout_rounded, color: Color(0xFFFF5252)),
                  title: const Text('Sign Out', style: TextStyle(color: Color(0xFFFF5252))),
                  onTap: () async {
                    await authSession.logout();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF33333F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
