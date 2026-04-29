import 'workout.dart';

class WorkoutPlan {
  final String id;
  final String userId;
  final String name;
  final String description;
  final int durationWeeks;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<WorkoutPlanDay>? days;

  const WorkoutPlan({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.durationWeeks,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.days,
  });

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) {
    return WorkoutPlan(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      durationWeeks: json['duration_weeks'] as int? ?? 4,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      days: (json['workout_plan_days'] as List<dynamic>?)
          ?.map((e) => WorkoutPlanDay.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'description': description,
      'duration_weeks': durationWeeks,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  WorkoutPlan copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    int? durationWeeks,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<WorkoutPlanDay>? days,
  }) {
    return WorkoutPlan(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      durationWeeks: durationWeeks ?? this.durationWeeks,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      days: days ?? this.days,
    );
  }
}

class WorkoutPlanDay {
  final String id;
  final String planId;
  final int dayOfWeek;
  final String workoutId;
  final int orderInDay;
  final DateTime createdAt;
  final Workout? workout;

  const WorkoutPlanDay({
    required this.id,
    required this.planId,
    required this.dayOfWeek,
    required this.workoutId,
    required this.orderInDay,
    required this.createdAt,
    this.workout,
  });

  String get dayName {
    final days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    return days[dayOfWeek];
  }

  factory WorkoutPlanDay.fromJson(Map<String, dynamic> json) {
    return WorkoutPlanDay(
      id: json['id'] as String,
      planId: json['plan_id'] as String,
      dayOfWeek: json['day_of_week'] as int,
      workoutId: json['workout_id'] as String,
      orderInDay: json['order_in_day'] as int? ?? 1,
      createdAt: DateTime.parse(json['created_at'] as String),
      workout: json['workouts'] != null
          ? Workout.fromJson(json['workouts'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'plan_id': planId,
      'day_of_week': dayOfWeek,
      'workout_id': workoutId,
      'order_in_day': orderInDay,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
