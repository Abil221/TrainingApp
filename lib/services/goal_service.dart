import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_goal.dart';
import '../models/weight_entry.dart';

class GoalService extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  List<UserGoal> _activeGoals = [];
  List<UserGoal> _completedGoals = [];
  List<WeightEntry> _weightHistory = [];
  bool _loaded = false;
  String? _loadedUserId;

  List<UserGoal> get activeGoals => _activeGoals;
  List<UserGoal> get completedGoals => _completedGoals;
  List<UserGoal> get allGoals => [..._activeGoals, ..._completedGoals];
  List<WeightEntry> get weightHistory => _weightHistory;

  String? get currentUserId {
    final user = _supabase.auth.currentUser;
    return user?.id;
  }

  bool get isUserAuthenticated => currentUserId != null;

  Future<void> loadGoals(String userId) async {
    if (_loaded && _loadedUserId == userId) {
      return;
    }

    if (_loadedUserId != userId) {
      reset();
    }

    try {
      final goalsData = await _supabase
          .from('user_goals')
          .select()
          .eq('user_id', userId)
          .order('deadline', ascending: true);

      final goals = (goalsData as List)
          .map((e) => UserGoal.fromJson(e as Map<String, dynamic>))
          .toList();

      _activeGoals = goals.where((g) => !g.isCompleted).toList();
      _completedGoals = goals.where((g) => g.isCompleted).toList();

      // Загружаем историю веса
      await _loadWeightHistory(userId);

      _loadedUserId = userId;
      _loaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading goals: $e');
    }
  }

  Future<void> _loadWeightHistory(String userId) async {
    try {
      final weightData = await _supabase
          .from('weight_history')
          .select()
          .eq('user_id', userId)
          .order('recorded_at', ascending: false)
          .limit(365); // Последний год

      _weightHistory = (weightData as List)
          .map((e) => WeightEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error loading weight history: $e');
    }
  }

  Future<UserGoal> createGoal({
    String? userId,
    required GoalType goalType,
    required String name,
    required String description,
    required double targetValue,
    required double currentValue,
    required String unit,
    required DateTime deadline,
  }) async {
    try {
      final uid = userId ?? currentUserId;
      if (uid == null || uid.isEmpty) {
        debugPrint('[GoalService] ERROR: User not authenticated');
        throw StateError('User not authenticated');
      }
      debugPrint('[GoalService] Creating goal for user: $uid, name: $name');
      final result = await _supabase
          .from('user_goals')
          .insert({
            'user_id': uid,
            'goal_type': goalType.value,
            'name': name,
            'description': description,
            'target_value': targetValue,
            'current_value': currentValue,
            'start_value': currentValue,
            'unit': unit,
            'deadline': deadline.toIso8601String(),
            'is_completed': false,
          })
          .select()
          .single();
      debugPrint('[GoalService] Goal created successfully: ${result['id']}');

      final goal = UserGoal.fromJson(result);
      _activeGoals.add(goal);
      _activeGoals.sort((a, b) => a.deadline.compareTo(b.deadline));

      notifyListeners();
      return goal;
    } catch (e) {
      debugPrint('Error creating goal: $e');
      rethrow;
    }
  }

  Future<void> updateGoal({
    required String goalId,
    required double currentValue,
    String? name,
    required String? description,
  }) async {
    try {
      final updateData = {
        'current_value': currentValue,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (name != null) {
        updateData['name'] = name;
      }

      if (description != null) {
        updateData['description'] = description;
      }

      await _supabase.from('user_goals').update(updateData).eq('id', goalId);

      // Обновляем локально
      final goalIndex = _activeGoals.indexWhere((g) => g.id == goalId);
      if (goalIndex != -1) {
        _activeGoals[goalIndex] = _activeGoals[goalIndex].copyWith(
          name: name ?? _activeGoals[goalIndex].name,
          currentValue: currentValue,
          description: description ?? _activeGoals[goalIndex].description,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating goal: $e');
      rethrow;
    }
  }

  Future<void> completeGoal(String goalId) async {
    try {
      await _supabase.from('user_goals').update({
        'is_completed': true,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', goalId);

      final goalIndex = _activeGoals.indexWhere((g) => g.id == goalId);
      if (goalIndex == -1) {
        debugPrint('Warning: completeGoal called for unknown goalId: $goalId');
        return;
      }

      final goal = _activeGoals[goalIndex];
      _activeGoals.removeAt(goalIndex);
      _completedGoals.add(goal.copyWith(
        isCompleted: true,
        updatedAt: DateTime.now(),
      ));

      notifyListeners();
    } catch (e) {
      debugPrint('Error completing goal: $e');
      rethrow;
    }
  }

  Future<void> deleteGoal(String goalId) async {
    try {
      await _supabase.from('user_goals').delete().eq('id', goalId);

      _activeGoals.removeWhere((g) => g.id == goalId);
      _completedGoals.removeWhere((g) => g.id == goalId);

      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting goal: $e');
      rethrow;
    }
  }

  Future<WeightEntry> recordWeight(
    String? userId,
    int weight, {
    String? notes,
  }) async {
    try {
      final uid = userId ?? currentUserId;
      if (uid == null || uid.isEmpty) {
        debugPrint(
            'Error: User not authenticated. Cannot record weight without user ID');
        throw StateError('User not authenticated');
      }
      final result = await _supabase
          .from('weight_history')
          .insert({
            'user_id': uid,
            'weight': weight,
            'recorded_at': DateTime.now().toIso8601String(),
            'notes': notes,
          })
          .select()
          .single();

      final entry = WeightEntry.fromJson(result);
      _weightHistory.insert(0, entry); // Добавляем в начало (последний записан)

      // Обновляем цели по снижению веса
      for (final goal in _activeGoals) {
        if (goal.goalType == GoalType.weightLoss) {
          await updateGoal(
            goalId: goal.id,
            currentValue: weight.toDouble(),
            description: null,
          );
        }
      }

      notifyListeners();
      return entry;
    } catch (e) {
      debugPrint('Error recording weight: $e');
      rethrow;
    }
  }

  double? getWeightChange() {
    if (_weightHistory.length < 2) return null;

    final latest = _weightHistory.first.weight.toDouble();
    final oldest = _weightHistory.last.weight.toDouble();

    return latest - oldest;
  }

  double getAverageWeight(int days) {
    final recentEntries = _weightHistory
        .where((e) =>
            e.recordedAt.isAfter(DateTime.now().subtract(Duration(days: days))))
        .toList();

    if (recentEntries.isEmpty) return 0;

    final sum = recentEntries.fold<double>(
        0, (previous, current) => previous + current.weight);

    return sum / recentEntries.length;
  }

  Future<void> reload(String userId) async {
    _loaded = false;
    await loadGoals(userId);
  }

  void reset() {
    _activeGoals = [];
    _completedGoals = [];
    _weightHistory = [];
    _loaded = false;
    _loadedUserId = null;
  }
}
