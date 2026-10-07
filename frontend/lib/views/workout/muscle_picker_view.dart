import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../models/exercise_model.dart';
import '../../repositories/exercise_repository.dart';

/// Muscle group definitions with assigned neon theme colors and anatomy data
enum MuscleGroupType {
  chest(
    name: 'Chest',
    color: Color(0xFFFF5252),
    isFront: true,
    icon: Icons.fitness_center_rounded,
    description: 'Pectoralis Major & Minor',
  ),
  back(
    name: 'Back',
    color: Color(0xFF2979FF),
    isFront: false,
    icon: Icons.shield_outlined,
    description: 'Latissimus Dorsi, Traps & Rhomboids',
  ),
  shoulders(
    name: 'Shoulders',
    color: Color(0xFFFF9100),
    isFront: true,
    icon: Icons.hardware_rounded,
    description: 'Anterior, Lateral & Posterior Deltoids',
  ),
  arms(
    name: 'Arms',
    color: Color(0xFFB388FF),
    isFront: true,
    icon: Icons.sports_martial_arts_rounded,
    description: 'Biceps, Triceps & Forearms',
  ),
  legs(
    name: 'Legs',
    color: Color(0xFF00E676),
    isFront: true,
    icon: Icons.directions_run_rounded,
    description: 'Quadriceps, Hamstrings, Glutes & Calves',
  ),
  core(
    name: 'Core',
    color: Color(0xFF00E5FF),
    isFront: true,
    icon: Icons.adjust_rounded,
    description: 'Rectus Abdominis & Obliques',
  );

  final String name;
  final Color color;
  final bool isFront;
  final IconData icon;
  final String description;

  const MuscleGroupType({
    required this.name,
    required this.color,
    required this.isFront,
    required this.icon,
    required this.description,
  });

