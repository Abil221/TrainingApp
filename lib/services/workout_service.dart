import '../models/workout.dart';

const List<String> _gymSplitGroups = [
  'Грудь',
  'Спина',
  'Ноги',
  'Плечи',
  'Руки',
];

class WorkoutService {
  static final WorkoutService _instance = WorkoutService._internal();

  factory WorkoutService() {
    return _instance;
  }

  WorkoutService._internal();

  final List<Workout> _workouts = [
    Workout(
      id: '1',
      title: 'Отжимания',
      description: '3x15',
      duration: 60,
      image: 'assets/pushups.jpg',
      category: 'Strength',
      difficulty: DifficultyLevel.easy,
      caloriesBurned: 50,
      equipment: const ['Без оборудования'],
      instructions:
          'Держи тело прямым. Опускайся вниз, пока грудь почти не коснется пола.',
      isFavorite: false,
    ),
    Workout(
      id: '2',
      title: 'Приседания',
      description: '3x20',
      duration: 90,
      image: 'assets/squats.jpg',
      category: 'Strength',
      difficulty: DifficultyLevel.medium,
      caloriesBurned: 75,
      equipment: const ['Без оборудования'],
      instructions:
          'Держи грудь раскрытой, а колени направляй по линии стоп. Опускайся до параллели бедер с полом.',
      isFavorite: false,
    ),
    Workout(
      id: '3',
      title: 'Бег',
      description: '10 мин',
      duration: 600,
      image: 'assets/running.png',
      category: 'Cardio',
      difficulty: DifficultyLevel.medium,
      caloriesBurned: 150,
      equipment: const ['Кроссовки'],
      instructions:
          'Держи ровный темп и расслабленные плечи. Дыши глубоко и стабильно.',
      isFavorite: false,
    ),
    Workout(
      id: '4',
      title: 'Планка',
      description: '60 сек',
      duration: 60,
      image: 'assets/plank.jpg',
      category: 'Flexibility',
      difficulty: DifficultyLevel.easy,
      caloriesBurned: 40,
      equipment: const ['Коврик'],
      instructions:
          'Сохраняй прямую линию от головы до пяток и держи пресс в напряжении.',
      isFavorite: false,
    ),
    Workout(
      id: '5',
      title: 'Берпи',
      description: '3x10',
      duration: 120,
      image: 'assets/burpees.jpg',
      category: 'Cardio',
      difficulty: DifficultyLevel.hard,
      caloriesBurned: 120,
      equipment: const ['Без оборудования'],
      instructions:
          'Уйди в упор лежа, сделай отжимание, вернись вперед и выпрыгни вверх.',
      isFavorite: false,
    ),
    Workout(
      id: '6',
      title: 'Йога-флоу',
      description: '30 мин',
      duration: 1800,
      image: 'assets/yoga.jpg',
      category: 'Flexibility',
      difficulty: DifficultyLevel.easy,
      caloriesBurned: 100,
      equipment: const ['Коврик'],
      instructions:
          'Следуй последовательности в своем темпе и концентрируйся на дыхании.',
      isFavorite: false,
    ),
    Workout(
      id: '7',
      title: 'Жим штанги лежа',
      description: '4x8',
      duration: 1500,
      image: 'assets/bench_press.jpg',
      category: 'Split: Грудь',
      difficulty: DifficultyLevel.medium,
      caloriesBurned: 180,
      equipment: const ['Штанга', 'Скамья'],
      instructions:
          'Выжимай штангу под контролем, своди лопатки и плотно упрись стопами в пол.',
      isFavorite: false,
    ),
    Workout(
      id: '8',
      title: 'Жим гантелей на наклонной',
      description: '4x10',
      duration: 1320,
      image: 'assets/incline_press.jpg',
      category: 'Split: Грудь',
      difficulty: DifficultyLevel.medium,
      caloriesBurned: 165,
      equipment: const ['Гантели', 'Наклонная скамья'],
      instructions:
          'Опускай гантели медленно и выжимай вверх без резкого выпрямления локтей.',
      isFavorite: false,
    ),
    Workout(
      id: '9',
      title: 'Тяга верхнего блока',
      description: '4x12',
      duration: 1440,
      image: 'assets/lat_pulldown.jpg',
      category: 'Split: Спина',
      difficulty: DifficultyLevel.easy,
      caloriesBurned: 150,
      equipment: const ['Блочный тренажер'],
      instructions: 'Тяни локти вниз к корпусу и не заваливайся сильно назад.',
      isFavorite: false,
    ),
    Workout(
      id: '10',
      title: 'Тяга штанги в наклоне',
      description: '4x8',
      duration: 1560,
      image: 'assets/barbell_row.jpg',
      category: 'Split: Спина',
      difficulty: DifficultyLevel.hard,
      caloriesBurned: 190,
      equipment: const ['Штанга'],
      instructions:
          'Напряги корпус, веди штангу близко к телу и тяни к нижней части груди.',
      isFavorite: false,
    ),
    Workout(
      id: '11',
      title: 'Присед со штангой',
      description: '5x5',
      duration: 1800,
      image: 'assets/barbell_squat.jpg',
      category: 'Split: Ноги',
      difficulty: DifficultyLevel.hard,
      caloriesBurned: 240,
      equipment: const ['Штанга', 'Стойка'],
      instructions:
          'Уводи таз назад и вниз, держи грудь раскрытой и дави в пол всей стопой.',
      isFavorite: false,
    ),
    Workout(
      id: '12',
      title: 'Румынская тяга',
      description: '4x10',
      duration: 1560,
      image: 'assets/romanian_deadlift.jpg',
      category: 'Split: Ноги',
      difficulty: DifficultyLevel.medium,
      caloriesBurned: 205,
      equipment: const ['Штанга'],
      instructions:
          'Отводи таз назад, веди штангу вдоль ног и сохраняй нейтральную спину.',
      isFavorite: false,
    ),
    Workout(
      id: '13',
      title: 'Жим гантелей сидя',
      description: '4x10',
      duration: 1380,
      image: 'assets/dumbbell_press.jpg',
      category: 'Split: Плечи',
      difficulty: DifficultyLevel.medium,
      caloriesBurned: 155,
      equipment: const ['Гантели', 'Скамья'],
      instructions:
          'Жми строго вверх, держи кисти устойчиво и не переразгибай поясницу.',
      isFavorite: false,
    ),
    Workout(
      id: '14',
      title: 'Махи в стороны',
      description: '4x15',
      duration: 1200,
      image: 'assets/lateral_raises.jpg',
      category: 'Split: Плечи',
      difficulty: DifficultyLevel.easy,
      caloriesBurned: 120,
      equipment: const ['Гантели'],
      instructions:
          'Поднимай руки до уровня плеч под контролем и оставляй легкий сгиб в локтях.',
      isFavorite: false,
    ),
    Workout(
      id: '15',
      title: 'Подъем штанги на бицепс',
      description: '4x12',
      duration: 1140,
      image: 'assets/barbell_curl.jpg',
      category: 'Split: Руки',
      difficulty: DifficultyLevel.easy,
      caloriesBurned: 110,
      equipment: const ['Штанга'],
      instructions:
          'Держи локти неподвижно и не раскачивай корпус, чтобы поднять вес.',
      isFavorite: false,
    ),
    Workout(
      id: '16',
      title: 'Разгибание на трицепс у блока',
      description: '4x12',
      duration: 1140,
      image: 'assets/triceps_pushdown.jpg',
      category: 'Split: Руки',
      difficulty: DifficultyLevel.easy,
      caloriesBurned: 115,
      equipment: const ['Блочный тренажер'],
      instructions:
          'Прижми локти к корпусу и полностью разгибай руки в нижней точке.',
      isFavorite: false,
    ),
    Workout(
      id: '17',
      title: 'Круговая силовая Fullbody',
      description: '5 кругов',
      duration: 2100,
      image: 'assets/fullbody_strength.jpg',
      category: 'Fullbody',
      difficulty: DifficultyLevel.hard,
      caloriesBurned: 320,
      equipment: const ['Штанга', 'Гантели', 'Скамья'],
      instructions:
          'Чередуй присед, жим, тягу и работу на корпус с коротким отдыхом между кругами.',
      isFavorite: false,
    ),
    Workout(
      id: '18',
      title: 'Fullbody на гипертрофию',
      description: '4x10 каждое',
      duration: 2400,
      image: 'assets/fullbody_hypertrophy.jpg',
      category: 'Fullbody',
      difficulty: DifficultyLevel.medium,
      caloriesBurned: 280,
      equipment: const ['Тренажеры', 'Гантели'],
      instructions:
          'В каждом круге выполни одно жимовое, одно тяговое, одно упражнение на ноги и одно на плечи.',
      isFavorite: false,
    ),
    Workout(
      id: '19',
      title: 'Fullbody для новичка',
      description: '3x12 каждое',
      duration: 1800,
      image: 'assets/fullbody_beginner.jpg',
      category: 'Fullbody',
      difficulty: DifficultyLevel.easy,
      caloriesBurned: 220,
      equipment: const ['Тренажеры', 'Коврик'],
      instructions:
          'Сосредоточься на технике с легким сопротивлением для ног, груди, спины и корпуса.',
      isFavorite: false,
    ),
  ];

