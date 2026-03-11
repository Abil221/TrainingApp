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
