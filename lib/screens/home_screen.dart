import 'package:flutter/material.dart';
import 'package:kpz_core/controllers/workout_controller.dart';
import 'package:kpz_core/models/workout.dart';
import 'package:kpz_core/screens/workout_screen.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  var workoutHistory = <Workout>[];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'KPZ CORE',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              _connectToBluetooth();
            },
            icon: Icon(Icons.bluetooth_connected),
          ),
        ],
      ),
      body: FutureBuilder(
        future: _fetchWorkouts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error fetching workouts'));
          } else if (workoutHistory.isEmpty) {
            return const Center(child: Text('No workouts found'));
          }
          return ListView.builder(
            itemCount: workoutHistory.length,
            itemBuilder: (context, index) {
              final workout = workoutHistory[index];
              return Text('Workout $index');
              // return ListTile(
              //   title: Text(workout.name),
              //   subtitle: Text(workout.date.toString()),
              //   onTap: () {
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(
              //         builder: (context) => WorkoutScreen(workout: workout),
              //       ),
              //     );
              //   },
              // );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ChangeNotifierProvider(
                    create: (context) => WorkoutController(),
                    child: const WorkoutScreen(),
                  ),
            ),
          );
        },
        label: const Text('Start Workout'),
        icon: const Icon(Icons.fitness_center),
      ),
    );
  }

  Future<void> _fetchWorkouts() async {}

  Future<void> _connectToBluetooth() async {}
}
