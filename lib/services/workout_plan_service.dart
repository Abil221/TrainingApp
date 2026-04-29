import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/workout.dart';
import '../models/workout_plan.dart';

class WorkoutPlanService extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  List<WorkoutPlan> _userPlans = [];
  WorkoutPlan? _activePlan;
  bool _loaded = false;
  String? _loadedUserId;

  List<WorkoutPlan> get userPlans => _userPlans;
  WorkoutPlan? get activePlan => _activePlan;

  String? get currentUserId {
    final user = _supabase.auth.currentUser;
    return user?.id;
  }

  bool get isUserAuthenticated => currentUserId != null;

  Future<void> loadPlans(String userId) async {
    if (_loaded && _loadedUserId == userId) {
      return;
    }

    if (_loadedUserId != userId) {
      reset();
    }

    try {
      final plansData = await _supabase
          .from('workout_plans')
          .select('*, workout_plan_days(*, workouts(*))')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      _userPlans = (plansData as List)
          .map((e) => WorkoutPlan.fromJson(e as Map<String, dynamic>))
          .toList();

      // Устанавливаем активный план
      _activePlan = _userPlans.isNotEmpty
          ? _userPlans.firstWhere(
              (p) => p.isActive,
              orElse: () => _userPlans.first,
            )
          : null;

      _loadedUserId = userId;
      _loaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading plans: $e');
    }
  }

  Future<WorkoutPlan> createPlan({
    String? userId,
    required String name,
    required String description,
    required int durationWeeks,
  }) async {
    try {
      final uid = userId ?? currentUserId;
      if (uid == null || uid.isEmpty) {
        debugPrint('[WorkoutPlanService] ERROR: User not authenticated');
        throw StateError('User not authenticated');
      }
      debugPrint('[WorkoutPlanService] Creating plan for user: $uid, name: $name');
      final result = await _supabase
          .from('workout_plans')
          .insert({
            'user_id': uid,
            'name': name,
            'description': description,
            'duration_weeks': durationWeeks,
            'is_active':
                _userPlans.isEmpty, // Первый план автоматически активный
          })
          .select()
          .single();
      debugPrint('[WorkoutPlanService] Plan created successfully: ${result['id']}');

      final plan = WorkoutPlan.fromJson(result);
      _userPlans.add(plan);

      if (plan.isActive) {
        _activePlan = plan;
      }

      notifyListeners();
      return plan;
    } catch (e) {
      debugPrint('Error creating plan: $e');
      rethrow;
    }
  }

  Future<void> updatePlan({
    required String planId,
    required String name,
    required String description,
    required int durationWeeks,
  }) async {
    try {
      await _supabase.from('workout_plans').update({
        'name': name,
        'description': description,
        'duration_weeks': durationWeeks,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', planId);

      final index = _userPlans.indexWhere((p) => p.id == planId);
      if (index != -1) {
        _userPlans[index] = _userPlans[index].copyWith(
          name: name,
          description: description,
          durationWeeks: durationWeeks,
          updatedAt: DateTime.now(),
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating plan: $e');
      rethrow;
    }
  }

  Future<void> setActivePlan(String planId) async {
    try {
      // Деактивируем старый активный план
      if (_activePlan != null) {
        await _supabase
            .from('workout_plans')
            .update({'is_active': false}).eq('id', _activePlan!.id);
      }

      // Активируем новый план
      await _supabase
          .from('workout_plans')
          .update({'is_active': true}).eq('id', planId);

      final index = _userPlans.indexWhere((p) => p.id == planId);
      if (index != -1) {
        for (int i = 0; i < _userPlans.length; i++) {
          _userPlans[i] = _userPlans[i].copyWith(
            isActive: i == index,
          );
        }
        _activePlan = _userPlans[index];
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error setting active plan: $e');
      rethrow;
    }
  }

  Future<void> deletePlan(String planId) async {
    try {
      await _supabase.from('workout_plans').delete().eq('id', planId);

      _userPlans.removeWhere((p) => p.id == planId);

      if (_activePlan?.id == planId) {
        _activePlan = _userPlans.isNotEmpty ? _userPlans.first : null;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting plan: $e');
      rethrow;
    }
  }

  Future<WorkoutPlanDay> addWorkoutToDay({
    required String planId,
    required int dayOfWeek,
    required String workoutId,
  }) async {
    try {
      final plan = _userPlans.firstWhere((p) => p.id == planId);
      final existingDays =
          plan.days?.where((d) => d.dayOfWeek == dayOfWeek).toList() ?? [];
      final maxOrder = existingDays.isEmpty
          ? 0
          : existingDays
              .map((d) => d.orderInDay)
              .reduce((a, b) => a > b ? a : b);

      final result = await _supabase
          .from('workout_plan_days')
          .insert({
            'plan_id': planId,
            'day_of_week': dayOfWeek,
            'workout_id': workoutId,
            'order_in_day': maxOrder + 1,
          })
          .select('*, workouts(*)')
          .single();

      final day = WorkoutPlanDay.fromJson(result);

      final planIndex = _userPlans.indexWhere((p) => p.id == planId);
      if (planIndex != -1) {
        _userPlans[planIndex] = _userPlans[planIndex].copyWith(
          days: [...(_userPlans[planIndex].days ?? []), day],
        );
        if (_activePlan?.id == planId) {
          _activePlan = _userPlans[planIndex];
        }
        notifyListeners();
      }

      return day;
    } catch (e) {
      debugPrint('Error adding workout to day: $e');
      rethrow;
    }
  }

  Future<void> removeWorkoutFromDay(String dayId) async {
    try {
      await _supabase.from('workout_plan_days').delete().eq('id', dayId);

      for (int i = 0; i < _userPlans.length; i++) {
        if (_userPlans[i].days?.any((d) => d.id == dayId) ?? false) {
          _userPlans[i] = _userPlans[i].copyWith(
            days: _userPlans[i].days?.where((d) => d.id != dayId).toList(),
          );
          if (_activePlan?.id == _userPlans[i].id) {
            _activePlan = _userPlans[i];
          }
          break;
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error removing workout from day: $e');
      rethrow;
    }
  }

  Future<List<Workout>> loadAvailableWorkouts() async {
    try {
      final data = await _supabase
          .from('workouts')
          .select()
          .eq('is_active', true)
          .order('category')
          .order('title');
      return (data as List)
          .map((e) => Workout.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error loading available workouts: $e');
      return [];
    }
  }

  List<WorkoutPlanDay> getWorkoutsForDay(int dayOfWeek) {
    return _activePlan?.days?.where((d) => d.dayOfWeek == dayOfWeek).toList() ??
        [];
  }

  Future<void> reload(String userId) async {
    _loaded = false;
    await loadPlans(userId);
  }

  void reset() {
    _userPlans = [];
    _activePlan = null;
    _loaded = false;
    _loadedUserId = null;
  }
}
