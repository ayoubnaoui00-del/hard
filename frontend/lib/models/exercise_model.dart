import '../config/constants.dart';

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
  final List<String> alternativeNames;

  String? get videoUrl => gifUrl;

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
    this.alternativeNames = const [],
  });

  factory ExerciseModel.fromJson(Map<String, dynamic> json) {
    String? category;
    String? equipment;
    String? imageUrl;
    String? gifUrl;
    List<String> altNames = [];

    if (json['alternatives'] is Map<String, dynamic>) {
      final alt = json['alternatives'] as Map<String, dynamic>;
      category = alt['category'] as String?;
      equipment = alt['equipment'] as String?;
      imageUrl = alt['imageUrl'] as String?;
      gifUrl = alt['gifUrl'] as String? ?? alt['videoUrl'] as String?;
      if (alt['secondaryMuscles'] is List) {
        altNames = (alt['secondaryMuscles'] as List)
            .map((e) => e.toString())
            .toList();
      }
    } else if (json['alternatives'] is List) {
      altNames = (json['alternatives'] as List)
          .map((e) => e.toString())
          .toList();
    }

    final rawImage = json['imageUrl'] as String? ?? imageUrl;
    final rawGif = json['videoUrl'] as String? ?? json['gifUrl'] as String? ?? gifUrl;

    return ExerciseModel(
      id: json['id'] ?? 0,
      name: json['name'] as String? ?? 'Exercise',
      muscleGroup: json['muscleGroup'] as String? ?? 'General',
      instructions: json['instructions'] as String?,
      formTips: json['formTips'] as String?,
      category: category ?? json['category'] as String?,
      equipment: equipment ?? json['equipment'] as String?,
      imageUrl: AppConstants.resolveMediaUrl(rawImage),
      gifUrl: AppConstants.resolveMediaUrl(rawGif),
      alternativeNames: altNames,
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
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (gifUrl != null) 'gifUrl': gifUrl,
      if (gifUrl != null) 'videoUrl': gifUrl,
      if (alternativeNames.isNotEmpty) 'alternatives': alternativeNames,
    };
  }

  static List<ExerciseModel> get defaultExercises => [
        // Chest
        ExerciseModel(
          id: 'bench-press-001',
          name: 'Barbell Bench Press',
          muscleGroup: 'Chest',
          equipment: 'Barbell',
          category: 'Strength',
          imageUrl: AppConstants.resolveMediaUrl('/media/exercises/images/0025-EIeI8Vf.jpg'),
          gifUrl: AppConstants.resolveMediaUrl('/media/exercises/videos/0025-EIeI8Vf.gif'),
          instructions:
              'Lie back on a flat bench. Grip the bar slightly wider than shoulder width. Lower the bar smoothly to your mid-chest, pause briefly, then press explosively back to starting position.',
          formTips:
              'Retract shoulder blades, keep elbows tucked at ~45-60 degrees, and drive through heels.',
          alternativeNames: const ['Dumbbell Bench Press', 'Push-Up', 'Chest Dip'],
        ),
        ExerciseModel(
          id: 'incline-dumbbell-press-002',
          name: 'Incline Dumbbell Press',
          muscleGroup: 'Chest',
          equipment: 'Dumbbell',
          category: 'Hypertrophy',
          imageUrl: AppConstants.resolveMediaUrl('/media/exercises/images/0047-3TZduzM.jpg'),
          gifUrl: AppConstants.resolveMediaUrl('/media/exercises/videos/0047-3TZduzM.gif'),
          instructions:
              'Set bench to 30-45 degrees. Hold dumbbells at chest height with palms forward. Press dumbbells upward until arms are extended, bringing them slightly together at the top.',
          formTips:
              'Avoid excessively steep angles to prevent shifting tension to anterior deltoids.',
          alternativeNames: const ['Incline Barbell Press', 'Low-to-High Cable Fly'],
        ),
        ExerciseModel(
          id: 'cable-crossover-013',
          name: 'Cable Chest Fly',
          muscleGroup: 'Chest',
          equipment: 'Cable',
          category: 'Hypertrophy',
          imageUrl: AppConstants.resolveMediaUrl('/media/exercises/images/1375-yl2IYyy.jpg'),
          gifUrl: AppConstants.resolveMediaUrl('/media/exercises/videos/1375-yl2IYyy.gif'),
          instructions:
              'Stand centered between pulleys at shoulder height. Step forward into a staggered stance. Bring handles together in a hugging motion, squeezing pecs at full contraction.',
          formTips:
              'Maintain slight elbow bend throughout movement; do not turn it into a press.',
          alternativeNames: const ['Pec Deck Machine', 'Dumbbell Fly'],
        ),

        // Back
        ExerciseModel(
          id: 'deadlift-barbell-005',
          name: 'Conventional Deadlift',
          muscleGroup: 'Back',
          equipment: 'Barbell',
          category: 'Strength',
          imageUrl: AppConstants.resolveMediaUrl('/media/exercises/images/1009-kuMiR2T.jpg'),
          gifUrl: AppConstants.resolveMediaUrl('/media/exercises/videos/1009-kuMiR2T.gif'),
          instructions:
              'Stand with feet hip-width under bar. Hinge hips back, grip bar just outside knees. Brace core, engage lats, and push floor away to stand upright with locked hips.',
          formTips:
              'Keep the barbell in contact with shins and thighs throughout the entire pull.',
          alternativeNames: const ['Romanian Deadlift', 'Trap Bar Deadlift'],
        ),
        ExerciseModel(
          id: 'pull-up-006',
          name: 'Pull-Up',
          muscleGroup: 'Back',
          equipment: 'Bodyweight',
          category: 'Strength',
          imageUrl: AppConstants.resolveMediaUrl('/media/exercises/images/3293-72BC5Za.jpg'),
          gifUrl: AppConstants.resolveMediaUrl('/media/exercises/videos/3293-72BC5Za.gif'),
          instructions:
              'Hang from pull-up bar with overhand grip wider than shoulders. Depress scapulae and pull chest toward bar until chin clears bar. Lower under control.',
          formTips:
              'Drive elbows down and back into your back pockets; avoid swinging or kipping.',
          alternativeNames: const ['Lat Pulldown', 'Chin-Up', 'Banded Pull-Up'],
        ),
        ExerciseModel(
          id: 'bent-over-row-014',
          name: 'Barbell Bent-Over Row',
          muscleGroup: 'Back',
          equipment: 'Barbell',
          category: 'Strength',
          imageUrl: AppConstants.resolveMediaUrl('/media/exercises/images/0027-eZyBC3j.jpg'),
          gifUrl: AppConstants.resolveMediaUrl('/media/exercises/videos/0027-eZyBC3j.gif'),
          instructions:
              'Hinge hips at 45 degrees with neutral spine. Pull bar toward lower ribcage, squeezing shoulder blades together at apex. Lower with full lat stretch.',
          formTips:
              'Do not bounce your torso to gain momentum. Keep head neutral.',
          alternativeNames: const ['Dumbbell Row', 'T-Bar Row', 'Seated Cable Row'],
        ),

        // Shoulders
        ExerciseModel(
          id: 'overhead-press-007',
          name: 'Overhead Barbell Press',
          muscleGroup: 'Shoulders',
          equipment: 'Barbell',
          category: 'Strength',
          imageUrl: AppConstants.resolveMediaUrl('/media/exercises/images/3204-NAkmgdx.jpg'),
          gifUrl: AppConstants.resolveMediaUrl('/media/exercises/videos/3204-NAkmgdx.gif'),
          instructions:
              'Hold bar at clavicle level with pronated grip. Brace glutes and abs. Press bar straight overhead, moving head back then through the window as bar passes face.',
          formTips:
              'Keep ribs tucked down; avoid hyperextending the lower back.',
          alternativeNames: const ['Dumbbell Shoulder Press', 'Push Press'],
        ),
        ExerciseModel(
          id: 'lateral-raise-008',
          name: 'Dumbbell Lateral Raise',
          muscleGroup: 'Shoulders',
          equipment: 'Dumbbell',
          category: 'Hypertrophy',
          imageUrl: AppConstants.resolveMediaUrl('/media/exercises/images/0977-sTg7iys.jpg'),
          gifUrl: AppConstants.resolveMediaUrl('/media/exercises/videos/0977-sTg7iys.gif'),
          instructions:
              'Hold dumbbells at sides with slight forward lean. Raise arms out laterally until parallel with floor, leading with elbows. Lower slowly.',
          formTips:
              'Pour the pitcher slightly at peak, keep traps relaxed and focus on lateral delt.',
          alternativeNames: const ['Cable Lateral Raise', 'Machine Lateral Raise'],
        ),
        ExerciseModel(
          id: 'face-pull-015',
          name: 'Cable Face Pull',
          muscleGroup: 'Shoulders',
          equipment: 'Cable',
          category: 'Posture & Hypertrophy',
          imageUrl: AppConstants.resolveMediaUrl('/media/exercises/images/0075-Ln9iTbU.jpg'),
          gifUrl: AppConstants.resolveMediaUrl('/media/exercises/videos/0075-Ln9iTbU.gif'),
          instructions:
              'Attach rope to upper pulley. Pull handles toward ears with knuckles facing back, externally rotating shoulders at end range.',
          formTips:
              'Pause for 1 second at peak contraction to stimulate rear delts and rotator cuff.',
          alternativeNames: const ['Reverse Pec Deck', 'Rear Delt Dumbbell Fly'],
        ),

        // Arms
        ExerciseModel(
          id: 'barbell-curl-009',
          name: 'Barbell Biceps Curl',
          muscleGroup: 'Arms',
          equipment: 'Barbell',
          category: 'Hypertrophy',
          imageUrl: AppConstants.resolveMediaUrl('/media/exercises/images/0968-3omWx6P.jpg'),
          gifUrl: AppConstants.resolveMediaUrl('/media/exercises/videos/0968-3omWx6P.gif'),
          instructions:
              'Stand upright holding bar with supinated grip shoulder-width apart. Curl bar upward while keeping elbows pinned at sides. Squeeze at top and control eccentric.',
          formTips:
              'Avoid swinging hips or leaning back to hoist weight.',
          alternativeNames: const ['Dumbbell Bicep Curl', 'EZ-Bar Preacher Curl', 'Hammer Curl'],
        ),
        ExerciseModel(
          id: 'triceps-pushdown-010',
          name: 'Triceps Cable Pushdown',
          muscleGroup: 'Arms',
          equipment: 'Cable',
          category: 'Hypertrophy',
          imageUrl: AppConstants.resolveMediaUrl('/media/exercises/images/0172-1PK5Uo3.jpg'),
          gifUrl: AppConstants.resolveMediaUrl('/media/exercises/videos/0172-1PK5Uo3.gif'),
          instructions:
              'Hold rope or straight bar at upper chest level. Keep upper arms glued to torso. Push downward by straightening elbows until arms are fully extended.',
          formTips:
              'Spread the rope ends apart at lockout for maximum lateral head contraction.',
          alternativeNames: const ['Skull Crusher', 'Overhead Tricep Extension', 'Close-Grip Bench Press'],
        ),
        ExerciseModel(
          id: 'hammer-curl-016',
          name: 'Dumbbell Hammer Curl',
          muscleGroup: 'Arms',
          equipment: 'Dumbbell',
          category: 'Hypertrophy',
          imageUrl: AppConstants.resolveMediaUrl('/media/exercises/images/0165-HPlPoQA.jpg'),
          gifUrl: AppConstants.resolveMediaUrl('/media/exercises/videos/0165-HPlPoQA.gif'),
          instructions:
              'Hold dumbbells with neutral palms facing each other. Curl dumbbells toward shoulders while maintaining neutral grip to target brachialis.',
          formTips:
              'Keep wrists firm and perform reps smoothly without swinging.',
          alternativeNames: const ['Rope Cable Hammer Curl', 'Reverse Barbell Curl'],
        ),

        // Legs
        ExerciseModel(
          id: 'barbell-squat-003',
          name: 'Barbell Back Squat',
          muscleGroup: 'Legs',
          equipment: 'Barbell',
          category: 'Strength',
          imageUrl: AppConstants.resolveMediaUrl('/media/exercises/images/0987-arsYEd3.jpg'),
          gifUrl: AppConstants.resolveMediaUrl('/media/exercises/videos/0987-arsYEd3.gif'),
          instructions:
              'Rest bar across upper traps. Unrack and set feet shoulder-width apart, toes flared slightly. Descend by bending hips and knees until thighs pass parallel. Drive upward.',
          formTips:
              'Keep knees tracking over toes and maintain upright, proud chest.',
          alternativeNames: const ['Front Squat', 'Goblet Squat', 'Leg Press'],
        ),
        ExerciseModel(
          id: 'romanian-deadlift-004',
          name: 'Romanian Deadlift',
          muscleGroup: 'Legs',
          equipment: 'Barbell',
          category: 'Strength',
          imageUrl: AppConstants.resolveMediaUrl('/media/exercises/images/0085-wQ2c4XD.jpg'),
          gifUrl: AppConstants.resolveMediaUrl('/media/exercises/videos/0085-wQ2c4XD.gif'),
          instructions:
              'Hold bar at hip level with slight knee bend. Push hips back while keeping spine neutral, lowering bar along thighs until deep hamstring stretch. Squeeze glutes to return.',
          formTips:
              'Do not bend knees further as you descend; hinge solely at the hips.',
          alternativeNames: const ['Dumbbell RDL', 'Seated Leg Curl', 'Good Morning'],
        ),
        ExerciseModel(
          id: 'standing-calf-raise-017',
          name: 'Standing Calf Raise',
          muscleGroup: 'Legs',
          equipment: 'Machine',
          category: 'Hypertrophy',
          imageUrl: AppConstants.resolveMediaUrl('/media/exercises/images/0999-9JprnPh.jpg'),
          gifUrl: AppConstants.resolveMediaUrl('/media/exercises/videos/0999-9JprnPh.gif'),
          instructions:
              'Place balls of feet on platform edge with heels hanging low. Rise onto toes as high as possible, holding peak for 1 second. Lower into full stretch.',
          formTips:
              'Do not bounce at the bottom; pause to eliminate Achilles tendon recoil.',
          alternativeNames: const ['Seated Calf Raise', 'Leg Press Calf Press'],
        ),

        // Core
        ExerciseModel(
          id: 'hanging-leg-raise-011',
          name: 'Hanging Leg Raise',
          muscleGroup: 'Core',
          equipment: 'Bodyweight',
          category: 'Strength',
          imageUrl: AppConstants.resolveMediaUrl('/media/exercises/images/0472-I3tsCnC.jpg'),
          gifUrl: AppConstants.resolveMediaUrl('/media/exercises/videos/0472-I3tsCnC.gif'),
          instructions:
              'Hang from bar with overhand grip. Engage lats and curl pelvis upward, raising legs until parallel to ground or higher. Lower slowly without swinging.',
          formTips:
              'Focus on posterior pelvic tilt (curling pelvis) rather than just hip flexion.',
          alternativeNames: const ['Captain\'s Chair Leg Raise', 'Lying Leg Raise'],
        ),
        ExerciseModel(
          id: 'plank-012',
          name: 'Forearm Plank',
          muscleGroup: 'Core',
          equipment: 'Bodyweight',
          category: 'Endurance',
          imageUrl: AppConstants.resolveMediaUrl('/media/exercises/images/3544-5VXmnV5.jpg'),
          gifUrl: AppConstants.resolveMediaUrl('/media/exercises/videos/3544-5VXmnV5.gif'),
          instructions:
              'Rest on forearms and toes. Maintain straight line from head to heels. Contract abs, glutes, and quads to hold rigid isometric posture.',
          formTips:
              'Do not let hips sag or hike into the air. Breathe rhythmically.',
          alternativeNames: const ['Ab Wheel Rollout', 'Pallof Press', 'Side Plank'],
        ),
      ];
}
