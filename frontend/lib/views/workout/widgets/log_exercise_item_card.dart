import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../config/theme.dart';
import '../../../models/workout_model.dart';
import 'metric_steppers.dart';

class LogExerciseItemCard extends StatelessWidget {
  final int index;
  final WorkoutExerciseModel exercise;
  final VoidCallback onRemove;
  final Function({int? sets, int? reps, double? weight}) onUpdate;

  const LogExerciseItemCard({
    super.key,
    required this.index,
    required this.exercise,
    required this.onRemove,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final subVolume = exercise.sets * exercise.reps * exercise.weight;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.velocitySurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.velocityBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Name, Muscle Badge, Delete
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppTheme.velocityLime.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(12),
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
                      exercise.exerciseName ?? 'Exercise ${index + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                        color: AppTheme.velocityTextPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (exercise.muscleGroup != null)
                      Text(
                        exercise.muscleGroup!,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.velocityTextSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFE53935), size: 20),
                tooltip: 'Remove',
                onPressed: onRemove,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppTheme.velocityBorder),
          const SizedBox(height: 12),

          // Sets, Reps, Weight Steppers Row
          Row(
            children: [
              Expanded(
                child: MetricStepper(
                  label: 'Sets',
                  value: exercise.sets,
                  min: 1,
                  max: 10,
                  onChanged: (newVal) => onUpdate(sets: newVal),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: MetricStepper(
                  label: 'Reps',
                  value: exercise.reps,
                  min: 1,
                  max: 50,
                  onChanged: (newVal) => onUpdate(reps: newVal),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: WeightInputStepper(
                  value: exercise.weight,
                  onChanged: (newVal) => onUpdate(weight: newVal),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Volume Subtotal for this exercise
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.velocitySurfaceMuted,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Volume: ${NumberFormat('#,##0').format(subVolume)} kg',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.velocityDark,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
