import 'package:flutter/material.dart';
import '../models/user_level.dart';

class LevelProgressCard extends StatelessWidget {
  final UserLevel userLevel;
  final bool showDetails;

  const LevelProgressCard({
    super.key,
    required this.userLevel,
    this.showDetails = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.purple.shade400,
            Colors.blue.shade600,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Уровень',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${userLevel.currentLevel}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.2),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${(userLevel.progressToNextLevel * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const Text(
                        'к уровню',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (showDetails) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: userLevel.progressToNextLevel,
                minHeight: 8,
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation(Colors.greenAccent.shade400),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Общий опыт',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${userLevel.totalXp}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'До следующего уровня',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${userLevel.xpForNextLevel}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
