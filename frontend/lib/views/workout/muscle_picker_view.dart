import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

  const MusclePickerView({
    super.key,
    this.initialMuscle = MuscleGroupType.chest,
    this.onExerciseSelected,
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
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(exercise);
    } else {
      final router = GoRouter.maybeOf(context);
      if (router != null && router.canPop()) {
        router.pop(exercise);
      } else if (router != null) {
        router.go('/workouts/log');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(
      exercisesListProvider(_selectedMuscle.name),
    );

    return Scaffold(
      backgroundColor: const Color(0xFF121214),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E24),
        title: const Row(
          children: [
            Icon(Icons.accessibility_new_rounded, color: Color(0xFFFF5252), size: 22),
            SizedBox(width: 10),
            Text(
              'Interactive Body Map',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        actions: [
          // Front / Back toggle pill
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: _toggleView,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF282832),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF33333F)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _isFrontView ? Icons.flip_to_front_rounded : Icons.flip_to_back_rounded,
                      size: 16,
                      color: _selectedMuscle.color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isFrontView ? 'Front View' : 'Back View',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _selectedMuscle.color,
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
          // Upper Section: Interactive Body Map & Muscle Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A22),
              border: Border(
                bottom: BorderSide(color: Color(0xFF282832), width: 1),
              ),
            ),
            child: Column(
              children: [
                // 1. Stylized Anatomical Body Canvas & Tap Target
                SizedBox(
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Background glow
                      Container(
                        width: 140,
                        height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _selectedMuscle.color.withValues(alpha: 0.12),
                          boxShadow: [
                            BoxShadow(
                              color: _selectedMuscle.color.withValues(alpha: 0.25),
                              blurRadius: 32,
                              spreadRadius: 8,
                            ),
                          ],
                        ),
                      ),

                      // Interactive Body Map Canvas
                      GestureDetector(
                        onTapUp: (details) {
                          _handleBodyTap(details.localPosition, const Size(180, 210));
                        },
                        child: CustomPaint(
                          size: const Size(180, 210),
                          painter: BodyMapPainter(
                            selectedMuscle: _selectedMuscle,
                            isFront: _isFrontView,
                          ),
                        ),
                      ),

                      // Quick View Switch button overlay
                      Positioned(
                        right: 8,
                        bottom: 8,
                        child: FloatingActionButton.small(
                          heroTag: 'bodyMapToggle',
                          backgroundColor: const Color(0xFF282832),
                          foregroundColor: Colors.white,
                          onPressed: _toggleView,
                          tooltip: 'Rotate View',
                          child: const Icon(Icons.sync_rounded, size: 20),
                        ),
                      ),

                      // Active Muscle indicator banner
                      Positioned(
                        left: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFF121214).withValues(alpha: 0.85),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: _selectedMuscle.color.withValues(alpha: 0.6),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _selectedMuscle.color,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _selectedMuscle.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  color: _selectedMuscle.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // 2. Horizontal Color-Coded Muscle Group Pills
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: MuscleGroupType.values.map((muscle) {
                      final isSelected = _selectedMuscle == muscle;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () => _selectMuscle(muscle),
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? muscle.color.withValues(alpha: 0.2)
                                  : const Color(0xFF24242E),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? muscle.color
                                    : const Color(0xFF33333F),
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  muscle.icon,
                                  size: 14,
                                  color: isSelected ? muscle.color : Colors.grey.shade400,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  muscle.name,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected ? Colors.white : Colors.grey.shade300,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Lower Section: Exercise List Header & Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) {
                      setState(() {
                        _searchQuery = val.trim().toLowerCase();
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search ${_selectedMuscle.name} exercises...',
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      filled: true,
                      fillColor: const Color(0xFF1E1E24),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF33333F)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Dynamic Exercise Cards List
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

  List<ExerciseModel> _filterExercises(List<ExerciseModel> exercises) {
    if (_searchQuery.isEmpty) return exercises;
    return exercises.where((e) {
      final nameMatch = e.name.toLowerCase().contains(_searchQuery);
      final equipMatch = e.equipment?.toLowerCase().contains(_searchQuery) ?? false;
      final tipMatch = e.formTips?.toLowerCase().contains(_searchQuery) ?? false;
      return nameMatch || equipMatch || tipMatch;
    }).toList();
  }

  Widget _buildExerciseList(List<ExerciseModel> exercises) {
    if (exercises.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 48, color: Colors.grey.shade600),
            const SizedBox(height: 12),
            Text(
              'No exercises found for ${_selectedMuscle.name}',
              style: const TextStyle(fontSize: 15, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
      itemCount: exercises.length,
      itemBuilder: (context, index) {
        final exercise = exercises[index];
        return _buildExerciseCard(exercise);
      },
    );
  }

  Widget _buildExerciseCard(ExerciseModel exercise) {
    final themeColor = _selectedMuscle.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E24),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF33333F)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise Header: Name + Muscle & Equipment Badges
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: themeColor.withValues(alpha: 0.15),
                  child: Icon(
                    Icons.fitness_center_rounded,
                    color: themeColor,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        exercise.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          _buildBadge(exercise.muscleGroup, themeColor),
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
              ],
            ),

            // Instructions snippet
            if (exercise.instructions != null && exercise.instructions!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                exercise.instructions!,
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: Colors.grey.shade300,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            // Form Tips Callout
            if (exercise.formTips != null && exercise.formTips!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF9100).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFFF9100).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 16,
                      color: Color(0xFFFF9100),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        exercise.formTips!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFFFD180),
                          fontStyle: FontStyle.italic,
                        ),
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
                    style: TextStyle(fontSize: 11, color: Colors.grey),
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
                              color: const Color(0xFF282832),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              alt,
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
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

            const SizedBox(height: 14),

            // "Select This" Action Button
            ElevatedButton(
              onPressed: () => _onChooseExercise(exercise),
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 2,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_circle_outline_rounded, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Select This Exercise',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
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
      ..color = const Color(0xFF2C2C38)
      ..style = PaintingStyle.fill;

    final baseBorderPaint = Paint()
      ..color = const Color(0xFF444455)
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
