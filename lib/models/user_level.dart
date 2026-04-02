class UserLevel {
  final String userId;
  final int currentLevel;
  final int totalXp;
  final int xpForNextLevel;
  final DateTime updatedAt;

  const UserLevel({
    required this.userId,
    required this.currentLevel,
    required this.totalXp,
    required this.xpForNextLevel,
    required this.updatedAt,
  });

  double get progressToNextLevel {
    final xpInCurrentLevel = totalXp - _getXpForLevel(currentLevel);
    final xpNeededForLevel = xpForNextLevel;
    
    if (xpNeededForLevel <= 0) return 0.0;
    return (xpInCurrentLevel / xpNeededForLevel).clamp(0.0, 1.0);
  }

  int get nextLevelXpRequired => xpForNextLevel;

  factory UserLevel.fromJson(Map<String, dynamic> json) {
    return UserLevel(
      userId: json['user_id'] as String,
      currentLevel: json['current_level'] as int,
      totalXp: json['total_xp'] as int? ?? 0,
      xpForNextLevel: json['xp_for_next_level'] as int? ?? 1000,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  static int _getXpForLevel(int level) {
    // Квадратическая прогрессия: 1000, 3000, 6000, 10000 XP
    return 1000 * ((level - 1) * (level - 1) + (level - 1)) ~/ 2;
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'current_level': currentLevel,
      'total_xp': totalXp,
      'xp_for_next_level': xpForNextLevel,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserLevel copyWith({
    String? userId,
    int? currentLevel,
    int? totalXp,
    int? xpForNextLevel,
    DateTime? updatedAt,
  }) {
    return UserLevel(
      userId: userId ?? this.userId,
      currentLevel: currentLevel ?? this.currentLevel,
      totalXp: totalXp ?? this.totalXp,
      xpForNextLevel: xpForNextLevel ?? this.xpForNextLevel,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
