import 'package:flutter/material.dart';
import '../../models/exercise_model.dart';
import '../../views/workout/muscle_picker_view.dart';

/// Screen alias exporting MusclePickerView for Task 5.7 (HRD-32)
class MusclePickerScreen extends StatelessWidget {
  final MuscleGroupType initialMuscle;
  final ValueChanged<ExerciseModel>? onExerciseSelected;

  const MusclePickerScreen({
    super.key,
    this.initialMuscle = MuscleGroupType.chest,
    this.onExerciseSelected,
  });

  @override
  Widget build(BuildContext context) {
    return MusclePickerView(
      initialMuscle: initialMuscle,
      onExerciseSelected: onExerciseSelected,
    );
  }
}
