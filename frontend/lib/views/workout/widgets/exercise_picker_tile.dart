import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../models/exercise_model.dart';

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
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.velocitySurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.velocityBorder),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.velocityLime.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.fitness_center_rounded, color: AppTheme.velocityDark, size: 18),
        ),
        title: Text(
          exercise.name,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: AppTheme.velocityTextPrimary,
          ),
        ),
        subtitle: Text(
          '${exercise.muscleGroup} ${exercise.equipment != null ? "• ${exercise.equipment}" : ""}',
          style: const TextStyle(color: AppTheme.velocityTextSecondary, fontSize: 12),
        ),
        trailing: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: AppTheme.velocitySurfaceMuted,
            shape: BoxShape.circle,
            border: Border.all(color: AppTheme.velocityBorder),
          ),
          child: const Icon(Icons.add_rounded, color: AppTheme.velocityDark, size: 18),
        ),
        onTap: onSelected,
      ),
    );
  }
}
