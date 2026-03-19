import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/daily_workout.dart';
import '../models/friend_profile.dart';
import '../models/workout_log_entry.dart';
import '../models/workout.dart';

const _favoriteWorkoutIdsKey = 'favorite_workout_ids';
const _completedWorkoutCountsKey = 'completed_workout_counts';
const _dailyWorkoutHistoryKey = 'daily_workout_history';
const _workoutLogsKey = 'workout_logs';
const _friendProfilesKey = 'friend_profiles';
const _friendWorkoutLogsKey = 'friend_workout_logs';

const List<String> _gymSplitGroups = [
  'Грудь',
  'Спина',
  'Ноги',
  'Плечи',
  'Руки',
];

class WorkoutService extends ChangeNotifier {
  static final WorkoutService _instance = WorkoutService._internal();

  factory WorkoutService() {
    return _instance;
  }

  WorkoutService._internal() {
    _resetWorkoutState();
  }

  final Map<String, List<String>> _dailyWorkoutIds = {};
  final Map<String, List<WorkoutLogEntry>> _dailyWorkoutLogs = {};

  final List<FriendProfile> _friendProfiles = [];
  final Map<String, List<WorkoutLogEntry>> _friendWorkoutLogs = {};
  String? _selectedFriendId;

  SharedPreferences? _preferences;

