import 'package:flutter/material.dart';

import '../../../config/theme.dart';
import '../../../models/workout_model.dart';
import 'log_empty_exercises_placeholder.dart';
import 'log_exercise_actions_row.dart';
import 'log_exercise_item_card.dart';

class LogExercisesSection extends StatelessWidget {
  final List<WorkoutExerciseModel> exercises;
  final VoidCallback onAddExercise;
  final VoidCallback onOpenBodyMap;
  final void Function(int index) onRemoveExercise;
  final void Function(int index, {int? sets, int? reps, double? weight})
      onUpdateExercise;

  const LogExercisesSection({
    super.key,
    required this.exercises,
    required this.onAddExercise,
    required this.onOpenBodyMap,
    required this.onRemoveExercise,
    required this.onUpdateExercise,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Exercises',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.2,
                color: AppTheme.velocityTextPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.velocitySurface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.velocityBorder),
              ),
              child: Text(
                '${exercises.length} ${exercises.length == 1 ? "Move" : "Moves"}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.velocityTextSecondary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (exercises.isEmpty)
          const LogEmptyExercisesPlaceholder()
        else
          ...List.generate(exercises.length, (index) {
            return LogExerciseItemCard(
              index: index,
              exercise: exercises[index],
              onRemove: () => onRemoveExercise(index),
              onUpdate: ({reps, sets, weight}) =>
                  onUpdateExercise(index, sets: sets, reps: reps, weight: weight),
            );
          }),
        const SizedBox(height: 12),
        LogExerciseActionsRow(
          onAddExercise: onAddExercise,
          onOpenBodyMap: onOpenBodyMap,
        ),
      ],
    );
  }
}
