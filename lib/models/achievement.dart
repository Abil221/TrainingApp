enum AchievementCriteria {
  totalWorkouts('total_workouts'),
  caloriesBurned('calories_burned'),
  streakDays('streak_days'),
  specificWorkout('specific_workout'),
  levelReached('level_reached');

  final String value;
  const AchievementCriteria(this.value);

  factory AchievementCriteria.fromString(String value) {
    return AchievementCriteria.values.firstWhere(
      (e) => e.value == value,
      orElse: () => AchievementCriteria.totalWorkouts,
    );
  }
}

class Achievement {
  final String id;
  final String name;
  final String description;
  final String iconName;
  final AchievementCriteria criteriaType;
  final int criteriaValue;
  final int rewardXp;
  final DateTime createdAt;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.iconName,
    required this.criteriaType,
    required this.criteriaValue,
    required this.rewardXp,
    required this.createdAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      iconName: json['icon_name'] as String,
      criteriaType: AchievementCriteria.fromString(json['criteria_type'] as String),
      criteriaValue: json['criteria_value'] as int? ?? 1,
      rewardXp: json['reward_xp'] as int? ?? 50,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon_name': iconName,
      'criteria_type': criteriaType.value,
      'criteria_value': criteriaValue,
      'reward_xp': rewardXp,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

class UserAchievement {
  final String id;
  final String userId;
  final String achievementId;
  final DateTime unlockedAt;
  final Achievement? achievement;

  const UserAchievement({
    required this.id,
    required this.userId,
    required this.achievementId,
    required this.unlockedAt,
    this.achievement,
  });

  factory UserAchievement.fromJson(Map<String, dynamic> json) {
    return UserAchievement(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      achievementId: json['achievement_id'] as String,
      unlockedAt: DateTime.parse(json['unlocked_at'] as String),
      achievement: json['achievements'] != null
          ? Achievement.fromJson(json['achievements'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'achievement_id': achievementId,
      'unlocked_at': unlockedAt.toIso8601String(),
    };
  }
}
