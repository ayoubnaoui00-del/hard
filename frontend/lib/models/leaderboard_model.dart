class LeaderboardEntryModel {
  final int userId;
  final String username;
  final int rank;
  final int level;
  final int totalXp;
  final int weeklyXp;
  final String? avatarUrl;

  const LeaderboardEntryModel({
    required this.userId,
    required this.username,
    required this.rank,
    this.level = 1,
    this.totalXp = 0,
    this.weeklyXp = 0,
    this.avatarUrl,
  });

  factory LeaderboardEntryModel.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntryModel(
      userId: json['userId'] as int? ?? json['id'] as int? ?? 0,
      username: json['username'] as String? ?? 'Athlete',
      rank: json['rank'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      totalXp: json['totalXp'] as int? ?? json['xp'] as int? ?? 0,
      weeklyXp: json['weeklyXp'] as int? ?? 0,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'rank': rank,
      'level': level,
      'totalXp': totalXp,
      'weeklyXp': weeklyXp,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
    };
  }

  LeaderboardEntryModel copyWith({
    int? userId,
    String? username,
    int? rank,
    int? level,
    int? totalXp,
    int? weeklyXp,
    String? avatarUrl,
  }) {
    return LeaderboardEntryModel(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      rank: rank ?? this.rank,
      level: level ?? this.level,
      totalXp: totalXp ?? this.totalXp,
      weeklyXp: weeklyXp ?? this.weeklyXp,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeaderboardEntryModel &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          rank == other.rank &&
          totalXp == other.totalXp &&
          weeklyXp == other.weeklyXp;

  @override
  int get hashCode =>
      userId.hashCode ^ rank.hashCode ^ totalXp.hashCode ^ weeklyXp.hashCode;
}
