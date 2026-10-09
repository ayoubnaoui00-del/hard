import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../models/exercise_model.dart';
import '../../models/workout_model.dart';
import '../../viewmodels/home/home_viewmodel.dart';
import '../../viewmodels/workout/workout_viewmodel.dart';
import '../../widgets/gradient_background.dart';
import 'muscle_picker_view.dart';
import 'widgets/exercise_picker_sheet.dart';
import 'widgets/log_date_duration_pickers.dart';
import 'widgets/log_exercises_section.dart';
import 'widgets/log_workout_submit_button.dart';
import 'widgets/log_workout_summary_bar.dart';
import 'widgets/log_workout_text_fields.dart';

class LogWorkoutView extends ConsumerStatefulWidget {
  const LogWorkoutView({super.key});

  @override
  ConsumerState<LogWorkoutView> createState() => _LogWorkoutViewState();
}

class _LogWorkoutViewState extends ConsumerState<LogWorkoutView> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Workout Session');
  final _durationController = TextEditingController(text: '45');
  final _notesController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  int _selectedDuration = 45;
  String? _validationError;

  final List<WorkoutExerciseModel> _exercises = [];
  final List<int> _suggestedDurations = const [30, 45, 60, 90];

  @override
  void initState() {
    super.initState();
    _exercises.add(
      const WorkoutExerciseModel(
        exerciseId: 'bench-press-001',
        exerciseName: 'Barbell Bench Press',
        muscleGroup: 'Chest',
        sets: 3,
        reps: 10,
        weight: 60.0,
        order: 1,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _totalVolume =>
      _exercises.fold(0.0, (sum, ex) => sum + (ex.sets * ex.reps * ex.weight));

  int get _totalSets => _exercises.fold(0, (sum, ex) => sum + ex.sets);

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 1),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _selectDuration(int minutes) {
    setState(() {
      _selectedDuration = minutes;
      _durationController.text = minutes.toString();
    });
  }

  void _addExercise(ExerciseModel exercise) {
    setState(() {
      _exercises.add(
        WorkoutExerciseModel(
          exerciseId: exercise.id,
          exerciseName: exercise.name,
          muscleGroup: exercise.muscleGroup,
          sets: 3,
          reps: 10,
          weight: 20.0,
          order: _exercises.length + 1,
        ),
      );
      _validationError = null;
    });
  }

  void _removeExercise(int index) {
    setState(() => _exercises.removeAt(index));
  }

  void _updateExercise(int index, {int? sets, int? reps, double? weight}) {
    setState(() {
      final current = _exercises[index];
      _exercises[index] = current.copyWith(
        sets: sets ?? current.sets,
        reps: reps ?? current.reps,
        weight: weight ?? current.weight,
      );
    });
  }

  bool _validateWorkout() {
    if (_exercises.isEmpty) {
      setState(() => _validationError = 'At least 1 exercise is required.');
      return false;
    }
    final duration = int.tryParse(_durationController.text.trim()) ?? 0;
    if (duration <= 0) {
      setState(() => _validationError = 'Duration must be greater than 0 minutes.');
      return false;
    }
    for (int i = 0; i < _exercises.length; i++) {
      final ex = _exercises[i];
      final name = ex.exerciseName ?? 'Exercise ${i + 1}';
      if (ex.sets <= 0 || ex.sets > 10) {
        setState(() => _validationError = '$name: Sets must be between 1 and 10.');
        return false;
      }
      if (ex.reps <= 0 || ex.reps > 50) {
        setState(() => _validationError = '$name: Reps must be between 1 and 50.');
        return false;
      }
      if (ex.weight < 0) {
        setState(() => _validationError = '$name: Weight cannot be negative.');
        return false;
      }
    }
    setState(() => _validationError = null);
    return true;
  }

  Future<void> _submitWorkout() async {
    if (!_validateWorkout()) return;
    final name = _nameController.text.trim().isEmpty ? 'Workout Session' : _nameController.text.trim();
    final duration = int.tryParse(_durationController.text.trim()) ?? 45;
    final notes = _notesController.text.trim().isEmpty ? null : _notesController.text.trim();

    final created = await ref.read(workoutViewModelProvider.notifier).createWorkout(
          name: name,
          date: _selectedDate,
          duration: duration,
          exercises: _exercises,
          notes: notes,
        );
    final success = created != null;

    if (success && mounted) {
      ref.invalidate(homeViewModelProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppTheme.velocityLime),
              SizedBox(width: 10),
              Text('Workout logged successfully! 🎉', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          backgroundColor: AppTheme.velocityDarkSurface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      final router = GoRouter.maybeOf(context);
      if (router != null && router.canPop()) {
        router.pop();
      } else if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else if (router != null) {
        router.go('/workouts');
      }
    }
  }

  void _openExercisePicker() {
    ExercisePickerSheet.show(
      context,
      onSelected: (exercise) {
        Navigator.pop(context);
        _addExercise(exercise);
      },
      onOpenBodyMap: () {
        Navigator.pop(context);
        _openBodyMapPicker();
      },
    );
  }

  Future<void> _openBodyMapPicker() async {
    final selected = await Navigator.of(context).push<ExerciseModel>(
      MaterialPageRoute(builder: (context) => const MusclePickerView()),
    );
    if (selected != null && mounted) {
      _addExercise(selected);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: AppTheme.velocityLime),
              const SizedBox(width: 8),
              Text('Added ${selected.name} from Body Map! 💪', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
          backgroundColor: AppTheme.velocityDarkSurface,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final workoutState = ref.watch(workoutViewModelProvider);
    final isSubmitting = workoutState.isSubmitting;

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Log Workout',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.3, color: AppTheme.velocityTextPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.velocityTextPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            LogValidationErrorBanner(error: _validationError),
            WorkoutTitleField(controller: _nameController),
            const SizedBox(height: 16),
            LogDateDurationPickers(
              selectedDate: _selectedDate,
              onPickDate: _pickDate,
              durationController: _durationController,
              selectedDuration: _selectedDuration,
              suggestedDurations: _suggestedDurations,
              onSelectDuration: _selectDuration,
            ),
            const SizedBox(height: 20),
            LogExercisesSection(
              exercises: _exercises,
              onAddExercise: _openExercisePicker,
              onOpenBodyMap: _openBodyMapPicker,
              onRemoveExercise: _removeExercise,
              onUpdateExercise: (index, {reps, sets, weight}) =>
                  _updateExercise(index, sets: sets, reps: reps, weight: weight),
            ),
            const SizedBox(height: 20),
            WorkoutNotesField(controller: _notesController),
            const SizedBox(height: 24),
            LogWorkoutSummaryBar(totalSets: _totalSets, totalVolume: _totalVolume),
            const SizedBox(height: 20),
            LogWorkoutSubmitButton(
              isSubmitting: isSubmitting,
              onSubmit: _submitWorkout,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    ),
  );
  }
}
