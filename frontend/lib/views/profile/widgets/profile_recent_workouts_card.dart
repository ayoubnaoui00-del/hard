import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../config/theme.dart';
import '../../../models/workout_model.dart';

class ProfileRecentWorkoutsCard extends StatelessWidget {
  final List<WorkoutModel> recentWorkouts;

  const ProfileRecentWorkoutsCard({
    super.key,
    required this.recentWorkouts,
  });

  static final DateFormat _dateFormat = DateFormat('MMM d, yyyy • h:mm a');
  static final NumberFormat _numberFormat = NumberFormat('#,###');

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.velocitySurface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.velocityBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'RECENT WORKOUTS (LAST 5)',
            style: TextStyle(
              color: AppTheme.velocityTextSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 12),
          if (recentWorkouts.isEmpty)
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
              itemCount: recentWorkouts.length,
              separatorBuilder: (context, index) =>
                  const Divider(color: AppTheme.velocityBorder, height: 16),
              itemBuilder: (context, index) {
                final w = recentWorkouts[index];
                final exerciseSummary =
                    w.exercises.map((e) => e.exerciseName).take(2).join(', ');
                final extra = w.exercises.length > 2
                    ? ' +${w.exercises.length - 2} more'
                    : '';

                return Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.velocityLime.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.fitness_center_rounded,
                        color: AppTheme.velocityLime,
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
                              color: AppTheme.velocityTextPrimary,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            exerciseSummary.isNotEmpty
                                ? '$exerciseSummary$extra'
                                : 'Workout Session',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: AppTheme.velocityTextSecondary, fontSize: 12),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _dateFormat.format(w.date),
                            style: const TextStyle(
                                color: AppTheme.velocityTextMuted, fontSize: 10),
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
                            color: AppTheme.velocityLime,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                          ),
                        ),
                        if (w.duration > 0)
                          Text(
                            '${w.duration} min',
                            style: const TextStyle(
                                color: AppTheme.velocityTextMuted, fontSize: 11),
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
}
