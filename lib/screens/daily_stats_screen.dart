import 'package:flutter/material.dart';

import '../models/daily_workout.dart';
import '../services/workout_service.dart';
import '../widgets/app_surfaces.dart';

class DailyStatsScreen extends StatefulWidget {
  const DailyStatsScreen({super.key});

  @override
  State<DailyStatsScreen> createState() => _DailyStatsScreenState();
}

class _DailyStatsScreenState extends State<DailyStatsScreen> {
  final workoutService = WorkoutService();
  late List<DateTime> _trainingDates;

  @override
  void initState() {
    super.initState();
    _trainingDates = workoutService.getAllTrainingDates();
  }

  @override
  Widget build(BuildContext context) {
    final streak = workoutService.getTrainingStreak();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final emptyIconColor = isDark
        ? Colors.white.withValues(alpha: 0.3)
        : Colors.black.withValues(alpha: 0.2);
    final emptyTextColor =
        isDark ? Colors.white : const Color(0xFF111827);
    final emptySubtextColor =
        isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

    return Scaffold(
      appBar: AppBar(
        title: const Text('За день'),
      ),
      body: AppScreenBackground(
        child: _trainingDates.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.fitness_center_rounded,
                      size: 64,
                      color: emptyIconColor,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Нет тренировок',
                      style: TextStyle(
                        color: emptyTextColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Начните тренироваться, чтобы видеть статистику',
                      style: TextStyle(
                        color: emptySubtextColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  // Streak Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.local_fire_department,
                          size: 48,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Серия тренировок',
                                style: TextStyle(
                                  color: Color(0xFFFFFFFF),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$streak дн.',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'История тренировок',
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF111827),
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._trainingDates.map((date) {
                    final dailyWorkout = workoutService.getDailyWorkout(date);
                    return Column(
                      children: [
                        _DailyWorkoutCard(
                          dailyWorkout: dailyWorkout!,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 12),
                      ],
                    );
                  }),
                ],
              ),
      ),
    );
  }
}

class _DailyWorkoutCard extends StatelessWidget {
  final DailyWorkout dailyWorkout;
  final bool isDark;

  const _DailyWorkoutCard({
    required this.dailyWorkout,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final durationMinutes = dailyWorkout.totalDuration ~/ 60;
    final durationSeconds = dailyWorkout.totalDuration % 60;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.03),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: ExpansionTile(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: const Color(0xFF2A9D8F).withValues(alpha: 0.2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    dailyWorkout.getDayOfWeek(),
                    style: const TextStyle(
                      color: Color(0xFF2A9D8F),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    dailyWorkout.getFormattedDate(),
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF111827),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${dailyWorkout.exercises.length} упражнений',
                    style: TextStyle(
                      color: isDark ? Colors.white : const Color(0xFF111827),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        size: 14,
                        color: const Color(0xFFFF6B35),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${dailyWorkout.totalCalories} ккал',
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFFD1D5DB)
                              : const Color(0xFF6B7280),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.schedule_rounded,
                        size: 14,
                        color: const Color(0xFF60A5FA),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${durationMinutes}м ${durationSeconds}с',
                        style: TextStyle(
                          color: isDark
                              ? const Color(0xFFD1D5DB)
                              : const Color(0xFF6B7280),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Упражнения:',
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFFD1D5DB)
                      : const Color(0xFF6B7280),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...dailyWorkout.exercises.map((exercise) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.06)
                          : Colors.black.withValues(alpha: 0.03),
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.05)
                            : Colors.black.withValues(alpha: 0.03),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    exercise.title,
                                    style: TextStyle(
                                      color:
                                          isDark ? Colors.white : const Color(0xFF111827),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    exercise.description,
                                    style: TextStyle(
                                      color: isDark
                                          ? const Color(0xFF9CA3AF)
                                          : const Color(0xFF6B7280),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(6),
                                    color: const Color(0xFFFF6B35)
                                        .withValues(alpha: 0.15),
                                  ),
                                  child: Text(
                                    '${exercise.caloriesBurned} ккал',
                                    style: const TextStyle(
                                      color: Color(0xFFFF6B35),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}
