import 'dart:async';

import 'package:flutter/material.dart';
import 'package:kpz_core/controllers/bluetooth_controller.dart';
import 'package:kpz_core/models/workout.dart';

class WorkoutController extends ChangeNotifier {
  WorkoutController(this.bluetoothController) {
    _workout = Workout();

    _startTimer();
  }

  // Variables
  double _coreTemperature = 36.5;

  Timer? _timer;
  Duration _elapsedTime = Duration.zero;

  Duration _zone1Time = Duration.zero;
  Duration _zone2Time = Duration.zero;
  Duration _zone3Time = Duration.zero;

  late Workout _workout;
  BluetoothController bluetoothController;

  // Getters
  double get coreTemperature => _coreTemperature;
  String get elapsedTime => formatElapsedTime(_elapsedTime);

  Duration get zone1Duration => _zone1Time;
  Duration get zone2Duration => _zone2Time;
  Duration get zone3Duration => _zone3Time;

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _elapsedTime += Duration(seconds: 1);
      _updateZoneTimes();
      _updateCoreTemperature();
      notifyListeners();
    });
  }

  void _updateZoneTimes() {
    if (_coreTemperature < 37) {
      _zone1Time += Duration(seconds: 1);
    } else if (_coreTemperature < 39) {
      _zone2Time += Duration(seconds: 1);
    } else {
      _zone3Time += Duration(seconds: 1);
    }
  }

  Workout generateWorkoutModel() {
    _workout.finish(_elapsedTime);
    return _workout;
  }

  static String formatElapsedTime(Duration time) {
    return '${time.inMinutes.remainder(60).toString().padLeft(2, '0')}:${(time.inSeconds.remainder(60)).toString().padLeft(2, '0')}';
  }

  void _updateCoreTemperature() {
    int heartRate = bluetoothController.currentHeartRate;
    double skinTemp = bluetoothController.currentSkinTemp;
    double ambientTemp = bluetoothController.currentAmbientTemp;

    _coreTemperature = WorkoutController.calculateCoreTemperature(
      heartRate,
      skinTemp,
      ambientTemp,
    );

    _workout.addDataEntry(
      timestamp: DateTime.now(),
      heartRate: heartRate,
      skinTemp: skinTemp,
      ambientTemp: ambientTemp,
      coreTemp: _coreTemperature,
    );
  }

  static double calculateCoreTemperature(
    int heartRate,
    double skinTemperature,
    double ambientTemperature,
  ) {
    return 15.35 +
        (0.648 * skinTemperature) -
        (0.064 * ambientTemperature) +
        (0.008 * heartRate) -
        (0.381 * 1);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
