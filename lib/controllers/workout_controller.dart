import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:kpz_core/models/workout.dart';

class WorkoutController extends ChangeNotifier {
  WorkoutController() {
    _workout = Workout();

    _startTimer();
  }

  // Variables
  final double _coreTemperature = 38.6;
  final int _heartRate = 122;

  Timer? _timer;
  Duration _elapsedTime = Duration.zero;

  Duration _zone1Time = Duration.zero;
  Duration _zone2Time = Duration.zero;
  Duration _zone3Time = Duration.zero;

  double _coreTemp = 36.6;

  late Workout _workout;

  // Getters
  double get coreTemperature => _coreTemperature;
  int get heartRate => _heartRate;
  String get elapsedTime => formatElapsedTime(_elapsedTime);

  Duration get zone1Duration => _zone1Time;
  Duration get zone2Duration => _zone2Time;
  Duration get zone3Duration => _zone3Time;

  double get coreTemp => _coreTemp;

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _elapsedTime += Duration(seconds: 1);
      _updateZoneTimes();
      notifyListeners();
    });
  }

  void _updateZoneTimes() {
    if (_coreTemp < 37) {
      _zone1Time += Duration(seconds: 1);
    } else if (_coreTemp < 39) {
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

  double calculateCoreTemperature(
    int heartRate,
    double skinTemperature,
    double ambientTemperature,
  ) {
    _coreTemp =
        15.35 +
        (0.648 * skinTemperature) -
        (0.064 * ambientTemperature) +
        (0.008 * heartRate) -
        (0.381 * 1);

    _workout.addDataEntry(
      timestamp: DateTime.now(),
      heartRate: heartRate,
      skinTemp: skinTemperature,
      ambientTemp: ambientTemperature,
      coreTemp: _coreTemp,
    );

    return _coreTemp;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
