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

  const AchievementLockedCard({
    super.key,
    required this.achievement,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade300.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
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
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(Icons.lock, color: Colors.grey),
                ),
              ),
              Text(
                '+${achievement.rewardXp} XP',
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            achievement.name,
            style: const TextStyle(
              color: Colors.grey,
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
        ],
      ),
    );
  }
}
