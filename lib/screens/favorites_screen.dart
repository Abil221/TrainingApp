import 'package:flutter/material.dart';
import '../services/workout_service.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Workouts'),
        backgroundColor: const Color(0xFF1E88E5),
      ),
      body: favorites.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'No favorites yet',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add workouts to your favorites',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: favorites.length,
              itemBuilder: (context, index) => WorkoutCard(
                workout: favorites[index],
                onFavoriteTap: () {
                  setState(() {
                    workoutService.toggleFavorite(favorites[index].id);
                  });
                },
              ),
            ),
    );
  }
}
