import 'package:flutter/material.dart';
import '../models/category.dart';
import '../services/workout_service.dart';
import '../widgets/workout_card.dart';
import '../widgets/category_selector.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int selectedCategoryIndex = 0;
  final workoutService = WorkoutService();

  final List<Category> categories = const [
    Category(name: 'Strength', icon: 'assets/strength.png'),
    Category(name: 'Cardio', icon: 'assets/cardio.png'),
    Category(name: 'Flexibility', icon: 'assets/flexibility.png'),
  ];

  @override
  Widget build(BuildContext context) {
    final allWorkouts = workoutService.getAllWorkouts();
    final filteredWorkouts = allWorkouts
        .where((w) => w.category == categories[selectedCategoryIndex].name)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workouts'),
        backgroundColor: const Color(0xFF1E88E5),
      ),
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
          if (filteredWorkouts.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.fitness_center, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No workouts found', style: TextStyle(fontSize: 18)),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                itemCount: filteredWorkouts.length,
                itemBuilder: (context, index) => WorkoutCard(
                  workout: filteredWorkouts[index],
                  onFavoriteTap: () {
                    setState(() {
                      workoutService.toggleFavorite(filteredWorkouts[index].id);
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