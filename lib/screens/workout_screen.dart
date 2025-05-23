import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:kpz_core/controllers/bluetooth_controller.dart';
import 'package:kpz_core/controllers/workout_controller.dart';
import 'package:kpz_core/widgets/heat_zone_chart.dart';
import 'package:provider/provider.dart';

class WorkoutScreen extends HookWidget {
  const WorkoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final pulseAnimationController = useAnimationController(
      duration: const Duration(milliseconds: 750),
    )..repeat(reverse: true);
    late final Animation<double> scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.1,
    ).animate(
      CurvedAnimation(
        parent: pulseAnimationController,
        curve: Curves.easeInOut,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text(
          'Workout',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _showCancelWorkoutDialog(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16,
            children: [
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Core Temperature',
                        style: TextStyle(
                          color: Color(0xFFD8D8D8),
                          fontSize: 20,
                        ),
                      ),
                      Consumer<WorkoutController>(
                        builder:
                            (context, controller, child) => Text(
                              '${controller.coreTemperature.toStringAsFixed(2)} °C',
                              style: TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              Flexible(
                flex: 5,
                child: Consumer<WorkoutController>(
                  builder:
                      (context, controller, child) => HeatZoneChart(
                        zone1Duration: controller.zone1Duration,
                        zone2Duration: controller.zone2Duration,
                        zone3Duration: controller.zone3Duration,
                      ),
                ),
              ),
              Flexible(
                flex: 2,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ScaleTransition(
                                  scale: scaleAnimation,
                                  child: Icon(
                                    Icons.favorite,
                                    color: Colors.red,
                                    size: 32,
                                  ),
                                ),
                                SizedBox(width: 4),
                                if (context
                                        .read<BluetoothController>()
                                        .heartRateStream !=
                                    null)
                                  StreamBuilder(
                                    stream:
                                        context
                                            .read<BluetoothController>()
                                            .heartRateStream,
                                    builder:
                                        (context, snapshot) => Text(
                                          '${snapshot.data}',
                                          style: TextStyle(
                                            fontSize: 32,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                  )
                                else
                                  Text('No Data'),
                              ],
                            ),
                            Text(
                              'Heart Rate',
                              style: TextStyle(
                                color: Color(0xFFD8D8D8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      VerticalDivider(),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Consumer<WorkoutController>(
                              builder:
                                  (context, controller, child) => Text(
                                    controller.elapsedTime,
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                            ),
                            Text(
                              'Elapsed Time',
                              style: TextStyle(
                                color: Color(0xFFD8D8D8),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ElevatedButton(
                  onPressed:
                      () => _showStopWorkoutDialog(
                        context,
                        controller: context.read<WorkoutController>(),
                      ),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: Text("Stop Workout"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showCancelWorkoutDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder:
          (BuildContext dialogContext) => AlertDialog(
            title: const Text('Cancel Workout?'),
            content: const Text(
              'Are you sure you want to cancel the workout? This action cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  Navigator.of(context).pop(true);
                },
                child: const Text('Yes'),
              ),
            ],
          ),
    );
  }

  Future<void> _showStopWorkoutDialog(
    BuildContext context, {
    required WorkoutController controller,
  }) {
    return showDialog(
      context: context,
      builder:
          (BuildContext dialogContext) => AlertDialog(
            title: const Text('Stop Workout?'),
            content: const Text('Are you sure you want to stop the workout? '),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                },
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () {
                  final newWorkout = controller.generateWorkoutModel();
                  Navigator.of(dialogContext).pop();
                  Navigator.of(context).pop(newWorkout);
                },
                child: const Text('Yes'),
              ),
            ],
          ),
    );
  }
}