  Future<void> load() async {
    if (_preferences != null) {
      return;
    }

    _preferences = await SharedPreferences.getInstance();
    _resetWorkoutState();

    final favorites = _preferences!.getStringList(_favoriteWorkoutIdsKey);
    final completedCounts = _preferences!.getString(_completedWorkoutCountsKey);
    final dailyHistory = _preferences!.getString(_dailyWorkoutHistoryKey);
    final encodedWorkoutLogs = _preferences!.getString(_workoutLogsKey);

    final hasSavedState = favorites != null ||
        completedCounts != null ||
        dailyHistory != null ||
        encodedWorkoutLogs != null;

    if (!hasSavedState) {
      _initializeDemoData();
      await _saveState();
      notifyListeners();
      return;
    }

    _restoreFavorites(favorites ?? const []);
    _restoreCompletedCounts(completedCounts);
    _restoreDailyHistory(dailyHistory);

    if (encodedWorkoutLogs != null && encodedWorkoutLogs.isNotEmpty) {
      _restoreWorkoutLogs(encodedWorkoutLogs);
    } else {
      _hydrateLogsFromDailyHistory();
      await _saveState();
    }

    final encodedFriendProfiles = _preferences!.getString(_friendProfilesKey);
    final encodedFriendLogs = _preferences!.getString(_friendWorkoutLogsKey);

    if (encodedFriendProfiles != null && encodedFriendProfiles.isNotEmpty) {
      final profiles = jsonDecode(encodedFriendProfiles) as List<dynamic>;
      _friendProfiles.clear();
      _friendProfiles.addAll(
        profiles
            .map((e) => FriendProfile.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
      );
    }

    if (encodedFriendLogs != null && encodedFriendLogs.isNotEmpty) {
      _friendWorkoutLogs.clear();
      final friendLogs = jsonDecode(encodedFriendLogs) as List<dynamic>;
      for (final item in friendLogs) {
        final map = item as Map<String, dynamic>;
        final friendId = map['friendId'] as String;
        final entries = (map['logs'] as List<dynamic>)
            .map((e) => WorkoutLogEntry.fromJson(e as Map<String, dynamic>))
            .toList(growable: false);
        _friendWorkoutLogs[friendId] = entries;
      }
    }

    if (_friendProfiles.isEmpty) {
      _ensureDefaultFriendProfiles();
    }

    notifyListeners();
  }

  void _resetWorkoutState() {
    _dailyWorkoutIds.clear();
    _dailyWorkoutLogs.clear();

    for (var index = 0; index < _workouts.length; index++) {
      _workouts[index] = _workouts[index].copyWith(
        isFavorite: false,
        completedCount: 0,
      );
    }
  }

  void _initializeDemoData() {
    final today = DateTime.now();

    _seedDemoWorkout(today, _workouts[0],
        progressValue: 15, progressUnit: 'повт.');
    _seedDemoWorkout(today, _workouts[1],
        progressValue: 20, progressUnit: 'повт.');

    final yesterday = today.subtract(const Duration(days: 1));
    _seedDemoWorkout(yesterday, _workouts[2],
        progressValue: 3.5, progressUnit: 'км');
    _seedDemoWorkout(yesterday, _workouts[3],
        progressValue: 60, progressUnit: 'сек');
    _seedDemoWorkout(yesterday, _workouts[5]);

    final twoDaysAgo = today.subtract(const Duration(days: 2));
    _seedDemoWorkout(twoDaysAgo, _workouts[7],
        progressValue: 32, progressUnit: 'кг');
    _seedDemoWorkout(twoDaysAgo, _workouts[9],
        progressValue: 40, progressUnit: 'кг');
  }

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

  List<Workout> getAllWorkouts() => List.from(_workouts);

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

  // --- Competition / Friends support ---
  List<FriendProfile> getFriendProfiles() {
    if (_friendProfiles.isEmpty) {
      _ensureDefaultFriendProfiles();
    }
    return List.unmodifiable(_friendProfiles);
  }

  FriendProfile? getActiveFriend() {
    final profiles = getFriendProfiles();
    if (_selectedFriendId != null) {
      return profiles.firstWhere(
        (element) => element.id == _selectedFriendId,
        orElse: () => profiles.first,
      );
    }
    return profiles.isNotEmpty ? profiles.first : null;
  }

  void setActiveFriend(String id) {
    if (_friendProfiles.any((f) => f.id == id)) {
      _selectedFriendId = id;
      _persistState();
    }
  }

  List<WorkoutLogEntry> getFriendWorkoutLogs(String friendId) {
    return List.unmodifiable(_friendWorkoutLogs[friendId] ?? []);
  }

  List<DateTime> getFriendTrainingDates(String friendId) {
    final logs = getFriendWorkoutLogs(friendId);
    final dates = logs
        .map((entry) => DateTime(entry.completedAt.year, entry.completedAt.month, entry.completedAt.day))
        .toSet()
        .toList(growable: false);
    dates.sort((a, b) => b.compareTo(a));
    return dates;
  }

  Map<String, int> getFriendStats(String friendId) {
    final logs = getFriendWorkoutLogs(friendId);
    final totalWorkouts = logs.length;
    final totalCalories = logs.fold<int>(0, (sum, e) => sum + e.caloriesBurned);
    final totalDuration = logs.fold<int>(0, (sum, e) => sum + e.durationSeconds);
    return {
      'totalWorkouts': totalWorkouts,
      'totalCalories': totalCalories,
      'totalDuration': totalDuration,
    };
  }

  int getFriendTrainingStreak(String friendId) {
    final dates = getFriendTrainingDates(friendId);
    if (dates.isEmpty) return 0;
    int streak = 1;
    for (var i = 0; i < dates.length - 1; i++) {
      final difference = dates[i].difference(dates[i + 1]).inDays;
      if (difference == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  int getSharedTrainingDays(String friendId) {
    final myDates = getAllTrainingDates()
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet();
    final friendDates = getFriendTrainingDates(friendId).toSet();
    return myDates.intersection(friendDates).length;
  }

  int getSharedTrainingStreak(String friendId) {
    final myDates = getAllTrainingDates()
        .map((d) => DateTime(d.year, d.month, d.day))
        .toSet();
    final friendDates = getFriendTrainingDates(friendId).toSet();
    final commonDates = myDates.intersection(friendDates).toList()
      ..sort((a, b) => b.compareTo(a));
    if (commonDates.isEmpty) return 0;
    int streak = 1;
    for (var i = 0; i < commonDates.length - 1; i++) {
      final difference = commonDates[i].difference(commonDates[i + 1]).inDays;
      if (difference == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  void _ensureDefaultFriendProfiles() {
    if (_friendProfiles.isNotEmpty) return;

    _friendProfiles.addAll(
      const [
        FriendProfile(id: 'friend_1', name: 'Петя'),
        FriendProfile(id: 'friend_2', name: 'Саша'),
      ],
    );

    _selectedFriendId = _friendProfiles.first.id;
    _ensureDefaultFriendLogs();
  }

  void _ensureDefaultFriendLogs() {
    if (_friendWorkoutLogs.isNotEmpty) return;
    final userLogs = getAllWorkoutLogs(descending: false);
    if (userLogs.isEmpty) {
      return;
    }

    for (final friend in _friendProfiles) {
      final friendEntries = userLogs.map((entry) {
        final hash = entry.id.hashCode;
        final duration = (entry.durationSeconds * (0.85 + ((hash % 31) / 100))).round();
        final calories = (entry.caloriesBurned * (0.85 + ((hash % 27) / 100))).round();

        final offsetDay = (hash % 4) - 1;
        final date = entry.completedAt.add(Duration(days: offsetDay));
        return WorkoutLogEntry(
          id: '${friend.id}-${entry.id}',
          workoutId: entry.workoutId,
          completedAt: DateTime(date.year, date.month, date.day, 10 + (hash % 5)),
          durationSeconds: duration,
          caloriesBurned: calories,
          progressValue: entry.progressValue == null
              ? null
              : (entry.progressValue! * (0.9 + ((hash % 19) / 100))),
          progressUnit: entry.progressUnit,
          resultNote: 'Данные друга',
        );
      }).toList(growable: false);

      _friendWorkoutLogs[friend.id] = friendEntries;
    }
  }

  // --- original methods continue ---

  List<Workout> getSplitWorkoutsByGroup(String group) {
    return _workouts.where((w) => w.category == 'Split: $group').toList();
  }

  List<Workout> getFullBodyWorkouts() {
    return _workouts.where((w) => w.category == 'Fullbody').toList();
  }

  List<Workout> getFavorites() {
    return _workouts.where((w) => w.isFavorite).toList();
  }

  void toggleFavorite(String id) {
    final index = _workouts.indexWhere((w) => w.id == id);
    if (index != -1) {
      _workouts[index] =
          _workouts[index].copyWith(isFavorite: !_workouts[index].isFavorite);
      _persistState();
    }
  }

  List<Workout> searchWorkouts(String query) {
    final normalizedQuery = query.toLowerCase();
    return _workouts
        .where((w) =>
            w.title.toLowerCase().contains(normalizedQuery) ||
            w.category.toLowerCase().contains(normalizedQuery) ||
            w.description.toLowerCase().contains(normalizedQuery) ||
            w.instructions.toLowerCase().contains(normalizedQuery) ||
            w.equipment.any(
              (item) => item.toLowerCase().contains(normalizedQuery),
            ) ||
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

  Workout? getWorkoutById(String id) {
    try {
      return _workouts.firstWhere((w) => w.id == id);
    } catch (_) {
      return null;
    }
  }

  void markAsCompleted(String id) {
    completeWorkoutOnDate(id, DateTime.now());
  }

  Map<String, int> getStats() {
    final logs = getAllWorkoutLogs(descending: false);
    int totalWorkouts = logs.length;
    int totalCalories =
        logs.fold(0, (sum, entry) => sum + entry.caloriesBurned);
    int totalDuration =
        logs.fold(0, (sum, entry) => sum + entry.durationSeconds);
    return {
      'totalWorkouts': totalWorkouts,
      'totalCalories': totalCalories,
      'totalDuration': totalDuration,
    };
  }

  void completeWorkoutOnDate(
    String workoutId,
    DateTime date, {
    int? durationSeconds,
    int? caloriesBurned,
    double? progressValue,
    String progressUnit = '',
    String resultNote = '',
  }) {
    final workout = getWorkoutById(workoutId);
    if (workout != null) {
      final entry = _createLogEntry(
        workout: workout,
        completedAt: date,
        durationSeconds: durationSeconds ?? workout.duration,
        caloriesBurned: caloriesBurned ?? workout.caloriesBurned,
        progressValue: progressValue,
        progressUnit: progressUnit,
        resultNote: resultNote,
      );
      _appendLogEntry(entry);
      _persistState();
    }
  }

  List<Workout> getWorkoutsForDate(DateTime date) {
    return getWorkoutLogsForDate(date)
        .map((entry) => getWorkoutById(entry.workoutId))
        .whereType<Workout>()
        .toList(growable: false);
  }

  List<WorkoutLogEntry> getWorkoutLogsForDate(DateTime date) {
    final dateKey = _formatDate(date);
    final entries = _dailyWorkoutLogs[dateKey] ?? const [];
    return List.unmodifiable(entries);
  }

  List<WorkoutLogEntry> getAllWorkoutLogs({bool descending = true}) {
    final logs = _dailyWorkoutLogs.values
        .expand((entries) => entries)
        .toList(growable: false)
      ..sort((a, b) => a.completedAt.compareTo(b.completedAt));

    return descending ? logs.reversed.toList(growable: false) : logs;
  }

  List<WorkoutLogEntry> getWorkoutLogsForWorkout(String workoutId) {
    final logs = getAllWorkoutLogs(descending: false)
        .where((entry) => entry.workoutId == workoutId)
        .toList(growable: false);
    return logs;
  }

  List<Workout> getWorkoutsWithProgressLogs() {
    final workoutIds = <String>{
      for (final entry in getAllWorkoutLogs(descending: false))
        if (entry.progressValue != null) entry.workoutId,
    };
    return workoutIds
        .map(getWorkoutById)
        .whereType<Workout>()
        .toList(growable: false);
  }

  List<DateTime> getAllTrainingDates() {
    return _dailyWorkoutLogs.keys
        .map((dateKey) => DateTime.parse(dateKey))
        .toList()
      ..sort((a, b) => b.compareTo(a));
  }

  DailyWorkout? getDailyWorkout(DateTime date) {
    final entries = getWorkoutLogsForDate(date);
    if (entries.isEmpty) return null;

    final workouts = entries
        .map((entry) => getWorkoutById(entry.workoutId))
        .whereType<Workout>()
        .toList(growable: false);

    int totalCalories =
        entries.fold(0, (sum, entry) => sum + entry.caloriesBurned);
    int totalDuration =
        entries.fold(0, (sum, entry) => sum + entry.durationSeconds);

    return DailyWorkout(
      date: date,
      exercises: workouts,
      entries: entries,
      totalCalories: totalCalories,
      totalDuration: totalDuration,
    );
  }

  bool hasWorkoutOnDate(DateTime date) {
    return getWorkoutLogsForDate(date).isNotEmpty;
  }

  int getTotalCaloriesForDate(DateTime date) {
    return getWorkoutLogsForDate(date)
        .fold(0, (sum, entry) => sum + entry.caloriesBurned);
  }

  int getTotalDurationForDate(DateTime date) {
    return getWorkoutLogsForDate(date)
        .fold(0, (sum, entry) => sum + entry.durationSeconds);
  }

  int getTrainingStreak() {
    final dates = getAllTrainingDates();
    if (dates.isEmpty) return 0;

    int streak = 1;
    for (int i = 0; i < dates.length - 1; i++) {
      final difference = dates[i].difference(dates[i + 1]).inDays;
      if (difference == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  bool hasWorkoutToday() {
    final today = DateTime.now();
    return getWorkoutsForDate(today).isNotEmpty;
  }

  String _formatDate(DateTime date) {
    final year = date.year;
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  void _incrementCompletedCount(String id) {
    final index = _workouts.indexWhere((w) => w.id == id);
    if (index == -1) {
      return;
    }

    _workouts[index] = _workouts[index].copyWith(
      completedCount: _workouts[index].completedCount + 1,
    );
  }

  void _restoreFavorites(List<String> favoriteIds) {
    final favoriteSet = favoriteIds.toSet();
    for (var index = 0; index < _workouts.length; index++) {
      _workouts[index] = _workouts[index].copyWith(
        isFavorite: favoriteSet.contains(_workouts[index].id),
      );
    }
  }

  void _restoreCompletedCounts(String? encodedCounts) {
    if (encodedCounts == null || encodedCounts.isEmpty) {
      return;
    }

    final decodedCounts = jsonDecode(encodedCounts) as Map<String, dynamic>;
    for (var index = 0; index < _workouts.length; index++) {
      final completedCount = decodedCounts[_workouts[index].id] as int? ?? 0;
      _workouts[index] = _workouts[index].copyWith(
        completedCount: completedCount,
      );
    }
  }

  void _restoreDailyHistory(String? encodedHistory) {
    if (encodedHistory == null || encodedHistory.isEmpty) {
      return;
    }

    final decodedHistory = jsonDecode(encodedHistory) as Map<String, dynamic>;
    for (final entry in decodedHistory.entries) {
      final workoutIds = (entry.value as List<dynamic>)
          .map((item) => item as String)
          .where((id) => getWorkoutById(id) != null)
          .toList();
      _dailyWorkoutIds[entry.key] = workoutIds;
    }
  }

  void _restoreWorkoutLogs(String encodedLogs) {
    _dailyWorkoutIds.clear();
    _dailyWorkoutLogs.clear();

    final decodedLogs = jsonDecode(encodedLogs) as List<dynamic>;
    for (final rawEntry in decodedLogs) {
      final entry = WorkoutLogEntry.fromJson(rawEntry as Map<String, dynamic>);
      _appendLogEntry(entry, incrementCompletedCount: false);
    }
  }

  void _hydrateLogsFromDailyHistory() {
    final historySnapshot = Map<String, List<String>>.fromEntries(
      _dailyWorkoutIds.entries.map(
        (entry) => MapEntry(entry.key, List<String>.from(entry.value)),
      ),
    );

    _dailyWorkoutIds.clear();
    _dailyWorkoutLogs.clear();

    for (final historyEntry in historySnapshot.entries) {
      final baseDate = DateTime.parse(historyEntry.key);
      for (var index = 0; index < historyEntry.value.length; index++) {
        final workout = getWorkoutById(historyEntry.value[index]);
        if (workout == null) {
          continue;
        }

        final entry = _createLogEntry(
          workout: workout,
          completedAt: baseDate.add(Duration(hours: 9 + index)),
          durationSeconds: workout.duration,
          caloriesBurned: workout.caloriesBurned,
        );
        _appendLogEntry(entry, incrementCompletedCount: false);
      }
    }
  }

  void _seedDemoWorkout(
    DateTime date,
    Workout workout, {
    double? progressValue,
    String progressUnit = '',
  }) {
    final entry = _createLogEntry(
      workout: workout,
      completedAt: date,
      durationSeconds: workout.duration,
      caloriesBurned: workout.caloriesBurned,
      progressValue: progressValue,
      progressUnit: progressUnit,
    );
    _appendLogEntry(entry);
  }

  WorkoutLogEntry _createLogEntry({
    required Workout workout,
    required DateTime completedAt,
    required int durationSeconds,
    required int caloriesBurned,
    double? progressValue,
    String progressUnit = '',
    String resultNote = '',
  }) {
    final normalizedDate = DateTime(
      completedAt.year,
      completedAt.month,
      completedAt.day,
      completedAt.hour == 0 ? 12 : completedAt.hour,
      completedAt.minute,
      completedAt.second,
    );
    final dateKey = _formatDate(normalizedDate);
    final nextIndex = _dailyWorkoutLogs[dateKey]?.length ?? 0;

    return WorkoutLogEntry(
      id: '$dateKey-${workout.id}-$nextIndex',
      workoutId: workout.id,
      completedAt: normalizedDate,
      durationSeconds: durationSeconds,
      caloriesBurned: caloriesBurned,
      progressValue: progressValue,
      progressUnit: progressUnit,
      resultNote: resultNote,
    );
  }

  void _appendLogEntry(
    WorkoutLogEntry entry, {
    bool incrementCompletedCount = true,
  }) {
    final dateKey = _formatDate(entry.completedAt);
    final workoutIds = _dailyWorkoutIds.putIfAbsent(dateKey, () => []);
    final logs = _dailyWorkoutLogs.putIfAbsent(dateKey, () => []);
    workoutIds.add(entry.workoutId);
    logs.add(entry);

    if (incrementCompletedCount) {
      _incrementCompletedCount(entry.workoutId);
    }
  }

  void _persistState() {
    _saveState();
    notifyListeners();
  }

  Future<void> _saveState() async {
    if (_preferences == null) {
      return;
    }

    await _preferences!.setStringList(
      _favoriteWorkoutIdsKey,
      _workouts.where((w) => w.isFavorite).map((w) => w.id).toList(),
    );
    await _preferences!.setString(
      _completedWorkoutCountsKey,
      jsonEncode({
        for (final workout in _workouts) workout.id: workout.completedCount,
      }),
    );
    await _preferences!.setString(
      _dailyWorkoutHistoryKey,
      jsonEncode(_dailyWorkoutIds),
    );
    await _preferences!.setString(
      _workoutLogsKey,
      jsonEncode(
        getAllWorkoutLogs(descending: false)
            .map((entry) => entry.toJson())
            .toList(growable: false),
      ),
    );

    await _preferences!.setString(
      _friendProfilesKey,
      jsonEncode(_friendProfiles.map((e) => e.toJson()).toList(growable: false)),
    );

    final friendLogBundle = _friendWorkoutLogs.entries
        .map((item) => {
              'friendId': item.key,
              'logs': item.value.map((e) => e.toJson()).toList(growable: false),
            })
        .toList(growable: false);

    await _preferences!.setString(
      _friendWorkoutLogsKey,
      jsonEncode(friendLogBundle),
    );
  }
}
