import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/chat_message.dart';
import '../models/daily_workout.dart';
import '../models/friend_profile.dart';
import '../models/friend_request.dart';
import '../models/profile_search_result.dart';
import '../models/workout_log_entry.dart';
import '../models/workout.dart';
import 'achievement_service.dart';

const _favoriteWorkoutIdsKey = 'favorite_workout_ids';
const _completedWorkoutCountsKey = 'completed_workout_counts';
const _dailyWorkoutHistoryKey = 'daily_workout_history';
const _workoutLogsKey = 'workout_logs';
const _friendProfilesKey = 'friend_profiles';
const _friendWorkoutLogsKey = 'friend_workout_logs';
const Duration _friendTypingTtl = Duration(seconds: 5);

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
    _fallbackWorkouts =
        _workouts.map((workout) => workout.copyWith()).toList(growable: false);
    _resetWorkoutState();
  }

  final Map<String, List<String>> _dailyWorkoutIds = {};
  final Map<String, List<WorkoutLogEntry>> _dailyWorkoutLogs = {};

  final List<FriendProfile> _friendProfiles = [];
  final Map<String, List<WorkoutLogEntry>> _friendWorkoutLogs = {};
  final Map<String, ChatMessage?> _lastChatMessageByFriendshipId = {};
  final Map<String, int> _unreadChatCountByFriendshipId = {};
  final Map<String, List<ChatMessage>> _chatMessagesByFriendshipId = {};
  final Map<String, ValueNotifier<List<ChatMessage>>> _chatMessagesNotifiers =
      {};
  final Map<String, ValueNotifier<bool>> _friendTypingNotifiers = {};
  final Map<String, Timer> _friendTypingExpiryTimers = {};
  RealtimeChannel? _chatMessagesChannel;
  String? _activeChatFriendshipId;
  String? _selectedFriendId;

  SharedPreferences? _preferences;
  bool _loaded = false;
  bool _isCloudSyncInProgress = false;
  final Map<String, String> _remoteWorkoutIdsByLegacyId = {};
  late final List<Workout> _fallbackWorkouts;
  RealtimeChannel? _friendshipsChannel;
  RealtimeChannel? _friendMessagesSummaryChannel;
  RealtimeChannel? _friendPresenceChannel;
  String? _activeRealtimeUserId;
  String? _activeMessagesRealtimeUserId;
  String? _activePresenceRealtimeUserId;
  int _lastKnownIncomingRequests = 0;

  final ValueNotifier<int> incomingFriendRequestsCount = ValueNotifier(0);
  final ValueNotifier<String?> socialNotificationMessage = ValueNotifier(null);

  Future<void> load() async {
    if (_loaded) {
      return;
    }

    _preferences = await SharedPreferences.getInstance();
    _loaded = true;
    Supabase.instance.client.auth.onAuthStateChange.listen((_) {
      unawaited(_handleAuthStateChanged());
    });

    await _handleAuthStateChanged();
  }

  Future<void> _handleAuthStateChanged() async {
    await _configureFriendshipsRealtime();
    await _configureFriendMessagesRealtime();
    await _configureFriendPresenceRealtime();
    await _reloadStateForCurrentUser();
    await _refreshIncomingRequestsCount(notifyOnIncrease: false);
  }

  Future<void> _reloadStateForCurrentUser() async {
    await _loadWorkoutCatalog();
    await _loadLocalState();
    await _syncWithSupabase();
    notifyListeners();
  }

  Future<void> _loadWorkoutCatalog() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      _restoreFallbackWorkoutCatalog();
      return;
    }

    try {
      final response = await Supabase.instance.client
          .from('workouts')
          .select(
            'legacy_id, title, description, duration_seconds, image_url, category, difficulty, calories_burned, equipment, instructions',
          )
          .eq('is_active', true)
          .order('legacy_id');

      final remoteWorkouts = (response as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(_workoutFromRemoteRow)
          .whereType<Workout>()
          .toList(growable: false);

      if (remoteWorkouts.isEmpty) {
        _restoreFallbackWorkoutCatalog();
        return;
      }

      _workouts
        ..clear()
        ..addAll(remoteWorkouts);
    } catch (_) {
      _restoreFallbackWorkoutCatalog();
    }
  }

  void _restoreFallbackWorkoutCatalog() {
    _workouts
      ..clear()
      ..addAll(
        _fallbackWorkouts
            .map((workout) => workout.copyWith())
            .toList(growable: false),
      );
  }

  Workout? _workoutFromRemoteRow(Map<String, dynamic> row) {
    final legacyId = row['legacy_id'] as String?;
    final title = row['title'] as String?;
    final category = row['category'] as String?;

    if (legacyId == null || title == null || category == null) {
      return null;
    }

    return Workout(
      id: legacyId,
      title: title,
      description: row['description'] as String? ?? '',
      duration: row['duration_seconds'] as int? ?? 0,
      image: row['image_url'] as String? ?? '',
      category: category,
      difficulty: _difficultyFromString(row['difficulty'] as String?),
      caloriesBurned: row['calories_burned'] as int? ?? 0,
      equipment: ((row['equipment'] as List<dynamic>?) ?? const [])
          .map((item) => item as String)
          .toList(growable: false),
      instructions: row['instructions'] as String? ?? '',
    );
  }

  DifficultyLevel _difficultyFromString(String? value) {
    switch (value) {
      case 'easy':
        return DifficultyLevel.easy;
      case 'hard':
        return DifficultyLevel.hard;
      case 'medium':
      default:
        return DifficultyLevel.medium;
    }
  }

  Future<void> _loadLocalState() async {
    _resetWorkoutState();
    _friendProfiles.clear();
    _friendWorkoutLogs.clear();
    _selectedFriendId = null;

    final favorites =
        _preferences!.getStringList(_storageKey(_favoriteWorkoutIdsKey));
    final completedCounts =
        _preferences!.getString(_storageKey(_completedWorkoutCountsKey));
    final dailyHistory =
        _preferences!.getString(_storageKey(_dailyWorkoutHistoryKey));
    final encodedWorkoutLogs =
        _preferences!.getString(_storageKey(_workoutLogsKey));

    final hasSavedState = favorites != null ||
        completedCounts != null ||
        dailyHistory != null ||
        encodedWorkoutLogs != null;

    if (hasSavedState) {
      _restoreFavorites(favorites ?? const []);
      _restoreCompletedCounts(completedCounts);
      _restoreDailyHistory(dailyHistory);

      if (encodedWorkoutLogs != null && encodedWorkoutLogs.isNotEmpty) {
        _restoreWorkoutLogs(encodedWorkoutLogs);
      } else {
        _hydrateLogsFromDailyHistory();
        await _saveState();
      }
    }

    final encodedFriendProfiles =
        _preferences!.getString(_storageKey(_friendProfilesKey));
    final encodedFriendLogs =
        _preferences!.getString(_storageKey(_friendWorkoutLogsKey));

    if (encodedFriendProfiles != null && encodedFriendProfiles.isNotEmpty) {
      final profiles = jsonDecode(encodedFriendProfiles) as List<dynamic>;
      _friendProfiles.addAll(
        profiles
            .map((e) => FriendProfile.fromJson(e as Map<String, dynamic>))
            .toList(growable: false),
      );
    }

    if (encodedFriendLogs != null && encodedFriendLogs.isNotEmpty) {
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
    return List.unmodifiable(_friendProfiles);
  }

  FriendProfile? getActiveFriend() {
    final profiles = getFriendProfiles();
    if (profiles.isEmpty) {
      return null;
    }
    if (_selectedFriendId != null) {
      return profiles.firstWhere(
        (element) => element.id == _selectedFriendId,
        orElse: () => profiles.first,
      );
    }
    return profiles.first;
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
        .map((entry) => DateTime(entry.completedAt.year,
            entry.completedAt.month, entry.completedAt.day))
        .toSet()
        .toList(growable: false);
    dates.sort((a, b) => b.compareTo(a));
    return dates;
  }

  Map<String, int> getFriendStats(String friendId) {
    final logs = getFriendWorkoutLogs(friendId);
    final totalWorkouts = logs.length;
    final totalCalories = logs.fold<int>(0, (sum, e) => sum + e.caloriesBurned);
    final totalDuration =
        logs.fold<int>(0, (sum, e) => sum + e.durationSeconds);
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
      final updatedFavoriteState = !_workouts[index].isFavorite;
      _workouts[index] =
          _workouts[index].copyWith(isFavorite: updatedFavoriteState);
      _persistState();
      unawaited(_syncFavoriteToSupabase(id, updatedFavoriteState));
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
      unawaited(_syncLogEntryToSupabase(entry));

      // Проверить достижения после завершения тренировки
      unawaited(_checkAchievementsAfterWorkout());
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
    unawaited(_saveState());
    notifyListeners();
  }

  Future<void> _saveState() async {
    if (_preferences == null) {
      return;
    }

    await _preferences!.setStringList(
      _storageKey(_favoriteWorkoutIdsKey),
      _workouts.where((w) => w.isFavorite).map((w) => w.id).toList(),
    );
    await _preferences!.setString(
      _storageKey(_completedWorkoutCountsKey),
      jsonEncode({
        for (final workout in _workouts) workout.id: workout.completedCount,
      }),
    );
    await _preferences!.setString(
      _storageKey(_dailyWorkoutHistoryKey),
      jsonEncode(_dailyWorkoutIds),
    );
    await _preferences!.setString(
      _storageKey(_workoutLogsKey),
      jsonEncode(
        getAllWorkoutLogs(descending: false)
            .map((entry) => entry.toJson())
            .toList(growable: false),
      ),
    );

    await _preferences!.setString(
      _storageKey(_friendProfilesKey),
      jsonEncode(
          _friendProfiles.map((e) => e.toJson()).toList(growable: false)),
    );

    final friendLogBundle = _friendWorkoutLogs.entries
        .map((item) => {
              'friendId': item.key,
              'logs': item.value.map((e) => e.toJson()).toList(growable: false),
            })
        .toList(growable: false);

    await _preferences!.setString(
      _storageKey(_friendWorkoutLogsKey),
      jsonEncode(friendLogBundle),
    );
  }

  String _storageKey(String baseKey) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null || userId.isEmpty) {
      return baseKey;
    }
    return '$baseKey:$userId';
  }

  Future<void> _syncWithSupabase() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null || _isCloudSyncInProgress) {
      return;
    }

    _isCloudSyncInProgress = true;
    try {
      await _refreshRemoteWorkoutMapping();
      if (_remoteWorkoutIdsByLegacyId.isEmpty) {
        return;
      }

      final localFavoriteIds = _workouts
          .where((workout) => workout.isFavorite)
          .map((workout) => workout.id)
          .toSet();
      final localLogs = getAllWorkoutLogs(descending: false);

      final remoteFavoriteIds = await _fetchRemoteFavoriteIds();
      final remoteLogs = await _fetchRemoteWorkoutLogs();

      await _pushMissingFavoritesToSupabase(
          localFavoriteIds, remoteFavoriteIds);
      await _pushMissingLogsToSupabase(localLogs, remoteLogs);

      final syncedFavoriteIds = await _fetchRemoteFavoriteIds();
      final syncedLogs = await _fetchRemoteWorkoutLogs();
      _applyRemoteWorkoutState(syncedFavoriteIds, syncedLogs);
      await _syncFriendStateFromSupabase();
      await _saveState();
    } finally {
      _isCloudSyncInProgress = false;
    }
  }

  Future<void> _syncFriendStateFromSupabase() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      return;
    }

    final friendshipsResponse = await Supabase.instance.client
        .from('friendships')
        .select('id, requester_id, addressee_id, status')
        .eq('status', 'accepted')
        .or('requester_id.eq.${currentUser.id},addressee_id.eq.${currentUser.id}');

    final friendshipRows = (friendshipsResponse as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);

    final friendIds = friendshipRows
        .map((row) {
          final requesterId = row['requester_id'] as String?;
          final addresseeId = row['addressee_id'] as String?;
          if (requesterId == null || addresseeId == null) {
            return null;
          }
          return requesterId == currentUser.id ? addresseeId : requesterId;
        })
        .whereType<String>()
        .toSet()
        .toList(growable: false);

    final friendshipIdByFriendId = {
      for (final row in friendshipRows)
        ((row['requester_id'] as String) == currentUser.id
            ? row['addressee_id']
            : row['requester_id']) as String: row['id'] as String,
    };

    _friendProfiles.clear();
    _friendWorkoutLogs.clear();

    if (friendIds.isEmpty) {
      _selectedFriendId = null;
      return;
    }

    final profilesResponse = await Supabase.instance.client
        .from('profiles')
        .select('id, display_name, is_online, last_seen')
        .inFilter('id', friendIds);

    final profiles = (profilesResponse as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(
          (row) => FriendProfile(
            id: row['id'] as String,
            name: row['display_name'] as String? ?? 'Друг',
            friendshipId: friendshipIdByFriendId[row['id'] as String],
            isOnline: row['is_online'] as bool? ?? false,
            lastSeen: row['last_seen'] == null
                ? null
                : DateTime.parse(row['last_seen'] as String),
          ),
        )
        .toList(growable: false)
      ..sort((a, b) => a.name.compareTo(b.name));

    _friendProfiles.addAll(profiles);

    final remoteIdToLegacyId = {
      for (final entry in _remoteWorkoutIdsByLegacyId.entries)
        entry.value: entry.key,
    };

    for (final friend in profiles) {
      final logsResponse = await Supabase.instance.client
          .from('workout_logs')
          .select(
            'id, workout_id, completed_at, duration_seconds, calories_burned, progress_value, progress_unit, result_note',
          )
          .eq('user_id', friend.id)
          .order('completed_at');

      final friendLogs = (logsResponse as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map((row) {
            final legacyId =
                remoteIdToLegacyId[row['workout_id'] as String? ?? ''];
            if (legacyId == null) {
              return null;
            }

            return WorkoutLogEntry(
              id: row['id'] as String? ?? '',
              workoutId: legacyId,
              completedAt: DateTime.parse(row['completed_at'] as String),
              durationSeconds: row['duration_seconds'] as int? ?? 0,
              caloriesBurned: row['calories_burned'] as int? ?? 0,
              progressValue: (row['progress_value'] as num?)?.toDouble(),
              progressUnit: row['progress_unit'] as String? ?? '',
              resultNote: row['result_note'] as String? ?? '',
            );
          })
          .whereType<WorkoutLogEntry>()
          .toList(growable: false);

      _friendWorkoutLogs[friend.id] = friendLogs;
    }

    if (_friendProfiles.any((friend) => friend.id == _selectedFriendId)) {
      return;
    }

    _selectedFriendId =
        _friendProfiles.isNotEmpty ? _friendProfiles.first.id : null;
  }

  Future<void> refreshSocialData({
    bool notifyOnIncomingIncrease = false,
  }) async {
    await _syncFriendStateFromSupabase();
    await refreshChatSummaries();
    await refreshUnreadChatCounts();
    await _refreshIncomingRequestsCount(
      notifyOnIncrease: notifyOnIncomingIncrease,
    );
    notifyListeners();
  }

  void clearSocialNotification() {
    socialNotificationMessage.value = null;
  }

  ChatMessage? getLastChatMessage(String friendshipId) {
    return _lastChatMessageByFriendshipId[friendshipId];
  }

  int getUnreadChatCount(String friendshipId) {
    return _unreadChatCountByFriendshipId[friendshipId] ?? 0;
  }

  Future<void> refreshChatSummaries() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      return;
    }

    _lastChatMessageByFriendshipId.clear();
    for (final friend in _friendProfiles) {
      final friendshipId = friend.friendshipId;
      if (friendshipId == null || friendshipId.isEmpty) {
        continue;
      }

      try {
        final response = await Supabase.instance.client
            .from('friend_messages')
            .select(
              'id, friendship_id, sender_id, recipient_id, content, created_at, read_at',
            )
            .eq('friendship_id', friendshipId)
            .order('created_at', ascending: false)
            .limit(1)
            .maybeSingle();

        if (response != null) {
          _lastChatMessageByFriendshipId[friendshipId] =
              ChatMessage.fromJson(response);
        }
      } catch (_) {
        // Ignore missing chat preview if the query fails.
      }
    }
  }

  Future<void> refreshUnreadChatCounts() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      return;
    }

    _unreadChatCountByFriendshipId.clear();
    for (final friend in _friendProfiles) {
      final friendshipId = friend.friendshipId;
      if (friendshipId == null || friendshipId.isEmpty) {
        continue;
      }

      try {
        final response = await Supabase.instance.client
            .from('friend_messages')
            .select('id')
            .eq('friendship_id', friendshipId)
            .eq('recipient_id', currentUser.id)
            .isFilter('read_at', null);

        _unreadChatCountByFriendshipId[friendshipId] =
            (response as List<dynamic>).length;
      } catch (_) {
        _unreadChatCountByFriendshipId[friendshipId] = 0;
      }
    }
  }

  Map<String, ChatMessage?> getLastChatMessages() {
    return Map.unmodifiable(_lastChatMessageByFriendshipId);
  }

  Map<String, int> getUnreadChatCounts() {
    return Map.unmodifiable(_unreadChatCountByFriendshipId);
  }

  ValueNotifier<bool> getFriendTypingNotifier(String friendshipId) {
    return _friendTypingNotifiers.putIfAbsent(
      friendshipId,
      () => ValueNotifier(false),
    );
  }

  Future<List<FriendRequest>> getPendingFriendRequests({
    required bool outgoing,
  }) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      return const [];
    }

    final userColumn = outgoing ? 'requester_id' : 'addressee_id';
    final profileIdColumn = outgoing ? 'addressee_id' : 'requester_id';

    final response = await Supabase.instance.client
        .from('friendships')
        .select('id, requester_id, addressee_id')
        .eq('status', 'pending')
        .eq(userColumn, currentUser.id);

    final rows = (response as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .toList(growable: false);
    if (rows.isEmpty) {
      return const [];
    }

    final profileIds = rows
        .map((row) => row[profileIdColumn] as String?)
        .whereType<String>()
        .toList(growable: false);

    final profilesResponse = await Supabase.instance.client
        .from('profiles')
        .select('id, display_name, email')
        .inFilter('id', profileIds);

    final profilesById = {
      for (final row in (profilesResponse as List<dynamic>)
          .whereType<Map<String, dynamic>>())
        row['id'] as String: row,
    };

    return rows.map((row) {
      final profileId = row[profileIdColumn] as String;
      final profile = profilesById[profileId];
      return FriendRequest(
        friendshipId: row['id'] as String,
        profileId: profileId,
        name: profile?['display_name'] as String? ?? 'Пользователь',
        email: profile?['email'] as String? ?? '',
        isOutgoing: outgoing,
      );
    }).toList(growable: false);
  }

  Future<List<ProfileSearchResult>> searchProfiles(String query) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final normalizedQuery = query.trim();
    if (currentUser == null || normalizedQuery.length < 2) {
      return const [];
    }

    final response = await Supabase.instance.client.rpc(
      'search_profiles',
      params: {'search_term': normalizedQuery},
    );

    return (response as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(
          (row) => ProfileSearchResult(
            profileId: row['id'] as String,
            displayName: row['display_name'] as String? ?? 'Пользователь',
            email: row['email'] as String? ?? '',
            friendshipId: row['friendship_id'] as String?,
            friendshipStatus: row['friendship_status'] as String?,
            isOutgoing: row['is_outgoing'] as bool? ?? false,
          ),
        )
        .toList(growable: false);
  }

  Future<void> sendFriendRequest(String profileId) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null || currentUser.id == profileId) {
      return;
    }

    final existing = await Supabase.instance.client
        .from('friendships')
        .select('id, requester_id, addressee_id, status')
        .or(
          'and(requester_id.eq.${currentUser.id},addressee_id.eq.$profileId),and(requester_id.eq.$profileId,addressee_id.eq.${currentUser.id})',
        )
        .maybeSingle();

    if (existing != null) {
      final status = existing['status'] as String?;
      final friendshipId = existing['id'] as String?;

      if (status == 'accepted' || status == 'pending') {
        return;
      }

      if (friendshipId != null) {
        await Supabase.instance.client
            .from('friendships')
            .delete()
            .eq('id', friendshipId);
      }

      if (status == 'declined') {
        await Supabase.instance.client.from('friendships').insert({
          'requester_id': currentUser.id,
          'addressee_id': profileId,
          'status': 'pending',
        });
      }
    } else {
      await Supabase.instance.client.from('friendships').insert({
        'requester_id': currentUser.id,
        'addressee_id': profileId,
        'status': 'pending',
      });
    }

    await refreshSocialData();
  }

  Future<void> respondToFriendRequest(
    String friendshipId, {
    required bool accept,
  }) async {
    await Supabase.instance.client.from('friendships').update(
        {'status': accept ? 'accepted' : 'declined'}).eq('id', friendshipId);

    await refreshSocialData();
  }

  Future<void> removeFriendship(String friendshipId) async {
    await Supabase.instance.client
        .from('friendships')
        .delete()
        .eq('id', friendshipId);

    await refreshSocialData();
  }

  Future<void> _configureFriendshipsRealtime() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final currentUserId = currentUser?.id;

    if (_activeRealtimeUserId == currentUserId) {
      return;
    }

    if (_friendshipsChannel != null) {
      await Supabase.instance.client.removeChannel(_friendshipsChannel!);
      _friendshipsChannel = null;
    }

    _activeRealtimeUserId = currentUserId;
    _lastKnownIncomingRequests = 0;
    incomingFriendRequestsCount.value = 0;
    socialNotificationMessage.value = null;

    if (currentUserId == null) {
      return;
    }

    final channel =
        Supabase.instance.client.channel('friendships:$currentUserId');
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'friendships',
      callback: (payload) {
        final newRecord = payload.newRecord;
        final oldRecord = payload.oldRecord;
        final requesterId =
            (newRecord['requester_id'] ?? oldRecord['requester_id']) as String?;
        final addresseeId =
            (newRecord['addressee_id'] ?? oldRecord['addressee_id']) as String?;

        final isRelatedToCurrentUser =
            requesterId == currentUserId || addresseeId == currentUserId;
        if (!isRelatedToCurrentUser) {
          return;
        }

        unawaited(_handleFriendshipRealtimeEvent());
      },
    );

    channel.subscribe();
    _friendshipsChannel = channel;
  }

  Future<void> _configureFriendMessagesRealtime() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final currentUserId = currentUser?.id;

    if (_activeMessagesRealtimeUserId == currentUserId) {
      return;
    }

    if (_friendMessagesSummaryChannel != null) {
      await Supabase.instance.client
          .removeChannel(_friendMessagesSummaryChannel!);
      _friendMessagesSummaryChannel = null;
    }

    _activeMessagesRealtimeUserId = currentUserId;
    if (currentUserId == null) {
      return;
    }

    final channel = Supabase.instance.client
        .channel('friend_messages_summary:$currentUserId');
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'friend_messages',
      callback: (payload) {
        final newRecord = payload.newRecord;
        final oldRecord = payload.oldRecord;
        final senderId =
            (newRecord['sender_id'] ?? oldRecord['sender_id']) as String?;
        final recipientId =
            (newRecord['recipient_id'] ?? oldRecord['recipient_id']) as String?;

        final isRelatedToCurrentUser =
            senderId == currentUserId || recipientId == currentUserId;
        if (!isRelatedToCurrentUser) {
          return;
        }

        unawaited(_handleFriendMessageRealtimeEvent());
      },
    );

    channel.subscribe();
    _friendMessagesSummaryChannel = channel;
  }

  Future<void> _configureFriendPresenceRealtime() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final currentUserId = currentUser?.id;

    if (_activePresenceRealtimeUserId == currentUserId) {
      return;
    }

    if (_friendPresenceChannel != null) {
      await Supabase.instance.client.removeChannel(_friendPresenceChannel!);
      _friendPresenceChannel = null;
    }

    _activePresenceRealtimeUserId = currentUserId;
    if (currentUserId == null) {
      return;
    }

    final channel =
        Supabase.instance.client.channel('friend_presence:$currentUserId');
    channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'profiles',
      callback: (payload) {
        final newRecord = payload.newRecord;
        final profileId = newRecord['id'] as String?;
        if (profileId == null ||
            !_friendProfiles.any((friend) => friend.id == profileId)) {
          return;
        }

        unawaited(_refreshFriendPresence());
      },
    );

    channel.subscribe();
    _friendPresenceChannel = channel;
  }

  Future<void> _refreshFriendPresence() async {
    if (_friendProfiles.isEmpty) {
      return;
    }

    final friendIds =
        _friendProfiles.map((friend) => friend.id).toList(growable: false);
    final profilesResponse = await Supabase.instance.client
        .from('profiles')
        .select('id, display_name, is_online, last_seen')
        .inFilter('id', friendIds);

    final profilesById = {
      for (final row in (profilesResponse as List<dynamic>)
          .whereType<Map<String, dynamic>>())
        row['id'] as String: row,
    };

    for (var index = 0; index < _friendProfiles.length; index++) {
      final friend = _friendProfiles[index];
      final row = profilesById[friend.id];
      if (row == null) {
        continue;
      }

      _friendProfiles[index] = friend.copyWith(
        name: row['display_name'] as String? ?? friend.name,
        isOnline: row['is_online'] as bool? ?? false,
        lastSeen: row['last_seen'] == null
            ? null
            : DateTime.parse(row['last_seen'] as String),
      );
    }

    notifyListeners();
  }

  Future<void> updatePresence({required bool isOnline}) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      return;
    }

    await Supabase.instance.client.from('profiles').update({
      'is_online': isOnline,
      'last_seen': DateTime.now().toIso8601String(),
    }).eq('id', currentUser.id);
  }

  Future<void> _handleFriendshipRealtimeEvent() async {
    await refreshSocialData(notifyOnIncomingIncrease: true);
  }

  Future<void> _handleFriendMessageRealtimeEvent() async {
    await refreshChatSummaries();
    await refreshUnreadChatCounts();
    notifyListeners();
  }

  Future<void> _refreshIncomingRequestsCount({
    required bool notifyOnIncrease,
  }) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      incomingFriendRequestsCount.value = 0;
      _lastKnownIncomingRequests = 0;
      return;
    }

    final incoming = await getPendingFriendRequests(outgoing: false);
    final nextCount = incoming.length;

    if (notifyOnIncrease && nextCount > _lastKnownIncomingRequests) {
      final latestName =
          incoming.isNotEmpty ? incoming.first.name : 'пользователь';
      socialNotificationMessage.value = 'Новая заявка в друзья от $latestName';
    }

    _lastKnownIncomingRequests = nextCount;
    incomingFriendRequestsCount.value = nextCount;
  }

  ValueNotifier<List<ChatMessage>> getChatMessagesNotifier(
      String friendshipId) {
    return _chatMessagesNotifiers.putIfAbsent(
      friendshipId,
      () => ValueNotifier(_chatMessagesByFriendshipId[friendshipId] ?? []),
    );
  }

  Future<List<ChatMessage>> loadChatMessages(String friendshipId) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null || friendshipId.isEmpty) {
      return const [];
    }

    final response = await Supabase.instance.client
        .from('friend_messages')
        .select(
          'id, friendship_id, sender_id, recipient_id, content, created_at, read_at',
        )
        .eq('friendship_id', friendshipId)
        .order('created_at', ascending: true);

    final messages = (response as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map(ChatMessage.fromJson)
        .toList(growable: false);

    _chatMessagesByFriendshipId[friendshipId] = messages;
    _lastChatMessageByFriendshipId[friendshipId] =
        messages.isEmpty ? null : messages.last;
    getChatMessagesNotifier(friendshipId).value = messages;
    await markChatAsRead(friendshipId);
    return messages;
  }

  Future<void> sendChatMessage(
    String friendshipId,
    String recipientId,
    String content,
  ) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null || friendshipId.isEmpty || content.trim().isEmpty) {
      return;
    }

    final result = await Supabase.instance.client
        .from('friend_messages')
        .insert({
          'friendship_id': friendshipId,
          'sender_id': currentUser.id,
          'recipient_id': recipientId,
          'content': content.trim(),
          'created_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    final newMessage = ChatMessage.fromJson(result);
    final existing = _chatMessagesByFriendshipId[friendshipId] ?? [];
    final updatedMessages = [...existing, newMessage];
    _chatMessagesByFriendshipId[friendshipId] = updatedMessages;
    _lastChatMessageByFriendshipId[friendshipId] = newMessage;
    getChatMessagesNotifier(friendshipId).value = updatedMessages;
    await setTypingState(friendshipId, false);
  }

  Future<void> setTypingState(String friendshipId, bool isTyping) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null || friendshipId.isEmpty) {
      return;
    }

    await Supabase.instance.client.from('friend_typing_states').upsert(
      {
        'friendship_id': friendshipId,
        'user_id': currentUser.id,
        'is_typing': isTyping,
        'updated_at': DateTime.now().toIso8601String(),
      },
      onConflict: 'friendship_id,user_id',
    );
  }

  Future<void> _refreshFriendTypingState(String friendshipId) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null || friendshipId.isEmpty) {
      return;
    }

    try {
      final threshold = DateTime.now().subtract(_friendTypingTtl);
      final response = await Supabase.instance.client
          .from('friend_typing_states')
          .select('user_id, is_typing, updated_at')
          .eq('friendship_id', friendshipId)
          .neq('user_id', currentUser.id)
          .eq('is_typing', true)
          .gte('updated_at', threshold.toIso8601String())
          .order('updated_at', ascending: false)
          .limit(1);

      final rows =
          (response as List<dynamic>).whereType<Map<String, dynamic>>();
      final activeTypingState = rows.cast<Map<String, dynamic>?>().firstWhere(
            (row) => row != null,
            orElse: () => null,
          );
      final isFriendTyping = activeTypingState != null;
      getFriendTypingNotifier(friendshipId).value = isFriendTyping;

      _friendTypingExpiryTimers.remove(friendshipId)?.cancel();
      if (!isFriendTyping) {
        return;
      }

      final updatedAtRaw = activeTypingState['updated_at'] as String?;
      final updatedAt = updatedAtRaw == null
          ? DateTime.now()
          : DateTime.tryParse(updatedAtRaw)?.toLocal() ?? DateTime.now();
      final expiresAt = updatedAt.add(_friendTypingTtl);
      final remaining = expiresAt.difference(DateTime.now());

      _friendTypingExpiryTimers[friendshipId] = Timer(
        remaining.isNegative ? Duration.zero : remaining,
        () {
          getFriendTypingNotifier(friendshipId).value = false;
          _friendTypingExpiryTimers.remove(friendshipId);
        },
      );
    } catch (_) {
      _friendTypingExpiryTimers.remove(friendshipId)?.cancel();
      getFriendTypingNotifier(friendshipId).value = false;
    }
  }

  Future<void> markChatAsRead(String friendshipId) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null || friendshipId.isEmpty) {
      return;
    }

    await Supabase.instance.client
        .from('friend_messages')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('friendship_id', friendshipId)
        .eq('recipient_id', currentUser.id)
        .isFilter('read_at', null);

    _unreadChatCountByFriendshipId[friendshipId] = 0;
    notifyListeners();
  }

  Future<void> subscribeToChat(String friendshipId) async {
    if (friendshipId.isEmpty) {
      return;
    }

    final activeFriendshipId = _activeChatFriendshipId;
    if (activeFriendshipId != null &&
        activeFriendshipId == friendshipId &&
        _chatMessagesChannel != null) {
      return;
    }

    if (_chatMessagesChannel != null) {
      await Supabase.instance.client.removeChannel(_chatMessagesChannel!);
      _chatMessagesChannel = null;
      _activeChatFriendshipId = null;
    }

    final channel =
        Supabase.instance.client.channel('friend_messages:$friendshipId');
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'friend_messages',
      callback: (payload) {
        final newRecord = payload.newRecord;
        final oldRecord = payload.oldRecord;
        final recordFriendshipId = (newRecord['friendship_id'] ??
            oldRecord['friendship_id']) as String;
        if (recordFriendshipId != friendshipId) {
          return;
        }
        unawaited(loadChatMessages(friendshipId));
      },
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'friendship_id',
        value: friendshipId,
      ),
    );
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'friend_typing_states',
      callback: (_) {
        unawaited(_refreshFriendTypingState(friendshipId));
      },
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'friendship_id',
        value: friendshipId,
      ),
    );

    channel.subscribe();
    _chatMessagesChannel = channel;
    _activeChatFriendshipId = friendshipId;
    await _refreshFriendTypingState(friendshipId);
  }

  Future<void> unsubscribeChat() async {
    if (_chatMessagesChannel == null) {
      return;
    }

    final friendshipId = _activeChatFriendshipId;
    if (friendshipId != null) {
      await setTypingState(friendshipId, false);
      _friendTypingExpiryTimers.remove(friendshipId)?.cancel();
      getFriendTypingNotifier(friendshipId).value = false;
    }

    await Supabase.instance.client.removeChannel(_chatMessagesChannel!);
    _chatMessagesChannel = null;
    _activeChatFriendshipId = null;
  }

  Future<void> _refreshRemoteWorkoutMapping() async {
    final response = await Supabase.instance.client
        .from('workouts')
        .select('id, legacy_id')
        .eq('is_active', true);

    _remoteWorkoutIdsByLegacyId
      ..clear()
      ..addEntries(
        (response as List<dynamic>)
            .whereType<Map<String, dynamic>>()
            .map(
              (row) => MapEntry(
                row['legacy_id'] as String? ?? '',
                row['id'] as String? ?? '',
              ),
            )
            .where((entry) => entry.key.isNotEmpty && entry.value.isNotEmpty),
      );
  }

  Future<Set<String>> _fetchRemoteFavoriteIds() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null || _remoteWorkoutIdsByLegacyId.isEmpty) {
      return <String>{};
    }

    final remoteIdToLegacyId = {
      for (final entry in _remoteWorkoutIdsByLegacyId.entries)
        entry.value: entry.key,
    };

    final response = await Supabase.instance.client
        .from('favorites')
        .select('workout_id')
        .eq('user_id', currentUser.id);

    return (response as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map((row) => remoteIdToLegacyId[row['workout_id'] as String? ?? ''])
        .whereType<String>()
        .toSet();
  }

  Future<List<WorkoutLogEntry>> _fetchRemoteWorkoutLogs() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null || _remoteWorkoutIdsByLegacyId.isEmpty) {
      return const [];
    }

    final remoteIdToLegacyId = {
      for (final entry in _remoteWorkoutIdsByLegacyId.entries)
        entry.value: entry.key,
    };

    final response = await Supabase.instance.client
        .from('workout_logs')
        .select(
          'id, workout_id, completed_at, duration_seconds, calories_burned, progress_value, progress_unit, result_note',
        )
        .eq('user_id', currentUser.id)
        .order('completed_at');

    return (response as List<dynamic>)
        .whereType<Map<String, dynamic>>()
        .map((row) {
          final legacyId =
              remoteIdToLegacyId[row['workout_id'] as String? ?? ''];
          if (legacyId == null) {
            return null;
          }
          return WorkoutLogEntry(
            id: row['id'] as String? ?? '',
            workoutId: legacyId,
            completedAt: DateTime.parse(row['completed_at'] as String),
            durationSeconds: row['duration_seconds'] as int? ?? 0,
            caloriesBurned: row['calories_burned'] as int? ?? 0,
            progressValue: (row['progress_value'] as num?)?.toDouble(),
            progressUnit: row['progress_unit'] as String? ?? '',
            resultNote: row['result_note'] as String? ?? '',
          );
        })
        .whereType<WorkoutLogEntry>()
        .toList(growable: false);
  }

  Future<void> _pushMissingFavoritesToSupabase(
    Set<String> localFavoriteIds,
    Set<String> remoteFavoriteIds,
  ) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      return;
    }

    final missingIds = localFavoriteIds.difference(remoteFavoriteIds);
    if (missingIds.isEmpty) {
      return;
    }

    final payload = missingIds
        .map((id) => _remoteWorkoutIdsByLegacyId[id])
        .whereType<String>()
        .map(
          (remoteWorkoutId) => {
            'user_id': currentUser.id,
            'workout_id': remoteWorkoutId,
          },
        )
        .toList(growable: false);

    if (payload.isEmpty) {
      return;
    }

    await Supabase.instance.client
        .from('favorites')
        .upsert(payload, onConflict: 'user_id,workout_id');
  }

  Future<void> _pushMissingLogsToSupabase(
    List<WorkoutLogEntry> localLogs,
    List<WorkoutLogEntry> remoteLogs,
  ) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      return;
    }

    final remoteKeys = remoteLogs.map(_logSyncKey).toSet();
    final payload = <Map<String, dynamic>>[];

    for (final entry in localLogs) {
      if (remoteKeys.contains(_logSyncKey(entry))) {
        continue;
      }

      final remoteWorkoutId = _remoteWorkoutIdsByLegacyId[entry.workoutId];
      if (remoteWorkoutId == null) {
        continue;
      }

      payload.add({
        'user_id': currentUser.id,
        'workout_id': remoteWorkoutId,
        'completed_at': entry.completedAt.toIso8601String(),
        'duration_seconds': entry.durationSeconds,
        'calories_burned': entry.caloriesBurned,
        'progress_value': entry.progressValue,
        'progress_unit': entry.progressUnit,
        'result_note': entry.resultNote,
      });
    }

    if (payload.isEmpty) {
      return;
    }

    await Supabase.instance.client.from('workout_logs').insert(payload);
  }

  void _applyRemoteWorkoutState(
    Set<String> favoriteIds,
    List<WorkoutLogEntry> logs,
  ) {
    _dailyWorkoutIds.clear();
    _dailyWorkoutLogs.clear();

    for (var index = 0; index < _workouts.length; index++) {
      _workouts[index] = _workouts[index].copyWith(
        isFavorite: favoriteIds.contains(_workouts[index].id),
        completedCount: 0,
      );
    }

    for (final entry in logs) {
      _appendLogEntry(entry);
    }
  }

  String _logSyncKey(WorkoutLogEntry entry) {
    final progressValue = entry.progressValue == null
        ? ''
        : entry.progressValue!.toStringAsFixed(2);
    return [
      entry.workoutId,
      entry.completedAt.toIso8601String(),
      entry.durationSeconds.toString(),
      entry.caloriesBurned.toString(),
      progressValue,
      entry.progressUnit,
      entry.resultNote,
    ].join('|');
  }

  Future<void> _syncFavoriteToSupabase(
      String workoutId, bool isFavorite) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      return;
    }

    try {
      if (_remoteWorkoutIdsByLegacyId.isEmpty) {
        await _refreshRemoteWorkoutMapping();
      }

      final remoteWorkoutId = _remoteWorkoutIdsByLegacyId[workoutId];
      if (remoteWorkoutId == null) {
        return;
      }

      if (isFavorite) {
        await Supabase.instance.client.from('favorites').upsert(
          {
            'user_id': currentUser.id,
            'workout_id': remoteWorkoutId,
          },
          onConflict: 'user_id,workout_id',
        );
      } else {
        await Supabase.instance.client
            .from('favorites')
            .delete()
            .eq('user_id', currentUser.id)
            .eq('workout_id', remoteWorkoutId);
      }
    } catch (_) {
      // Keep local state if the network request fails.
    }
  }

  Future<void> _syncLogEntryToSupabase(WorkoutLogEntry entry) async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      return;
    }

    try {
      if (_remoteWorkoutIdsByLegacyId.isEmpty) {
        await _refreshRemoteWorkoutMapping();
      }

      final remoteWorkoutId = _remoteWorkoutIdsByLegacyId[entry.workoutId];
      if (remoteWorkoutId == null) {
        return;
      }

      await Supabase.instance.client.from('workout_logs').insert({
        'user_id': currentUser.id,
        'workout_id': remoteWorkoutId,
        'completed_at': entry.completedAt.toIso8601String(),
        'duration_seconds': entry.durationSeconds,
        'calories_burned': entry.caloriesBurned,
        'progress_value': entry.progressValue,
        'progress_unit': entry.progressUnit,
        'result_note': entry.resultNote,
      });
    } catch (_) {
      // Keep local state if the network request fails.
    }
  }

  /// Проверить и разблокировать достижения после завершения тренировки
  Future<void> _checkAchievementsAfterWorkout() async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) return;

      final stats = getStats();
      final totalWorkouts = stats['totalWorkouts'] ?? 0;
      final totalCalories = stats['totalCalories'] ?? 0;

      // Получаем текущую полосу (streak) - количество дней подряд с тренировками
      final currentStreak = _calculateCurrentStreak();

      // Получаем AchievementService и проверяем достижения
      final achievementService = AchievementService();
      await achievementService.checkAndUnlockAchievements(
        currentUser.id,
        totalWorkouts,
        totalCalories,
        currentStreak,
      );
    } catch (e) {
      debugPrint('Error checking achievements after workout: $e');
    }
  }

  int getCurrentStreak() => _calculateCurrentStreak();

  /// Рассчитать текущую полосу (дни подряд с тренировками)
  int _calculateCurrentStreak() {
    if (_dailyWorkoutLogs.isEmpty) return 0;

    final dates = _dailyWorkoutLogs.keys
        .map((dateStr) {
          try {
            return DateTime.parse(dateStr);
          } catch (_) {
            return null;
          }
        })
        .whereType<DateTime>()
        .toList();

    if (dates.isEmpty) return 0;

    dates.sort((a, b) => b.compareTo(a)); // Сортируем от новых к старым

    int streak = 0;
    DateTime currentDate = DateTime.now();
    currentDate =
        DateTime(currentDate.year, currentDate.month, currentDate.day);

    for (final date in dates) {
      final dateOnly = DateTime(date.year, date.month, date.day);
      final daysDifference = currentDate.difference(dateOnly).inDays;

      if (daysDifference == streak) {
        streak++;
      } else {
        break;
      }
    }

    return streak;
  }
}
