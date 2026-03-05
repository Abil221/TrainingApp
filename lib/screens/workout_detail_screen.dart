import 'dart:async';
import 'package:flutter/material.dart';
import '../models/workout.dart';

class WorkoutDetailScreen extends StatefulWidget {
  final Workout workout;
  const WorkoutDetailScreen({super.key, required this.workout});

  @override
  State<WorkoutDetailScreen> createState() => _WorkoutDetailScreenState();
}

class _WorkoutDetailScreenState extends State<WorkoutDetailScreen> {
  late int remainingSeconds;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    remainingSeconds = widget.workout.duration;
  }

  void startTimer() {
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (remainingSeconds > 0) {
        setState(() => remainingSeconds--);
      } else {
        timer?.cancel();
      }
    });
  }

  void resetTimer() {
    timer?.cancel();
    setState(() => remainingSeconds = widget.workout.duration);
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double progress =
        (widget.workout.duration - remainingSeconds) / widget.workout.duration;

    return Scaffold(
      appBar: AppBar(title: Text(widget.workout.title), backgroundColor: const Color(0xFF1E88E5)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(widget.workout.image, width: 200, height: 200),
            const SizedBox(height: 24),
            Text(widget.workout.description, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 40),
            TweenAnimationBuilder(
              tween: Tween<double>(begin: 0, end: progress),
              duration: const Duration(milliseconds: 500),
              builder: (context, double value, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: value,
                      strokeWidth: 8,
                      color: const Color(0xFF1E88E5),
                      backgroundColor: Colors.grey[300],
                    ),
                    Text('$remainingSeconds s', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                );
              },
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(onPressed: startTimer, child: const Text('Start')),
                const SizedBox(width: 20),
                ElevatedButton(onPressed: resetTimer, child: const Text('Reset')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}