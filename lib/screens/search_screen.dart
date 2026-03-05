import 'package:flutter/material.dart';
import '../models/workout.dart';
import '../widgets/workout_card.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController controller = TextEditingController();
  String query = '';

  final List<Workout> workouts = const [
    Workout(title: 'Push Ups', description: '3x15', duration: 60, image: 'assets/pushups.jpg', category: 'Strength'),
    Workout(title: 'Squats', description: '3x20', duration: 90, image: 'assets/squats.jpg', category: 'Strength'),
    Workout(title: 'Running', description: '10 min', duration: 600, image: 'assets/running.png', category: 'Cardio'),
    Workout(title: 'Plank', description: '60 sec', duration: 60, image: 'assets/plank.jpg', category: 'Flexibility'),
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = workouts.where((w) => w.title.toLowerCase().contains(query.toLowerCase())).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Search Workouts'), backgroundColor: const Color(0xFF1E88E5)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                  hintText: 'Search workouts...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.search)),
              onChanged: (value) {
                setState(() {
                  query = value;
                });
              },
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (context, index) => WorkoutCard(workout: filtered[index]),
            ),
          ),
        ],
      ),
    );
  }
}