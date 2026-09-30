import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/leaderboard_provider.dart';

class LeaderboardView extends ConsumerStatefulWidget {
  const LeaderboardView({super.key});

  @override
  ConsumerState<LeaderboardView> createState() => _LeaderboardViewState();
}

class _LeaderboardViewState extends ConsumerState<LeaderboardView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(leaderboardViewModelProvider.notifier).fetchGlobalLeaderboard();
    });
  }

  Future<void> _refresh() async {
    final state = ref.read(leaderboardViewModelProvider);
    final notifier = ref.read(leaderboardViewModelProvider.notifier);
    switch (state.currentType) {
      case LeaderboardType.global:
        await notifier.fetchGlobalLeaderboard();
        break;
      case LeaderboardType.weekly:
        await notifier.fetchWeeklyLeaderboard();
        break;
      case LeaderboardType.friends:
        await notifier.fetchFriendsLeaderboard();
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(leaderboardViewModelProvider);
    final viewModel = ref.read(leaderboardViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF282832),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                _buildTabButton(
                  context,
                  title: 'Global',
                  isSelected: state.currentType == LeaderboardType.global,
                  onTap: () => viewModel.fetchGlobalLeaderboard(),
                ),
                _buildTabButton(
                  context,
                  title: 'Weekly',
                  isSelected: state.currentType == LeaderboardType.weekly,
                  onTap: () => viewModel.fetchWeeklyLeaderboard(),
                ),
                _buildTabButton(
                  context,
                  title: 'Friends',
                  isSelected: state.currentType == LeaderboardType.friends,
                  onTap: () => viewModel.fetchFriendsLeaderboard(),
                ),
              ],
            ),
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: state.isLoading && state.entries.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: state.entries.length,
                itemBuilder: (context, index) {
                  final entry = state.entries[index];
                  final isTop3 = entry.rank <= 3;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E24),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isTop3 ? const Color(0xFFFFB300) : const Color(0xFF33333F),
                        width: isTop3 ? 1.5 : 1.0,
                      ),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isTop3
                            ? const Color(0xFFFFB300).withValues(alpha: 0.2)
                            : const Color(0xFF282832),
                        child: Text(
                          '#${entry.rank}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isTop3 ? const Color(0xFFFFB300) : Colors.white70,
                          ),
                        ),
                      ),
                      title: Text(
                        entry.username,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        'Level ${entry.level} • ${entry.totalXp} XP',
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      trailing: const Icon(
                        Icons.military_tech_rounded,
                        color: Color(0xFFFFB300),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }

  Widget _buildTabButton(
    BuildContext context, {
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFFF5252) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.grey.shade400,
            ),
          ),
        ),
      ),
    );
  }
}
