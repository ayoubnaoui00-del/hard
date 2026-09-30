class FriendActivityModel {
  final int id;
  final String username;
  final String? avatarUrl;
  final String activityType; // e.g., 'WORKOUT', 'PR', 'ACHIEVEMENT'
  final String title;
  final String description;
  final String timeAgo;
  final int likesCount;
  final bool isLiked;

  const FriendActivityModel({
    required this.id,
    required this.username,
    this.avatarUrl,
    required this.activityType,
    required this.title,
    required this.description,
    required this.timeAgo,
    this.likesCount = 0,
    this.isLiked = false,
  });

  factory FriendActivityModel.fromJson(Map<String, dynamic> json) {
    return FriendActivityModel(
      id: json['id'] as int? ?? 0,
      username: json['username'] as String? ?? 'Athlete',
      avatarUrl: json['avatarUrl'] as String?,
      activityType: json['activityType'] as String? ?? 'WORKOUT',
      title: json['title'] as String? ?? 'Completed Workout',
      description: json['description'] as String? ?? '',
      timeAgo: json['timeAgo'] as String? ?? 'Recently',
      likesCount: json['likesCount'] as int? ?? 0,
      isLiked: json['isLiked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      'activityType': activityType,
      'title': title,
      'description': description,
      'timeAgo': timeAgo,
      'likesCount': likesCount,
      'isLiked': isLiked,
    };
  }

  FriendActivityModel copyWith({
    int? id,
    String? username,
    String? avatarUrl,
    String? activityType,
    String? title,
    String? description,
    String? timeAgo,
    int? likesCount,
    bool? isLiked,
  }) {
    return FriendActivityModel(
      id: id ?? this.id,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      activityType: activityType ?? this.activityType,
      title: title ?? this.title,
      description: description ?? this.description,
      timeAgo: timeAgo ?? this.timeAgo,
      likesCount: likesCount ?? this.likesCount,
      isLiked: isLiked ?? this.isLiked,
    );
  }

  static List<FriendActivityModel> get sampleActivities => [
        const FriendActivityModel(
          id: 1,
          username: 'Alex Miller',
          activityType: 'PR',
          title: 'New PR on Bench Press',
          description: 'Pushed 105 kg x 4 reps! Felt smooth 🔥',
          timeAgo: '25m ago',
          likesCount: 14,
          isLiked: true,
        ),
        const FriendActivityModel(
          id: 2,
          username: 'Sarah Connor',
          activityType: 'WORKOUT',
          title: 'Crushed Leg Day Destruction',
          description: '5 exercises • 6,400 kg total volume 🏋️‍♀️',
          timeAgo: '2h ago',
          likesCount: 8,
          isLiked: false,
        ),
        const FriendActivityModel(
          id: 3,
          username: 'Marcus Vance',
          activityType: 'ACHIEVEMENT',
          title: 'Unlocked "Iron Habit" Badge',
          description: 'Completed 10 consecutive logged workouts ⭐',
          timeAgo: '4h ago',
          likesCount: 19,
          isLiked: true,
        ),
        const FriendActivityModel(
          id: 4,
          username: 'Elena Rostova',
          activityType: 'WORKOUT',
          title: 'Back & Biceps Hypertrophy',
          description: 'Deadlifts felt easy today • 4,850 kg volume',
          timeAgo: '6h ago',
          likesCount: 5,
          isLiked: false,
        ),
        const FriendActivityModel(
          id: 5,
          username: 'David Chen',
          activityType: 'PR',
          title: 'Barbell Squat Record',
          description: '140 kg x 5 reps! Road to 150 kg begins',
          timeAgo: 'Yesterday',
          likesCount: 22,
          isLiked: false,
        ),
      ];
}
