import 'package:flutter/material.dart';

import '../services/workout_service.dart';
import '../widgets/app_surfaces.dart';
import '../widgets/workout_card.dart';

class HomeWorkoutsScreen extends StatefulWidget {
  const HomeWorkoutsScreen({super.key});

  @override
  State<HomeWorkoutsScreen> createState() => _HomeWorkoutsScreenState();
}

class _HomeWorkoutsScreenState extends State<HomeWorkoutsScreen> {
  final workoutService = WorkoutService();
  int selectedCategoryIndex = 0;

  final List<_HomeCategory> categories = const [
    _HomeCategory(
      title: 'Сила',
      sourceCategory: 'Strength',
      icon: Icons.bolt_rounded,
      accent: Color(0xFF111827),
      description: 'Базовые силовые движения с весом собственного тела.',
    ),
    _HomeCategory(
      title: 'Кардио',
      sourceCategory: 'Cardio',
      icon: Icons.monitor_heart_outlined,
      accent: Color(0xFFE63946),
      description: 'Интенсивные форматы для выносливости и жиросжигания.',
    ),
    _HomeCategory(
      title: 'Мобильность',
      sourceCategory: 'Flexibility',
      icon: Icons.self_improvement,
      accent: Color(0xFF2A9D8F),
      description: 'Растяжка, контроль корпуса и восстановление.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final activeCategory = categories[selectedCategoryIndex];
    final workouts =
        workoutService.getWorkoutsByCategory(activeCategory.sourceCategory);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Дома'),
      ),
      body: AppScreenBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                  colors: [Color(0xFFFF6B35), Color(0xFFE63946)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Тренировки дома',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Чёткие планы без сложного оборудования. Выбирай цель и начинай сразу.',
                    style: TextStyle(
                      color: Color(0xFFFFE3DA),
                      fontSize: 15,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 128,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final selected = index == selectedCategoryIndex;

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedCategoryIndex = index;
                      });
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      width: 170,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: selected
                              ? [
                                  category.accent,
                                  category.accent.withValues(alpha: 0.84),
                                ]
                              : [
                                  Colors.white.withValues(alpha: 0.94),
                                  category.accent.withValues(alpha: 0.08),
                                ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                          color: selected
                              ? category.accent
                              : const Color(0xFFE5E7EB),
                        ),
                        boxShadow: selected
                            ? [
                                BoxShadow(
                                  color:
                                      category.accent.withValues(alpha: 0.18),
                                  blurRadius: 22,
                                  offset: const Offset(0, 10),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: selected
                                  ? Colors.white.withValues(alpha: 0.16)
                                  : category.accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(
                              category.icon,
                              color: selected ? Colors.white : category.accent,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            category.title,
                            style: TextStyle(
                              color: selected
                                  ? Colors.white
                                  : const Color(0xFF111827),
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            category.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: selected
                                  ? const Color(0xFFFDEDE8)
                                  : const Color(0xFF6B7280),
                              fontSize: 12.5,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Text(
              activeCategory.title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              activeCategory.description,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontSize: 14,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 14),
            if (workouts.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
                  decoration: appPanelDecoration(
                    context,
                    accent: activeCategory.accent,
                  ),
                  child: const Center(
                    child: Text(
                      'Пока нет домашних тренировок в этой категории',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              )
            else
              ...workouts.map(
                (workout) => WorkoutCard(
                  workout: workout,
                  onFavoriteTap: () {
                    setState(() {
                      workoutService.toggleFavorite(workout.id);
                    });
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HomeCategory {
  final String title;
  final String sourceCategory;
  final IconData icon;
  final Color accent;
  final String description;

  const _HomeCategory({
    required this.title,
    required this.sourceCategory,
    required this.icon,
    required this.accent,
    required this.description,
  });
}
