enum DifficultyLevel { easy, medium, hard }

class Workout {
  final String id;
  final String title;
  final String description;
  final int duration;
  final String image;
  final String category;
  final DifficultyLevel difficulty;
  final int caloriesBurned;
  final List<String> equipment;
  final String instructions;
  bool isFavorite;
  int completedCount;

  Workout({
    required this.id,
    required this.title,
    required this.description,
    required this.duration,
    required this.image,
    required this.category,
    this.difficulty = DifficultyLevel.medium,
    this.caloriesBurned = 100,
    this.equipment = const [],
    this.instructions = '',
    this.isFavorite = false,
    this.completedCount = 0,
  });

  String get difficultyString {
    switch (difficulty) {
      case DifficultyLevel.easy:
        return 'Легко';
      case DifficultyLevel.medium:
        return 'Средне';
      case DifficultyLevel.hard:
        return 'Сложно';
    }
  }

  factory Workout.fromJson(Map<String, dynamic> json) {
    DifficultyLevel diff;
    switch (json['difficulty'] as String? ?? 'medium') {
      case 'easy':
        diff = DifficultyLevel.easy;
      case 'hard':
        diff = DifficultyLevel.hard;
      default:
        diff = DifficultyLevel.medium;
    }
    return Workout(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      duration: json['duration_seconds'] as int? ?? 0,
      image: json['image_url'] as String? ?? '',
      category: json['category'] as String? ?? '',
      difficulty: diff,
      caloriesBurned: json['calories_burned'] as int? ?? 0,
      equipment: (json['equipment'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      instructions: json['instructions'] as String? ?? '',
    );
  }

  Workout copyWith({
    String? id,
    String? title,
    String? description,
    int? duration,
    String? image,
    String? category,
    DifficultyLevel? difficulty,
    int? caloriesBurned,
    List<String>? equipment,
    String? instructions,
    bool? isFavorite,
    int? completedCount,
  }) {
    return Workout(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      duration: duration ?? this.duration,
      image: image ?? this.image,
      category: category ?? this.category,
      difficulty: difficulty ?? this.difficulty,
      caloriesBurned: caloriesBurned ?? this.caloriesBurned,
      equipment: equipment ?? this.equipment,
      instructions: instructions ?? this.instructions,
      isFavorite: isFavorite ?? this.isFavorite,
      completedCount: completedCount ?? this.completedCount,
    );
  }
}
