import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/achievement_service.dart';
import '../widgets/achievement_card.dart';
import '../widgets/level_progress_card.dart';

class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AchievementService>(
      builder: (context, achievementService, child) {
        final userLevel = achievementService.userLevel;
        final userAchievements = achievementService.userAchievements;
        final allAchievements = achievementService.allAchievements;

        if (userLevel == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final completedAchievements = <String>{};
        for (final ua in userAchievements) {
          completedAchievements.add(ua.achievementId);
        }

        final unlockedAchievements = userAchievements
            .map((ua) => (ua, ua.achievement))
            .where((item) => item.$2 != null)
            .toList();

        final lockedAchievements = allAchievements
            .where((a) => !completedAchievements.contains(a.id))
            .toList();

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
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Level Card
                    LevelProgressCard(userLevel: userLevel),
                    const SizedBox(height: 24),

                    // Unlocked Achievements
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
                        final userAch = item.$1;
                        final achDetails = item.$2;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: AchievementCard(
                            achievement: userAch,
                            details: achDetails,
                          ),
                        );
                      }),
                      const SizedBox(height: 24),
                    ],

                    // Locked Achievements
                    if (lockedAchievements.isNotEmpty) ...[
                      Text(
                        'Заблокированные (${lockedAchievements.length})',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...lockedAchievements.map((achievement) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: AchievementLockedCard(achievement: achievement),
                        );
                      }),
                    ],
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
