import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:kpz_core/models/workout.dart';

class WorkoutController extends ChangeNotifier {
  WorkoutController() {
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

  // Getters
  double get coreTemperature => _coreTemperature;
  int get heartRate => _heartRate;
  String get elapsedTime => formatElapsedTime(_elapsedTime);

  Duration get zone1Duration => _zone1Time;
  Duration get zone2Duration => _zone2Time;
  Duration get zone3Duration => _zone3Time;

  void _startTimer() {
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      _elapsedTime += Duration(seconds: 1);
      _updateZoneTimes();
      notifyListeners();
    });
  }

  void _updateZoneTimes() {
    if (Random().nextBool()) {
      _zone1Time += Duration(seconds: 1);
    } else if (Random().nextBool()) {
      _zone2Time += Duration(seconds: 1);
    } else {
      _zone3Time += Duration(seconds: 1);
    }
  }

  Workout generateWorkoutModel() {
    // TODO: Implement the logic to generate and save a workout model
    return Workout();
  }

  static String formatElapsedTime(Duration time) {
    return '${time.inMinutes.remainder(60).toString().padLeft(2, '0')}:${(time.inSeconds.remainder(60)).toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
