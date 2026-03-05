import 'package:flutter/material.dart';
import '../models/workout.dart';
import '../models/category.dart';
import '../widgets/workout_card.dart';
import '../widgets/category_selector.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedCategoryIndex = 0;

  final List<Category> categories = const [
    Category(name: 'Strength', icon: 'assets/strength.png'),
    Category(name: 'Cardio', icon: 'assets/cardio.png'),
    Category(name: 'Flexibility', icon: 'assets/flexibility.png'),
  ];

  final List<Workout> workouts = const [
    Workout(title: 'Push Ups', description: '3x15', duration: 60, image: 'assets/pushups.jpg', category: 'Strength'),
    Workout(title: 'Squats', description: '3x20', duration: 90, image: 'assets/squats.jpg', category: 'Strength'),
    Workout(title: 'Running', description: '10 min', duration: 600, image: 'assets/running.png', category: 'Cardio'),
    Workout(title: 'Plank', description: '60 sec', duration: 60, image: 'assets/plank.jpg', category: 'Flexibility'),
  ];

  @override
  Widget build(BuildContext context) {
    final filteredWorkouts = workouts.where((w) => w.category == categories[selectedCategoryIndex].name).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Workouts'), backgroundColor: const Color(0xFF1E88E5)),
      body: Column(
        children: [
          CategorySelector(
            categories: categories,
            selectedIndex: selectedCategoryIndex,
            onSelected: (index) {
              setState(() {
                selectedCategoryIndex = index;
              });
            },
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredWorkouts.length,
              itemBuilder: (context, index) => WorkoutCard(workout: filteredWorkouts[index]),
            ),
          ),
        ],
      ),
    );
  }
}