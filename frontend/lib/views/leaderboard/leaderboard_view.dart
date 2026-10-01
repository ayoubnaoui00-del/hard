import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../providers/auth_provider.dart';
import '../../providers/leaderboard_provider.dart';

class LeaderboardView extends ConsumerStatefulWidget {
  const LeaderboardView({super.key});

  @override
  ConsumerState<LeaderboardView> createState() => _LeaderboardViewState();
}

class _LeaderboardViewState extends ConsumerState<LeaderboardView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final NumberFormat _numberFormat = NumberFormat('#,###');

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.microtask(() {
      ref.read(leaderboardViewModelProvider.notifier).fetchGlobalLeaderboard();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(leaderboardViewModelProvider.notifier).loadMore();
    }
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

  void _showUserProfilePreview(BuildContext context, LeaderboardEntryModel entry) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _UserProfilePreviewSheet(entry: entry, numberFormat: _numberFormat),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(leaderboardViewModelProvider);
    final viewModel = ref.read(leaderboardViewModelProvider.notifier);
    final currentUser = ref.watch(currentUserProvider);

    final displayedEntries = state.filteredEntries;
    final hasSearch = state.searchQuery.trim().isNotEmpty;
    final top3 = !hasSearch && state.entries.length >= 3 ? state.top3 : <LeaderboardEntryModel>[];
    final listEntries = !hasSearch && state.entries.length >= 3
        ? state.remainingEntries
        : displayedEntries;

    // Determine current user rank if known
    LeaderboardEntryModel? myEntry = state.currentUserEntry;
    if (myEntry == null && currentUser != null) {
      try {
        myEntry = state.entries.firstWhere(
          (e) =>
              e.userId.toString() == currentUser.id.toString() ||
              e.username.toLowerCase() == currentUser.username.toLowerCase(),
        );
      } catch (_) {
        myEntry = null;
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      appBar: AppBar(
        backgroundColor: const Color(0xFF14141B),
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFB300), Color(0xFFFF5252)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Leaderboard',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 20,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(106),
          child: Column(
            children: [
              // Segmented Tab Switcher
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F1F2A),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF2E2E3E), width: 1),
                ),
                child: Row(
                  children: [
                    _buildTabButton(
                      title: 'Global',
                      icon: Icons.public_rounded,
                      isSelected: state.currentType == LeaderboardType.global,
                      onTap: () {
                        _searchController.clear();
                        viewModel.setSearchQuery('');
                        viewModel.fetchGlobalLeaderboard();
                      },
                    ),
                    _buildTabButton(
                      title: 'Weekly',
                      icon: Icons.bolt_rounded,
                      isSelected: state.currentType == LeaderboardType.weekly,
                      onTap: () {
                        _searchController.clear();
                        viewModel.setSearchQuery('');
                        viewModel.fetchWeeklyLeaderboard();
                      },
                    ),
                    _buildTabButton(
                      title: 'Friends',
                      icon: Icons.people_alt_rounded,
                      isSelected: state.currentType == LeaderboardType.friends,
                      onTap: () {
                        _searchController.clear();
                        viewModel.setSearchQuery('');
                        viewModel.fetchFriendsLeaderboard();
                      },
                    ),
                  ],
                ),
              ),
              // Search Input
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => viewModel.setSearchQuery(val),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Search athlete by name...',
                      hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                      prefixIcon: const Icon(Icons.search_rounded, color: Colors.white38, size: 18),
                      suffixIcon: state.searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded, color: Colors.white38, size: 16),
                              onPressed: () {
                                _searchController.clear();
                                viewModel.setSearchQuery('');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFF1B1B24),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF2E2E3E)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFF2E2E3E)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: Color(0xFFFF5252)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: RefreshIndicator(
              color: const Color(0xFFFF5252),
              backgroundColor: const Color(0xFF1A1A24),
              onRefresh: _refresh,
              child: state.isLoading && state.entries.isEmpty
                  ? _buildLoadingSkeleton()
                  : state.errorMessage != null && state.entries.isEmpty
                      ? _buildErrorView(state.errorMessage!)
                      : state.entries.isEmpty
                          ? _buildEmptyView()
                          : CustomScrollView(
                              controller: _scrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              slivers: [
                                // Top 3 Podium (only when not searching)
                                if (top3.isNotEmpty)
                                  SliverToBoxAdapter(
                                    child: _buildPodium(top3),
                                  ),

                                // Section Header for remaining ranks
                                if (top3.isNotEmpty)
                                  SliverToBoxAdapter(
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'RANKINGS',
                                            style: TextStyle(
                                              color: Colors.white54,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.1,
                                            ),
                                          ),
                                          Text(
                                            state.currentType == LeaderboardType.weekly
                                                ? 'Weekly Volume (kg)'
                                                : 'Total Volume (kg)',
                                            style: const TextStyle(
                                              color: Colors.white38,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                // Remaining Ranked List
                                SliverPadding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                  sliver: SliverList(
                                    delegate: SliverChildBuilderDelegate(
                                      (context, index) {
                                        final entry = listEntries[index];
                                        return _buildLeaderboardRow(entry);
                                      },
                                      childCount: listEntries.length,
                                    ),
                                  ),
                                ),

                                // Loading More Indicator
                                if (state.isLoadingMore)
                                  const SliverToBoxAdapter(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(vertical: 20),
                                      child: Center(
                                        child: SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Color(0xFFFF5252),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                const SliverToBoxAdapter(child: SizedBox(height: 80)),
                              ],
                            ),
            ),
          ),

          // User's Pinned Standing Bar
          if (myEntry != null) _buildUserStandingBar(myEntry),
        ],
      ),
    );
  }

  Widget _buildTabButton({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFFFF5252), Color(0xFFFF3838)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  )
                : null,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: const Color(0xFFFF5252).withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? Colors.white : Colors.white54,
              ),
              const SizedBox(width: 5),
              Text(
                title,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 13,
                  color: isSelected ? Colors.white : Colors.white60,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPodium(List<LeaderboardEntryModel> top3) {
    final first = top3[0];
    final second = top3.length > 1 ? top3[1] : null;
    final third = top3.length > 2 ? top3[2] : null;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.fromLTRB(12, 20, 12, 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF1E1E2A),
            const Color(0xFF14141D).withValues(alpha: 0.8),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2E2E3E), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd Place (Silver)
          if (second != null)
            Expanded(
              child: _buildPodiumPillar(
                entry: second,
                place: 2,
                height: 120,
                medalColor: const Color(0xFFD1D5DB),
                gradient: const [Color(0xFF9CA3AF), Color(0xFF4B5563)],
                label: '2nd',
              ),
            )
          else
            const Expanded(child: SizedBox()),

          const SizedBox(width: 8),

          // 1st Place (Gold)
          Expanded(
            child: _buildPodiumPillar(
              entry: first,
              place: 1,
              height: 155,
              medalColor: const Color(0xFFFFD700),
              gradient: const [Color(0xFFFFB300), Color(0xFFB45309)],
              label: '1st',
              isFirst: true,
            ),
          ),

          const SizedBox(width: 8),

          // 3rd Place (Bronze)
          if (third != null)
            Expanded(
              child: _buildPodiumPillar(
                entry: third,
                place: 3,
                height: 100,
                medalColor: const Color(0xFFF59E0B),
                gradient: const [Color(0xFFD97706), Color(0xFF78350F)],
                label: '3rd',
              ),
            )
          else
            const Expanded(child: SizedBox()),
        ],
      ),
    );
  }

  Widget _buildPodiumPillar({
    required LeaderboardEntryModel entry,
    required int place,
    required double height,
    required Color medalColor,
    required List<Color> gradient,
    required String label,
    bool isFirst = false,
  }) {
    final state = ref.watch(leaderboardViewModelProvider);
    final volume = state.currentType == LeaderboardType.weekly
        ? (entry.weeklyVolume > 0 ? entry.weeklyVolume : entry.weeklyXp)
        : (entry.totalVolume > 0 ? entry.totalVolume : entry.totalXp);

    return GestureDetector(
      onTap: () => _showUserProfilePreview(context, entry),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Crown for 1st place
          if (isFirst)
            const Padding(
              padding: EdgeInsets.only(bottom: 2),
              child: Icon(
                Icons.military_tech_rounded,
                color: Color(0xFFFFD700),
                size: 28,
              ),
            ),

          // Avatar with badge
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: medalColor,
                    width: isFirst ? 3.0 : 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: medalColor.withValues(alpha: isFirst ? 0.45 : 0.25),
                      blurRadius: isFirst ? 14 : 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: CircleAvatar(
                  radius: isFirst ? 28 : 22,
                  backgroundColor: const Color(0xFF262635),
                  child: Text(
                    entry.username.isNotEmpty
                        ? entry.username.substring(0, 1).toUpperCase()
                        : 'A',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: isFirst ? 20 : 16,
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: medalColor,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [
                      BoxShadow(color: Colors.black45, blurRadius: 4),
                    ],
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w900,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Username
          Text(
            entry.username,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isFirst ? 13 : 12,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 2),

          // Volume / Score
          Text(
            '${_numberFormat.format(volume)} kg',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 11,
              color: medalColor,
            ),
          ),

          const SizedBox(height: 8),

          // Podium Pedestal
          Container(
            height: height,
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  gradient[0].withValues(alpha: 0.35),
                  gradient[1].withValues(alpha: 0.15),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border.all(
                color: medalColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '#$place',
                  style: TextStyle(
                    color: medalColor.withValues(alpha: 0.8),
                    fontSize: isFirst ? 28 : 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black38,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'LVL ${entry.level}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardRow(LeaderboardEntryModel entry) {
    final state = ref.watch(leaderboardViewModelProvider);
    final isTop10 = entry.rank <= 10;
    final isMe = entry.isCurrentUser;
    final volume = state.currentType == LeaderboardType.weekly
        ? (entry.weeklyVolume > 0 ? entry.weeklyVolume : entry.weeklyXp)
        : (entry.totalVolume > 0 ? entry.totalVolume : entry.totalXp);

    return GestureDetector(
      onTap: () => _showUserProfilePreview(context, entry),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe
              ? const Color(0xFFFF5252).withValues(alpha: 0.12)
              : const Color(0xFF181822),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isMe
                ? const Color(0xFFFF5252)
                : isTop10
                    ? const Color(0xFF38384C)
                    : const Color(0xFF262635),
            width: isMe ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            // Rank Number Badge
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isTop10
                    ? const Color(0xFFFFB300).withValues(alpha: 0.15)
                    : const Color(0xFF222230),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '#${entry.rank}',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: isTop10 ? const Color(0xFFFFB300) : Colors.white60,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // User Avatar
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFF282836),
              child: Text(
                entry.username.isNotEmpty
                    ? entry.username.substring(0, 1).toUpperCase()
                    : 'A',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.white,
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Username, Level, Streak
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          entry.username,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isMe ? const Color(0xFFFF7B7B) : Colors.white,
                          ),
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF5252),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'YOU',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2B2B3A),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'LVL ${entry.level}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (entry.streak > 0) ...[
                        const SizedBox(width: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.local_fire_department_rounded,
                              color: Color(0xFFFF5252),
                              size: 13,
                            ),
                            Text(
                              '${entry.streak}d',
                              style: const TextStyle(
                                color: Color(0xFFFF7B7B),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Volume Stat
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${_numberFormat.format(volume)} kg',
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: Color(0xFFE2E8F0),
                  ),
                ),
                Text(
                  state.currentType == LeaderboardType.weekly ? 'this week' : 'lifetime',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.white38,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserStandingBar(LeaderboardEntryModel myEntry) {
    final state = ref.watch(leaderboardViewModelProvider);
    final volume = state.currentType == LeaderboardType.weekly
        ? (myEntry.weeklyVolume > 0 ? myEntry.weeklyVolume : myEntry.weeklyXp)
        : (myEntry.totalVolume > 0 ? myEntry.totalVolume : myEntry.totalXp);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2A),
        border: const Border(
          top: BorderSide(color: Color(0xFFFF5252), width: 2),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5252),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '#${myEntry.rank}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Your Standing',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${myEntry.username} • Level ${myEntry.level}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${_numberFormat.format(volume)} kg',
                  style: const TextStyle(
                    color: Color(0xFFFF5252),
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                Text(
                  '${myEntry.streak}d streak 🔥',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 6),
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFF1B1B24),
            borderRadius: BorderRadius.circular(14),
          ),
        );
      },
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFFF5252), size: 48),
            const SizedBox(height: 12),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5252),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.leaderboard_outlined, color: Colors.white24, size: 56),
            const SizedBox(height: 12),
            const Text(
              'No rankings found',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Log workouts or add friends to see rankings here!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white54, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _refresh,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF262635),
                foregroundColor: Colors.white,
              ),
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Rich athlete profile preview bottom sheet
class _UserProfilePreviewSheet extends StatelessWidget {
  final LeaderboardEntryModel entry;
  final NumberFormat numberFormat;

