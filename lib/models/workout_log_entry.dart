class WorkoutLogEntry {
  final String id;
  final String workoutId;
  final DateTime completedAt;
  final int durationSeconds;
  final int caloriesBurned;
  final double? progressValue;
  final String progressUnit;
  final String resultNote;

  const WorkoutLogEntry({
    required this.id,
    required this.workoutId,
    required this.completedAt,
    required this.durationSeconds,
    required this.caloriesBurned,
    this.progressValue,
    this.progressUnit = '',
    this.resultNote = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workoutId': workoutId,
      'completedAt': completedAt.toIso8601String(),
      'durationSeconds': durationSeconds,
      'caloriesBurned': caloriesBurned,
      'progressValue': progressValue,
      'progressUnit': progressUnit,
      'resultNote': resultNote,
    };
  }

  factory WorkoutLogEntry.fromJson(Map<String, dynamic> json) {
    return WorkoutLogEntry(
      id: json['id'] as String,
      workoutId: json['workoutId'] as String,
      completedAt: DateTime.parse(json['completedAt'] as String),
      durationSeconds: json['durationSeconds'] as int? ?? 0,
      caloriesBurned: json['caloriesBurned'] as int? ?? 0,
      progressValue: (json['progressValue'] as num?)?.toDouble(),
      progressUnit: json['progressUnit'] as String? ?? '',
      resultNote: json['resultNote'] as String? ?? '',
    );
  }
}
