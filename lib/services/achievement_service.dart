import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/achievement.dart';
import '../models/user_level.dart';

class AchievementService extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  List<Achievement> _allAchievements = [];
  List<UserAchievement> _userAchievements = [];
  UserLevel? _userLevel;
  bool _loaded = false;
  String? _loadedUserId;

  List<Achievement> get allAchievements => _allAchievements;
  List<UserAchievement> get userAchievements => _userAchievements;
  UserLevel? get userLevel => _userLevel;
  int get currentXp => _userLevel?.totalXp ?? 0;
  int get currentLevel => _userLevel?.currentLevel ?? 1;

  Future<void> loadAchievements(String userId) async {
    if (_loaded && _loadedUserId == userId) {
      return;
    }

    if (_loadedUserId != userId) {
      reset();
    }

    try {
      // Загружаем все достижения
      final achievementsData =
          await _supabase.from('achievements').select().order('created_at');

      _allAchievements = (achievementsData as List)
          .map((e) => Achievement.fromJson(e))
          .toList();

      // Загружаем достижения пользователя
      final userAchievementsData = await _supabase
          .from('user_achievements')
          .select('*, achievements(*)')
          .eq('user_id', userId);

      _userAchievements = (userAchievementsData as List)
          .map((e) => UserAchievement.fromJson(e))
          .toList();

      // Загружаем уровень пользователя
      final levelData = await _supabase
          .from('user_levels')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (levelData != null) {
        _userLevel = UserLevel.fromJson(levelData);
      } else {
        // Если записи нет, создаем новую
        _userLevel = UserLevel(
          userId: userId,
          currentLevel: 1,
          totalXp: 0,
          xpForNextLevel: 1000,
          updatedAt: DateTime.now(),
        );
        await _createUserLevel(userId, _userLevel!);
      }

      _loadedUserId = userId;
      _loaded = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading achievements: $e');
    }
  }

  Future<void> addXp(String userId, int xpAmount) async {
    if (_userLevel == null) return;

    try {
      final newTotalXp = _userLevel!.totalXp + xpAmount;
      final newLevel = _calculateLevelFromXp(newTotalXp);
      final nextLevelXp = 1000 * (newLevel * (newLevel + 1) ~/ 2);

      _userLevel = _userLevel!.copyWith(
        totalXp: newTotalXp,
        currentLevel: newLevel,
        xpForNextLevel: nextLevelXp,
        updatedAt: DateTime.now(),
      );

      await _supabase.from('user_levels').update({
        'total_xp': newTotalXp,
        'current_level': newLevel,
        'xp_for_next_level': nextLevelXp,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', userId);

      notifyListeners();
    } catch (e) {
      debugPrint('Error adding XP: $e');
    }
  }

  Future<void> unlockAchievement(
    String userId,
    String achievementId,
  ) async {
    try {
      // Проверяем, не разблокировано ли уже
      final existing = _userAchievements
          .where((a) => a.achievementId == achievementId)
          .firstOrNull;

      if (existing != null) return;

      final achievement =
          _allAchievements.where((a) => a.id == achievementId).firstOrNull;

      if (achievement == null) return;

      // Добавляем достижение
      final result = await _supabase
          .from('user_achievements')
          .insert({
            'user_id': userId,
            'achievement_id': achievementId,
            'unlocked_at': DateTime.now().toIso8601String(),
          })
          .select('*, achievements(*)')
          .single();

      final userAchievement = UserAchievement.fromJson(result);
      _userAchievements.add(userAchievement);

      // Добавляем XP
      await addXp(userId, achievement.rewardXp);

      notifyListeners();
    } catch (e) {
      debugPrint('Error unlocking achievement: $e');
    }
  }

  Future<List<Achievement>> checkAndUnlockAchievements(
    String userId,
    int totalWorkouts,
    int totalCalories,
    int currentStreak,
  ) async {
    final unlockedList = <Achievement>[];

    try {
      for (final achievement in _allAchievements) {
        // Пропускаем уже разблокированные
        if (_userAchievements.any((ua) => ua.achievementId == achievement.id)) {
          continue;
        }

        bool shouldUnlock = false;

        switch (achievement.criteriaType) {
          case AchievementCriteria.totalWorkouts:
            shouldUnlock = totalWorkouts >= achievement.criteriaValue;
          case AchievementCriteria.caloriesBurned:
            shouldUnlock = totalCalories >= achievement.criteriaValue;
          case AchievementCriteria.streakDays:
            shouldUnlock = currentStreak >= achievement.criteriaValue;
          default:
            continue;
        }

        if (shouldUnlock) {
          await unlockAchievement(userId, achievement.id);
          unlockedList.add(achievement);
        }
      }
    } catch (e) {
      debugPrint('Error checking achievements: $e');
    }

    return unlockedList;
  }

  Future<void> _createUserLevel(String userId, UserLevel userLevel) async {
    try {
      await _supabase.from('user_levels').insert({
        'user_id': userId,
        'current_level': userLevel.currentLevel,
        'total_xp': userLevel.totalXp,
        'xp_for_next_level': userLevel.xpForNextLevel,
        'updated_at': userLevel.updatedAt.toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error creating user level: $e');
    }
  }

  int _calculateLevelFromXp(int totalXp) {
    int level = 1;
    int requiredXp = 1000;

    while (totalXp >= requiredXp) {
      totalXp -= requiredXp;
      level++;
      requiredXp = 1000 + (level * 500); // Растущее требование XP
    }

    return level;
  }

  void reset() {
    _allAchievements = [];
    _userAchievements = [];
    _userLevel = null;
    _loaded = false;
    _loadedUserId = null;
  }
}
