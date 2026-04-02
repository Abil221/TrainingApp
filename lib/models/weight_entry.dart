class WeightEntry {
  final String id;
  final String userId;
  final int weight;
  final DateTime recordedAt;
  final String? notes;

  const WeightEntry({
    required this.id,
    required this.userId,
    required this.weight,
    required this.recordedAt,
    this.notes,
  });

  factory WeightEntry.fromJson(Map<String, dynamic> json) {
    return WeightEntry(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      weight: json['weight'] as int,
      recordedAt: DateTime.parse(json['recorded_at'] as String),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'weight': weight,
      'recorded_at': recordedAt.toIso8601String(),
      'notes': notes,
    };
  }

  WeightEntry copyWith({
    String? id,
    String? userId,
    int? weight,
    DateTime? recordedAt,
    String? notes,
  }) {
    return WeightEntry(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      weight: weight ?? this.weight,
      recordedAt: recordedAt ?? this.recordedAt,
      notes: notes ?? this.notes,
    );
  }
}
