import 'package:flutter/material.dart';
import 'package:kpz_core/controllers/bluetooth_controller.dart';
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
        title: Text('KPZ Core', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              final bluetoothController = context.read<BluetoothController>();
              if (bluetoothController.status == BluetoothStatus.connected) {
                bluetoothController.disconnect();
              } else {
                context.read<BluetoothController>().connect();
              }
            },
            icon: Consumer<BluetoothController>(
              builder: (context, value, child) {
                switch (value.status) {
                  case BluetoothStatus.unavailable:
                    return const Icon(Icons.bluetooth_disabled);
                  case BluetoothStatus.available:
                    return const Icon(Icons.bluetooth_connected);
                  case BluetoothStatus.connecting:
                    return const CircularProgressIndicator();
                  case BluetoothStatus.connected:
                    return const Icon(
                      Icons.bluetooth_connected,
                      color: Colors.green,
                    );
                }
              },
            ),
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
              // TODO: Implement the workout list item
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
      floatingActionButton: Consumer<BluetoothController>(
        builder: (context, bluetoothController, child) {
          // if (bluetoothController.status != BluetoothStatus.connected) {
          //   return const SizedBox.shrink();
          // }

          return FloatingActionButton.extended(
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
          );
        },
      ),
    );
  }

  Future<void> _fetchWorkouts() async {
    // TODO: Implement the logic to fetch workouts
  }
}
