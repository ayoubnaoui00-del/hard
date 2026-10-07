import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../models/exercise_model.dart';
import '../../repositories/exercise_repository.dart';
import '../workout/muscle_picker_view.dart';

class _MuscleOption {
  final String name;
  final IconData icon;
  final Color color;
  const _MuscleOption(this.name, this.icon, this.color);
}

class ExerciseView extends ConsumerStatefulWidget {
  const ExerciseView({super.key});

  @override
  ConsumerState<ExerciseView> createState() => _ExerciseViewState();
}

class _ExerciseViewState extends ConsumerState<ExerciseView> {
  int _selectedTab = 0; // 0: All Exercises, 1: 3D Body Model
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedMuscle = 'All';
  String _selectedEquipment = 'All';
  String _selectedCategory = 'All';

  final List<_MuscleOption> _muscleOptions = const [
    _MuscleOption('All', Icons.all_inclusive_rounded, AppTheme.velocityDark),
    _MuscleOption('Chest', Icons.fitness_center_rounded, Color(0xFFFF5252)),
    _MuscleOption('Back', Icons.shield_outlined, Color(0xFF2979FF)),
    _MuscleOption('Shoulders', Icons.hardware_rounded, Color(0xFFFF9100)),
    _MuscleOption('Arms', Icons.sports_martial_arts_rounded, Color(0xFFB388FF)),
    _MuscleOption('Legs', Icons.directions_run_rounded, Color(0xFF00E676)),
    _MuscleOption('Core', Icons.adjust_rounded, Color(0xFF00E5FF)),
  ];

  final List<String> _equipmentOptions = const [
    'All',
    'Barbell',
    'Dumbbell',
    'Machine',
    'Cable',
    'Bodyweight',
  ];

