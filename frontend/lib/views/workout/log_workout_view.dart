import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../models/exercise_model.dart';
import '../../models/workout_model.dart';
import '../../repositories/exercise_repository.dart';
import '../../viewmodels/home/home_viewmodel.dart';
import '../../viewmodels/workout/workout_viewmodel.dart';

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

  // Local list of editable workout exercises
  final List<WorkoutExerciseModel> _exercises = [];

  final List<int> _suggestedDurations = [30, 45, 60, 90];

  @override
  void initState() {
    super.initState();
    // Default initial exercise for immediate convenience
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
      setState(() {
        _selectedDate = picked;
      });
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
    setState(() {
      _exercises.removeAt(index);
    });
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
      setState(() {
        _validationError = 'At least 1 exercise is required.';
      });
      return false;
    }

    final duration = int.tryParse(_durationController.text.trim()) ?? 0;
    if (duration <= 0) {
      setState(() {
        _validationError = 'Duration must be greater than 0 minutes.';
      });
      return false;
    }

    for (int i = 0; i < _exercises.length; i++) {
      final ex = _exercises[i];
      final name = ex.exerciseName ?? 'Exercise ${i + 1}';

      if (ex.sets <= 0 || ex.sets > 10) {
        setState(() {
          _validationError = '$name: Sets must be between 1 and 10.';
        });
        return false;
      }

      if (ex.reps <= 0 || ex.reps > 50) {
        setState(() {
          _validationError = '$name: Reps must be between 1 and 50.';
        });
        return false;
      }

      if (ex.weight < 0) {
        setState(() {
          _validationError = '$name: Weight must be 0 or positive.';
        });
        return false;
      }
    }

    setState(() {
      _validationError = null;
    });
    return true;
  }

  Future<void> _submitWorkout() async {
    if (!_validateWorkout()) return;

    final name = _nameController.text.trim().isNotEmpty
        ? _nameController.text.trim()
        : 'Workout Session';
    final duration = int.tryParse(_durationController.text.trim()) ?? _selectedDuration;
    final notes = _notesController.text.trim().isNotEmpty
        ? _notesController.text.trim()
        : null;

    final created = await ref.read(workoutViewModelProvider.notifier).createWorkout(
          name: name,
          date: _selectedDate,
          duration: duration,
          notes: notes,
          exercises: _exercises,
        );

    if (created != null && mounted) {
      // Invalidate home dashboard to refresh stats with new workout
      ref.read(homeViewModelProvider.notifier).refresh();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded, color: Color(0xFF00E676)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Workout logged! +${100 + (_exercises.fold(0, (sum, ex) => sum + (ex.sets * ex.reps)) * 10)} XP earned! 🔥',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF1E1E24),
          duration: const Duration(seconds: 3),
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E24),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return _ExercisePickerSheet(onSelected: (exercise) {
          Navigator.pop(context);
          _addExercise(exercise);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final workoutState = ref.watch(workoutViewModelProvider);
    final isSubmitting = workoutState.isSubmitting;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Workout'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            final router = GoRouter.maybeOf(context);
            if (router != null && router.canPop()) {
              router.pop();
            } else if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else if (router != null) {
              router.go('/home');
            }
          },
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Error banner if validation failed
            if (_validationError != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5252).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFF5252)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded,
                        color: Color(0xFFFF5252), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _validationError!,
                        style: const TextStyle(
                          color: Color(0xFFFF5252),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Workout Name Input
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Workout Title',
                prefixIcon: Icon(Icons.edit_note_rounded),
                hintText: 'e.g. Push Day, Morning Cardio',
              ),
            ),
            const SizedBox(height: 16),

            // 1. Date/Time Picker Section
            _buildDatePickerCard(),
            const SizedBox(height: 16),

            // 2. Duration Input Section (Suggested 30, 45, 60, 90 + input)
            _buildDurationCard(),
            const SizedBox(height: 20),

            // 3. Dynamic Exercise List Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Exercises',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF282832),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_exercises.length} ${_exercises.length == 1 ? "Move" : "Moves"}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Exercise items
            if (_exercises.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E24),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF33333F)),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.fitness_center_outlined,
                      size: 40,
                      color: Colors.grey.shade600,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'No exercises added yet',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap "+ Add Exercise" below to pick your first exercise.',
                      style:
                          TextStyle(color: Colors.grey.shade400, fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ...List.generate(_exercises.length, (index) {
                return _buildExerciseCard(index, _exercises[index]);
              }),

            const SizedBox(height: 12),

            // 4. "Add Exercise" Button
            OutlinedButton.icon(
              onPressed: _openExercisePicker,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFFF5252),
                side: const BorderSide(color: Color(0xFFFF5252), width: 1.5),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'Add Exercise',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
            const SizedBox(height: 20),

            // 5. Notes Field
            const Text(
              'Session Notes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Add workout notes (e.g., energy levels, PR attempts)...',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 40),
                  child: Icon(Icons.notes_rounded),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Volume & Sets Summary bar
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E24),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF33333F)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      Text(
                        '$_totalSets',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text('Total Sets',
                          style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                  Container(width: 1, height: 32, color: const Color(0xFF33333F)),
                  Column(
                    children: [
                      Text(
                        '${NumberFormat('#,##0').format(_totalVolume)} kg',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00E676),
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text('Total Volume',
                          style: TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 6. "Log Workout" Submit Button
            ElevatedButton(
              onPressed: isSubmitting ? null : _submitWorkout,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF5252),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
              ),
              child: isSubmitting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_rounded, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Log Workout',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Date Picker Card
  // ---------------------------------------------------------------------------
  Widget _buildDatePickerCard() {
    final formattedDate =
        DateFormat('EEEE, MMM d, yyyy').format(_selectedDate);

    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E24),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF33333F)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFF5252).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.calendar_today_rounded,
                color: Color(0xFFFF5252),
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Workout Date',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_drop_down_rounded, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Duration Card
  // ---------------------------------------------------------------------------
  Widget _buildDurationCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E24),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF33333F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timer_outlined, color: Color(0xFF2979FF), size: 18),
              const SizedBox(width: 8),
              const Text(
                'Duration (Minutes)',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              SizedBox(
                width: 70,
                child: TextFormField(
                  controller: _durationController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                  decoration: const InputDecoration(
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    isDense: true,
                  ),
                  onChanged: (val) {
                    final intVal = int.tryParse(val);
                    if (intVal != null) {
                      setState(() {
                        _selectedDuration = intVal;
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Suggested duration buttons: 30, 45, 60, 90
          Row(
            children: _suggestedDurations.map((mins) {
              final isSelected = _selectedDuration == mins;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: InkWell(
                    onTap: () => _selectDuration(mins),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF2979FF)
                            : const Color(0xFF282832),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF2979FF)
                              : const Color(0xFF33333F),
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${mins}m',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Exercise Card Component
  // ---------------------------------------------------------------------------
  Widget _buildExerciseCard(int index, WorkoutExerciseModel ex) {
    final subVolume = ex.sets * ex.reps * ex.weight;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF33333F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Name, Muscle Badge, Delete
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: const Color(0xFFFF5252).withValues(alpha: 0.15),
                child: const Icon(
                  Icons.fitness_center_rounded,
                  color: Color(0xFFFF5252),
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ex.exerciseName ?? 'Exercise ${index + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (ex.muscleGroup != null)
                      Text(
                        ex.muscleGroup!,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded,
                    color: Color(0xFFFF5252), size: 20),
                tooltip: 'Remove',
                onPressed: () => _removeExercise(index),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Color(0xFF33333F)),
          const SizedBox(height: 12),

          // Sets, Reps, Weight Steppers Row
          Row(
            children: [
              // Sets Stepper (1 - 10)
              Expanded(
                child: _buildMetricStepper(
                  label: 'Sets',
                  value: ex.sets,
                  min: 1,
                  max: 10,
                  onChanged: (newVal) => _updateExercise(index, sets: newVal),
                ),
              ),
              const SizedBox(width: 8),
              // Reps Stepper (1 - 50)
              Expanded(
                child: _buildMetricStepper(
                  label: 'Reps',
                  value: ex.reps,
                  min: 1,
                  max: 50,
                  onChanged: (newVal) => _updateExercise(index, reps: newVal),
                ),
              ),
              const SizedBox(width: 8),
              // Weight Input (>= 0)
              Expanded(
                child: _buildWeightInput(
                  value: ex.weight,
                  onChanged: (newVal) => _updateExercise(index, weight: newVal),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Volume Subtotal for this exercise
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Volume: ${NumberFormat('#,##0').format(subVolume)} kg',
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF00E676),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricStepper({
    required String label,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF282832),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: value > min ? () => onChanged(value - 1) : null,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.remove_rounded,
                    size: 16,
                    color: value > min ? Colors.white : Colors.grey.shade700,
                  ),
                ),
              ),
              Text(
                '$value',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              InkWell(
                onTap: value < max ? () => onChanged(value + 1) : null,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.add_rounded,
                    size: 16,
                    color: value < max ? Colors.white : Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeightInput({
    required double value,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF282832),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          const Text('Weight (kg)',
              style: TextStyle(fontSize: 10, color: Colors.grey)),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: value >= 2.5
                    ? () => onChanged((value - 2.5).clamp(0.0, 999.0))
                    : null,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    Icons.remove_rounded,
                    size: 16,
                    color: value > 0 ? Colors.white : Colors.grey.shade700,
                  ),
                ),
              ),
              Text(
                value % 1 == 0 ? '${value.toInt()}' : value.toStringAsFixed(1),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              InkWell(
                onTap: () => onChanged((value + 2.5).clamp(0.0, 999.0)),
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(
                    Icons.add_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// -----------------------------------------------------------------------------
// Exercise Picker Bottom Sheet Modal
// -----------------------------------------------------------------------------
class _ExercisePickerSheet extends ConsumerStatefulWidget {
  final ValueChanged<ExerciseModel> onSelected;

  const _ExercisePickerSheet({required this.onSelected});

  @override
  ConsumerState<_ExercisePickerSheet> createState() =>
      _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends ConsumerState<_ExercisePickerSheet> {
  final _searchController = TextEditingController();
  String _selectedMuscle = 'All';

  final List<String> _muscles = [
    'All',
    'Chest',
    'Back',
    'Legs',
    'Shoulders',
    'Arms',
    'Core',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(
      exercisesListProvider(
        _selectedMuscle == 'All' ? null : _selectedMuscle,
      ),
    );

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade700,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Choose Exercise',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Search Bar
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Search by exercise name...',
                  prefixIcon: Icon(Icons.search_rounded),
                  isDense: true,
                ),
                onChanged: (val) => setState(() {}),
              ),
              const SizedBox(height: 10),

              // Muscle Filter Chips
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _muscles.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final muscle = _muscles[index];
                    final isSelected = _selectedMuscle == muscle;
                    return ChoiceChip(
                      label: Text(muscle),
                      selected: isSelected,
                      selectedColor: const Color(0xFFFF5252),
                      backgroundColor: const Color(0xFF282832),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey.shade400,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      onSelected: (selected) {
                        if (selected) {
                          setState(() {
                            _selectedMuscle = muscle;
                          });
                        }
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),

              // Exercises List
              Expanded(
                child: exercisesAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, stackTrace) => _buildFallbackList(scrollController),
                  data: (exercises) {
                    final query = _searchController.text.trim().toLowerCase();
                    final filtered = exercises.where((e) {
                      final matchesSearch = query.isEmpty ||
                          e.name.toLowerCase().contains(query) ||
                          e.muscleGroup.toLowerCase().contains(query);
                      return matchesSearch;
                    }).toList();

                    if (filtered.isEmpty) {
                      return Center(
                        child: Text(
                          'No exercises found for "$query"',
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                      );
                    }

                    return ListView.separated(
                      controller: scrollController,
                      itemCount: filtered.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final ex = filtered[index];
                        return Card(
                          margin: EdgeInsets.zero,
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF282832),
                              child: const Icon(
                                Icons.fitness_center_rounded,
                                color: Color(0xFFFF5252),
                                size: 18,
                              ),
                            ),
                            title: Text(
                              ex.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              '${ex.muscleGroup} ${ex.equipment != null ? "• ${ex.equipment}" : ""}',
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12),
                            ),
                            trailing: const Icon(Icons.add_circle_outline_rounded,
                                color: Color(0xFF00E676)),
                            onTap: () => widget.onSelected(ex),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFallbackList(ScrollController scrollController) {
    final list = ExerciseModel.defaultExercises;
    return ListView.separated(
      controller: scrollController,
      itemCount: list.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final ex = list[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.fitness_center_rounded,
                color: Color(0xFFFF5252)),
            title: Text(ex.name,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(ex.muscleGroup,
                style: const TextStyle(color: Colors.grey, fontSize: 12)),
            trailing: const Icon(Icons.add_circle_outline_rounded,
                color: Color(0xFF00E676)),
            onTap: () => widget.onSelected(ex),
          ),
        );
      },
    );
  }
}
