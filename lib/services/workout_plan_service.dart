import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/workout_plan.dart';

class WorkoutPlanService extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  List<WorkoutPlan> _userPlans = [];
  WorkoutPlan? _activePlan;
  bool _loaded = false;

  List<WorkoutPlan> get userPlans => _userPlans;
  WorkoutPlan? get activePlan => _activePlan;

  Future<void> loadPlans(String userId) async {
    if (_loaded) return;

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

      _loaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading plans: $e');
    }
  }

  Future<WorkoutPlan> createPlan({
    required String userId,
    required String name,
    required String description,
    required int durationWeeks,
  }) async {
    try {
      final result = await _supabase
          .from('workout_plans')
          .insert({
            'user_id': userId,
            'name': name,
            'description': description,
            'duration_weeks': durationWeeks,
            'is_active': _userPlans.isEmpty, // Первый план автоматически активный
          })
          .select()
          .single();

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
      await _supabase
          .from('workout_plans')
          .update({
            'name': name,
            'description': description,
            'duration_weeks': durationWeeks,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', planId);

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
            .update({'is_active': false})
            .eq('id', _activePlan!.id);
      }

      // Активируем новый план
      await _supabase
          .from('workout_plans')
          .update({'is_active': true})
          .eq('id', planId);

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
      await _supabase
          .from('workout_plans')
          .delete()
          .eq('id', planId);

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
      // Находим максимальный порядок для этого дня
      final existingDays = _activePlan?.days
              ?.where((d) => d.dayOfWeek == dayOfWeek)
              .toList() ??
          [];

      final maxOrder =
          existingDays.isEmpty ? 0 : existingDays.map((d) => d.orderInDay).reduce((a, b) => a > b ? a : b);

      final result = await _supabase
          .from('workout_plan_days')
          .insert({
            'plan_id': planId,
            'day_of_week': dayOfWeek,
            'workout_id': workoutId,
            'order_in_day': maxOrder + 1,
          })
          .select()
          .single();

      final day = WorkoutPlanDay.fromJson(result);

      // Обновляем активный план
      if (_activePlan?.id == planId) {
        _activePlan = _activePlan!.copyWith(
          days: [...(_activePlan?.days ?? []), day],
        );
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
      await _supabase
          .from('workout_plan_days')
          .delete()
          .eq('id', dayId);

      if (_activePlan != null) {
        _activePlan = _activePlan!.copyWith(
          days: _activePlan!.days?.where((d) => d.id != dayId).toList(),
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error removing workout from day: $e');
      rethrow;
    }
  }

  List<WorkoutPlanDay> getWorkoutsForDay(int dayOfWeek) {
    return _activePlan?.days?.where((d) => d.dayOfWeek == dayOfWeek).toList() ?? [];
  }

  Future<void> reload(String userId) async {
    _loaded = false;
    await loadPlans(userId);
  }

  void reset() {
    _userPlans = [];
    _activePlan = null;
    _loaded = false;
  }
}
