import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../config/theme.dart';
import '../../../models/exercise_model.dart';
import '../../../repositories/exercise_repository.dart';
import 'exercise_picker_tile.dart';

class ExercisePickerSheet extends ConsumerStatefulWidget {
  final ValueChanged<ExerciseModel> onSelected;
  final VoidCallback? onOpenBodyMap;

  const ExercisePickerSheet({
    super.key,
    required this.onSelected,
    this.onOpenBodyMap,
  });

  static void show(
    BuildContext context, {
    required ValueChanged<ExerciseModel> onSelected,
    VoidCallback? onOpenBodyMap,
  }) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: AppTheme.velocitySurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ExercisePickerSheet(
        onSelected: onSelected,
        onOpenBodyMap: onOpenBodyMap,
      ),
    );
  }

  @override
  ConsumerState<ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends ConsumerState<ExercisePickerSheet> {
  final _searchController = TextEditingController();
  String _selectedMuscle = 'All';

  final List<String> _muscles = const [
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
        return SafeArea(
          top: false,
          child: Container(
            decoration: const BoxDecoration(
              color: AppTheme.velocitySurface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.velocityBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text(
                  'Choose Exercise',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.2,
                    color: AppTheme.velocityTextPrimary,
                  ),
                ),
                const SizedBox(height: 10),

                if (widget.onOpenBodyMap != null)
                  InkWell(
                    onTap: widget.onOpenBodyMap,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppTheme.velocityDark,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.velocityDark.withValues(alpha: 0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.accessibility_new_rounded, color: AppTheme.velocityLime, size: 22),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Interactive Body Map', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.white)),
                                SizedBox(height: 2),
                                Text('Tap muscles to filter & preview form tips', style: TextStyle(fontSize: 12, color: Color(0xFF9DA8B9))),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: AppTheme.velocityLime),
                        ],
                      ),
                    ),
                  ),
                if (widget.onOpenBodyMap == null) const SizedBox(height: 4),

                TextField(
                  controller: _searchController,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.velocityTextPrimary),
                  decoration: InputDecoration(
                    hintText: 'Search by exercise name...',
                    hintStyle: const TextStyle(color: AppTheme.velocityTextMuted, fontSize: 13),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.velocityDark),
                    filled: true,
                    fillColor: AppTheme.velocitySurfaceMuted,
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.velocityBorder)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.velocityBorder)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppTheme.velocityDark, width: 1.5)),
                  ),
                  onChanged: (val) => setState(() {}),
                ),
                const SizedBox(height: 10),

                SizedBox(
                  height: 38,
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
                        selectedColor: AppTheme.velocityLime,
                        backgroundColor: AppTheme.velocitySurfaceMuted,
                        side: BorderSide(color: isSelected ? AppTheme.velocityLimeDim : AppTheme.velocityBorder, width: 1.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        labelStyle: TextStyle(
                          color: isSelected ? AppTheme.velocityDark : AppTheme.velocityTextSecondary,
                          fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                          fontSize: 12,
                        ),
                        onSelected: (selected) {
                          if (selected) setState(() => _selectedMuscle = muscle);
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),

                Expanded(
                  child: exercisesAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, stackTrace) {
                      final list = ExerciseModel.defaultExercises;
                      return ListView.separated(
                        controller: scrollController,
                        itemCount: list.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) => ExercisePickerTile(
                          exercise: list[index],
                          onSelected: () => widget.onSelected(list[index]),
                        ),
                      );
                    },
                    data: (exercises) {
                      final query = _searchController.text.trim().toLowerCase();
                      final filtered = exercises.where((e) {
                        return query.isEmpty ||
                            e.name.toLowerCase().contains(query) ||
                            e.muscleGroup.toLowerCase().contains(query);
                      }).toList();

                      if (filtered.isEmpty) {
                        return Center(
                          child: Text('No exercises found for "$query"', style: const TextStyle(color: AppTheme.velocityTextSecondary)),
                        );
                      }

                      return ListView.separated(
                        controller: scrollController,
                        itemCount: filtered.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 8),
                        itemBuilder: (context, index) => ExercisePickerTile(
                          exercise: filtered[index],
                          onSelected: () => widget.onSelected(filtered[index]),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
