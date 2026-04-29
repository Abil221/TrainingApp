import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/achievement_service.dart';
import '../services/workout_service.dart';
import '../widgets/achievement_card.dart';
import '../widgets/level_progress_card.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAchievements());
  }

  Future<void> _checkAchievements() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);

    final service = context.read<AchievementService>();
    if (!service.isUserAuthenticated) {
      setState(() => _isChecking = false);
      return;
    }

    final workoutService = WorkoutService();
    final stats = workoutService.getStats();
    final unlocked = await service.checkAndUnlockAchievementsForCurrentUser(
      stats['totalWorkouts'] ?? 0,
      stats['totalCalories'] ?? 0,
      workoutService.getCurrentStreak(),
    );

    if (mounted) {
      setState(() => _isChecking = false);
      if (unlocked.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Разблокировано достижений: ${unlocked.length}!',
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AchievementService>(
      builder: (context, achievementService, child) {
        final userLevel = achievementService.userLevel;
        final userAchievements = achievementService.userAchievements;
        final allAchievements = achievementService.allAchievements;

        if (userLevel == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final completedIds = {
          for (final ua in userAchievements) ua.achievementId,
        };

        final unlockedAchievements = userAchievements
            .map((ua) => (ua, ua.achievement))
            .where((item) => item.$2 != null)
            .toList();

        final lockedAchievements = allAchievements
            .where((a) => !completedIds.contains(a.id))
            .toList();

        final workoutStats = WorkoutService().getStats();
        final totalWorkouts = workoutStats['totalWorkouts'] ?? 0;
        final totalCalories = workoutStats['totalCalories'] ?? 0;
        final currentStreak = WorkoutService().getCurrentStreak();
        final currentLevel = userLevel.currentLevel;

        return Scaffold(
          backgroundColor: Colors.grey.shade50,
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                floating: true,
                backgroundColor: Colors.white,
                elevation: 0,
                title: const Text(
                  'Достижения',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                centerTitle: true,
                actions: [
                  if (_isChecking)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      onPressed: _checkAchievements,
                      tooltip: 'Проверить достижения',
                    ),
                ],
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    LevelProgressCard(userLevel: userLevel),
                    const SizedBox(height: 16),

                    // Текущий прогресс
                    _StatsRow(
                      totalWorkouts: totalWorkouts,
                      totalCalories: totalCalories,
                      streak: currentStreak,
                    ),
                    const SizedBox(height: 24),

                    // Разблокированные
                    if (unlockedAchievements.isNotEmpty) ...[
                      Text(
                        'Разблокированные (${unlockedAchievements.length})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...unlockedAchievements.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: AchievementCard(
                            achievement: item.$1,
                            details: item.$2,
                          ),
                        );
                      }),
                      const SizedBox(height: 24),
                    ],

                    // Заблокированные
                    if (lockedAchievements.isNotEmpty) ...[
                      Text(
                        'В процессе (${lockedAchievements.length})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...lockedAchievements.map((achievement) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: AchievementLockedCard(
                            achievement: achievement,
                            currentWorkouts: totalWorkouts,
                            currentCalories: totalCalories,
                            currentStreak: currentStreak,
                            currentLevel: currentLevel,
                          ),
                        );
                      }),
                    ],

                    if (allAchievements.isEmpty)
                      Center(
                        child: Column(
                          children: [
                            const SizedBox(height: 32),
                            Icon(Icons.emoji_events_outlined,
                                size: 64, color: Colors.grey.shade300),
                            const SizedBox(height: 16),
                            Text(
                              'Достижения не загружены',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Убедитесь, что таблица achievements заполнена\n(см. supabase/seed_achievements.sql)',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  color: Colors.grey.shade400, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int totalWorkouts;
  final int totalCalories;
  final int streak;

  const _StatsRow({
    required this.totalWorkouts,
    required this.totalCalories,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: _StatChip(
                icon: Icons.fitness_center,
                value: '$totalWorkouts',
                label: 'тренировок')),
        const SizedBox(width: 8),
        Expanded(
            child: _StatChip(
                icon: Icons.local_fire_department,
                value: '$totalCalories',
                label: 'ккал')),
        const SizedBox(width: 8),
        Expanded(
            child: _StatChip(
                icon: Icons.bolt,
                value: '$streak',
                label: 'дней подряд')),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: Colors.orange, size: 20),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label,
              style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 10)),
        ],
      ),
    );
  }
}
