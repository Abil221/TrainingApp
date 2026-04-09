class UserProgress {
  final String userName;
  final String fitnessLevel;
  final int height;
  final int weight;

  const UserProgress({
    this.userName = 'Атлет',
    this.fitnessLevel = 'Средний',
    this.height = 175,
    this.weight = 75,
  });

  double get bmi {
    final heightInMeters = height / 100;
    if (heightInMeters <= 0) {
      return 0;
    }

    return weight / (heightInMeters * heightInMeters);
  }

  UserProgress copyWith({
    String? userName,
    String? fitnessLevel,
    int? height,
    int? weight,
  }) {
    return UserProgress(
      userName: userName ?? this.userName,
      fitnessLevel: fitnessLevel ?? this.fitnessLevel,
      height: height ?? this.height,
      weight: weight ?? this.weight,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'display_name': userName,
      'fitness_level': fitnessLevel,
      'height': height,
      'weight': weight,
    };
  }

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    return UserProgress(
      userName: json['display_name'] as String? ?? 
                json['userName'] as String? ?? 'Атлет',
      fitnessLevel: json['fitness_level'] as String? ?? 
                    json['fitnessLevel'] as String? ?? 'Средний',
      height: json['height'] as int? ?? 175,
      weight: json['weight'] as int? ?? 75,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserProgress &&
        other.userName == userName &&
        other.fitnessLevel == fitnessLevel &&
        other.height == height &&
        other.weight == weight;
  }

  @override
  int get hashCode =>
      userName.hashCode ^
      fitnessLevel.hashCode ^
      height.hashCode ^
      weight.hashCode;
}
