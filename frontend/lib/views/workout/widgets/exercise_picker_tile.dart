import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../models/exercise_model.dart';
import '../../exercise/widgets/exercise_types.dart';

class ExercisePickerTile extends StatelessWidget {
  final ExerciseModel exercise;
  final VoidCallback onSelected;

  const ExercisePickerTile({
    super.key,
    required this.exercise,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final muscleColor = getMuscleColor(exercise.muscleGroup);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.velocitySurface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.velocityBorder, width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onSelected,
          splashColor: AppTheme.velocityLime.withValues(alpha: 0.14),
          highlightColor: Colors.white.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                // Exercise Thumbnail Image (concept from exercises screen)
                buildExerciseThumbnail(exercise, muscleColor, size: 50),
                const SizedBox(width: 14),

                // Exercise Name & Muscle / Equipment Badges
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        exercise.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          color: AppTheme.velocityTextPrimary,
                          letterSpacing: -0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 5),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          buildExercisePill(exercise.muscleGroup, muscleColor),
                          if (exercise.equipment != null && exercise.equipment!.trim().isNotEmpty)
                            buildExercisePill(
                              exercise.equipment!,
                              const Color(0xFF2979FF),
                            ),
                          if (exercise.category != null && exercise.category!.trim().isNotEmpty)
                            buildExercisePill(
                              exercise.category!,
                              const Color(0xFF00E676),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // High-Contrast Tactile Add Action Button
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppTheme.velocityLime.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppTheme.velocityLime.withValues(alpha: 0.45),
                      width: 1.1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.velocityLime.withValues(alpha: 0.14),
                        blurRadius: 6,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.add_rounded,
                      color: AppTheme.velocityLime,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
