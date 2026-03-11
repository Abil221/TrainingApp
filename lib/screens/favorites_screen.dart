import 'package:flutter/material.dart';
import '../services/workout_service.dart';
import '../widgets/app_surfaces.dart';
import '../widgets/workout_card.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final workoutService = WorkoutService();

  @override
  Widget build(BuildContext context) {
    final favorites = workoutService.getFavorites();
    final gymFavorites = favorites
        .where((workout) =>
            workout.category.startsWith('Split: ') ||
            workout.category == 'Fullbody')
        .length;
    final homeFavorites = favorites.length - gymFavorites;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Избранное'),
      ),
      body: AppScreenBackground(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [Color(0xFFE63946), Color(0xFFFF6B35)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Твой зал славы',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Сохранённые тренировки: ${favorites.length}',
                    style: const TextStyle(
                      color: Color(0xFFFFE3DA),
                      fontSize: 15,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _FavoriteStatCard(
                          value: '${favorites.length}',
                          label: 'всего',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _FavoriteStatCard(
                          value: '$homeFavorites',
                          label: 'дома',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _FavoriteStatCard(
                          value: '$gymFavorites',
                          label: 'зал',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (favorites.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: appPanelDecoration(
                  context,
                  accent: const Color(0xFFFF6B35),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.bolt_rounded, color: Color(0xFFFF6B35)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Сохраняй лучшие тренировки здесь, чтобы быстро собирать любимые сессии без повторного поиска.',
                        style: TextStyle(
                          color: Color(0xFF4B5563),
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            if (favorites.isEmpty)
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 56, horizontal: 24),
                decoration: appPanelDecoration(
                  context,
                  accent: const Color(0xFFE63946),
                ),
                child: Column(
                  children: [
                    Icon(Icons.favorite_border,
                        size: 64, color: Colors.grey[500]),
                    const SizedBox(height: 16),
                    const Text(
                      'Пока нет избранных тренировок',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Добавляй понравившиеся упражнения в избранное, чтобы возвращаться к ним быстрее.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 14, color: Color(0xFF6B7280), height: 1.45),
                    ),
                  ],
                ),
              )
            else
              ...favorites.map(
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

class _FavoriteStatCard extends StatelessWidget {
  final String value;
  final String label;

  const _FavoriteStatCard({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Color(0xFFFFE3DA), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
