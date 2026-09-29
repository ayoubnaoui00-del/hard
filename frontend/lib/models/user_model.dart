class UserModel {
  final int id;
  final String username;
  final String email;
  final String role;
  final int xp;
  final int streak;
  final int level;
  final String? avatarUrl;

  final int totalXp;

  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.role = 'user',
    this.xp = 0,
    this.totalXp = 0,
    this.streak = 0,
    this.level = 1,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final xpVal = json['xp'] as int? ?? json['currentXp'] as int? ?? 0;
    final totalXpVal = json['totalXp'] as int? ?? xpVal;
    return UserModel(
      id: json['id'] as int,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'user',
      xp: xpVal,
      totalXp: totalXpVal,
      streak: json['streak'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  UserModel copyWith({
    int? id,
    String? username,
    String? email,
    String? role,
    int? xp,
    int? totalXp,
    int? streak,
    int? level,
    String? avatarUrl,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      xp: xp ?? this.xp,
      totalXp: totalXp ?? this.totalXp,
      streak: streak ?? this.streak,
      level: level ?? this.level,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'role': role,
      'xp': xp,
      'totalXp': totalXp,
      'streak': streak,
      'level': level,
      'avatarUrl': avatarUrl,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          username == other.username &&
          email == other.email &&
          role == other.role &&
          xp == other.xp &&
          totalXp == other.totalXp &&
          streak == other.streak &&
          level == other.level &&
          avatarUrl == other.avatarUrl;

  @override
  int get hashCode =>
      id.hashCode ^
      username.hashCode ^
      email.hashCode ^
      role.hashCode ^
      xp.hashCode ^
      totalXp.hashCode ^
      streak.hashCode ^
      level.hashCode ^
      avatarUrl.hashCode;
}
