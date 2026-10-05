import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../viewmodels/auth/auth_session_viewmodel.dart';
import '../../viewmodels/home/home_viewmodel.dart';
import '../../widgets/perspective_grid.dart';
import '../../widgets/segmented_progress_bar.dart';
import '../../widgets/velocity_logo.dart';
import '../../widgets/workout_card.dart';
import '../../widgets/workout_lineup_pill.dart';

class HomeView extends ConsumerStatefulWidget {
  const HomeView({super.key});

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  // Interactive workout line-up state
  final List<Map<String, dynamic>> _lineupItems = [
    {
      'id': '1',
      'title': 'Conditioning: Body Movement',
      'playBg': AppTheme.velocityLime,
      'playIcon': AppTheme.velocityDark,
      'type': 'movement',
    },
    {
      'id': '2',
      'title': 'Sonic Meditation',
      'playBg': AppTheme.velocityDarkSurface,
      'playIcon': Colors.white,
      'type': 'meditation',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final homeState = ref.watch(homeViewModelProvider);
    final homeViewModel = ref.read(homeViewModelProvider.notifier);
    final authSession = ref.read(authSessionViewModelProvider.notifier);

    return Scaffold(
      backgroundColor: AppTheme.velocityBackground,
      appBar: _buildVelocityAppBar(context, authSession),
      body: RefreshIndicator(
        color: AppTheme.velocityDark,
        backgroundColor: AppTheme.velocityLime,
        onRefresh: homeViewModel.refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              // 1. Top Program & Check-In Cards (Horizontal Row)
              _buildProgramAndCheckInRow(context, homeState),
              const SizedBox(height: 24),

              // 2. Perspective 3D Wireframe Grid with Workout Line-Up & Cards
              PerspectiveGridBackground(
                child: Column(
                  children: [
                    // Section Title: "How's Your Workout Line-Up !"
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Center(
                        child: Text(
                          "How's Your Workout Line-Up !",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.4,
                            color: AppTheme.velocityTextPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Interactive Line-Up Pills
                    _buildLineUpPills(context),
                    const SizedBox(height: 26),

                    // Horizontal Workout Cards Carousel
                    _buildWorkoutCardsCarousel(context),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // 3. Performance Snapshot & Activity Metrics (Integrated stats)
              _buildPerformanceMetricsSection(context, homeState),

              const SizedBox(height: 24),

              // 4. Badges & Achievements
              if (homeState.recentAchievements.isNotEmpty)
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
  // Top Navigation Bar
  // ---------------------------------------------------------------------------
  PreferredSizeWidget _buildVelocityAppBar(
    BuildContext context,
    AuthSessionViewModel authSession,
  ) {
    return AppBar(
      backgroundColor: AppTheme.velocityBackground,
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      title: const VelocityLogo(
        size: 30,
        showText: true,
        title: 'VELOCITY',
      ),
      actions: [
        // Calendar Button
        IconButton(
          icon: const Icon(
            Icons.calendar_today_outlined,
            size: 22,
            color: AppTheme.velocityTextPrimary,
          ),
          tooltip: 'Schedule & Calendar',
          onPressed: () => _showCalendarScheduleSheet(context),
        ),
        // Notification Bell with Lime Dot
        Stack(
          alignment: Alignment.topRight,
          children: [
            IconButton(
              icon: const Icon(
                Icons.notifications_none_rounded,
                size: 24,
                color: AppTheme.velocityTextPrimary,
              ),
              tooltip: 'Notifications',
              onPressed: () => _showNotificationsSheet(context),
            ),
            Positioned(
              top: 10,
              right: 12,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppTheme.velocityLimeBright,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.velocityBackground,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
        // User Profile Avatar
        Padding(
          padding: const EdgeInsets.only(right: 16, left: 4),
          child: GestureDetector(
            onTap: () => _showUserMenu(context, authSession),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.velocityBorder,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/user_avatar.jpg',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppTheme.velocityLime,
                      child: const Center(
                        child: Text(
                          'A',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.velocityDark,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Program & Check-In Cards
  // ---------------------------------------------------------------------------
  Widget _buildProgramAndCheckInRow(BuildContext context, HomeState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          // Your Program Card
          Expanded(
            child: GestureDetector(
              onTap: () => _showProgramDetailsSheet(context),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppTheme.velocityBorder, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your Program',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                        color: AppTheme.velocityTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const SegmentedProgressBar(
                      totalSegments: 4,
                      completedSegments: 3,
                      activeColor: AppTheme.velocityLime,
                      hasStripedCurrent: true,
                      height: 14,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '3/4 Required Sessions',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.velocityTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Check-In Card
          Expanded(
            child: GestureDetector(
              onTap: () => _showCheckInAction(context),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppTheme.velocityBorder, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Check-In',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.2,
                            color: AppTheme.velocityTextPrimary,
                          ),
                        ),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppTheme.velocityAmber,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const SegmentedProgressBar(
                      totalSegments: 3,
                      completedSegments: 2,
                      activeColor: AppTheme.velocityAmber,
                      hasStripedCurrent: false,
                      height: 14,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      '2/3 Check-In Done',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.velocityTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 2. Interactive Line-Up Pills
  // ---------------------------------------------------------------------------
  Widget _buildLineUpPills(BuildContext context) {
    if (_lineupItems.isEmpty) {
      return Center(
        child: TextButton.icon(
          onPressed: () {
            setState(() {
              _lineupItems.add({
                'id': DateTime.now().toString(),
                'title': 'Conditioning: Body Movement',
                'playBg': AppTheme.velocityLime,
                'playIcon': AppTheme.velocityDark,
              });
            });
          },
          icon: const Icon(Icons.add_circle_outline, color: AppTheme.velocityDark),
          label: const Text(
            'Add Workout to Line-Up',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.velocityDark,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        for (final item in _lineupItems) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: WorkoutLineUpPill(
              title: item['title'] as String,
              playButtonColor: item['playBg'] as Color,
              playIconColor: item['playIcon'] as Color,
              onPlay: () => _handlePlayLineUpItem(context, item['title'] as String),
              onRemove: () {
                setState(() {
                  _lineupItems.removeWhere((i) => i['id'] == item['id']);
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppTheme.velocityDark,
                    content: Text(
                      'Removed "${item['title']}" from line-up',
                      style: const TextStyle(color: Colors.white),
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 3. Horizontal Workout Cards Carousel
  // ---------------------------------------------------------------------------
  Widget _buildWorkoutCardsCarousel(BuildContext context) {
    final workouts = [
      VelocityWorkoutCardData(
        id: '1',
        firstLine: 'Ultimate',
        highlightedPhrases: ['Dumbbell', 'Burn and'],
        lastLine: 'Build',
        highlightColor: AppTheme.velocityLime,
        imageAsset: 'assets/images/athlete_dumbbell.jpg',
        bulletPoints: const [
          'Core Velocity',
          'Endurance Build',
        ],
        onStart: () => context.go('/workouts/log'),
      ),
      VelocityWorkoutCardData(
        id: '2',
        firstLine: 'Lower',
        highlightedPhrases: ['Body Power', 'Training'],
        lastLine: 'Routine',
        highlightColor: AppTheme.velocityAmber,
        imageAsset: 'assets/images/lower_body_power.jpg',
        bulletPoints: const [
          'Boost- Up',
          'Flex Focus',
        ],
        onStart: () => context.go('/workouts/log'),
      ),
      VelocityWorkoutCardData(
        id: '3',
        firstLine: 'Explosive',
        highlightedPhrases: ['Velo-Sprint', 'HIIT Power'],
        lastLine: 'Circuit',
        highlightColor: AppTheme.velocityLime,
        imageAsset: 'assets/images/athlete_dumbbell.jpg',
        bulletPoints: const [
          'Metabolic Surge',
          'VO2 Max Peak',
        ],
        onStart: () => context.go('/workouts/log'),
      ),
    ];

    return SizedBox(
      height: 380,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: workouts.length,
        separatorBuilder: (context, index) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          return VelocityWorkoutCard(
            data: workouts[index],
            width: 255,
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 4. Performance Metrics Section
  // ---------------------------------------------------------------------------
  Widget _buildPerformanceMetricsSection(BuildContext context, HomeState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppTheme.velocityBorder, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Performance Metrics',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                    color: AppTheme.velocityTextPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.velocityLimeSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Level ${state.level} Athlete',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF2C3E14),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Metrics Row
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    label: 'Streak',
                    value: '${state.streakDays} Days',
                    icon: Icons.local_fire_department_rounded,
                    iconColor: const Color(0xFFFF5722),
                  ),
                ),
                Container(width: 1, height: 38, color: AppTheme.velocityBorder),
                Expanded(
                  child: _buildMetricTile(
                    label: 'Weekly Vol',
                    value: '${NumberFormat.compact().format(state.weeklyVolume)} kg',
                    icon: Icons.fitness_center_rounded,
                    iconColor: AppTheme.velocityDark,
                  ),
                ),
                Container(width: 1, height: 38, color: AppTheme.velocityBorder),
                Expanded(
                  child: _buildMetricTile(
                    label: 'This Month',
                    value: '${state.workoutsThisMonth} Sessions',
                    icon: Icons.check_circle_rounded,
                    iconColor: const Color(0xFF388E3C),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: AppTheme.velocityTextPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.velocityTextSecondary,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // 5. Recent Achievements
  // ---------------------------------------------------------------------------
  Widget _buildAchievementsSection(BuildContext context, HomeState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Achievements',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.2,
                  color: AppTheme.velocityTextPrimary,
                ),
              ),
              Text(
                '${state.recentAchievements.length} Unlocked',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.velocityTextSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: state.recentAchievements.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final badge = state.recentAchievements[index];
                return Container(
                  width: 200,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.velocityBorder, width: 1.2),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppTheme.velocityLimeSoft,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.emoji_events_rounded,
                            color: Color(0xFF4C6615),
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
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
                            const SizedBox(height: 2),
                            Text(
                              badge.description,
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppTheme.velocityTextSecondary,
                              ),
                              maxLines: 1,
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
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Action Handlers & Modals
  // ---------------------------------------------------------------------------
  void _handlePlayLineUpItem(BuildContext context, String title) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.velocityBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppTheme.velocityLime,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  size: 36,
                  color: AppTheme.velocityDark,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.velocityTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Starting audio guidance and tempo pacing for this session.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.velocityTextSecondary,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/workouts/log');
                },
                child: const Text('Start Now'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCalendarScheduleSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        final now = DateTime.now();
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.velocityBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Weekly Schedule',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.velocityTextPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Today is ${DateFormat('EEEE, MMM d').format(now)}',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.velocityTextSecondary,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.velocitySurfaceMuted,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        color: AppTheme.velocityLime,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.alarm_on_rounded,
                        color: AppTheme.velocityDark,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Session 4 of 4 Scheduled',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.velocityTextPrimary,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Legs & Mobility at 6:00 PM',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.velocityTextSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.velocityBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Velocity Notifications',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.velocityTextPrimary,
                ),
              ),
              const SizedBox(height: 14),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: AppTheme.velocityLime,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    color: AppTheme.velocityDark,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Streak Saved!',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: const Text(
                  'You are on track to complete your weekly program.',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showProgramDetailsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.velocityBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Current Program: Hypertrophy 4-Day',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.velocityTextPrimary,
                ),
              ),
              const SizedBox(height: 12),
              const SegmentedProgressBar(
                totalSegments: 4,
                completedSegments: 3,
                activeColor: AppTheme.velocityLime,
                hasStripedCurrent: true,
                height: 16,
              ),
              const SizedBox(height: 16),
              const Text(
                '3 of 4 required sessions completed this week. Complete 1 more workout to keep your streak intact and earn +150 bonus XP!',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.velocityTextSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/workouts/log');
                },
                child: const Text('Log Workout 4'),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCheckInAction(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        backgroundColor: AppTheme.velocityDark,
        content: Text(
          'Daily Check-in recorded! Streak maintained 🔥',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showUserMenu(
    BuildContext context,
    AuthSessionViewModel authSession,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.velocityBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              CircleAvatar(
                radius: 36,
                backgroundImage: const AssetImage('assets/images/user_avatar.jpg'),
              ),
              const SizedBox(height: 10),
              const Text(
                'Athlete Profile',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.velocityTextPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.person_outline_rounded),
                title: const Text('View Full Profile'),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/profile');
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: Colors.red),
                title: const Text('Log Out', style: TextStyle(color: Colors.red)),
                onTap: () async {
                  Navigator.pop(context);
                  await authSession.logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
