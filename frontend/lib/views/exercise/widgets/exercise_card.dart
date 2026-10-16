import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/theme.dart';
import '../../../models/exercise_model.dart';
import 'exercise_types.dart';

class ExerciseCard extends StatelessWidget {
  final ExerciseModel exercise;
  final VoidCallback onTapDetails;

  const ExerciseCard({
    super.key,
    required this.exercise,
    required this.onTapDetails,
  });

  @override
  Widget build(BuildContext context) {
    final muscleColor = getMuscleColor(exercise.muscleGroup);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTapDetails,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Media Thumbnail + Title + Badges
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildExerciseThumbnail(exercise, muscleColor, size: 52),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exercise.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.velocityTextPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              buildExercisePill(exercise.muscleGroup, muscleColor),
                              if (exercise.equipment != null)
                                buildExercisePill(
                                  exercise.equipment!,
                                  const Color(0xFF2979FF),
                                ),
                              if (exercise.category != null)
                                buildExercisePill(
                                  exercise.category!,
                                  const Color(0xFF00E676),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppTheme.velocityTextMuted,
                      size: 20,
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Card Bottom Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Details Action Button
                    OutlinedButton(
                      onPressed: onTapDetails,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.velocityTextPrimary,
                        side: const BorderSide(color: AppTheme.velocityBorder, width: 1.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7.5,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'View Details',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    // Log Exercise Action Button (Compact Neon Badge)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => context.push('/workouts/log'),
                        borderRadius: BorderRadius.circular(10),
                        child: Ink(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7.5,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                AppTheme.velocityLimeBright,
                                AppTheme.velocityLime,
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.velocityLime.withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.add_rounded,
                                size: 15,
                                color: AppTheme.velocityDark,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Log Workout',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.velocityDark,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
