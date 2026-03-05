import 'package:flutter/material.dart';
import '../models/workout.dart';
import '../screens/workout_detail_screen.dart';

class WorkoutCard extends StatelessWidget {
  final Workout workout;
  const WorkoutCard({super.key, required this.workout});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shadowColor: Colors.blue.withOpacity(0.3),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => WorkoutDetailScreen(workout: workout)));
        },
        child: Row(
          children: [
            Image.asset(workout.image, width: 100, height: 100, fit: BoxFit.cover),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(workout.title,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(workout.description),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}