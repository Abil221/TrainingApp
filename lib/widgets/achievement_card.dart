import 'package:flutter/material.dart';
import '../models/achievement.dart';

class AchievementCard extends StatelessWidget {
  final UserAchievement achievement;
  final Achievement? details;
  final VoidCallback? onTap;

  const AchievementCard({
    super.key,
    required this.achievement,
    this.details,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.amber.shade600,
              Colors.orange.shade600,
            ],
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      _getIconEmoji(),
                      style: const TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                Text(
                  '+${details?.rewardXp ?? 0} XP',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              details?.name ?? 'Достижение',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              details?.description ?? '',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              'Разблокировано ${_formatDate(achievement.unlockedAt)}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getIconEmoji() {
    switch (details?.iconName) {
      case 'beginner':
        return '🌱';
      case 'runner':
        return '🏃';
      case 'fire':
        return '🔥';
      case 'trophy':
        return '🏆';
      case 'star':
        return '⭐';
      case 'lightning':
        return '⚡';
      default:
        return '🎯';
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'сегодня';
    } else if (difference.inDays == 1) {
      return 'вчера';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} дней назад';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} недель назад';
    } else {
      return '${(difference.inDays / 30).floor()} месяцев назад';
    }
  }
}

class AchievementLockedCard extends StatelessWidget {
  final Achievement achievement;
  final int currentWorkouts;
  final int currentCalories;
  final int currentStreak;
  final int currentLevel;

  const AchievementLockedCard({
    super.key,
    required this.achievement,
    this.currentWorkouts = 0,
    this.currentCalories = 0,
    this.currentStreak = 0,
    this.currentLevel = 1,
  });

  double _progress() {
    if (achievement.criteriaValue <= 0) return 0;
    final current = switch (achievement.criteriaType) {
      AchievementCriteria.totalWorkouts => currentWorkouts,
      AchievementCriteria.caloriesBurned => currentCalories,
      AchievementCriteria.streakDays => currentStreak,
      AchievementCriteria.levelReached => currentLevel,
      _ => 0,
    };
    return (current / achievement.criteriaValue).clamp(0.0, 1.0);
  }

  String _progressLabel() {
    final current = switch (achievement.criteriaType) {
      AchievementCriteria.totalWorkouts =>
        '$currentWorkouts / ${achievement.criteriaValue} тренировок',
      AchievementCriteria.caloriesBurned =>
        '$currentCalories / ${achievement.criteriaValue} ккал',
      AchievementCriteria.streakDays =>
        '$currentStreak / ${achievement.criteriaValue} дней',
      AchievementCriteria.levelReached =>
        'Уровень $currentLevel / ${achievement.criteriaValue}',
      _ => achievement.description,
    };
    return current;
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progress();
    final hasProgress = progress > 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: hasProgress
                      ? Colors.orange.withValues(alpha: 0.15)
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    hasProgress ? Icons.lock_open : Icons.lock,
                    color: hasProgress ? Colors.orange : Colors.grey,
                  ),
                ),
              ),
              Text(
                '+${achievement.rewardXp} XP',
                style: TextStyle(
                  color: hasProgress ? Colors.orange : Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            achievement.name,
            style: TextStyle(
              color: hasProgress
                  ? Colors.black87
                  : Colors.grey,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            achievement.description,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation(
                hasProgress ? Colors.orange : Colors.grey.shade400,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _progressLabel(),
            style: TextStyle(
              color: hasProgress ? Colors.orange.shade700 : Colors.grey,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
