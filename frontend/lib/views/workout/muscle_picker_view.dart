import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../models/exercise_model.dart';
import '../../repositories/exercise_repository.dart';
import '../../widgets/gradient_background.dart';
import 'widgets/body_map_console.dart';
import 'widgets/body_map_models.dart';
import 'widgets/muscle_group_chips.dart';
import 'widgets/muscle_picker_details_sheet.dart';
import 'widgets/muscle_picker_exercise_card.dart';

export 'widgets/body_map_models.dart';
export 'widgets/body_map_painter.dart';

class MusclePickerView extends ConsumerStatefulWidget {
  final MuscleGroupType initialMuscle;
  final ValueChanged<ExerciseModel>? onExerciseSelected;
  final bool isEmbedded;

  const MusclePickerView({
    super.key,
    this.initialMuscle = MuscleGroupType.chest,
    this.onExerciseSelected,
    this.isEmbedded = false,
  });

  @override
  ConsumerState<MusclePickerView> createState() => _MusclePickerViewState();
}

class _MusclePickerViewState extends ConsumerState<MusclePickerView> {
  late MuscleGroupType _selectedMuscle;
  bool _isFrontView = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedMuscle = widget.initialMuscle;
    _isFrontView = _selectedMuscle.isFront;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _selectMuscle(MuscleGroupType muscle) {
    setState(() {
      _selectedMuscle = muscle;
      if (muscle == MuscleGroupType.back && _isFrontView) {
        _isFrontView = false;
      } else if (muscle != MuscleGroupType.back && !_isFrontView && muscle != MuscleGroupType.legs) {
        _isFrontView = true;
      }
    });
  }

  void _toggleView() {
    setState(() {
      _isFrontView = !_isFrontView;
      if (_isFrontView && _selectedMuscle == MuscleGroupType.back) {
        _selectedMuscle = MuscleGroupType.chest;
      } else if (!_isFrontView && _selectedMuscle == MuscleGroupType.chest) {
        _selectedMuscle = MuscleGroupType.back;
      }
    });
  }

  void _onChooseExercise(ExerciseModel exercise) {
    if (widget.onExerciseSelected != null) {
      widget.onExerciseSelected!(exercise);
    }
    if (!widget.isEmbedded && Navigator.of(context).canPop()) {
      Navigator.of(context).pop(exercise);
    } else {
      final router = GoRouter.maybeOf(context);
      if (router != null) {
        if (!widget.isEmbedded && router.canPop()) {
          router.pop(exercise);
        } else {
          router.push('/workouts/log');
        }
      }
    }
  }

  List<ExerciseModel> _filterExercises(List<ExerciseModel> exercises) {
    if (_searchQuery.isEmpty) return exercises;
    final query = _searchQuery.toLowerCase();
    return exercises.where((e) {
      final nameMatch = e.name.toLowerCase().contains(query);
      final equipMatch = e.equipment?.toLowerCase().contains(query) ?? false;
      final categoryMatch = e.category?.toLowerCase().contains(query) ?? false;
      final altMatch = e.alternativeNames.any((alt) => alt.toLowerCase().contains(query));
      return nameMatch || equipMatch || categoryMatch || altMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(
      exercisesListProvider(_selectedMuscle.name),
    );

    return GradientBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: widget.isEmbedded
            ? null
            : AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.velocityTextPrimary),
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
                title: const Row(
                  children: [
                    Icon(Icons.accessibility_new_rounded, color: AppTheme.velocityLime, size: 22),
                    SizedBox(width: 10),
                    Text(
                      'Interactive Body Map',
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppTheme.velocityTextPrimary),
                    ),
                  ],
                ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.sync_rounded, color: AppTheme.velocityLime),
                  tooltip: 'Rotate View',
                  onPressed: _toggleView,
                ),
                const SizedBox(width: 6),
              ],
            ),
      body: Column(
        children: [
          BodyMapConsole(
            selectedMuscle: _selectedMuscle,
            isFrontView: _isFrontView,
            isEmbedded: widget.isEmbedded,
            onToggleView: _toggleView,
            onSelectMuscle: _selectMuscle,
            onFullScreen: () => context.push('/workouts/muscle-picker'),
          ),
          MuscleGroupChips(
            selectedMuscle: _selectedMuscle,
            onSelectMuscle: _selectMuscle,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: AppTheme.velocitySurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppTheme.velocityBorder),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search in ${_selectedMuscle.name}...',
                  hintStyle: const TextStyle(color: AppTheme.velocityTextMuted, fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.velocityTextSecondary, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          color: AppTheme.velocityTextSecondary,
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
          ),
          Expanded(
            child: exercisesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => _buildExerciseList(
                _filterExercises(ExerciseModel.defaultExercises
                    .where((e) => e.muscleGroup.toLowerCase() == _selectedMuscle.name.toLowerCase())
                    .toList()),
              ),
              data: (exercises) {
                final targetList = exercises.isNotEmpty
                    ? exercises
                    : ExerciseModel.defaultExercises
                        .where((e) => e.muscleGroup.toLowerCase() == _selectedMuscle.name.toLowerCase())
                        .toList();
                return _buildExerciseList(_filterExercises(targetList));
              },
            ),
          ),
        ],
      ),
    ),
  );
  }

  Widget _buildExerciseList(List<ExerciseModel> exercises) {
    if (exercises.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.fitness_center_rounded, size: 48, color: AppTheme.velocityTextMuted),
              const SizedBox(height: 12),
              Text(
                'No exercises found for ${_selectedMuscle.name}',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.velocityTextPrimary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        return MusclePickerExerciseCard(
          exercise: exercise,
          selectedMuscle: _selectedMuscle,
          onTapDetails: () {
            MusclePickerDetailsSheet.show(
              context,
              exercise: exercise,
              selectedMuscle: _selectedMuscle,
              onChooseExercise: _onChooseExercise,
              onSelectVariation: (alt) {
                setState(() {
                  _searchQuery = alt.toLowerCase();
                  _searchController.text = alt;
                });
              },
            );
          },
          onSelectExercise: () => _onChooseExercise(exercise),
        );
      },
    );
  }
}
