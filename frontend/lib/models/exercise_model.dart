class ExerciseModel {
  final dynamic id;
  final String name;
  final String muscleGroup;
  final String? instructions;
  final String? formTips;
  final String? category;
  final String? equipment;
  final String? imageUrl;
  final String? gifUrl;

  const ExerciseModel({
    required this.id,
    required this.name,
    required this.muscleGroup,
    this.instructions,
    this.formTips,
    this.category,
    this.equipment,
    this.imageUrl,
    this.gifUrl,
  });

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    String? category;
    String? equipment;
    String? imageUrl;
    String? gifUrl;

    if (json['alternatives'] is Map<String, dynamic>) {
      final alt = json['alternatives'] as Map<String, dynamic>;
      category = alt['category'] as String?;
      equipment = alt['equipment'] as String?;
      imageUrl = alt['imageUrl'] as String?;
      gifUrl = alt['gifUrl'] as String?;
    }

    return ExerciseModel(
      id: json['id'] ?? 0,
      name: json['name'] as String? ?? 'Exercise',
      muscleGroup: json['muscleGroup'] as String? ?? 'General',
      instructions: json['instructions'] as String?,
      formTips: json['formTips'] as String?,
      category: category,
      equipment: equipment,
      imageUrl: imageUrl,
      gifUrl: gifUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'muscleGroup': muscleGroup,
      if (instructions != null) 'instructions': instructions,
      if (formTips != null) 'formTips': formTips,
      if (category != null) 'category': category,
      if (equipment != null) 'equipment': equipment,
    };
  }

  static List<ExerciseModel> get defaultExercises => [
        const ExerciseModel(
          id: 'bench-press-001',
          name: 'Barbell Bench Press',
          muscleGroup: 'Chest',
          equipment: 'Barbell',
          formTips: 'Keep shoulder blades retracted and elbows at 45 degrees.',
        ),
        const ExerciseModel(
          id: 'incline-dumbbell-press-002',
          name: 'Incline Dumbbell Press',
          muscleGroup: 'Chest',
          equipment: 'Dumbbell',
          formTips: 'Press upward and slightly inward, contracting upper chest.',
        ),
        const ExerciseModel(
          id: 'barbell-squat-003',
          name: 'Barbell Back Squat',
          muscleGroup: 'Legs',
          equipment: 'Barbell',
          formTips: 'Break at knees and hips simultaneously, maintain upright chest.',
        ),
        const ExerciseModel(
          id: 'romanian-deadlift-004',
          name: 'Romanian Deadlift',
          muscleGroup: 'Legs',
          equipment: 'Barbell',
          formTips: 'Push hips backward with soft knee bend until stretch in hamstrings.',
        ),
        const ExerciseModel(
          id: 'deadlift-barbell-005',
          name: 'Conventional Deadlift',
          muscleGroup: 'Back',
          equipment: 'Barbell',
          formTips: 'Engage lats and drive floor away through midfoot.',
        ),
        const ExerciseModel(
          id: 'pull-up-006',
          name: 'Pull-Up',
          muscleGroup: 'Back',
          equipment: 'Bodyweight',
          formTips: 'Pull chest toward bar while driving elbows down into ribs.',
        ),
        const ExerciseModel(
          id: 'overhead-press-007',
          name: 'Overhead Barbell Press',
          muscleGroup: 'Shoulders',
          equipment: 'Barbell',
          formTips: 'Brace glutes and core, press bar in straight vertical path.',
        ),
        const ExerciseModel(
          id: 'lateral-raise-008',
          name: 'Dumbbell Lateral Raise',
          muscleGroup: 'Shoulders',
          equipment: 'Dumbbell',
          formTips: 'Lead with elbows and avoid swinging momentum.',
        ),
        const ExerciseModel(
          id: 'barbell-curl-009',
          name: 'Barbell Biceps Curl',
          muscleGroup: 'Arms',
          equipment: 'Barbell',
          formTips: 'Keep elbows pinned to sides throughout range of motion.',
        ),
        const ExerciseModel(
          id: 'triceps-pushdown-010',
          name: 'Triceps Cable Pushdown',
          muscleGroup: 'Arms',
          equipment: 'Cable',
          formTips: 'Extend arms fully downward, squeezing triceps at lockout.',
        ),
        const ExerciseModel(
          id: 'hanging-leg-raise-011',
          name: 'Hanging Leg Raise',
          muscleGroup: 'Core',
          equipment: 'Bodyweight',
          formTips: 'Curl pelvis toward ribs rather than merely swinging legs.',
        ),
        const ExerciseModel(
          id: 'plank-012',
          name: 'Forearm Plank',
          muscleGroup: 'Core',
          equipment: 'Bodyweight',
          formTips: 'Squeeze glutes and create tension throughout posterior chain.',
        ),
      ];
}
