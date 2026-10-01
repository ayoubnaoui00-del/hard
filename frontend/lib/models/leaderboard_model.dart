class LeaderboardEntryModel {
  final dynamic userId;
  final String username;
  final int rank;
  final int level;
  final int streak;
  final int totalVolume;
  final int weeklyVolume;
  final int totalXp;
  final int weeklyXp;
  final String? avatarUrl;
  final bool isCurrentUser;

  const LeaderboardEntryModel({
    required this.userId,
    required this.username,
    required this.rank,
    this.level = 1,
    this.streak = 0,
    this.totalVolume = 0,
    this.weeklyVolume = 0,
    this.totalXp = 0,
    this.weeklyXp = 0,
    this.avatarUrl,
    this.isCurrentUser = false,
  });

  factory LeaderboardEntryModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val, int defaultVal) {
      if (val == null) return defaultVal;
      if (val is int) return val;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? defaultVal;
      return defaultVal;
    }

    String? parsedUsername;
    int? nestedLevel;
    int? nestedStreak;
    dynamic nestedUserId;
    if (json['user'] is Map<String, dynamic>) {
      final u = json['user'] as Map<String, dynamic>;
      parsedUsername = u['username'] as String?;
      nestedLevel = u['level'] as int?;
      nestedStreak = u['streak'] as int?;
      nestedUserId = u['id'];
    }

    final parsedTotalVolume = parseInt(json['totalVolume'] ?? json['totalXp'] ?? json['xp'], 0);
    final parsedWeeklyVolume = parseInt(json['weeklyVolume'] ?? json['weeklyXp'], 0);

    return LeaderboardEntryModel(
      userId: json['userId'] ?? json['id'] ?? nestedUserId ?? '',
      username: json['username'] as String? ?? parsedUsername ?? 'Athlete',
      rank: parseInt(json['rank'], 0),
      level: parseInt(json['level'] ?? nestedLevel, 1),
      streak: parseInt(json['streak'] ?? nestedStreak, 0),
      totalVolume: parsedTotalVolume,
      weeklyVolume: parsedWeeklyVolume,
      totalXp: parseInt(json['totalXp'] ?? json['xp'] ?? parsedTotalVolume, 0),
      weeklyXp: parseInt(json['weeklyXp'] ?? parsedWeeklyVolume, 0),
      avatarUrl: json['avatarUrl'] as String?,
      isCurrentUser: json['isCurrentUser'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'rank': rank,
      'level': level,
      'streak': streak,
      'totalVolume': totalVolume,
      'weeklyVolume': weeklyVolume,
      'totalXp': totalXp,
      'weeklyXp': weeklyXp,
      if (avatarUrl != null) 'avatarUrl': avatarUrl,
      'isCurrentUser': isCurrentUser,
    };
  }

  LeaderboardEntryModel copyWith({
    dynamic userId,
    String? username,
    int? rank,
    int? level,
    int? streak,
    int? totalVolume,
    int? weeklyVolume,
    int? totalXp,
    int? weeklyXp,
    String? avatarUrl,
    bool? isCurrentUser,
  }) {
    return LeaderboardEntryModel(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      rank: rank ?? this.rank,
      level: level ?? this.level,
      streak: streak ?? this.streak,
      totalVolume: totalVolume ?? this.totalVolume,
      weeklyVolume: weeklyVolume ?? this.weeklyVolume,
      totalXp: totalXp ?? this.totalXp,
      weeklyXp: weeklyXp ?? this.weeklyXp,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LeaderboardEntryModel &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          rank == other.rank &&
          totalVolume == other.totalVolume &&
          weeklyVolume == other.weeklyVolume &&
          totalXp == other.totalXp &&
          weeklyXp == other.weeklyXp;

  @override
  int get hashCode =>
      userId.hashCode ^ rank.hashCode ^ totalVolume.hashCode ^ weeklyVolume.hashCode ^ totalXp.hashCode ^ weeklyXp.hashCode;
}
