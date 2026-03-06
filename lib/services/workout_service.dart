import '../models/workout.dart';

class WorkoutService {
  static final WorkoutService _instance = WorkoutService._internal();

  factory WorkoutService() {
    return _instance;
  }

  WorkoutService._internal();

  final List<Workout> _workouts = [
    Workout(
      id: '1',
      title: 'Push Ups',
      description: '3x15',
      duration: 60,
      image: 'assets/pushups.jpg',
      category: 'Strength',
      difficulty: DifficultyLevel.easy,
      caloriesBurned: 50,
      equipment: const ['None'],
      instructions: 'Keep your body straight. Lower yourself until chest nearly touches floor.',
      isFavorite: false,
    ),
    Workout(
      id: '2',
      title: 'Squats',
      description: '3x20',
      duration: 90,
      image: 'assets/squats.jpg',
      category: 'Strength',
      difficulty: DifficultyLevel.medium,
      caloriesBurned: 75,
      equipment: const ['None'],
      instructions: 'Keep chest up and knees behind toes. Lower until thighs are parallel to ground.',
      isFavorite: false,
    ),
    Workout(
      id: '3',
      title: 'Running',
      description: '10 min',
      duration: 600,
      image: 'assets/running.png',
      category: 'Cardio',
      difficulty: DifficultyLevel.medium,
      caloriesBurned: 150,
      equipment: const ['Running shoes'],
      instructions: 'Maintain steady pace. Keep your body relaxed.',
      isFavorite: false,
    ),
    Workout(
      id: '4',
      title: 'Plank',
      description: '60 sec',
      duration: 60,
      image: 'assets/plank.jpg',
      category: 'Flexibility',
      difficulty: DifficultyLevel.easy,
      caloriesBurned: 40,
      equipment: const ['Mat'],
      instructions: 'Hold a straight line from head to heels. Engage your core.',
      isFavorite: false,
    ),
    Workout(
      id: '5',
      title: 'Burpees',
      description: '3x10',
      duration: 120,
      image: 'assets/burpees.jpg',
      category: 'Cardio',
      difficulty: DifficultyLevel.hard,
      caloriesBurned: 120,
      equipment: const ['None'],
      instructions: 'Jump back, drop, do push-up, jump forward, jump up.',
      isFavorite: false,
    ),
    Workout(
      id: '6',
      title: 'Yoga Flow',
      description: '30 min',
      duration: 1800,
      image: 'assets/yoga.jpg',
      category: 'Flexibility',
      difficulty: DifficultyLevel.easy,
      caloriesBurned: 100,
      equipment: const ['Mat'],
      instructions: 'Follow the sequence at your own pace. Focus on breathing.',
      isFavorite: false,
    ),
  ];

  // Get all workouts
  List<Workout> getAllWorkouts() => List.from(_workouts);

  // Get workouts by category
  List<Workout> getWorkoutsByCategory(String category) {
    return _workouts.where((w) => w.category == category).toList();
  }

  // Get favorites
  List<Workout> getFavorites() {
    return _workouts.where((w) => w.isFavorite).toList();
  }

  // Toggle favorite
  void toggleFavorite(String id) {
    final index = _workouts.indexWhere((w) => w.id == id);
    if (index != -1) {
      _workouts[index] =
          _workouts[index].copyWith(isFavorite: !_workouts[index].isFavorite);
    }
  }

  // Search workouts
  List<Workout> searchWorkouts(String query) {
    return _workouts
        .where((w) =>
            w.title.toLowerCase().contains(query.toLowerCase()) ||
            w.category.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }

  // Get workout by ID
  Workout? getWorkoutById(String id) {
    try {
      return _workouts.firstWhere((w) => w.id == id);
    } catch (_) {
      return null;
    }
  }

  // Mark workout as completed
  void markAsCompleted(String id) {
    final index = _workouts.indexWhere((w) => w.id == id);
    if (index != -1) {
      _workouts[index] = _workouts[index].copyWith(
        completedCount: _workouts[index].completedCount + 1,
      );
    }
  }

  // Get total stats
  Map<String, int> getStats() {
    int totalWorkouts = _workouts.fold(0, (sum, w) => sum + w.completedCount);
    int totalCalories =
        _workouts.fold(0, (sum, w) => sum + (w.caloriesBurned * w.completedCount));
    int totalDuration =
        _workouts.fold(0, (sum, w) => sum + (w.duration * w.completedCount));
    return {
      'totalWorkouts': totalWorkouts,
      'totalCalories': totalCalories,
      'totalDuration': totalDuration,
    };
  }
}
