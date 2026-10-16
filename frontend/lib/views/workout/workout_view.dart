import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../viewmodels/workout/workout_viewmodel.dart';
import '../../widgets/gradient_background.dart';

class WorkoutView extends ConsumerStatefulWidget {
  const WorkoutView({super.key});

  @override
  ConsumerState<WorkoutView> createState() => _WorkoutViewState();
}

class _WorkoutViewState extends ConsumerState<WorkoutView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(workoutViewModelProvider.notifier).fetchWorkouts();
    });
  }

  @override
  Widget build(BuildContext context) {
    final workoutState = ref.watch(workoutViewModelProvider);
    final workoutViewModel = ref.read(workoutViewModelProvider.notifier);
    final workouts = workoutState.workouts;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('Workouts'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Log Workout',
            onPressed: () => context.go('/workouts/log'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.go('/workouts/log'),
        backgroundColor: AppTheme.velocityLime,
        foregroundColor: AppTheme.velocityDark,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Log Workout',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => workoutViewModel.fetchWorkouts(),
        child: workoutState.isLoading && workouts.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : workouts.isEmpty
                ? ListView(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.65,
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 36,
                                  backgroundColor:
                                      AppTheme.velocityLime.withValues(alpha: 0.15),
                                  child: const Icon(
                                    Icons.fitness_center_rounded,
                                    size: 36,
                                    color: AppTheme.velocityLime,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No workouts logged yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.velocityTextPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Start tracking your sets, reps, and volume to level up your strength!',
                                  style: TextStyle(
                                    color: AppTheme.velocityTextSecondary,
                                    fontSize: 13,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: () => context.go('/workouts/log'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.velocityLime,
                                    foregroundColor: AppTheme.velocityDark,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  icon: const Icon(Icons.play_arrow_rounded),
                                  label: const Text(
                                    'Start Empty Workout',
                                    style: TextStyle(fontWeight: FontWeight.w900),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                    itemCount: workouts.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final workout = workouts[index];
                      final dateStr = DateFormat('MMM d, yyyy • h:mm a')
                          .format(workout.date);

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor:
                                        AppTheme.velocityLime.withValues(alpha: 0.15),
                                    child: const Icon(
                                      Icons.fitness_center_rounded,
                                      color: AppTheme.velocityLime,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          workout.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w900,
                                            color: AppTheme.velocityTextPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          dateStr,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.velocityTextSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.velocitySurfaceMuted,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppTheme.velocityBorder),
                                    ),
                                    child: Text(
                                      '${workout.duration}m',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.velocityAccentBlue,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${workout.workoutExercises.length} ${workout.workoutExercises.length == 1 ? "Exercise" : "Exercises"} • ${workout.totalSets} Sets',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.velocityTextSecondary,
                                    ),
                                  ),
                                  Text(
                                    '${NumberFormat('#,##0').format(workout.totalVolume)} kg',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      color: AppTheme.velocityLime,
                                    ),
                                  ),
                                ],
                              ),
                              if (workout.notes != null &&
                                  workout.notes!.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  workout.notes!,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.velocityTextMuted,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    ),
  );
}
}