  static MuscleGroupType fromString(String name) {
    return MuscleGroupType.values.firstWhere(
      (m) => m.name.toLowerCase() == name.toLowerCase(),
      orElse: () => MuscleGroupType.chest,
    );
  }
}

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

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(
      exercisesListProvider(_selectedMuscle.name),
    );

    return Scaffold(
      backgroundColor: AppTheme.velocityBackground,
      appBar: widget.isEmbedded
          ? null
          : AppBar(
              backgroundColor: AppTheme.velocityBackground,
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
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: AppTheme.velocityTextPrimary,
                    ),
                  ),
                ],
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: InkWell(
                    onTap: _toggleView,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.velocityDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.velocityDarkBorder),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isFrontView ? Icons.flip_to_front_rounded : Icons.flip_to_back_rounded,
                            size: 15,
                            color: AppTheme.velocityLime,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _isFrontView ? 'Front View' : 'Back View',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
      body: Column(
        children: [
          // 1. Sleek 3D Anatomical Body Map Card
          _buildBodyMapConsole(),

          // 2. Horizontal Muscle Category Filter Chips
          _buildMuscleGroupChips(),

          // 3. Search Bar
          _buildSearchBar(),

          // 4. Dynamic Exercise Cards List
          Expanded(
            child: exercisesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (err, stack) => _buildExerciseList(
                _filterExercises(ExerciseModel.defaultExercises
                    .where((e) =>
                        e.muscleGroup.toLowerCase() == _selectedMuscle.name.toLowerCase())
                    .toList()),
              ),
              data: (exercises) {
                final targetList = exercises.isNotEmpty
                    ? exercises
                    : ExerciseModel.defaultExercises
                        .where((e) =>
                            e.muscleGroup.toLowerCase() == _selectedMuscle.name.toLowerCase())
                        .toList();
                return _buildExerciseList(_filterExercises(targetList));
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 3D Anatomical Body Map Console
  // ---------------------------------------------------------------------------
  Widget _buildBodyMapConsole() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: AppTheme.velocityDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.velocityDarkBorder, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppTheme.velocityDark.withValues(alpha: 0.16),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Console Header Row (only in embedded mode since AppBar handles standalone mode)
          if (widget.isEmbedded) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: AppTheme.velocityLime.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.accessibility_new_rounded,
                        color: AppTheme.velocityLime,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Interactive Body Map',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    // Front / Back View Toggle Pill
                    InkWell(
                      onTap: _toggleView,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppTheme.velocityDarkSurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.velocityDarkBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isFrontView ? Icons.flip_to_front_rounded : Icons.flip_to_back_rounded,
                              size: 14,
                              color: AppTheme.velocityLime,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _isFrontView ? 'Front View' : 'Back View',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.fullscreen_rounded, color: Colors.white70, size: 20),
                      tooltip: 'Full Screen',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => context.push('/workouts/muscle-picker'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],

          // Anatomical Body Canvas & Tap Target
          SizedBox(
            height: 195,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Soft background radial aura for selected muscle
                Container(
                  width: 130,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _selectedMuscle.color.withValues(alpha: 0.12),
                    boxShadow: [
                      BoxShadow(
                        color: _selectedMuscle.color.withValues(alpha: 0.22),
                        blurRadius: 36,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                ),

                // Interactive Body Map Canvas
                GestureDetector(
                  onTapUp: (details) {
                    _handleBodyTap(details.localPosition, const Size(180, 195));
                  },
                  child: CustomPaint(
                    size: const Size(180, 195),
                    painter: BodyMapPainter(
                      selectedMuscle: _selectedMuscle,
                      isFront: _isFrontView,
                    ),
                  ),
                ),


                // Quick View Switch Floating Action Button
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: FloatingActionButton.small(
                    heroTag: 'bodyMapToggle',
                    backgroundColor: AppTheme.velocityDarkSurface,
                    foregroundColor: AppTheme.velocityLime,
                    elevation: 2,
                    onPressed: _toggleView,
                    tooltip: 'Rotate View',
                    child: const Icon(Icons.sync_rounded, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Muscle Group Filter Chips
  // ---------------------------------------------------------------------------
  Widget _buildMuscleGroupChips() {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: MuscleGroupType.values.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final muscle = MuscleGroupType.values[index];
          final isSelected = _selectedMuscle == muscle;
          return InkWell(
            onTap: () => _selectMuscle(muscle),
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
                    )
                  else
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    muscle.icon,
                    size: 14,
                    color: isSelected ? AppTheme.velocityLime : muscle.color,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    muscle.name,
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
  // Search Bar
  // ---------------------------------------------------------------------------
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
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
            hintText: 'Search ${_selectedMuscle.name} exercises...',
            hintStyle: const TextStyle(
              color: AppTheme.velocityTextMuted,
              fontSize: 13,
            ),
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: AppTheme.velocityTextSecondary,
              size: 20,
            ),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded, size: 18),
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
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ),
    );
  }

  List<ExerciseModel> _filterExercises(List<ExerciseModel> exercises) {
    if (_searchQuery.isEmpty) return exercises;
    return exercises.where((e) {
      final nameMatch = e.name.toLowerCase().contains(_searchQuery);
      final equipMatch = e.equipment?.toLowerCase().contains(_searchQuery) ?? false;
      final tipMatch = e.formTips?.toLowerCase().contains(_searchQuery) ?? false;
      return nameMatch || equipMatch || tipMatch;
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // Exercise List
  // ---------------------------------------------------------------------------
  Widget _buildExerciseList(List<ExerciseModel> exercises) {
    if (exercises.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 52,
                color: AppTheme.velocityTextMuted,
              ),
              const SizedBox(height: 12),
              Text(
                'No exercises found for ${_selectedMuscle.name}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.velocityTextPrimary,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Try adjusting your search query or select another muscle',
                style: TextStyle(
                  fontSize: 13,
                  color: AppTheme.velocityTextSecondary,
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
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${exercises.length} ${_selectedMuscle.name} exercises found',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.velocityTextSecondary,
                ),
              ),
              if (_searchQuery.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                  child: const Text(
                    'Clear search',
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
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
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
                    _selectedMuscle.icon,
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
        _selectedMuscle.icon,
        color: muscleColor,
        size: size * 0.45,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Exercise Card
  // ---------------------------------------------------------------------------
  Widget _buildExerciseCard(ExerciseModel exercise) {
    final muscleColor = _selectedMuscle.color;

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
                              _buildBadge(exercise.muscleGroup, muscleColor),
                              if (exercise.equipment != null)
                                _buildBadge(
                                  exercise.equipment!,
                                  const Color(0xFF2979FF),
                                ),
                              if (exercise.category != null)
                                _buildBadge(
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

                // Instructions snippet
                if (exercise.instructions != null && exercise.instructions!.isNotEmpty) ...[
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

                // Form Tips Callout
                if (exercise.formTips != null && exercise.formTips!.isNotEmpty) ...[
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

                // Alternative Exercises Chips
                if (exercise.alternativeNames.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const Text(
                        'Alternatives:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.velocityTextSecondary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: exercise.alternativeNames.map((alt) {
                              return Container(
                                margin: const EdgeInsets.only(right: 6),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.velocitySurfaceMuted,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  alt,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppTheme.velocityTextSecondary,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 12),

                // Card Bottom Action Buttons
                Row(
                  children: [
                    // View Details Outlined Button
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
                    // "Select This Exercise" Elevated Lime Button
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => _onChooseExercise(exercise),
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
                              'Select This Exercise',
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

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Exercise Demonstration Video Banner
  // ---------------------------------------------------------------------------
  Widget _buildVideoDemonstrationBanner(ExerciseModel exercise) {
    final videoUrl = exercise.videoUrl ?? exercise.gifUrl;
    final muscleColor = _selectedMuscle.color;

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
                  return Center(
                    child: Icon(
                      _selectedMuscle.icon,
                      size: 44,
                      color: muscleColor,
                    ),
                  );
                },
              )
            else
              Center(
                child: Icon(
                  _selectedMuscle.icon,
                  size: 44,
                  color: muscleColor,
                ),
              ),
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
    final muscleColor = _selectedMuscle.color;

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

                if (exercise.videoUrl != null || exercise.gifUrl != null) ...[
                  _buildVideoDemonstrationBanner(exercise),
                  const SizedBox(height: 18),
                ],

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
                              _buildBadge(exercise.muscleGroup, muscleColor),
                              if (exercise.equipment != null)
                                _buildBadge(exercise.equipment!, const Color(0xFF2979FF)),
                              if (exercise.category != null)
                                _buildBadge(exercise.category!, const Color(0xFF00E676)),
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
                                  color: Color(0xFFB26A00),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                ElevatedButton(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _onChooseExercise(exercise);
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
      },
    );
  }

  /// Maps tap positions on the custom canvas to specific muscle groups
  void _handleBodyTap(Offset tapPos, Size size) {
    final relX = tapPos.dx / size.width;
    final relY = tapPos.dy / size.height;

    if (_isFrontView) {
      if (relY >= 0.18 && relY <= 0.32 && relX >= 0.28 && relX <= 0.72) {
        _selectMuscle(MuscleGroupType.chest);
      } else if (relY >= 0.16 && relY <= 0.30 && (relX < 0.28 || relX > 0.72)) {
        _selectMuscle(MuscleGroupType.shoulders);
      } else if (relY > 0.30 && relY <= 0.52 && (relX < 0.26 || relX > 0.74)) {
        _selectMuscle(MuscleGroupType.arms);
      } else if (relY > 0.32 && relY <= 0.50 && relX >= 0.30 && relX <= 0.70) {
        _selectMuscle(MuscleGroupType.core);
      } else if (relY > 0.50) {
        _selectMuscle(MuscleGroupType.legs);
      }
    } else {
      if (relY >= 0.16 && relY <= 0.44 && relX >= 0.24 && relX <= 0.76) {
        _selectMuscle(MuscleGroupType.back);
      } else if (relY >= 0.16 && relY <= 0.28 && (relX < 0.24 || relX > 0.76)) {
        _selectMuscle(MuscleGroupType.shoulders);
      } else if (relY > 0.28 && relY <= 0.52 && (relX < 0.24 || relX > 0.76)) {
        _selectMuscle(MuscleGroupType.arms);
      } else if (relY > 0.50) {
        _selectMuscle(MuscleGroupType.legs);
      }
    }
  }
}

/// CustomPainter rendering an anatomical human silhouette with color-coded muscle zones
class BodyMapPainter extends CustomPainter {
  final MuscleGroupType selectedMuscle;
  final bool isFront;

  BodyMapPainter({
    required this.selectedMuscle,
    required this.isFront,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;

    final basePaint = Paint()
      ..color = const Color(0xFF2B3340)
      ..style = PaintingStyle.fill;

    final baseBorderPaint = Paint()
      ..color = const Color(0xFF424D5E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    // Helper to get paint for a muscle group
    Paint getMusclePaint(MuscleGroupType muscle, {bool isAccent = false}) {
      final isSelected = selectedMuscle == muscle;
      final baseColor = muscle.color;

      return Paint()
        ..color = isSelected
            ? baseColor.withValues(alpha: isAccent ? 0.95 : 0.8)
            : baseColor.withValues(alpha: 0.35)
        ..style = PaintingStyle.fill;
    }

    Paint getMuscleBorder(MuscleGroupType muscle) {
      final isSelected = selectedMuscle == muscle;
      return Paint()
        ..color = isSelected ? muscle.color : muscle.color.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.0 : 1.0;
    }

    // 1. Head & Neck Silhouette
    final headRect = Rect.fromCenter(
      center: Offset(centerX, size.height * 0.08),
      width: size.width * 0.18,
      height: size.height * 0.12,
    );
    canvas.drawOval(headRect, basePaint);
    canvas.drawOval(headRect, baseBorderPaint);

    final neckRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, size.height * 0.15),
        width: size.width * 0.11,
        height: size.height * 0.06,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(neckRect, basePaint);

    if (isFront) {
      // -----------------------------------------------------------------------
      // FRONT VIEW
      // -----------------------------------------------------------------------

      // Shoulders (Deltoids: Left & Right)
      final leftShoulderPath = Path()
        ..addOval(Rect.fromCenter(
          center: Offset(centerX - size.width * 0.28, size.height * 0.22),
          width: size.width * 0.18,
          height: size.height * 0.10,
        ));
      final rightShoulderPath = Path()
        ..addOval(Rect.fromCenter(
          center: Offset(centerX + size.width * 0.28, size.height * 0.22),
          width: size.width * 0.18,
          height: size.height * 0.10,
        ));

      final shoulderPaint = getMusclePaint(MuscleGroupType.shoulders);
      final shoulderBorder = getMuscleBorder(MuscleGroupType.shoulders);
      canvas.drawPath(leftShoulderPath, shoulderPaint);
      canvas.drawPath(leftShoulderPath, shoulderBorder);
      canvas.drawPath(rightShoulderPath, shoulderPaint);
      canvas.drawPath(rightShoulderPath, shoulderBorder);

      // Chest (Pectoralis Major: Left & Right plates)
      final leftPec = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          centerX - size.width * 0.22,
          size.height * 0.19,
          size.width * 0.21,
          size.height * 0.11,
        ),
        const Radius.circular(8),
      );
      final rightPec = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          centerX + size.width * 0.01,
          size.height * 0.19,
          size.width * 0.21,
          size.height * 0.11,
        ),
        const Radius.circular(8),
      );

      final chestPaint = getMusclePaint(MuscleGroupType.chest);
      final chestBorder = getMuscleBorder(MuscleGroupType.chest);
      canvas.drawRRect(leftPec, chestPaint);
      canvas.drawRRect(leftPec, chestBorder);
      canvas.drawRRect(rightPec, chestPaint);
      canvas.drawRRect(rightPec, chestBorder);

      // Core / Abdominals (Six-pack grid)
      final corePaint = getMusclePaint(MuscleGroupType.core);
      final coreBorder = getMuscleBorder(MuscleGroupType.core);
      for (int row = 0; row < 3; row++) {
        final leftAb = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            centerX - size.width * 0.14,
            size.height * 0.32 + (row * size.height * 0.05),
            size.width * 0.13,
            size.height * 0.042,
          ),
          const Radius.circular(4),
        );
        final rightAb = RRect.fromRectAndRadius(
          Rect.fromLTWH(
            centerX + size.width * 0.01,
            size.height * 0.32 + (row * size.height * 0.05),
            size.width * 0.13,
            size.height * 0.042,
          ),
          const Radius.circular(4),
        );
        canvas.drawRRect(leftAb, corePaint);
        canvas.drawRRect(leftAb, coreBorder);
        canvas.drawRRect(rightAb, corePaint);
        canvas.drawRRect(rightAb, coreBorder);
      }

      // Arms (Biceps & Forearms: Left & Right)
      final armsPaint = getMusclePaint(MuscleGroupType.arms);
      final armsBorder = getMuscleBorder(MuscleGroupType.arms);

      // Upper arm / Biceps
      final leftBicep = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          centerX - size.width * 0.39,
          size.height * 0.28,
          size.width * 0.11,
          size.height * 0.12,
        ),
        const Radius.circular(8),
      );
      final rightBicep = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          centerX + size.width * 0.28,
          size.height * 0.28,
          size.width * 0.11,
          size.height * 0.12,
        ),
        const Radius.circular(8),
      );
      canvas.drawRRect(leftBicep, armsPaint);
      canvas.drawRRect(leftBicep, armsBorder);
      canvas.drawRRect(rightBicep, armsPaint);
      canvas.drawRRect(rightBicep, armsBorder);

      // Forearms
      final leftForearm = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          centerX - size.width * 0.42,
          size.height * 0.41,
          size.width * 0.09,
          size.height * 0.13,
        ),
        const Radius.circular(6),
      );
      final rightForearm = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          centerX + size.width * 0.33,
          size.height * 0.41,
          size.width * 0.09,
          size.height * 0.13,
        ),
        const Radius.circular(6),
      );
      canvas.drawRRect(leftForearm, armsPaint);
      canvas.drawRRect(leftForearm, armsBorder);
      canvas.drawRRect(rightForearm, armsPaint);
      canvas.drawRRect(rightForearm, armsBorder);

      // Legs (Quadriceps & Calves)
      final legsPaint = getMusclePaint(MuscleGroupType.legs);
      final legsBorder = getMuscleBorder(MuscleGroupType.legs);

      // Left & Right Quads
      final leftQuad = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          centerX - size.width * 0.21,
          size.height * 0.50,
          size.width * 0.19,
          size.height * 0.24,
        ),
        const Radius.circular(10),
      );
      final rightQuad = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          centerX + size.width * 0.02,
          size.height * 0.50,
          size.width * 0.19,
          size.height * 0.24,
        ),
        const Radius.circular(10),
      );
      canvas.drawRRect(leftQuad, legsPaint);
      canvas.drawRRect(leftQuad, legsBorder);
      canvas.drawRRect(rightQuad, legsPaint);
      canvas.drawRRect(rightQuad, legsBorder);

      // Calves
      final leftCalf = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          centerX - size.width * 0.18,
          size.height * 0.77,
          size.width * 0.14,
          size.height * 0.18,
        ),
        const Radius.circular(8),
      );
      final rightCalf = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          centerX + size.width * 0.04,
          size.height * 0.77,
          size.width * 0.14,
          size.height * 0.18,
        ),
        const Radius.circular(8),
      );
      canvas.drawRRect(leftCalf, legsPaint);
      canvas.drawRRect(leftCalf, legsBorder);
      canvas.drawRRect(rightCalf, legsPaint);
      canvas.drawRRect(rightCalf, legsBorder);
    } else {
      // -----------------------------------------------------------------------
      // BACK VIEW
      // -----------------------------------------------------------------------

      // Upper Back & Trapezius
      final backPaint = getMusclePaint(MuscleGroupType.back);
      final backBorder = getMuscleBorder(MuscleGroupType.back);

      final upperBack = Path()
        ..moveTo(centerX - size.width * 0.22, size.height * 0.18)
        ..lineTo(centerX + size.width * 0.22, size.height * 0.18)
        ..lineTo(centerX + size.width * 0.15, size.height * 0.32)
        ..lineTo(centerX - size.width * 0.15, size.height * 0.32)
        ..close();
      canvas.drawPath(upperBack, backPaint);
      canvas.drawPath(upperBack, backBorder);

      // Lats (Latissimus Dorsi: Left & Right V-Taper wings)
      final leftLat = Path()
        ..moveTo(centerX - size.width * 0.25, size.height * 0.24)
        ..lineTo(centerX - size.width * 0.05, size.height * 0.26)
        ..lineTo(centerX - size.width * 0.05, size.height * 0.44)
        ..lineTo(centerX - size.width * 0.15, size.height * 0.42)
        ..close();
      final rightLat = Path()
        ..moveTo(centerX + size.width * 0.25, size.height * 0.24)
        ..lineTo(centerX + size.width * 0.05, size.height * 0.26)
        ..lineTo(centerX + size.width * 0.05, size.height * 0.44)
        ..lineTo(centerX + size.width * 0.15, size.height * 0.42)
        ..close();
      canvas.drawPath(leftLat, backPaint);
      canvas.drawPath(leftLat, backBorder);
      canvas.drawPath(rightLat, backPaint);
      canvas.drawPath(rightLat, backBorder);

      // Triceps (Back of arms)
      final armsPaint = getMusclePaint(MuscleGroupType.arms);
      final armsBorder = getMuscleBorder(MuscleGroupType.arms);

      final leftTricep = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          centerX - size.width * 0.39,
          size.height * 0.26,
          size.width * 0.11,
          size.height * 0.14,
        ),
        const Radius.circular(8),
      );
      final rightTricep = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          centerX + size.width * 0.28,
          size.height * 0.26,
          size.width * 0.11,
          size.height * 0.14,
        ),
        const Radius.circular(8),
      );
      canvas.drawRRect(leftTricep, armsPaint);
      canvas.drawRRect(leftTricep, armsBorder);
      canvas.drawRRect(rightTricep, armsPaint);
      canvas.drawRRect(rightTricep, armsBorder);

      // Glutes & Hamstrings
      final legsPaint = getMusclePaint(MuscleGroupType.legs);
      final legsBorder = getMuscleBorder(MuscleGroupType.legs);

      // Glutes
      final leftGlute = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          centerX - size.width * 0.19,
          size.height * 0.47,
          size.width * 0.18,
          size.height * 0.12,
        ),
        const Radius.circular(10),
      );
      final rightGlute = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          centerX + size.width * 0.01,
          size.height * 0.47,
          size.width * 0.18,
          size.height * 0.12,
        ),
        const Radius.circular(10),
      );
      canvas.drawRRect(leftGlute, legsPaint);
      canvas.drawRRect(leftGlute, legsBorder);
      canvas.drawRRect(rightGlute, legsPaint);
      canvas.drawRRect(rightGlute, legsBorder);

      // Hamstrings
      final leftHamstring = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          centerX - size.width * 0.20,
          size.height * 0.60,
          size.width * 0.18,
          size.height * 0.15,
        ),
        const Radius.circular(8),
      );
      final rightHamstring = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          centerX + size.width * 0.02,
          size.height * 0.60,
          size.width * 0.18,
          size.height * 0.15,
        ),
        const Radius.circular(8),
      );
      canvas.drawRRect(leftHamstring, legsPaint);
      canvas.drawRRect(leftHamstring, legsBorder);
      canvas.drawRRect(rightHamstring, legsPaint);
      canvas.drawRRect(rightHamstring, legsBorder);

      // Calves
      final leftCalfBack = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          centerX - size.width * 0.18,
          size.height * 0.77,
          size.width * 0.14,
          size.height * 0.18,
        ),
        const Radius.circular(8),
      );
      final rightCalfBack = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          centerX + size.width * 0.04,
          size.height * 0.77,
          size.width * 0.14,
          size.height * 0.18,
        ),
        const Radius.circular(8),
      );
      canvas.drawRRect(leftCalfBack, legsPaint);
      canvas.drawRRect(leftCalfBack, legsBorder);
      canvas.drawRRect(rightCalfBack, legsPaint);
      canvas.drawRRect(rightCalfBack, legsBorder);
    }
  }

  @override
  bool shouldRepaint(covariant BodyMapPainter oldDelegate) {
    return oldDelegate.selectedMuscle != selectedMuscle ||
        oldDelegate.isFront != isFront;
  }
}
