import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class Workout {
  Workout();

  List<DateTime> timestamps = [];
  List<int> heartRateData = [];
  List<double> skinTempData = [];
  List<double> ambientTempData = [];
  List<double> coreTempData = [];

  Duration duration = Duration.zero;

  void addDataEntry({
    required DateTime timestamp,
    required int heartRate,
    required double skinTemp,
    required double ambientTemp,
    required double coreTemp,
  }) {
    timestamps.add(timestamp);
    heartRateData.add(heartRate);
    skinTempData.add(skinTemp);
    ambientTempData.add(ambientTemp);
    coreTempData.add(coreTemp);
  }

  void finish(Duration duration) async {
    this.duration = duration;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    final workouts = prefs.getStringList('workouts') ?? [];
    workouts.add(toJsonString());
    prefs.setStringList('workouts', workouts);
  }

  Map<String, dynamic> toJson() {
    return {
      'timestamps': timestamps.map((ts) => ts.toIso8601String()).toList(),
      'heartRateData': heartRateData,
      'skinTempData': skinTempData,
      'ambientTempData': ambientTempData,
      'coreTempData': coreTempData,
      'duration': duration.inMilliseconds,
    };
  }

  factory Workout.fromJson(Map<String, dynamic> json) {
    final workout = Workout();
    workout.timestamps =
        (json['timestamps'] as List<dynamic>)
            .map((ts) => DateTime.parse(ts as String))
            .toList();
    workout.heartRateData =
        (json['heartRateData'] as List<dynamic>)
            .map((hr) => hr as int)
            .toList();
    workout.skinTempData =
        (json['skinTempData'] as List<dynamic>)
            .map((st) => st as double)
            .toList();
    workout.ambientTempData =
        (json['ambientTempData'] as List<dynamic>)
            .map((at) => at as double)
            .toList();
    workout.coreTempData =
        (json['coreTempData'] as List<dynamic>)
            .map((ct) => ct as double)
            .toList();
    workout.duration = Duration(milliseconds: json['duration'] as int);
    return workout;
  }

  String toJsonString() => jsonEncode(toJson());

  factory Workout.fromJsonString(String jsonString) {
    return Workout.fromJson(jsonDecode(jsonString) as Map<String, dynamic>);
  }
}
