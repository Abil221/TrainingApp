import 'package:flutter/material.dart';

import '../services/workout_service.dart';
import 'gym_screen.dart';
import 'home_workouts_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final workoutService = WorkoutService();
    return ListenableBuilder(
      listenable: workoutService,
      builder: (context, child) {
        final stats = workoutService.getStats();
        final menuEntries = [
          _MenuEntry(
            title: 'Зал',
            subtitle:
                'Split и Fullbody-программы с акцентом на силу, структуру и прогрессию.',
            stats: '${workoutService.getGymWorkouts().length} тренировок',
            icon: Icons.fitness_center,
            colors: const [Color(0xFF111827), Color(0xFF283548)],
            screen: const GymScreen(),
          ),
          _MenuEntry(
            title: 'Дома',
            subtitle:
                'Сила, кардио и мобильность без сложного оборудования и лишней суеты.',
            stats: '${workoutService.getHomeWorkouts().length} тренировок',
            icon: Icons.home_rounded,
            colors: const [Color(0xFFFF6B35), Color(0xFFE63946)],
            screen: const HomeWorkoutsScreen(),
          ),
        ];

        return Scaffold(
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(32),
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF0F172A),
                    Color(0xFF1F2937),
                    Color(0xFF2B3548)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF6B35).withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'TRAIN SMART',
                      style: TextStyle(
                        color: Color(0xFFFFB089),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Главное меню тренировок',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      height: 1.05,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Выбирай формат под задачу: тренировки дома для темпа и дисциплины или зал для силы, массы и системного прогресса.',
                    style: TextStyle(
                      color: Color(0xFFD1D5DB),
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          value: '${stats['totalWorkouts'] ?? 0}',
                          label: 'завершено',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatTile(
                          value: '${workoutService.getFavorites().length}',
                          label: 'избранных',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatTile(
                          value: _formatCompact(stats['totalCalories'] ?? 0),
                          label: 'калорий',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            ...menuEntries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _MainMenuCard(entry: entry),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Почему так удобнее',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 14),
            const _QuickBenefit(
              icon: Icons.tune_rounded,
              title: 'Разделение по формату',
              subtitle:
                  'Домашние и заловые тренировки больше не смешиваются в одном списке.',
              color: Color(0xFF111827),
            ),
            const SizedBox(height: 12),
            const _QuickBenefit(
              icon: Icons.local_fire_department,
              title: 'Спортивный визуальный стиль',
              subtitle:
                  'Тёмная энергия, чистая типографика и акцент без визуального шума.',
              color: Color(0xFFFF6B35),
            ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatCompact(int value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return '$value';
  }
}

class _MenuEntry {
  final String title;
  final String subtitle;
  final String stats;
  final IconData icon;
  final List<Color> colors;
  final Widget screen;

  const _MenuEntry({
    required this.title,
    required this.subtitle,
    required this.stats,
    required this.icon,
    required this.colors,
    required this.screen,
  });
}

class _MainMenuCard extends StatelessWidget {
  final _MenuEntry entry;

  const _MainMenuCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => entry.screen),
          );
        },
        child: Ink(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: LinearGradient(
              colors: entry.colors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: entry.colors.first.withValues(alpha: 0.25),
                blurRadius: 28,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(entry.icon, color: Colors.white, size: 28),
                  ),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      entry.stats,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                entry.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                entry.subtitle,
                style: const TextStyle(
                  color: Color(0xFFF9FAFB),
                  fontSize: 15,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              const Row(
                children: [
                  Text(
                    'Открыть раздел',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(width: 10),
                  Icon(Icons.arrow_forward, color: Colors.white),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;

  const _StatTile({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Color(0xFFD1D5DB), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _QuickBenefit extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _QuickBenefit({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
