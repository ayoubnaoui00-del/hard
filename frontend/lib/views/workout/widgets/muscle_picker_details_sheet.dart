import 'package:flutter/material.dart';
import '../../../config/theme.dart';
import '../../../models/exercise_model.dart';
import '../../exercise/widgets/exercise_types.dart';
import '../../exercise/widgets/exercise_video_banner.dart';
import 'body_map_models.dart';

class MusclePickerDetailsSheet extends StatelessWidget {
  final ExerciseModel exercise;
  final MuscleGroupType selectedMuscle;
  final ValueChanged<ExerciseModel> onChooseExercise;
  final ValueChanged<String>? onSelectVariation;

  const MusclePickerDetailsSheet({
    super.key,
    required this.exercise,
    required this.selectedMuscle,
    required this.onChooseExercise,
    this.onSelectVariation,
  });

  static void show(
    BuildContext context, {
    required ExerciseModel exercise,
    required MuscleGroupType selectedMuscle,
    required ValueChanged<ExerciseModel> onChooseExercise,
    ValueChanged<String>? onSelectVariation,
  }) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => MusclePickerDetailsSheet(
        exercise: exercise,
        selectedMuscle: selectedMuscle,
        onChooseExercise: onChooseExercise,
        onSelectVariation: onSelectVariation,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final muscleColor = selectedMuscle.color;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.velocitySurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
              const SizedBox(height: 16),

              if (exercise.videoUrl != null || exercise.gifUrl != null) ...[
                ExerciseVideoBanner(exercise: exercise),
                const SizedBox(height: 18),
              ],

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
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.velocityTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            buildExercisePill(exercise.muscleGroup, muscleColor),
                            if (exercise.equipment != null)
                              buildExercisePill(exercise.equipment!, const Color(0xFF2979FF)),
                            if (exercise.category != null)
                              buildExercisePill(exercise.category!, const Color(0xFF00E676)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),
              const Divider(color: AppTheme.velocityBorder),
              const SizedBox(height: 12),

              if (exercise.instructions != null && exercise.instructions!.isNotEmpty) ...[
                const Text(
                  'Instructions',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.velocityTextPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  exercise.instructions!,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AppTheme.velocityTextSecondary,
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (exercise.formTips != null && exercise.formTips!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFB300).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFFFB300).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.lightbulb_rounded,
                        color: Color(0xFFFF8F00),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Form Tip & Coaching Cue',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFE65100),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              exercise.formTips!,
                              style: const TextStyle(
                                fontSize: 12,
                                height: 1.4,
                                color: Color(0xFFBF360C),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              if (exercise.alternativeNames.isNotEmpty) ...[
                const Text(
                  'Alternative Variations',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.velocityTextPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: exercise.alternativeNames.map((alt) {
                    return InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                        onSelectVariation?.call(alt);
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.velocitySurfaceMuted,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.velocityBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.swap_horiz_rounded, size: 14, color: AppTheme.velocityTextSecondary),
                            const SizedBox(width: 4),
                            Text(
                              alt,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.velocityTextPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],

              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onChooseExercise(exercise);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.velocityLime,
                  foregroundColor: AppTheme.velocityDark,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.play_arrow_rounded, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Select This Exercise',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