  const _UserProfilePreviewSheet({
    required this.entry,
    required this.numberFormat,
  });

  @override
  Widget build(BuildContext context) {
    final isTop3 = entry.rank <= 3;
    final medalColor = entry.rank == 1
        ? const Color(0xFFFFD700)
        : entry.rank == 2
            ? const Color(0xFFD1D5DB)
            : entry.rank == 3
                ? const Color(0xFFF59E0B)
                : const Color(0xFFFF5252);

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF171720),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 18),

            // Avatar & Rank
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: const Color(0xFF262636),
                  child: Text(
                    entry.username.isNotEmpty
                        ? entry.username.substring(0, 1).toUpperCase()
                        : 'A',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
                Positioned(
                  bottom: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: medalColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '#${entry.rank}',
                      style: const TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Username
            Text(
              entry.username,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),

            // Athlete title
            Text(
              isTop3 ? 'Elite Podium Athlete' : 'Active Contender',
              style: TextStyle(
                fontSize: 12,
                color: medalColor,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 20),

            // Stat Cards Row
            Row(
              children: [
                _buildStatCard(
                  label: 'LEVEL',
                  value: '${entry.level}',
                  icon: Icons.shield_rounded,
                  iconColor: const Color(0xFF60A5FA),
                ),
                const SizedBox(width: 8),
                _buildStatCard(
                  label: 'STREAK',
                  value: '${entry.streak}d',
                  icon: Icons.local_fire_department_rounded,
                  iconColor: const Color(0xFFFF5252),
                ),
                const SizedBox(width: 8),
                _buildStatCard(
                  label: 'VOLUME',
                  value: '${numberFormat.format(entry.totalVolume > 0 ? entry.totalVolume : entry.totalXp)} kg',
                  icon: Icons.fitness_center_rounded,
                  iconColor: const Color(0xFFFFB300),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Sent cheer to ${entry.username}! 👊'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.thumb_up_alt_rounded, size: 16),
                    label: const Text('Cheer 👊'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF333348)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Challenge invited for ${entry.username}! ⚔️'),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    icon: const Icon(Icons.sports_martial_arts_rounded, size: 16),
                    label: const Text('Challenge ⚔️'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF5252),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF20202E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2C2C3D)),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 20),
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
              label,
              style: const TextStyle(
                color: Colors.white38,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