  // Get all workouts
  List<Workout> getAllWorkouts() => List.from(_workouts);

  // Get workouts by category
  List<Workout> getWorkoutsByCategory(String category) {
    return _workouts.where((w) => w.category == category).toList();
  }

  List<Workout> getHomeWorkouts() {
    return _workouts
        .where((w) =>
            w.category == 'Strength' ||
            w.category == 'Cardio' ||
            w.category == 'Flexibility')
        .toList();
  }

  List<Workout> getGymWorkouts() {
    return _workouts
        .where(
            (w) => w.category.startsWith('Split: ') || w.category == 'Fullbody')
        .toList();
  }

  List<String> getGymSplitGroups() => List.unmodifiable(_gymSplitGroups);

  List<Workout> getSplitWorkoutsByGroup(String group) {
    return _workouts.where((w) => w.category == 'Split: $group').toList();
  }

  List<Workout> getFullBodyWorkouts() {
    return _workouts.where((w) => w.category == 'Fullbody').toList();
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
    final normalizedQuery = query.toLowerCase();
    return _workouts
        .where((w) =>
            w.title.toLowerCase().contains(normalizedQuery) ||
            w.category.toLowerCase().contains(normalizedQuery) ||
            _localizedCategorySearchTerms(w.category)
                .any((term) => term.contains(normalizedQuery)))
        .toList();
  }

  List<String> _localizedCategorySearchTerms(String category) {
    switch (category) {
      case 'Strength':
        return const ['сила', 'силовые', 'дом', 'дома'];
      case 'Cardio':
        return const ['кардио', 'выносливость', 'дом', 'дома'];
      case 'Flexibility':
        return const ['мобильность', 'гибкость', 'растяжка', 'дом', 'дома'];
      case 'Fullbody':
        return const ['фулбоди', 'fullbody', 'зал', 'все тело'];
      default:
        if (category.startsWith('Split: ')) {
          final group = category.replaceFirst('Split: ', '').toLowerCase();
          return ['сплит', 'зал', group];
        }
        return const [];
    }
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
    int totalCalories = _workouts.fold(
        0, (sum, w) => sum + (w.caloriesBurned * w.completedCount));
    int totalDuration =
        _workouts.fold(0, (sum, w) => sum + (w.duration * w.completedCount));
    return {
      'totalWorkouts': totalWorkouts,
      'totalCalories': totalCalories,
      'totalDuration': totalDuration,
    };
  }
}
