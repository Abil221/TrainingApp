enum GoalType {
  weightLoss('weight_loss', 'Снижение веса'),
  muscleGain('muscle_gain', 'Набор мышц'),
  endurance('endurance', 'Выносливость'),
  strength('strength', 'Сила'),
  flexibility('flexibility', 'Гибкость');

  final String value;
  final String displayName;

  const GoalType(this.value, this.displayName);

  factory GoalType.fromString(String value) {
    return GoalType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => GoalType.weightLoss,
    );
  }
}

class UserGoal {
  final String id;
  final String userId;
  final GoalType goalType;
  final String name;
  final String description;
  final double targetValue;
  final double currentValue;
  final String unit;
  final DateTime deadline;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserGoal({
    required this.id,
    required this.userId,
    required this.goalType,
    required this.name,
    required this.description,
    required this.targetValue,
    required this.currentValue,
    required this.unit,
    required this.deadline,
    required this.isCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  double get progress {
    final diff = (targetValue - currentValue).abs();
    final totalDiff = (targetValue - (targetValue - diff)).abs();
    return (diff / totalDiff).clamp(0.0, 1.0);
  }

  int get daysRemaining {
    return deadline.difference(DateTime.now()).inDays;
  }

  bool get isOverdue => !isCompleted && daysRemaining < 0;

  factory UserGoal.fromJson(Map<String, dynamic> json) {
    return UserGoal(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      goalType: GoalType.fromString(json['goal_type'] as String),
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      targetValue: double.parse(json['target_value'].toString()),
      currentValue: double.parse(json['current_value'].toString()),
      unit: json['unit'] as String,
      deadline: DateTime.parse(json['deadline'] as String),
      isCompleted: json['is_completed'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'goal_type': goalType.value,
      'name': name,
      'description': description,
      'target_value': targetValue,
      'current_value': currentValue,
      'unit': unit,
      'deadline': deadline.toIso8601String(),
      'is_completed': isCompleted,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  UserGoal copyWith({
    String? id,
    String? userId,
    GoalType? goalType,
    String? name,
    String? description,
    double? targetValue,
    double? currentValue,
    String? unit,
    DateTime? deadline,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserGoal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      goalType: goalType ?? this.goalType,
      name: name ?? this.name,
      description: description ?? this.description,
      targetValue: targetValue ?? this.targetValue,
      currentValue: currentValue ?? this.currentValue,
      unit: unit ?? this.unit,
      deadline: deadline ?? this.deadline,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
