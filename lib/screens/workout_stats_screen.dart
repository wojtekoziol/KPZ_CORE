import 'package:flutter/material.dart';
import 'package:kpz_core/models/workout.dart';

class WorkoutStatsScreen extends StatelessWidget {
  const WorkoutStatsScreen({super.key, required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Workout Stats',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
    );
  }
}
