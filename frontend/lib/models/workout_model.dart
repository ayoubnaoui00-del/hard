class WorkoutExerciseModel {
  final dynamic id;
  final dynamic workoutId;
  final dynamic exerciseId;
  final int sets;
  final int reps;
  final double weight;
  final int order;
  final String? exerciseName;
  final String? muscleGroup;

  const WorkoutExerciseModel({
    this.id,
    this.workoutId,
    required this.exerciseId,
    this.sets = 1,
    this.reps = 1,
    this.weight = 0.0,
    this.order = 1,
    this.exerciseName,
    this.muscleGroup,
  });

  double get volume => sets * reps * weight;

  factory WorkoutExerciseModel.fromJson(Map<String, dynamic> json) {
    String? exName;
    String? exMuscle;
    if (json['exercise'] is Map<String, dynamic>) {
      exName = json['exercise']['name'] as String?;
      exMuscle = json['exercise']['muscleGroup'] as String?;
    }

    return WorkoutExerciseModel(
      id: json['id'],
      workoutId: json['workoutId'],
      exerciseId: json['exerciseId'] ?? 0,
      sets: json['sets'] as int? ?? 1,
      reps: json['reps'] as int? ?? 1,
      weight: (json['weight'] as num?)?.toDouble() ?? 0.0,
      order: json['order'] as int? ?? 1,
      exerciseName: exName ?? json['exerciseName'] as String?,
      muscleGroup: exMuscle ?? json['muscleGroup'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (workoutId != null) 'workoutId': workoutId,
      'exerciseId': exerciseId,
      'sets': sets,
      'reps': reps,
      'weight': weight,
      'order': order,
      if (exerciseName != null) 'exerciseName': exerciseName,
      if (muscleGroup != null) 'muscleGroup': muscleGroup,
    };
  }

  WorkoutExerciseModel copyWith({
    dynamic id,
    dynamic workoutId,
    dynamic exerciseId,
    int? sets,
    int? reps,
    double? weight,
    int? order,
    String? exerciseName,
    String? muscleGroup,
  }) {
    return WorkoutExerciseModel(
      id: id ?? this.id,
      workoutId: workoutId ?? this.workoutId,
      exerciseId: exerciseId ?? this.exerciseId,
      sets: sets ?? this.sets,
      reps: reps ?? this.reps,
      weight: weight ?? this.weight,
      order: order ?? this.order,
      exerciseName: exerciseName ?? this.exerciseName,
      muscleGroup: muscleGroup ?? this.muscleGroup,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutExerciseModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          workoutId == other.workoutId &&
          exerciseId == other.exerciseId &&
          sets == other.sets &&
          reps == other.reps &&
          weight == other.weight &&
          order == other.order;

  @override
  int get hashCode =>
      id.hashCode ^
      workoutId.hashCode ^
      exerciseId.hashCode ^
      sets.hashCode ^
      reps.hashCode ^
      weight.hashCode ^
      order.hashCode;
}

class WorkoutModel {
  final dynamic id;
  final dynamic userId;
  final String name;
  final DateTime date;
  final int duration; // in minutes or seconds
  final double totalVolume;
  final String? notes;
  final List<WorkoutExerciseModel> workoutExercises;
  final DateTime? createdAt;

  const WorkoutModel({
    required this.id,
    required this.userId,
    required this.name,
    required this.date,
    this.duration = 0,
    this.totalVolume = 0.0,
    this.notes,
    this.workoutExercises = const [],
    this.createdAt,
  });

  /// Calculates total volume (sets * reps * weight) across all exercises in this workout
  static double calculateVolume(List<WorkoutExerciseModel> exercises) {
    return exercises.fold(0.0, (sum, ex) => sum + ex.volume);
  }

  List<WorkoutExerciseModel> get exercises => workoutExercises;

  int get totalSets =>
      workoutExercises.fold(0, (sum, ex) => sum + ex.sets);

  int get totalReps =>
      workoutExercises.fold(0, (sum, ex) => sum + (ex.sets * ex.reps));

  factory WorkoutModel.fromJson(Map<String, dynamic> json) {
    final rawExercises = json['workoutExercises'] as List<dynamic>? ?? [];
    final exercises = rawExercises
        .map((e) => WorkoutExerciseModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return WorkoutModel(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      name: json['name'] as String? ?? 'Workout',
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      duration: json['duration'] as int? ?? 0,
      totalVolume: (json['totalVolume'] as num?)?.toDouble() ??
          calculateVolume(exercises),
      notes: json['notes'] as String?,
      workoutExercises: exercises,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'date': date.toIso8601String(),
      'duration': duration,
      'totalVolume': totalVolume,
      if (notes != null) 'notes': notes,
      'workoutExercises': workoutExercises.map((e) => e.toJson()).toList(),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  WorkoutModel copyWith({
    dynamic id,
    dynamic userId,
    String? name,
    DateTime? date,
    int? duration,
    double? totalVolume,
    String? notes,
    List<WorkoutExerciseModel>? workoutExercises,
    DateTime? createdAt,
  }) {
    return WorkoutModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      date: date ?? this.date,
      duration: duration ?? this.duration,
      totalVolume: totalVolume ?? this.totalVolume,
      notes: notes ?? this.notes,
      workoutExercises: workoutExercises ?? this.workoutExercises,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          userId == other.userId &&
          name == other.name &&
          date == other.date &&
          duration == other.duration &&
          totalVolume == other.totalVolume;

  @override
  int get hashCode =>
      id.hashCode ^
      userId.hashCode ^
      name.hashCode ^
      date.hashCode ^
      duration.hashCode ^
      totalVolume.hashCode;
}
