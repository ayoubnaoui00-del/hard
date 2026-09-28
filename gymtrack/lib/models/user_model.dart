class UserModel {
  final int id;
  final String username;
  final String email;
  final String role;
  final int xp;
  final int streak;
  final int level;
  final String? avatarUrl;

  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.role = 'user',
    this.xp = 0,
    this.streak = 0,
    this.level = 1,
    this.avatarUrl,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'user',
      xp: json['xp'] as int? ?? 0,
      streak: json['streak'] as int? ?? 0,
      level: json['level'] as int? ?? 1,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'role': role,
      'xp': xp,
      'streak': streak,
      'level': level,
      'avatarUrl': avatarUrl,
    };
  }
}