  final List<String> _categoryOptions = const [
    'All',
    'Strength',
    'Hypertrophy',
    'Endurance',
    'Mobility',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedMuscle = 'All';
      _selectedEquipment = 'All';
      _selectedCategory = 'All';
    });
  }

  bool get _hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _selectedMuscle != 'All' ||
      _selectedEquipment != 'All' ||
      _selectedCategory != 'All';

  List<ExerciseModel> _filterExercises(List<ExerciseModel> exercises) {
    return exercises.where((e) {
      // 1. Muscle Filter
      if (_selectedMuscle != 'All' &&
          !e.muscleGroup.toLowerCase().contains(_selectedMuscle.toLowerCase())) {
        return false;
      }

      // 2. Equipment Filter
      if (_selectedEquipment != 'All' &&
          (e.equipment == null ||
              !e.equipment!.toLowerCase().contains(_selectedEquipment.toLowerCase()))) {
        return false;
      }

      // 3. Category Filter
      if (_selectedCategory != 'All' &&
          (e.category == null ||
              !e.category!.toLowerCase().contains(_selectedCategory.toLowerCase()))) {
        return false;
      }

      // 4. Search Query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final nameMatch = e.name.toLowerCase().contains(query);
        final muscleMatch = e.muscleGroup.toLowerCase().contains(query);
        final equipMatch = e.equipment?.toLowerCase().contains(query) ?? false;
        final categoryMatch = e.category?.toLowerCase().contains(query) ?? false;
        final tipMatch = e.formTips?.toLowerCase().contains(query) ?? false;
        final instructionsMatch = e.instructions?.toLowerCase().contains(query) ?? false;
        final altMatch = e.alternativeNames.any((alt) => alt.toLowerCase().contains(query));
        return nameMatch || muscleMatch || equipMatch || categoryMatch || tipMatch || instructionsMatch || altMatch;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(
      exercisesListProvider(_selectedMuscle == 'All' ? null : _selectedMuscle),
    );

    return Scaffold(
      backgroundColor: AppTheme.velocityBackground,
      appBar: AppBar(
        backgroundColor: AppTheme.velocityBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Exercises Library',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppTheme.velocityTextPrimary,
            letterSpacing: 0.2,
          ),
        ),
        actions: [
          // Filter Sheet Action
          IconButton(
            icon: const Icon(
              Icons.filter_list_rounded,
              color: AppTheme.velocityTextPrimary,
            ),
            tooltip: 'Filter Exercises',
            onPressed: () => _openFilterModal(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 1. Segmented Switcher (All Exercises vs 3D Body Model)
          _buildSegmentedSwitcher(),

          // 2. Tab Body
          Expanded(
            child: _selectedTab == 1
                ? const MusclePickerView(isEmbedded: true)
                : _buildCatalogContent(exercisesAsync),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Segmented Switcher: Catalog vs 3D Body Model
  // ---------------------------------------------------------------------------
  Widget _buildSegmentedSwitcher() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.velocitySurfaceMuted,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.velocityBorder),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedTab = 0),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTab == 0 ? AppTheme.velocityDark : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    if (_selectedTab == 0)
                      BoxShadow(
                        color: AppTheme.velocityDark.withValues(alpha: 0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.fitness_center_rounded,
                      size: 17,
                      color: _selectedTab == 0
                          ? AppTheme.velocityLime
                          : AppTheme.velocityTextSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'All Exercises',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _selectedTab == 0
                            ? Colors.white
                            : AppTheme.velocityTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: InkWell(
              onTap: () => setState(() => _selectedTab = 1),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _selectedTab == 1 ? AppTheme.velocityDark : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    if (_selectedTab == 1)
                      BoxShadow(
                        color: AppTheme.velocityDark.withValues(alpha: 0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.accessibility_new_rounded,
                      size: 17,
                      color: _selectedTab == 1
                          ? AppTheme.velocityLime
                          : AppTheme.velocityTextSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '3D Body Model',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _selectedTab == 1
                            ? Colors.white
                            : AppTheme.velocityTextSecondary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _selectedTab == 1
                            ? AppTheme.velocityLime
                            : AppTheme.velocityLime.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        '3D',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.velocityDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Catalog View Content
  // ---------------------------------------------------------------------------
  Widget _buildCatalogContent(AsyncValue<List<ExerciseModel>> exercisesAsync) {
    return Column(
      children: [
        // Search Bar
        _buildSearchBar(),

        const SizedBox(height: 6),

        // Muscle Group Filter Chips
        _buildMuscleFilterChips(),

        // Equipment Filter Chips
        _buildEquipmentFilterChips(),

        const SizedBox(height: 8),

        // Exercise List Area
        Expanded(
          child: exercisesAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (err, stack) {
              // Fallback gracefully to default catalog
              final fallbackList = _filterExercises(ExerciseModel.defaultExercises);
              return _buildExerciseCardsList(fallbackList);
            },
            data: (exercises) {
              final baseList = exercises.isNotEmpty
                  ? exercises
                  : ExerciseModel.defaultExercises;
              final filtered = _filterExercises(baseList);
              return _buildExerciseCardsList(filtered);
            },
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Search Bar
  // ---------------------------------------------------------------------------
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.velocitySurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.velocityBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (val) {
            setState(() {
              _searchQuery = val.trim().toLowerCase();
            });
          },
          decoration: InputDecoration(
            hintText: 'Search exercises, muscles, equipment...',
            hintStyle: const TextStyle(
              color: AppTheme.velocityTextMuted,
              fontSize: 14,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppTheme.velocityTextSecondary,
              size: 22,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 20),
                    color: AppTheme.velocityTextSecondary,
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                    },
                  )
                : null,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Muscle Filter Chips
  // ---------------------------------------------------------------------------
  Widget _buildMuscleFilterChips() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: _muscleOptions.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final option = _muscleOptions[index];
          final isSelected = _selectedMuscle == option.name;
          return InkWell(
            onTap: () {
              setState(() {
                _selectedMuscle = option.name;
              });
            },
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.velocityDark : AppTheme.velocitySurface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? AppTheme.velocityDark : AppTheme.velocityBorder,
                  width: 1.2,
                ),
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: AppTheme.velocityDark.withValues(alpha: 0.15),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    option.icon,
                    size: 14,
                    color: isSelected ? AppTheme.velocityLime : option.color,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    option.name,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? Colors.white : AppTheme.velocityTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Equipment Filter Chips
  // ---------------------------------------------------------------------------
  Widget _buildEquipmentFilterChips() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: SizedBox(
        height: 32,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          scrollDirection: Axis.horizontal,
          itemCount: _equipmentOptions.length,
          separatorBuilder: (context, index) => const SizedBox(width: 6),
          itemBuilder: (context, index) {
            final equip = _equipmentOptions[index];
            final isSelected = _selectedEquipment == equip;
            return InkWell(
              onTap: () {
                setState(() {
                  _selectedEquipment = equip;
                });
              },
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.velocityLime.withValues(alpha: 0.2)
                      : AppTheme.velocitySurfaceMuted,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected ? AppTheme.velocityDark : Colors.transparent,
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    equip,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected
                          ? AppTheme.velocityDark
                          : AppTheme.velocityTextSecondary,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Exercise Cards List
  // ---------------------------------------------------------------------------
  Widget _buildExerciseCardsList(List<ExerciseModel> exercises) {
    if (exercises.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 56,
                color: AppTheme.velocityTextMuted,
              ),
              const SizedBox(height: 12),
              const Text(
                'No exercises found',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.velocityTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Try adjusting your search query or filters',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.velocityTextSecondary,
                ),
              ),
              const SizedBox(height: 16),
              if (_hasActiveFilters)
                ElevatedButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('Reset All Filters'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.velocityDark,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(160, 42),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Results Count Header
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${exercises.length} Exercises found',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.velocityTextSecondary,
                ),
              ),
              if (_hasActiveFilters)
                GestureDetector(
                  onTap: _clearFilters,
                  child: const Text(
                    'Clear filters',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFFF5252),
                    ),
                  ),
                ),
            ],
          ),
        ),

        // List View
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 100),
            itemCount: exercises.length,
            itemBuilder: (context, index) {
              final exercise = exercises[index];
              return _buildExerciseCard(exercise);
            },
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Exercise Media Thumbnail (Video demonstration preview from backend)
  // ---------------------------------------------------------------------------
  Widget _buildExerciseThumbnail(ExerciseModel exercise, Color muscleColor, {double size = 48}) {
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
                    _getMuscleIcon(exercise.muscleGroup),
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
        _getMuscleIcon(exercise.muscleGroup),
        color: muscleColor,
        size: size * 0.45,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Single Exercise Card
  // ---------------------------------------------------------------------------
  Widget _buildExerciseCard(ExerciseModel exercise) {
    final muscleColor = _getMuscleColor(exercise.muscleGroup);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.velocitySurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.velocityBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showExerciseDetailsSheet(context, exercise),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Media Thumbnail + Title + Badges
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildExerciseThumbnail(exercise, muscleColor, size: 52),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            exercise.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.velocityTextPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              _buildPill(exercise.muscleGroup, muscleColor),
                              if (exercise.equipment != null)
                                _buildPill(
                                  exercise.equipment!,
                                  const Color(0xFF2979FF),
                                ),
                              if (exercise.category != null)
                                _buildPill(
                                  exercise.category!,
                                  const Color(0xFF00E676),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppTheme.velocityTextMuted,
                      size: 20,
                    ),
                  ],
                ),

                // Instructions preview snippet
                if (exercise.instructions != null &&
                    exercise.instructions!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    exercise.instructions!,
                    style: const TextStyle(
                      fontSize: 12,
                      height: 1.4,
                      color: AppTheme.velocityTextSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                // Form Tips snippet
                if (exercise.formTips != null &&
                    exercise.formTips!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB300).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFFFB300).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 15,
                          color: Color(0xFFFF8F00),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            exercise.formTips!,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Color(0xFFE65100),
                              fontStyle: FontStyle.italic,
                              height: 1.3,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // Card Bottom Action Buttons
                Row(
                  children: [
                    // Details Action Button
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _showExerciseDetailsSheet(context, exercise),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.velocityDark,
                          side: const BorderSide(color: AppTheme.velocityBorder),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: const Text(
                          'View Details',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Log Exercise Action Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => context.push('/workouts/log'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.velocityLime,
                          foregroundColor: AppTheme.velocityDark,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_rounded, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'Log Workout',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Visual Preview Fallback Card
  // ---------------------------------------------------------------------------
  Widget _buildVisualPreviewFallback(ExerciseModel exercise, Color muscleColor) {
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
              _getMuscleIcon(exercise.muscleGroup),
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

  // ---------------------------------------------------------------------------
  // Exercise Demonstration Video Banner (Animated Demonstration from Backend)
  // ---------------------------------------------------------------------------
  Widget _buildVideoDemonstrationBanner(ExerciseModel exercise) {
    final videoUrl = exercise.videoUrl ?? exercise.gifUrl;
    final muscleColor = _getMuscleColor(exercise.muscleGroup);

    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        color: const Color(0xFF0F1117),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.velocityBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(19),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Video Demonstration Content
            if (videoUrl != null)
              Image.network(
                videoUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.velocityLime,
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Loading demonstration video...',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  debugPrint('[ExerciseMedia] Error loading video demo: $videoUrl: $error');
                  return _buildVisualPreviewFallback(exercise, muscleColor);
                },
              )
            else
              _buildVisualPreviewFallback(exercise, muscleColor),

            // Top badge: DEMONSTRATION VIDEO
            Positioned(
              top: 10,
              left: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.play_circle_fill_rounded,
                      size: 14,
                      color: AppTheme.velocityLime,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'DEMONSTRATION VIDEO',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Exercise Details Bottom Sheet
  // ---------------------------------------------------------------------------
  void _showExerciseDetailsSheet(BuildContext context, ExerciseModel exercise) {
    final muscleColor = _getMuscleColor(exercise.muscleGroup);

    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
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
                // Top drag pill
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Video Demonstration Banner (Animated GIF Video from Backend)
                if (exercise.videoUrl != null || exercise.gifUrl != null) ...[
                  _buildVideoDemonstrationBanner(exercise),
                  const SizedBox(height: 18),
                ],

                    // Title and Badges
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildExerciseThumbnail(exercise, muscleColor, size: 52),
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
                                  _buildPill(exercise.muscleGroup, muscleColor),
                                  if (exercise.equipment != null)
                                    _buildPill(exercise.equipment!, const Color(0xFF2979FF)),
                                  if (exercise.category != null)
                                    _buildPill(exercise.category!, const Color(0xFF00E676)),
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

                    // Step-by-Step Instructions
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

                    // Pro Form Tips
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

                    // Alternative Exercises
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
                              Navigator.of(ctx).pop();
                              setState(() {
                                _searchQuery = alt.toLowerCase();
                                _searchController.text = alt;
                              });
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

                    // Bottom CTA Button: Start Workout
                    ElevatedButton(
                      onPressed: () {
                        Navigator.of(ctx).pop();
                        context.push('/workouts/log');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.velocityLime,
                        foregroundColor: AppTheme.velocityDark,
                        minimumSize: const Size.fromHeight(50),
                        elevation: 0,
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
                            'Log This Exercise',
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
        },
      );
      }

  // ---------------------------------------------------------------------------
  // Filter Modal Bottom Sheet
  // ---------------------------------------------------------------------------
  void _openFilterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return SafeArea(
              top: false,
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                ),
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
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Exercises',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.velocityTextPrimary,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _selectedMuscle = 'All';
                            _selectedEquipment = 'All';
                            _selectedCategory = 'All';
                          });
                          setState(() {});
                        },
                        child: const Text('Reset All'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 1. Muscle Filter
                  const Text(
                    'Target Muscle Group',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.velocityTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _muscleOptions.map((opt) {
                      final isSel = _selectedMuscle == opt.name;
                      return ChoiceChip(
                        label: Text(opt.name),
                        selected: isSel,
                        onSelected: (val) {
                          setModalState(() => _selectedMuscle = opt.name);
                          setState(() {});
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // 2. Equipment Filter
                  const Text(
                    'Equipment',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.velocityTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _equipmentOptions.map((eq) {
                      final isSel = _selectedEquipment == eq;
                      return ChoiceChip(
                        label: Text(eq),
                        selected: isSel,
                        onSelected: (val) {
                          setModalState(() => _selectedEquipment = eq);
                          setState(() {});
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 14),

                  // 3. Category Filter
                  const Text(
                    'Training Goal / Category',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.velocityTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: _categoryOptions.map((cat) {
                      final isSel = _selectedCategory == cat;
                      return ChoiceChip(
                        label: Text(cat),
                        selected: isSel,
                        onSelected: (val) {
                          setModalState(() => _selectedCategory = cat);
                          setState(() {});
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // Apply Button
                  ElevatedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.velocityDark,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Apply Filters',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            );
          },
        );
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------
  Widget _buildPill(String text, Color color) {
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

  Color _getMuscleColor(String muscle) {
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

  IconData _getMuscleIcon(String muscle) {
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
}
