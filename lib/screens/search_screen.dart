import 'package:flutter/material.dart';
import '../services/workout_service.dart';
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
    final filtered = query.isEmpty
        ? workoutService.getAllWorkouts()
        : workoutService.searchWorkouts(query);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Workouts'),
        backgroundColor: const Color(0xFF1E88E5),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Search by name or category...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          controller.clear();
                          setState(() => query = '');
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  query = value;
                });
              },
            ),
          ),
          if (filtered.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Text(
                      query.isEmpty
                          ? 'Start searching for workouts'
                          : 'No workouts found',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) => WorkoutCard(
                  workout: filtered[index],
                  onFavoriteTap: () {
                    setState(() {
                      workoutService.toggleFavorite(filtered[index].id);
                    });
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}