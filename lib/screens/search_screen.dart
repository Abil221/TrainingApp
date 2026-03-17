import 'package:flutter/material.dart';

import '../services/workout_service.dart';
import '../widgets/app_surfaces.dart';
import '../widgets/workout_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController controller = TextEditingController();
  String query = '';
  final workoutService = WorkoutService();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: workoutService,
      builder: (context, child) {
        final filtered = query.isEmpty
            ? workoutService.getAllWorkouts()
            : workoutService.searchWorkouts(query);
        final gymMatches = filtered
            .where(
              (w) => w.category.contains('Split') || w.category == 'Fullbody',
            )
            .length;
        final homeMatches = filtered.length - gymMatches;

        return Scaffold(
          appBar: AppBar(title: const Text('Поиск')),
          body: AppScreenBackground(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: const LinearGradient(
                  colors: [Color(0xFF111827), Color(0xFF283548)],
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
                      'FIND YOUR NEXT SESSION',
                      style: TextStyle(
                        color: Color(0xFFFFB089),
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Ищи тренировки быстро',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Находи упражнения по названию, категории или формату тренировки без длинной прокрутки.',
                    style: TextStyle(
                      color: Color(0xFFD1D5DB),
                      fontSize: 15,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: controller,
                    decoration: InputDecoration(
                      hintText: 'Например: squat, fullbody, cardio...',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: query.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                controller.clear();
                                setState(() {
                                  query = '';
                                });
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(
                          color: Color(0xFFFF6B35),
                          width: 1.4,
                        ),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() {
                        query = value;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _SearchStatCard(
                    value: '${filtered.length}',
                    label: 'найдено',
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SearchStatCard(
                    value: '$homeMatches',
                    label: 'дома',
                    color: const Color(0xFFFF6B35),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SearchStatCard(
                    value: '$gymMatches',
                    label: 'зал',
                    color: const Color(0xFF2A9D8F),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (filtered.isEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
                decoration: appPanelDecoration(context),
                child: Column(
                  children: [
                    Icon(Icons.search_off_rounded,
                        size: 56, color: Colors.grey[500]),
                    const SizedBox(height: 14),
                    Text(
                      query.isEmpty
                          ? 'Начни поиск по названию или категории'
                          : 'Ничего не найдено по этому запросу',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Попробуй изменить запрос или использовать более короткое ключевое слово.',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 14,
                        height: 1.45,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              )
            else
              ...filtered.map(
                (workout) => WorkoutCard(
                  workout: workout,
                  onFavoriteTap: () => workoutService.toggleFavorite(workout.id),
                ),
              ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SearchStatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _SearchStatCard({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: appPanelDecoration(context, accent: color, radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
