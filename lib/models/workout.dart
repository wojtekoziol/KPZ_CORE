// TODO: Implement workout model
class Workout {
  List<DateTime> _timestamps = [];
  List<int> _heartRateData = [];
  List<double> _skinTempData = [];
  List<double> _ambientTempData = [];
  List<double> _coreTempData = [];

  Duration _duration = Duration.zero;

  void addDataEntry({
    required DateTime timestamp,
    required int heartRate,
    required double skinTemp,
    required double ambientTemp,
    required double coreTemp,
  }) {
    _timestamps.add(timestamp);
    _heartRateData.add(heartRate);
    _skinTempData.add(skinTemp);
    _ambientTempData.add(ambientTemp);
    _coreTempData.add(coreTemp);
  }

  void finish(Duration duration) {
    _duration = duration;
  }
}
