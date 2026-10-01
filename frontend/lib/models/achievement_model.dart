class AchievementModel {
  final dynamic id;
  final String code;
  final String name;
  final String description;
  final String badgeIcon;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  const AchievementModel({
    this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.badgeIcon,
    this.isUnlocked = false,
    this.unlockedAt,
  });

  factory AchievementModel.fromJson(Map<String, dynamic> json) {
    return AchievementModel(
      id: json['id'],
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? 'Achievement',
      description: json['description'] as String? ?? '',
      badgeIcon: json['badgeIcon'] as String? ?? 'trophy',
      isUnlocked: json['isUnlocked'] as bool? ?? (json['unlockedAt'] != null),
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.tryParse(json['unlockedAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'code': code,
      'name': name,
      'description': description,
      'badgeIcon': badgeIcon,
      'isUnlocked': isUnlocked,
      if (unlockedAt != null) 'unlockedAt': unlockedAt!.toIso8601String(),
    };
  }

  AchievementModel copyWith({
    dynamic id,
    String? code,
    String? name,
    String? description,
    String? badgeIcon,
    bool? isUnlocked,
    DateTime? unlockedAt,
  }) {
    return AchievementModel(
      id: id ?? this.id,
      code: code ?? this.code,
      name: name ?? this.name,
      description: description ?? this.description,
      badgeIcon: badgeIcon ?? this.badgeIcon,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }

  /// Default badges to show when user has not yet unlocked 3 achievements
  static List<AchievementModel> get sampleAchievements => [
        AchievementModel(
          code: 'WORKOUT_1',
          name: 'First Step',
          description: 'Completed your very first logged workout.',
          badgeIcon: 'footsteps',
          isUnlocked: true,
          unlockedAt: DateTime.now().subtract(const Duration(days: 2)),
        ),
        AchievementModel(
          code: 'STREAK_3',
          name: 'Weekend Warrior',
          description: 'Maintained a 3-day active streak.',
          badgeIcon: 'lightning',
          isUnlocked: true,
          unlockedAt: DateTime.now().subtract(const Duration(days: 1)),
        ),
        AchievementModel(
          code: 'VOLUME_1000',
          name: 'Heavy Lifter',
          description: 'Lifted over 1,000 kg total volume in a session.',
          badgeIcon: 'fire',
          isUnlocked: true,
          unlockedAt: DateTime.now(),
        ),
      ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AchievementModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          code == other.code &&
          name == other.name &&
          description == other.description &&
          badgeIcon == other.badgeIcon &&
          isUnlocked == other.isUnlocked &&
          unlockedAt == other.unlockedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      code.hashCode ^
      name.hashCode ^
      description.hashCode ^
      badgeIcon.hashCode ^
      isUnlocked.hashCode ^
      unlockedAt.hashCode;
}
