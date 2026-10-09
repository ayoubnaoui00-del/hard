import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../models/exercise_model.dart';

class MuscleOption {
  final String name;
  final IconData icon;
  final Color color;
  const MuscleOption(this.name, this.icon, this.color);
}

const List<MuscleOption> kMuscleOptions = [
  MuscleOption('All', Icons.all_inclusive_rounded, AppTheme.velocityDark),
  MuscleOption('Chest', Icons.fitness_center_rounded, Color(0xFFFF5252)),
  MuscleOption('Back', Icons.shield_outlined, Color(0xFF2979FF)),
  MuscleOption('Shoulders', Icons.hardware_rounded, Color(0xFFFF9100)),
  MuscleOption('Arms', Icons.sports_martial_arts_rounded, Color(0xFFB388FF)),
  MuscleOption('Legs', Icons.directions_run_rounded, Color(0xFF00E676)),
  MuscleOption('Core', Icons.adjust_rounded, Color(0xFF00E5FF)),
];

const List<String> kEquipmentOptions = [
  'All',
  'Barbell',
  'Dumbbell',
  'Machine',
  'Cable',
  'Bodyweight',
];

const List<String> kCategoryOptions = [
  'All',
  'Strength',
  'Hypertrophy',
  'Endurance',
  'Mobility',
];

Color getMuscleColor(String muscle) {
  switch (muscle.toLowerCase()) {
    case 'chest':
      return const Color(0xFFFF5252);
    case 'back':
      return const Color(0xFF2979FF);
    case 'shoulders':
      return const Color(0xFFFF9100);
    case 'arms':
      return const Color(0xFFB388FF);
    case 'legs':
      return const Color(0xFF00E676);
    case 'core':
      return const Color(0xFF00E5FF);
    default:
      return AppTheme.velocityDark;
  }
}

IconData getMuscleIcon(String muscle) {
  switch (muscle.toLowerCase()) {
    case 'chest':
      return Icons.fitness_center_rounded;
    case 'back':
      return Icons.shield_outlined;
    case 'shoulders':
      return Icons.hardware_rounded;
    case 'arms':
      return Icons.sports_martial_arts_rounded;
    case 'legs':
      return Icons.directions_run_rounded;
    case 'core':
      return Icons.adjust_rounded;
    default:
      return Icons.fitness_center_rounded;
  }
}

Widget buildExercisePill(String text, Color color) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    ),
  );
}

Widget buildExerciseThumbnail(ExerciseModel exercise, Color muscleColor, {double size = 48}) {
  final videoUrl = exercise.videoUrl ?? exercise.gifUrl;
  if (videoUrl != null && videoUrl.isNotEmpty) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: muscleColor.withValues(alpha: 0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12.5),
        child: Image.network(
          videoUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Center(
              child: CircleAvatar(
                radius: size * 0.42,
                backgroundColor: muscleColor.withValues(alpha: 0.15),
                child: Icon(
                  getMuscleIcon(exercise.muscleGroup),
                  color: muscleColor,
                  size: size * 0.45,
                ),
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(muscleColor),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  return CircleAvatar(
    radius: size / 2,
    backgroundColor: muscleColor.withValues(alpha: 0.15),
    child: Icon(
      getMuscleIcon(exercise.muscleGroup),
      color: muscleColor,
      size: size * 0.45,
    ),
  );
}

Widget buildVisualPreviewFallback(ExerciseModel exercise, Color muscleColor) {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: muscleColor.withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            getMuscleIcon(exercise.muscleGroup),
            size: 38,
            color: muscleColor,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          exercise.name,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          '${exercise.muscleGroup} • ${exercise.equipment ?? "Exercise"}',
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white54,
          ),
        ),
      ],
    ),
  );
}
