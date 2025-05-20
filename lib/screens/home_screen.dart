import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kpz_core/controllers/bluetooth_controller.dart';
import 'package:kpz_core/controllers/workout_controller.dart';
import 'package:kpz_core/models/workout.dart';
import 'package:kpz_core/screens/workout_screen.dart';
import 'package:kpz_core/screens/workout_stats_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Workout>> _workoutsFuture;

  @override
  void initState() {
    super.initState();
    _workoutsFuture = _fetchWorkouts();
  }

  Future<void> _refreshWorkouts() async {
    setState(() {
      _workoutsFuture = _fetchWorkouts();
    });
    await _workoutsFuture;
  }

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
      body: FutureBuilder<List<Workout>>(
        future: _workoutsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error fetching workouts'));
          } else if (!snapshot.hasData ||
              snapshot.data == null ||
              snapshot.data!.isEmpty) {
            return const Center(child: Text('No workouts found'));
          }
          return RefreshIndicator(
            onRefresh: _refreshWorkouts,
            child: ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final workout = snapshot.data![index];
                return ListTile(
                  title: Text(
                    DateFormat(
                      'yyyy-MM-dd – kk:mm',
                    ).format(workout.timestamps.first),
                  ),
                  subtitle: Text(_formatDuration(workout.duration)),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => WorkoutStatsScreen(workout: workout),
                      ),
                    );
                    if (result == true) {
                      _refreshWorkouts();
                    }
                  },
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: Consumer<BluetoothController>(
        builder: (context, bluetoothController, child) {
          if (bluetoothController.status != BluetoothStatus.connected) {
            return const SizedBox.shrink();
          }

          return FloatingActionButton.extended(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => ChangeNotifierProvider(
                        create:
                            (context) => WorkoutController(
                              context.read<BluetoothController>(),
                            ),
                        child: const WorkoutScreen(),
                      ),
                ),
              );

              if (result is Workout) {
                final newWorkout = result;

                setState(() {
                  _workoutsFuture = _fetchWorkouts();
                });
                await _workoutsFuture;

                if (mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => WorkoutStatsScreen(workout: newWorkout),
                    ),
                  );
                }
              } else if (result == true) {
                setState(() {
                  _workoutsFuture = _fetchWorkouts();
                });
                await _workoutsFuture;
              }
            },
            label: const Text('Start Workout'),
            icon: const Icon(Icons.fitness_center),
          );
        },
      ),
    );
  }

  Future<List<Workout>> _fetchWorkouts() async {
    final prefs = await SharedPreferences.getInstance();
    final workoutsString = prefs.getStringList('workouts') ?? [];
    final workouts =
        workoutsString.map((e) => Workout.fromJsonString(e)).toList();
    workouts.sort(
      (a, b) => a.timestamps.first.isBefore(b.timestamps.first) ? 1 : -1,
    );
    return workouts;
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }
}
